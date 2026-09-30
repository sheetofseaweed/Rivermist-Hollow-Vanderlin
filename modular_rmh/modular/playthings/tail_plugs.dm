// Tail plugs: once worn, the false tail draws exactly like a real one. Only a closer look tells.

/// Name to sprite accessory for every tail a tail plug may copy.
/proc/get_tail_plug_styles()
	var/static/list/styles
	if(!styles)
		styles = list()
		var/static/list/tail_types = list(
			/datum/sprite_accessory/tail/cat,
			/datum/sprite_accessory/tail/catbig,
			/datum/sprite_accessory/tail/cow,
			/datum/sprite_accessory/tail/deer,
			/datum/sprite_accessory/tail/fennec,
			/datum/sprite_accessory/tail/fox,
			/datum/sprite_accessory/tail/horse,
			/datum/sprite_accessory/tail/husky,
			/datum/sprite_accessory/tail/jackal,
			/datum/sprite_accessory/tail/kitsune,
			/datum/sprite_accessory/tail/lab,
			/datum/sprite_accessory/tail/leopard,
			/datum/sprite_accessory/tail/lynx,
			/datum/sprite_accessory/tail/rabbit,
			/datum/sprite_accessory/tail/raccoon,
			/datum/sprite_accessory/tail/redpanda,
			/datum/sprite_accessory/tail/shepherd,
			/datum/sprite_accessory/tail/skunk,
			/datum/sprite_accessory/tail/squirrel,
			/datum/sprite_accessory/tail/tiger,
			/datum/sprite_accessory/tail/wolf,
		)
		for(var/tail_type in tail_types)
			var/datum/sprite_accessory/tail/accessory = SPRITE_ACCESSORY(tail_type)
			if(accessory)
				styles[accessory.name] = tail_type
	return styles

/obj/item/dildo/plug/tail
	name = "unfinished tail plug"
	desc = "A plug with a soft false tail. Shape it in hand to pick its tail and fur."
	icon_state = "unfinished_bunny"
	dildo_material = "wooden"
	sellprice = 12
	bstorage_visible_layer = STORAGE_LAYER_INNER
	/// Sprite accessory the false tail copies.
	var/tail_accessory = /datum/sprite_accessory/tail/fox
	/// Fur colour of the false tail.
	var/tail_color = "#b5651d"
	/// The false tail organ while the plug is worn.
	var/obj/item/organ/tail/false_tail/false_tail

/obj/item/dildo/plug/tail/New()
	. = ..()
	name = "unfinished tail plug"

/obj/item/dildo/plug/tail/Destroy()
	detach_false_tail()
	return ..()

/obj/item/dildo/plug/tail/customize(mob/living/user)
	if(!can_custom)
		return FALSE
	if(!user.incapacitated() && in_range(user, src))
		var/list/styles = get_tail_plug_styles()
		var/style_name = input(user, "Choose the tail for your plug.", "Tail Plug") as null|anything in styles
		if(style_name && !QDELETED(src) && !user.incapacitated() && in_range(user, src))
			tail_accessory = styles[style_name]
		var/new_color = input(user, "Choose the fur colour.", "Tail Plug", tail_color) as color|null
		if(new_color && !QDELETED(src) && !user.incapacitated() && in_range(user, src))
			tail_color = sanitize_hexcolor(new_color, 6, TRUE, tail_color)
	return ..()

/obj/item/dildo/plug/tail/update_appearance()
	. = ..()
	icon_state = "plug_[dildo_size]_bunny"
	name = "[dildo_size] [get_tail_name()] tail plug"
	desc = "A plug with a soft false [get_tail_name()] tail. Worn, it passes for the real thing."

/obj/item/dildo/plug/tail/proc/get_tail_name()
	var/datum/sprite_accessory/tail/accessory = SPRITE_ACCESSORY(tail_accessory)
	return lowertext(accessory?.name || "fur")

/// One copy of the fur colour for each colour key of the chosen tail.
/obj/item/dildo/plug/tail/proc/get_tail_colors()
	var/datum/sprite_accessory/tail/accessory = SPRITE_ACCESSORY(tail_accessory)
	var/colors = ""
	for(var/i in 1 to max(accessory?.color_keys, 1))
		colors += tail_color
	return colors

/obj/item/dildo/plug/tail/on_body_storage_entered(obj/item/organ/storage_organ, target_layer)
	. = ..()
	if(storage_organ.slot == ORGAN_SLOT_ANUS && target_layer == STORAGE_LAYER_INNER)
		attach_false_tail(storage_organ.owner)

/obj/item/dildo/plug/tail/on_body_storage_exited(obj/item/organ/storage_organ)
	. = ..()
	detach_false_tail()

/// Grows the false tail on [wearer]; a real tail already there wins and the plug stays hidden.
/obj/item/dildo/plug/tail/proc/attach_false_tail(mob/living/carbon/wearer)
	if(!iscarbon(wearer) || false_tail || wearer.getorganslot(ORGAN_SLOT_TAIL))
		return FALSE
	var/obj/item/organ/tail/false_tail/new_tail = new
	new_tail.plug = src
	new_tail.set_accessory_type(tail_accessory, get_tail_colors())
	if(!new_tail.Insert(wearer, TRUE, FALSE))
		qdel(new_tail)
		return FALSE
	false_tail = new_tail
	return TRUE

/obj/item/dildo/plug/tail/proc/detach_false_tail()
	if(!false_tail)
		return
	var/obj/item/organ/tail/false_tail/old_tail = false_tail
	false_tail = null
	old_tail.plug = null
	if(old_tail.owner)
		old_tail.Remove(old_tail.owner, TRUE)
	qdel(old_tail)

/obj/item/organ/tail/false_tail
	name = "tail"
	desc = "A soft false tail on a short stem."
	can_wag = FALSE
	delete_on_drop = TRUE
	/// The plug this tail hangs from.
	var/obj/item/dildo/plug/tail/plug

/obj/item/organ/tail/false_tail/is_false_organ()
	return TRUE

// Fur keeps the plug's colour; hair dye on the wearer does not reach it.
/obj/item/organ/tail/false_tail/build_colors_for_accessory(list/source_key_list)
	return

/obj/item/organ/tail/false_tail/Remove(mob/living/carbon/human/H, special = 0)
	. = ..()
	if(plug?.false_tail == src)
		plug.false_tail = null
	plug = null

/obj/item/organ/tail/false_tail/Destroy()
	if(plug?.false_tail == src)
		plug.false_tail = null
	plug = null
	return ..()

// Use a piece of fur on a wooden plug.
/datum/repeatable_crafting_recipe/crafting/tail_plug
	name = "tail plug"
	output = /obj/item/dildo/plug/tail
	requirements = list(/obj/item/dildo/plug/wood = 1, /obj/item/natural/fur = 1)
	starting_atom = /obj/item/natural/fur
	attacked_atom = /obj/item/dildo/plug/wood
	category = "Lewd"
