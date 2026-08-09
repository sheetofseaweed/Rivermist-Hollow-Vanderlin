/datum/sex_action/masturbate/other/clit
	name = "Stroke their clit"
	check_same_tile = FALSE

/datum/sex_action/masturbate/other/clit/shows_on_menu(mob/living/user, mob/living/target)
	if(user == target)
		return FALSE
	if(!target.getorganslot(ORGAN_SLOT_VAGINA))
		return FALSE
	return TRUE

/datum/sex_action/masturbate/other/clit/can_perform(mob/living/user, mob/living/target)
	. = ..()
	if(!.)
		return FALSE
	if(user == target)
		return FALSE
	if(!check_location_accessible(user, target, BODY_ZONE_PRECISE_GROIN, TRUE))
		return FALSE
	if(!target.getorganslot(ORGAN_SLOT_VAGINA))
		return FALSE
	return TRUE

/datum/sex_action/masturbate/other/clit/on_start(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] starts stroking [target]'s clit..."))

/datum/sex_action/masturbate/other/clit/on_perform(mob/living/user, mob/living/target)
	. = ..()
	if(can_show_action_message(user, target))
		user.visible_message(spanify_force("[user] [get_generic_force_adjective()] strokes [target]'s clit..."))
	playsound(user, 'sound/misc/mat/fingering.ogg', 30, TRUE, -2, ignore_walls = FALSE)

	perform_sex_action(target, user, 2, 0, 2)

	handle_passive_ejaculation(target)

/datum/sex_action/masturbate/other/clit/on_finish(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] stops stroking [target]'s clit."))
