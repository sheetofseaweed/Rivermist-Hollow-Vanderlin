/**
 * # Agent profile menu
 *
 * Write a character in the round, then spawn it or put it on a mob that is
 * already standing there.
 *
 * Everything arriving from the window is treated as hostile: field names are
 * checked against a whitelist, actions against the protocol vocabulary, and
 * attach targets are re-resolved from the admin's own view rather than trusted
 * as refs. A ref that is not in view is refused even if it names a real mob.
 */
/datum/agent_profile_menu
	/// The library entry being edited, or a built-in typepath as text.
	var/selected
	var/mob/owner

/datum/agent_profile_menu/New(mob/new_owner)
	. = ..()
	owner = new_owner
	// Lazily, so a round that never opens the menu never touches the disk.
	if(!length(GLOB.agent_custom_profiles))
		SSagent_npc.load_profiles()

/datum/agent_profile_menu/Destroy(force, ...)
	owner = null
	return ..()

/datum/agent_profile_menu/ui_state(mob/user)
	return ADMIN_STATE(R_DEBUG)

/datum/agent_profile_menu/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AgentProfileMenu")
		ui.open()

/datum/agent_profile_menu/ui_static_data(mob/user)
	return list(
		"vocabulary" = GLOB.agent_action_vocabulary.Copy(),
		"builtins" = agent_builtin_profiles(),
		"labelMax" = AGENT_PROFILE_LABEL_MAX,
		"textMax" = AGENT_PROFILE_TEXT_MAX,
		"aliasMax" = AGENT_MAX_ALIASES,
	)

/datum/agent_profile_menu/ui_data(mob/user)
	var/list/profiles = list()
	for(var/name in GLOB.agent_custom_profiles)
		var/datum/agent_profile/profile = GLOB.agent_custom_profiles[name]
		if(QDELETED(profile))
			continue
		var/list/payload = profile.to_payload()
		payload["name"] = name
		profiles += list(payload)

	return list(
		"profiles" = profiles,
		"selected" = selected,
		"targets" = build_target_list(user),
		"subsystemEnabled" = SSagent_npc.enabled && !SSagent_npc.globally_disabled,
		"registered" = length(SSagent_npc.bindings),
	)

/// Mobs near the admin that could take an agent controller, and those that have one.
/datum/agent_profile_menu/proc/build_target_list(mob/user)
	var/list/targets = list()
	if(QDELETED(user))
		return targets

	for(var/mob/living/nearby in view(AGENT_ATTACH_RANGE, user))
		if(nearby == user)
			continue
		targets += list(list(
			"ref" = "[REF(nearby)]",
			"name" = "[nearby.name]",
			"agent" = istype(nearby.ai_controller, /datum/ai_controller/agent_social),
			// Attaching is allowed on anything clientless, but the controller is
			// built for humanoids, so the window says which is which.
			"humanoid" = ishuman(nearby),
			"player" = !isnull(nearby.client),
		))
	return targets

/// Resolve a ref the window sent, but only if it is genuinely in view now.
/datum/agent_profile_menu/proc/resolve_target(mob/user, supplied_ref)
	RETURN_TYPE(/mob/living)
	if(!istext(supplied_ref) || QDELETED(user))
		return null
	for(var/mob/living/nearby in view(AGENT_ATTACH_RANGE, user))
		if("[REF(nearby)]" == supplied_ref)
			return nearby
	return null

/datum/agent_profile_menu/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	var/mob/user = ui.user
	if(!check_rights_for(user.client, R_DEBUG))
		return TRUE

	switch(action)
		if("select")
			selected = istext(params["name"]) ? params["name"] : null
			return TRUE

		if("create")
			var/datum/agent_profile/template = agent_resolve_profile(params["from"])
			var/datum/agent_profile/made = template ? template.clone() : new /datum/agent_profile()
			var/name = agent_unique_profile_name(template ? template.label : "new profile")
			GLOB.agent_custom_profiles[name] = made
			selected = name
			log_admin("[key_name(user)] created agent profile '[name]'.")
			return TRUE

		if("delete")
			var/name = params["name"]
			if(!istext(name) || !GLOB.agent_custom_profiles[name])
				return TRUE
			QDEL_NULL(GLOB.agent_custom_profiles[name])
			GLOB.agent_custom_profiles -= name
			if(selected == name)
				selected = null
			log_admin("[key_name(user)] deleted agent profile '[name]'.")
			return TRUE

		if("rename")
			var/datum/agent_profile/profile = GLOB.agent_custom_profiles[selected]
			if(QDELETED(profile))
				return TRUE
			var/wanted = agent_clean_profile_text(params["name"], AGENT_PROFILE_LABEL_MAX)
			if(!length(wanted) || wanted == selected)
				return TRUE
			var/name = agent_unique_profile_name(wanted)
			GLOB.agent_custom_profiles -= selected
			GLOB.agent_custom_profiles[name] = profile
			selected = name
			return TRUE

		if("set_field")
			var/datum/agent_profile/profile = GLOB.agent_custom_profiles[selected]
			if(QDELETED(profile))
				return TRUE
			var/field = params["field"]
			// Whitelist, not a blacklist: a writable field name must be one we
			// chose, never one the window picked.
			if(!(field in GLOB.agent_profile_text_fields))
				return TRUE
			var/limit = (field == "label") ? AGENT_PROFILE_LABEL_MAX : AGENT_PROFILE_TEXT_MAX
			profile.vars[field] = agent_clean_profile_text(params["value"], limit)
			return TRUE

		if("set_aliases")
			var/datum/agent_profile/profile = GLOB.agent_custom_profiles[selected]
			if(QDELETED(profile))
				return TRUE
			profile.aliases = agent_clean_profile_aliases(params["value"])
			return TRUE

		if("toggle_action")
			var/datum/agent_profile/profile = GLOB.agent_custom_profiles[selected]
			if(QDELETED(profile))
				return TRUE
			var/entry = params["action"]
			if(!istext(entry) || !(entry in GLOB.agent_action_vocabulary))
				return TRUE
			var/list/wanted = profile.permitted_actions.Copy()
			if(entry in wanted)
				wanted -= entry
			else
				wanted += entry
			// Re-cleaned, so removing `wait` puts it straight back rather than
			// leaving a character that can never end a conversation.
			profile.permitted_actions = agent_clean_profile_actions(wanted)
			return TRUE

		if("save")
			var/saved = SSagent_npc.save_profiles()
			to_chat(user, span_notice("Saved [saved] agent profile(s) to [AGENT_PROFILE_FILE]."))
			return TRUE

		if("reload")
			var/loaded = SSagent_npc.load_profiles()
			if(loaded < 0)
				to_chat(user, span_warning("[AGENT_PROFILE_FILE] could not be read. The profiles already loaded were kept."))
				return TRUE
			selected = null
			to_chat(user, span_notice("Loaded [loaded] agent profile(s)."))
			return TRUE

		if("spawn")
			return handle_spawn(user)

		if("attach")
			var/mob/living/target = resolve_target(user, params["ref"])
			if(!target)
				to_chat(user, span_warning("That mob is no longer in view."))
				return TRUE
			var/refusal = agent_attach_controller(target, agent_resolve_profile(selected))
			if(refusal)
				to_chat(user, span_warning("Could not attach: [refusal]."))
				return TRUE
			to_chat(user, span_notice("Attached an agent controller to [target.name]."))
			message_admins("[key_name_admin(user)] attached an agent controller to [target.name] at [AREACOORD(target)].")
			log_admin("[key_name(user)] attached an agent controller to [target.name].")
			return TRUE

		if("detach")
			var/mob/living/target = resolve_target(user, params["ref"])
			if(!target)
				to_chat(user, span_warning("That mob is no longer in view."))
				return TRUE
			var/refusal = agent_detach_controller(target)
			if(refusal)
				to_chat(user, span_warning("Could not detach: [refusal]."))
				return TRUE
			to_chat(user, span_notice("Removed agent control from [target.name]."))
			message_admins("[key_name_admin(user)] removed agent control from [target.name].")
			log_admin("[key_name(user)] removed agent control from [target.name].")
			return TRUE

/datum/agent_profile_menu/proc/handle_spawn(mob/user)
	var/turf/here = get_turf(user)
	if(!here)
		to_chat(user, span_warning("You are not standing anywhere."))
		return TRUE

	var/mob/living/carbon/human/species/human/northern/agent_social/spawned = new(here)
	var/datum/ai_controller/agent_social/controller = spawned.ai_controller
	var/datum/agent_profile/chosen = agent_resolve_profile(selected)
	if(istype(controller) && chosen)
		QDEL_NULL(controller.profile)
		controller.profile = chosen.clone()
		controller.register_cooldown = 0
		controller.ensure_registered()

	var/bound = istype(controller) && controller.binding && !QDELETED(controller.binding)
	if(!bound)
		to_chat(user, span_warning("Spawned, but it did NOT bind to SSagent_npc. It will behave as an \
			ordinary passive NPC. Check that AGENT_NPC_ENABLED is set and the subsystem is not disabled."))
	else
		to_chat(user, span_notice("Spawned [spawned.name] as '[controller.profile.label]'."))

	message_admins("[key_name_admin(user)] spawned an agent NPC at [AREACOORD(here)].")
	log_admin("[key_name(user)] spawned an agent NPC at [AREACOORD(here)].")
	return TRUE

/**
 * # Agent control from View Variables
 *
 * The menu is for writing characters and spawning them. This is for pointing at
 * a mob that already exists, which VV already solves: the target is whatever you
 * opened VV on, so there is no list to search and no range limit.
 */
/mob/living/vv_get_dropdown()
	. = ..()
	VV_DROPDOWN_OPTION(VV_HK_AGENT_CONTROL, "Agent NPC - Attach / Detach")

/mob/living/vv_do_topic(list/href_list)
	. = ..()
	if(!href_list[VV_HK_AGENT_CONTROL])
		return
	if(!check_rights(R_DEBUG))
		return
	agent_vv_control(usr)

/// Pick a profile for this mob, or take agent control off it.
/mob/living/proc/agent_vv_control(mob/user)
	if(!length(GLOB.agent_custom_profiles))
		SSagent_npc.load_profiles()

	var/static/detach_label = "--- remove agent control ---"
	var/list/choices = list()
	if(istype(ai_controller, /datum/ai_controller/agent_social))
		choices[detach_label] = detach_label
	for(var/profile_name in GLOB.agent_custom_profiles)
		choices["[profile_name]"] = profile_name
	for(var/list/builtin as anything in agent_builtin_profiles())
		choices["[builtin["label"]] (built in)"] = builtin["type"]

	var/picked = input(user, "Agent control for [name]", "Agent NPC") as null|anything in choices
	if(!picked)
		return
	var/chosen = choices[picked]

	// input() sleeps. The mob may have been deleted, taken by a player, or had
	// its controller changed while the box was open, so decide again now.
	if(QDELETED(src) || QDELETED(user))
		return
	var/agent_now = istype(ai_controller, /datum/ai_controller/agent_social)

	if(chosen == detach_label)
		var/refusal = agent_detach_controller(src)
		if(refusal)
			to_chat(user, span_warning("Could not detach: [refusal]."))
			return
		to_chat(user, span_notice("Removed agent control from [name]."))
		message_admins("[key_name_admin(user)] removed agent control from [name].")
		log_admin("[key_name(user)] removed agent control from [name].")
		return

	var/datum/agent_profile/chosen_profile = agent_resolve_profile(chosen)
	if(!chosen_profile)
		to_chat(user, span_warning("That profile no longer exists."))
		return

	if(agent_now)
		// Swap in place. Refusing here would mean detaching and reattaching just
		// to change who an NPC is, which drops the binding and the conversation.
		var/swap_refusal = agent_swap_profile(src, chosen_profile)
		if(swap_refusal)
			to_chat(user, span_warning("Could not change profile: [swap_refusal]."))
			return
		to_chat(user, span_notice("[name] is now playing '[chosen_profile.label]'."))
		message_admins("[key_name_admin(user)] changed [name]'s agent profile to '[chosen_profile.label]'.")
		log_admin("[key_name(user)] changed [name]'s agent profile to '[chosen_profile.label]'.")
		return

	var/refusal = agent_attach_controller(src, chosen_profile)
	if(refusal)
		to_chat(user, span_warning("Could not attach: [refusal]."))
		return
	to_chat(user, span_notice("[name] is now agent controlled as '[chosen_profile.label]'."))
	message_admins("[key_name_admin(user)] attached an agent controller to [name] at [AREACOORD(src)].")
	log_admin("[key_name(user)] attached an agent controller to [name].")

/client/proc/agent_npc_profiles()
	set category = "Debug.Agent NPC"
	set name = "Agent NPC - Profiles"
	if(!check_rights(R_DEBUG))
		return

	var/datum/agent_profile_menu/menu = new(mob)
	menu.ui_interact(mob)
