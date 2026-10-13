/obj/item/clothing/armor/basiceast/yohei
	name = "black dobo robe"
	desc = "A dark dobo robe with reinforced leather inlays. Offers decent protection while allowing for ease of movement."
	icon = 'modular_twilightaxis/icons/clothing/armor.dmi'
	mob_overlay_icon = 'modular_twilightaxis/icons/clothing/onmob/armor.dmi'
	sleeved = 'modular_twilightaxis/icons/clothing/onmob/helpers/sleeves_armor_2.dmi'
	icon_state = "yoheisuit"
	armor_type = /datum/armor/brigandine
	max_integrity = ARMOR_INT_CHEST_LIGHT_MASTER + 25
	misc_flags = CRAFTING_TEST_EXCLUDE

/obj/item/clothing/armor/brigandine/harayoroi
	name = "hara-yoroi cuirass"
	desc = "A practical lightweight cuirass favored by disciplined mercenaries and provincial retainers of Kozakura. Layered blacksteel-coated steel plates to dull the shine of war, offer reliable protection without the burden of full battle harness."
	icon = 'modular_twilightaxis/icons/clothing/armor.dmi'
	mob_overlay_icon = 'modular_twilightaxis/icons/clothing/onmob/armor.dmi'
	sleeved = 'modular_twilightaxis/icons/clothing/onmob/helpers/sleeves_armor_2.dmi'
	icon_state = "kazengunlight"
	item_state = "kazengunlight"
	boobed = TRUE
	detail_tag = "_detail"
	color = "#FFFFFF"
	detail_color = "#FFFFFF"
	max_integrity = ARMOR_INT_CHEST_PLATE_BRIGANDINE + 25
	var/picked = FALSE
	dyeable = TRUE
	misc_flags = CRAFTING_TEST_EXCLUDE

/obj/item/clothing/armor/brigandine/harayoroi/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return
	if(!picked)
		var/choice = input(user, "Choose a color.", "Uniform colors") as anything in COLOR_MAP
		var/playerchoice = COLOR_MAP[choice]
		picked = TRUE
		detail_color = playerchoice
		detail_tag = "_detail"
		update_appearance()
		if(loc == user && ishuman(user))
			var/mob/living/carbon/H = user
			H.update_inv_armor()
			H.update_appearance()
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
