# Content Breakdown

Generated on 2026-03-11. Use this file when the user gives a fantasy-level content request and it must be decomposed into the cheapest real implementation.

## Goal

Turn a vague feature brief into a minimal implementation spec before code is written.

## Breakdown Order

1. Delivery channel
2. Base archetype
3. Delta set
4. Effect carrier
5. Trigger model
6. Scope and guards
7. Verification

## Questions To Answer

### 1. Delivery Channel

How does the content enter the game?

- crafting
- job or class loadout
- roundstart spawn
- loot or map placement
- merchant/shop
- admin-only
- donor or special entitlement

Prefer the cheapest existing delivery path instead of inventing a new one.

### 2. Base Archetype

What is the closest existing thing to extend?

- existing item subtype
- existing mob subtype
- existing spell/action/status
- existing structure/object family
- existing data entry such as recipe, outfit, wave, or template

Start from the nearest working archetype before adding new logic.

### 3. Delta Set

What is actually different from the base?

- visuals
- stats
- restrictions
- acquisition rules
- on-use behavior
- on-hit behavior
- passive behavior

If the delta is mostly visual or data-only, keep it that way.

### 4. Effect Carrier

What is the cheapest place to hold the new behavior?

Prefer in this order:

1. existing subtype vars or proc override
2. existing local on-use/on-hit proc
3. existing action, spell, or status effect path
4. small local helper datum
5. component or element
6. subsystem or global manager

Do not jump to a reusable carrier until the actual audience requires reuse.

### 5. Trigger Model

When does the effect happen?

- on spawn
- on equip
- on wield
- on use
- on hit
- on state change
- while active
- every step or tick

Prefer event-driven triggers over continuous processing.

### 6. Scope And Guards

Who can obtain it, who can use it, and who should process it?

- exact user audience
- exact host branch
- usage restrictions
- active-state gates
- server-cost gates

### 7. Verification

Define this before coding:

- how it is obtained
- how it is activated
- what the visible effect is
- what should not be affected

## Example Shape

Request:

- "I want a paladin sword that burns with fire."

Cheap decomposition:

1. Delivery channel:
   paladin loadout, crafting recipe, or merchant stock
2. Base archetype:
   nearest existing sword subtype
3. Delta set:
   icon/state, maybe stat tweaks, fire-on-hit behavior
4. Effect carrier:
   local on-hit proc or nearest existing weapon effect path first
5. Trigger model:
   on successful hit, not every tick
6. Scope and guards:
   only that sword branch, only users who obtain the sword
7. Verification:
   obtain sword -> hit target -> see fire effect -> unrelated swords unchanged

## Smell Check

Stop and rethink if:

- delivery requires a whole new system for one content entry
- there is no clear base archetype, but you are already designing abstractions
- the delta is small, but the carrier became global
- the trigger is event-driven, but the implementation became per-tick
