/datum/sex_session
	var/custom_action_editor_mode = null
	var/custom_action_editor_key = null
	var/datum/sex_custom_action_data/custom_action_editor_draft = null

/datum/sex_session/proc/get_saved_custom_action_data()
	return get_player_custom_sex_actions(user.ckey, get_character_slot(user))

/datum/sex_session/proc/save_saved_custom_action_data(list/custom_actions)
	return save_player_custom_sex_actions(user.ckey, custom_actions, get_character_slot(user))

/datum/sex_session/proc/get_all_menu_actions()
	var/list/menu_actions = list()
	for(var/action_type in GLOB.sex_actions)
		var/datum/sex_action/action = SEX_ACTION(action_type)
		if(action)
			menu_actions += action

	var/list/custom_actions = get_saved_custom_action_data()
	for(var/action_id in custom_actions)
		var/datum/sex_custom_action_data/action_data = custom_actions[action_id]
		if(!action_data)
			continue
		menu_actions += new /datum/sex_action/custom(action_data)

	return menu_actions

/datum/sex_session/proc/is_custom_action_key(action_key)
	return istext(action_key) && findtext(action_key, SEX_CUSTOM_ACTION_PREFIX) == 1

/datum/sex_session/proc/extract_custom_action_id(action_key)
	if(!is_custom_action_key(action_key))
		return null
	return copytext("[action_key]", findtext("[action_key]", SEX_CUSTOM_ACTION_PREFIX) + length(SEX_CUSTOM_ACTION_PREFIX))

/datum/sex_session/proc/resolve_custom_action_id(action_id, list/custom_actions = null)
	if(!length("[action_id]"))
		return null
	if(!islist(custom_actions))
		custom_actions = get_saved_custom_action_data()

	var/raw_id = "[action_id]"
	if(raw_id in custom_actions)
		return raw_id

	var/decoded_id = url_decode(raw_id)
	if(decoded_id in custom_actions)
		return decoded_id

	var/plus_id = replacetext(raw_id, " ", "+")
	if(plus_id in custom_actions)
		return plus_id

	var/space_id = replacetext(raw_id, "+", " ")
	if(space_id in custom_actions)
		return space_id

	return null

/datum/sex_session/proc/get_action_key(action_ref)
	if(istype(action_ref, /datum/sex_action))
		var/datum/sex_action/action = action_ref
		return action.get_menu_action_key()
	if(ispath(action_ref, /datum/sex_action))
		return "[action_ref]"
	if(istext(action_ref))
		var/action_key = trim("[action_ref]")
		if(!length(action_key))
			return null
		if(is_custom_action_key(action_key))
			return action_key
		var/list/custom_actions = get_saved_custom_action_data()
		var/resolved_custom_action_id = resolve_custom_action_id(action_key, custom_actions)
		if(resolved_custom_action_id)
			return "[SEX_CUSTOM_ACTION_PREFIX][resolved_custom_action_id]"
		return action_key
	return null

/datum/sex_session/proc/get_action_template(action_ref)
	if(istype(action_ref, /datum/sex_action))
		return action_ref

	var/action_key = get_action_key(action_ref)
	if(!action_key)
		return null

	var/list/custom_actions = get_saved_custom_action_data()
	if(is_custom_action_key(action_key))
		var/custom_action_id = resolve_custom_action_id(extract_custom_action_id(action_key), custom_actions)
		var/datum/sex_custom_action_data/action_data = custom_actions[custom_action_id]
		if(!action_data)
			return null
		return new /datum/sex_action/custom(action_data)

	var/resolved_custom_action_id = resolve_custom_action_id(action_key, custom_actions)
	if(resolved_custom_action_id)
		var/datum/sex_custom_action_data/action_data = custom_actions[resolved_custom_action_id]
		if(action_data)
			return new /datum/sex_action/custom(action_data)

	var/resolved_action_type = text2path(action_key)
	if(!resolved_action_type || !ispath(resolved_action_type, /datum/sex_action))
		return null
	return SEX_ACTION(resolved_action_type)

/datum/sex_session/proc/instantiate_action(action_ref)
	var/datum/sex_action/action_template = get_action_template(action_ref)
	if(!action_template)
		return null
	return action_template.build_runtime_instance()

/datum/sex_session/proc/get_custom_action_zone_label(part)
	var/zone_mask = get_custom_sex_part_filter_mask(part)
	switch(zone_mask)
		if(SEX_UI_ZONE_MOUTH)
			return "Mouth"
		if(SEX_UI_ZONE_GENITALS)
			return "Genitals"
		if(SEX_UI_ZONE_ARMS)
			return "Arms"
		if(SEX_UI_ZONE_LEGS)
			return "Legs"
		if(SEX_UI_ZONE_BODY)
			return "Body"
	return "Misc"

/datum/sex_session/proc/load_custom_action_draft_from_template(template_id)
	var/datum/sex_custom_action_template/template = GLOB.sex_custom_action_templates[template_id]
	if(!template)
		return FALSE
	custom_action_editor_mode = "template"
	custom_action_editor_key = template_id
	custom_action_editor_draft = template.build_draft()
	return TRUE

/datum/sex_session/proc/load_custom_action_draft_from_saved(action_id)
	var/list/custom_actions = get_saved_custom_action_data()
	action_id = resolve_custom_action_id(action_id, custom_actions)
	var/datum/sex_custom_action_data/action_data = custom_actions[action_id]
	if(!action_data)
		return FALSE
	custom_action_editor_mode = "custom"
	custom_action_editor_key = action_id
	custom_action_editor_draft = action_data.copy()
	return TRUE

/datum/sex_session/proc/reset_custom_action_draft()
	if(custom_action_editor_mode == "custom" && custom_action_editor_key)
		return load_custom_action_draft_from_saved(custom_action_editor_key)
	if(custom_action_editor_mode == "template" && custom_action_editor_key)
		return load_custom_action_draft_from_template(custom_action_editor_key)
	custom_action_editor_draft = null
	custom_action_editor_mode = null
	custom_action_editor_key = null
	return TRUE

/datum/sex_session/proc/save_custom_action_draft()
	if(!custom_action_editor_draft)
		return FALSE

	custom_action_editor_draft.normalize()
	var/list/custom_actions = get_saved_custom_action_data()
	var/is_new_action = !length(custom_action_editor_draft.id)
	if(is_new_action)
		custom_action_editor_draft.id = generate_custom_sex_action_id()
		custom_action_editor_draft.created = world.realtime
	else
		var/datum/sex_custom_action_data/existing_action = custom_actions[custom_action_editor_draft.id]
		if(existing_action?.created)
			custom_action_editor_draft.created = existing_action.created
		else if(!custom_action_editor_draft.created)
			custom_action_editor_draft.created = world.realtime

	custom_action_editor_draft.last_modified = world.realtime
	custom_actions[custom_action_editor_draft.id] = custom_action_editor_draft.copy()

	if(!save_saved_custom_action_data(custom_actions))
		return FALSE

	custom_action_editor_mode = "custom"
	custom_action_editor_key = custom_action_editor_draft.id
	var/datum/sex_custom_action_data/ca = custom_actions[custom_action_editor_draft.id]
	custom_action_editor_draft = ca.copy()
	to_chat(user, span_notice("[is_new_action ? "Saved" : "Updated"] custom action '[custom_action_editor_draft.name]'."))
	return TRUE

/datum/sex_session/proc/delete_custom_action(action_id)
	if(!action_id)
		return FALSE
	var/list/custom_actions = get_saved_custom_action_data()
	action_id = resolve_custom_action_id(action_id, custom_actions)
	if(!(action_id in custom_actions))
		return FALSE
	var/datum/sex_custom_action_data/deleted_action = custom_actions[action_id]
	custom_actions.Remove(action_id)
	if(!save_saved_custom_action_data(custom_actions))
		return FALSE
	if(custom_action_editor_key == action_id)
		custom_action_editor_mode = null
		custom_action_editor_key = null
		custom_action_editor_draft = null
	to_chat(user, span_notice("Deleted custom action '[deleted_action?.name || action_id]'."))
	return TRUE

/datum/sex_session/proc/get_custom_scope_options()
	return list(
		"Partner" = SEX_CUSTOM_SCOPE_PARTNER,
		"Solo" = SEX_CUSTOM_SCOPE_SELF,
	)

/datum/sex_session/proc/get_custom_part_options()
	return list(
		"Unspecified" = SEX_CUSTOM_PART_NONE,
		"Mouth" = SEX_CUSTOM_PART_MOUTH,
		"Penis" = SEX_CUSTOM_PART_PENIS,
		"Vagina" = SEX_CUSTOM_PART_VAGINA,
		"Anus" = SEX_CUSTOM_PART_ANUS,
		"Breasts" = SEX_CUSTOM_PART_BREASTS,
		"Testicles" = SEX_CUSTOM_PART_TESTICLES,
		"Hands" = SEX_CUSTOM_PART_HANDS,
		"Feet" = SEX_CUSTOM_PART_FEET,
		"Thighs" = SEX_CUSTOM_PART_THIGHS,
		"Body" = SEX_CUSTOM_PART_BODY,
		"Any genitals" = SEX_CUSTOM_PART_ANY_GENITALS,
	)

/datum/sex_session/proc/get_custom_climax_options()
	return list(
		"Default" = null,
		"On body" = ORGASM_LOCATION_ONTO,
		"Inside" = ORGASM_LOCATION_INTO,
		"Oral" = ORGASM_LOCATION_ORAL,
		"On self" = ORGASM_LOCATION_SELF,
	)

/datum/sex_session/proc/get_custom_actions_ui_data()
	var/list/templates_out = list()
	for(var/template_id in GLOB.sex_custom_action_templates)
		var/datum/sex_custom_action_template/template = GLOB.sex_custom_action_templates[template_id]
		templates_out += list(list(
			"id" = template_id,
			"name" = template.template_name,
			"summary" = template.template_summary,
			"selected" = (custom_action_editor_mode == "template" && custom_action_editor_key == template_id),
		))

	var/list/saved_out = list()
	var/list/custom_actions = get_saved_custom_action_data()
	for(var/action_id in custom_actions)
		var/datum/sex_custom_action_data/action_data = custom_actions[action_id]
		if(!action_data)
			continue
		saved_out += list(list(
			"id" = action_id,
			"name" = action_data.name,
			"summary" = get_custom_action_summary(action_data),
			"selected" = (custom_action_editor_mode == "custom" && custom_action_editor_key == action_id),
		))

	var/list/editor = null
	if(custom_action_editor_draft)
		custom_action_editor_draft.normalize()
		var/datum/sex_custom_action_data/draft = custom_action_editor_draft
		editor = list(
			"is_saved" = (custom_action_editor_mode == "custom" && length(draft.id)),
			"name" = draft.name,
			"scope" = draft.action_scope,
			"user_part" = draft.required_user_part,
			"target_part" = draft.required_target_part,
			"filter_summary" = "[get_custom_action_zone_label(draft.required_user_part)] -> [get_custom_action_zone_label(draft.required_target_part)]",
			"require_same_tile" = draft.require_same_tile,
			"require_grab" = draft.require_grab,
			"requires_free_hands" = draft.requires_free_hands,
			"gags_user" = draft.gags_user,
			"gags_target" = draft.gags_target,
			"do_time_seconds" = draft.do_time_seconds,
			"stamina_cost" = draft.stamina_cost,
			"user_arousal" = draft.user_arousal,
			"user_pain" = draft.user_pain,
			"user_orgasm" = draft.user_orgasm,
			"target_arousal" = draft.target_arousal,
			"target_pain" = draft.target_pain,
			"target_orgasm" = draft.target_orgasm,
			"message_start" = draft.message_start,
			"message_tick" = draft.message_tick,
			"message_finish" = draft.message_finish,
			"message_climax_active" = draft.message_climax_active,
			"message_climax_passive" = draft.message_climax_passive,
			"active_climax_location" = draft.active_climax_location,
			"passive_climax_location" = draft.passive_climax_location,
			"created_text" = draft.created ? time2text(draft.created, "MM/DD/YY hh:mm") : null,
			"modified_text" = draft.last_modified ? time2text(draft.last_modified, "MM/DD/YY hh:mm") : null,
		)

	return list(
		"templates" = templates_out,
		"saved" = saved_out,
		"scope_options" = build_custom_option_pairs(get_custom_scope_options()),
		"part_options" = build_custom_option_pairs(get_custom_part_options()),
		"climax_options" = build_custom_option_pairs(get_custom_climax_options()),
		"editor" = editor,
	)

/datum/sex_session/proc/build_custom_option_pairs(list/options)
	var/list/out = list()
	for(var/label in options)
		out += list(list("name" = label, "value" = options[label]))
	return out

/// Applies one client-supplied editor field. Field ids are whitelisted;
/// normalize() re-clamps every value afterwards, so raw values are safe to assign.
/datum/sex_session/proc/set_custom_action_field(field_id, value)
	if(!custom_action_editor_draft)
		return FALSE
	var/static/list/text_field_limits = list(
		"name" = 64,
		"message_start" = 400,
		"message_tick" = 400,
		"message_finish" = 400,
		"message_climax_active" = 400,
		"message_climax_passive" = 400,
	)
	// UI field id -> draft var name
	var/static/list/number_fields = list(
		"scope" = "action_scope",
		"user_part" = "required_user_part",
		"target_part" = "required_target_part",
		"do_time_seconds" = "do_time_seconds",
		"stamina_cost" = "stamina_cost",
		"user_arousal" = "user_arousal",
		"user_pain" = "user_pain",
		"user_orgasm" = "user_orgasm",
		"target_arousal" = "target_arousal",
		"target_pain" = "target_pain",
		"target_orgasm" = "target_orgasm",
	)
	var/static/list/toggle_fields = list(
		"require_same_tile",
		"require_grab",
		"requires_free_hands",
		"gags_user",
		"gags_target",
	)
	var/static/list/climax_fields = list(
		"active_climax_location",
		"passive_climax_location",
	)

	if(field_id in text_field_limits)
		var/max_length = text_field_limits[field_id]
		var/new_text = trim("[value]")
		if(length(new_text) > max_length)
			new_text = copytext(new_text, 1, max_length + 1)
		if(field_id == "name" && !length(new_text))
			to_chat(user, span_warning("Custom actions need a name."))
			return FALSE
		custom_action_editor_draft.vars[field_id] = length(new_text) ? new_text : null
	else if(field_id in number_fields)
		custom_action_editor_draft.vars[number_fields[field_id]] = text2num_safe(value)
	else if(field_id in toggle_fields)
		custom_action_editor_draft.vars[field_id] = !custom_action_editor_draft.vars[field_id]
	else if(field_id in climax_fields)
		custom_action_editor_draft.vars[field_id] = sanitize_custom_climax_location(value)
	else
		return FALSE

	custom_action_editor_draft.normalize()
	return TRUE

