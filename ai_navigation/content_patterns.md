# Content Patterns

Generated on 2026-03-11. Use this file after `ai_navigation/content_creation.md` when the feature goal is clear but the implementation shape is still undecided.

## Goal

Pick an existing content pattern quickly instead of inventing a new architecture for each feature.

## Pattern Table

| Pattern | Use when | Prefer | Trigger | Avoid | Typical risk |
|---|---|---|---|---|---|
| Cosmetic Variant | behavior is unchanged | subtype, data tweak, icon-state, metadata | none or existing trigger | new logic, new hooks | no |
| Data-Only Content Entry | new recipe, outfit, loot, migrant wave, template, or config-like content | existing data branch | existing system consumes it | adding code if the system already supports the content | no to low |
| Narrow Branch Override | one family needs new behavior | subtype or proc override on the narrowest host | local proc, existing branch events | broad host types, generic components | low |
| Active Item or Verb | player explicitly triggers the feature | item proc, verb, action, spell | explicit input or action | passive always-on processing | low to medium |
| Timed Temporary State | behavior exists only for a bounded active window | status effect or gated local state | apply/remove, state enter/exit | broad per-tick hooks outside the active window | low to medium |
| Structure Interaction | feature belongs to a specific world object family | object subtype or structure-local proc | interaction, attackby, context action, local signal | global hooks on unrelated objects | low to medium |
| Actor Family Behavior | many actors in one real branch share behavior | narrow shared proc, helper, or family-level abstraction | local state change, family-level signal | rooting it at `/mob/living` if only one actor family uses it | medium |
| AI-Only Behavior | NPC or controller logic changes without player-facing universal rules | AI controller, behavior, movement, or AI-specific datum | AI tick, behavior selection, controller events | coupling it to all mobs or all living movement hooks | medium |
| Shared Mechanic | multiple unrelated branches truly need the same rule | component or element | signal, callback, gated processing | speculative reuse with one real user | medium |
| Shared Simulation | the feature has real global ownership and many active instances | subsystem or central manager | scheduler, shared periodic ownership | using a subsystem for low-frequency or one-branch behavior | high |

## Selection Order

1. Try `Cosmetic Variant` or `Data-Only Content Entry` first.
2. If code is required, try `Narrow Branch Override`.
3. If the user explicitly triggers it, try `Active Item or Verb`.
4. If the behavior is temporary, try `Timed Temporary State`.
5. If it belongs to one object family, try `Structure Interaction` or `Actor Family Behavior`.
6. Only then consider `Shared Mechanic`.
7. Use `Shared Simulation` only with clear ownership and human approval.

## Preflight

Before coding, be able to answer all of these:

- Which pattern am I using?
- Why is a smaller pattern not enough?
- What is the exact host branch?
- What is the exact trigger?
- What stops the behavior?
- Is the chosen pattern consistent with `ai_navigation/human_checking.md`?
- Do `ai_navigation/core_procs.md` or `ai_navigation/signal_map.md` suggest a cheaper existing hook?

## Smell Check

Stop and rethink if:

- the feature started as local content but now wants a global subsystem
- the first real user is narrow, but the design is already generic
- per-step or per-tick processing appears before a local trigger has been ruled out
- the host type got broader than the actual audience
