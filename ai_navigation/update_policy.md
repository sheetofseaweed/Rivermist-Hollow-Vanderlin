# Update And Migration Policy

Generated on 2026-03-11. This is the `Maintenance Start` entrypoint for refreshing the `ai_navigation/` navigation layer, rebuilding it after heavy code drift, or migrating this repository-orientation system to another codebase.

## Terminology

In this file:

- `navigation layer`, `AI mapping`, or `repository mapping` means the docs in `ai_navigation/` plus `ai_navigation/AGENTS.md`
- it does not mean in-game map files, `_maps/**`, `code/modules/mapping/**`, or `SSmapping`

## Current Operating Mode

- refresh cadence:
  monthly manual refresh for now
- source of truth:
  source files, not existing navigation docs
- goal:
  keep the navigation layer cheap to rebuild and cheap to use

Do not treat the old navigation docs as authoritative during a refresh. Use them only as hints.

For ordinary feature work, do not start here. Use `ai_navigation/router.md` instead.

## Minimal Refresh Contract

When updating the navigation layer for this repository:

1. rebuild from source, not from memory
2. keep the same layered shape unless the repo architecture truly changed
3. prefer updating small helpers before large reference files
4. verify hot contracts and runtime owners before rewriting summaries
5. if a navigation doc and code disagree, update the navigation doc to match the code

## Rebuild Order

Use this order to keep the refresh cheap and deterministic.

1. repository shape
   - verify top directories, major languages, modular overlay paths
   - confirm whether `modular_rmh` still acts as an overlay layer
2. runtime ownership
   - rebuild `ai_navigation/subsystem_map.md`
   - verify `SS*` declarations and their files
3. type structure
   - rebuild type extraction
   - refresh `ai_navigation/type_tree.md`
   - refresh `ai_navigation/type_index.md`
4. system routing
   - refresh `ai_navigation/system_map.md`
   - refresh `ai_navigation/entrypoints.md`
   - refresh `ai_navigation/router.md`
5. runtime reasoning
   - refresh `ai_navigation/system_dependencies.md`
   - refresh `ai_navigation/runtime_flow.md`
   - refresh `ai_navigation/debug_routes.md`
6. contract helpers
   - verify and refresh:
     - `ai_navigation/signal_map.md`
     - `ai_navigation/spell_signal_map.md`
     - `ai_navigation/combat_signal_map.md`
     - `ai_navigation/movement_signal_map.md`
     - `ai_navigation/core_procs.md`
     - `ai_navigation/processing_hazards.md`
     - `ai_navigation/failure_modes.md`
7. workflow helpers
   - refresh:
     - `ai_navigation/human_checking.md`
     - `ai_navigation/content_creation.md`
     - `ai_navigation/content_breakdown.md`
     - `ai_navigation/content_patterns.md`
     - `ai_navigation/task_templates.md`
     - `ai_navigation/AGENTS.md`
     - `ai_navigation/navigation_guide.md`

If time is limited, refresh stages `2`, `4`, and `6` first. Those give the best routing value per effort.

## How The Navigation Layer Was Collected

Very short version for the next agent:

1. scan repo structure and major directories with `rg --files`
2. extract type paths from `.dm` files
3. collect subsystem declarations from `code/controllers/subsystem/**`
4. collect signal defines from `code/__DEFINES/**`
5. collect sender/listener call sites with:
   - `SEND_SIGNAL`
   - `RegisterSignal`
   - `UnregisterSignal`
6. collect hot proc families with targeted `rg` over:
   - lifecycle
   - combat
   - movement
   - spells/actions
   - processing/status
7. summarize only stable contracts and runtime owners

This repository mapping was intentionally built from stable contracts, not from exhaustive file listings.

## Refresh Validation

Before finishing a refresh:

- confirm every helper referenced by `ai_navigation/router.md` exists
- confirm every major route in `ai_navigation/entrypoints.md` still points to real directories or files
- confirm `ai_navigation/AGENTS.md` still matches the current helper set
- confirm the navigation layer still says it may lag by one monthly refresh cycle
- confirm no source files were modified if the task was docs-only

## Migration To Another Codebase

When asked to migrate this navigation layer to a different codebase:

1. do not copy paths blindly
2. rebuild the layers in the target repo's own terms
3. preserve the navigation model, not the exact filenames

## Migration Order

1. identify the target repo's equivalents for:
   - architecture/bootstrap
   - subsystem ownership
   - type hierarchy
   - signal/event system
   - modular overlay or extension layer
2. recreate only the core layers first:
   - `architecture`
   - `subsystem_map`
   - `system_map`
   - `entrypoints`
   - `router`
3. then recreate reasoning layers:
   - `runtime_flow`
   - `system_dependencies`
   - `debug_routes`
4. only then recreate specialized contract helpers:
   - spell-like
   - combat-like
   - movement-like
   - content workflow
   - risk/approval workflow

Do not invent a contract helper if the target repo has no stable equivalent.

## Migration Rules That Save Time

- if the target repo lacks BYOND type paths, replace `type_tree` with the nearest inheritance or registry view
- if the target repo lacks `SS*`, rebuild around its real scheduler or service-owner model
- if the target repo lacks DCS-style signals, rebuild around its real event or callback system
- if the target repo lacks a modular overlay, remove overlay-specific guidance instead of faking it
- keep helper names short and route-first; avoid carrying over repository-specific jargon unless it still exists

## Rule Of Thumb

- refresh this repo by preserving the layer order
- migrate to another repo by preserving the reasoning model
- in both cases, rebuild cheap routing first and deep reference docs second
