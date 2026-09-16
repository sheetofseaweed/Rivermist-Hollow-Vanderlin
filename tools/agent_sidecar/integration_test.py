#!/usr/bin/env python3
"""Run the DM-to-sidecar integration tests end to end.

Starts the fake sidecar, builds a throwaway DM project with
AGENT_NPC_INTEGRATION defined, focuses only the integration tests, runs it, and
reports. Nothing tracked by git is modified.

    python tools/agent_sidecar/integration_test.py

These tests are not part of the normal suite. They need a live sidecar, and a
test that silently passes when its dependency is missing is worse than no test,
so they are compiled out unless this harness builds them.

Note the explicit game port: DreamDaemon exits immediately and silently if the
port is taken, which it will be whenever a real server is running locally.
"""

import argparse
import json
import os
import re
import subprocess
import sys
import time

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SIDECAR_PORT = 1341          # must match AGENT_INTEGRATION_BASE in the DM file
DEFAULT_GAME_PORT = 47412
PROJECT = "agent_npc_integration"
TEST_FILE = os.path.join("code", "modules", "unit_tests", "agent_npc_integration.dm")
RESULTS = os.path.join("data", "unit_tests.json")

BYOND_CANDIDATES = [
    r"C:\Program Files (x86)\BYOND\bin",
    r"C:\Program Files\BYOND\bin",
]


def find_byond():
    for folder in BYOND_CANDIDATES:
        if os.path.isfile(os.path.join(folder, "dm.exe")):
            return folder
    sys.exit("could not find BYOND. Edit BYOND_CANDIDATES in this script.")


def focused_tests(sidecar):
    """Every /datum/unit_test in the integration file, excluding helper procs.

    The Claude sidecar has no fault-injection endpoint, so against it only the
    clean round trip is meaningful. Running the fault tests there would report
    passes that mean nothing.
    """
    with open(os.path.join(REPO, TEST_FILE), encoding="utf-8") as handle:
        found = re.findall(r"^/datum/unit_test/([a-z_0-9]+)\s*$", handle.read(), re.MULTILINE)
    names = sorted(set(n for n in found if n != "proc"))
    if not names:
        sys.exit("no integration tests found in " + TEST_FILE)
    if sidecar == "claude":
        names = [n for n in names if n == "agent_integration_valid_roundtrip"]
        if not names:
            sys.exit("the clean round-trip test is missing")
    return names


def cleanup(paths):
    for path in paths:
        try:
            os.remove(path)
        except OSError:
            pass


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--game-port", type=int, default=DEFAULT_GAME_PORT)
    parser.add_argument("--keep", action="store_true", help="keep the throwaway build")
    parser.add_argument("--sidecar", choices=["fake", "claude"], default="fake",
                        help="'claude' runs the real sidecar in dry-run: proves DM and the "
                             "Claude sidecar agree on the wire, without calling the API")
    args = parser.parse_args()

    byond = find_byond()
    os.chdir(REPO)

    names = focused_tests(args.sidecar)
    print("sidecar: %s%s" % (args.sidecar, " (dry run)" if args.sidecar == "claude" else ""))
    print("integration tests to run: %d" % len(names))

    scratch = "_integration_focus.dm"
    dme = PROJECT + ".dme"
    artifacts = [scratch, dme] + [PROJECT + ext for ext in
                                  (".dmb", ".rsc", ".int", ".dyn.rsc", ".rsc.lk", ".dyn.rsc.lk")]

    with open(scratch, "w", encoding="utf-8") as handle:
        for name in names:
            handle.write("TEST_FOCUS(/datum/unit_test/%s)\n" % name)

    with open(dme, "w", encoding="utf-8") as handle:
        handle.write("#define UNIT_TESTS\n")
        handle.write("#define AGENT_NPC_INTEGRATION\n")
        handle.write('#include "vanderlin.dme"\n')
        handle.write('#include "%s"\n' % scratch)

    if args.sidecar == "claude":
        sidecar_cmd = [sys.executable, os.path.join("tools", "agent_sidecar", "claude_sidecar.py"),
                       "--port", str(SIDECAR_PORT), "--dry-run"]
    else:
        sidecar_cmd = [sys.executable, os.path.join("tools", "agent_sidecar", "fake_sidecar.py"),
                       "--port", str(SIDECAR_PORT)]

    sidecar = subprocess.Popen(sidecar_cmd, stderr=subprocess.DEVNULL)
    time.sleep(1.5)

    try:
        if sidecar.poll() is not None:
            sys.exit("the fake sidecar exited immediately; is port %d in use?" % SIDECAR_PORT)

        print("compiling ...")
        build = subprocess.run([os.path.join(byond, "dm.exe"), dme],
                               capture_output=True, text=True)
        tail = [line for line in build.stdout.splitlines() if line.strip()][-1:]
        print("  " + (tail[0] if tail else "no compiler output"))
        if "error" in build.stdout and "0 errors" not in build.stdout:
            print(build.stdout[-3000:])
            return 1

        before = os.path.getmtime(RESULTS) if os.path.exists(RESULTS) else 0

        print("running on port %d ..." % args.game_port)
        subprocess.run([os.path.join(byond, "dreamdaemon.exe"), PROJECT + ".dmb",
                        str(args.game_port), "-close", "-trusted",
                        "-params", "log-directory=ci"],
                       capture_output=True, text=True)

        if not os.path.exists(RESULTS):
            sys.exit("no results file was written")
        after = os.path.getmtime(RESULTS)
        if after == before:
            # The classic silent failure: the port was taken, or a stale
            # DreamDaemon is holding the build, so the old json is still sitting
            # there looking like a pass.
            sys.exit("results file did not change. DreamDaemon likely never ran "
                     "(port %d in use?). Refusing to report stale results."
                     % args.game_port)

        with open(RESULTS, encoding="utf-8") as handle:
            results = json.load(handle)

        failures = [(k, v.get("message")) for k, v in results.items() if v.get("status") != 0]
        print("\n%d tests, %d failures" % (len(results), len(failures)))
        for name, message in failures:
            print("  FAIL %s" % name.split("/")[-1])
            print("       %s" % str(message).strip()[:300])
        return 1 if failures else 0
    finally:
        sidecar.terminate()
        try:
            sidecar.wait(timeout=5)
        except subprocess.TimeoutExpired:
            sidecar.kill()
        if not args.keep:
            cleanup(artifacts)
            print("cleaned up throwaway build")


if __name__ == "__main__":
    sys.exit(main())
