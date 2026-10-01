// Keeping fluid inside: gravity slows leaks while lying down, and a clench toggle holds the vagina and anus shut.

/// Leak multiplier from posture and from holding it in.
/obj/item/organ/genitals/filling_organ/proc/get_retention_multiplier()
	. = 1
	if(!owner)
		return
	if(owner.body_position == LYING_DOWN)
		. *= FLUID_LYING_LEAK_MULT
	if(can_hold_in && owner.is_holding_fluids_in())
		. *= FLUID_HELD_LEAK_MULT

/mob/living/proc/is_holding_fluids_in()
	return !!has_status_effect(/datum/status_effect/holding_fluids_in)

/// The openings a clench keeps shut.
/mob/living/proc/get_held_in_organs()
	. = list()
	for(var/slot in list(ORGAN_SLOT_VAGINA, ORGAN_SLOT_ANUS))
		var/obj/item/organ/genitals/filling_organ/opening = getorganslot(slot)
		if(istype(opening) && opening.can_hold_in)
			. += opening

/mob/living/proc/can_hold_fluids_in()
	return length(get_held_in_organs()) > 0

/// Starts or stops holding it in; returns TRUE when now holding.
/mob/living/proc/toggle_holding_fluids_in()
	if(is_holding_fluids_in())
		remove_status_effect(/datum/status_effect/holding_fluids_in)
		return FALSE
	if(stat != CONSCIOUS || !can_hold_fluids_in())
		return FALSE
	return !!apply_status_effect(/datum/status_effect/holding_fluids_in)

/datum/status_effect/holding_fluids_in
	id = "holding_fluids_in"
	tick_interval = FLUID_HOLD_TICK
	alert_type = /atom/movable/screen/alert/status_effect/holding_fluids_in
	/// Set when the hold gives out instead of being let go on purpose.
	var/gave_out = FALSE

/datum/status_effect/holding_fluids_in/on_apply()
	. = ..()
	if(!owner.can_hold_fluids_in())
		return FALSE
	to_chat(owner, span_notice("I clench, holding everything in."))

/datum/status_effect/holding_fluids_in/tick()
	if(owner.stat != CONSCIOUS || !owner.can_hold_fluids_in())
		give_out()
		return
	if(!is_holding_anything())
		return
	owner.adjust_stamina(FLUID_HOLD_STAMINA_COST, energy_loss_mult = 0)
	if(owner.stamina >= owner.maximum_stamina)
		give_out()

/datum/status_effect/holding_fluids_in/on_remove()
	. = ..()
	if(!gave_out)
		to_chat(owner, span_notice("I relax and let it flow."))
		return
	var/gushed = FALSE
	for(var/obj/item/organ/genitals/filling_organ/opening as anything in owner.get_held_in_organs())
		// A plug still keeps it in.
		if(!opening.reagents?.total_volume || length(opening.contents))
			continue
		opening.leak_reagents(opening.reagents.total_volume * FLUID_HOLD_GUSH_SHARE)
		gushed = TRUE
	if(gushed && owner.stat == CONSCIOUS)
		to_chat(owner, span_warning("I can't hold it in any longer!"))

/datum/status_effect/holding_fluids_in/get_examine_text(mob/user, list/P)
	if(user == owner || !is_holding_anything())
		return null
	return span_love("[capitalize(P[THEYRE])] squeezing [P[THEIR]] thighs together.")

/// Ends the hold with a gush, from exhaustion or passing out.
/datum/status_effect/holding_fluids_in/proc/give_out()
	gave_out = TRUE
	qdel(src)

/datum/status_effect/holding_fluids_in/proc/is_holding_anything()
	for(var/obj/item/organ/genitals/filling_organ/opening as anything in owner.get_held_in_organs())
		if(opening.reagents?.total_volume)
			return TRUE
	return FALSE

/atom/movable/screen/alert/status_effect/holding_fluids_in
	name = "Holding It In"
	desc = "I'm clenching to keep everything inside. Click to relax."
	icon_state = "buff"
	alert_group = ALERT_BUFF

/atom/movable/screen/alert/status_effect/holding_fluids_in/Click(location, control, params)
	. = ..()
	var/mob/living/viewer = mob_viewer
	if(istype(viewer) && viewer.is_holding_fluids_in())
		viewer.toggle_holding_fluids_in()
