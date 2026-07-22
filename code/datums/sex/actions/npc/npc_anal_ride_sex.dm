/datum/sex_action/npc
	abstract_type = /datum/sex_action/npc
	check_same_tile = FALSE
	check_incapacitated = FALSE
	requires_hole_storage = FALSE

/datum/sex_action/npc/npc_anal_ride_sex
	name = "NPC Ride them anally"
	stamina_cost = 0
	check_same_tile = FALSE
	hole_id = ORGAN_SLOT_ANUS
	scene_interaction = SEX_SCENE_INTERACTION_PENETRATION
	scene_user_role = SEX_SCENE_ROLE_RECEIVER
	scene_user_slot = ORGAN_SLOT_ANUS
	scene_target_role = SEX_SCENE_ROLE_GIVER
	scene_target_slot = ORGAN_SLOT_PENIS

/datum/sex_action/npc/npc_anal_ride_sex/shows_on_menu(mob/living/user, mob/living/target)
	return FALSE

/datum/sex_action/npc/npc_anal_ride_sex/can_perform(mob/living/user, mob/living/target)
	. = ..()
	if(!.)
		return FALSE
	if(user == target)
		return FALSE
	if(!check_location_accessible(user, user, BODY_ZONE_PRECISE_GROIN, TRUE))
		return FALSE
	if(!check_location_accessible(user, target, BODY_ZONE_PRECISE_GROIN, TRUE))
		return FALSE
	if(!user.getorganslot(ORGAN_SLOT_ANUS))
		return FALSE
	if(!target.getorganslot(ORGAN_SLOT_PENIS))
		return FALSE
	if(check_sex_lock(target, ORGAN_SLOT_PENIS))
		return FALSE
	return TRUE

/datum/sex_action/npc/npc_anal_ride_sex/on_start(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] gets on top of [target] and begins riding them with their ass!"))
	var/used_sex_volume = sex_volume
	playsound(target, list('sound/misc/mat/insert (1).ogg','sound/misc/mat/insert (2).ogg'), used_sex_volume, TRUE, ignore_walls = FALSE)


/datum/sex_action/npc/npc_anal_ride_sex/on_perform(mob/living/user, mob/living/target)
	if(can_show_action_message(user, target))
		user.visible_message(spanify_force("[user] [get_generic_force_adjective()] rides [target]."))
	var/used_sex_volume = sex_volume
	playsound(target, get_force_sound(), used_sex_volume, TRUE, -2, ignore_walls = FALSE)
	do_thrust_animate(user, target)

	if(considered_limp(target))
		perform_sex_action(target, user, 1.2, 4, 1.2)
	else
		perform_sex_action(target, user, 2.4, 9, 2.4)
	handle_passive_ejaculation()

	perform_sex_action(user, target, 2, 4, 2)

/datum/sex_action/npc/npc_anal_ride_sex/handle_climax_message(mob/living/user, mob/living/target, must_flip)
	if(must_flip)
		target.visible_message(span_love("[user] cums into [target]'s butt!"))
		user.lose_virginity()
		target.lose_virginity()
		return ORGASM_LOCATION_INTO
	else
		user.visible_message(span_love("[user] cums with their butt from [target]'s cock!"))
		user.lose_virginity()
		target.lose_virginity()
		return ORGASM_LOCATION_SELF

/datum/sex_action/npc/npc_anal_ride_sex/on_finish(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] gets off [target]."))
