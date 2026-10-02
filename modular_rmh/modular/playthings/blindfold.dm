// Blindfolds: cloth over the eyes. The sheer one looks the same but lets its wearer peek.

/obj/item/clothing/face/blindfold
	name = "blindfold"
	desc = "A strip of dark cloth tied around the eyes to block vision."
	icon = 'icons/obj/clothing/glasses.dmi'
	mob_overlay_icon = 'icons/mob/clothing/eyes.dmi'
	icon_state = "blindfold"
	item_state = "blindfold"
	body_parts_covered = EYES
	resistance_flags = FLAMMABLE
	strip_delay = 2 SECONDS
	equip_delay_other = 3 SECONDS
	salvage_result = /obj/item/natural/cloth
	sellprice = 3
	/// Whether the cloth actually blocks sight.
	var/blocks_sight = TRUE

/obj/item/clothing/face/blindfold/equipped(mob/user, slot, initial = FALSE)
	. = ..()
	if(!isliving(user))
		return
	var/mob/living/wearer = user
	if(blocks_sight && (slot & ITEM_SLOT_MASK))
		wearer.become_blind("blindfold_[REF(src)]")
	else
		wearer.cure_blind("blindfold_[REF(src)]")

/obj/item/clothing/face/blindfold/dropped(mob/user, silent = FALSE)
	. = ..()
	if(isliving(user))
		var/mob/living/wearer = user
		wearer.cure_blind("blindfold_[REF(src)]")

/obj/item/clothing/face/blindfold/white
	desc = "A strip of pale cloth tied around the eyes to block vision."
	icon_state = "blindfoldwhite"
	item_state = "blindfoldwhite"

/obj/item/clothing/face/blindfold/sheer
	desc = "A strip of dark cloth tied around the eyes to block vision."
	blocks_sight = FALSE

/obj/item/clothing/face/blindfold/sheer/examine(mob/user)
	. = ..()
	if(user.is_holding(src) || loc == user)
		. += span_notice("The weave is thin enough to see through, and nobody looking at it would know.")

/datum/repeatable_crafting_recipe/sewing/blindfold
	name = "blindfold"
	output = /obj/item/clothing/face/blindfold
	category = "Face"
	craftdiff = 0

/datum/repeatable_crafting_recipe/sewing/blindfold/white
	name = "blindfold (white)"
	output = /obj/item/clothing/face/blindfold/white

/datum/repeatable_crafting_recipe/sewing/blindfold/sheer
	name = "blindfold (sheer)"
	output = /obj/item/clothing/face/blindfold/sheer
	craftdiff = 1
