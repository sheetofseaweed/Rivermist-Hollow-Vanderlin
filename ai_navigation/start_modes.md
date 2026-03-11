# Start Modes

Generated on 2026-03-11. Use this file to choose the cheapest valid startup mode before opening other navigation docs.

## Goal

Do not force one bootstrap path on every task.

Use the cheapest start mode that still fits the task.

If you already know the task shape but not the exact helper, use:

- `ai_navigation/start_matrix.md`

## 1. Fast Start

Default mode for normal work.

Use when:

- the task has a keyword, feature name, symptom, subsystem, or type path
- the goal is ordinary bugfixing, investigation, or implementation
- there is no obvious need for broad onboarding first

Open:

1. `ai_navigation/router.md`
2. exactly 1 helper
3. up to 2 source files

Do not open `ai_navigation/AGENTS.md` first unless the task is genuinely broad or human-guided.

## 2. Guided Start

Use when a human wants the agent to follow the full repository guidance first.

Use when:

- the agent is new to the repository
- the task is broad, risky, or multi-system
- the user explicitly says to start with the main guide
- human approval or scope control is likely to matter early

Open:

1. `ai_navigation/AGENTS.md`
2. `ai_navigation/router.md`
3. exactly 1 helper
4. up to 2 source files

This is safer than Fast Start, but more expensive.

## 3. Maintenance Start

Use for monthly refreshes, rebuilds of the navigation layer, or migration to another codebase.

Use when:

- the task is to refresh the navigation layer
- the task is to rebuild stale docs after code drift
- the task is to port the navigation model to a different repository

Open:

1. `ai_navigation/update_policy.md`
2. use the rebuild or migration order from that file
3. open `ai_navigation/AGENTS.md` only for final consistency if needed

Do not start maintenance work from normal feature-routing helpers.

## Rule Of Thumb

- normal task: Fast Start
- broad or human-guided task: Guided Start
- refresh or migration: Maintenance Start

If unsure, start with Fast Start and escalate only if needed.
