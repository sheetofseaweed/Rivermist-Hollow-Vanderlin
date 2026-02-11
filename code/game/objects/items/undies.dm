/obj/item/clothing/undies
	name = "briefs"
	desc = "An absolute necessity."
	icon = 'modular_rmh/icons/clothing/underwear.dmi'
	mob_overlay_icon = 'modular_rmh/icons/clothing/onmob/underwear.dmi'
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
	var/icon_state_base
	boob_sized = FALSE
	sewrepair = TRUE
	salvage_result = /obj/item/natural/cloth
	slot_flags = ITEM_SLOT_MOUTH | ITEM_SLOT_UNDER_BOTTOM
	muteinmouth = TRUE
	flags_inv = HIDECROTCH

/obj/item/clothing/undies/Initialize(mapload, ...)
	. = ..()
	icon_state_base = icon_state

/obj/item/clothing/undies/attack(mob/M, mob/user, def_zone)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(!H.underwear)
			if(!get_location_accessible(H, BODY_ZONE_PRECISE_GROIN))
				return
			user.visible_message(span_notice("[user] tries to put [src] on [H]..."))
			if(do_after(user, 50, target = H))
				H.equip_to_slot_if_possible(src, ITEM_SLOT_UNDER_BOTTOM, disable_warning = TRUE)

/obj/item/clothing/undies/equipped(mob/living/carbon/user, slot)
	. = ..()
	if(user.mouth == src)
		flags_inv = null
		icon_state = null
		user.update_body()
		user.update_body_parts()

/obj/item/clothing/undies/dropped(mob/user)
	. = ..()
	flags_inv = HIDECROTCH
	icon_state = icon_state_base

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
