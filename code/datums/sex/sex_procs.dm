/mob/living/proc/get_highest_grab_state_on(mob/living/victim)
	var/grabstate = null
	var/obj/item/grabbing/right_grab = vars["r_grab"]
	var/obj/item/grabbing/left_grab = vars["l_grab"]
	if(right_grab && right_grab.grabbed == victim)
		if(grabstate == null || right_grab.grab_state > grabstate)
			grabstate = right_grab.grab_state
	if(left_grab && left_grab.grabbed == victim)
		if(grabstate == null || left_grab.grab_state > grabstate)
			grabstate = left_grab.grab_state
	return grabstate

/proc/do_thrust_animate(atom/movable/user, atom/movable/target, pixels = 4, time = 2.7)
	var/datum/sex_session/sex_session
	if(isliving(user) && isliving(target))
		sex_session = get_sex_session(user, target)
		if(!sex_session)
			sex_session = get_sex_session(target, user)
	if(sex_session)
		if(sex_session.speed > SEX_SPEED_MID)
			time = max(0.5, time - 0.25)
		if(sex_session.force < SEX_FORCE_MID)
			pixels = max(1, pixels - 1)
	var/oldx = user.pixel_x
	var/oldy = user.pixel_y
	var/target_x = oldx
	var/target_y = oldy
	var/dir = get_dir(user, target)
	if(user.loc == target.loc)
		dir = user.dir
	switch(dir)
		if(NORTH)
			target_y += pixels
		if(SOUTH)
			target_y -= pixels
		if(WEST)
			target_x -= pixels
		if(EAST)
			target_x += pixels

	animate(user, pixel_x = target_x, pixel_y = target_y, time = time)
	animate(pixel_x = oldx, pixel_y = oldy, time = time)

/mob/living/proc/start_sex_session(mob/living/target, show_ui = TRUE)
	if(!target)
		return
	var/datum/sex_session/old_session = get_sex_session(src, target)
	if(old_session && !QDELETED(old_session))
		if(show_ui)
			old_session.show_ui()
		return old_session


	var/datum/sex_session/session = new /datum/sex_session(src, target)
	LAZYADD(GLOB.sex_sessions, session)
	if(target.client && client && show_ui)
		session.show_ui()
	return session

/mob/living/proc/make_sucking_noise()
	if(gender == FEMALE)
		playsound(src, pick('sound/misc/mat/girlmouth (1).ogg','sound/misc/mat/girlmouth (2).ogg'), 25, TRUE, ignore_walls = FALSE)
	else
		playsound(src, pick('sound/misc/mat/guymouth (2).ogg','sound/misc/mat/guymouth (3).ogg','sound/misc/mat/guymouth (4).ogg','sound/misc/mat/guymouth (5).ogg'), 35, TRUE, ignore_walls = FALSE)

/mob/living/proc/can_do_sex()
	return TRUE

/mob/living/proc/has_sex_interface()
	return TRUE

/mob/living/MiddleMouseDrop_T(atom/movable/dragged, mob/living/user)
	var/mob/living/target = src

	if(user.mmb_intent)
		return ..()
	if(!istype(dragged))
		return
	// Need to drag yourself to the target.
	if(dragged != user)
		return
	if(!user.can_do_sex())
		to_chat(user, "<span class='warning'>I can't do this.</span>")
		return

	if(!user.start_sex_session(target))
		to_chat(user, "<span class='warning'>I'm already sexing.</span>")
		return

/proc/get_sex_session(mob/giver, mob/taker)
	for(var/datum/sex_session/session as anything in GLOB.sex_sessions)
		if(session.user != giver)
			continue
		if(session.target != taker)
			continue
		return session
	return null

/mob/living/proc/uses_sex_state_fallback()
	return !istype(src, /mob/living/carbon/human)

/mob/living/proc/get_sex_arousal_cap()
	return MAX_AROUSAL || 120

/mob/living/proc/get_sex_pain_cap()
	return 100

/mob/living/proc/get_sex_arousal_multiplier()
	var/arousal_cap = max(1, ACTIVE_EJAC_THRESHOLD || get_sex_arousal_cap())
	return 1 + min(1, (sex_arousal || 0) / arousal_cap)

/mob/living/proc/get_sex_arousal_data()
	var/list/arousal_data = list()
	if(!uses_sex_state_fallback())
		SEND_SIGNAL(src, COMSIG_SEX_GET_AROUSAL, arousal_data)
	else
		arousal_data["arousal"] = sex_arousal || 0
		arousal_data["orgasm_progress"] = sex_orgasm_progress || 0
		arousal_data["pain"] = sex_pain || 0
		arousal_data["frozen"] = !!sex_arousal_frozen
		arousal_data["arousal_multiplier"] = get_sex_arousal_multiplier()
		arousal_data["resistance_to_pleasure"] = sex_resistance_to_pleasure || RESIST_NONE

	if(isnull(arousal_data["pain"]))
		arousal_data["pain"] = 0
	if(isnull(arousal_data["frozen"]))
		arousal_data["frozen"] = FALSE
	if(isnull(arousal_data["arousal_multiplier"]))
		arousal_data["arousal_multiplier"] = 1
	if(isnull(arousal_data["resistance_to_pleasure"]))
		arousal_data["resistance_to_pleasure"] = RESIST_NONE

	return arousal_data

/mob/living/proc/get_sex_pain_percent()
	var/list/arousal_data = get_sex_arousal_data()
	var/pain_cap = max(1, get_sex_pain_cap())
	var/current_pain = arousal_data["pain"] || 0
	return min(100, (current_pain / pain_cap) * 100)

/mob/living/proc/notify_sex_arousal_changed()
	if(!uses_sex_state_fallback())
		return
	sync_sex_arousal_organs()
	SEND_SIGNAL(src, COMSIG_SEX_AROUSAL_CHANGED)

/mob/living/proc/sync_sex_arousal_organs()
	var/obj/item/organ/genitals/penis/native_penis = get_native_sex_organ(ORGAN_SLOT_PENIS)
	if(istype(native_penis))
		native_penis.on_arousal_changed()

	if(!sex_fallback_organs)
		return

	var/obj/item/organ/genitals/penis/fallback_penis = sex_fallback_organs[ORGAN_SLOT_PENIS]
	if(istype(fallback_penis) && fallback_penis != native_penis)
		fallback_penis.on_arousal_changed()

/mob/living/proc/set_sex_erect_state(aroused)
	if(!uses_sex_state_fallback())
		return SEND_SIGNAL(src, COMSIG_SET_ERECT_STATE, aroused)

	var/obj/item/organ/genitals/penis/native_penis = get_native_sex_organ(ORGAN_SLOT_PENIS)
	if(istype(native_penis))
		native_penis.set_hard(null, aroused)

	if(!sex_fallback_organs)
		return

	var/obj/item/organ/genitals/penis/fallback_penis = sex_fallback_organs[ORGAN_SLOT_PENIS]
	if(istype(fallback_penis) && fallback_penis != native_penis)
		fallback_penis.set_hard(null, aroused)

/mob/living/proc/adjust_sex_arousal(amount)
	if(!uses_sex_state_fallback())
		return SEND_SIGNAL(src, COMSIG_SEX_ADJUST_AROUSAL, amount)
	if(sex_arousal_frozen)
		return

	sex_arousal = clamp((sex_arousal || 0) + amount, 0, get_sex_arousal_cap())
	if(sex_arousal >= ACTIVE_EJAC_THRESHOLD)
		trigger_sex_climax()
	else
		notify_sex_arousal_changed()

/mob/living/proc/set_sex_arousal(amount)
	if(!uses_sex_state_fallback())
		return SEND_SIGNAL(src, COMSIG_SEX_SET_AROUSAL, amount)

	sex_arousal = clamp(amount, 0, get_sex_arousal_cap())
	if(amount >= ACTIVE_EJAC_THRESHOLD || sex_arousal >= ACTIVE_EJAC_THRESHOLD)
		trigger_sex_climax()
	else
		notify_sex_arousal_changed()

/mob/living/proc/toggle_sex_arousal_freeze()
	if(!uses_sex_state_fallback())
		return SEND_SIGNAL(src, COMSIG_SEX_FREEZE_AROUSAL)

	sex_arousal_frozen = !sex_arousal_frozen
	notify_sex_arousal_changed()

/mob/living/proc/set_sex_holding(new_resist)
	if(!uses_sex_state_fallback())
		return SEND_SIGNAL(src, COMSIG_SEX_SET_HOLDING, new_resist)

	sex_resistance_to_pleasure = clamp(new_resist, RESIST_NONE, RESIST_HIGH)
	notify_sex_arousal_changed()

/mob/living/proc/set_sex_edged_by_other_state(new_state)
	if(!uses_sex_state_fallback())
		return SEND_SIGNAL(src, COMSIG_SEX_EDGED_BY_OTHER_STATE, new_state)

	sex_edged_by_other = !!new_state

/mob/living/proc/receive_simple_sex_action(arousal_amt, pain_amt, orgasm_prog_amt, giving = FALSE)
	return receive_sex_action(null, null, null, arousal_amt, pain_amt, orgasm_prog_amt, giving)

/mob/living/proc/receive_sex_action(datum/sex_action/sex_act, mob/living/action_initiator, mob/living/action_target, arousal_amt, pain_amt, orgasm_prog_amt, giving = TRUE, incoming_force = SEX_FORCE_MID, incoming_speed = SEX_SPEED_MID, incoming_resistance = RESIST_NONE)
	if(!uses_sex_state_fallback())
		return SEND_SIGNAL(src, COMSIG_SEX_RECEIVE_ACTION, sex_act, action_initiator, action_target, arousal_amt, pain_amt, orgasm_prog_amt, giving, incoming_force, incoming_speed, incoming_resistance)

	var/arousal_mult = 1
	var/orgasm_mult = 1
	switch(incoming_resistance)
		if(RESIST_LOW)
			arousal_mult = 0.9
			orgasm_mult = 0.9
		if(RESIST_MEDIUM)
			arousal_mult = 0.75
			orgasm_mult = 0.75
		if(RESIST_HIGH)
			arousal_mult = 0.6
			orgasm_mult = 0.6

	if(sex_edged_by_other && orgasm_prog_amt > 0)
		orgasm_mult *= 0.5
		sex_edged_by_other = FALSE

	if(!sex_arousal_frozen)
		sex_arousal = clamp((sex_arousal || 0) + (arousal_amt * arousal_mult), 0, get_sex_arousal_cap())
	sex_orgasm_progress = clamp((sex_orgasm_progress || 0) + (orgasm_prog_amt * orgasm_mult), 0, PASSIVE_EJAC_THRESHOLD || 100)
	sex_pain = clamp((sex_pain || 0) + pain_amt, 0, get_sex_pain_cap())

	if(sex_arousal >= ACTIVE_EJAC_THRESHOLD || sex_orgasm_progress >= PASSIVE_EJAC_THRESHOLD)
		trigger_sex_climax()
	else
		notify_sex_arousal_changed()

/mob/living/proc/trigger_sex_climax()
	if(!uses_sex_state_fallback())
		return

	sex_orgasm_progress = 0
	sex_arousal = clamp(round((sex_arousal || 0) * 0.35), 0, get_sex_arousal_cap())
	sex_pain = max(0, (sex_pain || 0) - 10)
	sex_edged_by_other = FALSE
	notify_sex_arousal_changed()
	SEND_SIGNAL(src, COMSIG_SEX_CLIMAX)

/mob/living/proc/try_sex_knot(mob/living/target, sex_force)
	return SEND_SIGNAL(src, COMSIG_SEX_TRY_KNOT, target, sex_force)

/mob/living/proc/get_sex_var_value(var_name, default_value = null)
	if(!var_name)
		return default_value
	if(var_name in vars)
		return vars[var_name]

	var/mob/living/carbon/human/source_human = get_sex_source_human()
	if(source_human && source_human != src && (var_name in source_human.vars))
		return source_human.vars[var_name]

	return default_value

/mob/living/proc/get_native_sex_organ(organ_slot)
	if(!organ_slot)
		return null
	if(!hascall(src, "getorganslot"))
		return null
	return call(src, "getorganslot")(organ_slot)

/mob/living/proc/get_sex_source_organ(organ_slot)
	var/mob/living/carbon/human/source_human = get_sex_source_human()
	if(!source_human || source_human == src)
		return null
	return source_human.get_native_sex_organ(organ_slot)

/mob/living/proc/find_sex_source_human_in_list(list/candidates)
	if(!islist(candidates))
		return null

	var/mob/living/carbon/human/fallback = null
	for(var/entry as anything in candidates)
		if(!istype(entry, /mob/living/carbon/human))
			continue
		var/mob/living/carbon/human/human = entry
		if(human == src)
			continue
		if(human.client || human.mind || human.ckey)
			return human
		if(!fallback)
			fallback = human
	return fallback

/mob/living/proc/get_sex_source_human()
	if(istype(src, /mob/living/carbon/human))
		return src

	var/mob/living/carbon/human/source_human = find_sex_source_human_in_list(contents)
	if(source_human)
		return source_human

	source_human = find_sex_source_human_in_list(vars["important_recursive_contents"])
	if(source_human)
		return source_human

	source_human = find_sex_source_human_in_list(vars["recursive_contents_client_mobs"])
	if(source_human)
		return source_human

	return null

/mob/living/proc/can_use_sex_organ_slot(organ_slot)
	var/mob/living/carbon/human/source_human = get_sex_source_human()
	if(!source_human || source_human == src)
		return FALSE

	var/list/internal_organ_slots = source_human.vars["internal_organs_slot"]
	if(islist(internal_organ_slots))
		if(!isnull(internal_organ_slots[organ_slot]))
			return TRUE
		return organ_slot in internal_organ_slots

	return !!source_human.get_native_sex_organ(organ_slot)

/mob/living/proc/get_sex_fallback_organ_type(organ_slot)
	switch(organ_slot)
		if(ORGAN_SLOT_TESTICLES)
			return ball_organ || /obj/item/organ/genitals/filling_organ/testicles
		if(ORGAN_SLOT_PENIS)
			return penis_organ || /obj/item/organ/genitals/penis
		if(ORGAN_SLOT_BREASTS)
			return breast_organ || /obj/item/organ/genitals/filling_organ/breasts
		if(ORGAN_SLOT_VAGINA)
			return vagina_organ || /obj/item/organ/genitals/filling_organ/vagina
		if(ORGAN_SLOT_BUTT)
			return butt_organ || ass_organ || /obj/item/organ/genitals/butt
		if(ORGAN_SLOT_ANUS)
			return anus_organ
		if(ORGAN_SLOT_BELLY)
			return belly_organ
	return null

/mob/living/proc/get_sex_fallback_organ_size(organ_slot)
	var/obj/item/organ/genitals/source_organ = get_sex_source_organ(organ_slot)
	if(istype(source_organ))
		return source_organ.organ_size

	switch(organ_slot)
		if(ORGAN_SLOT_TESTICLES)
			return rand(ball_min, ball_max)
		if(ORGAN_SLOT_PENIS)
			return rand(penis_min, penis_max)
		if(ORGAN_SLOT_BREASTS)
			return rand(breast_min, breast_max)
		if(ORGAN_SLOT_BUTT)
			return rand(butt_min, butt_max)
	return null

/mob/living/proc/get_sex_fallback_storage_component(organ_slot)
	switch(organ_slot)
		if(ORGAN_SLOT_TESTICLES)
			return /datum/component/body_storage/testicles
		if(ORGAN_SLOT_PENIS)
			return /datum/component/body_storage/penis
		if(ORGAN_SLOT_BREASTS)
			return /datum/component/body_storage/breasts
		if(ORGAN_SLOT_VAGINA)
			return /datum/component/body_storage/vagina
		if(ORGAN_SLOT_ANUS)
			return /datum/component/body_storage/anus
	return null

/mob/living/proc/create_sex_fallback_organ(organ_slot)
	var/organ_type = get_sex_fallback_organ_type(organ_slot)
	if(!organ_type)
		return null

	var/obj/item/organ/genitals/fallback_organ = new organ_type()
	var/organ_size = get_sex_fallback_organ_size(organ_slot)
	if(!isnull(organ_size))
		fallback_organ.organ_size = organ_size
		fallback_organ.body_storage_bulk = initial(fallback_organ.body_storage_bulk) * fallback_organ.organ_size
	fallback_organ.owner = src
	configure_sex_fallback_organ(fallback_organ, organ_slot)

	var/storage_component_type = get_sex_fallback_storage_component(organ_slot)
	if(storage_component_type)
		fallback_organ.add_bodystorage(src, null, storage_component_type)

	return fallback_organ

/mob/living/proc/configure_sex_fallback_organ(obj/item/organ/genitals/fallback_organ, organ_slot)
	if(!fallback_organ)
		return

	var/obj/item/organ/genitals/source_organ = get_sex_source_organ(organ_slot)
	if(istype(source_organ))
		fallback_organ.organ_size = source_organ.organ_size
		fallback_organ.body_storage_bulk = source_organ.body_storage_bulk

	if(istype(fallback_organ, /obj/item/organ/genitals/filling_organ))
		var/obj/item/organ/genitals/filling_organ/filling_organ = fallback_organ
		var/obj/item/organ/genitals/filling_organ/source_filling_organ = source_organ

		if(istype(source_filling_organ))
			filling_organ.reagent_to_make = source_filling_organ.reagent_to_make
			if(filling_organ.reagents && source_filling_organ.reagents)
				filling_organ.reagents.clear_reagents()
				for(var/datum/reagent/reagent as anything in source_filling_organ.reagents.reagent_list)
					filling_organ.reagents.add_reagent(reagent.type, reagent.volume)

		switch(organ_slot)
			if(ORGAN_SLOT_TESTICLES)
				var/reagent_type = get_sex_var_value("cum")
				if(ispath(reagent_type, /datum/reagent))
					filling_organ.reagent_to_make = reagent_type
					if(filling_organ.reagents)
						filling_organ.reagents.clear_reagents()
						filling_organ.reagents.add_reagent(reagent_type, filling_organ.reagents.maximum_volume)
			if(ORGAN_SLOT_VAGINA)
				var/reagent_type = get_sex_var_value("femcum")
				if(ispath(reagent_type, /datum/reagent))
					filling_organ.reagent_to_make = reagent_type
			if(ORGAN_SLOT_BREASTS)
				var/reagent_type = get_sex_var_value("breast_milk")
				if(ispath(reagent_type, /datum/reagent))
					filling_organ.reagent_to_make = reagent_type

	if(istype(fallback_organ, /obj/item/organ/genitals/penis))
		var/obj/item/organ/genitals/penis/penis = fallback_organ
		penis.on_arousal_changed()

/mob/living/proc/get_cached_sex_organ(organ_slot)
	if(!sex_fallback_organs)
		sex_fallback_organs = list()

	var/obj/item/organ/genitals/fallback_organ = sex_fallback_organs[organ_slot]
	if(QDELETED(fallback_organ))
		sex_fallback_organs -= organ_slot
		fallback_organ = null

	if(!fallback_organ)
		fallback_organ = create_sex_fallback_organ(organ_slot)
		if(fallback_organ)
			sex_fallback_organs[organ_slot] = fallback_organ

	return fallback_organ

/mob/living/proc/get_sex_organ(organ_slot)
	var/obj/item/organ/native_organ = get_native_sex_organ(organ_slot)
	var/mob/living/carbon/human/source_human = get_sex_source_human()
	if(source_human && source_human != src)
		if(!can_use_sex_organ_slot(organ_slot))
			return null

		if(native_organ)
			return native_organ

		return get_cached_sex_organ(organ_slot)

	if(native_organ)
		return native_organ

	if(!istype(src, /mob/living/carbon/human))
		return get_cached_sex_organ(organ_slot)

	return null

/mob/living/proc/has_hands()
	return TRUE

/mob/living/proc/has_mouth()
	return TRUE

/mob/living/proc/has_penis()
	return get_sex_organ(ORGAN_SLOT_PENIS)

/mob/living/proc/has_testicles()
	return get_sex_organ(ORGAN_SLOT_TESTICLES)

/mob/living/proc/has_vagina()
	return get_sex_organ(ORGAN_SLOT_VAGINA)

/mob/living/proc/has_breasts()
	RETURN_TYPE(/obj/item/organ/genitals/filling_organ/breasts)
	return get_sex_organ(ORGAN_SLOT_BREASTS)

/mob/living/proc/has_belly()
	RETURN_TYPE(/obj/item/organ/genitals/belly)
	return get_sex_organ(ORGAN_SLOT_BELLY)

/mob/living/proc/has_butt()
	RETURN_TYPE(/obj/item/organ/genitals/butt)
	return get_sex_organ(ORGAN_SLOT_BUTT)

/mob/living/proc/is_fertile()
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = get_sex_organ(ORGAN_SLOT_VAGINA)
	return vagina?.fertility

/mob/living/proc/is_virile()
	var/obj/item/organ/genitals/filling_organ/testicles/testicles = get_sex_organ(ORGAN_SLOT_TESTICLES)
	return testicles?.virility

/mob/living/proc/mouth_is_free()
	return !is_mouth_covered()

/mob/living/proc/foot_is_free()
	return is_barefoot()

/mob/living/proc/is_barefoot()
	for(var/item_slot in DEFAULT_SLOT_PRIORITY)
		var/obj/item/clothing = get_item_by_slot(item_slot)
		if(!clothing) // Don't have this slot or not wearing anything in it
			continue
		if(clothing.body_parts_covered & FEET)
			return FALSE
	// If didn't stop before, then we're barefoot
	return TRUE

/mob/living/carbon/human/has_mouth()
	return get_bodypart(BODY_ZONE_HEAD)

/mob/living/carbon/human/has_hands() // technically should be an and but i'll replicate original behavior
	return get_bodypart(BODY_ZONE_L_ARM) || get_bodypart(BODY_ZONE_R_ARM)

/mob/living/proc/get_sex_display_name()
	return name

/mob/living/carbon/human/get_sex_display_name()
	return get_face_name() || name

/mob/living/proc/mark_sex_virginity_lost()
	return

/mob/living/carbon/human/mark_sex_virginity_lost()
	virginity = FALSE

/mob/living/proc/get_sex_restraints()
	return vars["handcuffed"]

/mob/living/proc/is_sex_sneaking()
	return !!vars["rogue_sneaking"]

/mob/living/proc/is_sex_combat_mode()
	return !!vars["cmode"]

/mob/living/proc/is_sex_location_accessible(location)
	switch(location)
		if(BODY_ZONE_PRECISE_MOUTH, BODY_ZONE_HEAD)
			return has_mouth() && mouth_is_free()
		if(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_PRECISE_L_HAND, BODY_ZONE_PRECISE_R_HAND)
			return has_hands()
		if(BODY_ZONE_PRECISE_L_FOOT, BODY_ZONE_PRECISE_R_FOOT, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
			return foot_is_free()
	return TRUE

/mob/living/carbon/human/is_sex_location_accessible(location)
	var/obj/item/bodypart/bodypart = get_bodypart(location)
	if(!bodypart)
		return FALSE

	var/hidden_slots = NONE
	for(var/obj/item/item as anything in get_equipped_items())
		if(!istype(item, /obj/item/clothing))
			continue
		var/obj/item/clothing/clothing = item
		if(clothing.armor_class > AC_LIGHT)
			hidden_slots |= clothing.body_parts_covered

	if(location in body_parts_covered2organ_names(hidden_slots))
		return FALSE

	return TRUE

/mob/living/proc/return_character_information()
	var/list/data = list()
	if(has_hands())
		data += "<div>...have hands.</div>"
	if(has_mouth())
		data += "<div>...have a mouth, which is [mouth_is_free() ? "uncovered" : "covered"].</div>"
	return data

/mob/living/proc/get_active_precise_hand()
	var/active_hand = BODY_ZONE_PRECISE_L_HAND
	if(active_hand_index != 1)
		active_hand = BODY_ZONE_PRECISE_R_HAND
	return active_hand

/mob/proc/check_handholding()
	return

/mob/living/carbon/human/check_handholding()
	if(pulledby && pulledby != src)
		var/obj/item/bodypart/LH
		var/obj/item/bodypart/RH
		LH = get_bodypart(BODY_ZONE_PRECISE_L_HAND)
		RH = get_bodypart(BODY_ZONE_PRECISE_R_HAND)
		if(LH || RH)
			for(var/obj/item/grabbing/G in src.grabbedby)
				if(G.limb_grabbed == LH || G.limb_grabbed == RH)
					return TRUE

/proc/return_sessions_with_user(mob/living/user)
	var/list/sessions = list()
	for(var/datum/sex_session/session in GLOB.sex_sessions)
		if(user != session.target && user != session.user)
			continue
		sessions |= session
	return sessions

/proc/return_highest_priority_action(list/sessions = list(), mob/living/user)
	var/datum/sex_session/highest_session
	for(var/datum/sex_session/session in sessions)
		if(!session.current_action)
			continue
		if(!highest_session)
			highest_session = session
			continue
		if(user == session.target)
			if(session.current_action.target_priority > highest_session.current_action.target_priority)
				highest_session = session
				continue
		if(user == session.user)
			if(session.current_action.user_priority > highest_session.current_action.user_priority)
				highest_session = session
				continue
	return highest_session

/mob/proc/get_erp_pref(pref_type)
	if(!client?.prefs)
		return FALSE

	if(!ispath(pref_type, /datum/erp_preference))
		return FALSE

	var/datum/erp_preference/pref = new pref_type()
	return pref.get_value(client.prefs)

/mob/proc/set_erp_pref(pref_type, value)
	if(!client?.prefs)
		return FALSE

	if(!ispath(pref_type, /datum/erp_preference))
		return FALSE

	var/datum/erp_preference/pref = new pref_type()
	pref.set_value(client.prefs, value)
	client.prefs.save_preferences()
	return TRUE

/mob/proc/has_erp_pref(pref_type)
	return get_erp_pref(pref_type) == TRUE

/mob/proc/get_all_erp_prefs()
	if(!client?.prefs)
		return list()

	var/list/prefs_by_category = list()

	for(var/pref_type in subtypesof(/datum/erp_preference))
		var/datum/erp_preference/pref = new pref_type()
		var/category = pref.category
		var/value = pref.get_value(client.prefs)

		if(!prefs_by_category[category])
			prefs_by_category[category] = list()

		prefs_by_category[category][pref_type] = list(
			"name" = pref.name,
			"description" = pref.description,
			"value" = value,
			"pref_object" = pref
		)

	return prefs_by_category

/proc/any_has_erp_pref(list/mobs, pref_type)
	for(var/mob/M in mobs)
		if(M.has_erp_pref(pref_type))
			return TRUE
	return FALSE

/proc/all_have_erp_pref(list/mobs, pref_type)
	for(var/mob/M in mobs)
		if(!M.has_erp_pref(pref_type))
			return FALSE
	return TRUE

/mob/living/proc/has_kink(kink_name)
	if(!client?.prefs?.erp_preferences)
		return FALSE
	var/list/kink_prefs = client.prefs.erp_preferences["kinks"]
	if(!kink_prefs || !kink_prefs[kink_name])
		return FALSE
	return kink_prefs[kink_name]["enabled"]


/mob/living

	///npc organs to use
	var/list/sex_fallback_organs = null
	var/sex_arousal = 0
	var/sex_orgasm_progress = 0
	var/sex_pain = 0
	var/sex_arousal_frozen = FALSE
	var/sex_edged_by_other = FALSE
	var/sex_resistance_to_pleasure = RESIST_NONE
	var/ball_organ = /obj/item/organ/genitals/filling_organ/testicles
	var/ball_min = MIN_TESTICLES_SIZE
	var/ball_max = MAX_TESTICLES_SIZE
	var/breast_organ = /obj/item/organ/genitals/filling_organ/breasts
	var/breast_min = MIN_BREASTS_SIZE
	var/breast_max = MAX_BREASTS_SIZE
	var/ass_organ = /obj/item/organ/genitals/butt
	var/ass_min = MIN_BUTT_SIZE
	var/ass_max = MAX_BUTT_SIZE
	var/penis_organ = /obj/item/organ/genitals/penis
	var/penis_min = MIN_PENIS_SIZE
	var/penis_max = MAX_PENIS_SIZE
	var/butt_organ = /obj/item/organ/genitals/butt
	var/butt_min = MIN_BUTT_SIZE
	var/butt_max = MAX_BUTT_SIZE
	var/anus_organ = /obj/item/organ/genitals/filling_organ/anus
	var/belly_organ = /obj/item/organ/genitals/belly
	var/vagina_organ = /obj/item/organ/genitals/filling_organ/vagina
	var/show_genitals = FALSE
	var/mouth_blocked = FALSE

/mob/living/Initialize()
	. = ..()
	if(ai_controller)
		var/datum/ai_planning_subtree/horny/hornybehavior = locate() in ai_controller.planning_subtrees
		if(hornybehavior)
			addtimer(CALLBACK(src, PROC_REF(give_genitals)), 1)

/mob/living/proc/give_genitals()
	if(!isanimal(src))
		var/mob/living/user = src
		if(gender == MALE)
			var/obj/item/organ/genitals/filling_organ/testicles/testicles = user.get_native_sex_organ(ORGAN_SLOT_TESTICLES)
			if(!testicles)
				if(!show_genitals)
					testicles = new /obj/item/organ/genitals/filling_organ/testicles/invisible
				else
					testicles = new ball_organ
				testicles.organ_size = rand(ball_min, ball_max)
				testicles.Insert(user, TRUE)
			var/obj/item/organ/genitals/penis/penis = user.get_native_sex_organ(ORGAN_SLOT_PENIS)
			if(!penis)
				if(!show_genitals)
					penis = new /obj/item/organ/genitals/penis
				else
					penis = new penis_organ
				penis.organ_size = rand(penis_min, penis_max)
				penis.Insert(user, TRUE)
		if(gender == FEMALE)
			var/obj/item/organ/genitals/butt/buttie = user.get_native_sex_organ(ORGAN_SLOT_BUTT)
			if(!buttie)
				if(!show_genitals)
					buttie = new /obj/item/organ/genitals/butt/invisible
				else
					buttie = new butt_organ
				buttie.organ_size = rand(butt_min, butt_max)
				buttie.Insert(user, TRUE)
			var/obj/item/organ/genitals/filling_organ/breasts/breasts = user.get_native_sex_organ(ORGAN_SLOT_BREASTS)
			if(!breasts)
				if(!show_genitals)
					breasts = new /obj/item/organ/genitals/filling_organ/breasts
				else
					breasts = new breast_organ
				breasts.organ_size = rand(breast_min,breast_max)
				breasts.Insert(user, TRUE)
			var/obj/item/organ/genitals/filling_organ/vagina/vagina = user.get_native_sex_organ(ORGAN_SLOT_VAGINA)
			if(!vagina)
				if(!show_genitals)
					vagina = new /obj/item/organ/genitals/filling_organ/vagina
				else
					vagina = new vagina_organ
				vagina.Insert(user, TRUE)
			if(prob(5)) //5 chance to be dickgirl.
				var/obj/item/organ/genitals/filling_organ/testicles/testicles = user.get_native_sex_organ(ORGAN_SLOT_TESTICLES)
				if(!testicles)
					if(!show_genitals)
						testicles = new /obj/item/organ/genitals/filling_organ/testicles/invisible
					else
						testicles = new ball_organ
					testicles.organ_size = rand(ball_min, ball_max)
					testicles.Insert(user, TRUE)
				var/obj/item/organ/genitals/penis/penis = user.get_native_sex_organ(ORGAN_SLOT_PENIS)
				if(!penis)
					if(!show_genitals)
						penis = new /obj/item/organ/genitals/penis
					else
						penis = new penis_organ
					penis.organ_size = rand(penis_min, penis_max)
					penis.Insert(user, TRUE)
		color_key_source_list_from_carbon(src)
