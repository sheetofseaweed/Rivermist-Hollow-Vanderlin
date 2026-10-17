// Breasts seen from the front go above gloves, wrists, rings, belts and sleeves (BODY_BREASTS_FRONT_LAYER),
// with nipple piercings just above them. Side and back views stay on the body layers, where the near arm covers them.
// Lifted when nothing is worn over the chest, or only breast-sized clothing that lifts its own breast layers:
// then the body breasts go right under the clothing's front layers, cut wherever their bases still cover them.

#define BODY_BREASTS_COVER_BARE "bare"
#define BODY_BREASTS_COVER_BLOCKED "blocked"

/// Chest clothing state for lifting the body breasts: BODY_BREASTS_COVER_* or the list of breast-sized items over them.
/mob/living/carbon/human/proc/get_body_breasts_front_cover()
	if(undershirt)
		return BODY_BREASTS_COVER_BLOCKED
	var/list/stack = get_chest_stack()
	if(!length(stack))
		return BODY_BREASTS_COVER_BARE
	for(var/obj/item/item as anything in stack)
		if(!item.can_lift_breast_sized_front())
			return BODY_BREASTS_COVER_BLOCKED
	return stack

/// Whether the front view of the body breasts goes above hands, gloves and rings.
/mob/living/carbon/human/proc/can_lift_body_breasts_front()
	return get_body_breasts_front_cover() != BODY_BREASTS_COVER_BLOCKED

/// Moves the south view of source into a new appearance on front_layer and leaves the other directions in source.
/// Split icons are cached by cache_key, which must identify source's icon and icon_state.
/// cover_masks: optional icons in source's pixel frame; the front view is cut wherever any of them is opaque.
/proc/split_south_view(mutable_appearance/source, cache_key, front_layer, list/cover_masks)
	var/static/list/split_icons = list()
	var/list/icons = split_icons[cache_key]
	if(!icons)
		var/icon/whole = icon(source.icon, source.icon_state)
		var/list/masks = list()
		for(var/icon/cover_mask as anything in cover_masks)
			var/icon/mask = icon(cover_mask)
			// Opaque white wherever the cover is empty, transparent where it covers.
			mask.MapColors(0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,-1, 1,1,1,1)
			masks += mask
		var/icon/front = split_dirs(whole, TRUE, masks)
		var/icon/side = split_dirs(whole, FALSE)
		icons = list(fcopy_rsc(front), fcopy_rsc(side))
		split_icons[cache_key] = icons

	var/had_blocker = length(source.overlays)
	var/mutable_appearance/front_appearance = new(source)
	front_appearance.icon = icons[1]
	front_appearance.icon_state = ""
	front_appearance.layer = -front_layer
	front_appearance.overlays.Cut()
	if(had_blocker)
		front_appearance.overlays += emissive_blocker(icons[1], "")
	source.icon = icons[2]
	source.icon_state = ""
	return front_appearance

/// Copy of whole (state "") keeping only the south direction (keep_south) or everything but it,
/// for every frame of both its still and movement versions, then cut by masks (see cut_by_masks()).
/proc/split_dirs(icon/whole, keep_south, list/masks)
	var/icon/result
	for(var/moving in list(0, 1))
		var/icon/part = icon(whole, "", moving = moving)
		if(!length(icon_states(part)))
			continue
		// A one-frame blank inserted into a direction blanks it in every frame.
		var/icon/blank = icon(part, "", SOUTH, 1)
		blank.MapColors(0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0)
		if(keep_south)
			for(var/dir in list(NORTH, EAST, WEST))
				part.Insert(blank, "", dir)
		else
			part.Insert(blank, "", SOUTH)
		if(!result)
			result = new /icon()
		result.Insert(part, "", moving = moving)
	return length(masks) ? cut_by_masks(result, masks) : result

/// Copy of whole (state "") with every one of masks (opaque white = keep) multiplied over its still and movement
/// versions. An animated mask cuts the movement frames with its movement version, its still version the rest.
/proc/cut_by_masks(icon/whole, list/masks)
	var/icon/result
	for(var/moving in list(0, 1))
		var/icon/part = icon(whole, "", moving = moving)
		if(!length(icon_states(part)))
			continue
		for(var/icon/mask as anything in masks)
			var/icon/part_mask = icon(mask, "", moving = moving)
			if(!length(icon_states(part_mask)))
				part_mask = icon(mask, "", moving = 0)
			part.Blend(part_mask, ICON_MULTIPLY)
		if(!result)
			result = new /icon()
		result.Insert(part, "", moving = moving)
	return result

/// split_south_view() with the "_front"/"_side" copies of the state already in source's icon, so nothing is cut at
/// runtime. The body breast icons hold them for every ADJ state (tools/breast_anim/south_split.py), and the coloured
/// bundle includes them (generate_icon_states() below).
/proc/split_south_view_packed(mutable_appearance/source, front_layer)
	var/had_blocker = length(source.overlays)
	var/mutable_appearance/front_appearance = new(source)
	front_appearance.icon_state = "[source.icon_state]_front"
	front_appearance.layer = -front_layer
	front_appearance.overlays.Cut()
	if(had_blocker)
		front_appearance.overlays += emissive_blocker(source.icon, front_appearance.icon_state)
	source.icon_state = "[source.icon_state]_side"
	return front_appearance

/// Whether this breast-sized item hides the lifted body breasts with the cover states in its own front layer (packed by
/// pack_breast_sized.py for the human offsets), so the body breasts need no cut by its base.
/obj/item/proc/covers_body_breasts_packed(mob/living/carbon/human/wearer, body_x, body_y)
	var/size = get_breast_sized_size()
	if(isnull(size) || !has_breast_sized_state("[icon_state]_f_[size]_cover_front"))
		return FALSE
	var/list/frame = get_breast_sized_cover_frame(wearer)
	// Custom race sprites or other offsets: the cover was packed for the human body frame (body breasts 1px lower).
	return !frame[1] && frame[2] - body_x == 0 && frame[3] - body_y == 1

/datum/sprite_accessory/genitals/breasts/generate_icon_states(overlay_icon_state, color_string, icon_file)
	. = ..()
	var/file = icon_file || icon
	var/list/color_list = color_string_to_list(color_string)
	for(var/suffix in list("ADJ_front", "ADJ_side"))
		if(icon_exists(file, "[overlay_icon_state]_[suffix]"))
			.["[overlay_icon_state]_[suffix]"] = generate_icon_state(overlay_icon_state, color_list, BODY_ADJ_TOP_LAYER, suffix, file)

/// Splits the front view off appearances drawn on from_layer when owner's breasts are lifted.
/// colors: the accessory colors the appearances were built with, part of the split icon cache key.
/// use_cover: cut the front view by breast-sized clothing worn over it; otherwise only lift when bare.
/datum/sprite_accessory/proc/lift_body_breasts_front(list/appearance_list, obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/human/owner, from_layer, front_layer, colors, use_cover = FALSE)
	if(draw_above_clothes || !istype(owner) || !owner.getorganslot(ORGAN_SLOT_BREASTS))
		return
	var/cover = owner.get_body_breasts_front_cover()
	if(cover == BODY_BREASTS_COVER_BLOCKED || (!use_cover && cover != BODY_BREASTS_COVER_BARE))
		return
	var/icon_file = get_icon(organ, bodypart, owner)
	for(var/mutable_appearance/appearance as anything in appearance_list.Copy())
		if(appearance.layer != -from_layer)
			continue
		// Pre-split states, and garments that cover the body breasts from their own front layer: nothing to cut.
		if(use_cover && icon_exists(icon_file, "[appearance.icon_state]_front"))
			var/packed = TRUE
			if(islist(cover))
				for(var/obj/item/cover_item as anything in cover)
					if(!cover_item.covers_body_breasts_packed(owner, appearance.pixel_x, appearance.pixel_y))
						packed = FALSE
						break
			if(packed)
				appearance_list += split_south_view_packed(appearance, front_layer)
				continue
		var/cache_key = "[type]|[icon_file]|[appearance.icon_state]|[colors]"
		var/list/cover_masks = list()
		if(islist(cover))
			for(var/obj/item/cover_item as anything in cover)
				var/icon/cover_mask = cover_item.get_breast_sized_cover_mask(owner, appearance.pixel_x, appearance.pixel_y)
				if(cover_mask)
					cover_masks += cover_mask
					cache_key += "|[cover_item.get_breast_sized_cover_key(owner, appearance.pixel_x, appearance.pixel_y)]"
		appearance_list += split_south_view(appearance, cache_key, front_layer, cover_masks)

/datum/sprite_accessory/genitals/breasts/adjust_appearance_list(list/appearance_list, obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/human/owner)
	..()
	lift_body_breasts_front(appearance_list, organ, bodypart, owner, BODY_ADJ_TOP_LAYER, BODY_BREASTS_FRONT_LAYER, organ?.accessory_colors, use_cover = TRUE)

/datum/sprite_accessory/piercing/adjust_appearance_list(list/appearance_list, obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/human/owner)
	..()
	var/colors
	for(var/datum/bodypart_feature/feature as anything in bodypart?.bodypart_features)
		if(feature.accessory_type == type)
			colors = feature.accessory_colors
			break
	lift_body_breasts_front(appearance_list, organ, bodypart, owner, layer, BREAST_PIERCING_FRONT_LAYER, colors)

/obj/item/organ/genitals/filling_organ/breasts/get_render_key_state()
	. = ..()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/human_owner = owner
	var/cover = human_owner.get_body_breasts_front_cover()
	if(cover == BODY_BREASTS_COVER_BARE)
		. = "[.]_front"
	else if(islist(cover))
		. = "[.]_front"
		for(var/obj/item/cover_item as anything in cover)
			. += "_[cover_item.get_breast_sized_cover_key(human_owner)]"

/// Species clothing id and slot offset this item is drawn with on wearer, as used by update_inv_shirt()/armor()/cloak()/undie_top().
/obj/item/proc/get_breast_sized_cover_frame(mob/living/carbon/human/wearer)
	var/datum/species/species = wearer.dna?.species
	var/customi
	if(species?.custom_clothes)
		customi = species.custom_id || species.id
	var/offset_key = OFFSET_SHIRT
	if(src == wearer.bra)
		offset_key = OFFSET_BRA
	else if(src == wearer.wear_armor)
		offset_key = OFFSET_ARMOR
	else if(src == wearer.cloak)
		offset_key = OFFSET_CLOAK
	var/list/offset = LAZYACCESS(species?.offset_features_f, offset_key)
	return list(customi, offset ? offset[1] : 0, offset ? offset[2] : 0)

/// Identifies get_breast_sized_cover_mask() output, for cache and render keys.
/obj/item/proc/get_breast_sized_cover_key(mob/living/carbon/human/wearer, body_x = 0, body_y = 0)
	var/list/frame = get_breast_sized_cover_frame(wearer)
	var/size = get_breast_sized_size()
	return "[type]|[mob_overlay_icon]|[icon_state]|[size][get_breast_sized_anim(size)]|[breast_sized_still_only()]|[frame[1]]|[frame[2] - body_x]|[frame[3] - body_y]"

/// This item's worn base after its hide cut, moved into the pixel frame of a body appearance at body_x/body_y.
/obj/item/proc/get_breast_sized_cover_mask(mob/living/carbon/human/wearer, body_x = 0, body_y = 0)
	var/size = get_breast_sized_size()
	if(isnull(size) || !mob_overlay_icon)
		return null
	var/list/frame = get_breast_sized_cover_frame(wearer)
	var/customi = frame[1]
	var/t_state = "[icon_state]_f[customi ? "_[customi]" : ""]"
	var/hide_offset = get_breast_sized_offset(customi)
	var/base = get_breast_sized_masked_icon(mob_overlay_icon, t_state, "[mob_overlay_icon]|[t_state]|cover", "[icon_state]_f[get_breast_sized_anim(size)]_[size]_hide", hide_offset, breast_sized_still_only())
	var/icon/mask = base ? icon(base) : icon(mob_overlay_icon, t_state, frame = 1)
	var/shift_x = frame[2] - body_x
	var/shift_y = frame[3] - body_y
	if(shift_x)
		mask.Shift(shift_x > 0 ? EAST : WEST, abs(shift_x))
	if(shift_y)
		mask.Shift(shift_y > 0 ? NORTH : SOUTH, abs(shift_y))
	return mask

#undef BODY_BREASTS_COVER_BARE
#undef BODY_BREASTS_COVER_BLOCKED
