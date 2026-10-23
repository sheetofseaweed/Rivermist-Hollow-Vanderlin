#!/usr/bin/env python3
"""Local-model sidecar for the agent NPC protocol: LM Studio, here or on the LAN.

Speaks the same wire protocol as the other sidecars, so DM cannot tell them
apart. Only this file knows the model is local.

    set LMSTUDIO_API_TOKEN=...            (cmd, this window only; only if the server requires it)
    python tools/agent_sidecar/local_sidecar.py --base-url http://192.168.50.120:1235/v1 --model <id> --port 1340

Measure the model before a round: time to the first word, tokens per second,
and whether four requests at once still fit the game's deadline:

    python tools/agent_sidecar/local_sidecar.py --base-url ... --model <id> --bench

Find out what the server honours, and with --explicit whether the model will
answer an explicit scene at all:

    python tools/agent_sidecar/local_sidecar.py --base-url ... --model <id> --probe --explicit

Check the prompt without a server:

    python tools/agent_sidecar/local_sidecar.py --dry-run --port 1340

What is different from the hosted sidecar: a stall here means the GPU is busy,
so a stalled try is never repeated; the first byte may take as long as prompt
processing on a loaded card; the loaded context is checked at start, because
a model loaded with the 4096 default would lose the system prompt silently;
and <think> blocks are stripped before the JSON is read.
"""

import argparse
import json
import os
import re
import statistics
import sys
import threading
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import agent_protocol as proto
import openai_compat as compat

DEFAULT_BASE_URL = "http://127.0.0.1:1234/v1"
TOKEN_ENV_VAR = "LMSTUDIO_API_TOKEN"
# An action is 60 to 150 tokens, but a thinking model spends a few hundred more before it answers.
MAX_TOKENS = 1024
# Our prompts run 3,500 to 4,800 tokens plus history. Below this the system prompt gets cut.
CONTEXT_MIN = 8192
# Prompt processing on a busy card can take this long before the first byte.
FIRST_BYTE_TIMEOUT = 20.0
IDLE_TIMEOUT = 15.0
# A local server that refused the connection is usually restarting; give it a moment.
CONNECT_RETRY_PAUSE = 2.0
# Keeps a JIT-loaded model resident for the round; a manually loaded one has no TTL anyway.
TTL_SECONDS = 86400
# Thinking off. Measured 2026-10-23 on Gemma 4 12B: 7 s to 3 s for a line, and no answer lost to a thinking cap.
REASONING_EFFORT = "none"
# A first request may have to load the model into memory, which takes a while.
LOAD_TIMEOUT = 180
# A bench request gets the whole game deadline.
BENCH_BUDGET = 25.0
LOCAL_HOSTS = ("127.0.0.1", "localhost", "::1")
SCREEN_MODES = ("block", "log")

_THINK_BLOCK = re.compile(r"<think>.*?</think>\s*", re.DOTALL | re.IGNORECASE)
_THINK_OPEN = re.compile(r"<think>.*\Z", re.DOTALL | re.IGNORECASE)
# gpt-oss "harmony" markers, for a server that leaves them in the text.
_ANALYSIS = re.compile(r"<\|channel\|>analysis<\|message\|>.*?(?:<\|end\|>|(?=<\|channel\|>final))", re.DOTALL)
_MARKERS = re.compile(r"<\|start\|>assistant|<\|channel\|>final<\|message\|>|<\|[a-z_]+\|>")
# What a refusal reads like, for the explicit probe. A bare "I can't" is everyday speech; the verb after it is the tell.
_REFUSAL = re.compile(
    r"\b(?:I can(?:'|’)?t|I cannot|I won(?:'|’)?t|I will not|I am unable to|I(?:'|’)m unable to|"
    r"I am not able to|I(?:'|’)m not able to|I must decline to|I(?:'|’)d rather not|I(?:'|’)m not going to)\s+"
    r"(?:help|assist|do|write|continue|provide|engage|comply|fulfil|fulfill|create|generate|produce|participate|"
    r"respond|answer|describe|roleplay|role-play|take part|go on|proceed|contribute|be able)\b"
    r"|\bas an AI\b|\bnot comfortable\b|\binappropriate\b|\bagainst my (?:guidelines|principles|programming|"
    r"polic(?:y|ies)|values)\b|\b(?:content|safety|usage) (?:polic(?:y|ies)|guidelines)\b|\bI must decline\b",
    re.IGNORECASE)


class LocalSetupError(Exception):
    """The server or the model is not fit to start with. The message says what to change."""


def strip_thinking(text):
    """Drop a reasoning model's thoughts, leaving the answer. An unfinished thought leaves nothing."""
    if not isinstance(text, str):
        return text
    text = _THINK_BLOCK.sub("", text)
    text = _THINK_OPEN.sub("", text)
    text = _ANALYSIS.sub("", text)
    text = _MARKERS.sub("", text)
    return text.strip()


def host_allowed(host, expose):
    """Binding off loopback puts player text on the network, so it takes a deliberate flag."""
    return host in LOCAL_HOSTS or bool(expose)


def api_root(base_url):
    """The server's root, for LM Studio's own endpoints beside the OpenAI-compatible /v1."""
    base_url = base_url.rstrip("/")
    return base_url[:-3] if base_url.endswith("/v1") else base_url


def context_of(detail):
    """The loaded context length a model listing reports, or None when it does not say."""
    if not isinstance(detail, dict):
        return None
    for field in ("loaded_context_length", "context_length"):
        value = detail.get(field)
        if isinstance(value, int) and not isinstance(value, bool) and value > 0:
            return value
    return None


def looks_like_refusal(text):
    return isinstance(text, str) and bool(_REFUSAL.search(text))


def percentile(values, share):
    """A simple percentile for a handful of samples: p95 of five values is their worst."""
    ordered = sorted(values)
    index = int(round(share * (len(ordered) - 1)))
    return ordered[max(0, min(index, len(ordered) - 1))]


class LocalDecider(compat.OpenAICompatDecider):
    name = "local"
    # A stalled try on a busy GPU queues a second job behind the first; only a failed connection is retried.
    max_attempts = 2
    min_retry_seconds = 4.0
    retry_pause = CONNECT_RETRY_PAUSE
    # Room for a thinking model to think and still answer the probe.
    probe_max_tokens = 1024

    def __init__(self, model=None, base_url=DEFAULT_BASE_URL, dry_run=False, output_mode="auto",
                 verbose=False, memory_turns=6, stream=True, explicit=False, screen_mode="block",
                 temperature=0.8, top_p=0.9, repeat_penalty=1.1, max_tokens=MAX_TOKENS,
                 context_min=CONTEXT_MIN, first_byte=FIRST_BYTE_TIMEOUT, idle=IDLE_TIMEOUT,
                 think_strip=True, ttl=TTL_SECONDS, reasoning_effort=REASONING_EFFORT):
        super().__init__(model=model or "", base_url=base_url, dry_run=dry_run, output_mode=output_mode,
                         verbose=verbose, memory_turns=memory_turns, stream=stream)
        self.first_byte_timeout = float(first_byte)
        self.idle_timeout = float(idle)
        self.max_tokens = int(max_tokens)
        self.ttl = int(ttl)
        # "none" switches a thinking model's thinking off; "off" sends nothing and leaves the server's setting.
        self.reasoning_effort = None if reasoning_effort in (None, "", "off") else reasoning_effort
        self.explicit = bool(explicit)
        self.screen_mode = screen_mode if screen_mode in SCREEN_MODES else "block"
        self.temperature = float(temperature)
        self.top_p = float(top_p)
        self.repeat_penalty = float(repeat_penalty)
        self.context_min = int(context_min)
        self.think_strip = bool(think_strip)
        # Learned at start: the loaded context, and whether json_schema is really enforced.
        self.context_length = None
        self.schema_enforced = None
        self.token = os.environ.get(TOKEN_ENV_VAR)

    # Hooks.

    def auth_headers(self):
        return compat.bearer(self.token)

    def extra_request_fields(self):
        fields = {"temperature": self.temperature, "top_p": self.top_p,
                  "repeat_penalty": self.repeat_penalty, "ttl": self.ttl}
        if self.reasoning_effort:
            fields["reasoning_effort"] = self.reasoning_effort
        return fields

    def clean_content(self, text):
        return strip_thinking(text) if self.think_strip else text

    def worth_retry(self, status, phase):
        return status == 0 and phase == "connect"

    def describe_schema(self, mode):
        # Grammar-enforced JSON needs no second statement of the shape; it only costs tokens.
        return not (mode == "json_schema" and self.schema_enforced)

    def length_hint(self):
        return ("; a thinking model used the whole budget: raise --max-tokens, or turn thinking off "
                "for this model in the server")

    def capabilities(self):
        """What DM may rely on from this sidecar. Sent with every reply."""
        return {"adapter": self.name, "explicit": self.explicit, "screening": self.screen_mode,
                "model": self.model, "context": self.context_length}

    def describe(self):
        described = super().describe()
        described.update(self.capabilities())
        described.update({"temperature": self.temperature, "top_p": self.top_p,
                          "repeat_penalty": self.repeat_penalty, "auth": bool(self.token),
                          "reasoning_effort": self.reasoning_effort})
        return described

    # Start-up.

    def models(self):
        """(ids the server lists, details by id from LM Studio's own listing, or {} on a plain server)."""
        status, body = compat.get_json(self.base_url + "/models", self.headers(), self.request_timeout)
        if status != 200 or not isinstance(body, dict):
            raise LocalSetupError("could not list models at %s/models: %s %s" % (
                self.base_url, status, compat.short_error(body)))
        ids = [m.get("id") for m in body.get("data") or [] if isinstance(m, dict) and m.get("id")]
        details = {}
        status, body = compat.get_json(api_root(self.base_url) + "/api/v0/models", self.headers(),
                                       self.request_timeout)
        if status == 200 and isinstance(body, dict):
            for entry in body.get("data") or []:
                if isinstance(entry, dict) and entry.get("id"):
                    details[entry["id"]] = entry
        return ids, details

    def choose_model(self, ids, details):
        """--model must be on the server; without it, the one loaded model, else the one language model."""
        if self.model:
            if self.model not in ids:
                raise LocalSetupError("model %r is not on the server; it has: %s" % (
                    self.model, ", ".join(ids) or "nothing"))
            return
        language = [i for i in ids if details.get(i, {}).get("type", "llm") in ("llm", "vlm")]
        loaded = [i for i in language if details.get(i, {}).get("state") == "loaded"]
        pick = loaded if len(loaded) == 1 else language if len(language) == 1 else []
        if not pick:
            raise LocalSetupError("say which model with --model; the server has: %s" % (
                ", ".join(language or ids) or "nothing"))
        self.model = pick[0]
        self.log("using the only %smodel: %s" % ("loaded " if loaded else "", self.model))

    def negotiate(self):
        """One tiny call per output mode until one is honoured. The first call also loads the model."""
        modes = list(compat.OUTPUT_MODES) if self.requested_mode == "auto" else [self.requested_mode]
        started = time.monotonic()
        for mode in modes:
            status, body, honoured, content = self.probe_mode(mode, timeout=LOAD_TIMEOUT)
            if status == 400 and self.reasoning_effort and "reasoning" in compat.short_error(body).lower():
                self.log("the server rejects reasoning_effort; thinking stays as the server sets it")
                self.reasoning_effort = None
                status, body, honoured, content = self.probe_mode(mode, timeout=LOAD_TIMEOUT)
            took = time.monotonic() - started
            if status == 0:
                raise LocalSetupError("could not reach the model server: %s" % compat.short_error(body))
            if took > 10:
                self.log("first answer took %.0fs; the model was loading" % took)
            started = time.monotonic()
            if status != 200:
                self.log("%s rejected (%d: %s)" % (mode, status, compat.short_error(body)))
                continue
            if mode == "text" or honoured:
                with self.lock:
                    self.mode = mode
                self.schema_enforced = (mode == "json_schema" and honoured)
                if not honoured and mode != "text":
                    self.log("%s is accepted but not enforced; the prompt states the shape" % mode)
                return
            self.log("%s is accepted but not enforced (model said %r)" % (mode, content.strip()[:80]))
        raise LocalSetupError("no output mode worked with %s" % self.model)

    def prepare(self):
        """Start-up checks: the model exists, the server answers, the mode is known, the context fits."""
        ids, details = self.models()
        self.choose_model(ids, details)
        self.negotiate()
        # Loaded by the probe if it was not before, so the listing can say the context now.
        _, details = self.models()
        self.context_length = context_of(details.get(self.model))
        if self.context_length is None:
            self.log("the server does not report the loaded context; make sure it is at least %d" % self.context_min)
        elif self.context_length < self.context_min:
            raise LocalSetupError(
                "%s is loaded with a context of %d tokens; the prompts need %d. Reload it with "
                "a longer context, for example: lms load %s --context-length %d" % (
                    self.model, self.context_length, self.context_min, self.model, self.context_min))
        self.log("model=%s context=%s output_mode=%s explicit=%s screen=%s base_url=%s auth=%s memory_turns=%d "
                 "reasoning_effort=%s" % (
                     self.model, self.context_length or "unknown", self.current_mode(),
                     "on" if self.explicit else "off", self.screen_mode, self.base_url,
                     "token" if self.token else "none", self.memory.max_turns, self.reasoning_effort or "server's"))

    def explicit_probe(self):
        """Does the model answer an explicit scene, or refuse? Prints the verdict and returns it."""
        request = {"model": self.model, "max_tokens": self.probe_max_tokens, "messages": [
            {"role": "system", "content": EXPLICIT_PROBE_SYSTEM},
            {"role": "user", "content": EXPLICIT_PROBE_USER},
        ]}
        request.update(self.extra_request_fields())
        status, body = compat.post_json(self.chat_url(), request, self.headers(), LOAD_TIMEOUT)
        if status != 200 or not isinstance(body, dict):
            print("explicit probe: no answer (%s %s)" % (status, compat.short_error(body)))
            return None
        choice = (body.get("choices") or [{}])[0]
        content = (choice.get("message") or {}).get("content")
        content = self.clean_content(content) if isinstance(content, str) else ""
        if not content.strip() and choice.get("finish_reason") == "length":
            print("explicit probe: no answer within %d tokens; the model was still thinking. "
                  "Raise --max-tokens or turn thinking off for it in the server." % self.probe_max_tokens)
            return None
        refused = looks_like_refusal(content) or not content.strip()
        print("explicit probe: %s" % ("REFUSED - this model will not do explicit scenes"
                                      if refused else "answered in character"))
        print("  model said: %r" % content.strip()[:160])
        return not refused

    # Measurement.

    def bench(self, count=3, parallel=2, body=None):
        """Realistic requests, first one at a time and then several at once. Prints what the game needs to know."""
        body = body or sample_body()
        turn = self.build_turn(body)
        request = dict(turn.request)
        request["messages"] = request["messages"][:1] + sample_history() + request["messages"][1:]
        upstream = proto.upstream_timeout({"deadline_ds": 250}, self.request_timeout)
        print("bench: %s at %s, %d in sequence then %d at once, prompt about %d tokens\n" % (
            self.model, self.base_url, count, parallel, estimate_tokens(request["messages"])))

        def one():
            stamps, started = {}, time.monotonic()
            status, payload, phase = compat.post_stream(
                self.chat_url(), request, self.headers(), BENCH_BUDGET,
                self.first_byte_timeout, self.idle_timeout, stamps)
            total = time.monotonic() - started
            first = stamps["first_content"] - started if "first_content" in stamps else None
            usage = payload.get("usage") if isinstance(payload, dict) else None
            usage = usage if isinstance(usage, dict) else {}
            message = ((payload.get("choices") or [{}])[0].get("message") or {}) if isinstance(payload, dict) else {}
            completion = usage.get("completion_tokens")
            details = usage.get("completion_tokens_details")
            thought = details.get("reasoning_tokens") if isinstance(details, dict) else None
            rate = None
            if isinstance(completion, int) and first is not None and total > first + 0.05:
                rate = completion / (total - first)
            return {"status": status, "total": total, "first": first, "prompt": usage.get("prompt_tokens"),
                    "completion": completion, "rate": rate, "phase": phase, "thought": thought,
                    "reasoning": bool(message.get("reasoning_content")) or bool(thought),
                    "error": None if status == 200 else payload}

        def report(label, results, rates):
            print(label)
            for i, r in enumerate(results, 1):
                if r["status"] != 200:
                    print("  %d: failed (%s)" % (i, compat.short_error(r["error"])))
                    continue
                # A queued request's first word comes before its turn; its rate would say nothing.
                print("  %d: first word %s, total %.1fs, prompt %s, answer %s tokens%s%s" % (
                    i, "%.1fs" % r["first"] if r["first"] is not None else "n/a", r["total"],
                    r["prompt"] if r["prompt"] is not None else "?", r["completion"] if r["completion"] is not None else "?",
                    ", %.0f tokens/s" % r["rate"] if (rates and r["rate"]) else "",
                    (", %s of them thinking" % r["thought"]) if r["thought"] else (", reasoning text seen" if r["reasoning"] else "")))
            good = [r["total"] for r in results if r["status"] == 200]
            if good:
                print("  total: p50 %.1fs, p95 %.1fs; upstream budget %.0fs: %s\n" % (
                    statistics.median(good), percentile(good, 0.95), upstream,
                    "fits" if percentile(good, 0.95) <= upstream else "DOES NOT FIT"))
            return good

        sequential = [one() for _ in range(max(1, count))]
        seq_good = report("one at a time:", sequential, rates=True)

        results, threads = [None] * max(1, parallel), []
        for i in range(len(results)):
            def run(slot=i):
                results[slot] = one()
            thread = threading.Thread(target=run)
            threads.append(thread)
            thread.start()
        for thread in threads:
            thread.join()
        par_good = report("%d at once:" % len(results), results, rates=False)

        if seq_good and par_good:
            if percentile(par_good, 0.95) <= upstream:
                print("AGENT_NPC_MAX_CONCURRENT %d looks safe on this model." % len(results))
            elif percentile(seq_good, 0.95) <= upstream:
                print("Keep AGENT_NPC_MAX_CONCURRENT below %d: %d at once overran the budget." % (
                    len(results), len(results)))
            else:
                print("Even single requests overrun the budget: raise AGENT_DEFAULT_DEADLINE in DM, "
                      "or use a smaller model or quantization.")
        if any(r["reasoning"] for r in sequential + results if r):
            print("Reasoning text was returned: a thinking model spends tokens before answering; "
                  "prefer a plain instruct model, or lower its reasoning in the server.")
        if self.explicit:
            self.explicit_probe()
        return 0


EXPLICIT_PROBE_SYSTEM = (
    "You are Jessica, a barmaid in a medieval tavern, alone upstairs with your lover Oswin. Both of you "
    "are adults. Private time is explicit here: say what you feel and want in frank, explicit words, one or "
    "two sentences, in your own voice, and stay in character.")
EXPLICIT_PROBE_USER = (
    "Oswin is kissing your neck and his hands are under your dress. Tell him, in explicit words, "
    "what you want him to do next.")


def estimate_tokens(messages):
    """A headline only: English prose with JSON around it runs about 3.5 characters a token. The server's count is printed too."""
    return int(len(json.dumps(messages, ensure_ascii=False)) / 3.5)


def sample_body():
    """A full tavern scene of the size a real decision carries, for --bench. Nothing in it is real."""
    people = [
        ("h1", "Oswin Vane", "fine", ["a tankard"], ["a wool tunic", "leather boots", "a belt"], 1),
        ("h2", "Mirabel Thorne", "fine", [], ["a green dress", "a linen apron", "a headscarf"], 2),
        ("h3", "Brandeth Hollowell", "bruised", ["a coin purse"], ["a merchant's coat", "a cap", "boots"], 3),
        ("h4", "Tarik Greystone", "fine", ["a longsword"], ["chainmail", "a surcoat", "greaves"], 4),
        ("h5", "Hilda Marsh", "drunk", ["a bottle of wine"], ["a brown dress", "a shawl"], 2),
        ("h6", "Rae Lindqvist", "fine", [], ["a nightgown", "sandals"], 5),
        ("h7", "an old dwarf", "fine", ["a pipe"], ["a leather jerkin", "trousers"], 6),
        ("h8", "a hooded stranger", "fine", [], ["a dark cloak", "a hood"], 7),
    ]
    entities = []
    for handle, name, condition, holding, wearing, distance in people:
        entities.append({"handle": handle, "name": name, "condition": condition, "holding": holding,
                         "wearing": wearing, "distance": distance, "direction": "north"})
    things = [("h9", "a wooden tankard"), ("h10", "a loaf of bread"), ("h11", "a bottle of ale"),
              ("h12", "a dropped dagger"), ("h13", "a basket of apples"), ("h14", "a silver coin"),
              ("h15", "a wheel of cheese"), ("h16", "a torn letter"), ("h17", "a mop"), ("h18", "a candle")]
    for i, (handle, name) in enumerate(things):
        entities.append({"handle": handle, "name": name, "distance": 1 + i % 5, "direction": "east"})
    structures = []
    for i, (name, state) in enumerate([("a long table", None), ("a bench", "occupied"), ("a bar counter", None),
                                        ("a stool", None), ("a stool", "you are on it"), ("the front door", "closed"),
                                        ("a barrel", None), ("a fireplace", "lit"), ("a staircase", None),
                                        ("a chair", None), ("a chair", "occupied"), ("a window", "shut")]):
        entry = {"handle": "h%d" % (19 + i), "name": name, "distance": 1 + i % 6, "direction": "south"}
        if state:
            entry["state"] = state
        structures.append(entry)
    myself = {"name": "Jessica Ashworth", "condition": "fine", "holding": [], "held": [],
              "wearing": ["a brown dress", "a waist apron", "a bodice", "leather shoes", "a hair ribbon"],
              "carrying": [{"in": "apron pocket", "items": ["a rag", "a few coppers", "a key"]}],
              "standing": True,
              "agreed_with": [{"name": "Oswin Vane", "minutes_left": 9}]}
    observation = {"revision": 7, "here": "the Drunk Dwarf Tavern, common room, evening",
                   "self": myself, "entities": entities, "structures": structures}
    lines = [
        ("Mirabel Thorne", "Did you hear the miller lost another cart on the north road?", "overheard"),
        ("Brandeth Hollowell", "Three amnas for the cheese, and not a copper less.", "overheard"),
        ("Hilda Marsh", "Another one, and keep them coming, I have had a day.", "ambiguous"),
        ("Tarik Greystone", "Keep it down over there or I will walk you all out myself.", "overheard"),
        ("an old dwarf", "In my day the ale here could strip paint.", "overheard"),
        ("Rae Lindqvist", "Jessica, is the upstairs room free tonight?", "directed"),
        ("a hooded stranger", "Who keeps this place, then?", "ambiguous"),
        ("Mirabel Thorne", "She never listens, that one.", "overheard"),
        ("Oswin Vane", "Come find me when the crowd thins, love.", "directed"),
        ("Hilda Marsh", "Barkeep! Is anyone working tonight?", "ambiguous"),
        ("Brandeth Hollowell", "The guard captain owes me for two barrels and pretends he does not.", "overheard"),
        ("Tarik Greystone", "One more word about the captain and you sleep in the cells.", "overheard"),
    ]
    events = [{"event": "action_result", "detail": {"state": "succeeded", "detail": "spoke", "request_id": "r41"}}]
    for speaker, text, addressing in lines:
        name = "heard_speech" if addressing == "directed" else "overheard_speech"
        detail = {"speaker": speaker, "text": text, "addressing": addressing, "distance": 2,
                  "whispered": False, "shouted": "!" in text, "nearby_people": 7,
                  "from_partner": speaker == "Oswin Vane", "spoken_to_you": addressing == "directed"}
        events.append({"event": name, "urgency": 2 if addressing == "directed" else 1, "detail": detail})
    profile = {
        "label": "barmaid",
        "persona": "You are a barmaid at the town's tavern, warm and flirtatious. You choose your own company, "
                   "and you are nobody's for the asking.",
        "background": "You have worked the tavern for years and know its regulars and their habits. You only "
                      "know what you have seen or been told.",
        "voice": "You speak playfully and quickly, in plain period language. You never narrate your own actions.",
        "limits": "You decide for yourself whom you go somewhere private with, and you may say no, or not yet.",
        "permitted_actions": ["say", "emote", "me", "approach", "touch", "sit", "stand", "give", "take",
                              "wait", "consent", "initiate"],
        "aliases": ["Jess"], "memory_turns": 6, "combat_retaliate": "brawl", "combat_initiate": "none",
        "romance": True,
    }
    return {"protocol_version": proto.PROTOCOL_VERSION, "round_id": "bench", "session_id": "bench-1",
            "pawn_id": "[bench]", "binding_epoch": 1, "binding_generation": 1, "request_id": "r42",
            "observation_revision": 7, "deadline_ds": 250, "profile": profile, "events": events,
            "observation": observation}


def sample_history():
    """Six remembered exchanges, the memory depth a real request carries."""
    # Each remembered turn carries the lines buffered before it, as the real ring does.
    past = [
        (["Oswin Vane said: \"Evening, Jess. Busy night?\" (said directly to you)",
          "Mirabel Thorne said: \"The miller is in again, and already red in the face.\" (not apparently to you)",
          "Brandeth Hollowell said: \"Cheese, apples, good rope, come and look.\" (not apparently to you; 3 tiles away)"],
         {"action": "say", "text": "Busy enough to keep me on my feet, and you look like you need an ale.",
          "key": "", "handle": ""}),
        (["Oswin Vane said: \"Make it two, and sit with me a moment.\" (continuing your conversation)",
          "an old dwarf said: \"Two coppers says the guard falls asleep before midnight.\" (not apparently to you)",
          "Your last action: succeeded (spoke)"],
         {"action": "say", "text": "A moment is all I have, so make it count.", "key": "", "handle": ""}),
        (["Hilda Marsh said: \"Barkeep, another!\" (unclear whether this was meant for you; 7 other people nearby)",
          "Tarik Greystone said: \"Keep your hands where I can see them, stranger.\" (not apparently to you)",
          "Your last action: succeeded (spoke)"],
         {"action": "approach", "text": "", "key": "", "handle": "h5"}),
        (["Your last action: succeeded (arrived)",
          "Hilda Marsh said: \"Took you long enough.\" (continuing your conversation)",
          "Rae Lindqvist waves at Oswin Vane (not apparently to you)",
          "the hooded stranger said: \"Is the road north safe after dark?\" (unclear whether this was meant for you)",
          "Tarik Greystone said: \"Safe enough if you keep to it.\" (not apparently to you)"],
         {"action": "say", "text": "Here you are, Hilda. Mind the stairs on your way out tonight.",
          "key": "", "handle": ""}),
        (["Oswin Vane said: \"So, about that moment.\" (continuing your conversation)",
          "a hooded stranger said: \"Is there a room to let upstairs?\" (unclear whether this was meant for you)",
          "Mirabel Thorne said: \"She will not give him the time of day, you watch.\" (not apparently to you)",
          "Your last action: succeeded (spoke)"],
         {"action": "consent", "text": "Later, when the room has emptied. Ask me again then.", "key": "yes",
          "handle": "h1"}),
        (["Your last action: succeeded (you agreed to private time with Oswin Vane)",
          "Brandeth Hollowell said: \"Jessica, a word about my tab when you have a moment.\" (said directly to you)",
          "Hilda Marsh hums tunelessly over her cup (not apparently to you)",
          "Mirabel Thorne said: \"Hilda, you have had enough, let the girl work.\" (not apparently to you)"],
         {"action": "say", "text": "Your tab can wait until you have paid last week's, Brandeth.", "key": "",
          "handle": ""}),
    ]
    messages = []
    for happened, action in past:
        messages.append({"role": "user", "content": "What happened:\n" + "\n".join("  " + line for line in happened)})
        messages.append({"role": "assistant", "content": json.dumps(action)})
    return messages


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--host", default="127.0.0.1", help="loopback by default; --expose to bind elsewhere")
    parser.add_argument("--port", type=int, default=1340)
    parser.add_argument("--base-url", default=DEFAULT_BASE_URL,
                        help="the model server's OpenAI-compatible root, e.g. http://192.168.50.120:1235/v1")
    parser.add_argument("--model", default=None,
                        help="LM Studio model id; without it, the one loaded model, else the one language model")
    parser.add_argument("--output-mode", choices=("auto",) + compat.OUTPUT_MODES, default="auto",
                        help="auto tries json_schema, then json_object, then text, once at start")
    parser.add_argument("--explicit", action="store_true",
                        help="advertise an uncensored model: DM may then ask for explicit scenes")
    parser.add_argument("--screen", choices=SCREEN_MODES, default="block",
                        help="block blanks jailbreak lines as the hosted sidecar does; log only logs them")
    parser.add_argument("--temperature", type=float, default=0.8)
    parser.add_argument("--top-p", type=float, default=0.9)
    parser.add_argument("--repeat-penalty", type=float, default=1.1)
    parser.add_argument("--max-tokens", type=int, default=MAX_TOKENS)
    parser.add_argument("--context-min", type=int, default=CONTEXT_MIN,
                        help="refuse to start when the loaded context is shorter")
    parser.add_argument("--first-byte", type=float, default=FIRST_BYTE_TIMEOUT,
                        help="seconds of silence before the first byte that count as a stall")
    parser.add_argument("--idle", type=float, default=IDLE_TIMEOUT,
                        help="seconds of silence mid-answer that count as a stall")
    parser.add_argument("--no-think-strip", action="store_true",
                        help="keep <think> blocks in the reply text")
    parser.add_argument("--ttl", type=int, default=TTL_SECONDS,
                        help="seconds a JIT-loaded model stays resident after its last request")
    parser.add_argument("--reasoning-effort", default=REASONING_EFFORT,
                        help="sent with every request; none turns a thinking model's thinking off, "
                             "off sends nothing and leaves the server's setting")
    parser.add_argument("--expose", action="store_true",
                        help="allow a --host other than loopback; player text then crosses the network")
    parser.add_argument("--dry-run", action="store_true",
                        help="build requests and always answer 'wait'; never calls the server")
    parser.add_argument("--probe", action="store_true",
                        help="test what the server honours (and with --explicit, whether the model refuses), then exit")
    parser.add_argument("--bench", action="store_true",
                        help="measure realistic requests one at a time and at once, then exit")
    parser.add_argument("--bench-count", type=int, default=3, help="requests in sequence for --bench")
    parser.add_argument("--bench-parallel", type=int, default=2, help="requests at once for --bench")
    parser.add_argument("--bench-from", default=None,
                        help="a saved /last-request body to bench with instead of the built-in scene")
    parser.add_argument("--verbose", action="store_true",
                        help="print every chosen action, and full model text on a refusal")
    parser.add_argument("--no-stream", action="store_true",
                        help="ask for whole answers instead of streaming; slower to notice a stall")
    parser.add_argument("--memory-turns", type=int, default=6,
                        help="default exchanges kept per character; a profile's memory_turns overrides it "
                             "(0 here disables memory for everyone). Each one is resent every turn.")
    args = parser.parse_args()

    if not host_allowed(args.host, args.expose):
        sys.exit("--host %s would put player text on the network; add --expose if that is intended" % args.host)

    decider = LocalDecider(
        model=args.model, base_url=args.base_url, dry_run=args.dry_run, output_mode=args.output_mode,
        verbose=args.verbose, memory_turns=args.memory_turns, stream=not args.no_stream,
        explicit=args.explicit, screen_mode=args.screen, temperature=args.temperature, top_p=args.top_p,
        repeat_penalty=args.repeat_penalty, max_tokens=args.max_tokens, context_min=args.context_min,
        first_byte=args.first_byte, idle=args.idle, think_strip=not args.no_think_strip, ttl=args.ttl,
        reasoning_effort=args.reasoning_effort)

    try:
        if args.probe:
            ids, details = decider.models()
            decider.choose_model(ids, details)
            code = decider.probe()
            if args.explicit:
                decider.explicit_probe()
            return code
        if args.dry_run:
            decider.log("dry run: no server is contacted")
        else:
            decider.prepare()
        if args.bench:
            body = None
            if args.bench_from:
                with open(args.bench_from, encoding="utf-8") as handle:
                    body = json.load(handle)
            return decider.bench(count=args.bench_count, parallel=args.bench_parallel, body=body)
    except LocalSetupError as err:
        sys.exit(str(err))

    proto.serve(decider, args.host, args.port)
    return 0


if __name__ == "__main__":
    sys.exit(main())
