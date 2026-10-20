/datum/action/cooldown/spell/projectile/fire_flare
	name = "Fire Flare"
	desc = "Shoot out a low-powered ball of fire that shines brightly on impact, potentially blinding a target."
	button_icon_state = "fireball_multi"
	sound = 'sound/magic/whiteflame.ogg'
	charge_sound = 'sound/magic/charging_fire.ogg'

	point_cost = 3

	charge_time = 2 SECONDS
	charge_drain = 1
	charge_slowdown = 0.7
	cooldown_time = 15 SECONDS
	spell_cost = 40
	spell_flags = SPELL_RITUOS
	projectile_type = /obj/projectile/magic/aoe/fireball/flare

	slot_level = 1
	minor_cost = SPELL_MINOR_COST_DEFAULT
	slot_label = "Fire Flare"
	required_form = FORM_FIRE

/datum/action/cooldown/spell/projectile/fire_flare/ready_projectile(obj/projectile/magic/aoe/fireball/to_fire, atom/target, mob/user, iteration)
	. = ..()
	var/level = get_effect_level()
	if(isnull(level))
		to_fire.damage *= get_rank_multiplier()
		return
	if(level == SPELL_SLOT_MINOR)
		to_fire.damage = 5 * get_cantrip_multiplier()
		to_fire.exp_flash = 1
		return
	// The flash widens by one tile every two levels.
	switch(level)
		if(1)
			to_fire.damage = 10
			to_fire.exp_flash = 1
		if(2)
			to_fire.damage = 15
			to_fire.exp_flash = 1
		if(3)
			to_fire.damage = 20
			to_fire.exp_flash = 2
		if(4)
			to_fire.damage = 25
			to_fire.exp_flash = 2
		if(5)
			to_fire.damage = 30
			to_fire.exp_flash = 3
	to_fire.damage *= get_rank_multiplier()
	if(user)
		to_chat(user, span_notice("The [get_slot_label()] forms at spell level [level]."))

/obj/projectile/magic/aoe/fireball/flare
	name = "spitfire"
	exp_heavy = 0
	exp_light = 0
	exp_flash = 1
	exp_fire = 0
	speed = 2.5
