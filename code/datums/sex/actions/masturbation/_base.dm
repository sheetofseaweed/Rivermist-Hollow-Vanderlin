/datum/sex_action/masturbate
	abstract_type = /datum/sex_action/masturbate

/datum/sex_action/masturbate/can_perform(mob/living/user, mob/living/target)
	. = ..()
	if(!.)
		return FALSE
	var/locked = user.get_active_precise_hand()
	if(check_sex_lock(user, null, locked))
		return FALSE
	return TRUE

/datum/sex_action/masturbate/lock_sex_object(mob/living/user, mob/living/target)
	var/locked = user.get_active_precise_hand()
	sex_locks |= new /datum/sex_session_lock(user, locked)
