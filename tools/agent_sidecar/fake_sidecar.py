#!/usr/bin/env python3
"""Deterministic fake sidecar for the agent NPC protocol.

No model, no provider, no network egress. It exists so the DM side can be tested
against every protocol failure mode with zero spend and zero model variability.

Run:
    python tools/agent_sidecar/fake_sidecar.py --port 1340

Endpoints:
    GET  /health    readiness probe
    POST /decide    the decision endpoint SSagent_npc calls
    POST /control   arm a fault for the next N /decide calls
    GET  /control   report armed fault and request log

Faults are armed, not random. A test arms one, makes one request, and asserts
what DM did. See FAULTS for the list.

Arming a fault. Prefer the helper, which has no quoting to get wrong:

    python tools/agent_sidecar/arm.py stale

Or use query parameters, which every shell handles identically:

    curl -X POST "localhost:1340/control?fault=stale&count=1"

A JSON body also works, but note that cmd.exe does not treat ' as a quote
character, so the bash form below only works in bash/sh:

    curl -X POST localhost:1340/control -d '{"fault":"stale","count":1}'

Always check the reply says {"armed": "stale"}. A malformed body is now a 400
rather than a silent fall back to "none".
"""

import argparse
import json
import sys
import threading
import time
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

# Returned by _read_json when a body was sent but is not JSON. Distinct from {},
# which means no body at all. Silently treating garbage as empty is how a test
# harness ends up arming nothing while reporting success.
BAD_JSON = object()

PROTOCOL_VERSION = 1

FAULTS = (
    "none",       # well-formed reply for the request that was sent
    "delay",      # sleep, then reply normally; use to probe the deadline
    "silence",    # sleep well past any sane deadline
    "stale",      # reply echoing an older request's identity
    "duplicate",  # reply echoing the immediately previous request's identity
    "malformed",  # not JSON at all
    "oversized",  # valid JSON, absurd size
    "refusal",    # well-formed protocol reply carrying a model refusal
    "bad_handle", # action targets a handle that was never offered
    "http_500",   # transport-level failure
    "neg_tokens", # negative reported usage, which would credit the budget
    "stale_epoch",# identity of a previous binding for the same pawn
)


class State:
    """Armed fault plus enough request history to forge stale replies."""

    def __init__(self):
        self.lock = threading.Lock()
        self.fault = "none"
        self.remaining = 0
        self.delay_seconds = 2.0
        self.history = []  # newest last: dicts of request identity fields

    def arm(self, fault, count, delay_seconds):
        with self.lock:
            self.fault = fault
            self.remaining = count
            self.delay_seconds = delay_seconds

    def take(self):
        """Consume one armed use. Returns the fault to apply to this request."""
        with self.lock:
            if self.remaining <= 0:
                return "none", self.delay_seconds
            self.remaining -= 1
            return self.fault, self.delay_seconds

    def record(self, identity):
        with self.lock:
            self.history.append(identity)
            del self.history[:-50]

    def previous(self, offset):
        """Identity of an earlier request, or None if history is too short."""
        with self.lock:
            if len(self.history) <= offset:
                return None
            return self.history[-1 - offset]


STATE = State()


def identity_of(body):
    return {
        "protocol_version": body.get("protocol_version"),
        "round_id": body.get("round_id"),
        "session_id": body.get("session_id"),
        "pawn_id": body.get("pawn_id"),
        "binding_epoch": body.get("binding_epoch"),
        "binding_generation": body.get("binding_generation"),
        "request_id": body.get("request_id"),
        "observation_revision": body.get("observation_revision"),
    }


def first_handle(body):
    """Pick any handle the observation offered, so 'none' produces a legal action."""
    for entity in body.get("observation", {}).get("entities", []):
        handle = entity.get("handle")
        if handle:
            return handle
    return None


def decision_for(body, identity):
    """A well-formed decision. Says hello, or approaches whatever it was shown."""
    handle = first_handle(body)
    if handle:
        action = {"name": "approach", "handle": handle}
    else:
        action = {"name": "say", "text": "Well met, traveller."}
    return {"echo": identity, "action": action}


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt, *args):
        sys.stderr.write("[fake-sidecar] %s\n" % (fmt % args))

    def _send(self, code, payload, raw=False):
        body = payload if raw else json.dumps(payload).encode("utf-8")
        if isinstance(body, str):
            body = body.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _read_json(self):
        length = int(self.headers.get("Content-Length") or 0)
        if length <= 0:
            return {}
        raw = self.rfile.read(length)
        try:
            parsed = json.loads(raw.decode("utf-8"))
        except (ValueError, UnicodeDecodeError):
            return BAD_JSON
        return parsed if isinstance(parsed, dict) else BAD_JSON

    def _route(self):
        """Path without its query string."""
        return urllib.parse.urlsplit(self.path).path

    def _query(self):
        """Query params as a flat dict, so shell quoting never matters."""
        raw = urllib.parse.parse_qs(urllib.parse.urlsplit(self.path).query)
        return {k: v[0] for k, v in raw.items() if v}

    def do_GET(self):
        route = self._route()
        if route == "/health":
            self._send(200, {"ok": True, "protocol_version": PROTOCOL_VERSION})
        elif route == "/control":
            with STATE.lock:
                self._send(200, {
                    "fault": STATE.fault,
                    "remaining": STATE.remaining,
                    "delay_seconds": STATE.delay_seconds,
                    "history_depth": len(STATE.history),
                })
        else:
            self._send(404, {"error": "no such endpoint"})

    def do_POST(self):
        route = self._route()
        if route == "/control":
            return self._handle_control()
        if route == "/decide":
            return self._handle_decide()
        self._send(404, {"error": "no such endpoint"})

    def _handle_control(self):
        body = self._read_json()
        if body is BAD_JSON:
            # cmd.exe does not treat ' as a quote character, so a bash-style
            # curl arrives here wrapped in literal single quotes. Refuse loudly:
            # silently arming "none" would make every later fault test lie.
            return self._send(400, {
                "error": "request body was not JSON",
                "hint": "shell quoting; use /control?fault=stale&count=1, or arm.py",
            })

        params = self._query()
        params.update(body)

        if "fault" not in params:
            return self._send(400, {"error": "no fault given", "known": list(FAULTS)})

        fault = params["fault"]
        if fault not in FAULTS:
            return self._send(400, {"error": "unknown fault", "got": fault, "known": list(FAULTS)})

        try:
            count = int(params.get("count", 1))
            delay_seconds = float(params.get("delay_seconds", 2.0))
        except (TypeError, ValueError):
            return self._send(400, {"error": "count must be an int and delay_seconds a number"})

        STATE.arm(fault, count, delay_seconds)
        return self._send(200, {"armed": fault, "count": count})

    def _handle_decide(self):
        body = self._read_json()
        if body is BAD_JSON:
            return self._send(400, {"error": "request body was not JSON"})
        identity = identity_of(body)
        STATE.record(identity)
        fault, delay_seconds = STATE.take()

        if fault == "http_500":
            return self._send(500, {"error": "injected transport failure"})

        if fault == "malformed":
            return self._send(200, "{this is not json", raw=True)

        if fault in ("delay", "silence"):
            time.sleep(delay_seconds if fault == "delay" else max(delay_seconds, 120.0))
            fault = "none"

        if fault == "stale":
            older = STATE.previous(3) or STATE.previous(1)
            if older:
                identity = older
        elif fault == "duplicate":
            older = STATE.previous(1)
            if older:
                identity = older

        payload = decision_for(body, identity)

        if fault == "refusal":
            payload["action"] = None
            payload["refusal"] = "The assistant declined to act."
        elif fault == "bad_handle":
            payload["action"] = {"name": "approach", "handle": "h-never-offered"}
        elif fault == "oversized":
            payload["padding"] = "x" * (2 * 1024 * 1024)
        elif fault == "neg_tokens":
            payload["tokens_used"] = -100
        elif fault == "stale_epoch":
            epoch = payload["echo"].get("binding_epoch")
            payload["echo"]["binding_epoch"] = (epoch - 1) if isinstance(epoch, int) else 0

        return self._send(200, payload)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default="127.0.0.1", help="loopback by default; do not expose")
    parser.add_argument("--port", type=int, default=1340)
    args = parser.parse_args()

    server = ThreadingHTTPServer((args.host, args.port), Handler)
    sys.stderr.write("[fake-sidecar] listening on %s:%d\n" % (args.host, args.port))
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        sys.stderr.write("[fake-sidecar] stopping\n")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
