/datum/action/cooldown/spell/blade_burst
	name = "Blade Burst"
	desc = "Summon a storm of arcyne force in an area that damages through armor, wounding anything in that location after a delay."
	button_icon_state = "blade_burst"
	self_cast_possible = FALSE

	point_cost = 2

	invocation = "Earth pierce you!!!"
	invocation_type = INVOCATION_SHOUT

	spell_flags = SPELL_RITUOS
	charge_time = 2 SECONDS
	charge_drain = 1
	charge_slowdown = 0.7
	cooldown_time = 20 SECONDS
	spell_cost = 30

	slot_level = 1
	minor_cost = SPELL_MINOR_COST_DEFAULT
	slot_label = "Blade Burst"
	required_form = FORM_EARTH
	required_technique = TECHNIQUE_CREATION

/datum/action/cooldown/spell/blade_burst/cast(atom/cast_on)
	. = ..()
	var/turf/T = get_turf(cast_on)
	new /obj/effect/temp_visual/trap(T)
	playsound(T, 'sound/magic/blade_burst.ogg', 80, TRUE, soundping = TRUE)
	addtimer(CALLBACK(src, PROC_REF(send_blades), T, get_effect_level()), 1 SECONDS)

/// Damage per slot level; Minor casts cut without fracturing.
/datum/action/cooldown/spell/blade_burst/proc/get_level_damage(level)
	switch(level)
		if(2)
			return 55
		if(3)
			return 65
		if(4)
			return 80
		if(5)
			return 95
	return 45

/datum/action/cooldown/spell/blade_burst/proc/send_blades(turf/victim, level)
	var/scaled_damage = round(45 * get_rank_multiplier())
	var/can_fracture = TRUE
	if(level == SPELL_SLOT_MINOR)
		scaled_damage = 15 * get_cantrip_multiplier()
		can_fracture = FALSE
	else if(!isnull(level))
		scaled_damage = round(get_level_damage(level) * get_rank_multiplier())
	new /obj/effect/temp_visual/blade_burst(victim)
	playsound(victim,'sound/combat/newstuck.ogg', 80, TRUE, soundping = TRUE)
	for(var/mob/living/L in victim)
		var/def_zone = pick(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
		L.apply_damage(scaled_damage, BRUTE, def_zone)
		var/obj/item/bodypart/BP = L.get_bodypart(def_zone)
		if(BP)
			var/probby = (BP.get_damage() / BP.max_damage) * 20
			if(can_fracture && prob(probby))
				BP.add_wound(/datum/wound/fracture)
		L.adjustBruteLoss(scaled_damage, damage_type = BCLASS_CUT)
		to_chat(L, span_userdanger("I'm cut by arcyne force!"))

/obj/effect/temp_visual/trap
	icon = 'icons/effects/effects.dmi'
	icon_state = "trap"
	light_outer_range =  2
	duration = 7
	plane = GAME_PLANE_UPPER

/obj/effect/temp_visual/blade_burst
	icon = 'icons/effects/effects.dmi'
	icon_state = "grassblade"
	randomdir = FALSE
	duration = 1 SECONDS
