/obj/item/paint_palette/filled
	colors = list(
		"Red" = COLOR_RED,
		"Yellow" = COLOR_YELLOW,
		"Green" = COLOR_GREEN,
		"Cyan" = COLOR_CYAN,
		"Blue" = COLOR_BLUE,
		"Brown" = "#6B3E1E",
		"White" = "#FFFFFF",
		"Black" = COLOR_BLACK
	)

/obj/item/paint_palette
	item_weight = 14 GRAMS
	name = "paint palette"
	desc = "A tool used for painting"
	icon = 'icons/paint_supplies/paint_items.dmi'
	icon_state = "palette"

	grid_height = 32
	grid_width = 64
	var/list/colors = list()
	/// one per "palette-greyscaleN" well in the icon
	var/max_colors = 8


/obj/item/paint_palette/Initialize()
	. = ..()
	update_appearance(UPDATE_OVERLAYS)

/obj/item/paint_palette/examine(mob/user)
	. = ..()
	if(!length(colors))
		. += span_notice("Its wells are bare.")
		return
	var/list/swatches = list()
	for(var/color_name in colors)
		swatches += "<font color='[colors[color_name]]'>[color_name]</font>"
	. += span_notice("Its wells hold [english_list(swatches)].")

/obj/item/paint_palette/get_mechanics_examine(mob/user)
	. = ..()
	. += span_info("Use it in hand to mix a new colour into an empty well, it holds up to [max_colors].")
	. += span_info("Right-click it to scrape a colour out of its well.")
	. += span_info("Strike it with a paint brush to take a colour up.")

/obj/item/paint_palette/proc/add_color(mob/user)
	if(length(colors) >= max_colors)
		to_chat(user, span_warning("Every well on [src] is full, I must scrape one out first."))
		return
	var/add_color = input(user, "Choose a color to add") as color|null
	if(!add_color)
		return
	var/color_name = browser_input_text(user, "Choose a name for this color", "NAME THE COLOUR", max_length = MAX_NAME_LEN)
	if(!color_name)
		return
	if(QDELETED(src) || !user.is_holding(src))
		return
	if(length(colors) >= max_colors && !(color_name in colors))
		return
	colors[color_name] = add_color
	update_appearance(UPDATE_OVERLAYS)

/obj/item/paint_palette/proc/remove_color(mob/user)
	if(!length(colors))
		return
	var/remove_color = input(user, "Choose a color to remove") as null|anything in colors
	if(!remove_color || QDELETED(src) || !user.Adjacent(src))
		return
	colors -= remove_color
	update_appearance(UPDATE_OVERLAYS)

/obj/item/paint_palette/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return
	remove_color(user)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/item/paint_palette/attack_self(mob/user, list/modifiers)
	. = ..()
	add_color(user)

/obj/item/paint_palette/update_overlays()
	. = ..()

	for(var/i = 1 to min(length(colors), max_colors))
		var/mutable_appearance/MA = mutable_appearance(icon, "palette-greyscale[i]")
		var/color_name = colors[i]
		MA.color = colors[color_name]
		. += MA
