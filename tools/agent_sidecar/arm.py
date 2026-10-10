#!/usr/bin/env python3
"""Arm a fault on the running fake sidecar, with no shell quoting to get wrong.

    python tools/agent_sidecar/arm.py stale
    python tools/agent_sidecar/arm.py delay --count 3 --delay-seconds 4
    python tools/agent_sidecar/arm.py --status

Exits non-zero if the sidecar did not confirm the fault you asked for, so this
cannot quietly arm nothing the way a mis-quoted curl can.
"""

import argparse
import json
import sys
import urllib.error
import urllib.parse
import urllib.request


def call(url, method):
    req = urllib.request.Request(url, method=method)
    try:
        with urllib.request.urlopen(req, timeout=8) as response:
            return response.status, json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as err:
        return err.code, json.loads(err.read().decode("utf-8") or "{}")
    except urllib.error.URLError as err:
        sys.exit("could not reach the sidecar at %s (%s). Is it running?" % (url, err.reason))


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("fault", nargs="?", help="fault name; omit with --status")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=1340)
    parser.add_argument("--count", type=int, default=1)
    parser.add_argument("--delay-seconds", type=float, default=2.0)
    parser.add_argument("--status", action="store_true", help="report the armed fault and exit")
    args = parser.parse_args()

    base = "http://%s:%d/control" % (args.host, args.port)

    if args.status or not args.fault:
        status, body = call(base, "GET")
        print(json.dumps(body, indent=2))
        return 0

    query = urllib.parse.urlencode({
        "fault": args.fault,
        "count": args.count,
        "delay_seconds": args.delay_seconds,
    })
    status, body = call(base + "?" + query, "POST")

    if status != 200:
        print(json.dumps(body, indent=2), file=sys.stderr)
        return 1

    armed = body.get("armed")
    if armed != args.fault:
        print("asked for %r but the sidecar armed %r" % (args.fault, armed), file=sys.stderr)
        return 1

    print("armed %s x%d" % (armed, body.get("count")))
    return 0


if __name__ == "__main__":
    sys.exit(main())
