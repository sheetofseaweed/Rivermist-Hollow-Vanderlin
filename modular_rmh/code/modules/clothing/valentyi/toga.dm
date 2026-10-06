/obj/item/clothing/shirt/toga
	slot_flags = ITEM_SLOT_SHIRT | ITEM_SLOT_ARMOR
	name = "toga"
	desc = "A pristine white toga of flowing linen, draped to evoke grace and timeless allure."
	body_parts_covered = CHEST|GROIN|VITALS
	icon = 'modular_rmh/icons/clothing/valentyi/toga.dmi'
	mob_overlay_icon = 'modular_rmh/icons/clothing/valentyi/onmob/toga.dmi'
	icon_state = "toga"
	item_state = "toga"
	var/base_icon = "toga"
	var/changed_icon = "toga"
	var/alt_wear = FALSE
	r_sleeve_status = SLEEVE_NORMAL
	l_sleeve_status = SLEEVE_NORMAL
	ignore_sleeves_code = TRUE // No sleeves, otherwise arms will be over the sprite
	nodismemsleeves = TRUE
	sleevetype = null
	sleeved = null

/obj/item/clothing/shirt/toga/attack_hand_secondary(mob/user, params)
	switch(alt_wear)
		if(FALSE)
			name = "revealing toga"
			body_parts_covered = null
			icon_state = "[changed_icon]_alt"
			to_chat(usr, span_warning("Now wearing more revealing!"))
			alt_wear = TRUE
		if(TRUE)
			name = "toga"
			body_parts_covered = CHEST|GROIN|VITALS
			icon_state = "[changed_icon]"
			to_chat(usr, span_warning("Now wearing normally!"))
			alt_wear = FALSE
	update_icon()
	if(ismob(loc))
		var/mob/L = loc
		L.update_inv_armor()
		L.update_inv_shirt()

/obj/item/clothing/shirt/toga/equipped(mob/user, slot)
	. = ..()
	if(user.gender == FEMALE)
		icon_state = "[base_icon]fem"
		changed_icon = "[base_icon]fem"
	else
		icon_state = "[base_icon]"
		changed_icon = "[base_icon]"

/obj/item/clothing/shirt/toga/build_worn_icon(age = AGE_ADULT, default_layer = 0, default_icon_file = null, isinhands = FALSE, femaleuniform = NO_FEMALE_UNIFORM, override_state = null, coom = FALSE, customi = null, sleeveindex, breast_size = 0, icon/clip_mask = null)
	// Large visible breasts get the fuller _bvl fit; no race-specific _bvl art exists.
	if(!override_state && !isinhands && coom == FEMALE_BOOB && !customi && ishuman(loc))
		var/mob/living/carbon/human/wearer = loc
		var/obj/item/organ/genitals/filling_organ/breasts/boobs = wearer.getorganslot(ORGAN_SLOT_BREASTS)
		if(boobs?.organ_size >= BREAST_SIZE_LARGE)
			override_state = "[icon_state]_f_bvl"
	return ..(age, default_layer, default_icon_file, isinhands, femaleuniform, override_state, coom, customi, sleeveindex, breast_size, clip_mask)

/datum/repeatable_crafting_recipe/sewing/toga
	name = "toga"
	output = /obj/item/clothing/shirt/toga
	requirements = list(/obj/item/natural/cloth = 2)
