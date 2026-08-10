/datum/sex_action/npc/npc_throat_sex
	name = "NPC Fuck their throat"
	check_same_tile = FALSE
	hole_id = BODY_ZONE_PRECISE_MOUTH
	gags_target = TRUE
	scene_interaction = SEX_SCENE_INTERACTION_ORAL
	scene_user_role = SEX_SCENE_ROLE_RECEIVER
	scene_user_slot = ORGAN_SLOT_PENIS
	scene_target_role = SEX_SCENE_ROLE_GIVER
	scene_target_slot = BODY_ZONE_PRECISE_MOUTH

/datum/sex_action/npc/npc_throat_sex/shows_on_menu(mob/living/user, mob/living/target)
	return FALSE

/datum/sex_action/npc/npc_throat_sex/can_perform(mob/living/user, mob/living/target)
	. = ..()
	if(!.)
		return FALSE
	if(user == target)
		return FALSE
	if(!check_location_accessible(user, user, BODY_ZONE_PRECISE_GROIN, TRUE))
		return FALSE
	if(!check_location_accessible(user, target, BODY_ZONE_PRECISE_MOUTH))
		return FALSE
	if(!user.getorganslot(ORGAN_SLOT_PENIS))
		return FALSE
	if(check_sex_lock(user, ORGAN_SLOT_PENIS))
		return FALSE
	return TRUE

/datum/sex_action/npc/npc_throat_sex/on_perform(mob/living/user, mob/living/target)
	. = ..()
	if(can_show_action_message(user, target))
		user.visible_message(spanify_force("[user] [get_generic_force_adjective()] fucks [target]'s throat."))
	playsound(target, 'sound/misc/mat/segso.ogg', 50, TRUE, -2, ignore_walls = FALSE)
	do_thrust_animate(user, target)

	perform_sex_action(user, target, 2, 0, 2)

	if(considered_limp(user))
		perform_sex_action(target, user, 0, 2, 2)
	else
		perform_sex_action(target, user, 0, 7, 2)
		if(force >= SEX_FORCE_HIGH)
			var/choker_snap_chance = 5
			if(force >= SEX_FORCE_EXTREME)
				choker_snap_chance = 15
			if(prob(choker_snap_chance))
				target.snap_worn_choker(user)
	handle_passive_ejaculation()

/datum/sex_action/npc/npc_throat_sex/handle_climax_message(mob/living/user, mob/living/target, must_flip)
	if(must_flip)
		user.visible_message(span_love("[user] shudders in orgasm from being throatfucked!"))
		user.lose_virginity()
		return ORGASM_LOCATION_SELF
	else
		user.visible_message(span_love("[user] cums into [target]'s throat!"))
		user.lose_virginity()
		return ORGASM_LOCATION_ORAL


/datum/sex_action/npc/npc_throat_sex/on_finish(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] pulls [user.p_their()] cock out of [target]'s throat."))

/datum/sex_action/npc/npc_throat_sex/lock_sex_object(mob/living/user, mob/living/target)
	add_sex_lock(user, ORGAN_SLOT_PENIS)
	add_sex_lock(target, BODY_ZONE_PRECISE_MOUTH, null, FALSE)
