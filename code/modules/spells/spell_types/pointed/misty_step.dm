// Misty Step: a short blink to a seen tile.
/datum/action/cooldown/spell/misty_step
	name = "Misty Step"
	desc = "Vanish in a puff of mist and reappear on an open tile you can see, up to 5 tiles away. Each slot level above the second adds two tiles, to at most 9."
	button_icon_state = "air_walk"
	sound = 'sound/magic/ethereal_enter.ogg'

	invocation = "Through the mist."
	invocation_type = INVOCATION_WHISPER

	self_cast_possible = FALSE
	// The clicked tile is the destination, not a mob standing on it.
	aim_assist = FALSE
	cast_range = 5
	charge_required = FALSE
	cooldown_time = 30 SECONDS
	spell_cost = 40

	slot_level = 2
	slot_level_max = 4
	slot_only = TRUE
	slot_label = "Misty Step"
	required_form = FORM_ARCANE
	required_technique = TECHNIQUE_ALTERATION
	required_level = MASTERY_RANK_ADEPT
	learnable = TRUE

	/// Tiles of reach gained per slot level above the spell's own.
	var/range_per_upcast = 2
	/// Farthest blink at any slot level.
	var/max_range = 9

/// Five tiles at level 2, seven at level 3, nine from level 4.
/datum/action/cooldown/spell/misty_step/get_cast_range()
	return min(cast_range + range_per_upcast * get_upcast_steps(), max_range)

/// The blink carries only the caster, so Distant has no range to double.
/datum/action/cooldown/spell/misty_step/metamagic_fits(id)
	if(id == METAMAGIC_DISTANT)
		return FALSE
	return ..()

/datum/action/cooldown/spell/misty_step/is_valid_target(atom/cast_on)
	return ..() && !isnull(get_turf(cast_on))

/datum/action/cooldown/spell/misty_step/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	// Refusing here spends neither the slot nor the cooldown.
	var/refusal = get_blink_refusal(get_turf(cast_on))
	if(refusal)
		owner.balloon_alert(owner, refusal)
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/misty_step/cast(atom/cast_on)
	. = ..()
	var/mob/living/blinker = owner
	var/turf/origin = get_turf(blinker)
	var/turf/destination = get_turf(cast_on)
	blinker.buckled?.unbuckle_mob(blinker, force = TRUE)
	new /obj/effect/temp_visual/small_smoke/misty_step(origin)
	blinker.visible_message(span_notice("[blinker] vanishes in a puff of mist!"), span_notice("I step into the mist."))
	if(!do_teleport(blinker, destination, asoundout = 'sound/magic/ethereal_exit.ogg', channel = TELEPORT_CHANNEL_MAGIC))
		blinker.balloon_alert(blinker, "the mist scatters!")
		return
	new /obj/effect/temp_visual/small_smoke/misty_step(destination)
	blinker.visible_message(span_notice("[blinker] steps out of a puff of mist."), ignored_mobs = blinker)

/// Why the caster cannot blink to the destination, or null when the blink can happen.
/datum/action/cooldown/spell/misty_step/proc/get_blink_refusal(turf/destination)
	var/turf/origin = get_turf(owner)
	if(!isturf(owner.loc) || !origin)
		return "no room to blink!"
	if(!destination || destination.z != origin.z)
		return "can't see there!"
	if(destination == origin)
		return "already here!"
	if(isclosedturf(destination) || destination.density)
		return "can't blink into a wall!"
	if(destination.is_blocked_turf())
		return "something is in the way!"
	if(isopenspace(destination))
		return "no footing there!"
	if(!has_line_of_sight(origin, destination))
		return "can't see there!"
	var/area/origin_area = get_area(origin)
	var/area/destination_area = get_area(destination)
	if(HAS_TRAIT(owner, TRAIT_NO_TELEPORT) || destination.is_transition_turf() || ((origin_area.area_flags | destination_area.area_flags) & NO_TELEPORT))
		return "the mist will not carry me there!"
	return null

/// Every tile after the origin, destination included, must let sight through; closed doors block it.
/datum/action/cooldown/spell/misty_step/proc/has_line_of_sight(turf/origin, turf/destination)
	for(var/turf/step_turf in get_line(origin, destination))
		if(step_turf != origin && step_turf.has_opaque_atom)
			return FALSE
	return TRUE

/// A pale puff left where the caster vanishes and where they reappear.
/obj/effect/temp_visual/small_smoke/misty_step
	color = "#DCE6EE"
	alpha = 200
	duration = 1.2 SECONDS
