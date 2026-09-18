/obj/item/clothing/gloves/essence_gauntlet
	name = "essence gauntlet"
	desc = "A gauntlet that can store alchemical essences and channel them into alchemical spells. Advanced combinations can unlock powerful effects."
	icon_state = "essence_gauntlet"
	var/list/obj/item/essence_vial/stored_vials = list()
	var/list/datum/essence_combo/active_combos = list()
	var/max_vials = 4

/obj/item/clothing/gloves/essence_gauntlet/equipped(mob/user, slot)
	. = ..()
	if(slot & ITEM_SLOT_GLOVES)
		refresh_combos(user)

/obj/item/clothing/gloves/essence_gauntlet/dropped(mob/user)
	clear_combos(user)
	return ..()

/obj/item/clothing/gloves/essence_gauntlet/Destroy()
	var/mob/living/wearer = get_gauntlet_user()
	if(wearer)
		clear_combos(wearer)

	var/atom/drop_target = drop_location()
	var/list/vials_to_eject = stored_vials.Copy()
	stored_vials.Cut()
	for(var/obj/item/essence_vial/vial in vials_to_eject)
		if(drop_target && !QDELETED(vial))
			vial.forceMove(drop_target)

	active_combos.Cut()
	return ..()

/obj/item/clothing/gloves/essence_gauntlet/handle_atom_del(atom/deleted_atom)
	. = ..()
	if(!(deleted_atom in stored_vials))
		return
	stored_vials -= deleted_atom
	var/mob/living/wearer = get_gauntlet_user()
	if(wearer)
		refresh_combos(wearer)

/obj/item/clothing/gloves/essence_gauntlet/Exited(atom/movable/gone, direction)
	. = ..()
	if(!(gone in stored_vials))
		return
	stored_vials -= gone
	var/mob/living/wearer = get_gauntlet_user()
	if(wearer)
		refresh_combos(wearer)

/obj/item/clothing/gloves/essence_gauntlet/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return
	. = SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

	if(!is_worn_by(user))
		to_chat(user, span_warning("You must wear [src] to adjust its vials."))
		return
	if(!length(stored_vials))
		to_chat(user, span_warning("[src] has no vials to remove."))
		return

	var/list/radial_options = list()
	var/list/vial_map = list()
	for(var/i in 1 to length(stored_vials))
		var/obj/item/essence_vial/vial = stored_vials[i]
		var/label = vial_label(vial, user, i)
		var/datum/radial_menu_choice/choice = new()
		choice.name = label
		choice.image = vial_radial_image(vial)
		radial_options[label] = choice
		vial_map[label] = vial

	var/picked = show_radial_menu(
		user,
		src,
		radial_options,
		custom_check = CALLBACK(src, PROC_REF(is_worn_by), user),
		radial_slice_icon = "radial_thaum"
	)
	if(!picked || !is_worn_by(user))
		return

	var/obj/item/essence_vial/chosen = vial_map[picked]
	if(!chosen || !(chosen in stored_vials))
		return

	stored_vials -= chosen
	chosen.forceMove(get_turf(user))
	user.put_in_hands(chosen)
	to_chat(user, span_notice("You remove [chosen] from [src]."))
	refresh_combos(user)

/obj/item/clothing/gloves/essence_gauntlet/proc/is_worn_by(mob/user)
	if(!ishuman(user) || loc != user)
		return FALSE
	var/mob/living/carbon/human/human_user = user
	return human_user.get_item_by_slot(ITEM_SLOT_GLOVES) == src

/obj/item/clothing/gloves/essence_gauntlet/proc/vial_label(obj/item/essence_vial/vial, mob/user, index)
	if(!vial.contained_essence || vial.essence_amount <= 0)
		return "Empty Vial [index]"
	if(HAS_TRAIT(user, TRAIT_LEGENDARY_ALCHEMIST))
		return "[vial.contained_essence.name] — [vial.essence_amount] ligulae"
	return "Essence smelling of [vial.contained_essence.smells_like] — [vial.essence_amount] ligulae"

/obj/item/clothing/gloves/essence_gauntlet/proc/vial_radial_image(obj/item/essence_vial/vial)
	var/image/vial_image = image(icon = 'icons/roguetown/misc/alchemy.dmi', icon_state = "essence")
	if(vial.contained_essence && vial.essence_amount > 0)
		vial_image.color = vial.contained_essence.color
	return vial_image

/obj/item/clothing/gloves/essence_gauntlet/proc/refresh_combos(mob/user)
	if(!isliving(user) || !is_worn_by(user))
		return

	var/mob/living/living_user = user
	var/list/available = get_available_essence_types()
	var/list/datum/essence_combo/new_combos = get_available_essence_combos(available, user)

	for(var/datum/essence_combo/combo in active_combos.Copy())
		if(combo in new_combos)
			continue
		combo.remove(src, living_user)
		active_combos -= combo

	for(var/datum/essence_combo/combo in new_combos)
		if(combo in active_combos)
			continue
		combo.apply(src, living_user)
		active_combos += combo

/obj/item/clothing/gloves/essence_gauntlet/proc/clear_combos(mob/user)
	if(!isliving(user))
		active_combos.Cut()
		return

	var/mob/living/living_user = user
	for(var/datum/essence_combo/combo in active_combos)
		combo.remove(src, living_user)
	active_combos.Cut()

	// Remove any stale gauntlet spells left by an interrupted refresh.
	living_user.remove_spells(source = src)

/obj/item/clothing/gloves/essence_gauntlet/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	var/parent_result = ..()
	if(parent_result)
		return parent_result
	if(!istype(tool, /obj/item/essence_vial) || user.cmode)
		return NONE

	var/obj/item/essence_vial/vial = tool
	if(!vial.contained_essence || vial.essence_amount <= 0)
		to_chat(user, span_warning("[vial] is empty!"))
		return ITEM_INTERACT_BLOCKING
	if(length(stored_vials) >= max_vials)
		to_chat(user, span_warning("[src] is full!"))
		return ITEM_INTERACT_BLOCKING
	if(!user.transferItemToLoc(vial, src))
		return ITEM_INTERACT_BLOCKING

	stored_vials += vial
	to_chat(user, span_notice("You slot [vial] into [src]."))
	refresh_combos(user)
	return ITEM_INTERACT_SUCCESS

/// Returns TRUE if the gauntlet can cover the cost from vials matching the requested essence types.
/obj/item/clothing/gloves/essence_gauntlet/proc/can_consume_essence(amount, list/essence_types = null)
	if(amount <= 0)
		return TRUE

	var/available = 0
	for(var/obj/item/essence_vial/vial in stored_vials)
		if(!vial.contained_essence || vial.essence_amount <= 0)
			continue
		if(essence_types && !(vial.contained_essence.type in essence_types))
			continue
		available += vial.essence_amount
	return available >= amount

/// Consumes essence, splitting the cost across each matching essence type.
/// Returns TRUE on success without partially draining vials when the full cost is unavailable.
/obj/item/clothing/gloves/essence_gauntlet/proc/consume_essence(amount, list/essence_types = null)
	if(!can_consume_essence(amount, essence_types))
		return FALSE
	if(amount <= 0)
		return TRUE

	var/list/vials_by_essence = list()
	for(var/obj/item/essence_vial/vial in stored_vials)
		if(!vial.contained_essence || vial.essence_amount <= 0)
			continue
		var/essence_type = vial.contained_essence.type
		if(essence_types && !(essence_type in essence_types))
			continue
		if(!vials_by_essence[essence_type])
			vials_by_essence[essence_type] = list()
		vials_by_essence[essence_type] += vial

	var/remaining = amount
	var/group_count = length(vials_by_essence)
	if(group_count > 1)
		var/share = CEILING(amount / group_count, 1)
		for(var/essence_type in vials_by_essence)
			if(remaining <= 0)
				break
			var/to_draw = min(share, remaining)
			for(var/obj/item/essence_vial/vial in vials_by_essence[essence_type])
				if(to_draw <= 0)
					break
				var/drawn = min(vial.essence_amount, to_draw)
				vial.essence_amount -= drawn
				to_draw -= drawn
				remaining -= drawn
				if(vial.essence_amount <= 0)
					vial.contained_essence = null
				vial.update_appearance(UPDATE_OVERLAYS)

	if(remaining > 0)
		for(var/essence_type in vials_by_essence)
			if(remaining <= 0)
				break
			for(var/obj/item/essence_vial/vial in vials_by_essence[essence_type])
				if(remaining <= 0)
					break
				if(!vial.contained_essence || vial.essence_amount <= 0)
					continue
				var/drawn = min(vial.essence_amount, remaining)
				vial.essence_amount -= drawn
				remaining -= drawn
				if(vial.essence_amount <= 0)
					vial.contained_essence = null
				vial.update_appearance(UPDATE_OVERLAYS)

	var/mob/living/wearer = get_gauntlet_user()
	if(wearer)
		refresh_combos(wearer)
	return TRUE

/obj/item/clothing/gloves/essence_gauntlet/proc/get_available_essence_types()
	var/list/available_types = list()
	for(var/obj/item/essence_vial/vial in stored_vials)
		if(vial.contained_essence && vial.essence_amount > 0)
			available_types[vial.contained_essence.type] = TRUE
	return available_types

/obj/item/clothing/gloves/essence_gauntlet/proc/essence_failure_feedback(mob/user)
	to_chat(user, span_warning("[src] lacks sufficient essence to cast that spell!"))
	return TRUE

/obj/item/clothing/gloves/essence_gauntlet/proc/get_gauntlet_user()
	if(!ishuman(loc))
		return null
	var/mob/living/carbon/human/human_user = loc
	if(human_user.get_item_by_slot(ITEM_SLOT_GLOVES) != src)
		return null
	return human_user

/obj/item/clothing/gloves/essence_gauntlet/examine(mob/user)
	. = ..()
	. += span_notice("Vials: [length(stored_vials)]/[max_vials]")

	if(!length(stored_vials))
		. += span_notice("No vials inserted.")
		return

	for(var/obj/item/essence_vial/vial in stored_vials)
		if(!vial.contained_essence || vial.essence_amount <= 0)
			. += span_notice("- Empty")
			continue
		if(HAS_TRAIT(user, TRAIT_LEGENDARY_ALCHEMIST))
			. += span_notice("- [vial.essence_amount] ligulae of [vial.contained_essence.name].")
		else
			. += span_notice("- [vial.essence_amount] ligulae of essence smelling of [vial.contained_essence.smells_like].")

	. += span_notice("Right-click while wearing [src] to remove a vial.")
