# Human Checking

Generated on 2026-03-11. Use this file before edits when the planned change may have a wide blast radius, uncertain audience, or non-trivial server cost.

## Goal

Force a human approval checkpoint before medium-risk, high-risk, or ambiguous-scope work.

## Risk Tiers

### No Risk

Safe to implement without a special approval checkpoint.

Typical examples:

- isolated cosmetic variant of an existing item, mob, or content entry
- recolor, icon-state swap, name, description, or metadata change
- one-off subtype that reuses existing behavior exactly

### Low Risk

Usually safe to implement after a brief scope note, without stopping for approval.

Typical examples:

- unique object or actor on an isolated branch
- localized proc override for one narrow family
- one-off feature used by a small, known audience

### Medium Risk

Requires human approval before edits.

Typical examples:

- shared mechanic for a broad family, common object family, large actor population, or other high-count branch
- component or element intended for multiple real users
- change to shared status, action, AI, job, or content flow that many actors can reach
- any design where expected audience is large, such as 200-300 active objects in a round

### High Risk

Requires explicit human approval before edits and a short risk summary.

Typical examples:

- `code/controllers/subsystem/**`, `code/controllers/master.dm`, `code/world.dm`
- base roots or shared abstractions like `/mob/living`, `/obj/item`, `/datum/status_effect`, `/datum/component`, `/datum/element`
- per-step, per-tick, per-fire, or always-on hooks across a large population
- global signals, shared processing lists, AI-wide loops, roundstart ownership, worldgen, economy, or other system-wide paths

## Default Rule

If scope is unclear, treat it as at least `medium` until the user clarifies the intended audience and blast radius.

## Approval Gates

- `no risk`: proceed
- `low risk`: state the local scope and proceed
- `medium risk`: ask for approval before editing
- `high risk`: ask for approval before editing and state the likely blast radius and server-cost risks
- `unknown risk`: ask for clarification before editing

## Questions To Ask The Human

Ask only what is needed to constrain the blast radius:

1. Who should use this right now?
2. Who is realistically expected to use it later?
3. Is touching a shared branch acceptable, or should this stay local?
4. Is per-step or per-tick behavior acceptable, or must this stay event-driven?
5. Is minimum server cost more important than future reuse for this feature?

## Rule Of Thumb

- Unique cosmetic/content variant: usually `no risk`
- Unique isolated gameplay object: usually `low risk`
- Shared mechanic with many real users: usually `medium risk`
- Subsystems, shared roots, and hot paths: usually `high risk`
