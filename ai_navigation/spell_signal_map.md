# Spell Signal Map

Generated on 2026-03-11. Use this file when a spell, miracle, rituos effect, or cooldown-based magical ability is routed through both core procs and DCS signals.

## Why Spells Need Their Own Map

Spells are not just subtype overrides under `code/modules/spells/**`.

They sit on a reusable contract rooted at `/datum/action/cooldown/spell`, with:

- core proc lifecycle in `code/modules/spells/spell.dm`
- signal definitions in `code/__DEFINES/dcs/signals/signals_spell.dm`
- owner-side hooks on the casting mob
- subtype-specific signal branches for projectile, AOE, cone, touch, and jaunt behavior

Detected spell-signal footprint:

- `19` spell-related signal defines in `signals_spell.dm`
- `54` spell-signal references across `code/**` and `modular_rmh/**`

## Canonical Spell Contract

Start from `code/modules/spells/spell.dm`, not from a random spell subtype.

Base proc chain:

1. `Trigger`
2. `set_click_ability`
3. `Activate`
4. `before_cast`
5. `cast`
6. `after_cast`
7. `reset_spell_cooldown`

This is the real contract. Subtypes usually customize `before_cast`, `cast`, or `after_cast`.

## Core Signal Order

### Activation / selection

- sender proc: `set_click_ability`
- main signal:
  - `COMSIG_MOB_SPELL_ACTIVATED`
- purpose:
  - owner-side veto before the spell fully arms
  - click-intercept / retrigger coordination

### Pre-cast

- sender proc: `before_cast`
- signals:
  - `COMSIG_SPELL_BEFORE_CAST`
  - `COMSIG_MOB_BEFORE_SPELL_CAST`
- return flags:
  - `SPELL_CANCEL_CAST`
  - `SPELL_NO_FEEDBACK`
  - `SPELL_NO_IMMEDIATE_COOLDOWN`
  - `SPELL_NO_IMMEDIATE_COST`
- purpose:
  - final veto point
  - cost gating
  - target gating
  - invocation / feedback suppression

### Main cast

- sender proc: `cast`
- signals:
  - `COMSIG_SPELL_CAST`
  - `COMSIG_MOB_CAST_SPELL`
- purpose:
  - the actual cast event
  - owner-side reactions
  - downstream listeners like trigger systems, AI inputs, or achievements

### After-cast

- sender proc: `after_cast`
- signals:
  - `COMSIG_SPELL_AFTER_CAST`
  - `COMSIG_MOB_AFTER_SPELL_CAST`
- purpose:
  - post-effect cleanup
  - delayed follow-up logic
  - pay-after-success style components

### Cooldown reset

- sender proc: `reset_spell_cooldown`
- signal:
  - `COMSIG_SPELL_CAST_RESET`
- purpose:
  - explicit cooldown rollback / recovery path

## Specialized Spell Branches

These sit on top of the generic contract:

- projectile spells:
  - `COMSIG_SPELL_PROJECTILE_HIT`
- AOE spells:
  - `COMSIG_SPELL_AOE_ON_CAST`
- cone spells:
  - `COMSIG_SPELL_CONE_ON_CAST`
  - `COMSIG_SPELL_CONE_ON_LAYER_EFFECT`
- touch spells:
  - `COMSIG_SPELL_TOUCH_HAND_HIT`
- invocation / voice:
  - `COMSIG_MOB_PRE_INVOCATION`
- jaunt branches:
  - `COMSIG_MOB_ENTER_JAUNT`
  - `COMSIG_MOB_EJECTED_FROM_JAUNT`
  - `COMSIG_MOB_AFTER_EXIT_JAUNT`
  - bloodcrawl-specific living hooks

## Known Listeners And Extensions

High-value listeners already in the repo:

- `code/datums/actions/action_cooldown.dm`
  - listens to `COMSIG_MOB_SPELL_ACTIVATED` for retrigger cancellation
- `code/datums/chimeric_organs/inputs/spell_cast.dm`
  - listens to `COMSIG_MOB_CAST_SPELL`
- `code/datums/components/use_mana.dm`
  - designed around `COMSIG_SPELL_BEFORE_CAST` and `COMSIG_SPELL_AFTER_CAST`

If a spell bug feels indirect, these listeners matter almost as much as the spell subtype itself.

## Cheap Search Order

1. Open `code/modules/spells/spell.dm`.
2. Open `code/__DEFINES/dcs/signals/signals_spell.dm`.
3. Open the concrete spell subtype.
4. Search `RegisterSignal(` for the relevant `COMSIG_*SPELL*`.
5. Only then widen into components, owner mob code, or modular overlays.

## Fast Search Patterns

- spell-signal defines:
  `rg -n "COMSIG_.*SPELL|COMSIG_MOB_.*SPELL|COMSIG_MOB_PRE_INVOCATION|JAUNT|BLOOD_CRAWL" code/__DEFINES/dcs/signals/signals_spell.dm`
- spell-signal senders/listeners:
  `rg -n "COMSIG_SPELL_|COMSIG_MOB_.*SPELL" code modular_rmh -g "*.dm"`
- spell contract procs:
  `rg -n "/(Trigger|set_click_ability|Activate|before_cast|cast|after_cast|reset_spell_cooldown)\(" code/modules/spells code/datums/actions -g "*.dm"`

## Rule Of Thumb

- If the spell UI/button is wrong, start at `Trigger` and `set_click_ability`.
- If the spell never goes off, start at `before_cast` and its signal listeners.
- If the spell goes off but side effects are missing, check `cast` and `after_cast`.
- If the subtype looks too small for the observed behavior, the real logic is probably in the spell contract or a spell signal listener.
