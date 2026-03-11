# Start Matrix

Generated on 2026-03-11. Use this file when you know the task shape but want the cheapest correct start path immediately.

## Goal

Keep the number of top-level startup modes small:

- `Fast Start`
- `Guided Start`
- `Maintenance Start`

Then choose a cheap profile inside that mode.

## Matrix

| Task shape | Start mode | First helper or file | Notes |
|---|---|---|---|
| ordinary bug with a visible symptom | `Fast Start` | `ai_navigation/debug_routes.md` | best default for player/admin symptom reports |
| known feature or keyword | `Fast Start` | `ai_navigation/entrypoints.md` | use when the system name is already known |
| explicit BYOND type path | `Fast Start` | `ai_navigation/type_index.md` | escalate to `type_tree` only if inheritance depth matters |
| spell, miracle, cooldown action | `Fast Start` | `ai_navigation/spell_signal_map.md` | use when proc lifecycle and signals both matter |
| combat, weapon, projectile, disarm, hit logic | `Fast Start` | `ai_navigation/combat_signal_map.md` | best for attack-chain work |
| movement, collision, pull, buckle, moveloop | `Fast Start` | `ai_navigation/movement_signal_map.md` | best for doll movement and physics routing |
| indirect behavior, components, elements, DCS | `Fast Start` | `ai_navigation/signal_map.md` | use when the visible proc chain is too short |
| runtime, scheduler, subsystem ownership, tick order | `Fast Start` | `ai_navigation/runtime_flow.md` or `ai_navigation/subsystem_map.md` | use `subsystem_map` first if `SS*` is already known |
| whole loop froze, no runtimes, timers stopped | `Fast Start` | `ai_navigation/processing_hazards.md` | use before assuming raw load |
| owner already known but break mode unclear | `Fast Start` | `ai_navigation/failure_modes.md` | use after ownership is localized |
| new content or mechanic | `Fast Start` | `ai_navigation/content_creation.md` | default for implementation work |
| vague content fantasy or item request | `Fast Start` | `ai_navigation/content_breakdown.md` | decompose delivery/base/delta/effect first |
| content goal clear but implementation shape unclear | `Fast Start` | `ai_navigation/content_patterns.md` | choose the cheapest fitting pattern |
| broad, risky, multi-system, or explicitly human-guided task | `Guided Start` | `ai_navigation/AGENTS.md` | only use when the safer heavier bootstrap is worth it |
| refresh of the navigation layer | `Maintenance Start` | `ai_navigation/update_policy.md` | monthly rebuild path |
| migration of the navigation layer to another codebase | `Maintenance Start` | `ai_navigation/update_policy.md` | preserve the navigation model, not exact paths |

## Rule Of Thumb

- If you can name the task shape, you probably do not need `Guided Start`.
- If you can name the subsystem, feature, symptom, or type path, `Fast Start` is usually enough.
- Use `Guided Start` only when the task is broad enough that route mistakes are likely to be expensive.
- Use `Maintenance Start` only for refresh and migration work.
