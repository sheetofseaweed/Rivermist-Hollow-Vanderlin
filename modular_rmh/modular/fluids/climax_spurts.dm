// A climax outside the body comes in spurts: each lands where the aim is at that moment, or drifts down the body.

/datum/component/arousal
	/// Spurts of a climax still in flight, so a squeeze can choke them off.
	var/datum/climax_spurts/active_spurts

/// Splits a load into one to three spurts, bigger loads in more of them.
/proc/get_climax_spurt_amounts(total)
	if(total < CLIMAX_SPURT_TWO_UNITS)
		return list(total)
	if(total <= CLIMAX_SPURT_THREE_UNITS)
		return list(total * 0.6, total * 0.4)
	return list(total * 0.5, total * 0.3, total * 0.2)

/// The aim on the climaxer's cock, when it has a target and this climax comes from a hand on it.
/datum/component/arousal/proc/get_steering_aim(datum/sex_action/action)
	var/mob/living/climaxer = parent
	var/obj/item/organ/genitals/penis/penis = climaxer.getorganslot(ORGAN_SLOT_PENIS)
	var/datum/climax_aim/aim = penis?.climax_aim
	if(!aim?.target)
		return null
	if(action && action.get_grip_owner(action.action_user, action.action_target) != climaxer)
		return null
	return aim

/// Lands a steered climax in spurts; FALSE when the aim is gone, so the normal routing runs.
/datum/component/arousal/proc/climax_at_aim(datum/climax_aim/aim, datum/sex_action/action, mob/living/action_initiator, mob/living/action_target, atom/action_performer)
	var/mob/living/carbon/climaxer = parent
	var/obj/item/organ/genitals/filling_organ/testicles/testes = climaxer.getorganslot(ORGAN_SLOT_TESTICLES)
	if(!testes?.reagents)
		return FALSE
	if(!aim.get_valid_target())
		if(aim.aimer)
			to_chat(aim.aimer, span_warning("I lose my aim."))
		aim.clear()
		return FALSE
	var/mob/living/aimed_mob = isliving(aim.target) ? aim.target : null
	var/into_mouth = start_spurts(aim, testes.get_climax_release(ORGASM_LOCATION_ONTO), FALSE, action, action_initiator, action_target, action_performer)
	var/obj/item/organ/genitals/filling_organ/vagina/vag = climaxer.getorganslot(ORGAN_SLOT_VAGINA)
	if(vag?.reagents)
		vag.produce_climax_fluid()
	if(testes.reagents.total_volume <= testes.reagents.maximum_volume / 4)
		to_chat(climaxer, span_info("Damn, my [pick(testes.altnames)] are pretty dry now."))
	after_ejaculation(into_mouth, climaxer, aimed_mob, action, action_initiator, action_target, action_performer)
	return TRUE

/// Begins a spurting climax at the aim; returns TRUE when the first spurt went into a mouth.
/datum/component/arousal/proc/start_spurts(datum/climax_aim/aim, total, quiet_first, datum/sex_action/action, mob/living/action_initiator, mob/living/action_target, atom/action_performer, transient_aim = FALSE)
	if(active_spurts)
		qdel(active_spurts)
	active_spurts = new(src, aim, total, quiet_first, action, action_initiator, action_target, action_performer, transient_aim)
	return active_spurts.pulse()

/// One climax's spurts, fired one after another.
/datum/climax_spurts
	var/datum/component/arousal/arousal
	var/datum/climax_aim/aim
	/// The aim's revision when the climax began; a newer one means someone re-aimed.
	var/start_revision
	var/list/amounts
	var/pulse_index = 0
	/// The action already announced the climax, so the first spurt stays quiet.
	var/quiet_first = FALSE
	/// The aim was made for this climax alone and goes with it.
	var/transient_aim = FALSE
	var/datum/sex_action/action
	var/mob/living/action_initiator
	var/mob/living/action_target
	var/atom/action_performer
	var/timer_id

/datum/climax_spurts/New(datum/component/arousal/new_arousal, datum/climax_aim/new_aim, total, new_quiet_first, datum/sex_action/new_action, mob/living/new_initiator, mob/living/new_target, atom/new_performer, new_transient_aim)
	arousal = new_arousal
	aim = new_aim
	start_revision = aim.revision
	amounts = get_climax_spurt_amounts(total)
	quiet_first = new_quiet_first
	transient_aim = new_transient_aim
	action = new_action
	action_initiator = new_initiator
	action_target = new_target
	action_performer = new_performer

/datum/climax_spurts/Destroy(force)
	if(timer_id)
		deltimer(timer_id)
		timer_id = null
	if(arousal?.active_spurts == src)
		arousal.active_spurts = null
	if(transient_aim)
		QDEL_NULL(aim)
	aim = null
	arousal = null
	action = null
	action_initiator = null
	action_target = null
	action_performer = null
	return ..()

/// Fires the next spurt and schedules the one after; TRUE when it went into a mouth.
/datum/climax_spurts/proc/pulse()
	if(timer_id)
		deltimer(timer_id)
		timer_id = null
	if(QDELETED(arousal) || QDELETED(arousal.parent) || QDELETED(aim) || pulse_index >= length(amounts))
		qdel(src)
		return FALSE
	pulse_index++
	var/datum/sex_action/live_action = QDELETED(action) ? null : action
	var/drift = aim.revision == start_revision ? pulse_index - 1 : 0
	var/into_mouth = arousal.deliver_spurt(aim, amounts[pulse_index], drift, pulse_index == 1 && quiet_first, pulse_index > 1, live_action, action_initiator, action_target, action_performer)
	if(pulse_index < length(amounts))
		timer_id = addtimer(CALLBACK(src, PROC_REF(pulse)), CLIMAX_SPURT_INTERVAL, TIMER_STOPPABLE)
	else
		qdel(src)
	return into_mouth

/// A squeeze chokes off the spurts still to come; returns the units held back.
/datum/climax_spurts/proc/choke()
	. = 0
	for(var/i in (pulse_index + 1) to length(amounts))
		. += amounts[i]
	qdel(src)

/// Lands one spurt; TRUE when it went into a mouth.
/datum/component/arousal/proc/deliver_spurt(datum/climax_aim/aim, amount, drift_steps, quiet, is_follow_up, datum/sex_action/action, mob/living/action_initiator, mob/living/action_target, atom/action_performer)
	var/mob/living/carbon/climaxer = parent
	var/obj/item/organ/genitals/filling_organ/testicles/testes = climaxer.getorganslot(ORGAN_SLOT_TESTICLES)
	if(!testes?.reagents?.total_volume || amount <= 0)
		return FALSE
	var/datum/reagents/load = testes.reagents
	var/atom/landing = aim.get_valid_target()
	if(!landing)
		// The aim was lost between spurts; the rest falls on the floor.
		route_climax_reagents(load, amount, climaxer, null, action, ORGASM_LOCATION_SELF, get_turf(climaxer), null, action_initiator, action_target, action_performer, TRUE)
		return FALSE
	var/mob/living/aimer = aim.aimer || climaxer
	var/mob/living/aimed_mob = isliving(landing) ? landing : null
	var/zone = aimed_mob ? aim.resolve_zone(aimed_mob, drift_steps) : null
	var/obj/item/clothing/shoes/heels/heels = aim.get_worn_heels(aimed_mob, zone)
	var/into_mouth = zone == PENIS_AIM_MOUTH && aimed_mob.mouth_is_free()
	if(zone == PENIS_AIM_MOUTH && !into_mouth)
		zone = FLUID_COAT_FACE
	var/whose = aimed_mob ? get_aim_whose(aimed_mob, is_follow_up ? climaxer : aimer) : null
	var/phrase
	if(into_mouth)
		phrase = "into [whose] open mouth"
	else if(heels)
		phrase = "into [whose] heels, where it pools around [aimed_mob.p_their()] toes"
	else if(aimed_mob)
		phrase = "all over [whose] [get_fluid_coat_zone_name(zone, aimed_mob)]"
	else if(isturf(landing))
		phrase = "onto the floor"
	else
		phrase = "[is_aim_container(landing) ? "into" : "onto"] \the [landing]"
	if(is_follow_up)
		climaxer.visible_message(span_love("[climaxer]'s cock spurts again, [phrase]!"), span_love("<i>Spurt!</i> Another rope lands [phrase]!"))
	else if(!quiet)
		if(aimer == climaxer)
			climaxer.visible_message(span_love("[climaxer] shoots [climaxer.p_their()] load [phrase]!"))
		else
			aimer.visible_message(span_love("[aimer] aims [climaxer]'s cock as it shoots [phrase]!"))
	log_combat(climaxer, aimed_mob || climaxer, "came [phrase], aimed by [key_name(aimer)]")

	if(into_mouth)
		var/swallowed = amount * PENIS_AIM_MOUTH_SHARE
		route_climax_reagents(load, swallowed, climaxer, aimed_mob, action, ORGASM_LOCATION_ORAL, aimed_mob, INGEST, action_initiator, action_target, action_performer)
		coat_climax_onto(load, amount - swallowed, climaxer, aimed_mob, action, ORGASM_LOCATION_ONTO, FLUID_COAT_FACE, action_initiator, action_target, action_performer)
	else if(heels)
		fill_aimed_container(heels, load, amount, climaxer, aimed_mob, action, action_initiator, action_target, action_performer)
	else if(aimed_mob)
		coat_climax_onto(load, amount, climaxer, aimed_mob, action, ORGASM_LOCATION_ONTO, zone, action_initiator, action_target, action_performer)
	else if(is_aim_container(landing))
		fill_aimed_container(landing, load, amount, climaxer, null, action, action_initiator, action_target, action_performer)
	else if(is_aim_garment(landing))
		soak_aimed_garment(landing, load, amount, climaxer, action, action_initiator, action_target, action_performer)
	else
		route_climax_reagents(load, amount, climaxer, null, action, ORGASM_LOCATION_SELF, get_turf(landing), null, action_initiator, action_target, action_performer, TRUE)
	return into_mouth

/// An open container with room, such as a cup, a bucket or heels nobody wears.
/proc/is_aim_container(atom/target)
	return isobj(target) && target.reagents && target.is_refillable()

/proc/is_aim_garment(atom/target)
	var/obj/item/clothing/garment = target
	return istype(garment) && garment.can_soak_fluid()

/// Fills a container from the load and spills what does not fit under it; returns the units that went in.
/datum/component/arousal/proc/fill_aimed_container(obj/container, datum/reagents/load, amount, mob/living/climaxer, mob/living/aimed_mob, datum/sex_action/action, mob/living/action_initiator, mob/living/action_target, atom/action_performer)
	var/into = min(amount, container.reagents.maximum_volume - container.reagents.total_volume)
	if(into > 0)
		route_climax_reagents(load, into, climaxer, aimed_mob, action, ORGASM_LOCATION_CONTAINER, container, INJECT, action_initiator, action_target, action_performer)
	var/overflow = amount - max(into, 0)
	if(overflow > 0)
		container.visible_message(span_warning("\The [container] overflows!"))
		route_climax_reagents(load, overflow, climaxer, aimed_mob, action, ORGASM_LOCATION_SELF, get_turf(container), null, action_initiator, action_target, action_performer, TRUE)
	return max(into, 0)

/// Cloth soaks the load; what it cannot hold drips to the floor under it.
/datum/component/arousal/proc/soak_aimed_garment(obj/item/clothing/garment, datum/reagents/load, amount, mob/living/climaxer, datum/sex_action/action, mob/living/action_initiator, mob/living/action_target, atom/action_performer)
	var/remaining = apply_sex_action_climax_effects(climaxer, null, action, ORGASM_LOCATION_CONTAINER, load, amount, garment, null, action_initiator, action_target, action_performer)
	if(remaining <= 0)
		return
	var/dripping = remaining - garment.soak_fluid(load, remaining)
	if(dripping > 0)
		deposit_cum_on_turf(get_turf(garment), load, dripping)

/// An unaimed climax onto someone still spurts, drifting down the body from where it started.
/datum/component/arousal/proc/spurt_onto(mob/living/target, coat_zone, amount, datum/sex_action/action, mob/living/action_initiator, mob/living/action_target, atom/action_performer)
	var/mob/living/climaxer = parent
	var/obj/item/organ/genitals/penis/penis = climaxer.getorganslot(ORGAN_SLOT_PENIS)
	if(!penis || !target)
		return FALSE
	var/datum/climax_aim/aim = new(penis)
	aim.target = target
	aim.zone = coat_zone
	start_spurts(aim, amount, TRUE, action, action_initiator, action_target, action_performer, TRUE)
	return TRUE
