# Combat Signal Map

Generated on 2026-03-11. Use this file when melee, unarmed, projectile, disarm, or combat-target behavior is routed through both core procs and DCS signals.

## Why Combat Needs Its Own Map

Combat is not one file or one proc family here.

It is split across:

- click and item attack entrypoints in `code/_onclick/**`
- human and living attack/defense paths in `code/modules/mob/**`
- projectile lifecycle in `code/modules/projectiles/**`
- signal listeners in components, AI behaviors, and combat side systems

Detected combat-signal footprint:

- `53` combat-related `COMSIG_*` defines
- `421` combat-related signal references
- `168` references in the most important core combat families

## Canonical Combat Contracts

Start from these contract files before opening random weapon or mob subtypes:

- held item combat:
  `code/_onclick/item_attack.dm`
- unarmed and hand attacks:
  `code/_onclick/other_mobs.dm`
- projectile combat:
  `code/modules/projectiles/projectile.dm`

If the bug is specifically species, disarm, or defense-side logic, then add:

- `code/modules/mob/living/carbon/human/species.dm`
- `code/modules/mob/living/carbon/human/human_defense.dm`
- `code/modules/mob/living/living_defense.dm`

## Held Item Combat Contract

Base proc chain in `code/_onclick/item_attack.dm`:

1. `attack_self`
2. `pre_attack`
3. target-side `attackby`
4. item-side `attack`
5. `afterattack`
6. `attack_qdeleted`
7. `do_special_attack_effect`

This is the main contract for held item attacks and on-hit style weapon behavior.

### Core signals

- sender proc: `attack_self`
  - `COMSIG_ITEM_ATTACK_SELF`
- sender proc: `pre_attack`
  - `COMSIG_ITEM_PRE_ATTACK`
- sender proc: target `attackby`
  - `COMSIG_ATOM_ATTACKBY`
- sender proc: item `attack`
  - `COMSIG_ITEM_ATTACK`
  - `COMSIG_MOB_ITEM_ATTACK`
- sender proc: `afterattack`
  - `COMSIG_ITEM_AFTERATTACK`
  - `COMSIG_MOB_ITEM_AFTERATTACK`
- sender proc: `attack_qdeleted`
  - `COMSIG_ITEM_ATTACK_QDELETED`
- sender proc: `do_special_attack_effect`
  - `COMSIG_ITEM_ATTACK_EFFECT`

Use this path for weapon effects, attack-side components, hit reactions, and item-driven combat extensions.

## Unarmed And Hand Attack Contract

Base path in `code/_onclick/other_mobs.dm` with human-specific extensions in `species.dm`:

1. early unarmed routing
2. melee unarmed execution
3. target `attack_hand`
4. disarm or species-specific follow-up if relevant

### Core signals

- early unarmed gate:
  - `COMSIG_HUMAN_EARLY_UNARMED_ATTACK`
- main unarmed melee:
  - `COMSIG_HUMAN_MELEE_UNARMED_ATTACK`
- target hand-attack hook:
  - `COMSIG_ATOM_ATTACK_HAND`
  - `COMSIG_MOB_ATTACK_HAND`
- disarm branch:
  - `COMSIG_HUMAN_DISARM_HIT`
- animal/living-side attack variants:
  - `COMSIG_ATOM_ATTACK_ANIMAL`

Use this path when punches, grapples, disarms, bites, or target-side hand responses behave unexpectedly.

## Projectile Combat Contract

Base proc chain in `code/modules/projectiles/projectile.dm`:

1. `fire`
2. pre-hit validation
3. `on_hit`

### Core signals

- sender proc: `fire`
  - `COMSIG_PROJECTILE_BEFORE_FIRE`
- sender proc: pre-hit path
  - `COMSIG_PROJECTILE_PREHIT`
- sender proc: `on_hit`
  - `COMSIG_PROJECTILE_ON_HIT`
  - `COMSIG_PROJECTILE_SELF_ON_HIT`

Projectile travel also overlaps with movement and bump behavior. If pathing or collisions look wrong, add `ai_navigation/movement_signal_map.md`.

## Target Selection And Combat Coordination

Not all combat logic begins on hit. Some systems react when a target is chosen or updated.

High-value signal:

- `COMSIG_COMBAT_TARGET_SET`

Known listeners and users already in the repo:

- `code/datums/components/combat_noises.dm`
- `code/datums/ai/behaviours/hostile/melee_attack.dm`
- `code/datums/ai/subtrees/human_basic_attack.dm`
- `code/datums/ai/subtrees/minotaur_melee.dm`
- `code/datums/ai/subtrees/bow_usage.dm`
- other AI combat subtrees and target-selection helpers

If combat behavior looks "smart" or reactive instead of directly coded in the weapon or mob, check target-set listeners early.

## Cheap Search Order

1. Open `code/_onclick/item_attack.dm` for held items or weapon effects.
2. Open `code/_onclick/other_mobs.dm` for punches, bites, hand attacks, and disarms.
3. Open `code/modules/projectiles/projectile.dm` for ranged or spell-projectile behavior.
4. Open the exact weapon, mob, or species subtype.
5. Search `RegisterSignal(` for the relevant `COMSIG_*ATTACK*`, `COMSIG_*HIT*`, or projectile family.
6. Only then widen into components, elements, AI, or modular overlays.

## Fast Search Patterns

- combat-signal defines:
  `rg -n "^#define COMSIG_.*(ATTACK|COMBAT|MELEE|PROJECTILE|HIT|PARRY|BLOCK|DODGE|BULLET|THROW)" code/__DEFINES -g "*.dm"`
- combat senders and listeners:
  `rg -n "COMSIG_.*(ATTACK|COMBAT|MELEE|PROJECTILE|HIT|DISARM)" code modular_rmh -g "*.dm"`
- held item contract:
  `rg -n "/(attack_self|pre_attack|attackby|attack|afterattack|attack_qdeleted|do_special_attack_effect)\(" code/_onclick code/modules -g "*.dm"`
- projectile contract:
  `rg -n "/(fire|on_hit)\(" code/modules/projectiles -g "*.dm"`

## Rule Of Thumb

- If a weapon effect appears on click or hit, start at `code/_onclick/item_attack.dm`.
- If the issue is unarmed, disarm, or hand-target logic, start at `code/_onclick/other_mobs.dm`.
- If the visible subtype looks too small for the observed behavior, the real logic is probably in a combat signal listener.
- If a ranged issue mixes collision and hit logic, read `ai_navigation/movement_signal_map.md` together with this file.
