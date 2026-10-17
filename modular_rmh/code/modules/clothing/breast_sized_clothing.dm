// Worn sprites that follow the wearer's visible breast size.
// For size N the female worn state is cut by "<state>_f_<N>_hide", then "<state>_f_pair_<N>_<LAYER>"
// and "<state>_f_<N>_extra" go on top. The detail (paint) layer repeats this with "<state>_f_detail_..." states.
// Animated sizes follow the body breasts (breast_animation.dm): the default states carry the walk cycle as a
// movement state, "<state>_f_run_..." the run cycle, "<state>_f_f<K>_..." / "_r<K>_" / "_s<K>_" walk, run and squeeze frame K.
// Icons are packed with tools/breast_sized_clothing/pack_breast_sized.py, see tools/breast_sized_clothing/README.md.
// Several garments stack over the chest (bra, shirt, armor, tabard-layer cloak, see get_chest_stack()): each one cuts its own
// base, and lifted south views are ordered by slot (BREAST_BRA/SHIRT/ARMOR/CLOAK_FRONT_LAYER), each cut by the bases above it.
// Under a closed breast-sized garment (breast_sized_closed) a lower garment draws no breast or extra layers at all,
// so its own animation can never push them out from under the closed one.

/// Female breast offset the layers were drawn for. Races with their own clothing sprites shift by the difference.
#define BREAST_SIZED_BASE_OFFSET_Y -1

/obj/item
	/// Icon with per-breast-size layers for the female worn state. Null keeps the old single "_boob" overlay.
	var/breast_sized_icon
	/// The breast-sized garment covers the whole chest: garments under it skip their breast and extra layers.
	var/breast_sized_closed = FALSE

/// Visible breast size to draw, or null when the wearer or this icon has no matching layers.
/obj/item/proc/get_breast_sized_size()
	if(!breast_sized_icon || !ishuman(loc))
		return null
	var/mob/living/carbon/human/wearer = loc
	var/obj/item/organ/genitals/filling_organ/breasts/breasts = wearer.getorganslot(ORGAN_SLOT_BREASTS)
	if(!breasts || !ispath(breasts.accessory_type, /datum/sprite_accessory/genitals/breasts/pair))
		return null
	var/size = breasts.get_visible_size()
	if(!has_breast_sized_state("[icon_state]_f_[size]_hide"))
		return null
	return size

/// Vertical shift for races drawn with their own clothing sprites (customi), matching their breast offset.
/obj/item/proc/get_breast_sized_offset(customi)
	if(!customi || !ishuman(loc))
		return 0
	var/mob/living/carbon/human/wearer = loc
	var/list/offset = LAZYACCESS(wearer.dna?.species?.offset_genitals_f, OFFSET_BREASTS)
	if(!offset)
		return 0
	return offset[2] - BREAST_SIZED_BASE_OFFSET_Y

/// Animation variant matching the wearer's breasts ("", "_run", "_f<K>", "_r<K>" or "_s<K>") when this icon has it for size.
/obj/item/proc/get_breast_sized_anim(size)
	if(!ishuman(loc))
		return ""
	var/mob/living/carbon/human/wearer = loc
	var/obj/item/organ/genitals/filling_organ/breasts/breasts = wearer.getorganslot(ORGAN_SLOT_BREASTS)
	var/suffix = breasts?.get_anim_suffix()
	if(suffix && has_breast_sized_state("[icon_state]_f[suffix]_[size]_hide"))
		return suffix
	return ""

/// Whether layers drop their walk cycle movement states because the wearer turned breast animation off.
/obj/item/proc/breast_sized_still_only()
	return ishuman(loc) && !breast_animation_enabled(loc)

/// Icon and icon_state for a layer state: the packed file, or its still version when animation is off.
/obj/item/proc/get_breast_sized_layer_icon(state)
	var/static/list/still_icons = list()
	if(!breast_sized_still_only())
		return list(breast_sized_icon, state)
	var/key = "[breast_sized_icon]|[state]"
	if(!still_icons[key])
		still_icons[key] = fcopy_rsc(icon(breast_sized_icon, state, moving = 0))
	return list(still_icons[key], "")

/obj/item/proc/has_breast_sized_state(state)
	var/static/list/states_by_icon = list()
	var/key = "[breast_sized_icon]"
	var/list/states = states_by_icon[key]
	if(!states)
		states = list()
		for(var/icon_state_name in icon_states(breast_sized_icon))
			states[icon_state_name] = TRUE
		states_by_icon[key] = states
	return states[state]

/// Returns base_icon with the hide mask cut out. Cached, keyed by cache_key.
/// An animated mask also gives the result a movement version (the base cut frame by frame), unless still_only.
/obj/item/proc/get_breast_sized_masked_icon(base_icon, base_state, cache_key, mask_state, offset_y, still_only = FALSE)
	var/static/list/masked_icons = list()
	if(!has_breast_sized_state(mask_state))
		return null
	var/key = "[cache_key]|[breast_sized_icon]|[mask_state]|[offset_y]|[still_only]"
	. = masked_icons[key]
	if(.)
		return
	// First frame of the base only: Blend does not pair up mismatched frame counts.
	var/icon/base = icon(base_icon, base_state, frame = 1, moving = 0)
	var/icon/result
	for(var/moving in still_only ? list(0) : list(0, 1))
		var/icon/mask = icon(breast_sized_icon, mask_state, moving = moving)
		if(!length(icon_states(mask)))
			continue
		if(offset_y)
			mask.Shift(offset_y > 0 ? NORTH : SOUTH, abs(offset_y))
		// Opaque white wherever the mask is empty, transparent where it hides.
		mask.MapColors(0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,-1, 1,1,1,1)
		// A one-frame base blended with an animated mask takes the mask's frames.
		var/icon/masked = icon(base)
		masked.Blend(mask, ICON_MULTIPLY)
		if(!result)
			result = masked
		else
			result.Insert(masked, "", moving = moving)
	. = fcopy_rsc(result)
	masked_icons[key] = .

/// part: "" for every direction, "_side" without the south frame, "_front" with only the south frame.
/// covers: null for every state, TRUE for the cover state only, FALSE without it.
/obj/item/proc/get_breast_sized_layer_states(size, detail = FALSE, part = "", anim = "", covers = null)
	var/prefix = "[icon_state]_f[detail ? "_detail" : ""][anim]"
	. = list()
	var/list/states = covers ? list() : list("[prefix]_pair_[size]_BEHIND", "[prefix]_pair_[size]_ADJ", "[prefix]_pair_[size]_FRONT", "[prefix]_[size]_extra")
	// "_cover" (only "_cover_front" exists): the base over the lifted body breasts, see covers_body_breasts_packed().
	// Packed from the human sprites, so races with their own clothing sprites keep the runtime cut instead.
	var/mob/living/carbon/human/wearer = loc
	if(covers != FALSE && istype(wearer) && !wearer.dna?.species?.custom_clothes)
		states.Insert(1, "[prefix]_[size]_cover")
	for(var/state in states)
		if(has_breast_sized_state("[state][part]"))
			. += "[state][part]"

/// Worn items over the chest, bottom to top: bra, shirt, armor, tabard-layer cloak. Breast-sized ones and any bra always
/// count; others only when they cover the chest (a waist apron does not).
/mob/living/carbon/human/proc/get_chest_stack()
	. = list()
	for(var/obj/item/item in list(bra, wear_shirt, wear_armor, cloak))
		if(item == cloak && cloak.alternate_worn_layer != TABARD_LAYER)
			continue
		if(item == bra || item.draws_breast_sized_layers() || (item.body_parts_covered & CHEST) || (item.flags_inv & HIDEBOOB))
			. += item

/// Worn items in the chest stack above this one.
/obj/item/proc/get_breast_sized_items_above()
	if(!ishuman(loc))
		return list()
	var/mob/living/carbon/human/wearer = loc
	var/list/stack = wearer.get_chest_stack()
	var/index = stack.Find(src)
	return index ? stack.Copy(index + 1) : list()

/// Whether the south view of the breast layers can go above sleeves, gloves and rings: when every item above it in
/// the chest stack is breast-sized too (and lifted above it); a plain garment over the chest keeps it down.
/obj/item/proc/can_lift_breast_sized_front()
	if(!draws_breast_sized_layers())
		return FALSE
	for(var/obj/item/item as anything in get_breast_sized_items_above())
		if(!item.draws_breast_sized_layers())
			return FALSE
	return TRUE

/// Layer of the lifted south view, by the slot the item is worn in.
/obj/item/proc/get_breast_sized_front_layer()
	var/mob/living/carbon/human/wearer = loc
	if(src == wearer.bra)
		return BREAST_BRA_FRONT_LAYER
	if(src == wearer.wear_armor)
		return BREAST_ARMOR_FRONT_LAYER
	if(src == wearer.cloak)
		return BREAST_CLOAK_FRONT_LAYER
	return BREAST_SHIRT_FRONT_LAYER

/// Layer part drawn on the garment's own layer: the south view moves to build_breast_sized_front() when lifted.
/obj/item/proc/get_breast_sized_side_part()
	return can_lift_breast_sized_front() ? "_side" : ""

/// Whether a closed breast-sized garment is worn over this one, see breast_sized_closed.
/obj/item/proc/is_under_closed_breast_sized()
	for(var/obj/item/item as anything in get_breast_sized_items_above())
		if(item.breast_sized_closed && item.draws_breast_sized_layers())
			return TRUE
	return FALSE

/// Whether the wearer set the breasts to "Show Above clothes" (Expose/Hide genitals): the garment then draws none of
/// its breast and extra layers, only its base cut around the breasts, so they show bare from every side.
/obj/item/proc/breasts_exposed_over_garment()
	if(!ishuman(loc))
		return FALSE
	var/mob/living/carbon/human/wearer = loc
	var/obj/item/organ/genitals/breasts = wearer.getorganslot(ORGAN_SLOT_BREASTS)
	return breasts?.visible_through_clothes == DRAW_ABOVE

/// cut_masks/cut_key: see build_breast_sized_front().
/obj/item/proc/make_breast_sized_overlays(size, offset_y, layer2use, detail, part, list/cut_masks, cut_key, covers = null)
	. = list()
	if(is_under_closed_breast_sized() || breasts_exposed_over_garment())
		return
	for(var/state in get_breast_sized_layer_states(size, detail, part, get_breast_sized_anim(size), covers))
		var/list/layer_icon = length(cut_masks) ? list(get_breast_sized_cut_icon(state, cut_masks, cut_key), "") : get_breast_sized_layer_icon(state)
		var/mutable_appearance/layer_overlay = mutable_appearance(layer_icon[1], layer_icon[2], -layer2use)
		layer_overlay.pixel_y = offset_y
		if(detail)
			layer_overlay.appearance_flags = RESET_COLOR
			if(get_detail_color())
				layer_overlay.color = get_detail_color()
		. += layer_overlay

/// Cuts the base out of standing and puts the breast and extra layers over it.
/obj/item/proc/apply_breast_sized_layers(mutable_appearance/standing, cache_key, size, offset_y, layer2use)
	var/masked = get_breast_sized_masked_icon(standing.icon, standing.icon_state, cache_key, "[icon_state]_f[get_breast_sized_anim(size)]_[size]_hide", offset_y, breast_sized_still_only())
	if(masked)
		standing.icon = masked
		standing.icon_state = ""
	standing.overlays.Add(make_breast_sized_overlays(size, offset_y, layer2use, FALSE, get_breast_sized_side_part()))

/// Detail (paint) layer: the detail state with its own hide mask, then the detail breast and extra layers.
/obj/item/proc/apply_breast_sized_detail(mutable_appearance/standing, file2use, t_state, size, offset_y, layer2use)
	var/detail_state = "[t_state][get_detail_tag()]"
	var/masked = get_breast_sized_masked_icon(file2use, detail_state, "[file2use]|[detail_state]", "[icon_state]_f_detail[get_breast_sized_anim(size)]_[size]_hide", offset_y, breast_sized_still_only())
	var/mutable_appearance/pic = mutable_appearance(masked || icon(file2use, detail_state), "", -layer2use)
	pic.appearance_flags = RESET_COLOR
	if(get_detail_color())
		pic.color = get_detail_color()
	standing.overlays.Add(pic)
	standing.overlays.Add(make_breast_sized_overlays(size, offset_y, layer2use, TRUE, get_breast_sized_side_part()))

/// Layer state state of this icon cut wherever any of cut_masks (garments worn above, see build_breast_sized_front()) is
/// opaque, with its still and movement versions. Cached by cut_key, which identifies the masks.
/obj/item/proc/get_breast_sized_cut_icon(state, list/cut_masks, cut_key)
	var/static/list/cut_icons = list()
	var/key = "[breast_sized_icon]|[state]|[breast_sized_still_only()]|[cut_key]"
	. = cut_icons[key]
	if(.)
		return
	var/icon/whole = breast_sized_still_only() ? icon(breast_sized_icon, state, moving = 0) : icon(breast_sized_icon, state)
	var/list/inverted = list()
	for(var/icon/mask as anything in cut_masks)
		var/icon/inverse = icon(mask)
		// Opaque white wherever the mask is empty, transparent where it covers.
		inverse.MapColors(0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,-1, 1,1,1,1)
		inverted += inverse
	. = fcopy_rsc(cut_by_masks(whole, inverted))
	cut_icons[key] = .

/// South view of the breast and extra layers on its slot's front layer, or null when it stays on the garment layer.
/// It is cut by the bases of the breast-sized garments worn above it, which are lifted over it.
/// Arguments match the build_worn_icon() call for this item; the caller copies the garment's pixel offsets.
/obj/item/proc/build_breast_sized_front(coom, customi, icon/clip_mask)
	if(coom != FEMALE_BOOB || !boobed || !can_lift_breast_sized_front())
		return null
	var/size = get_breast_sized_size()
	if(isnull(size))
		return null
	var/mob/living/carbon/human/wearer = loc
	var/list/frame = get_breast_sized_cover_frame(wearer)
	var/list/cut_masks = list()
	var/cut_key = ""
	for(var/obj/item/item as anything in get_breast_sized_items_above())
		var/icon/mask = item.get_breast_sized_cover_mask(wearer, frame[2], frame[3])
		if(mask)
			cut_masks += mask
			cut_key += "|[item.get_breast_sized_cover_key(wearer, frame[2], frame[3])]"
	var/front_layer = get_breast_sized_front_layer()
	var/offset_y = get_breast_sized_offset(customi)
	// Covers of the base and the paint first, under the breast layers of both (as the static garment is).
	var/list/layers = make_breast_sized_overlays(size, offset_y, front_layer, FALSE, "_front", cut_masks, cut_key, covers = TRUE)
	if(get_detail_tag())
		layers += make_breast_sized_overlays(size, offset_y, front_layer, TRUE, "_front", cut_masks, cut_key, covers = TRUE)
	layers += make_breast_sized_overlays(size, offset_y, front_layer, FALSE, "_front", cut_masks, cut_key, covers = FALSE)
	if(get_detail_tag())
		layers += make_breast_sized_overlays(size, offset_y, front_layer, TRUE, "_front", cut_masks, cut_key, covers = FALSE)
	if(!length(layers))
		return null
	var/mutable_appearance/front = mutable_appearance(null, "", -front_layer)
	front.overlays.Add(layers)
	if(istype(clip_mask))
		front.filters += filter(type = "alpha", icon = clip_mask)
	front.alpha = alpha
	front.color = color
	return front

/// Whether this worn item currently draws its breast-sized layers, so the body breasts should show under its hide cut.
/// Mirrors the FEMALE_BOOB choice in update_inv_shirt()/update_inv_armor()/update_inv_cloak()/update_inv_undie_top().
/obj/item/proc/draws_breast_sized_layers()
	if(!boobed || !ishuman(loc))
		return FALSE
	var/mob/living/carbon/human/wearer = loc
	if(src == wearer.bra)
		return wearer.bra_draws_breast_sized_layers()
	if(src != wearer.wear_shirt && src != wearer.wear_armor && !(src == wearer.cloak && alternate_worn_layer == TABARD_LAYER))
		return FALSE
	var/datum/species/species = wearer.dna?.species
	if(!species?.sexes || species.no_boobs || wearer.gender != FEMALE || species.swap_female_clothes)
		return FALSE
	return !isnull(get_breast_sized_size())

/// Whether the worn bra uses its breast-sized layers: a female wearer whose chest is not covered by a plain
/// (non breast-sized) garment over it, which would hide the bra's breasts and let them poke out when animating.
/mob/living/carbon/human/proc/bra_draws_breast_sized_layers()
	if(!bra?.boobed || !bra.gendered)
		return FALSE
	var/datum/species/species = dna?.species
	if(!species?.sexes || species.no_boobs || gender != FEMALE || species.swap_female_clothes)
		return FALSE
	for(var/obj/item/item as anything in list(wear_shirt, wear_armor, cloak))
		if(item?.flags_inv & HIDEBOOB && !item.draws_breast_sized_layers())
			return FALSE
	return !isnull(bra.get_breast_sized_size())

/// is_human_part_visible(owner, HIDEBOOB|HIDEJUMPSUIT) that lets breast-sized clothing through.
/proc/breasts_visible_under_clothes(mob/living/carbon/human/owner)
	if(!istype(owner))
		return TRUE
	for(var/obj/item/item as anything in get_all_worn_items(owner))
		if(!(item.flags_inv & (HIDEBOOB|HIDEJUMPSUIT)))
			continue
		if(item.draws_breast_sized_layers())
			continue
		return FALSE
	return TRUE

/// Draws the breast and extra layers onto a flat icon, for the blood overlay shape.
/obj/item/proc/blend_breast_sized_layers(icon/target, size, offset_y)
	if(is_under_closed_breast_sized() || breasts_exposed_over_garment())
		return
	for(var/state in get_breast_sized_layer_states(size, anim = get_breast_sized_anim(size)))
		var/icon/layer_icon = icon(breast_sized_icon, state, moving = 0)
		if(offset_y)
			layer_icon.Shift(offset_y > 0 ? NORTH : SOUTH, abs(offset_y))
		target.Blend(layer_icon, ICON_OVERLAY)

/obj/item/clothing/shirt/dress/gown
	breast_sized_icon = 'modular_rmh/icons/clothing/onmob/breast_sized/springgown.dmi'
	breast_sized_closed = TRUE

/obj/item/clothing/shirt/dress/gown/summergown
	breast_sized_icon = 'modular_rmh/icons/clothing/onmob/breast_sized/summergown.dmi'
	breast_sized_closed = FALSE

/obj/item/clothing/shirt/dress/gown/wintergown
	breast_sized_icon = 'modular_rmh/icons/clothing/onmob/breast_sized/wintergown.dmi'

/obj/item/clothing/shirt/dress/gown/fallgown
	breast_sized_icon = 'modular_rmh/icons/clothing/onmob/breast_sized/fallgown.dmi'
	breast_sized_closed = FALSE

// Subtypes with their own art (loudmouth, weddingdress) find no states for their icon_state and keep the old overlay.
/obj/item/clothing/shirt/dress/silkdress
	breast_sized_icon = 'modular_rmh/icons/clothing/onmob/breast_sized/silkdress.dmi'

// Royal gown. The detail layer (lord's primary colour) follows the sizes too. Princess and prince subtypes find no
// states for their icon_state and keep the old overlay.
/obj/item/clothing/shirt/dress/royal
	breast_sized_icon = 'modular_rmh/icons/clothing/onmob/breast_sized/royaldress.dmi'
	breast_sized_closed = TRUE

// Bras are the bottom of the chest stack (update_inv_undie_top()). Draft art: to be redrawn.
/obj/item/clothing/bra
	breast_sized_icon = 'modular_rmh/icons/clothing/onmob/breast_sized/bra.dmi'
	boobed = TRUE

/obj/item/clothing/bra/bikini
	breast_sized_icon = 'modular_rmh/icons/clothing/onmob/breast_sized/bikini_top.dmi'

/obj/item/clothing/bra/exoticsilkbra
	breast_sized_icon = 'modular_rmh/icons/clothing/onmob/breast_sized/exoticsilkbra.dmi'

/obj/item/clothing/bra/shibari
	breast_sized_icon = 'modular_rmh/icons/clothing/onmob/breast_sized/shibari.dmi'

#undef BREAST_SIZED_BASE_OFFSET_Y
