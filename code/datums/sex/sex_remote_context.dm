/datum/sex_remote_context
	var/datum/weakref/caster_ref
	var/datum/weakref/target_ref
	var/datum/sex_session/session
	var/expires_at = 0
	var/range = 7
	var/requires_range = TRUE
	var/requires_line_of_sight = TRUE
	var/line_of_sight_break_grace = 20 SECONDS
	var/line_of_sight_lost_at = 0
	var/check_interval = 2 SECONDS

/datum/sex_remote_context/New(mob/living/caster, mob/living/target, duration = 2 MINUTES, range_override = 7)
	. = ..()
	if(caster)
		caster_ref = WEAKREF(caster)
		RegisterSignal(caster, COMSIG_LIVING_DEATH, PROC_REF(on_participant_invalidated))
	if(target)
		target_ref = WEAKREF(target)
		RegisterSignal(target, COMSIG_LIVING_DEATH, PROC_REF(on_participant_invalidated))
	range = range_override
	if(duration > 0)
		expires_at = world.time + duration
		addtimer(CALLBACK(src, PROC_REF(check_validity)), min(duration, check_interval))

/datum/sex_remote_context/Destroy(force, ...)
	clear_all_overlays()
	var/mob/living/caster = get_caster()
	if(caster)
		UnregisterSignal(caster, COMSIG_LIVING_DEATH)
	var/mob/living/target = get_target()
	if(target)
		UnregisterSignal(target, COMSIG_LIVING_DEATH)
	caster_ref = null
	target_ref = null
	session = null
	return ..()

/datum/sex_remote_context/proc/get_caster()
	return caster_ref?.resolve()

/datum/sex_remote_context/proc/get_target()
	return target_ref?.resolve()

/datum/sex_remote_context/proc/is_valid(datum/sex_session/owning_session)
	if(owning_session && session && owning_session != session)
		return FALSE
	var/mob/living/caster = get_caster()
	var/mob/living/remote_target = get_target()
	if(QDELETED(caster) || QDELETED(remote_target))
		return FALSE
	if(!caster.loc || !remote_target.loc)
		return FALSE
	if(owning_session && (owning_session.user != caster || owning_session.target != remote_target))
		return FALSE
	if(caster.stat != CONSCIOUS)
		return FALSE
	if(remote_target.stat == DEAD)
		return FALSE
	if(expires_at && world.time > expires_at)
		return FALSE
	if(!requires_line_of_sight && requires_range && get_dist(caster, remote_target) > range)
		return FALSE
	if(!has_required_line_of_sight(caster, remote_target))
		return FALSE
	return TRUE

/datum/sex_remote_context/proc/has_required_line_of_sight(mob/living/caster, mob/living/remote_target)
	if(!requires_line_of_sight)
		line_of_sight_lost_at = 0
		return TRUE
	if(can_see(caster, remote_target, range))
		line_of_sight_lost_at = 0
		return TRUE
	if(line_of_sight_break_grace <= 0)
		return FALSE
	if(line_of_sight_lost_at <= 0)
		line_of_sight_lost_at = world.time
		return TRUE
	return world.time < line_of_sight_lost_at + line_of_sight_break_grace

/datum/sex_remote_context/proc/allows_action(datum/sex_action/action)
	return FALSE

/datum/sex_remote_context/proc/show_action_overlay(datum/sex_action/action)
	return FALSE

/datum/sex_remote_context/proc/show_action_message(datum/sex_action/action, message_stage)
	return FALSE

/datum/sex_remote_context/proc/clear_action_overlay(datum/sex_action/action)
	return

/datum/sex_remote_context/proc/clear_all_overlays()
	return

/datum/sex_remote_context/proc/get_active_overlay_count()
	return 0

/datum/sex_remote_context/proc/check_validity()
	if(QDELETED(src))
		return
	if(!is_valid(session))
		clear_from_session()
		return
	addtimer(CALLBACK(src, PROC_REF(check_validity)), check_interval)

/datum/sex_remote_context/proc/clear_from_session()
	var/datum/sex_session/owning_session = session
	if(owning_session && !QDELETED(owning_session) && owning_session.remote_context == src)
		owning_session.clear_remote_context()
		return
	qdel(src)

/datum/sex_remote_context/proc/on_participant_invalidated()
	SIGNAL_HANDLER
	clear_from_session()

/datum/sex_remote_context/mage_hand
	var/list/active_overlay_counts = list()
	var/list/mutable_appearance/active_overlays = list()
	var/list/action_overlay_zones = list()

/datum/sex_remote_context/mage_hand/allows_action(datum/sex_action/action)
	return !!action?.mage_hand_allowed

/datum/sex_remote_context/mage_hand/show_action_message(datum/sex_action/action, message_stage)
	if(!action || !is_valid(session))
		return FALSE
	var/mob/living/caster = get_caster()
	var/mob/living/remote_target = get_target()
	if(!caster || !remote_target)
		return FALSE

	if(message_stage == MAGE_HAND_ACTION_MESSAGE_PERFORM)
		if(world.time < action.next_message_time)
			return FALSE
		var/speed_time = 40
		if(session)
			speed_time = rand(10, 100 - session.get_current_speed() * 10)
		action.next_message_time = world.time + speed_time

	var/caster_message = sanitize_action_message(get_action_message(action, message_stage, FALSE), caster)
	var/target_message = sanitize_action_message(get_action_message(action, message_stage, TRUE), caster)
	if(caster_message)
		to_chat(caster, format_action_message(caster_message))
	if(target_message && remote_target != caster)
		to_chat(remote_target, format_action_message(target_message))
	return TRUE

/datum/sex_remote_context/mage_hand/proc/get_action_message(datum/sex_action/action, message_stage, target_perspective = FALSE)
	if(!action)
		return null
	var/action_phrase = get_action_phrase(action, target_perspective)
	if(!action_phrase)
		return null
	switch(message_stage)
		if(MAGE_HAND_ACTION_MESSAGE_START)
			return "Someone's ghostly hand starts [action_phrase]."
		if(MAGE_HAND_ACTION_MESSAGE_PERFORM)
			return "Someone's ghostly hand continues [action_phrase]."
		if(MAGE_HAND_ACTION_MESSAGE_FINISH)
			return "Someone's ghostly hand stops [action_phrase]."
	return null

/datum/sex_remote_context/mage_hand/proc/get_action_phrase(datum/sex_action/action, target_perspective = FALSE)
	if(!action?.name)
		return null
	var/phrase = lowertext(action.name)
	var/mob/living/remote_target = get_target()
	if(target_perspective)
		phrase = replacetext(phrase, "their", "my")
		phrase = replacetext(phrase, "them", "me")
	else
		phrase = replacetext(phrase, "their", "[remote_target]'s")
		phrase = replacetext(phrase, "them", "[remote_target]")
	return gerundize_action_phrase(phrase)

/datum/sex_remote_context/mage_hand/proc/gerundize_action_phrase(phrase)
	if(!phrase)
		return null
	if(findtext(phrase, "play with ") == 1)
		return "playing with [copytext(phrase, length("play with ") + 1)]"

	var/space_position = findtext(phrase, " ")
	var/verb = space_position ? copytext(phrase, 1, space_position) : phrase
	var/rest = space_position ? copytext(phrase, space_position) : ""
	return "[gerundize_action_verb(verb)][rest]"

/datum/sex_remote_context/mage_hand/proc/gerundize_action_verb(verb)
	switch(verb)
		if("finger")
			return "fingering"
		if("rub")
			return "rubbing"
		if("slap")
			return "slapping"
		if("spank")
			return "spanking"
		if("stroke")
			return "stroking"
		if("jerk")
			return "jerking"
		if("play")
			return "playing"
	if(copytext(verb, length(verb), length(verb) + 1) == "e")
		return "[copytext(verb, 1, length(verb))]ing"
	return "[verb]ing"

/datum/sex_remote_context/mage_hand/proc/format_action_message(message)
	if(!message)
		return null
	if(session)
		return session.spanify_force(message)
	return span_notice(message)

/datum/sex_remote_context/mage_hand/proc/sanitize_action_message(message, mob/living/source)
	if(!message || !source)
		return message

	var/list/source_names = list()
	if(iscarbon(source))
		var/mob/living/carbon/carbon_source = source
		add_portal_message_name_candidate(source_names, carbon_source.get_visible_name(""))
		add_portal_message_name_candidate(source_names, carbon_source.get_face_name("", null, FALSE))
	else
		add_portal_message_name_candidate(source_names, source.get_visible_name())
	add_portal_message_name_candidate(source_names, source.real_name)
	add_portal_message_name_candidate(source_names, source.name)
	add_portal_message_name_candidate(source_names, "[source]")

	var/sanitized_message = message
	for(var/source_name in source_names)
		sanitized_message = replacetext(sanitized_message, source_name, "Someone")
	return sanitized_message

/datum/sex_remote_context/mage_hand/show_action_overlay(datum/sex_action/action)
	if(!action || !is_valid(session))
		return FALSE
	var/mob/living/remote_target = get_target()
	if(!ishuman(remote_target))
		return FALSE
	var/zone = get_action_overlay_zone(action)
	if(!zone)
		return FALSE

	action_overlay_zones[action] = zone
	active_overlay_counts[zone] = (active_overlay_counts[zone] || 0) + 1
	if(active_overlays[zone])
		return TRUE

	var/mutable_appearance/hand_overlay = mutable_appearance('modular_rmh/icons/mob/overlays/mage_hands.dmi', "overlay", ABOVE_MOB_LAYER)
	hand_overlay.color = "#8fc7ff"
	hand_overlay.alpha = 170
	var/list/offset = get_overlay_offset(zone)
	hand_overlay.pixel_x = offset["x"]
	hand_overlay.pixel_y = offset["y"]
	active_overlays[zone] = hand_overlay
	remote_target.add_overlay(hand_overlay)
	return TRUE

/datum/sex_remote_context/mage_hand/clear_action_overlay(datum/sex_action/action)
	if(!action)
		return
	var/zone = action_overlay_zones[action] || get_action_overlay_zone(action)
	action_overlay_zones -= action
	if(!zone || !active_overlay_counts[zone])
		return

	active_overlay_counts[zone]--
	if(active_overlay_counts[zone] > 0)
		return

	active_overlay_counts -= zone
	var/mutable_appearance/hand_overlay = active_overlays[zone]
	if(hand_overlay)
		var/mob/living/remote_target = get_target()
		if(remote_target)
			remote_target.cut_overlay(hand_overlay)
	active_overlays -= zone

/datum/sex_remote_context/mage_hand/clear_all_overlays()
	var/mob/living/remote_target = get_target()
	if(remote_target)
		for(var/zone in active_overlays)
			var/mutable_appearance/hand_overlay = active_overlays[zone]
			if(hand_overlay)
				remote_target.cut_overlay(hand_overlay)
	active_overlay_counts.Cut()
	active_overlays.Cut()
	action_overlay_zones.Cut()

/datum/sex_remote_context/mage_hand/get_active_overlay_count()
	var/count = 0
	for(var/zone in active_overlay_counts)
		count += active_overlay_counts[zone]
	return count

/datum/sex_remote_context/mage_hand/proc/get_action_overlay_zone(datum/sex_action/action)
	if(action.mage_hand_overlay_zone)
		return action.mage_hand_overlay_zone
	if(action.hole_id == ORGAN_SLOT_BREASTS)
		return MAGE_HAND_ZONE_CHEST
	if(action.hole_id == ORGAN_SLOT_ANUS)
		return MAGE_HAND_ZONE_BUTT
	if(action.hole_id == ORGAN_SLOT_PENIS || action.hole_id == ORGAN_SLOT_VAGINA)
		return MAGE_HAND_ZONE_GROIN
	if(action.target_menu_zone_mask & SEX_UI_ZONE_MOUTH)
		return MAGE_HAND_ZONE_MOUTH
	if(action.target_menu_zone_mask & SEX_UI_ZONE_BODY)
		return MAGE_HAND_ZONE_BODY
	return MAGE_HAND_ZONE_BODY

/datum/sex_remote_context/mage_hand/proc/get_overlay_offset(zone)
	switch(zone)
		if(MAGE_HAND_ZONE_GROIN)
			return list("x" = 0, "y" = -7)
		if(MAGE_HAND_ZONE_CHEST)
			return list("x" = -5, "y" = 7)
		if(MAGE_HAND_ZONE_BUTT)
			return list("x" = 5, "y" = -5)
		if(MAGE_HAND_ZONE_MOUTH)
			return list("x" = 0, "y" = 13)
		if(MAGE_HAND_ZONE_BODY)
			return list("x" = 0, "y" = 2)
	return list("x" = 0, "y" = 0)

/proc/clear_mage_hand_tethers_for(mob/living/caster)
	if(!caster)
		return
	for(var/datum/sex_session/session as anything in return_sessions_with_user(caster))
		if(!istype(session.remote_context, /datum/sex_remote_context/mage_hand))
			continue
		var/datum/sex_remote_context/mage_hand/context = session.remote_context
		if(context.get_caster() != caster)
			continue
		session.clear_remote_context()
