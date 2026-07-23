/datum/sex_action/npc/npc_body_rub
	name = "Rub genitals against their body"
	stamina_cost = 0
	var/selected_genital_slot

/datum/sex_action/npc/npc_body_rub/shows_on_menu(mob/living/user, mob/living/target)
	return FALSE

/datum/sex_action/npc/npc_body_rub/can_perform(mob/living/user, mob/living/target)
	. = ..()
	if(!. || user == target)
		return FALSE
	if(!check_location_accessible(user, user, BODY_ZONE_PRECISE_GROIN, TRUE))
		return FALSE
	if(!check_location_accessible(user, target, BODY_ZONE_CHEST))
		return FALSE

	selected_genital_slot = null
	for(var/genital_slot in list(ORGAN_SLOT_PENIS, ORGAN_SLOT_VAGINA))
		if(user.getorganslot(genital_slot) && !check_sex_lock(user, genital_slot))
			selected_genital_slot = genital_slot
			break
	return !!selected_genital_slot

/datum/sex_action/npc/npc_body_rub/on_start(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] presses [user.p_their()] groin against [target]'s body."))

/datum/sex_action/npc/npc_body_rub/on_perform(mob/living/user, mob/living/target)
	. = ..()
	if(can_show_action_message(user, target))
		user.visible_message(spanify_force("[user] [get_generic_force_adjective()] rubs [user.p_their()] genitals against [target]'s body."))
	do_thrust_animate(user, target)
	perform_sex_action(user, target, 1.8, 0, 1.5)
	perform_sex_action(target, user, 0.5, 0, 0.3)
	handle_passive_ejaculation()

/datum/sex_action/npc/npc_body_rub/on_finish(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] pulls [user.p_their()] groin away from [target]."))

/datum/sex_action/npc/npc_body_rub/lock_sex_object(mob/living/user, mob/living/target)
	if(selected_genital_slot)
		add_sex_lock(user, selected_genital_slot)
