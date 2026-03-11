# Architecture Overview

Generated on 2026-03-11. This file explains how the repository is put together and where runtime ownership lives.

## Composition Model

- The project is a BYOND/Dream Maker codebase with a classic tgstation-style linear `.dme` include graph.
- The high-level include order is: maps/templates -> world/defines -> helpers -> globalvars -> controllers -> datums -> modules -> game atoms/objects -> interface -> `modular_rmh` late extensions.
- Because `modular_rmh` is included near the end of `vanderlin.dme`, it acts as an overlay layer: it can extend existing type trees and piggyback on core singletons without replacing the architecture.

## Runtime Backbone

- `code/world.dm` defines `/world`; `code/controllers/master.dm` owns the master controller loop and discovers all `/datum/controller/subsystem` subtypes via `subtypesof(...)`.
- `code/controllers/subsystem.dm` is the base scheduler contract: metadata (`init_order`, `wait`, `priority`, `flags`), runlevels, queueing, `Initialize()`, and `fire()`.
- `code/__DEFINES/MC.dm` turns subsystem macros into `SS*` globals plus type declarations, so subsystem files effectively declare singletons and their types together.
- `SSatoms` is the bridge between BYOND construction and the project initialization model: it drives `Initialize`, `LateInitialize`, and init diagnostics for atoms.

## Domain Layers

- `code/__DEFINES`: compile-time constants, macros, signal definitions, subsystem flags, and root constants.
- `code/__HELPERS`: shared procs/helpers used across every gameplay layer.
- `code/_globalvars`: global singletons, caches, lookup tables, and configuration state.
- `code/controllers`: world bootstrap, master controller, configuration, and subsystem framework.
- `code/datums`: pure/stateful datums for AI, components, status effects, faith, RTS, migrants, runewords, and other reusable logic.
- `code/modules`: feature-sliced gameplay code such as jobs, spells, antagonists, mobs, crafting, mapping, reagents, and UI bridges.
- `code/game`: concrete atoms, mobs, objects, turfs, areas, and gamemode implementations.
- `_maps`: static maps, templates, and map adjustment files.
- `interface`: BYOND client verbs, menus, DMF, and font datums.
- `tgui`: TypeScript/React frontend packages and build tooling.
- `modular_rmh`: late-included modular extension layer for jobs, spells, mobs, mapgen, status effects, religion, fluids, and content packs.
- `config`, `SQL`, `tools`: runtime config, schema data, and developer tooling.

## Core Patterns

- Type-tree inheritance is the primary structural unit. Most gameplay features are found by following paths under `/datum`, `/obj`, `/mob`, `/turf`, and `/area`.
- Signal-driven composition is a first-class pattern: `RegisterSignal` and `SEND_SIGNAL` appear at `2195` call sites, which means behavior is frequently attached indirectly through DCS contracts instead of hardcoded call chains.
- Component-based extension is pervasive: `AddComponent(...)` appears at `416` call sites, especially around atoms, items, mobs, and environmental systems.
- Status effects are a common cross-system state container: `apply_status_effect(...)` appears at `345` call sites spanning combat, spells, liquids, wounds, quirks, and modular features.
- Feature slices are split between `code/datums` for reusable logic/state and `code/modules` for feature bundles, UI, content, and mechanics.
- Mapping is hybrid: static DMM/templates in `_maps` coexist with procedural generation in `code/modules/mapping`, `code/modules/procedural_mapping`, and voyage/dungeon subsystems.

## Modular RMH Layer

- `modular_rmh/code/modules` is dominated by jobs, clothing, spells, and mobs. RMH mostly extends character-facing content rather than core scheduling infrastructure.
- `modular_rmh/code/datums` primarily extends religion, AI, status effects, stress, and a few support datums.
- `modular_rmh/modular` contains smaller self-contained packs such as `piercing`, `selectable_moanpacks`, `resurrection_rune`, `fluids`, `comfy`, `ceramics`, and `loot`.
- The important navigation rule is: find the core type first in `code/`, then check whether `modular_rmh` adds descendants, overrides behavior on that path, or introduces parallel content that hooks into the same subsystem.

## Frontend and External Integration

- DM-side UI backends live in `code/modules/tgui/**`, `code/modules/visual_ui/**`, and `interface/**`.
- The TypeScript frontend is under `tgui/packages/**` (`common`, `tgui`, `tgui-panel`, `tgui-say`, etc.) with Rspack/TS build tooling in the `tgui/` root.
- Runtime configuration and policies live under `config/**`; SQL/schema files live under `SQL/**`; CI/build helpers are under `bin/**`, `tools/**`, and shell/cmd scripts at repo root.
