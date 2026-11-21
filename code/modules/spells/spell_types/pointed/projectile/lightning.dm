/datum/action/cooldown/spell/projectile/lightning
	name = "Bolt of Lightning"
	desc = "Emit a bolt of lightning that burns and stuns a target."
	button_icon_state = "lightning"
	sound = 'sound/magic/lightning.ogg'
	charge_sound = 'sound/magic/charging_lightning.ogg'
	sparks_amt = 5

	invocation = "THUNDER STRIKE!!!"
	invocation_type = INVOCATION_SHOUT

	cast_range = 8
	point_cost = 3

	charge_time = 3 SECONDS
	charge_drain = 1
	charge_slowdown = 0.7
	cooldown_time = 30 SECONDS
	spell_cost = 40
	spell_flags = SPELL_RITUOS
	projectile_type = /obj/projectile/magic/lightning

	slot_level = 1
	slot_only = TRUE
	slot_label = "Lightning Bolt"
	required_form = FORM_LIGHTNING
	required_technique = TECHNIQUE_DESTRUCTION

/datum/action/cooldown/spell/projectile/lightning/ready_projectile(obj/projectile/to_fire, atom/target, mob/user, iteration)
	. = ..()
	var/level = get_effect_level()
	if(isnull(level))
		return
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
	to_fire.damage *= get_rank_multiplier()
	if(user)
		to_chat(user, span_notice("The [get_slot_label()] forms at spell level [level]."))

/obj/projectile/magic/lightning
	name = "bolt of lightning"
	tracer_type = /obj/effect/projectile/tracer/stun
	hitscan = TRUE
	movement_type = FLYING
	projectile_piercing = PROJECTILE_PIERCE_HIT
	damage = 15
	damage_type = BURN
	nodamage = FALSE
	woundclass = BCLASS_BURN
	speed = 0.3
	light_color = "#dbe72c"
	light_outer_range =  7

/obj/projectile/magic/lightning/on_hit(atom/target, blocked, pierce_hit)
	. = ..()
	if(isliving(target))
		var/mob/living/L = target
		L.electrocute_act(1, src)
		L.apply_status_effect(/datum/status_effect/debuff/electrified)
