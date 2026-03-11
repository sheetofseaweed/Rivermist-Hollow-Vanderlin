# Core Procs

Generated on 2026-03-11. Use this file to keep the main proc families and entry hooks in mind before doing a broad search.

## Lifecycle Procs

These are common first entrypoints for object and datum behavior:

- `New`
- `Initialize`
- `Destroy`
- `qdel`

Use these when behavior appears on creation, mapload, cleanup, or deletion.

## Interaction Procs

These are common gameplay hook points:

- `attack_self`
- `pre_attack`
- `attack`
- `attackby`
- `attack_hand`
- `afterattack`
- `ui_interact`
- `Topic`

Use these when a feature happens because a player clicked, used, or targeted something.

## Combat Hooks

These are the main proc families for direct combat routing:

- `attack_self`
- `pre_attack`
- `attack`
- `attackby`
- `attack_hand`
- `afterattack`
- `fire`
- `on_hit`

Use these when behavior follows item attacks, unarmed attacks, projectiles, or hit-side reactions. For proc-and-signal combat contracts, open `ai_navigation/combat_signal_map.md`.

## Action And Spell Hooks

These are the main proc families for cooldown actions and spells:

- `Trigger`
- `set_click_ability`
- `PreActivate`
- `Activate`
- `before_cast`
- `cast`
- `after_cast`
- `reset_spell_cooldown`

Use these when behavior follows action buttons, click intercepts, cast validation, cast execution, or cooldown reset logic.

## Movement And Physics Hooks

- `Move`
- `Moved`
- `Crossed`
- `Uncrossed`
- `Bump`

Use these when behavior follows stepping, transit, collision, or turf/object movement. For client movement, move loops, throws, pulls, or buckle chains, open `ai_navigation/movement_signal_map.md`.

## Timed And Status Hooks

- `process`
- `tick`
- `on_apply`
- `on_remove`

Use these when a feature is periodic, temporary, or stateful.

## Scheduler Hooks

- subsystem `fire`
- `START_PROCESSING`
- `STOP_PROCESSING`
- `addtimer`

Use these when runtime ownership, periodic updates, or delayed effects matter.

## DCS And Indirect Hooks

- `RegisterSignal`
- `SEND_SIGNAL`
- `UnregisterSignal`

Use these when behavior is component-driven or the visible cause is far from the actual logic.

## Fast Search Patterns

- lifecycle:
  `rg -n "/(Initialize|Destroy|New)\(" code modular_rmh -g "*.dm"`
- interaction:
  `rg -n "/(attack_self|attackby|afterattack|ui_interact|Topic)\(" code modular_rmh -g "*.dm"`
- action/spell:
  `rg -n "/(Trigger|set_click_ability|PreActivate|Activate|before_cast|cast|after_cast|reset_spell_cooldown)\(" code/modules/spells code/datums/actions modular_rmh -g "*.dm"`
- combat:
  `rg -n "/(attack_self|pre_attack|attack|attackby|attack_hand|afterattack|fire|on_hit)\(" code/_onclick code/modules modular_rmh -g "*.dm"`
- movement:
  `rg -n "/(Move|Moved|Crossed|Uncrossed|Bump)\(" code/modules code/controllers modular_rmh -g "*.dm"`
- timed/state:
  `rg -n "/(process|tick|on_apply|on_remove)\(" code modular_rmh -g "*.dm"`
- scheduler:
  `rg -n "\b(addtimer|START_PROCESSING|STOP_PROCESSING)\b" code modular_rmh -g "*.dm"`

## Rule Of Thumb

- If it happens on creation, start with `Initialize`.
- If it happens on use, start with interaction procs.
- If it happens in combat or hit resolution, open `ai_navigation/combat_signal_map.md`.
- If it happens in a cooldown-action or spell lifecycle, start with the action/spell hooks and then open `ai_navigation/spell_signal_map.md`.
- If it happens in stepping, collisions, pull chains, or automated movement, open `ai_navigation/movement_signal_map.md`.
- If it happens over time, start with `process` or `tick`.
- If it feels indirect, switch immediately to `ai_navigation/signal_map.md`.
