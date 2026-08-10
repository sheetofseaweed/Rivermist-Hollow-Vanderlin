/datum/sex_action/npc/npc_handjob
	name = "Use their hand"

/datum/sex_action/npc/npc_handjob/shows_on_menu(mob/living/user, mob/living/target)
	return FALSE

/datum/sex_action/npc/npc_handjob/can_perform(mob/living/user, mob/living/target)
	. = ..()
	if(!. || user == target)
		return FALSE
	if(!check_location_accessible(user, user, BODY_ZONE_PRECISE_GROIN, TRUE))
		return FALSE
	if(!user.getorganslot(ORGAN_SLOT_PENIS) || check_sex_lock(user, ORGAN_SLOT_PENIS))
		return FALSE

	selected_hand = find_available_hand(target)
	return !!selected_hand

/datum/sex_action/npc/npc_handjob/on_start(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] takes [target]'s hand and wraps it around [user.p_their()] cock."))

/datum/sex_action/npc/npc_handjob/on_perform(mob/living/user, mob/living/target)
	. = ..()
	if(can_show_action_message(user, target))
		user.visible_message(spanify_force("[user] [get_generic_force_adjective()] works [target]'s hand over [user.p_their()] cock."))
	playsound(user, 'sound/misc/mat/fingering.ogg', 30, TRUE, -2, ignore_walls = FALSE)
	perform_sex_action(user, target, 2, 0, 2)
	perform_sex_action(target, user, 0.4, 0, 0.2)
	handle_passive_ejaculation()

/datum/sex_action/npc/npc_handjob/on_finish(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] lets go of [target]'s hand."))

/datum/sex_action/npc/npc_handjob/lock_sex_object(mob/living/user, mob/living/target)
	add_sex_lock(user, ORGAN_SLOT_PENIS)
	if(selected_hand)
		add_sex_lock(target, selected_hand)
