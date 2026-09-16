#!/usr/bin/env python3
"""Anthropic-backed sidecar for the agent NPC protocol.

Speaks the same wire protocol as fake_sidecar.py and codex_sale_sidecar.py, so
DM cannot tell them apart. Only this file knows Anthropic exists.

    pip install anthropic
    set AGENT_NPC_ANTHROPIC_KEY=...      (cmd, this window only)
    python tools/agent_sidecar/claude_sidecar.py --port 1340

Check the prompt without spending anything:

    python tools/agent_sidecar/claude_sidecar.py --dry-run --port 1340

Use AGENT_NPC_ANTHROPIC_KEY, not ANTHROPIC_API_KEY. Claude Code on a Pro or Max
subscription starts billing an API key as soon as ANTHROPIC_API_KEY is visible
in its environment, so setting that name machine-wide to run this sidecar would
quietly move your Claude Code usage onto pay-as-you-go. ANTHROPIC_API_KEY still
works if it is already how you authenticate.

Use `set`, not `setx`: `set` lasts for that console window only. The key is
never a command-line argument, so it cannot reach shell history or a process
listing.

Billing note: API usage is a separate product from a Claude Pro/Max
subscription, on separate pay-as-you-go billing through the Claude Console.
"""

import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import agent_protocol as proto

KEY_ENV_VAR = "AGENT_NPC_ANTHROPIC_KEY"
MODEL = "claude-opus-5"
MAX_TOKENS = 2048
# An NPC choosing one short action from a closed list is a simple task, and
# latency is felt directly by players. Effort is the lever for that, not a
# smaller model.
EFFORT = "low"
FALLBACK_MODEL = "claude-opus-4-8"
FALLBACK_BETA = "server-side-fallback-2026-06-01"


class ClaudeDecider(proto.Decider):
    name = "claude"

    def __init__(self, model=MODEL, dry_run=False, memory_turns=6):
        super().__init__(dry_run=dry_run)
        self.model = model
        self.client = None
        self.memory = proto.ConversationStore(max_turns=memory_turns)
        if dry_run:
            return

        try:
            import anthropic
        except ImportError:
            sys.exit("the anthropic package is not installed. pip install anthropic")
        self.anthropic = anthropic

        # Prefer our own variable name over ANTHROPIC_API_KEY, so running this
        # sidecar cannot move a developer's Claude Code usage onto API billing.
        scoped_key = os.environ.get(KEY_ENV_VAR)
        self.client = (anthropic.Anthropic(api_key=scoped_key) if scoped_key
                       else anthropic.Anthropic())

    def describe(self):
        return {"adapter": self.name, "dry_run": self.dry_run, "model": self.model,
                "memory_turns": self.memory.max_turns}

    def build_turn(self, body):
        profile = body.get("profile") or {}
        permitted = profile.get("permitted_actions") or ["wait"]
        user_text = proto.build_user_message(
            body.get("observation") or {}, body.get("events") or [])

        # Prior exchanges sit between the cached system block and this turn, so
        # the cacheable prefix stays first and stable.
        messages = list(self.memory.history(body))
        messages.append({"role": "user", "content": user_text})

        request = {
            "model": self.model,
            "max_tokens": MAX_TOKENS,
            "system": [{
                "type": "text",
                "text": proto.build_system(profile),
                "cache_control": {"type": "ephemeral"},
            }],
            "messages": messages,
            "output_config": {
                "effort": EFFORT,
                "format": {"type": "json_schema", "schema": proto.action_schema(permitted)},
            },
        }
        return proto.Turn(body, request=request, user_text=user_text, permitted=permitted)

    def call_provider(self, turn):
        try:
            response = self.client.beta.messages.create(
                betas=[FALLBACK_BETA],
                fallbacks=[{"model": FALLBACK_MODEL}],
                **turn.request
            )
        except self.anthropic.RateLimitError:
            return None, "rate limited", 0
        except self.anthropic.APIStatusError as err:
            return None, "api error %s" % err.status_code, 0
        except self.anthropic.APIConnectionError:
            return None, "could not reach the api", 0

        usage = response.usage
        tokens = (getattr(usage, "input_tokens", 0) or 0) + (getattr(usage, "output_tokens", 0) or 0)

        # Always check stop_reason before reading content.
        if response.stop_reason == "refusal":
            category = getattr(response.stop_details, "category", None)
            return None, "model declined (%s)" % category, tokens

        text = next((b.text for b in response.content if b.type == "text"), None)
        parsed = proto.extract_json(text)
        if parsed is None:
            return None, "model output was not json", tokens

        action = proto.to_dm_action(parsed)
        if action is None:
            return None, "model chose an action outside its permitted list", tokens
        return action, None, tokens


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--host", default="127.0.0.1", help="loopback by default; do not expose")
    parser.add_argument("--port", type=int, default=1340)
    parser.add_argument("--model", default=MODEL)
    parser.add_argument("--dry-run", action="store_true",
                        help="build requests and always answer 'wait'; never calls the API")
    parser.add_argument("--memory-turns", type=int, default=6,
                        help="exchanges of conversation kept per character (0 disables). "
                             "Each one is resent every turn, so this is a direct token cost.")
    args = parser.parse_args()

    if not args.dry_run and not (os.environ.get(KEY_ENV_VAR)
                                 or os.environ.get("ANTHROPIC_API_KEY")
                                 or os.environ.get("ANTHROPIC_AUTH_TOKEN")):
        sys.stderr.write("[claude] no key in the environment; relying on an "
                         "`ant auth login` profile\n")

    proto.serve(ClaudeDecider(model=args.model, dry_run=args.dry_run,
                              memory_turns=args.memory_turns), args.host, args.port)
    return 0


if __name__ == "__main__":
    sys.exit(main())
