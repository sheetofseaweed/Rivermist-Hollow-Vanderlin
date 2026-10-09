// DND divine spell variants.

/datum/action/cooldown/spell/healing/dnd
	name = "DND Healing"
	desc = "Heal a target using a spell slot. Healing scales with the selected level. There is no minor form."
	spell_cost = 0
	charge_drain = 0

	spell_flags = NONE
	dnd_use_spell_slots = TRUE
	dnd_min_spell_slot_level = 1
	dnd_max_spell_slot_level = 5
	dnd_spell_slot_label = "Healing"

/datum/action/cooldown/spell/healing/dnd/cast(mob/living/cast_on)
	var/old_base_healing = base_healing
	var/old_wound_modifier = wound_modifier
	var/old_blood_restoration = blood_restoration

	var/level = dnd_get_cast_level()

	switch(level)
		if(1)
			base_healing = 25
			wound_modifier = 0.25
			blood_restoration = 0
		if(2)
			base_healing = 35
			wound_modifier = 0.35
			blood_restoration = 0
		if(3)
			base_healing = 50
			wound_modifier = 0.50
			blood_restoration = BLOOD_VOLUME_SURVIVE / 2
		if(4)
			base_healing = 65
			wound_modifier = 0.65
			blood_restoration = BLOOD_VOLUME_SURVIVE
		if(5)
			base_healing = 80
			wound_modifier = 0.80
			blood_restoration = BLOOD_VOLUME_NORMAL

	. = ..()

	base_healing = old_base_healing
	wound_modifier = old_wound_modifier
	blood_restoration = old_blood_restoration

/datum/action/cooldown/spell/sacred_flame/dnd
	name = "DND Sacred Flame"
	desc = "Strike a target with divine fire. Stacks scale with the selected DND spell slot."
	spell_cost = 0
	charge_drain = 0

	spell_flags = NONE
	dnd_use_spell_slots = TRUE
	dnd_min_spell_slot_level = 1
	dnd_max_spell_slot_level = 5
	dnd_spell_slot_label = "Sacred Flame"

/datum/action/cooldown/spell/sacred_flame/dnd/cast(atom/cast_on)
	var/old_stacks = stacks_to_add
	var/level = dnd_get_cast_level()

	switch(level)
		if(1)
			stacks_to_add = 3
		if(2)
			stacks_to_add = 4
		if(3)
			stacks_to_add = 5
		if(4)
			stacks_to_add = 7
		if(5)
			stacks_to_add = 9

	. = ..()

	stacks_to_add = old_stacks
