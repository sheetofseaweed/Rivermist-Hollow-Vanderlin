/// Rucksack
/obj/item/storage/backpack/backpack/bagpack
	name = "rucksack"
	desc = "A sack tied with some rope. Can be flung over your shoulders, if it's tied shut."
	icon = 'modular_rmh/icons/clothing/storage.dmi'
	icon_state = "rucksack_untied"
	item_state = "rucksack"
	component_type = /datum/component/storage/concrete/grid/sack
	max_integrity = 100
	sewrepair = /datum/attribute/skill/misc/sewing/mending
	var/tied = FALSE

/obj/item/storage/backpack/backpack/bagpack/attack_hand_secondary(mob/user)
	tied = !tied
	to_chat(user, span_info("I [tied ? "tighten" : "loosen"] the rucksack."))
	playsound(src, 'sound/foley/equip/rummaging-01.ogg', 100)
	update_icon()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	if(tied)
		STR.click_gather = FALSE
		STR.allow_quick_gather = FALSE
		STR.allow_quick_empty = FALSE
	else
		STR.click_gather = TRUE
		STR.allow_quick_gather = TRUE
		STR.allow_quick_empty = TRUE

/obj/item/storage/backpack/backpack/bagpack/equipped(mob/living/carbon/human/user, slot)
	. = ..()
	if(!tied && (slot == ITEM_SLOT_BACK_L || slot == ITEM_SLOT_BACK_R))
		var/datum/component/storage/STR = GetComponent(/datum/component/storage)
		var/list/things = STR.contents()
		if(length(things))
			visible_message(span_warning("The loose bag empties as it is swung around [user]'s shoulder!"))
			STR.quick_empty(user)

/obj/item/storage/backpack/backpack/bagpack/update_icon()
	. = ..()
	if(tied)
		icon_state = "rucksack_tied_sling"
	else
		icon_state = "rucksack_untied"

///////////////////////////////////////////////////////////////

/// Backpack
/obj/item/storage/backpack/backpack/longhike
	name = "longhike backpack"
	desc = "That bulky backpack is surely designed for long-range hikes. It even has gears for bedroll to attach."
	icon_state = "backpack_deluxe"
	item_state = "backpack"
	icon = 'modular_rmh/icons/clothing/storage.dmi'
	var/obj/item/sleepingbag/deluxe/backpack_bedroll
	var/bedroll_spawn = FALSE

/obj/item/storage/backpack/backpack/longhike/Initialize()
	. = ..()
	if(bedroll_spawn)
		add_bedroll(new /obj/item/sleepingbag/deluxe(src), null)
		update_appearance(UPDATE_OVERLAYS)

/obj/item/storage/backpack/backpack/longhike/with_bedroll
	bedroll_spawn = TRUE

/obj/item/storage/backpack/backpack/longhike/MiddleClick(mob/user, list/modifiers)
	if(backpack_bedroll)
		remove_bedroll(user)
	..()

/////////////////////////////

/obj/item/storage/backpack/backpack/longhike/worn_overlays(mutable_appearance/standing, isinhands = FALSE, icon_file = icon, dummy_block = FALSE)
	. = ..()
	if(!isinhands && backpack_bedroll)
		var/mutable_appearance/bedroll_overlay_mob = mutable_appearance('modular_rmh/icons/clothing/onmob/back_l.dmi', "[icon_state]_bedroll_overlay")
		. += bedroll_overlay_mob

/obj/item/storage/backpack/backpack/longhike/update_overlays()
	. = ..()
	if(backpack_bedroll)
		var/mutable_appearance/bedroll_overlay_item = mutable_appearance(icon, "[icon_state]_bedroll_overlay")
		. += bedroll_overlay_item

/// Proc for handling script + icon changes of bedroll being added on backpack
/obj/item/storage/backpack/backpack/longhike/proc/add_bedroll(obj/item/bedroll, mob/living/M)
	if(backpack_bedroll)
		if(M)
			to_chat(M, span_red("The [name] already have a bedroll on it!"))
		return
	backpack_bedroll = bedroll
	item_weight += backpack_bedroll.item_weight
	bedroll.moveToNullspace() // To avoid bugs like getting bedroll with inventory frame. Still accessable via middle click

	update_appearance(UPDATE_OVERLAYS)
	if(M)
		M.update_inv_back()

/// Same as add_bedroll() but opposite one
/obj/item/storage/backpack/backpack/longhike/proc/remove_bedroll(mob/living/M)
	if(!backpack_bedroll)
		return
	M.put_in_hands(backpack_bedroll)
	item_weight -= backpack_bedroll.item_weight
	backpack_bedroll = null

	update_appearance(UPDATE_OVERLAYS)
	if(M)
		M.update_inv_back()

///////////////////////////////////////////////////////////////
