# System Dependencies

Generated on 2026-03-11. Use this file when the task spans more than one system and you need the shortest high-level dependency map.

## Read This File When

- a bug crosses subsystem boundaries
- a feature touches both gameplay logic and runtime ownership
- you know one system, but not the next system it hands off to

## Core Dependency Chains

| From | Usually hands off to | Runtime owner(s) | First places to open |
|---|---|---|---|
| `/world` bootstrap | `Master` -> `/datum/controller/subsystem` tree | `Master` | `code/world.dm`, `code/controllers/master.dm`, `code/controllers/subsystem.dm` |
| Storytellers / `round_event_control` | `round_event` -> antagonist/job/mob changes | `SSgamemode`, `SSevents`, `SSticker` | `code/datums/storytellers/**`, `code/modules/events/**`, `code/modules/antagonists/**` |
| Antagonist datums | mob state, role state, spawn logic, HUD/clan/action setup | `SSgamemode`, `SSevents`, sometimes `SSmapping`/`SSjob` | `code/modules/antagonists/**`, `code/modules/events/antagonist/**`, `code/datums/migrants/waves/antagonist/**` |
| Jobs / migrants / role classes | mob spawn and loadout, later antagonist or map-specific logic | `SSjob`, `SSmigrants`, `SSrole_class_handler` | `code/modules/jobs/**`, `code/datums/migrants/**`, `modular_rmh/code/modules/jobs/**` |
| Actions / spells | status effects, cooldown processing, mob/item effects | `SSmagic`, `SSstatusprocess`, `SSskills` | `code/modules/spells/**`, `code/datums/status_effects/**` |
| Components / elements | signal-driven reactions in mobs, items, UI, status systems | `SSdcs` | `code/datums/components/**`, `code/datums/elements/**`, `code/__DEFINES/dcs/**` |
| AI controllers | AI behaviors -> movement -> mob actions | `SSai_controllers`, `SSai_behaviors`, `SSai_movement` | `code/datums/ai/**`, `code/modules/mob/**` |
| Mapping / worldgen | landmarks, spawn points, dungeon placement, voyage terrain | `SSmapping`, `SSminor_mapping`, `SSdungeon_generator`, `SSterrain_generation` | `_maps/**`, `code/modules/mapping/**`, `code/modules/procedural_mapping/**` |
| Economy / property / merchants | faction state, housing, treasury flows, settlement simulation | `SSeconomy`, `SStreasury`, `SShousing`, `SSmerchant` | `code/modules/economy/**`, `code/datums/world_factions/**`, `code/datums/nation/**`, `code/datums/rts/**` |
| UI / tgui / browser UIs | DM-side UI datums -> underlying gameplay system | `SStgui`, `SSvisual_ui`, `SSchat` | `code/modules/tgui/**`, `code/modules/visual_ui/**`, `interface/**`, `tgui/packages/**` |

## Cross-Cutting Contracts

- DCS signals are the main decoupling layer. `RegisterSignal` and `SEND_SIGNAL` appear at `2195` call sites, so indirect behavior often lives in components/elements rather than in the caller.
- Components are a common attachment mechanism. `AddComponent(...)` appears at `416` call sites across mobs, items, status handling, and feature modules.
- Status effects are a common state handoff. `apply_status_effect(...)` appears at `345` call sites across spells, combat, liquids, wounds, quirks, and modular content.
- Mob lifecycle is less direct than it looks. Only `52` direct `new /mob` call sites were detected; round flow, role systems, migrants, events, and map spawners do most of the orchestration.
- `modular_rmh` usually extends an existing branch instead of creating a parallel runtime architecture. After locating the core path in `code/`, check the same branch in `modular_rmh`.

## Cheap Debugging Routes

- If a spell or ability issue becomes indirect, check `status effects` first, then `components/elements`, then the owning `SS*`.
- If an antagonist issue is not local to `code/modules/antagonists/**`, check `events`, then `jobs/migrants`, then `mapping` for landmarks/spawn points.
- If a role/spawn issue is not local to jobs, check `migrants`, then `role_class_handler`, then map-specific landmarks/templates.
- If AI behavior looks wrong, split the question into three layers: controller selection, behavior execution, movement/pathing.
- If the bug is timing-dependent, switch to `ai_navigation/runtime_flow.md` and `ai_navigation/subsystem_map.md` before reading more feature files.
