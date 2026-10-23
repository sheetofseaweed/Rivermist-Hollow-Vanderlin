#!/usr/bin/env python3
"""codex.sale sidecar for the agent NPC protocol.

Speaks the same wire protocol as fake_sidecar.py, claude_sidecar.py and
local_sidecar.py, so DM cannot tell any of them apart. Only this file knows
the provider exists.

    set CODEX_SALE_API_KEY=...            (cmd, this window only)
    python tools/agent_sidecar/codex_sale_sidecar.py --port 1340

Find out what the endpoint actually supports before relying on it. One tiny
call per mode, and it prints which ones the provider accepted:

    python tools/agent_sidecar/codex_sale_sidecar.py --probe

Check the prompt without spending anything:

    python tools/agent_sidecar/codex_sale_sidecar.py --dry-run --port 1340

The transport lives in openai_compat.py, shared with the local sidecar:
streaming with its stall phases, retries, the output-mode negotiation, reply
parsing and the tally. This file keeps what is codex.sale's own: the key, the
URL, the model, and a retry policy for a hosted provider whose stalls are
usually the network's. Stdlib only, no pip install.
"""

import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import agent_protocol as proto
import openai_compat as compat

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
RETRY_STATUSES = compat.RETRY_STATUSES
SUMMARY_EVERY = compat.SUMMARY_EVERY
OUTPUT_MODES = compat.OUTPUT_MODES

# The shared pieces, under the names this module has always had.
Tally = compat.Tally
set_read_timeout = compat.set_read_timeout
response_format_for = compat.response_format_for
next_mode = compat.next_mode
short_error = compat.short_error
probe_honoured = compat.probe_honoured


def post_json(url, payload, api_key, timeout=REQUEST_TIMEOUT):
    """Returns (status, parsed_body_or_text). Never raises on an HTTP error."""
    return compat.post_json(url, payload, compat.json_headers(compat.bearer(api_key)), timeout)


def post_stream(url, payload, api_key, budget, stamps=None):
    """Stream a chat completion within budget seconds, with this provider's stall thresholds."""
    return compat.post_stream(url, payload, compat.json_headers(compat.bearer(api_key)), budget,
                              FIRST_BYTE_TIMEOUT, IDLE_TIMEOUT, stamps)


def get_json(url, api_key, timeout=REQUEST_TIMEOUT):
    return compat.get_json(url, compat.json_headers(compat.bearer(api_key)), timeout)


class CodexSaleDecider(compat.OpenAICompatDecider):
    name = "codex-sale"
    request_timeout = REQUEST_TIMEOUT
    max_tokens = MAX_TOKENS

    # Read from the module each time, so a test can shorten them.
    first_byte_timeout = property(lambda self: FIRST_BYTE_TIMEOUT)
    idle_timeout = property(lambda self: IDLE_TIMEOUT)
    min_retry_seconds = property(lambda self: MIN_RETRY_SECONDS)
    max_attempts = property(lambda self: MAX_ATTEMPTS)
    summary_every = property(lambda self: SUMMARY_EVERY)

    def __init__(self, model=DEFAULT_MODEL, dry_run=False, output_mode="auto",
                 reasoning_effort=None, base_url=BASE_URL, verbose=False, memory_turns=6, stream=True):
        super().__init__(model=model, base_url=base_url, dry_run=dry_run, output_mode=output_mode,
                         verbose=verbose, memory_turns=memory_turns, stream=stream)
        self.reasoning_effort = reasoning_effort
        self.api_key = os.environ.get(KEY_ENV_VAR)
        if not dry_run and not self.api_key:
            sys.exit("%s is not set in this environment." % KEY_ENV_VAR)

    def auth_headers(self):
        return compat.bearer(self.api_key)

    def extra_request_fields(self):
        return {"reasoning_effort": self.reasoning_effort} if self.reasoning_effort else {}


def probe(model, base_url):
    """One tiny call per output mode, so capability is measured not assumed."""
    return CodexSaleDecider(model=model, base_url=base_url).probe()


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
