/datum/action/cooldown/spell/aoe/on_turf/arcyne_storm
	name = "Arcane storm"
	desc = "Conjure ripples of force into existence over a large area, injuring any who enter."
	button_icon_state = "hierophant"

	point_cost = 8

	charge_time = 4 SECONDS
	charge_drain = 1
	cooldown_time = 50 SECONDS
	spell_cost = 40

	aoe_radius = 4

	invocation = "BE TORN APART!!!"
	invocation_type = INVOCATION_SHOUT

	slot_level = 4
	slot_only = TRUE
	slot_label = "Arcane Storm"
	required_form = FORM_ARCANE
	required_technique = TECHNIQUE_DESTRUCTION
	required_level = MASTERY_RANK_MASTER
	prerequisite_spells = list(/datum/action/cooldown/spell/projectile/arcyne_bolt)

	/// Seconds the storm cuts each turf at the spell's own level.
	var/storm_ticks = 16

/datum/action/cooldown/spell/aoe/on_turf/arcyne_storm/cast_on_thing_in_aoe(atom/victim, atom/caster)
	var/level = get_effect_level()
	var/ticks = get_storm_ticks()
	for(var/i in 1 to ticks)
		addtimer(CALLBACK(src, PROC_REF(apply_damage), victim, level), wait = i * 1 SECONDS)

/// Storm length for the cast in progress; upcasting adds half the length per level.
/datum/action/cooldown/spell/aoe/on_turf/arcyne_storm/proc/get_storm_ticks()
	return round(storm_ticks * get_upcast_duration_multiplier())

/datum/action/cooldown/spell/aoe/on_turf/arcyne_storm/proc/apply_damage(turf/victim, level)
	var/tick_damage = round(7 * get_rank_multiplier())
	if(!isnull(level))
		tick_damage = round((level == SPELL_SLOT_MAX ? 9 : 7) * get_rank_multiplier())
	new /obj/effect/temp_visual/arcyne_storm(victim)
	playsound(victim, "genslash", 40, TRUE)
	for(var/mob/living/L in victim.contents)
		L.adjustBruteLoss(tick_damage, damage_type = BCLASS_CUT)
		to_chat(L, span_userdanger("I'm cut by an arcyne force!"))

/obj/effect/temp_visual/arcyne_storm
	name = "vortex energy"
	icon_state = "hierophant_squares"
	layer = BELOW_MOB_LAYER
	duration = 3
	light_outer_range = MINIMUM_USEFUL_LIGHT_RANGE
	randomdir = FALSE
