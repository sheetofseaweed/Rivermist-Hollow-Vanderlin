/obj/item/canvas
	item_weight = 95 GRAMS
	name = "canvas"
	desc = "A perfect place to capture Faerun through art." // RMH

	icon = 'icons/paint_supplies/canvas_32.dmi'
	icon_state = "canvas"

	var/easel_offset = 9
	var/canvas_size_x = 32
	var/canvas_size_y = 32

	var/atom/movable/screen/canvas/used_canvas
	var/list/showers = list()

	var/icon/draw
	var/icon/base

	var/title
	var/author
	var/author_ckey
	var/canvas_size = "32x32"
	/// archive filename stem, assigned on first upload
	var/painting_id

	var/canvas_icon = 'icons/paint_supplies/canvas/canvas_32x32.dmi'
	var/canvas_icon_state = "canvas"
	var/canvas_screen_loc = "6,6"
	var/canvas_divider_x = 5
	var/canvas_divider_y = 5

	/// painted cell colours keyed "x,y", the authoritative picture data
	var/list/modified_areas = list()
	var/list/overlay_to_index = list()
	var/current_overlays = 0

/obj/item/canvas/Initialize()
	. = ..()
	draw = icon(icon, icon_state)
	base = icon(icon, icon_state)
	underlays += base
	icon = draw
	used_canvas = new
	used_canvas.setup(src)
	RegisterSignal(src, COMSIG_MOVABLE_TURF_ENTERED, PROC_REF(remove_showers))

/obj/item/canvas/Destroy()
	remove_showers()
	QDEL_NULL(used_canvas)
	return ..()

/obj/item/canvas/pickup(mob/user)
	. = ..()
	remove_showers()

/obj/item/canvas/get_mechanics_examine(mob/user)
	. = ..()
	. += span_info("Hit it with a brush, or right-click it barehanded, to open the painting surface.")
	. += span_info("Left-click the surface to toggle drawing, then move the mouse across it.")
	. += span_info("Right-click toggles erasing, alt+left-click toggles shading, ctrl+left-click picks a colour.")
	. += span_info("Sign it with a feather, then feed it to a printing press to archive it.")

/obj/item/canvas/examine(mob/user)
	. = ..()
	if(author)
		. += span_notice("Signed by [author].")
	if(painting_id)
		. += span_notice("It bears an archivist's mark.")

/obj/item/canvas/attack_hand(mob/user)
	. = ..()
	if(user.cmode)
		return
	if(!anchored)
		return
	to_chat(user, "I start unmounting [src]...")
	if(!do_after(user, 3 SECONDS, src))
		return
	anchored = FALSE
	to_chat(user, "I unmount [src].")
	user.put_in_hands(src)

/obj/item/canvas/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return
	if(user.get_active_held_item())
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	add_shower(user)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/item/canvas/attackby(obj/item/I, mob/living/user, list/modifiers)
	. = ..()
	if(istype(I, /obj/item/natural/feather))
		sign_painting(user)
		return

	if(!istype(I, /obj/item/paint_brush))
		return
	add_shower(user)

/obj/item/canvas/proc/sign_painting(mob/living/user)
	var/new_author = browser_input_text(user, "Who's the author of this painting?", "NAME YOURSELF", max_length = MAX_NAME_LEN)
	var/new_title = browser_input_text(user, "What's the title of this painting?", "NAME YOUR MASTERPIECE", max_length = MAX_CHARTER_LEN)
	if(!new_author && !new_title)
		return
	if(new_author)
		author = new_author
		author_ckey = user.ckey
		desc = "Painted by: [author]."
	if(new_title)
		title = new_title
		name = title
	SEND_SIGNAL(user, COMSIG_ART_CREATED)

/obj/item/canvas/attack_atom(atom/attacked_atom, mob/living/user)
	if(!isclosedturf(attacked_atom))
		return ..()

	. = TRUE
	to_chat(user, "I start mounting [src] to [attacked_atom]...")
	if(!do_after(user, 3 SECONDS, attacked_atom))
		return
	user.dropItemToGround(src)
	forceMove(attacked_atom)
	pixel_x = base_pixel_x
	pixel_y = base_pixel_y
	anchored = TRUE

/obj/item/canvas/proc/add_shower(mob/user)
	if(!user?.client)
		return
	if(user in showers)
		return
	user.client.screen += used_canvas
	showers |= user
	RegisterSignal(user, list(COMSIG_MOVABLE_TURF_ENTERED, COMSIG_PARENT_QDELETING), PROC_REF(remove_shower))

/obj/item/canvas/proc/remove_showers()
	SIGNAL_HANDLER
	for(var/mob/mob as anything in showers.Copy())
		remove_shower(mob)

/obj/item/canvas/proc/remove_shower(mob/source)
	SIGNAL_HANDLER
	showers -= source
	source.client?.screen -= used_canvas
	UnregisterSignal(source, list(COMSIG_MOVABLE_TURF_ENTERED, COMSIG_PARENT_QDELETING))
	used_canvas?.painter_states -= source

/obj/item/canvas/proc/update_drawing(x, y, current_color)
	var/key = "[x],[y]"
	var/mutable_appearance/old = overlay_to_index[key]
	if(old)
		cut_overlay(old)
	var/mutable_appearance/MA = mutable_appearance('icons/paint_supplies/pixel.dmi', "pixel")
	MA.color = current_color
	MA.pixel_x = x
	MA.pixel_y = y
	add_overlay(MA)
	overlay_to_index[key] = MA
	if(!old)
		current_overlays++
	if(current_overlays > 150)
		flatten()

/// caller is responsible for reassigning icon after a batch of erases
/obj/item/canvas/proc/erase_cell(x, y, was_painted)
	var/key = "[x],[y]"
	var/mutable_appearance/MA = overlay_to_index[key]
	if(MA)
		cut_overlay(MA)
		overlay_to_index -= key
		current_overlays = max(current_overlays - 1, 0)
	if(was_painted)
		draw.DrawBox(null, x + 1, y + 1)

/// bakes pending pixel overlays into the item's own icon, server-side
/obj/item/canvas/proc/flatten()
	for(var/key in overlay_to_index)
		var/cell_color = modified_areas[key]
		if(!cell_color)
			continue
		var/list/coords = splittext(key, ",")
		draw.DrawBox(cell_color, text2num(coords[1]) + 1, text2num(coords[2]) + 1)
	icon = draw
	cut_overlays()
	overlay_to_index = list()
	current_overlays = 0

/obj/item/canvas/proc/upload_painting(mob/user)
	if(!author || !title)
		return "This canvas isn't signed."
	flatten()
	used_canvas?.flatten()
	if(!painting_id)
		painting_id = SSpaintings.generate_painting_id(author_ckey)
	return SSpaintings.save_painting(src, user)

/// restores an archived painting onto this canvas, both the item and its surface
/obj/item/canvas/proc/load_painting(loaded_id)
	var/list/metadata = SSpaintings.paintings[loaded_id]
	if(!length(metadata))
		return FALSE
	var/image_path = SSpaintings.get_painting_filename(loaded_id)
	if(!fexists(image_path))
		return FALSE

	cut_overlays()
	overlay_to_index = list()
	modified_areas = list()
	current_overlays = 0

	draw = icon(image_path)
	icon = draw

	var/icon/surface = icon(image_path)
	surface.Scale(canvas_size_x * canvas_divider_x, canvas_size_y * canvas_divider_y)
	if(used_canvas)
		used_canvas.cut_overlays()
		used_canvas.overlay_to_index = list()
		used_canvas.current_overlays = 0
		used_canvas.draw = surface
		used_canvas.icon = surface

	painting_id = loaded_id
	title = metadata["painting_title"]
	author = metadata["author"]
	author_ckey = metadata["author_ckey"]
	if(title)
		name = title
	if(author)
		desc = "Painted by: [author]."
	return TRUE

/atom/movable/screen/canvas
	icon = 'icons/paint_supplies/canvas/canvas_32x32.dmi'
	icon_state = "canvas"
	screen_loc = "6,6"
	mouse_drag_pointer = MOUSE_INACTIVE_POINTER

	var/obj/item/canvas/host
	var/icon/draw
	var/icon/base

	var/list/overlay_to_index = list()
	var/current_overlays = 0

	/// per-painter drag/erase/shade state, keyed by mob
	var/list/painter_states = list()
	/// cells one continuous stroke may lay down before the brush lifts
	var/max_ink = 50

/atom/movable/screen/canvas/Destroy()
	host = null
	painter_states.Cut()
	return ..()

/atom/movable/screen/canvas/proc/setup(obj/item/canvas/new_host)
	host = new_host
	icon = new_host.canvas_icon
	icon_state = new_host.canvas_icon_state
	screen_loc = new_host.canvas_screen_loc
	draw = icon(icon, icon_state)
	base = icon(icon, icon_state)
	underlays += base
	icon = draw

/atom/movable/screen/canvas/proc/get_painter_state(mob/user)
	var/list/state = painter_states[user]
	if(!state)
		state = list("drawing" = FALSE, "erasing" = FALSE, "shading" = FALSE, "last_x" = null, "last_y" = null, "ink" = 0)
		painter_states[user] = state
	return state

/atom/movable/screen/canvas/proc/can_paint(mob/user)
	if(!user || QDELETED(host))
		return FALSE
	if(host.item_flags & IN_STORAGE)
		return FALSE
	if(host.loc == user)
		return TRUE
	if(!isturf(host.loc))
		return FALSE
	if(get_dist(user, host) > 2)
		return FALSE
	return TRUE

/atom/movable/screen/canvas/Click(location, control, params)
	. = ..()
	if(!can_paint(usr))
		return
	var/obj/item/paint_brush/brush = usr.get_active_held_item()
	if(!istype(brush))
		return

	var/list/modifiers = params2list(params)
	var/x = text2num(LAZYACCESS(modifiers, ICON_X))
	var/y = text2num(LAZYACCESS(modifiers, ICON_Y))
	if(isnull(x) || isnull(y))
		return

	x = clamp(FLOOR(x / host.canvas_divider_x, 1), 0, host.canvas_size_x - 1)
	y = clamp(FLOOR(y / host.canvas_divider_y, 1), 0, host.canvas_size_y - 1)

	var/is_right_click = LAZYACCESS(modifiers, RIGHT_CLICK)
	var/is_middle_click = LAZYACCESS(modifiers, MIDDLE_CLICK)
	var/is_alt = LAZYACCESS(modifiers, ALT_CLICKED)
	var/is_ctrl = LAZYACCESS(modifiers, CTRL_CLICKED)
	var/is_left_click = !is_right_click && !is_middle_click

	var/list/state = get_painter_state(usr)

	if(is_ctrl && is_left_click)
		var/picked_color = host.modified_areas["[x],[y]"]
		if(picked_color)
			brush.current_color = picked_color
			brush.update_appearance(UPDATE_OVERLAYS)
			to_chat(usr, span_notice("I pick the colour off the canvas."))
		else
			to_chat(usr, span_warning("There is no paint there to pick up."))
		state["last_x"] = x
		state["last_y"] = y
		return

	if(is_alt && is_left_click)
		state["shading"] = !state["shading"]
		if(state["shading"])
			state["drawing"] = FALSE
		else
			if(!brush.current_color)
				to_chat(usr, span_warning("I need to pick up a colour first!"))
				return
			state["drawing"] = TRUE
			state["erasing"] = FALSE
		to_chat(usr, span_notice("I am [state["shading"] ? "" : "no longer "]adjusting the shade of the painted portions."))
		state["last_x"] = x
		state["last_y"] = y
		return

	if(is_right_click)
		state["erasing"] = !state["erasing"]
		state["drawing"] = state["erasing"]
		to_chat(usr, span_notice("I am [state["erasing"] ? "" : "no longer "]erasing my work."))

	else if(is_left_click)
		if(!brush.current_color)
			to_chat(usr, span_warning("I need to pick up a colour first!"))
			return
		state["drawing"] = !state["drawing"]
		state["erasing"] = FALSE
		to_chat(usr, span_notice("I am [state["drawing"] ? "" : "no longer "]painting."))

	if(state["drawing"])
		state["ink"] = 0

	state["last_x"] = x
	state["last_y"] = y

/// paints or erases one brush stamp, returns TRUE if the baked icon needs reassigning
/atom/movable/screen/canvas/proc/draw_pixel(x, y, color, is_erasing, brush_size = 1, shading = FALSE, mob/user)
	. = FALSE
	var/list/state = painter_states[user]
	if(!state || !state["drawing"])
		return
	var/lo = round((brush_size - 1) / 2)
	var/hi = brush_size - 1 - lo
	for(var/px = x - lo to x + hi)
		for(var/py = y - lo to y + hi)
			if(px < 0 || px >= host.canvas_size_x || py < 0 || py >= host.canvas_size_y)
				continue

			var/key = "[px],[py]"

			if(is_erasing)
				var/was_painted = (key in host.modified_areas)
				host.modified_areas -= key
				var/mutable_appearance/erased = overlay_to_index[key]
				if(erased)
					cut_overlay(erased)
					overlay_to_index -= key
					current_overlays = max(current_overlays - 1, 0)
				if(was_painted)
					draw.DrawBox(null, px * host.canvas_divider_x + 1, py * host.canvas_divider_y + 1, (px + 1) * host.canvas_divider_x, (py + 1) * host.canvas_divider_y)
					. = TRUE
				host.erase_cell(px, py, was_painted)
				continue

			if(state["ink"] >= max_ink)
				state["drawing"] = FALSE
				state["last_x"] = null
				state["last_y"] = null
				return

			var/cell_color = color
			var/pre_merge = host.modified_areas[key]
			if(shading)
				if(!pre_merge)
					continue
				if(pre_merge != cell_color)
					cell_color = BlendRGB(cell_color, pre_merge, 0.5)
			// overlapping drag stamps mostly repaint identical cells, skip them
			if(pre_merge == cell_color)
				continue
			host.modified_areas[key] = cell_color

			var/mutable_appearance/old = overlay_to_index[key]
			if(old)
				cut_overlay(old)
			var/mutable_appearance/MA = mutable_appearance(host.canvas_icon, "pixel")
			MA.color = cell_color
			MA.pixel_x = px * host.canvas_divider_x
			MA.pixel_y = py * host.canvas_divider_y
			MA.layer = layer + 1
			MA.plane = plane
			add_overlay(MA)
			overlay_to_index[key] = MA
			if(!old)
				current_overlays++

			state["ink"]++
			host.update_drawing(px, py, cell_color)
			if(current_overlays > 150)
				flatten()

/atom/movable/screen/canvas/proc/flatten()
	if(!host)
		return
	for(var/key in overlay_to_index)
		var/cell_color = host.modified_areas[key]
		if(!cell_color)
			continue
		var/list/coords = splittext(key, ",")
		var/px = text2num(coords[1])
		var/py = text2num(coords[2])
		draw.DrawBox(cell_color, px * host.canvas_divider_x + 1, py * host.canvas_divider_y + 1, (px + 1) * host.canvas_divider_x, (py + 1) * host.canvas_divider_y)
	icon = draw
	cut_overlays()
	overlay_to_index = list()
	current_overlays = 0

/// bresenham, so a fast mouse drag leaves a solid line instead of scattered dots
/atom/movable/screen/canvas/proc/draw_line(start_x, start_y, end_x, end_y, color, is_erasing, brush_size = 1, mob/user)
	. = FALSE
	var/dx = abs(end_x - start_x)
	var/dy = abs(end_y - start_y)
	var/sx = start_x < end_x ? 1 : -1
	var/sy = start_y < end_y ? 1 : -1
	var/err = dx - dy

	var/cx = start_x
	var/cy = start_y
	var/list/state = painter_states[user]

	while(TRUE)
		if(!state || !state["drawing"])
			break
		if(draw_pixel(cx, cy, color, is_erasing, brush_size, FALSE, user))
			. = TRUE
		if(cx == end_x && cy == end_y)
			break
		var/e2 = err * 2
		if(e2 > -dy)
			err -= dy
			cx += sx
		if(e2 < dx)
			err += dx
			cy += sy

/atom/movable/screen/canvas/MouseMove(location, control, params)
	. = ..()
	handle_paint_move(usr, params)

/atom/movable/screen/canvas/MouseDrag(over_object, src_location, over_location, src_control, over_control, params)
	. = ..()
	if(over_object == src)
		handle_paint_move(usr, params)
	else
		reset_stroke(usr)

/atom/movable/screen/canvas/MouseExited(location, control, params)
	. = ..()
	reset_stroke(usr)

/atom/movable/screen/canvas/proc/reset_stroke(mob/user)
	var/list/state = painter_states[user]
	if(!state)
		return
	state["last_x"] = null
	state["last_y"] = null

/atom/movable/screen/canvas/proc/handle_paint_move(mob/user, params)
	if(world.cpu > 90)
		return
	if(!can_paint(user))
		return
	var/list/state = painter_states[user]
	if(!state || !state["drawing"])
		return

	var/list/modifiers = params2list(params)
	var/x = text2num(LAZYACCESS(modifiers, ICON_X))
	var/y = text2num(LAZYACCESS(modifiers, ICON_Y))
	if(isnull(x) || isnull(y))
		return

	x = clamp(FLOOR(x / host.canvas_divider_x, 1), 0, host.canvas_size_x - 1)
	y = clamp(FLOOR(y / host.canvas_divider_y, 1), 0, host.canvas_size_y - 1)

	var/obj/item/paint_brush/brush = user.get_active_held_item()
	if(!istype(brush))
		return

	var/is_erasing = state["erasing"]
	var/current_color = brush.current_color
	if(!is_erasing && !current_color)
		return

	if(state["shading"])
		if("[x],[y]" in host.modified_areas)
			draw_pixel(x, y, current_color, FALSE, brush.brush_size, TRUE, user)
			state["last_x"] = x
			state["last_y"] = y
		return

	var/dirty = FALSE
	var/last_x = state["last_x"]
	var/last_y = state["last_y"]
	if(!isnull(last_x) && !isnull(last_y) && (last_x != x || last_y != y))
		dirty = draw_line(last_x, last_y, x, y, current_color, is_erasing, brush.brush_size, user)
	else
		dirty = draw_pixel(x, y, current_color, is_erasing, brush.brush_size, FALSE, user)

	if(dirty)
		icon = draw
		host.icon = host.draw

	state["last_x"] = x
	state["last_y"] = y

/obj/item/canvas/random_painting

/obj/item/canvas/random_painting/Initialize()
	. = ..()
	var/chosen_id = SSpaintings.pick_painting_id(canvas_size)
	if(!chosen_id)
		return
	load_painting(chosen_id)
