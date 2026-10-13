/obj/item/clothing/gloves/plate/nightmare
	name = "nightmare tears gauntlets"
	desc = ""
	icon = 'modular_twilightaxis/icons/clothing/nightmare_set.dmi'
	mob_overlay_icon = 'modular_twilightaxis/icons/clothing/onmob/nightmare_set.dmi'
	sleeved = 'modular_twilightaxis/icons/clothing/onmob/nightmare_set.dmi'
	icon_state = "nightmare_gauntlets"
	item_state = "nightmare_gauntlets"
	misc_flags = CRAFTING_TEST_EXCLUDE

/obj/item/clothing/gloves/plate/baotha_ta
	name = "saccharine gauntlets"
	desc = "Plated gauntlets lacquered in sickly pink. It is better to numb the regret than to face the guilt - or so whisper the cultists of Blissara."
	icon = 'modular_twilightaxis/icons/clothing/gloves_2.dmi'
	mob_overlay_icon = 'modular_twilightaxis/icons/clothing/onmob/gloves.dmi'
	sleeved = 'modular_twilightaxis/icons/clothing/onmob/gloves.dmi'
	icon_state = "baothagloves"
	item_state = "baothagloves"
	max_integrity = ARMOR_INT_SIDE_ANTAG - 250
	armor_class = AC_LIGHT
	misc_flags = CRAFTING_TEST_EXCLUDE

/obj/item/clothing/gloves/plate/baotha_ta/Initialize()
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, CURSED_ITEM_TRAIT)

/obj/item/clothing/gloves/plate/baotha_ta/dropped(mob/user, silent = FALSE)
	. = ..()
	if(QDELETED(src))
		return
	qdel(src)

/obj/item/clothing/gloves/plate/blacksteel/legate
	name = "legate's plate gauntlets"
	desc = "Blacksteel gauntlets richly adorned with gold. A simple oath is engraved on the inside: 'By my word and your hands, every foe shall be cast down.' </br>\u200e </br>Who truly makes history - the one who gives the order, or the one who stains their hands with blood? Both shall answer for it before eternity."
	icon = 'modular_twilightaxis/icons/clothing/gloves.dmi'
	mob_overlay_icon = 'modular_twilightaxis/icons/clothing/onmob/gloves_2.dmi'
	sleeved = 'modular_twilightaxis/icons/clothing/onmob/gloves.dmi'
	icon_state = "lplategloves"
	item_state = "lplategloves"

/obj/item/clothing/gloves/plate/legion
	name = "Shoonite manica"
	desc = "Segmented steel guards crafted to shield the arms. Once the armour of pit-fighters and gladiators in Calimport's arenas, it found new purpose among soldiers who needed protection against the great two-handed swords of northern raiders."
	icon = 'modular_twilightaxis/icons/clothing/gloves.dmi'
	mob_overlay_icon = 'modular_twilightaxis/icons/clothing/onmob/gloves_2.dmi'
	sleeved = 'modular_twilightaxis/icons/clothing/onmob/gloves.dmi'
	icon_state = "legiongloves"
	misc_flags = CRAFTING_TEST_EXCLUDE

/obj/item/clothing/gloves/plate/zizo/bloodraider
	name = "raider's gauntlets"
	desc = "Clawed plate gauntlets, capable of tormenting N'wah with their tips."
	icon = 'modular_twilightaxis/icons/clothing/bloodraider.dmi'
	mob_overlay_icon = 'modular_twilightaxis/icons/clothing/onmob/bloodraider.dmi'
	sleeved = 'modular_twilightaxis/icons/clothing/onmob/gloves.dmi'
	icon_state = "bloodgauntlets"
	item_state = "bloodgauntlets"
	armor_class = AC_LIGHT
	misc_flags = CRAFTING_TEST_EXCLUDE
