# Failure Modes

Generated on 2026-03-11. Use this file after the owner subsystem or datum family is known, but the exact break mode is still unclear.

## Use This Helper When

- you know which `SS*` or datum family owns the problem
- the symptom is real, but the cause is still ambiguous
- you need to separate `where it breaks` from `how it breaks`

## Scale First

Classify the scope before picking a cause:

- one effect or object is wrong
- one family of effects is wrong
- all effects in the same subsystem freeze
- the whole subsystem stops firing

Larger scope usually means shared ownership or shared execution failure.

## Common Failure Modes

### Whole subsystem or process family freezes

- blocking call in `process()`, `tick()`, `fire()`, or a directly-called proc
- subsystem no longer firing or stuck in the wrong state
- datums dropped from the processing list
- `PROCESS_KILL` returned too early
- early `return`, `pause()`, or bad resume path
- scheduler pressure or starvation

### Single effect or single object gets stuck

- duration or timer never set correctly
- effect never entered the processing list
- `process()` runs, but expiry logic never reaches `qdel()`
- `on_remove()` or cleanup never runs
- refresh/replace semantics hide the real active instance
- the visual or trait cleanup path differs from the lifecycle path

## Cheap Distinguishers

- `everything froze at once` points to shared execution, not local logic
- `no runtimes` makes blocking or silent scheduler issues more likely
- `effect exists but never clears` points to expiry or cleanup
- `effect vanishes too early` points to replace/refresh or bad `qdel`

## Cheap Search Patterns

- owner subsystem state and calls:
  `rg -n "\bSS[A-Z][A-Za-z0-9_]*\b|PROCESS_KILL|pause\(|currentrun|processing \+=" code modular_rmh -g "*.dm"`
- lifecycle and cleanup:
  `rg -n "qdel\(|Destroy\(|on_remove\(|before_remove\(|refresh\(|be_replaced\(" code modular_rmh -g "*.dm"`
- entry into processing:
  `rg -n "START_PROCESSING\(|STOP_PROCESSING\(" code modular_rmh -g "*.dm"`

## Rule Of Thumb

- First identify the owner.
- Then classify the scale of the failure.
- Then test failure modes in this order:
  blocking -> not firing -> dropped from list -> wrong cleanup -> starvation.
