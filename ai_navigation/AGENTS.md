# Repository Agent Guide

This repository is meant to be handed to agents after a separate goal statement from the user.

Terminology note:

- `AI mapping` or `navigation layer` means the repository-orientation docs in `ai_navigation/` plus this file.
- It does not mean in-game map files, `_maps/**`, `code/modules/mapping/**`, or `SSmapping`.

This file is the `Guided Start` entrypoint, not the cheapest default bootstrap.

For ordinary work, `ai_navigation/router.md` is cheaper.
For refreshes and migrations, `ai_navigation/update_policy.md` is the correct entrypoint.

The `ai_navigation/` navigation layer is a routing aid, not a source of truth. It may lag behind the codebase by up to one monthly manual refresh cycle. Use it to localize work quickly, then verify against source files before making conclusions or edits. If the navigation layer and code disagree, trust the code and report the mismatch.

Recommended guided handoff pattern:

1. First message: the goal.
2. Second message: this repository and its guidance.

## Bootstrap

Use this file only when `Guided Start` is actually needed.

1. Open `ai_navigation/router.md`.
2. Choose exactly 1 helper file.
3. Open up to 2 source files.
4. Check the same branch in `modular_rmh`.
5. Escalate only if unresolved.

Do not start with a full repository scan if the navigation layer already narrows the task.
Before edits, classify the planned change with `ai_navigation/human_checking.md`.
Do not edit medium-risk, high-risk, or ambiguous-scope changes until the human approves the intended blast radius.
For new content or mechanics, define who uses it and how often first; then prefer the narrowest existing host and cheapest trigger surface before introducing components, global hooks, or broad type coverage.
If a whole process loop or effect family freezes without runtimes, sweep for blocking calls before blaming load.
If the owner is known but the cause is still unclear, use `ai_navigation/failure_modes.md` to classify the break mode before guessing.
If the task is to refresh the navigation layer or migrate it to another codebase, use `ai_navigation/update_policy.md` before planning the rebuild.

## If You Need More

- startup mode selection: `ai_navigation/start_modes.md`
- task-shape to startup routing matrix: `ai_navigation/start_matrix.md`
- human developer onboarding: `ai_navigation/DEVELOPER_GUIDE.md`
- task framing: `ai_navigation/task_templates.md`
- navigation-layer refresh and migration rules: `ai_navigation/update_policy.md`
- human approval and risk gates: `ai_navigation/human_checking.md`
- content-first implementation rules: `ai_navigation/content_creation.md`
- content feature decomposition: `ai_navigation/content_breakdown.md`
- content implementation archetypes: `ai_navigation/content_patterns.md`
- signal routing and DCS hotspots: `ai_navigation/signal_map.md`
- spell signal contract and lifecycle: `ai_navigation/spell_signal_map.md`
- combat signal contract and hit routing: `ai_navigation/combat_signal_map.md`
- doll movement signal contract and moveloops: `ai_navigation/movement_signal_map.md`
- core proc families and entry hooks: `ai_navigation/core_procs.md`
- process-chain hazards: `ai_navigation/processing_hazards.md`
- subsystem/process failure classification: `ai_navigation/failure_modes.md`
- larger system map: `ai_navigation/system_map.md`
- runtime ownership: `ai_navigation/subsystem_map.md`
- architecture/layers: `ai_navigation/architecture.md`
- deep inheritance: `ai_navigation/type_tree.md`
