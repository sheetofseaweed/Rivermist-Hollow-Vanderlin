# System Map

Generated on 2026-03-11. Use this file as the fast index of gameplay and infrastructure systems before opening source files.

## Repository Hotspots

- `code/modules` largest slices by DM file count: `mob (342)`, `spells (196)`, `crafting (169)`, `antagonists (107)`, `clothing (95)`, `mapping (82)`, `admin (79)`, `client (66)`.
- `code/datums` largest slices by DM file count: `ai (217)`, `components (186)`, `sex (96)`, `rts (87)`, `runeword (43)`, `chimeric_organs (42)`, `elements (32)`, `status_effects (23)`.
- `modular_rmh/code/modules` largest slices: `jobs (157)`, `clothing (49)`, `spells (33)`, `mob (22)`, then smaller `homestead`, `sprite_accesory`, `mapping`, `food`.
- `modular_rmh/code/datums` focuses on `religion`, `ai`, `status_effects`, `stress`, plus a few standalone support datums.
- `modular_rmh/modular` standalone packs include `piercing`, `selectable_moanpacks`, `resurrection_rune`, `fluids`, `comfy`, `ceramics`, `loot`, and helpers.

## Major Systems

### Master Controller and Round Flow

- Main type root(s): `/datum/controller/subsystem`
- Approximate path count under the root(s): `127` subsystem macro declarations
- Primary directories: `code/world.dm`, `code/controllers/**`
- Main controllers/subsystems: `Master`, `SSticker`, `SSatoms`, `SStimer`
- Notes: `/world` boots the game; `Master` discovers subsystem subtypes, sorts by `init_order`, and drives runlevels/tick budgets.

### DCS Components and Elements

- Main type root(s): `/datum/component`, `/datum/element`
- Approximate path count under the root(s): `222` components, `33` elements
- Primary directories: `code/datums/components/**`, `code/datums/elements/**`, `code/__DEFINES/dcs/**`
- Main controllers/subsystems: `SSdcs`
- Notes: Main composition/event system. `RegisterSignal` and `SEND_SIGNAL` appear at `2195` call sites, so many interactions are routed through DCS contracts instead of direct proc chains.

### Antagonists and Hostile Role Systems

- Main type root(s): `/datum/antagonist`
- Approximate path count under the root(s): `27`
- Primary directories: `code/modules/antagonists/**`, `code/modules/events/antagonist/**`, `code/datums/migrants/waves/antagonist/**`
- Main controllers/subsystems: `SSgamemode`, `SSevents`
- Notes: Direct antagonist datums coexist with storyteller-driven antagonist events and antag migrant waves.

### Storytellers, Round Events, and Omen Tracks

- Main type root(s): `/datum/storyteller`, `/datum/round_event_control`, `/datum/round_event`, `/datum/event_group`
- Approximate path count under the root(s): `15` storyteller paths plus the event/event-group trees
- Primary directories: `code/datums/storytellers/**`, `code/datums/event_groups/**`, `code/modules/events/**`
- Main controllers/subsystems: `SSgamemode`, `SSevents`, `SSticker`
- Notes: Storytellers buy/select `round_event_control` instances; event groups provide cooldown/track grouping; antagonist events bridge directly into role systems.

### Status Effects, Actions, and Spell Trees

- Main type root(s): `/datum/status_effect`, `/datum/action`
- Approximate path count under the root(s): `355` status-effect paths, `420` action paths
- Primary directories: `code/datums/status_effects/**`, `code/modules/spells/**`, `modular_rmh/code/modules/spells/**`, `modular_rmh/code/datums/status_effects/**`
- Main controllers/subsystems: `SSstatusprocess`, `SSmagic`, `SSskills`
- Notes: `apply_status_effect(...)` appears at `345` call sites across combat, spells, liquids, quirks, wounds, and modular packs.

### AI Controllers and Behavior Trees

- Main type root(s): `/datum/ai_controller`, `/datum/ai_behavior`
- Approximate path count under the root(s): `75` AI controller paths, `201` AI behavior paths
- Primary directories: `code/datums/ai/**`, `modular_rmh/code/datums/ai/**`, `modular_rmh/code/modules/mob/**`
- Main controllers/subsystems: `SSai_controllers`, `SSai_idle_controllers`, `SSai_behaviors`, `SSai_movement`, `SSidle_ai_behaviors`
- Notes: AI is split into controllers, behaviors, planning subtrees, movement datums, and dedicated processing loops.

### Mobs, Jobs, Migrants, and Character Lifecycle

- Main type root(s): `/mob`, `/datum/migrant_wave`, `/datum/migrant_role`
- Approximate path count under the root(s): `/mob` has `634` explicit paths; migrant wave types are centered in `code/datums/migrants/**`
- Primary directories: `code/modules/mob/**`, `code/modules/jobs/**`, `code/datums/migrants/**`, `modular_rmh/code/modules/jobs/**`, `modular_rmh/code/modules/mob/**`
- Main controllers/subsystems: `SSjob`, `SSmobs`, `SSmigrants`, `SSrole_class_handler`
- Notes: Core player/NPC logic lives in `mob/`; jobs and migrant waves define spawn-time role structure; RMH adds a large parallel job layer.

### RTS / Strategy Layer

- Main type root(s): `/datum/work_order`, `/datum/building_datum`
- Approximate path count under the root(s): the `code/datums/rts/**` slice contains `87` DM files
- Primary directories: `code/datums/rts/**`
- Main controllers/subsystems: `SSstrategy_master`
- Notes: Standalone strategy subsystem with work orders, building datums, worker minds, templates, and controller UI.

### Economy, Property, Merchants, and World Factions

- Main type root(s): `/datum/nation`, `/datum/world_faction`
- Approximate path count under the root(s): `nation` and `world_factions` are smaller trees; runtime ownership is subsystem-heavy
- Primary directories: `code/modules/economy/**`, `code/controllers/subsystem/economy.dm`, `code/controllers/subsystem/treasury.dm`, `code/controllers/subsystem/property_management.dm`, `code/datums/world_factions/**`
- Main controllers/subsystems: `SSeconomy`, `SStreasury`, `SShousing`, `SSmerchant`
- Notes: Money/accounting, estate income, housing, trader flows, and factional world state are split across controllers and datums.

### Crafting, Materials, Runewords, Farming, Fishing

- Main type root(s): `/datum/material`, `/datum/runeword`
- Approximate path count under the root(s): `runeword` alone spans `43` files in `code/datums/runeword/**`; crafting is concentrated in `code/modules/crafting/**`
- Primary directories: `code/modules/crafting/**`, `code/datums/materials/**`, `code/datums/quality/**`, `code/datums/runeword/**`, `code/modules/farming/**`, `code/modules/fishing/**`
- Main controllers/subsystems: `SSskills`, `SSfishing`, `SSanvil`, `SSenchantment`
- Notes: Progression logic concentrates in crafting/material datums plus module-sliced recipes and minigames.

### Faith, Gods, Mana, Quirks, Wounds

- Main type root(s): `/datum/faith`, `/datum/mana`, `/datum/quirk`, `/datum/wound`
- Approximate path count under the root(s): `quirk` has `118` paths and `wound` has `63`; faith/gods/mana are smaller but central
- Primary directories: `code/datums/faith/**`, `code/datums/gods/**`, `code/datums/mana/**`, `code/datums/quirks/**`, `code/datums/wounds/**`
- Main controllers/subsystems: `SSskills`, `SSstatusprocess`, `SSmood`
- Notes: Character state is distributed across faith/devotion, mana, quirks, wounds, stress, rage, and organ systems.

### Mapping, Dungeons, Voyage, and Procedural Generation

- Main type root(s): `/datum/map_template`
- Approximate path count under the root(s): map templates are spread across `_maps/**` and several mapgen slices
- Primary directories: `_maps/**`, `code/modules/mapping/**`, `code/modules/procedural_mapping/**`, `modular_rmh/code/game/modules/mapgen/**`
- Main controllers/subsystems: `SSmapping`, `SSminor_mapping`, `SSdungeon_generator`, `SSterrain_generation`, `SSpathfinder`
- Notes: Static DMM templates, procedural mapgen, dungeon placement, and voyage terrain generation coexist.

### World Simulation: Liquids, Weather, Fire, Overlays

- Main type root(s): `/datum/liquid`, `/datum/weather_effect`
- Approximate path count under the root(s): environment logic is spread across datums plus subsystem-owned runtime state
- Primary directories: `code/datums/liquids/**`, `code/datums/particle_weathers/**`, `code/controllers/subsystem/liquids.dm`, `code/controllers/subsystem/particle_weather*.dm`
- Main controllers/subsystems: `SSliquids`, `SSParticleWeather`, `SSoutdoor_effects`, `SSfire_burning`, `SSfire_spread`, `SSlighting`, `SSvis_overlays`
- Notes: High-frequency simulation cluster for environmental state and visual side effects.

### UI and Frontend Stack

- Main type root(s): `/datum/ui`, `/datum/tgui`
- Approximate path count under the root(s): UI types are spread between DM and the separate `tgui` TS workspace
- Primary directories: `code/modules/tgui/**`, `code/modules/visual_ui/**`, `interface/**`, `tgui/packages/**`, `html/**`
- Main controllers/subsystems: `SStgui`, `SSvisual_ui`, `SSchat`
- Notes: DM-side browser UIs coexist with TypeScript `tgui` packages and custom BYOND interface verbs/menus.

### RMH Modular Extension Layer

- Main type root(s): multiple existing roots extended late in the include graph
- Approximate path count under the root(s): RMH contributes heavily to jobs, clothing, spells, mobs, religion, status effects, and standalone modular packs
- Primary directories: `modular_rmh/code/**`, `modular_rmh/modular/**`
- Main controllers/subsystems: uses the same core `SS*` singletons
- Notes: Loaded late in `vanderlin.dme`; treat it as an overlay layer rather than a separate architecture.

## High-Level Dependency Awareness

- Components/elements are the main cross-cutting composition mechanism: `AddComponent(...)` appears at `416` call sites, and most signal-driven wiring routes through `SSdcs` and `code/__DEFINES/dcs/**`.
- Status effects are a core gameplay contract: `apply_status_effect(...)` appears at `345` call sites across combat, spells, liquids, quirks, wounds, and modular packs.
- Event-driven communication is pervasive: `RegisterSignal`/`SEND_SIGNAL` appear at `2195` call sites, so many systems are decoupled by signals instead of direct proc calls.
- Mob creation is relatively centralized: only `52` direct `new /mob` call sites were detected, while round setup, migrants, event controllers, and spawners handle most mob lifecycle orchestration.
- Map and worldgen systems are layered: static `_maps` templates feed mapping helpers, while `SSmapping`, `SSminor_mapping`, `SSdungeon_generator`, and `SSterrain_generation` own runtime placement/generation passes.
- The modular RMH layer does not introduce a second runtime architecture; it extends existing roots and reuses the same `SS*` infrastructure, so always check `modular_rmh` after locating the core path in `code/`.
