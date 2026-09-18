#!/usr/bin/env python3
"""Print saved-workspace diagnostics from the same dm-langserver used by VS Code."""

import argparse
import json
import os
from pathlib import Path
import queue
import shutil
import subprocess
import sys
import tempfile
import threading
import time
from urllib.parse import urlparse
from urllib.request import url2pathname


def find_server():
    override = os.environ.get("DM_LANGSERVER")
    if override:
        return override
    candidates = list((Path.home() / ".vscode/extensions").glob(
        "platymuus.dm-langclient-*/bin/dm-langserver*.exe"
    ))
    if candidates:
        return str(max(candidates, key=lambda path: path.stat().st_mtime))
    return shutil.which("dm-langserver")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--server", default=find_server())
    parser.add_argument("--json", action="store_true", help="Emit full LSP diagnostic objects")
    parser.add_argument("--timeout", type=float, default=180)
    args = parser.parse_args()
    if not args.server:
        parser.error("Install the DreamMaker VS Code extension or set DM_LANGSERVER")
    root = args.root.resolve()
    messages = queue.Queue()
    diagnostics = {}

    with tempfile.TemporaryFile() as log:
        process = subprocess.Popen(
            [args.server], cwd=root, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            stderr=log, creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0),
        )

        def send(method, params=None, request_id=None):
            message = {"jsonrpc": "2.0", "method": method}
            if params is not None:
                message["params"] = params
            if request_id is not None:
                message["id"] = request_id
            payload = json.dumps(message).encode("utf-8")
            process.stdin.write(f"Content-Length: {len(payload)}\r\n\r\n".encode() + payload)
            process.stdin.flush()

        def read_messages():
            try:
                while True:
                    headers = {}
                    while True:
                        line = process.stdout.readline()
                        if not line:
                            raise EOFError("Language server closed stdout")
                        if line == b"\r\n":
                            break
                        key, value = line.decode().split(":", 1)
                        headers[key.lower()] = value.strip()
                    size = int(headers["content-length"])
                    payload = process.stdout.read(size)
                    if len(payload) != size:
                        raise EOFError("Incomplete language-server response")
                    messages.put(json.loads(payload))
            except Exception as error:
                messages.put(error)

        reader = threading.Thread(target=read_messages, daemon=True)
        reader.start()
        deadline = time.monotonic() + args.timeout
        busy = False
        shutting_down = False
        try:
            send("initialize", {
                "processId": os.getpid(), "rootUri": root.as_uri(),
                "capabilities": {"textDocument": {"publishDiagnostics": {"relatedInformation": True}}},
            }, 1)
            while True:
                message = messages.get(timeout=max(0.001, deadline - time.monotonic()))
                if isinstance(message, Exception):
                    raise message
                if "error" in message:
                    raise RuntimeError(message["error"])
                if message.get("id") == 1 and "result" in message:
                    send("initialized", {})
                elif message.get("id") == 2 and "result" in message:
                    send("exit")
                    process.wait(timeout=5)
                    break
                elif message.get("method") == "textDocument/publishDiagnostics":
                    params = message["params"]
                    diagnostics[params["uri"]] = params["diagnostics"]
                elif message.get("method") == "$window/status":
                    tasks = message["params"].get("tasks", [])
                    if any(task in tasks for task in ("no .dme file", "single file mode")):
                        raise RuntimeError("Language server did not load a project")
                    busy = busy or bool(tasks)
                    if busy and not tasks and not shutting_down:
                        # The shutdown response is a barrier for any parser diagnostics
                        # sent just after the idle notification (e.g. on parse failure).
                        send("shutdown", request_id=2)
                        shutting_down = True
                elif "id" in message and "method" in message:
                    raise RuntimeError(f"Unsupported server request: {message['method']}")
        except Exception as error:
            log.seek(0)
            print(log.read().decode("utf-8", errors="replace"), file=sys.stderr)
            detail = "Timed out waiting for complete diagnostics" if isinstance(error, queue.Empty) else str(error)
            print(f"Diagnostics failed: {detail}", file=sys.stderr)
            return 2
        finally:
            if process.poll() is None:
                process.kill()
                process.wait()
            reader.join(timeout=2)
            process.stdin.close()
            process.stdout.close()

    results = []
    for uri, entries in sorted(diagnostics.items()):
        # url2pathname decodes URI escaping and Windows drive letters.
        parsed = urlparse(uri)
        path = url2pathname(parsed.path)
        if parsed.netloc:
            path = "//" + parsed.netloc + path
        if Path(uri).is_absolute():
            # Some SpacemanDMM diagnostics use native paths instead of file URIs.
            path = uri
        for entry in entries:
            results.append({"file": path, "uri": uri, **entry})
    if args.json:
        print(json.dumps({"root": str(root), "server": args.server, "diagnostics": results}, indent=2))
    else:
        levels = {1: "error", 2: "warning", 3: "information", 4: "hint"}
        for entry in results:
            start = entry["range"]["start"]
            print(f"{entry['file']}:{start['line'] + 1}:{start['character'] + 1}: "
                  f"{levels.get(entry.get('severity'), 'diagnostic')}: {entry['message']}")
        print(f"{len(results)} diagnostics (saved files; {args.server})")
    return 1 if any(entry.get("severity", 1) == 1 for entry in results) else 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except OSError as error:
        print(f"Diagnostics failed: {error}", file=sys.stderr)
        sys.exit(2)
