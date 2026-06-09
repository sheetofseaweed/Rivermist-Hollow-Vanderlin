/datum/sex_action/masturbate/other
	abstract_type = /datum/sex_action/masturbate/other
	flipped = TRUE
	mage_hand_allowed = TRUE
	mage_hand_overlay_zone = MAGE_HAND_ZONE_GROIN

/datum/sex_action/masturbate/other/can_perform(mob/living/user, mob/living/target)
	. = ..()
	if(!.)
		return FALSE
	if(!find_available_hand(user))
		return FALSE
	return TRUE

/datum/sex_action/masturbate/other/lock_sex_object(mob/living/user, mob/living/target)
	var/locked = get_hand_lock_slot(user)
	if(locked)
		add_sex_lock(user, locked)

/datum/sex_action/masturbate/other/is_finished(mob/living/user, mob/living/target)
	var/datum/sex_session/sex_session = get_sex_session(user, target)
	if(sex_session.finished_check())
		return TRUE
	return FALSE
