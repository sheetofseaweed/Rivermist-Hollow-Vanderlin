// DND projectile spell variants.
// These are separate /dnd subtypes and do not overwrite the original spells.

/datum/action/cooldown/spell/projectile/acid_splash/dnd
	name = "DND Acid Splash"
	desc = "Shoot acid that scales with the selected DND spell slot."
	spell_cost = 0
	charge_drain = 0
	projectile_type = /obj/projectile/magic/acidsplash/dnd

	spell_flags = NONE
	dnd_use_spell_slots = TRUE
	dnd_min_spell_slot_level = 1
	dnd_max_spell_slot_level = 5
	dnd_spell_slot_label = "Acid Splash"

/datum/action/cooldown/spell/projectile/acid_splash/dnd/ready_projectile(obj/projectile/magic/acidsplash/dnd/to_fire, atom/target, mob/user, iteration)
	. = ..()

	var/level = dnd_get_cast_level()

	switch(level)
		if(1)
			to_fire.damage = 10
			to_fire.aoe_range = 1
			to_fire.strength_modifier = 1
		if(2)
			to_fire.damage = 16
			to_fire.aoe_range = 1
			to_fire.strength_modifier = 2
		if(3)
			to_fire.damage = 24
			to_fire.aoe_range = 2
			to_fire.strength_modifier = 3
		if(4)
			to_fire.damage = 32
			to_fire.aoe_range = 2
			to_fire.strength_modifier = 4
		if(5)
			to_fire.damage = 40
			to_fire.aoe_range = 3
			to_fire.strength_modifier = 5

	to_fire.damage *= attuned_strength
	to_fire.aoe_range *= attuned_strength
	to_fire.strength_modifier *= attuned_strength

	if(user)
		to_chat(user, span_notice("The Acid Splash forms at spell level [level]."))

/obj/projectile/magic/acidsplash/dnd
	name = "acid splash"
	damage = 10
	aoe_range = 1
	strength_modifier = 1


/datum/action/cooldown/spell/projectile/frost_bolt/dnd
	name = "DND Frost Bolt"
	desc = "Use a spell slot for scaling frost damage and frostbite, or select Minor for a 2-mana bolt without frostbite. Minor damage is 10 before attunement."
	spell_cost = 0
	charge_drain = 0
	projectile_type = /obj/projectile/magic/frostbolt/dnd
	dnd_minor_mana_cost = 2
	dnd_minor_projectile_type = /obj/projectile/magic/dnd_frost

	spell_flags = NONE
	dnd_use_spell_slots = TRUE
	dnd_min_spell_slot_level = 1
	dnd_max_spell_slot_level = 5
	dnd_spell_slot_label = "Frost Bolt"

/datum/action/cooldown/spell/projectile/frost_bolt/dnd/ready_projectile(obj/projectile/to_fire, atom/target, mob/user, iteration)
	. = ..()

	var/level = dnd_get_cast_level()
	if(level == DND_MINOR_TIER)
		to_fire.damage = 10 * clamp(attuned_strength, 0.5, 1.5)
		return

	switch(level)
		if(1)
			to_fire.damage = 25
		if(2)
			to_fire.damage = 35
		if(3)
			to_fire.damage = 45
		if(4)
			to_fire.damage = 60
		if(5)
			to_fire.damage = 75

	to_fire.damage *= attuned_strength

	if(user)
		to_chat(user, span_notice("The Frost Bolt forms at spell level [level]."))

/obj/projectile/magic/frostbolt/dnd
	name = "frost bolt"
	damage = 25

// Minor frost deals direct damage without the frostbite on-hit effect.
/obj/projectile/magic/dnd_frost
	name = "minor frost bolt"
	icon_state = "ice_2"
	damage = 10
	damage_type = BURN
	woundclass = BCLASS_BURN
	nodamage = FALSE
	range = 10
	speed = 1


/datum/action/cooldown/spell/projectile/lightning/dnd
	name = "DND Lightning Bolt"
	desc = "Shoot lightning that scales with the selected DND spell slot."
	spell_cost = 0
	charge_drain = 0
	projectile_type = /obj/projectile/magic/lightning/dnd

	spell_flags = NONE
	dnd_use_spell_slots = TRUE
	dnd_min_spell_slot_level = 1
	dnd_max_spell_slot_level = 5
	dnd_spell_slot_label = "Lightning Bolt"

/datum/action/cooldown/spell/projectile/lightning/dnd/ready_projectile(obj/projectile/magic/lightning/dnd/to_fire, atom/target, mob/user, iteration)
	. = ..()

	var/level = dnd_get_cast_level()

	switch(level)
		if(1)
			to_fire.damage = 15
		if(2)
			to_fire.damage = 25
		if(3)
			to_fire.damage = 40
		if(4)
			to_fire.damage = 55
		if(5)
			to_fire.damage = 70

	to_fire.damage *= attuned_strength

	if(user)
		to_chat(user, span_notice("The Lightning Bolt forms at spell level [level]."))

/obj/projectile/magic/lightning/dnd
	name = "lightning bolt"
	damage = 15
