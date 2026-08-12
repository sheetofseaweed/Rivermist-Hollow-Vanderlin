/datum/sex_action/npc/npc_rimming
	name = "NPC Rim them"
	check_same_tile = FALSE
	gags_user = TRUE
	scene_interaction = SEX_SCENE_INTERACTION_ORAL
	scene_user_role = SEX_SCENE_ROLE_GIVER
	scene_user_slot = BODY_ZONE_PRECISE_MOUTH
	scene_target_role = SEX_SCENE_ROLE_RECEIVER
	scene_target_slot = ORGAN_SLOT_ANUS

/datum/sex_action/npc/npc_rimming/shows_on_menu(mob/living/user, mob/living/target)
	return FALSE

/datum/sex_action/npc/npc_rimming/can_perform(mob/living/user, mob/living/target)
	. = ..()
	if(!.)
		return FALSE
	if(user == target)
		return FALSE
	if(!check_location_accessible(user, user, BODY_ZONE_PRECISE_MOUTH))
		return FALSE
	if(!check_location_accessible(user, target, BODY_ZONE_PRECISE_GROIN, TRUE))
		return FALSE
	if(!target.getorganslot(ORGAN_SLOT_ANUS))
		return FALSE
	if(check_sex_lock(user, BODY_ZONE_PRECISE_MOUTH))
		return FALSE
	if(check_sex_lock(target, ORGAN_SLOT_ANUS))
		return FALSE
	return TRUE

/datum/sex_action/npc/npc_rimming/on_start(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] starts rimming [target]'s butt..."))

/datum/sex_action/npc/npc_rimming/on_perform(mob/living/user, mob/living/target)
	. = ..()
	if(can_show_action_message(user, target))
		user.visible_message(spanify_force("[user] [get_generic_force_adjective()] rims [target]'s butt..."))
	user.make_sucking_noise()
	do_thrust_animate(user, target)

	perform_sex_action(user, target, 1, 0, 1)
	handle_passive_ejaculation()

	perform_sex_action(target, user, 2, 0, 2)
	handle_passive_ejaculation(target)
/datum/sex_action/npc/npc_rimming/on_finish(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] stops rimming [target]'s butt ..."))

/datum/sex_action/npc/npc_rimming/lock_sex_object(mob/living/user, mob/living/target)
	add_sex_lock(user, BODY_ZONE_PRECISE_MOUTH)
	add_sex_lock(target, ORGAN_SLOT_ANUS, null, FALSE)
