// Separate DND Fireball spell.
// Uses /datum/action/cooldown/spell/projectile/dnd_fireball so the normal fireball stays untouched.

/datum/action/cooldown/spell/projectile/dnd_fireball
	name = "DND Fireball"
	desc = "Use a spell slot for a scaling fireball, or select Minor for a 2-mana firebolt with a small blast but no ignition. Minor direct damage is 10 before attunement. A level-five blast can reach the caster!"
	button_icon_state = "fireball"
	charge_sound = 'sound/magic/charging_fire.ogg'
	sound = 'sound/magic/fireball.ogg'

	cast_range = 8
	point_cost = 4
	attunements = list(
		/datum/attunement/fire = 0.5
	)

	invocation = "ONI SOMA!!!"
	invocation_type = INVOCATION_SHOUT

	charge_time = 2.5 SECONDS
	charge_drain = 0
	charge_slowdown = 0.7
	cooldown_time = 10 SECONDS
	spell_cost = 0
	spell_flags = NONE
	projectile_type = /obj/projectile/magic/aoe/fireball/dnd

	dnd_use_spell_slots = TRUE
	dnd_minor_mana_cost = 2
	dnd_minor_projectile_type = /obj/projectile/magic/dnd_ember
	dnd_min_spell_slot_level = 1
	dnd_max_spell_slot_level = 5
	dnd_spell_slot_label = "Fireball"

/datum/action/cooldown/spell/projectile/dnd_fireball/on_start_charge()
	. = ..()
	if(dnd_get_cast_level() == 5)
		to_chat(owner, span_warning("This level-five [dnd_get_spell_label()] has a wide blast that could reach you, even when aimed at a distant target!"))

/datum/action/cooldown/spell/projectile/dnd_fireball/proc/apply_dnd_fireball_level(obj/projectile/magic/aoe/fireball/to_fire)
	if(!to_fire)
		return dnd_get_cast_level()

	var/level = dnd_get_cast_level()

	switch(level)
		if(1)
			to_fire.damage = 35
			to_fire.exp_light = 2
			to_fire.exp_fire = 1
			to_fire.exp_heavy = 0
			to_fire.speed = 3

		if(2)
			to_fire.damage = 45
			to_fire.exp_light = 3
			to_fire.exp_fire = 2
			to_fire.exp_heavy = 0
			to_fire.speed = 3

		if(3)
			to_fire.damage = 60
			to_fire.exp_light = 3
			to_fire.exp_fire = 3
			to_fire.exp_heavy = 0
			to_fire.speed = 3

		if(4)
			to_fire.damage = 80
			to_fire.exp_light = 4
			to_fire.exp_fire = 3
			to_fire.exp_heavy = 0
			to_fire.speed = 4

		if(5)
			to_fire.damage = 110
			to_fire.exp_light = 5
			to_fire.exp_fire = 4
			to_fire.exp_heavy = 1
			to_fire.speed = 5

	return level

/datum/action/cooldown/spell/projectile/dnd_fireball/ready_projectile(obj/projectile/to_fire, atom/target, mob/user, iteration)
	. = ..()

	if(dnd_get_cast_level() == DND_MINOR_TIER)
		to_fire.damage = 10 * clamp(attuned_strength, 0.5, 1.5)
		return

	var/level = apply_dnd_fireball_level(to_fire)

	var/obj/projectile/magic/aoe/fireball/fireball = to_fire
	to_fire.damage *= attuned_strength
	fireball.exp_light *= attuned_strength
	fireball.exp_fire *= attuned_strength

	if(user)
		to_chat(user, span_notice("The Fireball forms at spell level [level]."))

/datum/action/cooldown/spell/projectile/dnd_fireball/greater
	name = "DND Fireball (Greater)"
	desc = "Shoot out an immense ball of fire that scales with the selected DND spell slot. A level-five blast can reach the caster!"
	button_icon_state = "fireball_greater"

	point_cost = 6
	attunements = list(
		/datum/attunement/fire = 1.1,
	)

	charge_time = 4 SECONDS
	charge_drain = 0
	charge_slowdown = 1.3
	cooldown_time = 70 SECONDS
	spell_cost = 0
	spell_flags = NONE

	projectile_type = /obj/projectile/magic/aoe/fireball/dnd/great
	dnd_min_spell_slot_level = 3
	dnd_minor_mana_cost = 0
	dnd_spell_slot_label = "Greater Fireball"

/obj/projectile/magic/aoe/fireball/dnd
	name = "fireball"
	exp_heavy = 0
	exp_light = 2
	exp_flash = 0
	exp_fire = 1
	damage = 35
	damage_type = BURN
	nodamage = FALSE
	flag = "magic"
	hitsound = 'sound/fireball.ogg'
	aoe_range = 0
	speed = 3

/obj/projectile/magic/aoe/fireball/dnd/great
	name = "fireball"
	exp_devi = 0
	exp_heavy = 1
	exp_light = 5
	exp_flash = 0
	exp_fire = 4
	damage = 130
	exp_hotspot = 0
	aoe_range = 0
	speed = 6

/datum/action/cooldown/spell/projectile/dnd_fireball/greater/apply_dnd_fireball_level(obj/projectile/magic/aoe/fireball/to_fire)
	if(!to_fire)
		return dnd_get_cast_level()

	var/level = dnd_get_cast_level()

	switch(level)
		if(3)
			to_fire.damage = 130
			to_fire.exp_light = 5
			to_fire.exp_fire = 4
			to_fire.exp_heavy = 1
			to_fire.speed = 6

		if(4)
			to_fire.damage = 160
			to_fire.exp_light = 6
			to_fire.exp_fire = 5
			to_fire.exp_heavy = 1
			to_fire.speed = 6

		if(5)
			to_fire.damage = 200
			to_fire.exp_light = 7
			to_fire.exp_fire = 6
			to_fire.exp_heavy = 2
			to_fire.speed = 7

	return level

// Keep the minor blast fixed in size and separate from full fireball's ignition.
/obj/projectile/magic/dnd_ember
	name = "minor firebolt"
	icon_state = "fireball"
	damage = 10
	damage_type = BURN
	woundclass = BCLASS_BURN
	flag = "magic"
	nodamage = FALSE
	range = 8
	speed = 3

/obj/projectile/magic/dnd_ember/on_hit(atom/target)
	. = ..()
	// Explosion ranges are exclusive: light range 2 reaches the adjacent tiles.
	explosion(get_turf(target), devastation_range = 0, heavy_impact_range = 0, light_impact_range = 2, flash_range = 0, adminlog = FALSE, flame_range = 0, hotspot_range = 0, soundin = 'sound/misc/explode/incendiary (1).ogg')
