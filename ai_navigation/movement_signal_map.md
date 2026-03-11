# Movement Signal Map

Generated on 2026-03-11. Use this file when client movement, puppet movement, collisions, pulling, buckle state, throw travel, or moveloop-driven motion is routed through both core procs and DCS signals.

## Why Movement Needs Its Own Map

Movement is not only `Moved()` on a mob.

It is split across:

- client input and doll movement in `code/modules/mob/mob_movement.dm`
- living-side movement consequences in `code/modules/mob/living/living_movement.dm`
- movable signal families for crossing, bumping, pulling, throwing, and buckling
- automated movement loops in `code/controllers/subsystem/movement/**`

Detected movement-signal footprint:

- `54` movement-related `COMSIG_*` defines
- `440` movement-related signal references
- `245` references in the most important client, movable, and moveloop families

## Canonical Movement Contracts

Start from these contract files before opening random mob or vehicle subtypes:

- client and doll movement:
  `code/modules/mob/mob_movement.dm`
- living-side movement consequences:
  `code/modules/mob/living/living_movement.dm`
- automated movement loops:
  `code/controllers/subsystem/movement/movement_loop.dm`
  `code/controllers/subsystem/movement/move_manager.dm`

## Doll And Client Movement Contract

Base proc chain in `code/modules/mob/mob_movement.dm`:

1. `/client/Move`
2. pre-move signal gate
3. BYOND move via `..()` / target mob move path
4. post-move signal

### Core signals

- sender proc: `/client/Move`
  - `COMSIG_MOB_CLIENT_PRE_MOVE`
- sender proc: after successful move handling
  - `COMSIG_MOB_CLIENT_MOVED`

Use this path for player input, movement veto, movement state setup, and post-step reactions tied to the controlled mob.

## Movable Propagation Contract

After the client-side gate, movement fans out into movable and living hooks.

Key proc families:

1. `Move`
2. `Moved`
3. `Cross`
4. `Crossed`
5. `Uncrossed`
6. `Bump`

### Core signals

- pre-move and post-move:
  - `COMSIG_MOVABLE_PRE_MOVE`
  - `COMSIG_MOVABLE_MOVED`
- transit and overlap:
  - `COMSIG_MOVABLE_CROSS`
  - `COMSIG_MOVABLE_CROSSED`
  - `COMSIG_MOVABLE_UNCROSSED`
- collision:
  - `COMSIG_MOVABLE_BUMP`

Use this layer when the visible issue happens after stepping, when entering or leaving overlap, or when collisions trigger effects.

## Pull, Throw, Buckle, And Driver Movement

These are not side notes. They are their own movement branches.

### Pull-related signals

- `COMSIG_LIVING_START_PULL`
- `COMSIG_ATOM_CAN_BE_PULLED`
- `COMSIG_ATOM_NO_LONGER_PULLED`
- `COMSIG_ATOM_NO_LONGER_PULLING`

### Throw-related signals

- `COMSIG_MOVABLE_PRE_THROW`
- `COMSIG_MOVABLE_POST_THROW`
- `COMSIG_MOVABLE_THROW_LANDED`

### Buckle and driver signals

- `COMSIG_MOVABLE_PREBUCKLE`
- `COMSIG_MOVABLE_BUCKLE`
- `COMSIG_MOVABLE_UNBUCKLE`
- `COMSIG_RIDDEN_DRIVER_MOVE`

Use these when the bug is not "walking" in general, but dragging, mounting, riding, or thrown-object travel.

## Automated Movement And Moveloops

Loop-managed movement is owned by `SSmovement`.

Canonical files:

- `code/controllers/subsystem/movement/movement_loop.dm`
- `code/controllers/subsystem/movement/move_manager.dm`

High-value signal family:

- `COMSIG_MOVELOOP_START`
- `COMSIG_MOVELOOP_STOP`
- `COMSIG_MOVELOOP_PREPROCESS_CHECK`
- `COMSIG_MOVELOOP_POSTPROCESS`
- `COMSIG_MOVELOOP_JPS_REPATH`

Related state signals:

- `COMSIG_MOVETYPE_FLAG_ENABLED`
- `COMSIG_MOVETYPE_FLAG_DISABLED`

Use this path for AI walking, `walk_to`-style behavior, repathing, or movement that continues without repeated player input.

## Cheap Search Order

1. Open `code/modules/mob/mob_movement.dm`.
2. Open `code/modules/mob/living/living_movement.dm` or the exact movable subtype.
3. If the movement is automated, open `code/controllers/subsystem/movement/movement_loop.dm` and `move_manager.dm`.
4. Search `RegisterSignal(` for the relevant `COMSIG_MOB_CLIENT_*`, `COMSIG_MOVABLE_*`, or `COMSIG_MOVELOOP_*`.
5. Only then widen into components, elements, vehicles, or modular overlays.

## Fast Search Patterns

- movement-signal defines:
  `rg -n "^#define COMSIG_.*(MOVE|MOVED|CROSS|BUMP|BUCKLE|PULL|DRIVER_MOVE|MOVELOOP|MOVETYPE|GLIDE|STEP)" code/__DEFINES -g "*.dm"`
- movement senders and listeners:
  `rg -n "COMSIG_.*(MOVE|MOVED|CROSS|BUMP|BUCKLE|PULL|THROW|MOVELOOP|MOVETYPE)" code modular_rmh -g "*.dm"`
- client and movable movement hooks:
  `rg -n "/(Move|Moved|Crossed|Uncrossed|Bump)\(" code/modules code/controllers modular_rmh -g "*.dm"`

## Rule Of Thumb

- If the issue starts from player input, start at `/client/Move`.
- If the move succeeds but side effects are wrong, start at `Moved` and the movable signal families.
- If the issue continues without new input, start at `SSmovement` and the moveloop signals.
- If collision or projectile travel is part of the bug, read this file together with `ai_navigation/combat_signal_map.md`.
