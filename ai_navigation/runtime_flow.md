# Runtime Flow

Generated on 2026-03-11. Use this file when the question is about order of execution, ownership, or lifecycle rather than just file location.

## Canonical Flows

### 1. World Bootstrap and Scheduler Startup

- Typical chain: `/world` -> `Master` -> subsystem subtype discovery -> `PreInit/Initialize` -> runlevel-driven `fire()`
- Runtime owner(s): `Master` and the target `SS*`
- Open first: `code/world.dm`, `code/controllers/master.dm`, `code/controllers/subsystem.dm`
- Use when: startup, init order, tick budgeting, scheduler, or "who owns this process?"

### 2. Round Flow to Antagonist Assignment

- Typical chain: storyteller / ticker state -> `round_event_control` selection -> `round_event` setup -> `add_antag_datum(...)` -> antagonist `on_gain()`
- Runtime owner(s): `SSticker`, `SSgamemode`, `SSevents`
- Open first: `code/controllers/subsystem/ticker.dm`, `code/controllers/subsystem/storyteller.dm`, `code/controllers/subsystem/events.dm`, `code/modules/events/**`, `code/modules/antagonists/**`
- Use when: antag spawn, roundstart role assignment, villain events, storyteller balance

### 3. Role / Job / Migrant Spawn

- Typical chain: round or join flow -> job / migrant role resolution -> loadout/spawn setup -> mob enters map -> later class/antag overlays
- Runtime owner(s): `SSjob`, `SSmigrants`, `SSrole_class_handler`
- Open first: `code/controllers/subsystem/job.dm`, `code/controllers/subsystem/migration.dm`, `code/modules/jobs/**`, `code/datums/migrants/**`
- Use when: latejoin, wrong role, bad loadout, missing class options, migrant wave issues

### 4. Action or Spell to Status Effect

- Typical chain: user input / action button -> `/datum/action` or spell proc -> validation/cost/cooldown -> effect application -> `apply_status_effect(...)` or direct mob/item change
- Runtime owner(s): `SSmagic`, `SSstatusprocess`, sometimes `SSskills`
- Open first: `code/modules/spells/spell.dm`, `code/modules/spells/**`, `code/datums/status_effects/**`
- Then check: `code/datums/components/**`, `code/datums/elements/**` if the behavior is reactive or signal-driven
- Use when: abilities do nothing, buffs/debuffs misbehave, cooldown logic seems wrong

### 5. Signal and Component Reaction Path

- Typical chain: source proc -> `SEND_SIGNAL(...)` -> component/element handler -> state mutation / status / follow-up proc
- Runtime owner(s): `SSdcs` plus the owning feature subsystem
- Open first: `code/datums/components/**`, `code/datums/elements/**`, `code/__DEFINES/dcs/**`
- Use when: behavior appears indirect, there is no obvious direct proc chain, or a change "comes from nowhere"

### 6. AI Tick to Mob Action

- Typical chain: controller process -> behavior selection/execution -> movement/path update -> mob action/attack/use
- Runtime owner(s): `SSai_controllers`, `SSai_behaviors`, `SSai_movement`
- Open first: `code/controllers/subsystem/ai_controller.dm`, `code/controllers/subsystem/processing/ai_behaviors.dm`, `code/controllers/subsystem/processing/ai_movement.dm`, `code/datums/ai/**`
- Use when: NPC logic, target selection, stuck movement, behavior trees, hostile mob decisions

### 7. Mapping and World Generation

- Typical chain: map bootstrap or generation pass -> template placement / terrain generation -> landmarks/spawners become available -> jobs/events/mobs use those locations
- Runtime owner(s): `SSmapping`, `SSminor_mapping`, `SSdungeon_generator`, `SSterrain_generation`
- Open first: `code/controllers/subsystem/mapping.dm`, `_maps/**`, `code/modules/mapping/**`, `code/modules/procedural_mapping/**`
- Use when: spawn landmarks missing, dungeon placement issues, voyage terrain, procedural map bugs

### 8. UI Request to Gameplay State

- Typical chain: UI interaction -> DM-side UI/tgui datum -> underlying gameplay datum/mob/proc -> optional status/component update
- Runtime owner(s): `SStgui`, `SSvisual_ui`, `SSchat`
- Open first: `code/modules/tgui/**`, `code/modules/visual_ui/**`, `interface/**`, `tgui/packages/**`
- Use when: UI opens but logic fails, UI state is stale, DM and TS disagree

## Escalation Rules

- If you know the keyword but not the flow, start with `ai_navigation/entrypoints.md`.
- If you know the flow but not the owner, use `ai_navigation/subsystem_map.md`.
- If you know the systems involved but not how they connect, use `ai_navigation/system_dependencies.md`.
- If the issue is still local after identifying the flow, go back to source files instead of opening more maps.
