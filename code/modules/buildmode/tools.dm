/**
 * Basic mode tools: place, exact pixel, paint area, erase area, copy, pick type, delete.
 *
 * The tool picked in the catalogue decides what a plain left click does. The modifier hotkeys
 * always work, whatever tool is picked, so experienced builders never need the buttons:
 * the catalogue shows each tool's hotkey next to its button.
 *
 * Area tools follow the mouse: the middle button (or the left button with an area tool picked)
 * is held down on the first corner and released on the opposite one.
 */

/datum/buildmode
	/// What a plain left click does in Basic mode, a BM_TOOL_* value.
	var/active_tool = BM_TOOL_PLACE
	/// Whether a plain right click with nothing selected deletes. Ctrl + right click always does.
	var/rmb_delete = TRUE
	/// Exact object copied with Ctrl + left click. Placement duplicates it, variables included.
	var/datum/weakref/copy_ref
	/// Area drag in progress: first and current corner.
	var/turf/area_start
	var/turf/area_end
	/// Mouse button that drives the drag in progress (LEFT_CLICK or MIDDLE_CLICK).
	var/area_button
	/// Whether the drag in progress erases instead of painting.
	var/area_erase = FALSE
	/// Outline of the dragged rectangle, shown only to the builder.
	var/list/area_images

/proc/buildmode_tool_ids()
	var/static/list/tools = list(BM_TOOL_PLACE, BM_TOOL_PIXEL, BM_TOOL_AREA, BM_TOOL_ERASE, BM_TOOL_COPY, BM_TOOL_PICK, BM_TOOL_DELETE)
	return tools

/datum/buildmode/proc/setup_tools()
	RegisterSignal(holder, COMSIG_CLIENT_MOUSEDOWN, PROC_REF(on_client_mousedown))
	RegisterSignal(holder, COMSIG_CLIENT_MOUSEDRAG, PROC_REF(on_client_mousedrag))
	RegisterSignal(holder, COMSIG_CLIENT_MOUSEUP, PROC_REF(on_client_mouseup))

/datum/buildmode/proc/cleanup_tools()
	if(holder)
		UnregisterSignal(holder, list(COMSIG_CLIENT_MOUSEDOWN, COMSIG_CLIENT_MOUSEDRAG, COMSIG_CLIENT_MOUSEUP))
	clear_area()
	copy_ref = null
	clear_undo()

/// Picks the tool a plain left click uses. Tools belong to Basic mode, so this switches to it.
/datum/buildmode/proc/set_tool(tool)
	if(!(tool in buildmode_tool_ids()))
		return FALSE
	active_tool = tool
	clear_area()
	if(!istype(mode, /datum/buildmode_mode/basic))
		change_mode(/datum/buildmode_mode/basic)
	item_browser?.send_selection()
	return TRUE

/// Locks or unlocks deleting with a plain right click. Ctrl + right click always deletes.
/datum/buildmode/proc/set_rmb_delete(enabled)
	rmb_delete = !!enabled
	item_browser?.set_status(rmb_delete ? "Right click deletes again (after clearing the selection)." : "Right-click deleting is locked. Ctrl + right click still deletes.")
	item_browser?.write_preferences()
	return TRUE

/// The object being copied, if it still exists and still matches the selection.
/datum/buildmode/proc/copy_template()
	var/atom/movable/template = copy_ref?.resolve()
	if(QDELETED(template) || template.type != selected_item)
		copy_ref = null
		return null
	return template

/// Builds one copy of the selection on target: an exact duplicate when copying, a fresh instance otherwise.
/datum/buildmode/proc/spawn_one(turf/target, atom/movable/template)
	var/atom/movable/built
	if(template)
		built = buildmode_duplicate(template, target)
	else
		built = new selected_item(target)
	if(QDELETED(built))
		return null
	built.flags_1 |= ADMIN_SPAWNED_1
	built.setDir(build_dir)
	return built

/// Makes an exact copy of object the selection. Turfs are copied by type.
/datum/buildmode/proc/copy_object(atom/object)
	if(QDELETED(object) || istype(object, /atom/movable/screen))
		return FALSE
	if(ismob(object))
		var/mob/target_mob = object
		if(target_mob.ckey)
			item_browser?.set_status("Players cannot be copied.")
			return FALSE
	if(isturf(object))
		return select_item(object.type)
	if(!ismovable(object))
		return FALSE
	if(!select_item(object.type))
		return FALSE
	copy_ref = WEAKREF(object)
	change_dir(object.dir)
	item_browser?.set_status("Copying [object.name] exactly, variables included. Left click to place copies.")
	return TRUE

/datum/buildmode/proc/rotate_build_dir()
	change_dir(turn(build_dir, -90))
	item_browser?.set_status("Build direction: [dir2text(build_dir)].")

/// Basic mode click handling: hotkeys first, then the picked tool.
/datum/buildmode/proc/handle_tool_click(client/c, list/modifiers, atom/object)
	// Middle button work is done by the drag handlers, including a click without movement.
	if(LAZYACCESS(modifiers, MIDDLE_CLICK))
		return
	var/ctrl = LAZYACCESS(modifiers, CTRL_CLICKED)
	var/alt = LAZYACCESS(modifiers, ALT_CLICKED)
	var/shift = LAZYACCESS(modifiers, SHIFT_CLICKED)

	if(LAZYACCESS(modifiers, RIGHT_CLICK))
		if(ctrl)
			delete_object(c.mob, object)
		else if(alt)
			rotate_build_dir()
		else if(selected_item)
			// The first right click only drops the selection, so a stray click never deletes.
			clear_selection()
		else if(rmb_delete)
			delete_object(c.mob, object)
		else
			item_browser?.set_status("Right-click deleting is locked. Use Ctrl + right click, or unlock it in Tools.")
		return
	if(!LAZYACCESS(modifiers, LEFT_CLICK))
		return

	if(alt)
		use_tool(BM_TOOL_PICK, c, modifiers, object)
	else if(ctrl)
		use_tool(BM_TOOL_COPY, c, modifiers, object)
	else if(shift)
		use_tool(BM_TOOL_PIXEL, c, modifiers, object)
	else
		use_tool(active_tool, c, modifiers, object)

/datum/buildmode/proc/use_tool(tool, client/c, list/modifiers, atom/object)
	switch(tool)
		if(BM_TOOL_PLACE)
			if(!selected_item)
				to_chat(c, span_warning("Pick something in the catalogue first."))
				return
			place_selected(get_turf(object), c.mob)
		if(BM_TOOL_PIXEL)
			if(!selected_item)
				to_chat(c, span_warning("Pick something in the catalogue first."))
				return
			var/list/cursor = resolve_cursor(modifiers)
			if(cursor)
				place_selected(cursor[1], c.mob, cursor[2], cursor[3])
			else
				place_selected(get_turf(object), c.mob)
		if(BM_TOOL_COPY)
			// After taking a copy, the next left click places it instead of copying again.
			if(copy_object(object))
				active_tool = BM_TOOL_PLACE
				item_browser?.send_selection()
		if(BM_TOOL_PICK)
			if(isturf(object) || isobj(object) || ismob(object))
				select_item(object.type)
		if(BM_TOOL_DELETE)
			delete_object(c.mob, object)
		// BM_TOOL_AREA and BM_TOOL_ERASE work through the drag handlers.

/// Which area drag a button press starts: "paint", "erase" or null.
/datum/buildmode/proc/area_drag_kind(list/modifiers)
	if(!istype(mode, /datum/buildmode_mode/basic))
		return null
	if(LAZYACCESS(modifiers, MIDDLE_CLICK))
		return LAZYACCESS(modifiers, CTRL_CLICKED) ? "erase" : "paint"
	if(!LAZYACCESS(modifiers, LEFT_CLICK))
		return null
	if(LAZYACCESS(modifiers, CTRL_CLICKED) || LAZYACCESS(modifiers, ALT_CLICKED) || LAZYACCESS(modifiers, SHIFT_CLICKED))
		return null
	if(active_tool == BM_TOOL_AREA)
		return "paint"
	if(active_tool == BM_TOOL_ERASE)
		return "erase"
	return null

/// The turf under a mouse event, or null for the HUD and anything off the map.
/proc/buildmode_event_turf(atom/object)
	if(!isatom(object) || istype(object, /atom/movable/screen))
		return null
	return get_turf(object)

/datum/buildmode/proc/on_client_mousedown(client/source, atom/object, location, control, params)
	SIGNAL_HANDLER
	var/list/modifiers = params2list(params)
	var/kind = area_drag_kind(modifiers)
	if(!kind)
		return
	var/turf/start = buildmode_event_turf(object)
	if(!start)
		return
	clear_area()
	area_start = start
	area_end = start
	area_erase = (kind == "erase")
	area_button = LAZYACCESS(modifiers, MIDDLE_CLICK) ? MIDDLE_CLICK : LEFT_CLICK
	draw_area()

/datum/buildmode/proc/on_client_mousedrag(client/source, src_object, atom/over_object, src_location, over_location, src_control, over_control, params)
	SIGNAL_HANDLER
	if(!area_start)
		return
	var/turf/over = buildmode_event_turf(over_object)
	if(!over || over == area_end || over.z != area_start.z)
		return
	area_end = over
	draw_area()

/datum/buildmode/proc/on_client_mouseup(client/source, atom/object, location, control, params)
	SIGNAL_HANDLER
	if(!area_start)
		return
	var/list/modifiers = params2list(params)
	if(!LAZYACCESS(modifiers, area_button))
		return
	var/turf/released = buildmode_event_turf(object)
	if(released && released.z == area_start.z)
		area_end = released
	var/turf/corner_a = area_start
	var/turf/corner_b = area_end
	var/erase = area_erase
	clear_area()
	INVOKE_ASYNC(src, PROC_REF(apply_area), corner_a, corner_b, erase)

/// Outlines the dragged rectangle. Only the border is drawn, so big rectangles stay cheap.
/datum/buildmode/proc/draw_area()
	if(holder && length(area_images))
		holder.images -= area_images
	area_images = list()
	if(!holder || !area_start || !area_end)
		return
	var/min_x = min(area_start.x, area_end.x)
	var/max_x = max(area_start.x, area_end.x)
	var/min_y = min(area_start.y, area_end.y)
	var/max_y = max(area_start.y, area_end.y)
	var/overlay_state = area_erase ? "redOverlay" : "greenOverlay"
	for(var/x in min_x to max_x)
		for(var/y in min_y to max_y)
			if(x != min_x && x != max_x && y != min_y && y != max_y)
				continue
			var/turf/border = locate(x, y, area_start.z)
			if(!border)
				continue
			var/image/outline = image('icons/turf/overlays.dmi', border, overlay_state)
			outline.plane = ABOVE_LIGHTING_PLANE
			outline.alpha = 170
			area_images += outline
	holder.images += area_images
	var/width = max_x - min_x + 1
	var/height = max_y - min_y + 1
	item_browser?.set_status("[area_erase ? "Erase" : "Paint"] area: [width] x [height] ([width * height] tiles). Release to apply.")

/datum/buildmode/proc/clear_area()
	if(holder && length(area_images))
		holder.images -= area_images
	area_images = null
	area_start = null
	area_end = null
	area_button = null

/// Paints the rectangle with the selection, or erases the objects in it. Turfs are never erased.
/datum/buildmode/proc/apply_area(turf/corner_a, turf/corner_b, erase)
	if(QDELETED(src) || !holder || !check_rights_for(holder, R_BUILD) || !corner_a || !corner_b)
		return
	if(!erase && !selected_item)
		item_browser?.set_status("Pick something in the catalogue before painting an area.")
		return
	var/list/region = block(corner_a, corner_b)
	var/tiles = length(region)
	if(tiles > BM_AREA_MAX_TILES)
		item_browser?.set_status("That area has [tiles] tiles; the limit is [BM_AREA_MAX_TILES]. Use a smaller rectangle.")
		return
	if(tiles > BM_AREA_CONFIRM_TILES)
		var/answer = tgui_alert(holder.mob, "[erase ? "Erase objects on" : "Paint"] [tiles] tiles?", "Build Mode", list("Yes", "No"))
		if(answer != "Yes" || QDELETED(src) || !holder)
			return
	var/user_key = key_name(holder)
	if(erase)
		var/removed = 0
		begin_undo("erase [tiles] tiles")
		for(var/turf/target as anything in region)
			for(var/atom/movable/thing as anything in target)
				if(!buildmode_can_erase(thing))
					continue
				undoable_delete(thing)
				removed++
		end_undo()
		log_admin("Build Mode: [user_key] erased [removed] objects from [AREACOORD(corner_a)] through [AREACOORD(corner_b)].")
		item_browser?.set_status("Erased [removed] objects on [tiles] tiles.")
		return
	var/painting = selected_item
	var/atom/movable/template = copy_template()
	var/created = 0
	begin_undo("paint [tiles] tiles")
	for(var/turf/target as anything in region)
		if(QDELETED(src))
			break
		if(ispath(painting, /turf))
			undo_note_turf(target)
			var/turf/replacement = target.ChangeTurf(painting)
			if(replacement)
				replacement.flags_1 |= ADMIN_SPAWNED_1
				created++
			continue
		var/atom/movable/built = spawn_one(target, template)
		if(built)
			undo_note_created(built)
			created++
	if(!QDELETED(src))
		end_undo()
	log_admin("Build Mode: [user_key] painted [created] of [painting][template ? " (copy)" : ""] from [AREACOORD(corner_a)] through [AREACOORD(corner_b)].")
	if(!QDELETED(src))
		item_browser?.set_status("Painted [created] tiles.")

/// What an area erase may delete: objects and mindless mobs, never players or map machinery.
/proc/buildmode_can_erase(atom/movable/thing)
	if(QDELETED(thing) || thing.invisibility >= INVISIBILITY_ABSTRACT)
		return FALSE
	if(ismob(thing))
		var/mob/target_mob = thing
		return !target_mob.ckey && !target_mob.client
	if(!isobj(thing))
		return FALSE
	if(istype(thing, /obj/effect/landmark) || istype(thing, /obj/effect/mapping_helpers))
		return FALSE
	return TRUE

/**
 * Exact copy of original on newloc, for the Copy tool.
 *
 * Unlike DuplicateObject() this never copies internal bookkeeping (signals, components, timers,
 * traits, references to other datums) and never stops on a read-only variable: a failed
 * assignment is skipped, so a copy always gets placed.
 */
/proc/buildmode_duplicate(atom/movable/original, turf/newloc)
	var/atom/movable/copy = new original.type(newloc)
	if(QDELETED(copy))
		return null
	var/static/list/skipped = list(
		"type", "parent_type", "vars", "verbs", "tag", "loc", "locs", "x", "y", "z", "contents",
		"vis_locs", "vis_contents", "overlays", "underlays", "appearance", "managed_overlays",
		"managed_vis_overlays", "area", "ckey", "key", "client", "mind", "reagents",
		"datum_flags", "gc_destroyed", "weak_reference", "cooldowns", "active_timers",
		"important_recursive_contents", "pulledby", "pulling", "buckled_mobs", "orbiters",
		"light", "light_sources", "stat", "screen_loc", "plane", "flags_1", "atom_storage",
		"spatial_grid_key", "group", "power_supply", "atmos_adjacent_turfs", "comp_lookup",
	)
	for(var/var_name in original.vars)
		if(var_name in skipped)
			continue
		if(copytext(var_name, 1, 2) == "_") // internal lists: signals, components, traits...
			continue
		var/value = original.vars[var_name]
		if(isdatum(value))
			continue // the copy would share, then break, the original's datum
		if(islist(value))
			var/list/value_list = value
			value = value_list.Copy()
		try
			copy.vars[var_name] = value
		catch
			continue
	copy.update_appearance()
	return copy
