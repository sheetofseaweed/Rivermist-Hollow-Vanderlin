# Processing Hazards

Generated on 2026-03-11. Use this file when a whole process-driven system stalls, freezes, or silently stops progressing.

## Use This Helper When

- many effects or entities stop updating at once
- a whole `SS*` loop appears frozen
- there are no runtimes, but timers/effects never expire
- the symptom looks like a hung process chain, not a single bad datum

## Red Flags

If these appear inside `process()`, `tick()`, `fire()`, or procs called directly from them, treat them as high risk:

- `input(`
- `alert(`
- `browse(`
- `do_after(`
- `sleep(`
- `waitfor = TRUE` or implicit waiting behavior
- sync UI or user-interaction calls from subsystem-owned code

Safe-looking async escape hatches to check for:

- `INVOKE_ASYNC`
- timer callbacks
- explicit `set waitfor = FALSE`

## Debug Order

1. Find the owner subsystem and open its `fire()` or processing file.
2. Inspect the affected datum's `process()` or `tick()` path.
3. Sweep for blocking calls in that path before assuming overload.
4. If the owner is known but the exact break mode is still unclear, open `ai_navigation/failure_modes.md`.
5. If the current source still does not explain the freeze, optionally inspect recent changes.
6. Only then fall back to overload, starvation, or scheduler-budget hypotheses.

## Cheap Search Patterns

- blocking calls in process-heavy code:
  `rg -n "\binput\(|\balert\(|browse\(|do_after\(|sleep\(|waitfor = TRUE|set waitfor = TRUE" code modular_rmh -g "*.dm"`
- async handoff:
  `rg -n "\bINVOKE_ASYNC\b|set waitfor = FALSE|set waitfor = 0|addtimer\(" code modular_rmh -g "*.dm"`
- optional history check:
  `git log --oneline -n 20 -- code/controllers/subsystem/** code/datums/**`

## Interpretation

- If one effect misbehaves, start with local logic.
- If a whole class of effects freezes together, assume shared ownership first.
- If the subsystem stops without runtimes, blocking calls are often a better first hypothesis than raw load.
