// Slot-only prototype: retains the existing familiar's behavior and lifetime.
/datum/action/cooldown/spell/conjure/familiar/dnd
	name = "DND Familiar"
	desc = "Summon a familiar using a level 2 or higher spell slot. There is no minor form."
	spell_cost = 0
	charge_drain = 0
	spell_flags = NONE
	dnd_use_spell_slots = TRUE
	dnd_min_spell_slot_level = 2
	dnd_spell_slot_label = "Familiar"
