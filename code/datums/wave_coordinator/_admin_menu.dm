/datum/tgui_wave_creator
	var/set_id = "default"
	/// Associative list of mob typepath text to spawn count.
	var/list/mob_counts = list()

/datum/tgui_wave_creator/ui_state(mob/user)
	return ADMIN_STATE(R_ADMIN)

/datum/tgui_wave_creator/ui_static_data(mob/user)
	var/static/list/available_mobs
	if(!available_mobs)
		available_mobs = list()
		for(var/mob/living/mob_type as anything in subtypesof(/mob/living))
			if(IS_ABSTRACT(mob_type) || !ispath(initial(mob_type:ai_controller), /datum/ai_controller))
				continue
			available_mobs += list(list(
				"path" = "[mob_type]",
				"name" = initial(mob_type:name) || "[mob_type]",
			))
	return list("living_subtypes" = available_mobs)

/datum/tgui_wave_creator/ui_data(mob/user)
	var/list/matching_landmarks = list()
	for(var/obj/effect/landmark/wave_defense/landmark in GLOB.wave_defense_landmarks)
		if(landmark.set_id == set_id)
			matching_landmarks += landmark
	sortTim(matching_landmarks, GLOBAL_PROC_REF(cmp_wave_landmark_order))

	var/list/waypoint_data = list()
	for(var/obj/effect/landmark/wave_defense/landmark as anything in matching_landmarks)
		waypoint_data += list(list(
			"ref" = REF(landmark),
			"order" = landmark.order,
			"name" = landmark.name,
			"coordinates" = "([landmark.x], [landmark.y], [landmark.z])",
		))

	var/list/mob_entries = list()
	for(var/path_text in mob_counts)
		if(mob_counts[path_text] <= 0)
			continue
		var/mob_type = text2path(path_text)
		if(!ispath(mob_type, /mob/living))
			continue
		mob_entries += list(list(
			"path" = path_text,
			"name" = initial(mob_type:name) || path_text,
			"count" = mob_counts[path_text],
		))

	return list(
		"set_id" = set_id,
		"waypoints" = waypoint_data,
		"mob_entries" = mob_entries,
	)

/datum/tgui_wave_creator/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	var/mob/user = ui.user
	switch(action)
		if("set_set_id")
			var/new_id = trim(copytext(sanitize(params["set_id"]), 1, 65))
			if(!length(new_id))
				return FALSE
			set_id = new_id
			return TRUE

		if("add_waypoint")
			var/turf/user_turf = get_turf(user)
			if(!user_turf)
				return FALSE
			var/obj/effect/landmark/wave_defense/waypoint = new(user_turf)
			waypoint.set_id = set_id
			var/highest_order = 0
			for(var/obj/effect/landmark/wave_defense/existing in GLOB.wave_defense_landmarks)
				if(existing.set_id == set_id && existing.order > highest_order)
					highest_order = existing.order
			waypoint.order = highest_order + 1
			return TRUE

		if("remove_waypoint")
			var/obj/effect/landmark/wave_defense/waypoint = locate(params["ref"])
			if((waypoint in GLOB.wave_defense_landmarks) && waypoint.set_id == set_id)
				qdel(waypoint)
			return TRUE

		if("set_mob_count")
			var/path_text = params["path"]
			var/mob/living/mob_type = text2path(path_text)
			if(!ispath(mob_type, /mob/living) || IS_ABSTRACT(mob_type) || !ispath(initial(mob_type:ai_controller), /datum/ai_controller))
				return FALSE
			var/count = clamp(round(text2num(params["count"])), 0, 50)
			if(!count)
				mob_counts -= path_text
			else
				mob_counts[path_text] = count
			return TRUE

		if("launch_wave")
			return spawn_wave(user)

	return FALSE

/datum/tgui_wave_creator/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new /datum/tgui(user, src, "WaveCreator", "Wave Creator")
		ui.open()

/datum/tgui_wave_creator/ui_close(mob/user)
	qdel(src)

/datum/tgui_wave_creator/proc/spawn_wave(mob/admin)
	var/list/points = get_wave_defense_points(set_id)
	if(!length(points))
		to_chat(admin, span_warning("No wave defense landmarks found for set '[set_id]'."))
		return FALSE
	var/turf/spawn_turf = get_turf(admin)
	if(!spawn_turf)
		to_chat(admin, span_warning("You must be on the map to launch a wave."))
		return FALSE

	var/list/mob/living/wave_mobs = list()
	for(var/path_text in mob_counts)
		var/mob/living/mob_type = text2path(path_text)
		if(!ispath(mob_type, /mob/living) || IS_ABSTRACT(mob_type) || !ispath(initial(mob_type:ai_controller), /datum/ai_controller))
			continue
		for(var/index in 1 to mob_counts[path_text])
			var/mob/living/wave_mob = new mob_type(spawn_turf)
			if(!wave_mob.ai_controller)
				qdel(wave_mob)
				continue
			wave_mobs += wave_mob

	if(!length(wave_mobs))
		to_chat(admin, span_warning("No AI-controlled mobs are configured; the wave was not launched."))
		return FALSE

	var/admin_key = key_name(admin)
	new /datum/wave_defense_coordinator(
		set_id,
		wave_mobs,
		on_complete = CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(report_admin_wave_complete), admin_key, set_id),
		on_failed = CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(report_admin_wave_failed), admin_key, set_id),
	)
	to_chat(admin, span_notice("Wave launched: [length(wave_mobs)] mob(s), [length(points)] waypoint(s)."))
	message_admins("[admin_key] launched wave '[set_id]' with [length(wave_mobs)] mobs.")
	return TRUE

/proc/report_admin_wave_complete(admin_key, set_id, datum/wave_defense_coordinator/coordinator)
	message_admins("Wave '[set_id]' spawned by [admin_key] completed.")

/proc/report_admin_wave_failed(admin_key, set_id, datum/wave_defense_coordinator/coordinator)
	message_admins("Wave '[set_id]' spawned by [admin_key] failed.")

/client/proc/open_wave_creator()
	set name = "Open Wave Creator"
	set category = "GameMaster.Fun"
	if(!check_rights(R_ADMIN))
		return
	var/datum/tgui_wave_creator/creator = new
	creator.ui_interact(mob)
