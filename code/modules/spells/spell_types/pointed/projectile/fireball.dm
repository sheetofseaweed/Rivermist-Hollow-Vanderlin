/datum/action/cooldown/spell/projectile/fireball
	name = "Fireball"
	desc = "Shoot out a ball of fire that emits a light explosion on impact, setting the target alight."
	button_icon_state = "fireball"
	charge_sound = 'sound/magic/charging_fire.ogg'
	sound = 'sound/magic/fireball.ogg'

	cast_range = 8
	point_cost = 4

	invocation = "ONI SOMA!!!"
	invocation_type = INVOCATION_SHOUT

	charge_time = 2.5 SECONDS
	charge_drain = 1
	charge_slowdown = 0.7
	cooldown_time = 40 SECONDS
	spell_cost = 40
	spell_flags = SPELL_RITUOS
	projectile_type = /obj/projectile/magic/aoe/fireball/rogue

	slot_level = 1
	minor_cost = SPELL_MINOR_COST_DEFAULT
	minor_projectile_type = /obj/projectile/magic/firebolt_minor
	slot_label = "Fireball"
	required_form = FORM_FIRE
	required_technique = TECHNIQUE_DESTRUCTION

/datum/action/cooldown/spell/projectile/fireball/on_start_charge()
	. = ..()
	if(get_effect_level() >= 4)
		to_chat(owner, span_warning("This level-[get_effect_level()] [get_slot_label()] has a wide blast; stay well back from where it lands."))

/// Slot profiles. Legacy mana casts never reach this and keep the projectile's own numbers.
/datum/action/cooldown/spell/projectile/fireball/proc/apply_level_profile(obj/projectile/magic/aoe/fireball/to_fire, level)
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
			to_fire.damage = 75
			to_fire.exp_light = 3
			to_fire.exp_fire = 3
			to_fire.exp_heavy = 0
			to_fire.speed = 4
		// Light range 4 reaches three tiles: a caster at range stays outside it.
		if(5)
			to_fire.damage = 90
			to_fire.exp_light = 4
			to_fire.exp_fire = 3
			to_fire.exp_heavy = 0
			to_fire.speed = 4

/datum/action/cooldown/spell/projectile/fireball/ready_projectile(obj/projectile/magic/aoe/fireball/to_fire, atom/target, mob/user, iteration)
	. = ..()
	var/level = get_effect_level()
	if(isnull(level))
		to_fire.damage *= get_rank_multiplier()
		return
	if(level == SPELL_SLOT_MINOR)
		to_fire.damage = 10 * get_cantrip_multiplier()
		return
	apply_level_profile(to_fire, level)
	to_fire.damage *= get_rank_multiplier()
	if(user)
		to_chat(user, span_notice("The [get_slot_label()] forms at spell level [level]."))

/datum/action/cooldown/spell/projectile/fireball/baali
	name = "Infernal Fireball"

	associated_skill = /datum/attribute/skill/magic/blood

	spell_type = SPELL_BLOOD
	slot_level = null
	learnable = FALSE

	charge_time = 4 SECONDS
	spell_cost = 150
	cooldown_time = 80 SECONDS

/datum/action/cooldown/spell/projectile/fireball/greater
	name = "Fireball (Greater)"
	desc = "Shoot out an immense ball of fire that explodes on impact."
	button_icon_state = "fireball_greater"

	point_cost = 6

	charge_time = 4 SECONDS
	charge_drain = 2
	charge_slowdown = 1.3
	cooldown_time = 70 SECONDS
	spell_cost = 80
	spell_flags = NONE

	projectile_type = /obj/projectile/magic/aoe/fireball/rogue/great

	slot_level = 3
	minor_cost = 0
	minor_projectile_type = null
	slot_label = "Greater Fireball"
	required_level = MASTERY_RANK_EXPERT
	prerequisite_spells = list(/datum/action/cooldown/spell/projectile/fireball)

/datum/action/cooldown/spell/projectile/fireball/greater/apply_level_profile(obj/projectile/magic/aoe/fireball/to_fire, level)
	switch(level)
		if(3)
			to_fire.damage = 110
			to_fire.exp_light = 4
			to_fire.exp_fire = 3
			to_fire.exp_heavy = 0
			to_fire.speed = 6
		if(4)
			to_fire.damage = 130
			to_fire.exp_light = 4
			to_fire.exp_fire = 4
			to_fire.exp_heavy = 0
			to_fire.speed = 6
		// The only heavy blast left; light range 5 reaches four tiles.
		if(5)
			to_fire.damage = 150
			to_fire.exp_light = 5
			to_fire.exp_fire = 4
			to_fire.exp_heavy = 1
			to_fire.speed = 6

/obj/projectile/magic/aoe/fireball/rogue
	name = "fireball"
	exp_heavy = 0
	exp_light = 3
	exp_flash = 0
	exp_fire = 3
	damage = 50
	damage_type = BURN
	nodamage = FALSE
	woundclass = BCLASS_BURN
	flag = "magic"
	hitsound = 'sound/fireball.ogg'
	aoe_range = 0
	speed = 3

/obj/projectile/magic/aoe/fireball/rogue/great
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

/// Minor Fireball: a small fixed blast reaching adjacent tiles, no ignition.
/obj/projectile/magic/firebolt_minor
	name = "minor firebolt"
	icon_state = "fireball"
	damage = 10
	damage_type = BURN
	woundclass = BCLASS_BURN
	flag = "magic"
	nodamage = FALSE
	range = 8
	speed = 3

/obj/projectile/magic/firebolt_minor/on_hit(atom/target)
	. = ..()
	// Explosion ranges are exclusive: light range 2 reaches the adjacent tiles.
	explosion(get_turf(target), devastation_range = 0, heavy_impact_range = 0, light_impact_range = 2, flash_range = 0, adminlog = FALSE, flame_range = 0, hotspot_range = 0, soundin = 'sound/misc/explode/incendiary (1).ogg')
