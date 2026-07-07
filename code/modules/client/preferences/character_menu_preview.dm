/// TGUI character setup menu — doll preview engine.
/// Three embedded map views (main/front/side) rendering a prefs-dressed dummy,
/// measured via flat icon art bounds so the frontend can zoom to fit.

/datum/preferences/proc/character_setup_selectable_ages()
	. = list()
	if(!pref_species)
		return
	for(var/possible_age in pref_species.possible_ages)
		. += possible_age

/datum/preferences/proc/character_setup_validate_smallclothes()
	validate_customizer_entries()

/datum/preferences/proc/character_setup_preview_job()
	var/datum/job/result
	var/highest = 0
	for(var/job_type in job_preferences)
		if(job_preferences[job_type] > highest)
			highest = job_preferences[job_type]
			result = SSjob.GetJob(job_type)
	return result

/datum/preferences/proc/character_setup_ensure_view(mob/user, datum/tgui/ui)
	if(!ui || QDELETED(ui))
		return
	if(!character_setup_view)
		var/client/view_client = user?.client
		var/list/view_size = view_client?.view ? getviewsize(view_client.view) : null
		character_setup_view_tile_top = (islist(view_size) && length(view_size) >= 2) ? view_size[2] : 15
		character_setup_view_tile_center = max(1, round((character_setup_view_tile_top + 1) / 2))
		character_setup_view_scale = max(1, character_setup_view_tile_top - 2)
		character_setup_view = new
		character_setup_view.generate_view("character_setup_main_[REF(src)]_map")
		character_setup_view_front = new
		character_setup_view_front.generate_view("character_setup_front_[REF(src)]_map")
		character_setup_view_side = new
		character_setup_view_side.generate_view("character_setup_side_[REF(src)]_map")
		character_setup_bg = new
		character_setup_bg.assigned_map = character_setup_view.assigned_map
		character_setup_bg_front = new
		character_setup_bg_front.assigned_map = character_setup_view_front.assigned_map
		character_setup_bg_side = new
		character_setup_bg_side.assigned_map = character_setup_view_side.assigned_map
		if(!character_setup_body)
			character_setup_body = new
		character_setup_log("VIEW", "ensure_view created map=[character_setup_view.assigned_map] user=[user?.ckey] window=[ui?.window ? "yes" : "NO"] window_visible=[ui?.window?.visible] tile_top=[character_setup_view_tile_top]")
		character_setup_update_view()
	if(character_setup_view_shown)
		return
	var/client/target_client = user?.client
	if(!target_client || QDELETED(ui) || !ui.window)
		return
	if(!ui.window.visible)
		character_setup_log("VIEW", "await window visible, retry queued")
		addtimer(CALLBACK(src, PROC_REF(character_setup_ensure_view), user, ui), 5, TIMER_UNIQUE)
		return
	character_setup_view_shown = TRUE
	character_setup_view.display_to_client(target_client)
	character_setup_view_front.display_to_client(target_client)
	character_setup_view_side.display_to_client(target_client)
	target_client.register_map_obj(character_setup_bg)
	target_client.register_map_obj(character_setup_bg_front)
	target_client.register_map_obj(character_setup_bg_side)
	character_setup_log("VIEW", "displayed maps=[character_setup_view.assigned_map],[character_setup_view_front.assigned_map],[character_setup_view_side.assigned_map] window=[ui.window.id] tile_center=[character_setup_view_tile_center] scale=[character_setup_view_scale]")
	character_setup_diag_controls(user, "post_display")

/datum/preferences/proc/character_setup_diag_controls(mob/user, context)
	set waitfor = FALSE
	if(!GLOB.character_setup_debug || !user?.client)
		return
	sleep(1 SECONDS)
	if(!user?.client)
		return
	var/client/C = user.client
	var/window_id = character_setup_active_window_id(user)
	character_setup_log("CTRL", "[context] === geometry dump === window_id=[window_id] view=[C.view] tile_center=[character_setup_view_tile_center] feet_margin=[character_setup_view_feet_margin] last_flat=[character_setup_view_last_flat]")
	if(window_id)
		character_setup_log("CTRL", "[context] WINDOW [window_id] winget=[winget(user, window_id, "size;pos;is-visible;is-maximized;inner-size")]")
		character_setup_log("CTRL", "[context] WINDOW.map winget=[winget(user, "[window_id].map", "size;pos;is-visible")]")
	for(var/atom/movable/screen/map_view/view as anything in list(character_setup_view, character_setup_view_front, character_setup_view_side))
		if(!view)
			continue
		var/list/bound = C.screen_maps[view.assigned_map]
		var/in_screen = (view in C.screen) ? "yes" : "NO"
		var/ctrl = winget(user, view.assigned_map, "parent;type;pos;size;view-size;icon-size;zoom;letterbox;zoom-mode;is-visible")
		character_setup_log("CTRL", "[context] MAP id=[view.assigned_map] screen_loc=[view.screen_loc] transform_scale=[character_setup_current_view_scale()] registered=[length(bound)] in_screen=[in_screen] winget=[ctrl ? ctrl : "MISSING"]")

/datum/preferences/proc/character_setup_apply_map_background(mob/user)
	if(!user?.client)
		return
	var/bg_hex = "#0d0d0d"
	switch(character_setup_preview_background)
		if("white")
			bg_hex = "#d8d8d8"
		if("dark")
			bg_hex = "#0a0a0a"
	for(var/atom/movable/screen/map_view/view as anything in list(character_setup_view, character_setup_view_front, character_setup_view_side))
		if(view)
			winset(user, view.assigned_map, "background-color=[bg_hex]")

/datum/preferences/proc/character_setup_apply_reported_zoom(mob/user, zoom_main, zoom_mini)
	if(!user?.client)
		return
	if(zoom_main > 0 && character_setup_view)
		winset(user, character_setup_view.assigned_map, "zoom=[zoom_main]")
	if(zoom_mini > 0)
		if(character_setup_view_front)
			winset(user, character_setup_view_front.assigned_map, "zoom=[zoom_mini]")
		if(character_setup_view_side)
			winset(user, character_setup_view_side.assigned_map, "zoom=[zoom_mini]")
	character_setup_apply_map_background(user)
	if(GLOB.character_setup_debug)
		character_setup_log("ZOOM", "applied main=[zoom_main] mini=[zoom_mini]")

/datum/preferences/proc/character_setup_active_window_id(mob/user)
	for(var/datum/tgui/open_ui in open_uis)
		if(open_ui.user == user && open_ui.window)
			return open_ui.window.id
	return null

/datum/preferences/proc/character_setup_teardown_view(mob/user)
	character_setup_log("VIEW", "teardown map=[character_setup_view?.assigned_map] user=[user?.ckey]")
	character_setup_hover_acc = null
	character_setup_hover_color = null
	character_setup_hover_customizer = null
	character_setup_view_shown = FALSE
	character_setup_view?.hide_from(user)
	character_setup_view_front?.hide_from(user)
	character_setup_view_side?.hide_from(user)
	QDEL_NULL(character_setup_body)
	QDEL_NULL(character_setup_view)
	QDEL_NULL(character_setup_view_front)
	QDEL_NULL(character_setup_view_side)
	QDEL_NULL(character_setup_bg)
	QDEL_NULL(character_setup_bg_front)
	QDEL_NULL(character_setup_bg_side)

/datum/preferences/proc/character_setup_update_view()
	set waitfor = FALSE
	if(!character_setup_view || !character_setup_body || !pref_species)
		character_setup_log("VIEW", "update_view SKIP view=[!!character_setup_view] body=[!!character_setup_body] species=[!!pref_species]")
		return
	if(character_setup_view_busy)
		character_setup_view_pending = TRUE
		character_setup_log("VIEW", "update_view BUSY -> pending")
		return
	character_setup_view_busy = TRUE
	do
		character_setup_view_pending = FALSE
		var/_t = world.timeofday
		character_setup_render_body()
		character_setup_log_op("render_body", _t, "dir=[character_setup_preview_dir] hover=[character_setup_hover_acc || "none"] species=[pref_species?.id]")
	while(character_setup_view_pending)
	character_setup_view_busy = FALSE
	var/bbox_sig = "[character_setup_view_zoom_w]x[character_setup_view_zoom_h]"
	if(bbox_sig != character_setup_view_bbox_sent)
		character_setup_view_bbox_sent = bbox_sig
		SStgui.update_uis(src)

/datum/preferences/proc/character_setup_render_body()
	var/mob/living/carbon/human/dummy/body = character_setup_body
	var/datum/job/preview_job = character_setup_preview_clothes ? character_setup_preview_job() : null
	var/datum/outfit/preview_outfit
	if(preview_job)
		preview_outfit = (gender == FEMALE && preview_job.outfit_female) ? preview_job.outfit_female : preview_job.outfit
	character_setup_validate_smallclothes()
	var/datum/customizer_entry/hover_entry
	var/hover_old_acc
	var/hover_old_colors
	var/hover_old_disabled
	var/hover_acc_path = character_setup_hover_acc ? text2path(character_setup_hover_acc) : null
	var/hover_customizer_path = character_setup_hover_customizer ? text2path(character_setup_hover_customizer) : null
	if(hover_acc_path && hover_customizer_path)
		hover_entry = get_customizer_entry_for_customizer_type(hover_customizer_path)
		if(hover_entry)
			hover_old_acc = hover_entry.accessory_type
			hover_old_colors = hover_entry.accessory_colors
			hover_old_disabled = hover_entry.disabled
			hover_entry.accessory_type = hover_acc_path
			if(character_setup_hover_color)
				hover_entry.accessory_colors = character_setup_hover_color
			hover_entry.disabled = FALSE
	body.wipe_state()
	// character_setup = TRUE: culls stale taur bodies (ensure_not_taur) and skips
	// roundstart-only side effects (quirks, bans, kinks) on the preview dummy.
	apply_prefs_to(body, TRUE, TRUE)
	if(hover_entry)
		hover_entry.accessory_type = hover_old_acc
		hover_entry.accessory_colors = hover_old_colors
		hover_entry.disabled = hover_old_disabled
	if(!character_setup_preview_underwear)
		// Smallclothes are worn items living in inventory slots here, not strings.
		QDEL_NULL(body.underwear)
		QDEL_NULL(body.undershirt)
		QDEL_NULL(body.bra)
		QDEL_NULL(body.garter)
		QDEL_NULL(body.legwear_socks)
		QDEL_NULL(body.armsleeves)
		body.update_body_parts()
	if(preview_job)
		body.dna.species.pre_equip_species_outfit(preview_job, body, TRUE)
	if(preview_outfit)
		body.equipOutfit(preview_outfit, TRUE)
	body.update_inv_hands()
	body.update_inv_belt(hide_experimental = TRUE)
	body.update_inv_back(hide_experimental = TRUE)
	body.update_inv_head(hide_nonstandard = TRUE)
	var/main_only = character_setup_render_main_only
	character_setup_render_main_only = FALSE
	character_setup_measure_body(character_setup_preview_dir)
	if(!main_only)
		var/list/perp_art = character_setup_measure_art(turn(character_setup_preview_dir, 90))
		var/zoom_dim_w = max(character_setup_view_bbox_w, perp_art ? perp_art[1] : 0)
		var/zoom_dim_h = max(character_setup_view_bbox_h, perp_art ? perp_art[2] : 0)
		character_setup_view_zoom_w = CEILING(zoom_dim_w, 4)
		character_setup_view_zoom_h = CEILING(zoom_dim_h, 4)
	character_setup_apply_to_view(character_setup_view, body, character_setup_preview_dir)
	if(!main_only)
		character_setup_apply_to_view(character_setup_view_front, body, SOUTH)
		character_setup_apply_to_view(character_setup_view_side, body, EAST)
	character_setup_log("VIEW", "render done main_only=[main_only] dir=[character_setup_preview_dir] flat=[character_setup_view_last_flat] feet_margin=[character_setup_view_feet_margin] underwear=[body.underwear]")

/datum/preferences/proc/character_setup_measure_art(dir)
	var/mob/living/carbon/human/dummy/body = character_setup_body
	if(!body)
		return null
	var/icon/measure = character_setup_get_flat_icon(body, dir, no_anim = TRUE)
	var/measure_w = isicon(measure) ? measure.Width() : 32
	var/measure_h = isicon(measure) ? measure.Height() : 32
	var/art_x = 0
	var/art_y = 0
	var/list/art = character_setup_art_bounds(measure)
	if(art)
		art_x = art[1] - 1
		art_y = art[2] - 1
		measure_w = art[3] - art[1] + 1
		measure_h = art[4] - art[2] + 1
	return list(measure_w, measure_h, GLOB.character_setup_flat_origin_x + art_x, GLOB.character_setup_flat_origin_y + art_y)

/datum/preferences/proc/character_setup_measure_body(dir)
	var/list/art = character_setup_measure_art(dir)
	if(!art)
		return
	character_setup_view_bbox_w = art[1]
	character_setup_view_bbox_h = art[2]
	character_setup_view_off_x = art[3]
	character_setup_view_off_y = art[4]
	character_setup_view_extent_w = max(1, CEILING(character_setup_view_bbox_w / 32, 1))
	character_setup_view_extent_h = max(1, CEILING(character_setup_view_bbox_h / 32, 1))
	character_setup_bg?.fill_rect(1, 1, character_setup_view_canvas_w, character_setup_view_canvas_h)
	character_setup_bg_front?.fill_rect(1, 1, character_setup_view_canvas_w, character_setup_view_canvas_h)
	character_setup_bg_side?.fill_rect(1, 1, character_setup_view_canvas_w, character_setup_view_canvas_h)
	if(GLOB.character_setup_debug)
		character_setup_log("VIEW", "measure dir=[dir] art=[character_setup_view_bbox_w]x[character_setup_view_bbox_h] origin=[character_setup_view_off_x],[character_setup_view_off_y] extent=[character_setup_view_extent_w]x[character_setup_view_extent_h] zoom_dims=[character_setup_view_zoom_w]x[character_setup_view_zoom_h] species=[pref_species?.id] taur=[pref_species?.forced_taur ? 1 : 0]")

/proc/character_setup_get_flat_icon(image/appearance, defdir, deficon, defstate, defblend, start = TRUE, no_anim = FALSE)
	#define CHARACTER_SETUP_PROCESS_OVERLAYS_OR_UNDERLAYS(flat, process, base_layer) \
		for (var/i in 1 to length(process)) { \
			var/image/current = process[i]; \
			if (!current) { \
				continue; \
			} \
			if (current.plane != FLOAT_PLANE && current.plane != appearance.plane) { \
				continue; \
			} \
			var/current_layer = current.layer; \
			if (current_layer < 0) { \
				if (current_layer <= -1000) { \
					return flat; \
				} \
				current_layer = base_layer + appearance.layer + current_layer / 1000; \
			} \
			for (var/index_to_compare_to in 1 to length(layers)) { \
				var/compare_to = layers[index_to_compare_to]; \
				if (current_layer < layers[compare_to]) { \
					layers.Insert(index_to_compare_to, current); \
					break; \
				} \
			} \
			layers[current] = current_layer; \
		}

	var/static/icon/flat_template = icon('icons/blanks/32x32.dmi', "nothing")
	var/icon/flat = icon(flat_template)

	if(!appearance || appearance.alpha <= 0)
		return flat

	if(start)
		GLOB.character_setup_flat_origin_x = 0
		GLOB.character_setup_flat_origin_y = 0
		if(!defdir)
			defdir = appearance.dir
		if(!deficon)
			deficon = appearance.icon
		if(!defstate)
			defstate = appearance.icon_state
		if(!defblend)
			defblend = appearance.blend_mode

	var/curicon = appearance.icon || deficon
	var/curstate = appearance.icon_state || defstate
	var/curdir = (!appearance.dir || appearance.dir == SOUTH) ? defdir : appearance.dir

	var/render_icon = curicon

	if(render_icon)
		if(!icon_exists(curicon, curstate))
			if(icon_exists(curicon, ""))
				curstate = ""
			else
				render_icon = FALSE

	var/base_icon_dir

	if(render_icon)
		if (curdir != SOUTH)
			if(!length(icon_states(icon(curicon, curstate, NORTH))))
				base_icon_dir = SOUTH

		var/list/icon_dimensions = get_icon_dimensions(curicon)
		var/icon_width = icon_dimensions["width"]
		var/icon_height = icon_dimensions["height"]
		if(icon_width != 32 || icon_height != 32)
			flat.Scale(icon_width, icon_height)

	if(!base_icon_dir)
		base_icon_dir = curdir

	var/curblend = appearance.blend_mode || defblend

	if(length(appearance.overlays) || length(appearance.underlays))
		var/list/layers = list()
		var/image/copy
		if(render_icon)
			copy = image(icon=curicon, icon_state=curstate, layer=appearance.layer, dir=base_icon_dir)
			copy.color = appearance.color
			copy.alpha = appearance.alpha
			copy.blend_mode = curblend
			layers[copy] = appearance.layer

		CHARACTER_SETUP_PROCESS_OVERLAYS_OR_UNDERLAYS(flat, appearance.underlays, 0)
		CHARACTER_SETUP_PROCESS_OVERLAYS_OR_UNDERLAYS(flat, appearance.overlays, 1)

		var/icon/add

		var/flatX1 = 1
		var/flatX2 = flat.Width()
		var/flatY1 = 1
		var/flatY2 = flat.Height()

		var/addX1 = 0
		var/addX2 = 0
		var/addY1 = 0
		var/addY2 = 0

		for(var/image/layer_image as anything in layers)
			if(layer_image.alpha == 0)
				continue

			if(layer_image == copy)
				curblend = BLEND_OVERLAY
				add = icon(layer_image.icon, layer_image.icon_state, base_icon_dir)
			else
				add = character_setup_get_flat_icon(image(layer_image), curdir, curicon, curstate, curblend, FALSE, no_anim)
			if(!add)
				continue

			addX1 = min(flatX1, layer_image.pixel_x + 1)
			addX2 = max(flatX2, layer_image.pixel_x + add.Width())
			addY1 = min(flatY1, layer_image.pixel_y + 1)
			addY2 = max(flatY2, layer_image.pixel_y + add.Height())

			if (
				addX1 != flatX1 \
				|| addX2 != flatX2 \
				|| addY1 != flatY1 \
				|| addY2 != flatY2 \
			)
				flat.Crop(
					addX1 - flatX1 + 1,
					addY1 - flatY1 + 1,
					addX2 - flatX1 + 1,
					addY2 - flatY1 + 1
				)

				flatX1 = addX1
				flatX2 = addX2
				flatY1 = addY1
				flatY2 = addY2

			flat.Blend(add, blendMode2iconMode(curblend), layer_image.pixel_x + 2 - flatX1, layer_image.pixel_y + 2 - flatY1)

		if(appearance.color)
			if(islist(appearance.color))
				flat.MapColors(arglist(appearance.color))
			else
				flat.Blend(appearance.color, ICON_MULTIPLY)

		if(appearance.alpha < 255)
			flat.Blend(rgb(255, 255, 255, appearance.alpha), ICON_MULTIPLY)

		if(start)
			GLOB.character_setup_flat_origin_x = flatX1 - 1
			GLOB.character_setup_flat_origin_y = flatY1 - 1

		if(no_anim)
			var/icon/cleaned = new /icon()
			cleaned.Insert(flat, "", SOUTH, 1, 0)
			return cleaned
		else
			return icon(flat, "", SOUTH)
	else if (render_icon)
		var/icon/final_icon = icon(icon(curicon, curstate, base_icon_dir), "", SOUTH, no_anim ? TRUE : null)

		if (appearance.alpha < 255)
			final_icon.Blend(rgb(255,255,255, appearance.alpha), ICON_MULTIPLY)

		if (appearance.color)
			if (islist(appearance.color))
				final_icon.MapColors(arglist(appearance.color))
			else
				final_icon.Blend(appearance.color, ICON_MULTIPLY)

		return final_icon

	#undef CHARACTER_SETUP_PROCESS_OVERLAYS_OR_UNDERLAYS

/datum/preferences/proc/character_setup_apply_to_view(atom/movable/screen/map_view/view, mob/living/carbon/human/dummy/body, view_dir)
	if(!view)
		return
	view.appearance = body.appearance
	view.setDir(view_dir)
	view.plane = GAME_PLANE
	view.layer = GAME_PLANE
	view.pixel_x = 0
	view.pixel_y = 0
	view.pixel_z = 0
	view.pixel_w = 0
	view.maptext = null
	view.appearance_flags = KEEP_TOGETHER | PIXEL_SCALE
	view.transform = null
	var/anchor_px = round(character_setup_view_canvas_cx - character_setup_view_bbox_w / 2) - character_setup_view_off_x + character_setup_view_doll_px
	var/anchor_py = round(character_setup_view_canvas_cy - character_setup_view_bbox_h / 2) - character_setup_view_off_y + character_setup_view_doll_py
	view.set_position(character_setup_view_doll_x, character_setup_view_doll_y, anchor_px, anchor_py)
	if(GLOB.character_setup_debug)
		character_setup_log("VIEW", "apply map=[view.assigned_map] dir=[view_dir] bbox=[character_setup_view_bbox_w]x[character_setup_view_bbox_h] extent=[character_setup_view_extent_w]x[character_setup_view_extent_h] screen_loc=[view.screen_loc] base_icon=[body.icon] overlays=[length(view.overlays)] appearance_flags=[view.appearance_flags] view_dir=[view.dir]")
	character_setup_view_last_flat = "appearance dir=[view_dir] bbox=[character_setup_view_bbox_w]x[character_setup_view_bbox_h] extent=[character_setup_view_extent_w]x[character_setup_view_extent_h] overlays=[length(view.overlays)] view_dir=[view.dir]"

/datum/preferences/proc/character_setup_current_view_scale()
	if(pref_species?.forced_taur && LAZYLEN(pref_species.allowed_taur_types))
		return max(1, round(character_setup_view_scale * 0.55))
	return character_setup_view_scale
