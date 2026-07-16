/// TGUI port of the sex session window. Data builders + ui_act live here;
/// domain logic stays in sex_session.dm.

/datum/sex_session/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SexSession", "Sate Desire", 725, 470)
		ui.set_autoupdate(FALSE)
		ui.open()

/datum/sex_session/ui_state(mob/user)
	// Session procs do their own distance/consciousness checks per action;
	// the window must stay usable while lying down or grabbed.
	return GLOB.always_state

/datum/sex_session/ui_data(mob/viewer)
	var/list/data = list()
	data["target_name"] = target?.name
	data["is_self"] = (user == target)

	var/list/status_lines = list()
	for(var/line in user.return_character_information())
		if(line)
			status_lines += line
	data["status_lines"] = status_lines

	data["arousal"] = get_arousal_ui_data()
	data["controls"] = list(
		"speed" = speed,
		"force" = force,
		"resist" = resistance_to_pleasure,
		"manual_arousal" = manual_arousal,
		"has_penis" = !!user.getorganslot(ORGAN_SLOT_PENIS),
		"do_until_finished" = do_until_finished,
		"edging_other" = edging_other,
		"lying_direction" = user.get_lying_direction_name(),
	)
	data["zone_options"] = get_zone_options_ui_data()
	data["actions"] = get_actions_ui_data()
	data["bellyriding"] = get_bellyriding_ui_data()
	data["custom"] = get_custom_actions_ui_data()
	data["intimacy"] = get_intimacy_ui_data()
	data["notes"] = get_notes_ui_data()
	return data

/datum/sex_session/proc/get_arousal_ui_data()
	var/list/arousal_data = list()
	SEND_SIGNAL(user, COMSIG_SEX_GET_AROUSAL, arousal_data)
	var/current_arousal = arousal_data["arousal"] || 0
	var/orgasm_progress = arousal_data["orgasm_progress"] || 0
	return list(
		"arousal_pct" = min(100, (current_arousal / MAX_AROUSAL) * 100),
		"orgasm_pct" = min(100, (orgasm_progress / PASSIVE_EJAC_THRESHOLD) * 100),
		"pain_pct" = 0,
	)

/datum/sex_session/proc/get_zone_options_ui_data()
	var/list/options = list()
	for(var/filter_label in action_zone_filter_options)
		options += list(list(
			"name" = filter_label,
			"value" = action_zone_filter_options[filter_label],
		))
	return options

/datum/sex_session/proc/get_actions_ui_data()
	var/list/actions_out = list()
	for(var/datum/sex_action/action as anything in active_actions)
		actions_out += list(list(
			"key" = action.get_menu_action_key(),
			"name" = action.name,
			"active" = TRUE,
			"can_perform" = TRUE,
			"user_zones" = action.user_menu_zone_mask,
			"target_zones" = action.target_menu_zone_mask,
		))
	for(var/datum/sex_action/action as anything in get_all_menu_actions())
		if(!action.shows_on_menu(user, target))
			continue
		if(is_action_active(action))
			continue
		actions_out += list(list(
			"key" = action.get_menu_action_key(),
			"name" = action.name,
			"active" = FALSE,
			"can_perform" = can_perform_action(action),
			"user_zones" = action.user_menu_zone_mask,
			"target_zones" = action.target_menu_zone_mask,
		))
	return actions_out

/datum/sex_session/proc/get_bellyriding_ui_data()
	var/datum/component/bellyriding/belly_comp = get_bellyriding_component()
	if(!belly_comp)
		return null
	var/static/list/bellyriding_action_types = list(
		/datum/sex_action/bellyriding/groin_rub,
		/datum/sex_action/bellyriding/frot,
		/datum/sex_action/bellyriding/vaginal,
		/datum/sex_action/bellyriding/anal,
	)
	var/list/actions_out = list()
	for(var/action_type in bellyriding_action_types)
		var/datum/sex_action/action = SEX_ACTION(action_type)
		if(!action)
			continue
		actions_out += list(list(
			"key" = "[action_type]",
			"name" = action.name,
			"selected" = (belly_comp.selected_action_type == action_type),
			"can_perform" = can_perform_action(action),
		))
	return list(
		"enabled" = belly_comp.enable_interactions,
		"actions" = actions_out,
	)

/datum/sex_session/proc/get_intimacy_ui_data()
	var/list/out = list(
		"lock_reason" = null,
		"yours" = list(),
		"theirs" = list(),
		"their_kinks" = list(),
	)
	var/list/your_erp_data
	var/datum/preferences/your_prefs = user?.client?.prefs
	if(your_prefs)
		your_erp_data = your_prefs.character_setup_erp_data(user)
		out["yours"] = your_erp_data["categories"]
		out["lock_reason"] = your_erp_data["lock_reason"]

	var/list/their_erp_data = your_erp_data
	if(target != user)
		their_erp_data = null
		var/datum/preferences/their_prefs = target?.client?.prefs
		if(their_prefs)
			their_erp_data = their_prefs.character_setup_erp_data(target)
			out["theirs"] = their_erp_data["categories"]

	if(their_erp_data)
		var/list/categories_out = list()
		for(var/list/category in their_erp_data["kink_categories"])
			var/list/kinks_out = list()
			for(var/list/kink in category["kinks"])
				if(!kink["enabled"])
					continue
				kinks_out += list(kink)
			if(length(kinks_out))
				categories_out += list(list("name" = category["name"], "kinks" = kinks_out))
		out["their_kinks"] = categories_out
	return out

/datum/sex_session/proc/get_notes_ui_data()
	var/list/yours_out = list()
	var/list/theirs_out = list()
	if(user?.ckey)
		var/list/self_notes = get_player_notes_about(user.ckey, user.ckey, get_character_slot(user))
		for(var/note_title in self_notes)
			yours_out += list(build_note_ui_entry(note_title, self_notes[note_title]))
	if(target != user && target?.ckey)
		var/list/target_self_notes = get_player_notes_about(target.ckey, target.ckey, get_character_slot(target))
		for(var/note_title in target_self_notes)
			theirs_out += list(build_note_ui_entry(note_title, target_self_notes[note_title]))
	return list("yours" = yours_out, "theirs" = theirs_out)

/datum/sex_session/proc/build_note_ui_entry(note_title, list/note_data)
	var/created_time = note_data["created"]
	var/modified_time = note_data["last_modified"]
	var/meta = "Created: [time2text(created_time, "MM/DD/YY hh:mm")]"
	if(modified_time != created_time)
		meta += " | Modified: [time2text(modified_time, "MM/DD/YY hh:mm")]"
	return list(
		"title" = note_title,
		"content" = note_data["content"],
		"meta" = meta,
	)

/datum/sex_session/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(ui.user != user)
		return FALSE

	switch(action)
		if("action")
			if(!get_action_template(params["key"]))
				return FALSE
			try_start_action(params["key"])
			return TRUE
		if("stop")
			try_stop_current_action(params["key"])
			return TRUE
		if("set_speed")
			var/value = text2num("[params["value"]]")
			if(isnull(value) || value < SEX_SPEED_MIN || value > SEX_SPEED_MAX)
				return FALSE
			set_current_speed(value)
			return TRUE
		if("set_force")
			var/value = text2num("[params["value"]]")
			if(isnull(value) || value < SEX_FORCE_MIN || value > SEX_FORCE_MAX)
				return FALSE
			set_current_force(value)
			return TRUE
		if("set_resist")
			var/value = text2num("[params["value"]]")
			if(isnull(value) || value < RESIST_NONE || value > RESIST_HIGH)
				return FALSE
			set_current_resist(value)
			return TRUE
		if("set_manual_arousal")
			var/value = text2num("[params["value"]]")
			if(isnull(value) || value < SEX_MANUAL_AROUSAL_MIN || value > SEX_MANUAL_AROUSAL_MAX)
				return FALSE
			manual_arousal = value
			SEND_SIGNAL(user, COMSIG_SET_ERECT_STATE, manual_arousal > 2)
			return TRUE
		if("toggle_finished")
			do_until_finished = !do_until_finished
			return TRUE
		if("toggle_edging")
			edging_other = !edging_other
			return TRUE
		if("swap_side")
			user.swap_lying_direction()
			return TRUE
		if("bellyriding_toggle")
			var/datum/component/bellyriding/belly_comp = get_bellyriding_component()
			if(!belly_comp)
				return FALSE
			belly_comp.enable_interactions = !belly_comp.enable_interactions
			return TRUE
		if("bellyriding_release")
			var/datum/component/bellyriding/belly_comp = get_bellyriding_component()
			if(!belly_comp)
				return FALSE
			belly_comp.unbuckle_victim()
			return TRUE
		if("bellyriding_action")
			var/datum/component/bellyriding/belly_comp = get_bellyriding_component()
			var/datum/sex_action/belly_action = get_action_template(params["key"])
			if(!belly_comp || !belly_action || !ispath(belly_action.type, /datum/sex_action/bellyriding))
				return FALSE
			belly_comp.set_selected_action(belly_action.type, user)
			INVOKE_ASYNC(belly_comp, TYPE_PROC_REF(/datum/component/bellyriding, maybe_do_interaction))
			return TRUE
		if("bellyriding_clear")
			var/datum/component/bellyriding/belly_comp = get_bellyriding_component()
			if(!belly_comp)
				return FALSE
			belly_comp.set_selected_action(null, user)
			return TRUE
		if("erp_pref")
			if(!user.client?.prefs)
				return FALSE
			// handle_erp_pref_topic reads href-style text values; tgui sends
			// JSON numbers, so stringify every param (text2num(number) runtimes).
			var/list/href_list = list()
			for(var/key in params)
				href_list[key] = "[params[key]]"
			user.client.prefs.handle_erp_pref_topic(user, href_list)
			return TRUE
		if("note_add")
			var/note_title = trim("[params["title"]]")
			var/note_content = trim("[params["content"]]")
			if(!length(note_title) || !length(note_content))
				to_chat(user, span_warning("Both title and content are required."))
				return TRUE
			note_title = copytext(note_title, 1, 129)
			var/character_slot = get_character_slot(user)
			var/list/existing_notes = get_player_notes_about(user.ckey, user.ckey, character_slot)
			if(existing_notes[note_title])
				to_chat(user, span_warning("A note with that title already exists. Please choose a different title."))
				return TRUE
			// Old HTML code wrote this under target.ckey by mistake, so fresh
			// self-notes never appeared in the list; write under our own key.
			if(set_player_note_about(user.ckey, user.ckey, note_title, note_content, character_slot))
				to_chat(user, span_notice("Note '[note_title]' saved."))
			else
				to_chat(user, span_warning("Failed to save note."))
			return TRUE
		if("note_edit")
			var/note_title = "[params["title"]]"
			var/note_content = trim("[params["content"]]")
			if(!length(note_title) || !length(note_content))
				return FALSE
			var/character_slot = get_character_slot(user)
			var/list/notes = get_player_notes_about(user.ckey, user.ckey, character_slot)
			if(!notes[note_title])
				to_chat(user, span_warning("Note not found."))
				return TRUE
			set_player_note_about(user.ckey, user.ckey, note_title, note_content, character_slot)
			return TRUE
		if("note_remove")
			var/note_title = "[params["title"]]"
			if(!length(note_title))
				return FALSE
			var/character_slot = get_character_slot(user)
			var/datum/save_manager/note_save_manager = get_save_manager(user.ckey)
			if(!note_save_manager)
				return FALSE
			var/save_name = "character_[character_slot]_notes"
			var/list/all_notes = note_save_manager.get_data(save_name, "partner_notes", list())
			var/list/own_notes = all_notes[ckey(user.ckey)]
			if(!islist(own_notes) || !own_notes[note_title])
				to_chat(user, span_warning("Note not found."))
				return TRUE
			own_notes -= note_title
			note_save_manager.set_data(save_name, "partner_notes", all_notes)
			return TRUE
		if("custom_select_template")
			return load_custom_action_draft_from_template("[params["id"]]")
		if("custom_select_saved")
			return load_custom_action_draft_from_saved("[params["id"]]")
		if("custom_field")
			return set_custom_action_field("[params["field"]]", params["value"])
		if("custom_save")
			if(!save_custom_action_draft())
				to_chat(user, span_warning("Failed to save the custom action."))
			return TRUE
		if("custom_reset")
			return reset_custom_action_draft()
		if("custom_delete")
			// Deletion is confirmed client-side via Button.Confirm.
			if(!delete_custom_action("[params["id"]]"))
				to_chat(user, span_warning("Failed to find that custom action."))
			return TRUE

	return FALSE
