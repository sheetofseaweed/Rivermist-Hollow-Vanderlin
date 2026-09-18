# Language-server diagnostics for agents

Run `python tools/dm_diagnostics.py` from the repository. Codex, Claude Code,
and other harnesses with shell access can use this same command. No running
editor, MCP service, API key, or Python package installation is required.

The command starts a separate instance of the installed VS Code DreamMaker
language server, initializes the project, collects `publishDiagnostics`
notifications, and waits for SpacemanDMM's idle status before shutting down.
It uses the repository's `SpacemanDMM.toml` (including DreamChecker settings).
It checks saved files, not live or unsaved editor buffers.

```powershell
python tools/dm_diagnostics.py
python tools/dm_diagnostics.py --json
python tools/dm_diagnostics.py --root 'F:\path\to\another-repo'
python tools/dm_diagnostics.py --server 'C:\path\to\dm-langserver.exe' --timeout 300
```

Server discovery: `--server`, then `DM_LANGSERVER`, then the most recently
modified server binary in the standard Windows VS Code extension directory,
then `dm-langserver` on PATH. Set an explicit path if using a custom VS Code
server override or several extension installations.

Text positions are one-based; JSON preserves LSP's zero-based ranges and full
diagnostics, including related information. Exit codes: 0 = no errors,
1 = errors found, 2 = tool failure or timeout. Hints and warnings are printed
but do not produce exit code 1. Output is fresh on each invocation and no report
is cached. Redirect `--json` output when a persistent report is needed.

`AGENTS.md`, `CLAUDE.md`, and the navigation entrypoint instruct agents to run
the check after DM edits. Other harnesses must read those instructions or add
this command to their validation workflow; this does not inject diagnostics
automatically into an already-running agent or expose VS Code's Problems panel.

## Debugger compatibility checked on 2026-09-13

The installed extension was `platymuus.dm-langclient` 0.2.6, with language
server `1.11.0+38` (b9212f8, 2026-01-28) bundling auxtools 2.3.6.
BYOND and `dependencies.sh` use 516.1687. The prior repository pin was 516.1661
(changed by bd0bef8c37).

[Auxtools 2.3.7](https://github.com/willox/auxtools/releases/tag/v2.3.7)
explicitly adds 516.1686/1687 support and fixes breakpoint handling around
`sin`, `cos`, `tan`, and `ispointer`. Prefer that DLL over an engine rollback.
VS Code supports the user setting `dreammaker.debugServerDll` for a DLL override.
The official Windows DLL SHA-256 is
`b188999ac58a0e0171b015c39a403ab7da2f37ddb8ac3817a078f5bce02a8be7`.

A temporary minimal world compiled and ran on 516.1687: the installed 2.3.6
DLL returned `FAILED (Couldn't find to_string)` from `auxtools_init`; the
checksum-verified 2.3.7 DLL returned `SUCCESS`. This verifies initialization,
not an interactive VS Code breakpoint session. On this machine the new DLL
is under `%LOCALAPPDATA%/BYOND-tools/auxtools-2.3.7/`, and VS Code's user
`dreammaker.debugServerDll` setting points there. The previous user settings
were backed up alongside `settings.json` as `settings.json.byond-debugger-20260913.bak`.

[SpacemanDMM suite 1.11](https://github.com/SpaceManiac/SpacemanDMM/releases/tag/suite-1.11)
supports BYOND 516 syntax; language parsing is separate from auxtools' runtime
compatibility. There is no need to downgrade the language server for this fix.
