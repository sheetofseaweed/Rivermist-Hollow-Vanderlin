# Content Creation

Generated on 2026-03-11. Use this file when adding new mechanics, gameplay content, or extensions to existing systems.

## Goal

Ship new content quickly without widening the implementation surface more than the feature actually needs.

## Global First

Before choosing code shape, answer these first:

1. Who uses it now?
2. Who is expected to use it later?
3. How many concurrent instances can exist in one round?
4. How often does it trigger:
   - once per spawn
   - once per action
   - once per state change
   - repeatedly while active
   - every step or every tick
5. How long does it stay active?

These answers define the server cost surface before any code is written.

## Fast Algorithm

1. Define the player-facing behavior in one sentence.
2. Define the usage surface:
   - exact user group
   - expected future user group
   - trigger frequency
   - active lifetime
3. Prefer the minimum-server-cost design that satisfies that usage surface.
4. Classify change risk with `ai_navigation/human_checking.md`.
5. If the audience, blast radius, or hot-path cost is unclear, ask the human before choosing architecture.
6. Find the narrowest existing owner branch that already matches that behavior.
7. Reuse the closest existing pattern before inventing a new abstraction.
8. Pick the smallest implementation shape that fits:
   - new subtype or proc override on an existing branch
   - small targeted helper on the narrow host type
   - component or element only if the same behavior must work across unrelated branches
   - subsystem or global hook only if the feature truly needs shared periodic ownership
9. Pick the cheapest trigger surface:
   - explicit action or verb
   - state transition
   - signal or callback
   - gated processing while active
   - per-step or per-tick only as a last resort
10. Gate the behavior by the active state that actually needs it.
11. Check the same branch in `modular_rmh` before adding a duplicate extension path.
12. If the content brief is still vague, open `ai_navigation/content_breakdown.md`.
13. If the implementation shape is still unclear, open `ai_navigation/content_patterns.md`.
14. Define the spawn/trigger/cleanup verification before coding.

## Cost Lens

Prefer solutions in this order when possible:

1. one-shot or action-driven
2. state-change driven
3. signal or callback driven
4. gated processing while active
5. always-on shared processing

The broader the audience and the higher the frequency, the more the design must justify itself.

## Anti-Bloat Rules

- Do not attach logic to `/mob/living` if only carbons need it.
- Do not hook every step, move, or tick if the feature matters only in one temporary state.
- Do not introduce a component if a subtype override or a local proc is enough.
- Do not introduce a status effect if the feature is not a timed temporary state.
- Do not introduce a subsystem for one mostly idle feature.
- Do not generalize across branches until at least two real users need the same abstraction.
- If shared usage is plausible but not confirmed, ask the human instead of speculating.

## Quick Decision Table

| If the feature is | Prefer |
|---|---|
| one branch, one behavior | subtype or narrow proc override |
| narrow audience, low frequency | local proc, action, or state-change hook |
| temporary timed state | status effect |
| shared by a few unrelated branches | component or element |
| player-triggered action | action, spell, verb, or item proc |
| always-on simulation with real shared ownership | subsystem |

## Cheap Questions Before Coding

- Who uses it right now?
- Who might use it later, and is that real or speculative?
- What is the per-round concurrency?
- What is the trigger frequency?
- Can this be event-driven instead of process-driven?
- Does this cross into medium or high risk and need approval first?
- Which existing content pattern already matches this feature?
- What is the delivery channel?
- What is the base archetype?
- What is the actual delta from the base?
- What is the cheapest carrier for the new effect?
- Who is the narrowest correct host type?
- What is the exact trigger?
- When should it stop running?
- Does it need processing at all?
- Does the repo already have the same pattern on a nearby branch?

## Smell Check

If the solution starts drifting toward:

- `all mob/living`
- `every step`
- `every tick`
- a new global subsystem
- a generic component with one real user

stop and shrink the design.
