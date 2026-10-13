/obj/item/clothing/neck/ornateamulet/noble/triumph
	name = "ornate amulet"
	desc = "An opulent, golden necklace. When it catches the candelight, it offers a warped yet unmarred reflection of its wearer's guise."
	icon = 'modular_azurepeak/icons/clothing/neck_2.dmi'
	mob_overlay_icon = 'modular_azurepeak/icons/clothing/onmob/neck.dmi'
	sleeved = null
	sellprice = 33
	misc_flags = CRAFTING_TEST_EXCLUDE

/obj/item/clothing/neck/ornateamulet/noble
	name = "heirloom amulet"
	desc = "An ornate amulet representing a prestigious noble house."
	icon = 'modular_azurepeak/icons/clothing/neck_2.dmi'
	mob_overlay_icon = 'modular_azurepeak/icons/clothing/onmob/neck.dmi'
	sleeved = null
	var/choicename = FALSE
	slot_flags = ITEM_SLOT_NECK|ITEM_SLOT_WRISTS|ITEM_SLOT_HIP
	sellprice = 10
	misc_flags = CRAFTING_TEST_EXCLUDE

/obj/item/clothing/neck/ornateamulet/noble/attack_hand_secondary(mob/user, list/modifiers)
	if(choicename)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	var/current_time = world.time
	var/namechoice = input(user, "Input a new name", "Rename Object")
	if(namechoice)
		name = namechoice
		choicename = TRUE
	else
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	if(world.time > (current_time + 30 SECONDS))
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/item/clothing/neck/gorget/gold/king
	name = "royal golden gorget"
	icon = 'modular_azurepeak/icons/clothing/neck_2.dmi'
	mob_overlay_icon = 'modular_azurepeak/icons/clothing/onmob/neck.dmi'
	sleeved = null
	max_integrity = 10
	sellprice = 300
	misc_flags = CRAFTING_TEST_EXCLUDE
