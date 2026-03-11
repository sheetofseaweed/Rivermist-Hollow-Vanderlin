/datum/sex_action/npc/npc_facesitting
	name = "NPC Sit on their face with cunt"
	stamina_cost = 0
	check_same_tile = FALSE
	hole_id = BODY_ZONE_PRECISE_MOUTH
	gags_target = TRUE

/datum/sex_action/npc/npc_facesitting/shows_on_menu(mob/living/user, mob/living/target)
	return FALSE

/datum/sex_action/npc/npc_facesitting/on_start(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] sits their butt on [target]'s face!"))


/datum/sex_action/npc/npc_facesitting/on_perform(mob/living/user, mob/living/target)
	var/datum/sex_session/sex_session = get_sex_session(user, target)
	var/verbstring = pick(list("rubs", "smushes", "forces"))
	if(can_show_action_message(user, target))
		user.visible_message(sex_session.spanify_force("[user] [sex_session.get_generic_force_adjective()] [verbstring] [user.p_their()] butt against [target] face."))
	target.make_sucking_noise()
	do_thrust_animate(user, target)

	sex_session.perform_sex_action(user, target, 1, 3, 2, src)
	sex_session.handle_passive_ejaculation()

	sex_session.perform_sex_action(target, user, 0, 2, 0, src)

/datum/sex_action/npc/npc_facesitting/on_finish(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] gets off [target]'s face."))

/datum/sex_action/npc/npc_facesitting/lock_sex_object(mob/living/user, mob/living/target)
	sex_locks |= new /datum/sex_session_lock(target, BODY_ZONE_PRECISE_MOUTH)
	sex_locks |= new /datum/sex_session_lock(user, ORGAN_SLOT_VAGINA)
