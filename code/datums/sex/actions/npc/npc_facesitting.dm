/datum/sex_action/npc/npc_facesitting
	name = "NPC Sit on their face with cunt"
	check_same_tile = FALSE
	hole_id = BODY_ZONE_PRECISE_MOUTH
	gags_target = TRUE
	scene_interaction = SEX_SCENE_INTERACTION_ORAL
	scene_user_role = SEX_SCENE_ROLE_RECEIVER
	scene_user_slot = ORGAN_SLOT_VAGINA
	scene_target_role = SEX_SCENE_ROLE_GIVER
	scene_target_slot = BODY_ZONE_PRECISE_MOUTH

/datum/sex_action/npc/npc_facesitting/shows_on_menu(mob/living/user, mob/living/target)
	return FALSE

/datum/sex_action/npc/npc_facesitting/can_perform(mob/living/user, mob/living/target)
	. = ..()
	if(!.)
		return FALSE
	if(user == target)
		return FALSE
	if(!check_location_accessible(user, user, BODY_ZONE_PRECISE_GROIN, TRUE))
		return FALSE
	if(!check_location_accessible(user, target, BODY_ZONE_PRECISE_MOUTH))
		return FALSE
	if(!user.getorganslot(ORGAN_SLOT_VAGINA))
		return FALSE
	if(check_sex_lock(target, BODY_ZONE_PRECISE_MOUTH))
		return FALSE
	if(check_sex_lock(user, ORGAN_SLOT_VAGINA))
		return FALSE
	return TRUE

/datum/sex_action/npc/npc_facesitting/on_start(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] sits their butt on [target]'s face!"))


/datum/sex_action/npc/npc_facesitting/on_perform(mob/living/user, mob/living/target)
	. = ..()
	var/verbstring = pick(list("rubs", "smushes", "forces"))
	if(can_show_action_message(user, target))
		user.visible_message(spanify_force("[user] [get_generic_force_adjective()] [verbstring] [user.p_their()] butt against [target] face."))
	target.make_sucking_noise()
	do_thrust_animate(user, target)

	perform_sex_action(user, target, 1, 3, 2)
	handle_passive_ejaculation()

	perform_sex_action(target, user, 0, 2, 0)

/datum/sex_action/npc/npc_facesitting/on_finish(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] gets off [target]'s face."))

/datum/sex_action/npc/npc_facesitting/lock_sex_object(mob/living/user, mob/living/target)
	add_sex_lock(target, BODY_ZONE_PRECISE_MOUTH, null, FALSE)
	add_sex_lock(user, ORGAN_SLOT_VAGINA, null, FALSE)
