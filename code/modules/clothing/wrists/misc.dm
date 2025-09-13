
/obj/item/clothing/wrists/wrappings
	name = "solar wrappings"
	desc = "Common Astratan vestments for the forearms."
	slot_flags = ITEM_SLOT_WRISTS
	icon_state = "wrappings"
	item_state = "wrappings"

/obj/item/clothing/wrists/nocwrappings
	name = "moon wrappings"
	slot_flags = ITEM_SLOT_WRISTS
	icon_state = "nocwrappings"
	item_state = "nocwrappings"

<<<<<<< HEAD
/obj/item/clothing/wrists/bracers/rare
	abstract_type = /obj/item/clothing/wrists/bracers/rare

//Aasimar hoplite bracers
=======
/obj/item/clothing/wrists/silverbracelet
	name = "silver bracelets"
	slot_flags = ITEM_SLOT_WRISTS
	icon_state = "bracelets"
	sellprice = 30

/obj/item/clothing/wrists/silverbracelet/Initialize()
	. = ..()
	enchant(/datum/enchantment/silver)

/obj/item/clothing/wrists/goldbracelet
	name = "gold bracelets"
	slot_flags = ITEM_SLOT_WRISTS
	icon_state = "braceletg"
	sellprice = 65

/obj/item/clothing/wrists/bracers/rare
	abstract_type = /obj/item/clothing/wrists/bracers/rare

>>>>>>> vanderlin/main
/obj/item/clothing/wrists/bracers/rare/hoplite
	name = "ancient bracers"
	desc = "Stalwart bronze bracers, from an age long past."
	icon_state = "aasimarwrist"
	item_state = "aasimarwrist"
	armor = list("blunt" = 70, "slash" = 70, "stab" = 70,  "piercing" = 50, "fire" = 0, "acid" = 0) // Less protection than steel
	smeltresult = /obj/item/ingot/bronze

//copper bracers

/obj/item/clothing/wrists/bracers/copper
	name = "copper bracers"
	desc = "Copper forearm guards that offer some protection while looking rather stylish."
	body_parts_covered = ARMS
	icon_state = "copperarm"
	item_state = "copperarm"
	armor = list("blunt" = 50, "slash" = 50, "stab" = 50,  "piercing" = 60, "fire" = 0, "acid" = 0)
	prevent_crits = list(BCLASS_LASHING, BCLASS_BITE, BCLASS_CUT, BCLASS_CHOP, BCLASS_BLUNT, BCLASS_TWIST)
	smeltresult = /obj/item/ingot/copper
	blocksound = PLATEHIT
	resistance_flags = FIRE_PROOF
	anvilrepair = /datum/skill/craft/armorsmithing
	sewrepair = FALSE

//Queensleeves
/obj/item/clothing/wrists/royalsleeves
	name = "royal sleeves"
	desc = "Sleeves befitting an elaborate gown."
	slot_flags = ITEM_SLOT_WRISTS
	icon_state = "royalsleeves"
	item_state = "royalsleeves"
	detail_tag = "_detail"
	detail_color = CLOTHING_SOOT_BLACK
	uses_lord_coloring = LORD_PRIMARY
