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
"""

import argparse
import json
import os
import sys
import urllib.error
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import agent_protocol as proto

KEY_ENV_VAR = "CODEX_SALE_API_KEY"
BASE_URL = "https://codex.sale/v1"
DEFAULT_MODEL = "gpt-5.6-luna"
REQUEST_TIMEOUT = 30
MAX_TOKENS = 2048

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


class CodexSaleDecider(proto.Decider):
    name = "codex-sale"

    def __init__(self, model=DEFAULT_MODEL, dry_run=False, output_mode="auto",
                 reasoning_effort=None, base_url=BASE_URL, verbose=False, memory_turns=6):
        super().__init__(dry_run=dry_run)
        self.model = model
        self.verbose = verbose
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
        timeout = proto.upstream_timeout(body, REQUEST_TIMEOUT)

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

            status, payload = post_json(self.base_url + "/chat/completions",
                                        turn.request, self.api_key, timeout=timeout)
            # A 400 in auto mode usually means this output mode is unsupported.
            if status == 400 and self.requested_mode == "auto" and mode != modes[-1]:
                nxt = self.demote_mode(mode)
                sys.stderr.write("[codex-sale] %s rejected (%s); trying %s\n" % (
                    mode, short_error(payload), nxt))
                continue

            action, refusal, tokens = self.interpret(status, payload, turn)
            # Only successful turns are proposed. DM may still refuse the action,
            # and reconcile() drops the proposal on the next turn if it does.
            if action and self.memory:
                self.memory.record(body, turn.history_text, action)
                if self.verbose:
                    sys.stderr.write("[codex-sale] memory: %d exchanges for this character\n"
                                     % self.memory.depth(body))
            return action, refusal, tokens
        return None, "no output mode was attempted", 0

    def refuse(self, reason, tokens=0, raw=None):
        """Every refusal is logged.

        A refusal returns HTTP 200 to DM with action=null, so from the outside
        it looks exactly like a working request. Without this line the most
        likely failure mode - the model answering unusably - is invisible on
        both sides.
        """
        sys.stderr.write("[codex-sale] REFUSED: %s\n" % reason)
        if raw is not None:
            shown = raw if self.verbose else (raw[:300] + ("..." if len(raw) > 300 else ""))
            sys.stderr.write("[codex-sale]   model said: %r\n" % shown)
            if not self.verbose:
                sys.stderr.write("[codex-sale]   (run with --verbose for the full text)\n")
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
                    sys.stderr.write("[codex-sale] content was empty; used %r instead\n" % alt)
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
                sys.stderr.write("[codex-sale] recovered a non-JSON reply as %r\n" % parsed["action"])
        if parsed is None:
            return self.refuse("model output was not json", tokens, raw=text)

        action = proto.to_dm_action(parsed)
        if action is None:
            return self.refuse("model chose an action outside its permitted list",
                               tokens, raw=text)

        if self.verbose:
            sys.stderr.write("[codex-sale] action: %s\n" % json.dumps(action))
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
    parser.add_argument("--memory-turns", type=int, default=6,
                        help="default exchanges kept per character; a profile's memory_turns overrides it "
                             "(0 here disables memory for everyone). Each one is resent every turn.")
    args = parser.parse_args()

    if args.probe:
        return probe(args.model, args.base_url)

    decider = CodexSaleDecider(
        model=args.model, dry_run=args.dry_run, output_mode=args.output_mode,
        reasoning_effort=args.reasoning_effort, base_url=args.base_url,
        verbose=args.verbose, memory_turns=args.memory_turns)
    sys.stderr.write("[codex-sale] model=%s output_mode=%s memory_turns=%d\n" % (
        decider.model, decider.mode, decider.memory.max_turns))
    proto.serve(decider, args.host, args.port)
    return 0


if __name__ == "__main__":
    sys.exit(main())
