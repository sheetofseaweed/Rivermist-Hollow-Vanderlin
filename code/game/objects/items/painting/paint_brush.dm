/obj/item/paint_brush
	item_weight = 9 GRAMS
	name = "paint brush"
	desc = "A tool used for painting"
	icon = 'icons/paint_supplies/paint_items.dmi'
	icon_state = "paintbrush"

	grid_height = 32
	grid_width = 64
	var/current_color
	var/brush_size = 1
	var/max_brush_size = 5

/obj/item/paint_brush/examine(mob/user)
	. = ..()
	if(current_color)
		. += span_notice("It is lathered with <font color='[current_color]'>colour</font>.")
	. += span_notice("The bristles are spread [brush_size] wide.")

/obj/item/paint_brush/get_mechanics_examine(mob/user)
	. = ..()
	. += span_info("Strike a palette with it to take up a colour, striking again blends the two.")
	. += span_info("Shift+right-click to widen the bristles, alt+right-click to narrow them.")
	. += span_info("Use it in hand to wipe the colour off, or wash it in water.")

/obj/item/paint_brush/update_overlays()
	. = ..()
	if(!current_color)
		return

	var/mutable_appearance/MA = mutable_appearance(icon, "paintbrush-color")
	MA.color = current_color
	. += MA

/obj/item/paint_brush/proc/increase_brush_size()
	if(brush_size >= max_brush_size)
		return FALSE
	brush_size++
	return TRUE

/obj/item/paint_brush/proc/decrease_brush_size()
	if(brush_size <= 1)
		return FALSE
	brush_size--
	return TRUE

/obj/item/paint_brush/ShiftRightClick(mob/user)
	if(loc != user)
		return ..()
	if(increase_brush_size())
		to_chat(user, span_notice("I spread the bristles to [brush_size]."))
	else
		to_chat(user, span_warning("The bristles are as wide as they go."))

/obj/item/paint_brush/AltRightClick(mob/user, list/modifiers)
	if(loc != user)
		return ..()
	if(decrease_brush_size())
		to_chat(user, span_notice("I pinch the bristles down to [brush_size]."))
	else
		to_chat(user, span_warning("The bristles are as fine as they go."))

/obj/item/paint_brush/attack_self(mob/user, list/modifiers)
	. = ..()
	if(!current_color)
		return
	current_color = null
	update_appearance(UPDATE_OVERLAYS)
	to_chat(user, span_notice("I wipe [src] clean."))

/// modular hook for painting things that aren't canvases, return TRUE to consume the swing
/obj/item/paint_brush/proc/try_special_paint(atom/target, mob/living/user)
	return FALSE

/obj/item/paint_brush/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(istype(interacting_with, /obj/item/paint_palette))
		var/obj/item/paint_palette/palette = interacting_with
		if(!length(palette.colors))
			to_chat(user, span_warning("[palette] is bare."))
			return ITEM_INTERACT_BLOCKING
		var/color_name = browser_input_list(user, "Choose a color to blend", items = palette.colors)
		if(!color_name || QDELETED(palette) || !user.Adjacent(palette))
			return ITEM_INTERACT_BLOCKING
		var/merge_color = palette.colors[color_name]
		if(!merge_color)
			return ITEM_INTERACT_BLOCKING
		if(!current_color)
			current_color = merge_color
			to_chat(user, span_notice("I take up some <font color='[current_color]'>[color_name]</font>."))
		else
			current_color = BlendRGB(current_color, merge_color, 0.5)
			to_chat(user, span_notice("I blend in some [color_name], and the bristles turn <font color='[current_color]'>this shade</font>."))
		update_appearance(UPDATE_OVERLAYS)
		return ITEM_INTERACT_SUCCESS

	if(try_special_paint(interacting_with, user))
		return ITEM_INTERACT_SUCCESS

	if(!(interacting_with.reagents?.flags & DRAINABLE))
		return NONE

	if(!interacting_with.reagents.has_reagent(/datum/reagent/water))
		return NONE

	to_chat(user, span_notice("I start to wash [src] in [interacting_with]..."))
	if(!do_after(user, 1 SECONDS, interacting_with))
		return ITEM_INTERACT_BLOCKING

	current_color = null
	update_appearance(UPDATE_OVERLAYS)
	return ITEM_INTERACT_SUCCESS
