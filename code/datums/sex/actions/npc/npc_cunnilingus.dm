/datum/sex_action/npc/npc_cunnilingus
	name = "NPC Suck their cunt off"
	stamina_cost = 0
	check_same_tile = FALSE
	hole_id = BODY_ZONE_PRECISE_MOUTH
	gags_user = TRUE


/datum/sex_action/npc/npc_cunnilingus/shows_on_menu(mob/living/user, mob/living/target)
	return FALSE

/datum/sex_action/npc/npc_cunnilingus/on_start(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] starts licking [target]'s cunt..."))

/datum/sex_action/npc/npc_cunnilingus/on_perform(mob/living/user, mob/living/target)
	. = ..()
	var/datum/sex_session/sex_session = get_sex_session(user, target)
	if(can_show_action_message(user, target))
		user.visible_message(sex_session.spanify_force("[user] [sex_session.get_generic_force_adjective()] sucks [target]'s clit..."))
	user.make_sucking_noise()
	do_thrust_animate(user, target)

	sex_session.perform_sex_action(target, user, 2, 3,  2, src)

/datum/sex_action/npc/npc_cunnilingus/handle_climax_message(mob/living/user, mob/living/target, must_flip)
	if(must_flip)
		target.visible_message(span_love("[user] squirts girlcum into [target]'s mouth!"))
		return ORGASM_LOCATION_ORAL
	else //I mean it's never gonna happen but ok
		target.visible_message(span_love("[user] cums from sucking [target]'s pussy somehow!"))
		return ORGASM_LOCATION_SELF



/datum/sex_action/npc/npc_cunnilingus/on_finish(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] stops sucking [target]'s clit ..."))


/datum/sex_action/npc/npc_cunnilingus/lock_sex_object(mob/living/user, mob/living/target)
	sex_locks |= new /datum/sex_session_lock(target, ORGAN_SLOT_VAGINA)
	sex_locks |= new /datum/sex_session_lock(user, BODY_ZONE_PRECISE_MOUTH)


