/obj/item/clothing/head/twilight_hammerhold_hat
	name = "kokoshnik"
	desc = ""
	icon = 'modular_twilightaxis/icons/clothing/head.dmi'
	mob_overlay_icon = 'modular_twilightaxis/icons/clothing/onmob/head_48.dmi'
	sleeved = null
	icon_state = "white_mage_headwear"
	flags_inv = HIDEEARS
	var/hammerhold_colors = list("white", "blue")
	var/hammerhold_variants = null
	var/picked = FALSE
	var/hammerhold_final_icon = null
	misc_flags = CRAFTING_TEST_EXCLUDE

/obj/item/clothing/head/twilight_hammerhold_hat/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return
	if(!picked)
		var/choiceC = input(user, "Choose a color.", "Mithral Hall colors") as anything in hammerhold_colors
		if(choiceC == "white")
			icon_state = "white_mage_headwear"
		if(choiceC == "blue")
			icon_state = "blue_mage_headwear"
		update_appearance()
		if(loc == user && ishuman(user))
			var/mob/living/carbon/H = user
			H.update_inv_head()
		if(alert("Are you pleased with your kokoshnik?", "Kokoshnik", "Yes", "No") != "Yes")
			icon_state = "white_mage_headwear"
			update_appearance()
			if(loc == user && ishuman(user))
				var/mob/living/carbon/H = user
				H.update_inv_head()
			return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
		picked = TRUE
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/item/clothing/head/twilight_hammerhold_hat/attack_hand_secondary(mob/user, list/modifiers)
	if(!picked)
		var/choiceV = input(user, "Choose a variant.", "Mithral Hall colors") as anything in hammerhold_variants
		if(choiceV == "a")
			icon_state = "headwear_a"
			hammerhold_final_icon = "headwear_a"
		if(choiceV == "b")
			icon_state = "headwear_b"
			hammerhold_final_icon = "headwear_b"
		update_appearance()
		if(loc == user && ishuman(user))
			var/mob/living/carbon/H = user
			H.update_inv_head()
		if(alert("Are you pleased with your hat?", "hat", "Yes", "No") != "Yes")
			icon_state = "headwear_a"
			hammerhold_final_icon = "headwear_a"
			update_appearance()
			if(loc == user && ishuman(user))
				var/mob/living/carbon/H = user
				H.update_inv_head()
			return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
		picked = TRUE
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/item/clothing/head/twilight_hammerhold_hat/equipped(mob/user, slot, initial = FALSE)
	. = ..()
	if(hammerhold_final_icon)
		icon_state = hammerhold_final_icon
		item_state = hammerhold_final_icon
		update_appearance()

/obj/item/clothing/head/twilight_hammerhold_hat/dropped(mob/user, silent = FALSE)
	. = ..()
	if(hammerhold_final_icon)
		icon_state = hammerhold_final_icon
		item_state = hammerhold_final_icon
		update_appearance()

/obj/item/clothing/head/twilight_hammerhold_hat/peasant
	name = "Mithral Hall hat"
	desc = ""
	icon = 'modular_twilightaxis/icons/clothing/head.dmi'
	mob_overlay_icon = 'modular_twilightaxis/icons/clothing/onmob/head_48.dmi'
	sleeved = null
	icon_state = "headwear_a"
	flags_inv = HIDEEARS
	hammerhold_colors = null
	hammerhold_variants = list("a", "b")
	picked = FALSE
	misc_flags = CRAFTING_TEST_EXCLUDE
