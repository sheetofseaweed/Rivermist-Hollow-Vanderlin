/datum/action/cooldown/spell/projectile/frost_bolt
	name = "Frost Bolt"
	desc = "A ray of frozen energy, slowing the first thing it touches and lightly damaging it."
	button_icon_state = "frostbite"
	sound = 'sound/magic/whiteflame.ogg'

	point_cost = 1

	invocation = "Beam of Frost!!"
	invocation_type = INVOCATION_SHOUT

	charge_time = 2 SECONDS
	charge_drain = 1
	charge_slowdown = 0.7
	cooldown_time = 20 SECONDS
	spell_cost = 30
	spell_flags = SPELL_RITUOS
	projectile_type = /obj/projectile/magic/frostbolt

	slot_level = 1
	minor_cost = SPELL_MINOR_COST_DEFAULT
	minor_projectile_type = /obj/projectile/magic/frostbolt_minor
	slot_label = "Frost Bolt"
	required_form = FORM_ICE
	required_technique = TECHNIQUE_DESTRUCTION

/datum/action/cooldown/spell/projectile/frost_bolt/cast(atom/cast_on)
	. = ..()
	owner.visible_message(span_warning("[owner] hurls a frosty beam at [cast_on]!"), span_notice("You hurl a frosty beam at [cast_on]!"))

/datum/action/cooldown/spell/projectile/frost_bolt/ready_projectile(obj/projectile/to_fire, atom/target, mob/user, iteration)
	. = ..()
	var/level = get_effect_level()
	if(isnull(level))
		to_fire.damage *= get_rank_multiplier()
		return
	if(level == SPELL_SLOT_MINOR)
		to_fire.damage = 10 * get_cantrip_multiplier()
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
	to_fire.damage *= get_rank_multiplier()
	if(user)
		to_chat(user, span_notice("The [get_slot_label()] forms at spell level [level]."))

/// Minor Frost Bolt: direct damage without frostbite.
/obj/projectile/magic/frostbolt_minor
	name = "minor frost bolt"
	icon_state = "ice_2"
	damage = 10
	damage_type = BURN
	woundclass = BCLASS_BURN
	nodamage = FALSE
	range = 10
	speed = 1

/obj/projectile/magic/frostbolt
	name = "frost bolt"
	icon_state = "ice_2"
	damage = 25
	damage_type = BURN
	woundclass = BCLASS_BURN
	range = 10
	speed = 1

/obj/projectile/magic/frostbolt/on_hit(atom/target, blocked = FALSE, pierce_hit)
	. = ..()
	if(isliving(target))
		var/mob/living/L = target
		L.apply_status_effect(/datum/status_effect/debuff/frostbite)
		new /obj/effect/temp_visual/snap_freeze(get_turf(L))
