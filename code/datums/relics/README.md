# Relic system

Relics are atoms with a `/datum/component/relic`. Each relic combines three datums:

- A trigger decides when the relic is active.
- An effect performs the relic's mechanical result.
- An information datum supplies its identity and presentation hooks.

Call `make_relic(trigger_type, effect_type, information_type)` on an atom to assemble one. The information type is optional and defaults to the generic datum.

The baseline secure trigger activates while its item is placed on a matching `/obj/structure/secure_spot`. Periodic effects are processed by `SSrelics`; signal-driven effects register only while the relic is active.
