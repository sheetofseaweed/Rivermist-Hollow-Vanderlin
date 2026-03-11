# Router

Generated on 2026-03-11. This is the primary Fast Start entrypoint for normal tasks.

Terminology note:

- `navigation layer` means the repository-orientation docs in `ai_navigation/`.
- It does not mean game maps, `_maps/**`, `code/modules/mapping/**`, or mapping subsystems.

The `ai_navigation/` navigation layer may lag behind the codebase by up to one monthly manual refresh cycle. Use it for routing, then verify in source. If the navigation layer and code disagree, trust the code.

## Start Mode

This file is for `Fast Start`.

Use `ai_navigation/AGENTS.md` only for `Guided Start`.
Use `ai_navigation/update_policy.md` for `Maintenance Start`.
If the start mode is still unclear, open `ai_navigation/start_matrix.md`.

## Dispatch

| If the task looks like | Open this helper |
|---|---|
| planned change may be broad, risky, or needs approval before edits | `ai_navigation/human_checking.md` |
| refresh the navigation layer, rebuild its docs, or migrate this repository-orientation stack to another codebase | `ai_navigation/update_policy.md` |
| new mechanic, gameplay content, or extension to an existing feature | `ai_navigation/content_creation.md` |
| content request is vague and needs delivery/base/delta/effect decomposition | `ai_navigation/content_breakdown.md` |
| content goal is clear but the implementation form is undecided | `ai_navigation/content_patterns.md` |
| signals, components, or indirect event routing seem involved | `ai_navigation/signal_map.md` |
| spell, miracle, or cooldown action behavior depends on both core procs and signals | `ai_navigation/spell_signal_map.md` |
| melee, projectile, hit, disarm, or combat chains depend on both core procs and signals | `ai_navigation/combat_signal_map.md` |
| client movement, collisions, buckle, pull, throw, or moveloop behavior depends on both core procs and signals | `ai_navigation/movement_signal_map.md` |
| you need the main proc entrypoints before searching source | `ai_navigation/core_procs.md` |
| whole subsystem or process loop freezes, hangs, or stops without runtimes | `ai_navigation/processing_hazards.md` |
| explicit failure-mode analysis after the owner is already known | `ai_navigation/failure_modes.md` |
| symptom-first bug report | `ai_navigation/debug_routes.md` |
| keyword or feature-name routing | `ai_navigation/entrypoints.md` |
| BYOND type path like `/datum/...`, `/mob/...`, `/obj/...` | `ai_navigation/type_index.md` |
| lifecycle, order, timing, scheduler, round flow | `ai_navigation/runtime_flow.md` |
| cross-system handoff or dependency question | `ai_navigation/system_dependencies.md` |
| explicit `SS*` subsystem question | `ai_navigation/subsystem_map.md` |
| unknown architecture/location question after the above | `ai_navigation/system_map.md` or `ai_navigation/architecture.md` |
| deep inheritance problem | `ai_navigation/type_tree.md` |

## Budget

- Open exactly 1 helper first.
- Then open up to 2 source files.
- Check `modular_rmh` on the same branch.
- Before editing medium/high/unknown-risk work, stop and get human approval.
- For whole-loop stalls with no runtimes, do a blocking-call sweep before blaming load.
- Escalate only if unresolved.
- For normal tasks, this file is cheaper than opening `ai_navigation/AGENTS.md` first.
