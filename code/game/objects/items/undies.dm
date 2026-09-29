/obj/item/clothing/undies
	name = "briefs"
	desc = "An absolute necessity."
	icon = 'modular_rmh/icons/clothing/underwear/underwear.dmi'
	mob_overlay_icon = 'modular_rmh/icons/clothing/underwear/onmob/underwear.dmi'
	icon_state = "briefs"
	item_state = "briefs"
	w_class = WEIGHT_CLASS_TINY
	resistance_flags = FLAMMABLE
	obj_flags = CAN_BE_HIT
	break_sound = 'sound/foley/cloth_rip.ogg'
	blade_dulling = DULLING_CUT
	max_integrity = 200
	integrity_failure = 0.1
	drop_sound = 'sound/foley/dropsound/cloth_drop.ogg'
	var/covers_breasts = FALSE
	var/mob_overlay_icon_base
	boob_sized = FALSE
	sewrepair = /datum/attribute/skill/misc/sewing/mending
	salvage_result = /obj/item/natural/cloth
	slot_flags = ITEM_SLOT_MOUTH | ITEM_SLOT_UNDER_BOTTOM
	muteinmouth = TRUE
	flags_inv = HIDECROTCH

/obj/item/clothing/undies/Initialize(mapload, ...)
	. = ..()
	mob_overlay_icon_base = mob_overlay_icon

/obj/item/clothing/undies/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!ishuman(interacting_with) || (user.zone_selected == BODY_ZONE_PRECISE_MOUTH && has_soaked_fluid()))
		return ..()

	var/mob/living/carbon/human/target = interacting_with
	if(target.underwear || !get_location_accessible(target, BODY_ZONE_PRECISE_GROIN))
		return ITEM_INTERACT_BLOCKING

	user.visible_message(span_notice("[user] tries to put [src] on [target]..."))
	if(!do_after(user, 5 SECONDS, target = target))
		return ITEM_INTERACT_BLOCKING

	if(!target.equip_to_slot_if_possible(src, ITEM_SLOT_UNDER_BOTTOM, disable_warning = TRUE))
		return ITEM_INTERACT_BLOCKING

	return ITEM_INTERACT_SUCCESS

/obj/item/clothing/undies/equipped(mob/living/carbon/user, slot)
	. = ..()
	if(user.mouth == src)
		flags_inv = null
		mob_overlay_icon = null
		user.update_body()
		user.update_inv_mouth()
	else
		flags_inv = HIDECROTCH
		mob_overlay_icon = mob_overlay_icon_base

/obj/item/clothing/undies/dropped(mob/user)
	. = ..()
	flags_inv = HIDECROTCH
	mob_overlay_icon = mob_overlay_icon_base

/// TRUE when this worn item hides the organ in [slot], even genitals set to show through clothes.
/obj/item/clothing/undies/proc/hides_organ_slot(slot)
	return FALSE

/obj/item/clothing/undies/bikini_bottom
	name = "bikini bottom"
	desc = "A perfect bathing garment."
	icon_state = "bikini_bottom"
	item_state = "bikini_bottom"
	gendered = TRUE

/obj/item/clothing/undies/panties
	name = "panties"
	icon_state = "panties"
	item_state = "panties"
	gendered = FALSE

/obj/item/clothing/undies/braies
	name = "braies"
	desc = "A pair of linen underpants; Faerun's most common." // RMH
	icon_state = "braies"
	item_state = "braies"
	flags_inv = HIDEBUTT|HIDECROTCH

/obj/item/clothing/undies/thong
	name = "thong"
	icon_state = "thong"
	item_state = "thong"
	gendered = TRUE

// Craft

/datum/repeatable_crafting_recipe/sewing/undies
	name = "briefs"
	output = /obj/item/clothing/undies
	requirements = list(/obj/item/natural/cloth = 1,
				/obj/item/natural/fibers = 1)
	craftdiff = 2

/datum/repeatable_crafting_recipe/sewing/undies/thong
	name = "thong"
	output = /obj/item/clothing/undies/thong
	requirements = list(/obj/item/natural/cloth = 1,
				/obj/item/natural/fibers = 2)

/datum/repeatable_crafting_recipe/sewing/bikini_bottom
	name = "bikini bottom"
	output = /obj/item/clothing/undies/bikini_bottom
	requirements = list(/obj/item/natural/cloth = 2,
				/obj/item/natural/fibers = 1)
	craftdiff = 2

/datum/repeatable_crafting_recipe/sewing/panties
	name = "panties"
	output = /obj/item/clothing/undies/panties
	requirements = list(/obj/item/natural/cloth = 1)
	craftdiff = 2

/datum/repeatable_crafting_recipe/sewing/braies
	name = "braies"
	output = /obj/item/clothing/undies/braies
	requirements = list(/obj/item/natural/cloth = 1)
	craftdiff = 2
