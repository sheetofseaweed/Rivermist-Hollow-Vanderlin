# Hybrid casting prototype

This is an opt-in prototype. Normal learned spells and class loadouts still use
their existing resources. The DND variants use numbered spell slots; Fireball
and Frost Bolt also support an explicitly selected **Minor** mode using mana.

## Try it

1. Use the existing admin **Give Spell** tool to grant **DND Fireball**, **DND
   Frost Bolt**, **DND Healing**, and **DND Familiar** to a human character.
   Granting the first variant initializes slots and adds the HUD automatically.
   The hidden, debug-rights-only **Grant DND Spell Pack** verb grants the whole
   experimental set and resets its reserves.
2. Select **MIN** beside the numbered slot buttons to cast minor spells. The
   selected button is gold and its tooltip says **Selected**. Selection remains
   available while numbered slots remain; there is no automatic fallback or
   automatic spending of a higher tier.
3. Select a numbered tier for full-strength casting. Empty or incompatible tiers
   refuse the cast. Healing and Familiar cannot be cast in Minor mode. Familiar
   requires tier 2 or higher and otherwise retains the original familiar behavior.
4. Start charging, change the selector, then release. The charging spell keeps
   its original tier; the new selection applies to the next cast.

## Initial tuning

| Spell | Minor effect | Minor mana cost | Paid effect |
| --- | --- | --- | --- |
| Fireball | Direct burn damage and a fixed light blast reaching adjacent tiles; no ignition | 2 | Existing tier 1–5 fireball scaling |
| Frost Bolt | Direct burn damage; no frostbite handler | 2 | Existing tier 1–5 frost scaling and frostbite |
| Healing | Unavailable | — | Existing tier 1–5 healing |
| Familiar | Unavailable | — | Existing familiar, tier 2–5 |

Minor damage starts at 10, with attunement scaling capped to 0.5–1.5 (5–15
direct damage). Minor Fireball also causes a light explosion (range parameter 2,
exclusive), without heavy damage, flash, or fire. Its blast does not scale with
attunement and can hit nearby allies or the caster. Both Fireball variants warn
the caster when charging at level five, before releasing the wide blast.
Mana payment uses the existing pools, foci, and attunement cost rules;
2 is the base cost, not necessarily the physical drain from a particular pool.
Charge times and cooldowns remain those of the existing variants. Regeneration
has not been globally changed. Combat sustainability still needs playtesting.

The other DND variants remain slot-only. All experimental variants are excluded
from Rituos discovery until their normal acquisition is deliberately designed.

## Resource contract

- Slots and mana are alternative costs, never simultaneous costs for these spells.
- A tier is locked at charge start, or at activation for an uncharged spell.
- Target/casting restrictions and final resource checks precede payment.
- Payment happens once immediately before releasing the effect. A missed
  projectile is still a spent cast; cancellation before release is free.
- Paid casts award normal casting XP using a provisional cost equivalent of
  10 per slot tier. Minor casts award neither casting XP nor projectile-hit XP.
- Slot capacity is independent of sprite capacity; tooltips show actual counts.
- Slot state belongs to the human body. Class progression, mind/body transfer
  policy, and conversion of the normal learning tree are outside this prototype.

## Recovery

Lie down and **left-click the rest button** for a 60-second short rest. It
recovers up to eight spell levels: each restored slot costs its tier. The tier
selected at the start gets priority, then remaining points go to tiers 1�5 in
ascending order. MIN prioritizes cheap slots. Unspent points do not carry over.
From empty, prioritizing tier 5 restores one fifth-tier and three first-tier
slots; selecting MIN restores four first-tier and two second-tier slots.

There are two baseline short-rest charges. Eternal Wellspring grants a third,
including one immediately available charge, without refilling spent charges.
Its existing mana bonuses, prerequisites and purchase cost are unchanged.
Buying it before receiving a slot spell also works. Reapplying the rest unlock
cannot farm charges. The HUD shows the actual count even though the old sprites
only depict up to two charges.

**Right-click the rest button while lying down** to begin a five-minute sleep.
The normal Sleep verb only supplies a short nap, so this action supplies enough
sleep for full recovery. Any continuous five-minute sleep can restore all slots
and rest charges; fatigue is no longer a prerequisite. Sleep Potion does not
skip the timer. Mana recovery remains independent.

Movement, attacks, spellcasting, damage, loss of the required resting/sleeping
state, and death interrupt recovery. Turning or changing held items alone do not.
Charging a spell prevents recovery. Interrupted rests grant nothing and spend
nothing; a new attempt starts from zero. Charges are spent only when a short
rest completes with slots to recover. Full reserves cannot waste a charge.
There are no partial long-rest rewards, bed bonuses or safe-zone requirements.
The 60-second/5-minute durations and eight-point budget are prototype tuning.

## Verification

Run `BUILD.cmd` to compile. Run
`tools\build\build.bat dm-test -DFOCUS_DND_CASTING` for the focused runtime test.
It covers the actual activation/payment path, exact-cost and insufficient mana,
slot exhaustion, cancellation, tier locking, slot-only restrictions, minor
projectile profiles, ordinary mana-spell compatibility, recovery allocation,
Wellspring progression, interruptions, and both complete recovery timers. The
focused run includes roughly six minutes of timed recovery checks; ordinary
unit-test runs skip those two long waits.

For client testing, also check HUD creation/reconnection, hiding and showing the
HUD, readable selection, empty-tier feedback, interrupted charges, and combat
against a pursuing enemy with normal starting equipment. Automated checks do
not establish whether the initial damage/cooldowns feel useful in combat.
