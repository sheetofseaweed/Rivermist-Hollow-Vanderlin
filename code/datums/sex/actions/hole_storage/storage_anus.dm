
/datum/sex_action/hole_storage/anus_store
	name = "Store items in anus"
	hole_id = ORGAN_SLOT_ANUS

/datum/sex_action/hole_storage/anus_store/shows_on_menu(mob/living/user, mob/living/target)
	if(!istype(user, /mob/living/carbon/human) || !istype(target, /mob/living/carbon/human))
		return FALSE
	if(!target.get_sex_organ(ORGAN_SLOT_ANUS))
		return FALSE
	if(check_sex_lock(target, ORGAN_SLOT_ANUS))
		return FALSE
	if(!user.get_active_held_item())
		return FALSE
	return TRUE

/datum/sex_action/hole_storage/anus_store/can_perform(mob/living/user, mob/living/target)
	. = ..()
	if(!.)
		return FALSE
	if(!check_location_accessible(user, target, BODY_ZONE_PRECISE_GROIN, TRUE))
		return FALSE
	if(!user.get_active_held_item())
		return FALSE
	return TRUE

/datum/sex_action/hole_storage/anus_store/on_start(mob/living/user, mob/living/target)
	. = ..()
	var/datum/sex_session/sex_session = get_sex_session(user, target)
	var/obj/item/dildo = user.get_active_held_item()

	if(user == target)
		target_organ = user.get_sex_organ(hole_id)
		to_chat(user, sex_session.spanify_force("I start inserting \the [dildo] in my ass..."))
	else
		target_organ = target.get_sex_organ(hole_id)
		user.visible_message(span_warning("[user] starts inserting \the [dildo] in [target]'s ass..."))

	playsound(target, list('sound/misc/mat/insert (1).ogg','sound/misc/mat/insert (2).ogg'), 20, TRUE, ignore_walls = FALSE)


/datum/sex_action/hole_storage/anus_store/on_perform(mob/living/user, mob/living/target)
	var/pain_amt = 4 //base pain amt to use
	var/self = (user == target)
	if(!target_organ)
		if(self)
			target_organ = user.get_sex_organ(hole_id)
		else
			target_organ = target.get_sex_organ(hole_id)
	var/datum/sex_session/sex_session = get_sex_session(user, target)

	var/obj/item/dildo = user.get_active_held_item()
	if(!dildo)
		sex_session.stop_current_action()
		return
	var/force = FALSE
	if(sex_session.get_current_force() >= SEX_FORCE_HIGH)
		force = TRUE
	var/success = SEND_SIGNAL(target_organ, COMSIG_BODYSTORAGE_TRY_INSERT, dildo, STORAGE_LAYER_INNER, force)
	switch(success)
		if(INSERT_FEEDBACK_OK)
			if(self)
				to_chat(user, sex_session.spanify_force("I stuff \the [dildo] in my ass..."))
			else
				user.visible_message(sex_session.spanify_force("I stuff \the [dildo] in [target]'s ass..."))
		if(INSERT_FEEDBACK_OK_FORCE)
			if(prob(15))
				var/stuffed_res = SEND_SIGNAL(target_organ, COMSIG_BODYSTORAGE_SWAP_LAYERS_RAND, STORAGE_LAYER_INNER, STORAGE_LAYER_DEEP, force)
				if(stuffed_res == INSERT_FEEDBACK_OK_FORCE || stuffed_res == INSERT_FEEDBACK_OK)
					pain_amt += 4
					if(self)
						to_chat(user, sex_session.spanify_force("\The [dildo] slips deep inside of my ass!"))
					else
						user.visible_message(sex_session.spanify_force("\The [dildo] slips deep inside of [target]'s ass!"))
			else
				pain_amt += 4
				if(self)
					to_chat(user, sex_session.spanify_force("I force \the [dildo] in my ass, fighting the pressure!"))
				else
					user.visible_message(sex_session.spanify_force("I force \the [dildo] in [target]'s ass, fighting the pressure!"))
		if(INSERT_FEEDBACK_ALMOST_FULL)
			pain_amt += 2
			if(self)
				to_chat(user, sex_session.spanify_force("I stuff the \the [dildo] in my ass, seems like it won't fit much more..."))
			else
				user.visible_message(sex_session.spanify_force("I stuff the \the [dildo] in [target]'s ass, seems like it won't fit much more..."))
		if(INSERT_FEEDBACK_STUFFED)
			if(force && prob(50))
				var/stuffed_res = SEND_SIGNAL(target_organ, COMSIG_BODYSTORAGE_SWAP_LAYERS_RAND, STORAGE_LAYER_INNER, STORAGE_LAYER_DEEP, force)
				if(stuffed_res == INSERT_FEEDBACK_OK_FORCE || stuffed_res == INSERT_FEEDBACK_OK)
					pain_amt += 2
					if(self)
						to_chat(user, sex_session.spanify_force("\The [dildo] slips deep inside of my ass!"))
					else
						user.visible_message(sex_session.spanify_force("\The [dildo] slips deep inside of [target]'s ass!"))
			else
				if(self)
					to_chat(user, sex_session.spanify_force("My ass is too full to stuff even \the [dildo] in."))
				else
					user.visible_message(sex_session.spanify_force("[target]'s ass is too full to stuff even \the [dildo] in."))
				sex_session.stop_current_action()
				return
		if(INSERT_FEEDBACK_TRY_FORCE)
			pain_amt += 3
			if(self)
				to_chat(user, sex_session.spanify_force("I feel like \the [dildo] might fit if I just use more force."))
			else
				user.visible_message(sex_session.spanify_force("I feel like \the [dildo] might fit in [target]'s ass if I just use more force."))
		if(FALSE)
			if(self)
				to_chat(user, sex_session.spanify_force("I fail to stuff \the [dildo] in my ass."))
			else
				user.visible_message(sex_session.spanify_force("I fail to stuff \the [dildo] in [target]'s ass."))
			sex_session.stop_current_action()
			return

	user.update_inv_hands()
	user.update_a_intents()
	sex_session.perform_sex_action(user, target, 0.5, pain_amt, 0.5, src)
	sex_session.handle_passive_ejaculation()

/datum/sex_action/hole_storage/anus_remove
	name = "Remove items from anus"
	hole_id = ORGAN_SLOT_ANUS

/datum/sex_action/hole_storage/anus_remove/shows_on_menu(mob/living/user, mob/living/target)
	if(!istype(user, /mob/living/carbon/human) || !istype(target, /mob/living/carbon/human))
		return FALSE
	if(!target.get_sex_organ(ORGAN_SLOT_ANUS))
		return FALSE
	if(check_sex_lock(target, ORGAN_SLOT_ANUS))
		return FALSE
	if(user == target)
		target_organ = user.get_sex_organ(hole_id)
	else
		target_organ = target.get_sex_organ(hole_id)
	var/list/stored_items = SEND_SIGNAL(target_organ, COMSIG_BODYSTORAGE_GET_LISTS)
	if(!islist(stored_items))
		return FALSE
	var/list/stored_items_layer = stored_items[STORAGE_LAYER_INNER]
	if(!islist(stored_items_layer) || !stored_items_layer.len)
		return FALSE
	return TRUE

/datum/sex_action/hole_storage/anus_remove/can_perform(mob/living/user, mob/living/target)
	. = ..()
	if(!.)
		return FALSE
	if(!check_location_accessible(user, target, BODY_ZONE_PRECISE_GROIN, TRUE))
		return FALSE
	if(user.get_active_held_item())
		return FALSE
	return TRUE

/datum/sex_action/hole_storage/anus_remove/on_start(mob/living/user, mob/living/target)
	. = ..()

	if(user == target)
		target_organ = user.get_sex_organ(hole_id)
		to_chat(user, span_warning("I start removing items from my ass..."))
	else
		target_organ = target.get_sex_organ(hole_id)
		user.visible_message(span_warning("[user] starts removing items from [target]'s ass..."))

	playsound(target, list('sound/misc/mat/insert (1).ogg','sound/misc/mat/insert (2).ogg'), 20, TRUE, ignore_walls = FALSE)


/datum/sex_action/hole_storage/anus_remove/on_perform(mob/living/user, mob/living/target)
	var/pain_amt = 2 //base pain amt to use

	var/datum/sex_session/sex_session = get_sex_session(user, target)
	var/self = (user == target)

	if(!target_organ)
		if(self)
			target_organ = user.get_sex_organ(hole_id)
		else
			target_organ = target.get_sex_organ(hole_id)

	var/obj/item/removed_item
	removed_item = SEND_SIGNAL(target_organ, COMSIG_BODYSTORAGE_REMOVE_RAND_ITEM, STORAGE_LAYER_INNER)
	if(!removed_item)
		to_chat(user, sex_session.spanify_force("I couldn't find anything inside..."))
		sex_session.stop_current_action()
		return
	if(user.get_active_held_item())
		user.visible_message(sex_session.spanify_force("The [removed_item] falls down on the floor..."))
		removed_item.doMove(get_turf(user))
	else
		if(self)
			to_chat(user, sex_session.spanify_force("I fish out the [removed_item] from my ass..."))
		else
			user.visible_message(sex_session.spanify_force("I fish out the [removed_item] from [target]'s ass..."))
		removed_item.doMove(get_turf(user))
		user.put_in_active_hand(removed_item)
	sex_session.perform_sex_action(user, target, 0.5, pain_amt, 0.5, src)
	sex_session.handle_passive_ejaculation()


/datum/sex_action/hole_storage/anus_remove_deep
	name = "Remove items deep from anus"
	hole_id = ORGAN_SLOT_ANUS
	do_time = 10

/datum/sex_action/hole_storage/anus_remove_deep/shows_on_menu(mob/living/user, mob/living/target)
	if(!istype(user, /mob/living/carbon/human) || !istype(target, /mob/living/carbon/human))
		return FALSE
	if(!target.get_sex_organ(ORGAN_SLOT_ANUS))
		return FALSE
	if(check_sex_lock(target, ORGAN_SLOT_ANUS))
		return FALSE
	if(user == target)
		target_organ = user.get_sex_organ(hole_id)
	else
		target_organ = target.get_sex_organ(hole_id)
	var/list/stored_items = SEND_SIGNAL(target_organ, COMSIG_BODYSTORAGE_GET_LISTS)
	if(!islist(stored_items))
		return FALSE
	var/list/stored_items_layer = stored_items[STORAGE_LAYER_DEEP]
	if(!islist(stored_items_layer) || !stored_items_layer.len)
		return FALSE
	return TRUE

/datum/sex_action/hole_storage/anus_remove_deep/can_perform(mob/living/user, mob/living/target)
	. = ..()
	if(!.)
		return FALSE
	if(!check_location_accessible(user, target, BODY_ZONE_PRECISE_GROIN, TRUE))
		return FALSE
	if(user.get_active_held_item())
		return FALSE
	return TRUE

/datum/sex_action/hole_storage/anus_remove_deep/on_start(mob/living/user, mob/living/target)
	. = ..()

	if(user == target)
		target_organ = user.get_sex_organ(hole_id)
		to_chat(user, span_warning("I start removing items from deep in my ass..."))
	else
		target_organ = target.get_sex_organ(hole_id)
		user.visible_message(span_warning("[user] starts removing items from deep in [target]'s ass..."))

	playsound(target, list('sound/misc/mat/insert (1).ogg','sound/misc/mat/insert (2).ogg'), 20, TRUE, ignore_walls = FALSE)


/datum/sex_action/hole_storage/anus_remove_deep/on_perform(mob/living/user, mob/living/target)
	var/pain_amt = 2 //base pain amt to use

	var/datum/sex_session/sex_session = get_sex_session(user, target)
	var/self = (user == target)

	if(!target_organ)
		if(self)
			target_organ = user.get_sex_organ(hole_id)
		else
			target_organ = target.get_sex_organ(hole_id)

	var/obj/item/removed_item
	removed_item = SEND_SIGNAL(target_organ, COMSIG_BODYSTORAGE_REMOVE_RAND_ITEM, STORAGE_LAYER_DEEP)
	if(!removed_item)
		to_chat(user, sex_session.spanify_force("I couldn't find anything inside..."))
		sex_session.stop_current_action()
		return
	if(user.get_active_held_item())
		user.visible_message(sex_session.spanify_force("The [removed_item] falls down on the floor..."))
		removed_item.doMove(get_turf(user))
	else
		if(self)
			to_chat(user, sex_session.spanify_force("I fish out the [removed_item] from deep in my ass..."))
		else
			user.visible_message(sex_session.spanify_force("I fish out the [removed_item] from deep in [target]'s ass..."))
		removed_item.doMove(get_turf(user))
		user.put_in_active_hand(removed_item)
	sex_session.perform_sex_action(user, target, 0.5, pain_amt, 0.5, src)
	sex_session.handle_passive_ejaculation()
