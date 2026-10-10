#!/usr/bin/env python3
"""codex.sale sidecar for the agent NPC protocol.

Speaks the same wire protocol as fake_sidecar.py and claude_sidecar.py, so DM
cannot tell any of them apart. Only this file knows the provider exists.

    set CODEX_SALE_API_KEY=...            (cmd, this window only)
    python tools/agent_sidecar/codex_sale_sidecar.py --port 1340

Find out what the endpoint actually supports before relying on it. One tiny
call per mode, and it prints which ones the provider accepted:

    python tools/agent_sidecar/codex_sale_sidecar.py --probe

Check the prompt without spending anything:

    python tools/agent_sidecar/codex_sale_sidecar.py --dry-run --port 1340

Stdlib only, no pip install. The provider is OpenAI-compatible, and raw HTTP
keeps error bodies visible - which matters for an endpoint whose exact feature
support is not documented anywhere public.

Structured output is negotiated, not assumed. The adapter tries json_schema,
falls back to json_object, then to plain text with the shape described in the
prompt. Whatever works first is remembered for the rest of the run.

Every log line carries the clock time. Every 20 requests, and on Ctrl+C, a
tally follows: answers on the first try, after a retry, lost, and why tries failed.
"""

import argparse
import collections
import http.client
import json
import os
import statistics
import sys
import threading
import time
import urllib.error
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import agent_protocol as proto

KEY_ENV_VAR = "CODEX_SALE_API_KEY"
BASE_URL = "https://codex.sale/v1"
DEFAULT_MODEL = "gpt-5.6-luna"
REQUEST_TIMEOUT = 30
MAX_TOKENS = 2048

# Streamed, a healthy answer starts within two seconds (measured 2026-10-03). Silence this long is a stall.
FIRST_BYTE_TIMEOUT = 6.0
# Longest quiet spell allowed after that, while the model reasons or writes.
IDLE_TIMEOUT = 10.0
# A retry with less time left than this could not finish before DM gives up anyway.
MIN_RETRY_SECONDS = 6.0
MAX_ATTEMPTS = 3
# Provider-side hiccups worth another try, alongside stalls and failed connections.
RETRY_STATUSES = (500, 502, 503, 504)
# The tally is logged after this many requests, and again when the sidecar stops.
SUMMARY_EVERY = 20

# Tried in order. The first the provider accepts is reused for the run.
OUTPUT_MODES = ("json_schema", "json_object", "text")


def post_json(url, payload, api_key, timeout=REQUEST_TIMEOUT):
    """Returns (status, parsed_body_or_text). Never raises on an HTTP error."""
    request = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "Authorization": "Bearer %s" % api_key,
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            raw = response.read().decode("utf-8", "replace")
            try:
                return response.status, json.loads(raw)
            except ValueError:
                return response.status, raw
    except urllib.error.HTTPError as err:
        raw = err.read().decode("utf-8", "replace")
        try:
            return err.code, json.loads(raw)
        except ValueError:
            return err.code, raw
    except urllib.error.URLError as err:
        return 0, "could not reach %s (%s)" % (url, err.reason)
    except (OSError, http.client.HTTPException) as err:
        # A failure after the connection opened, such as a read timeout, arrives bare instead of as a URLError.
        return 0, "no reply from %s (%s)" % (url, err)


def set_read_timeout(response, seconds):
    """Change an open response's read timeout. Python has no public way; this reaches the socket urllib opened."""
    sock = getattr(getattr(getattr(response, "fp", None), "raw", None), "_sock", None)
    if sock is not None:
        sock.settimeout(max(0.1, seconds))


class _StampedConnection:
    """Notes when the connection is open, TLS included. A stall after that is the provider's, not the network's."""

    def __init__(self, *args, stamps=None, **kwargs):
        super().__init__(*args, **kwargs)
        self.stamps = stamps

    def connect(self):
        super().connect()
        if self.stamps is not None:
            self.stamps["connected"] = time.monotonic()


class _StampedHTTPConnection(_StampedConnection, http.client.HTTPConnection):
    pass


class _StampedHTTPSConnection(_StampedConnection, http.client.HTTPSConnection):
    pass


class _StampingHandler(urllib.request.HTTPHandler, urllib.request.HTTPSHandler):
    """Opens http and https through the stamped connections. Everything else, proxies included, stays urllib's own."""

    def __init__(self, stamps):
        super().__init__()
        self.stamps = stamps

    def http_open(self, req):
        return self.do_open(_StampedHTTPConnection, req, stamps=self.stamps)

    def https_open(self, req):
        return self.do_open(_StampedHTTPSConnection, req, stamps=self.stamps)


def post_stream(url, payload, api_key, budget, stamps=None):
    """Stream a chat completion within budget seconds. Returns (status, unstreamed-shaped body, phase reached)."""
    # Unstreamed, a stall looks like a slow answer until the timeout. Streamed, it shows in seconds, in time to retry.
    deadline = time.monotonic() + budget
    stamps = {} if stamps is None else stamps
    payload = dict(payload, stream=True, stream_options={"include_usage": True})
    request = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "Authorization": "Bearer %s" % api_key,
        },
        method="POST",
    )
    opener = urllib.request.build_opener(_StampingHandler(stamps))
    phase = "connect"
    try:
        with opener.open(request, timeout=min(FIRST_BYTE_TIMEOUT, budget)) as response:
            phase = "waiting"
            content, reasoning, finish, usage = [], [], None, None
            while True:
                left = deadline - time.monotonic()
                if left <= 0:
                    return 0, "no complete answer within %.0fs" % budget, phase
                set_read_timeout(response, min(IDLE_TIMEOUT, left))
                line = response.readline()
                if not line:
                    break
                text = line.decode("utf-8", "replace").strip()
                if not text.startswith("data:"):
                    continue
                data = text[5:].strip()
                if data == "[DONE]":
                    break
                try:
                    chunk = json.loads(data)
                except ValueError:
                    continue
                if not isinstance(chunk, dict):
                    continue
                if chunk.get("error"):
                    # Reported inside a 200 stream by some providers. Treated as the server error it is.
                    return 500, chunk, phase
                usage = chunk.get("usage") or usage
                for choice in chunk.get("choices") or []:
                    delta = choice.get("delta") or {}
                    if isinstance(delta.get("content"), str) and delta["content"]:
                        content.append(delta["content"])
                        phase = "answering"
                    for field in ("reasoning_content", "reasoning"):
                        if isinstance(delta.get(field), str):
                            reasoning.append(delta[field])
                    finish = choice.get("finish_reason") or finish
            message = {"content": "".join(content)}
            if reasoning:
                message["reasoning_content"] = "".join(reasoning)
            return 200, {"choices": [{"message": message, "finish_reason": finish}],
                         "usage": usage or {}}, "done"
    except urllib.error.HTTPError as err:
        raw = err.read().decode("utf-8", "replace")
        try:
            return err.code, json.loads(raw), "done"
        except ValueError:
            return err.code, raw, "done"
    except (OSError, http.client.HTTPException) as err:
        # urllib wraps failures while connecting or sending in a URLError; later ones arrive bare.
        reason = err.reason if isinstance(err, urllib.error.URLError) else err
        if phase == "connect" and "connected" in stamps:
            phase = "sent"
        if isinstance(reason, TimeoutError):
            return 0, "timed out %s" % _PHASE_WORDS[phase], phase
        if phase == "connect":
            return 0, "could not reach %s (%s)" % (url, reason), phase
        return 0, "connection lost %s (%s)" % (_PHASE_WORDS[phase], reason), phase


_PHASE_WORDS = {
    "connect": "while connecting to the provider",
    "sent": "before the provider responded",
    "waiting": "waiting for the model to start answering",
    "answering": "while the model was answering",
}

# How each phase reads in the tally of failed tries.
_FAILED_TRY_WORDS = {
    "connect": "while connecting",
    "sent": "waiting for the provider",
    "waiting": "waiting for the model",
    "answering": "cut off mid-answer",
}


class Tally:
    """What became of each request since the sidecar started."""

    def __init__(self):
        self.lock = threading.Lock()
        self.requests = 0
        self.first_try = 0
        self.retried = 0
        self.lost = 0
        self.answer_seconds = []
        self.connect_seconds = []
        self.failed_tries = collections.Counter()

    def record(self, answered_on, seconds, connects, failures):
        """answered_on is the attempt that answered, or None. Returns True when the tally is due in the log."""
        with self.lock:
            self.requests += 1
            if answered_on == 1:
                self.first_try += 1
            elif answered_on:
                self.retried += 1
            else:
                self.lost += 1
            if answered_on:
                self.answer_seconds.append(seconds)
            self.connect_seconds.extend(connects)
            self.failed_tries.update(failures)
            return self.requests % SUMMARY_EVERY == 0

    def lines(self):
        with self.lock:
            if not self.requests:
                return []
            lines = ["tally: %d request%s, %d answered first try, %d after a retry, %d lost" % (
                self.requests, "" if self.requests == 1 else "s", self.first_try, self.retried, self.lost)]
            took = []
            if self.answer_seconds:
                took.append("answers took %s" % _spread(self.answer_seconds, "%.1fs"))
            if self.connect_seconds:
                took.append("connecting took %s" % _spread(self.connect_seconds, "%.2fs"))
            if took:
                lines.append("  " + "; ".join(took))
            if self.failed_tries:
                lines.append("  failed tries: " + ", ".join(
                    "%d %s" % (count, kind) for kind, count in self.failed_tries.most_common()))
            return lines


def _spread(values, fmt):
    """Median and worst of some durations, as in "4.1s median, 13.4s at most"."""
    return (fmt + " median, " + fmt + " at most") % (statistics.median(values), max(values))


class CodexSaleDecider(proto.Decider):
    name = "codex-sale"

    def __init__(self, model=DEFAULT_MODEL, dry_run=False, output_mode="auto",
                 reasoning_effort=None, base_url=BASE_URL, verbose=False, memory_turns=6, stream=True):
        super().__init__(dry_run=dry_run)
        self.model = model
        self.stream = stream
        self.verbose = verbose
        self.tally = Tally()
        self.memory = proto.ConversationStore(max_turns=memory_turns)
        self.base_url = base_url.rstrip("/")
        self.reasoning_effort = reasoning_effort
        self.requested_mode = output_mode
        # In auto we start optimistic and degrade on the first rejection.
        self.mode = OUTPUT_MODES[0] if output_mode == "auto" else output_mode
        self.api_key = os.environ.get(KEY_ENV_VAR)
        if not dry_run and not self.api_key:
            sys.exit("%s is not set in this environment." % KEY_ENV_VAR)

    def describe(self):
        return {"adapter": self.name, "dry_run": self.dry_run,
                "model": self.model, "output_mode": self.current_mode(),
                "base_url": self.base_url, "memory_turns": self.memory.max_turns}

    def log(self, text):
        proto.log(self.name, text)

    def summary_lines(self):
        return self.tally.lines()

    def build_turn(self, body, mode=None):
        profile = body.get("profile") or {}
        permitted = profile.get("permitted_actions") or ["wait"]
        mode = mode or self.current_mode()

        # Always describe the shape, even in json_schema mode.
        #
        # codex.sale accepts response_format json_schema without enforcing it,
        # so the model is free to answer in shorthand. A schema the server may
        # or may not honour must never be the only thing stating the format.
        user_text = proto.build_user_message(
            body.get("observation") or {}, body.get("events") or [])

        # System, then prior exchanges, then this turn. Keeping the system block
        # first and stable is also what makes it cacheable where caching exists.
        messages = [{"role": "system",
                     "content": proto.build_system(profile, describe_schema=True)}]
        messages.extend(self.memory.history(body))
        messages.append({"role": "user", "content": user_text})

        request = {
            "model": self.model,
            "max_tokens": MAX_TOKENS,
            "messages": messages,
        }
        if self.reasoning_effort:
            request["reasoning_effort"] = self.reasoning_effort
        request.update(response_format_for(mode, permitted))
        return proto.Turn(body, request=request, user_text=user_text,
                          permitted=permitted, mode=mode)

    def current_mode(self):
        """The negotiated mode. Shared, so read it under the lock."""
        with self.lock:
            return self.mode

    def demote_mode(self, from_mode):
        """Record that a mode was rejected, without clobbering a newer result."""
        with self.lock:
            if self.mode == from_mode:
                self.mode = next_mode(from_mode) or from_mode
            return self.mode

    def decide(self, body):
        """Try the current output mode, degrading on rejection.

        Each attempt builds a fresh Turn from the original body. Per-request
        values live on that Turn and never on self: the server is threaded, and
        a concurrent request would otherwise overwrite them between building the
        prompt and recording the answer.
        """
        if self.memory:
            self.memory.reconcile(body)

        # Stay inside the deadline DM sent. Outliving it means answering a
        # request nobody is listening for any more.
        deadline = time.monotonic() + proto.upstream_timeout(body, REQUEST_TIMEOUT)

        start = self.current_mode()
        modes = [start]
        if self.requested_mode == "auto":
            modes = list(OUTPUT_MODES[OUTPUT_MODES.index(start):])

        for mode in modes:
            turn = self.build_turn(body, mode=mode)
            with self.lock:
                self.last_request = turn.request
            if self.dry_run:
                return {"name": "wait"}, None, 0

            status, payload = self.call(turn.request, deadline)
            # A 400 in auto mode usually means this output mode is unsupported.
            if status == 400 and self.requested_mode == "auto" and mode != modes[-1]:
                nxt = self.demote_mode(mode)
                self.log("%s rejected (%s); trying %s" % (mode, short_error(payload), nxt))
                continue

            action, refusal, tokens = self.interpret(status, payload, turn)
            # Only successful turns are proposed. DM may still refuse the action,
            # and reconcile() drops the proposal on the next turn if it does.
            if action and self.memory:
                self.memory.record(body, turn.history_text, action)
                if self.verbose:
                    self.log("memory: %d exchanges for this character" % self.memory.depth(body))
            return action, refusal, tokens
        return None, "no output mode was attempted", 0

    def call(self, request, deadline):
        """Post the request, again if an attempt stalled before the answer began and there is time to finish."""
        url = self.base_url + "/chat/completions"
        started = time.monotonic()
        if not self.stream:
            status, payload = post_json(url, request, self.api_key, timeout=max(1.0, deadline - started))
            failed = {} if status == 200 else {"provider error %d" % status if status else "no reply, unstreamed": 1}
            self.count(1 if status == 200 else None, started, [], failed)
            return status, payload
        connects, failed = [], collections.Counter()
        for attempt in range(1, MAX_ATTEMPTS + 1):
            stamps, tried = {}, time.monotonic()
            status, payload, phase = post_stream(url, request, self.api_key, max(1.0, deadline - tried), stamps)
            connect = stamps["connected"] - tried if "connected" in stamps else None
            if connect is not None:
                connects.append(connect)
            if status == 200:
                if self.verbose:
                    self.log("answered in %.1fs (attempt %d, connected in %.2fs)" % (
                        time.monotonic() - started, attempt, connect or 0))
                self.count(attempt, started, connects, failed)
                return status, payload
            failed["provider error %d" % status if status else _FAILED_TRY_WORDS.get(phase, phase)] += 1
            stalled = (status == 0 and phase in ("connect", "sent", "waiting")) or status in RETRY_STATUSES
            left = deadline - time.monotonic()
            retry = stalled and attempt < MAX_ATTEMPTS and left >= MIN_RETRY_SECONDS
            self.log("attempt %d: %s after %.1fs%s; %s" % (
                attempt, payload if status == 0 else "provider error %d" % status,
                time.monotonic() - started, "" if connect is None else " (connected in %.2fs)" % connect,
                "retrying, %.0fs left" % left if retry else "giving up"))
            if not retry:
                self.count(None, started, connects, failed)
                return status, payload

    def count(self, answered_on, started, connects, failed):
        """Adds a finished request to the tally, and logs the tally when it is due."""
        if self.tally.record(answered_on, time.monotonic() - started, connects, failed):
            for line in self.tally.lines():
                self.log(line)

    def refuse(self, reason, tokens=0, raw=None):
        """Every refusal is logged.

        A refusal returns HTTP 200 to DM with action=null, so from the outside
        it looks exactly like a working request. Without this line the most
        likely failure mode - the model answering unusably - is invisible on
        both sides.
        """
        self.log("REFUSED: %s" % reason)
        if raw is not None:
            shown = raw if self.verbose else (raw[:300] + ("..." if len(raw) > 300 else ""))
            self.log("  model said: %r" % shown)
            if not self.verbose:
                self.log("  (run with --verbose for the full text)")
        return None, reason, tokens

    def interpret(self, status, body, turn):
        if status == 0:
            return self.refuse(str(body))
        if status == 401 or status == 403:
            return self.refuse("provider rejected the api key (%d)" % status)
        if status == 429:
            return self.refuse("rate limited by the provider")
        if status != 200:
            return self.refuse("provider error %d: %s" % (status, short_error(body)))
        if not isinstance(body, dict):
            return self.refuse("provider returned a non-JSON body")

        usage = body.get("usage") or {}
        tokens = int(usage.get("total_tokens")
                     or (usage.get("prompt_tokens", 0) + usage.get("completion_tokens", 0)))

        choices = body.get("choices") or []
        if not choices:
            return self.refuse("provider returned no choices", tokens, raw=json.dumps(body)[:2000])

        choice = choices[0]
        message = choice.get("message") or {}
        finish = choice.get("finish_reason")
        if finish == "content_filter":
            return self.refuse("provider content filter declined the turn", tokens)

        text = message.get("content")
        if isinstance(text, list):
            # Some OpenAI-compatible servers return content parts, not a string.
            text = "".join(part.get("text", "") for part in text if isinstance(part, dict))

        # Reasoning models sometimes leave content empty and put the answer in a
        # sibling field. Try the known ones before giving up.
        if not text:
            for alt in ("reasoning_content", "reasoning", "text"):
                if isinstance(message.get(alt), str) and message[alt].strip():
                    text = message[alt]
                    self.log("content was empty; used %r instead" % alt)
                    break

        if not text:
            # A reasoning model can spend the whole budget thinking and never answer.
            hint = "; its reasoning used up max_tokens, try --reasoning-effort low" if finish == "length" else ""
            return self.refuse("model returned empty content (finish_reason=%s%s)" % (finish, hint),
                               tokens, raw=json.dumps(choice)[:2000])

        permitted = turn.permitted
        parsed = proto.extract_json(text)
        if parsed is None:
            # Not JSON. Try the obvious shorthand before giving up; the game
            # server revalidates whatever comes out of this either way.
            parsed = proto.parse_loose_action(text, permitted)
            if parsed is not None:
                self.log("recovered a non-JSON reply as %r" % parsed["action"])
        if parsed is None:
            return self.refuse("model output was not json", tokens, raw=text)

        action = proto.to_dm_action(parsed)
        if action is None:
            return self.refuse("model chose an action outside its permitted list",
                               tokens, raw=text)

        if self.verbose:
            self.log("action: %s" % json.dumps(action))
        return action, None, tokens


def response_format_for(mode, permitted):
    if mode == "json_schema":
        return {"response_format": {
            "type": "json_schema",
            "json_schema": {
                "name": "npc_action",
                "strict": True,
                "schema": proto.action_schema(permitted),
            },
        }}
    if mode == "json_object":
        return {"response_format": {"type": "json_object"}}
    return {}


def next_mode(current):
    try:
        return OUTPUT_MODES[OUTPUT_MODES.index(current) + 1]
    except (ValueError, IndexError):
        return None


def short_error(body):
    if isinstance(body, dict):
        err = body.get("error")
        if isinstance(err, dict):
            return str(err.get("message") or err)[:200]
        return str(err or body)[:200]
    return str(body)[:200]


def probe_honoured(mode, content, permitted):
    """Did the reply prove the mode is enforced? Any JSON used to count, so "{}" passed as json_schema."""
    parsed = proto.extract_json(content)
    if mode == "json_schema":
        return proto.matches_action_schema(parsed, permitted)
    if mode == "json_object":
        # This mode promises an object, never a shape.
        return isinstance(parsed, dict)
    return False


def probe(model, base_url):
    """One tiny call per output mode, so capability is measured not assumed."""
    api_key = os.environ.get(KEY_ENV_VAR)
    if not api_key:
        sys.exit("%s is not set in this environment." % KEY_ENV_VAR)

    base_url = base_url.rstrip("/")
    print("probing %s with model %s\n" % (base_url, model))

    status, body = get_json(base_url + "/models", api_key)
    if status == 200 and isinstance(body, dict):
        ids = [m.get("id") for m in (body.get("data") or [])]
        print("  models endpoint: ok, %d models" % len(ids))
        if ids:
            print("    %s" % ", ".join(str(i) for i in ids[:12]))
        if model not in ids:
            print("    NOTE: %r is not in that list" % model)
    else:
        print("  models endpoint: %s %s" % (status, short_error(body)))

    permitted = ["say", "wait"]
    enforced = {}
    print("\n  Accepting a parameter is not the same as honouring it, so the prompt")
    print("  below never mentions JSON. Prose back means the schema is decorative.\n")

    for mode in OUTPUT_MODES:
        request = {
            "model": model,
            "max_tokens": 128,
            "messages": [
                {"role": "system", "content": "You are a villager."},
                {"role": "user", "content": "Greet a traveller in one short sentence."},
            ],
        }
        request.update(response_format_for(mode, permitted))
        status, body = post_json(base_url + "/chat/completions", request, api_key)

        if status != 200:
            print("  %-12s not accepted (%d: %s)" % (mode, status, short_error(body)))
            enforced[mode] = False
            continue

        content = ((body.get("choices") or [{}])[0].get("message") or {}).get("content")
        content = content if isinstance(content, str) else ""
        honoured = probe_honoured(mode, content, permitted)
        enforced[mode] = honoured
        print("  %-12s accepted | shape honoured unprompted: %s" % (
            mode, "yes" if honoured else "NO - not enforced"))
        if not honoured:
            print("               model said: %r" % content.strip()[:120])

    print("")
    if enforced.get("json_schema"):
        print("json_schema is genuinely enforced. Use: --output-mode json_schema")
        return 0
    if enforced.get("json_object"):
        print("json_schema is accepted but NOT enforced; json_object is.")
        print("Use: --output-mode json_object")
        return 0

    print("No mode enforces a shape on this endpoint.")
    print("Use: --output-mode text")
    print("The adapter states the shape in the prompt and recovers shorthand")
    print("replies, so this still works - it just relies on the model complying.")
    return 0


def get_json(url, api_key, timeout=REQUEST_TIMEOUT):
    request = urllib.request.Request(
        url, headers={"Authorization": "Bearer %s" % api_key}, method="GET")
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            raw = response.read().decode("utf-8", "replace")
            try:
                return response.status, json.loads(raw)
            except ValueError:
                return response.status, raw
    except urllib.error.HTTPError as err:
        return err.code, err.read().decode("utf-8", "replace")
    except urllib.error.URLError as err:
        return 0, str(err.reason)


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--host", default="127.0.0.1", help="loopback by default; do not expose")
    parser.add_argument("--port", type=int, default=1340)
    parser.add_argument("--model", default=DEFAULT_MODEL,
                        help="default %(default)s; glm-5.3-flash is the cheap option to try first")
    parser.add_argument("--base-url", default=BASE_URL)
    parser.add_argument("--output-mode", choices=("auto",) + OUTPUT_MODES, default="auto",
                        help="auto tries json_schema, then json_object, then text")
    parser.add_argument("--reasoning-effort", default=None,
                        help="passed through when the model supports it, e.g. low")
    parser.add_argument("--dry-run", action="store_true",
                        help="build requests and always answer 'wait'; never calls the provider")
    parser.add_argument("--probe", action="store_true",
                        help="test what the endpoint supports, then exit")
    parser.add_argument("--verbose", action="store_true",
                        help="print every chosen action, and full model text on a refusal")
    parser.add_argument("--no-stream", action="store_true",
                        help="ask for whole answers instead of streaming; slower to notice a stall, and no retry")
    parser.add_argument("--memory-turns", type=int, default=6,
                        help="default exchanges kept per character; a profile's memory_turns overrides it "
                             "(0 here disables memory for everyone). Each one is resent every turn.")
    args = parser.parse_args()

    if args.probe:
        return probe(args.model, args.base_url)

    decider = CodexSaleDecider(
        model=args.model, dry_run=args.dry_run, output_mode=args.output_mode,
        reasoning_effort=args.reasoning_effort, base_url=args.base_url,
        verbose=args.verbose, memory_turns=args.memory_turns, stream=not args.no_stream)
    decider.log("model=%s output_mode=%s memory_turns=%d stream=%s" % (
        decider.model, decider.mode, decider.memory.max_turns, "on" if decider.stream else "off"))
    proto.serve(decider, args.host, args.port)
    return 0


if __name__ == "__main__":
    sys.exit(main())
