/datum/sex_action/sex/other
	abstract_type = /datum/sex_action/sex/other
	target_priority = 100
	user_priority = 0
	flipped = TRUE

/datum/sex_action/sex/other/try_knot_on_climax(mob/living/user, mob/living/target)
	if(!knot_on_finish)
		return FALSE
	if(!can_knot)
		return FALSE

	var/datum/sex_session/session = get_sex_session(user, target)
	if(!session)
		return FALSE
	return target.try_sex_knot(user, session.force)

/datum/sex_action/sex/other/lock_sex_object(mob/living/user, mob/living/target)
	sex_locks |= new /datum/sex_session_lock(target, ORGAN_SLOT_PENIS)


/datum/sex_action/sex/other/check_hole_storage_available(mob/living/target, mob/living/user)
	if(!hole_id || !stored_item_type)
		return TRUE // No storage requirements

	var/obj/item/organ/user_o = user.get_sex_organ(hole_id)
	// Check if target has hole storage component
	var/datum/component/body_storage/storage_comp = user_o.GetComponent(/datum/component/body_storage)
	if(!storage_comp)
		return FALSE

	return TRUE
