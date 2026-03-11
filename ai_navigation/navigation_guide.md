# Navigation Guide for Future AI Agents

Use this guide to avoid rescanning the whole repository when a task can be localized quickly.

Terminology note:

- `navigation layer`, `AI mapping`, or `repository mapping` means the docs in `ai_navigation/` plus `ai_navigation/AGENTS.md`.
- It does not mean in-game map files, `_maps/**`, `code/modules/mapping/**`, or `SSmapping`.

If you are framing a new task for an agent, use `ai_navigation/task_templates.md` together with this guide.

## Start Modes

Choose one mode first:

- `Fast Start`:
  `ai_navigation/router.md` -> 1 helper -> up to 2 source files
- `Guided Start`:
  `ai_navigation/AGENTS.md` -> `ai_navigation/router.md` -> 1 helper -> up to 2 source files
- `Maintenance Start`:
  `ai_navigation/update_policy.md`

Default to `Fast Start` unless there is a clear reason to use a heavier mode.

## Escalation

After the first route, escalate only if it is still ambiguous:
   - `ai_navigation/start_modes.md`
   - `ai_navigation/start_matrix.md`
   - `ai_navigation/human_checking.md`
   - `ai_navigation/update_policy.md`
   - `ai_navigation/content_creation.md`
   - `ai_navigation/content_breakdown.md`
   - `ai_navigation/content_patterns.md`
   - `ai_navigation/signal_map.md`
   - `ai_navigation/spell_signal_map.md`
   - `ai_navigation/combat_signal_map.md`
   - `ai_navigation/movement_signal_map.md`
   - `ai_navigation/core_procs.md`
   - `ai_navigation/processing_hazards.md`
   - `ai_navigation/failure_modes.md`
   - `ai_navigation/system_map.md`
   - `ai_navigation/subsystem_map.md`
   - `ai_navigation/architecture.md`
   - `ai_navigation/type_tree.md`

## Read Budget

- Stage 1: `Fast Start` by default: `ai_navigation/router.md` + one small helper file + up to 2 source files.
- Stage 2: one more helper file or one `SS*` file + up to 2 more source files.
- Stage 3: only then open the larger navigation docs or do broader searches.

## Fast Routing Rules

- If a keyword in `ai_navigation/entrypoints.md` already matches the task, use that route before opening the larger navigation docs.
- If you know the task shape but not the best entrypoint, use `ai_navigation/start_matrix.md`.
- If the task is ordinary and localized, prefer `Fast Start` over `Guided Start`.
- If the task is broad, risky, or explicitly human-guided, switch to `ai_navigation/AGENTS.md`.
- If the task begins with a symptom, use `ai_navigation/debug_routes.md` before anything else.
- If the planned change may touch a shared branch or hot path, use `ai_navigation/human_checking.md` before editing.
- If the task is to refresh `ai_navigation/` or migrate this mapping to another codebase, use `ai_navigation/update_policy.md` before scanning broadly.
- If the task is about adding a mechanic or content, use `ai_navigation/content_creation.md` before broad architectural docs.
- If the content request is still fuzzy at the fantasy/spec level, use `ai_navigation/content_breakdown.md`.
- If the content goal is known but the implementation shape is still fuzzy, use `ai_navigation/content_patterns.md`.
- If behavior feels indirect, component-driven, or COMSIG-like, use `ai_navigation/signal_map.md`.
- If the system is spell-like and the proc lifecycle matters as much as the signals, use `ai_navigation/spell_signal_map.md`.
- If the system is combat-like and the hit chain matters as much as the signals, use `ai_navigation/combat_signal_map.md`.
- If the system is about doll movement, collisions, pulls, buckles, throws, or moveloops, use `ai_navigation/movement_signal_map.md`.
- If you need the likely hook family before searching code, use `ai_navigation/core_procs.md`.
- If the task says a whole loop froze, timers stopped, or there are no runtimes, use `ai_navigation/processing_hazards.md` before generic symptom routing.
- If the owner is already known but the exact break mode is unclear, use `ai_navigation/failure_modes.md`.
- If the task gives a BYOND type path, use `ai_navigation/type_index.md` before `ai_navigation/type_tree.md`.
- If you know the systems but not their handoff, use `ai_navigation/system_dependencies.md` before opening more source files.
- If you know the symptom is timing/order related, use `ai_navigation/runtime_flow.md` before doing a broad search.
- Use `ai_navigation/router.md` only as dispatch; do not treat it as a large reference file.
- Unknown type path: search the exact path in `ai_navigation/type_index.md`; use `ai_navigation/type_tree.md` only if inheritance depth is the issue.
- `SS*` subsystem mention: find the global in `ai_navigation/subsystem_map.md`; open the mapped file in `code/controllers/subsystem/**` and then inspect any type roots it schedules.
- Jobs, classes, spawn roles: inspect `code/modules/jobs/**`, `code/datums/migrants/**`, then `modular_rmh/code/modules/jobs/**` for RMH-specific roles and subclasses.
- Spells, actions, status effects: inspect `code/modules/spells/**`, `code/datums/status_effects/**`, `code/datums/components/**`, `code/datums/elements/**`, then the parallel RMH paths in `modular_rmh/`.
- Combat, weapons, projectiles, hit effects: inspect `ai_navigation/combat_signal_map.md`, `code/_onclick/item_attack.dm`, `code/_onclick/other_mobs.dm`, and `code/modules/projectiles/projectile.dm` before widening into weapon or mob subtypes.
- Doll movement, collisions, pulls, buckles, or automated movement: inspect `ai_navigation/movement_signal_map.md`, `code/modules/mob/mob_movement.dm`, `code/modules/mob/living/living_movement.dm`, and `code/controllers/subsystem/movement/**`.
- Sex, arousal, ERP, lewd systems: inspect `code/datums/sex/**`, `code/datums/components/arousal.dm`, then the matching mob/chat hooks and RMH lewd or horny-AI overlays.
- AI and NPC behavior: inspect `code/datums/ai/**`, then the AI-related entries in `ai_navigation/subsystem_map.md`, then any mob-specific files in `code/modules/mob/**` or `modular_rmh/code/modules/mob/**`.
- Worldgen, maps, dungeons, voyage: inspect `_maps/**`, `code/modules/mapping/**`, `code/modules/procedural_mapping/**`, and the mapping-related subsystem files (`mapping.dm`, `minor_mapping.dm`, `dungeon_generator.dm`, `voyage.dm`).
- Economy, property, regional simulation: inspect economy + treasury + property-management subsystems, then `code/datums/world_factions/**`, `code/datums/nation/**`, and `code/datums/rts/**` if the issue is strategic or settlement-related.
- UI, browser, tgui work: inspect `code/modules/tgui/**`, `code/modules/visual_ui/**`, `interface/**`, and `tgui/packages/**` together; DM and TS halves are usually paired.
- Modular behavior suspicion: after finding a core path, always check `modular_rmh` for descendants on the same type branch or late-included content that reuses the same subsystem.

## Suggested Search Patterns

- Exact type path: `rg -n "^/datum/status_effect" code modular_rmh -g "*.dm"`
- All subsystem declarations: `rg -n "^(SUBSYSTEM_DEF|PROCESSING_SUBSYSTEM_DEF|TIMER_SUBSYSTEM_DEF|MOVEMENT_SUBSYSTEM_DEF|AI_CONTROLLER_SUBSYSTEM_DEF|VERB_MANAGER_SUBSYSTEM_DEF)\(" code/controllers/subsystem -g "*.dm"`
- Any `SS*` call site: `rg -n "\bSS[A-Z][A-Za-z0-9_]*\b" code modular_rmh -g "*.dm"`
- Component hooks: `rg -n "\bAddComponent\(" code modular_rmh -g "*.dm"`
- Status effect application: `rg -n "\bapply_status_effect\(" code modular_rmh -g "*.dm"`
- Map/template references: `rg -n "map_template|map_load_mark|map_adjustment" code _maps modular_rmh -g "*.dm"`
- AI paths: `rg -n "^/datum/ai_(controller|behavior)" code modular_rmh -g "*.dm"`

## Heuristics That Save Time

- Prefer one helper file plus source files over multiple helper files in a row.
- Prefer `Fast Start` unless a heavier startup mode is justified.
- Prefer directory families over whole-repo scans: `code/datums` for logic/state, `code/modules` for feature slices, `code/game` for concrete world objects.
- If a system is content-heavy, inspect `modular_rmh` early; if it is scheduler/runtime-heavy, inspect `code/controllers` first.
- Before editing anything broad, classify risk and ask for approval if the scope is medium, high, or ambiguous.
- For navigation-layer refreshes, rebuild runtime ownership and routing layers before deep reference layers.
- For migration work, preserve the navigation model, not this repo's exact paths.
- For new content, minimize host scope first and minimize trigger frequency second.
- For new content, decompose delivery/base/delta/effect before choosing code shape.
- For new content, prefer an existing implementation pattern before designing a new abstraction.
- For indirect behavior, check signals and core proc families before doing a broad code walk.
- For spells and similar cooldown-action systems, check the spell signal contract before doing a broad DCS walk.
- For combat and hit chains, check the combat signal contract before walking individual weapons or mobs.
- For player or looped movement, check the movement signal contract before broad searches through mob code.
- If a shared subsystem silently stalls, check for blocking calls before assuming scheduler pressure.
- If ownership is clear but cause is not, classify the failure mode before tracing more code.
- When behavior feels indirect, assume signals/components are involved and search DCS hooks before tracing every proc call by hand.
- When an issue is round-start or lifecycle related, always open `code/world.dm`, `code/controllers/master.dm`, and the relevant `SS*` entry before diving into content files.
