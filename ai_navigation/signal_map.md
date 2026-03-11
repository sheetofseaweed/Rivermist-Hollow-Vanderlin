# Signal Map

Generated on 2026-03-11. Use this file when behavior is indirect, component-driven, or routed through DCS signals instead of obvious proc calls.

## Why This Matters

This repository has a large signal layer:

- `685` `COMSIG_*` defines under `code/__DEFINES/**`
- `991` `SEND_SIGNAL(` call sites
- `1203` `RegisterSignal(` call sites
- `667` `UnregisterSignal(` call sites

Signals are a first-class behavior path here, not an edge case.

## Contract-First Helpers

Some systems have stable proc-and-signal contracts and should be read through those contracts first.

- spells and miracles:
  `ai_navigation/spell_signal_map.md`
- combat and hit chains:
  `ai_navigation/combat_signal_map.md`
- doll movement, collisions, and moveloops:
  `ai_navigation/movement_signal_map.md`
- generic hook families:
  `ai_navigation/core_procs.md`

If a system has a dedicated contract helper, prefer that over this generic map.

## Main Signal Families

Start from these define roots:

- `code/__DEFINES/dcs/signals_atoms/**`
  atom, item, attack, click, movement, throw, destruction, storage-like hooks
- `code/__DEFINES/dcs/signals_mob/**`
  mob, living, carbon, mind, role, health, combat, death, status-like hooks
- `code/__DEFINES/dcs/signals/**`
  actions, AI, client, HUD, global, subsystems, tgui, spells, moveloop, objectives
- `code/__DEFINES/*.dm`
  repo-specific families outside the main DCS tree such as fish, emotions, devotion, sex

## High-Value Signal Zones

When the feature feels indirect, check these first:

- item and attack chains:
  `COMSIG_ITEM_*`, `COMSIG_ATOM_ATTACKBY*`, `COMSIG_ITEM_AFTERATTACK*`, then `ai_navigation/combat_signal_map.md`
- movement and location:
  `COMSIG_MOVABLE_*`, `COMSIG_MOVELOOP_*`, then `ai_navigation/movement_signal_map.md`
- mob and living state:
  `COMSIG_LIVING_*`, `COMSIG_MOB_*`
- subsystem and round flow:
  `COMSIG_TICKER_*`, global `SSdcs` listeners
- UI and input:
  `COMSIG_CLIENT_*`, `COMSIG_CLICK*`, HUD-related signals
- spells and cooldown actions:
  `COMSIG_SPELL_*`, `COMSIG_MOB_*SPELL*`, and the lifecycle in `code/modules/spells/spell.dm`

## Fast Search Order

1. Find the trigger event or user-visible moment.
2. Search for the nearest `COMSIG_*` family name.
3. Find `SEND_SIGNAL(` call sites for the event source.
4. Find `RegisterSignal(` listeners on the target or shared subsystem.
5. Check whether a component or element is the real receiver.
6. If the system is spell-like, switch to `ai_navigation/spell_signal_map.md` before widening further.
7. If the system is combat-like, switch to `ai_navigation/combat_signal_map.md`.
8. If the system is movement-like, switch to `ai_navigation/movement_signal_map.md`.

## Cheap Search Patterns

- find a signal family:
  `rg -n "^#define COMSIG_" code/__DEFINES -g "*.dm"`
- find senders:
  `rg -n "\bSEND_SIGNAL\(" code modular_rmh -g "*.dm"`
- find listeners:
  `rg -n "\bRegisterSignal\(" code modular_rmh -g "*.dm"`
- find cleanup:
  `rg -n "\bUnregisterSignal\(" code modular_rmh -g "*.dm"`

## Rule Of Thumb

- If the proc chain looks too short for the observed behavior, assume signals are involved.
- If a component or element exists, assume it probably enters through signals.
- If a feature changes state "by itself", search signals before tracing every proc by hand.
