/datum/attribute_holder/sheet/job/advclass/combat/adventurer_fighter/calishite_mercenary
	raw_attribute_list = list(
		STAT_STRENGTH = 1,
		STAT_ENDURANCE = 2,
		STAT_PERCEPTION = 1,
		/datum/attribute/skill/misc/swimming = 20,
		/datum/attribute/skill/misc/climbing = 30,
		/datum/attribute/skill/misc/sneaking = 30,
		/datum/attribute/skill/misc/lockpicking = 10,
		/datum/attribute/skill/combat/axesmaces = 20,
		/datum/attribute/skill/combat/bows = 20,
		/datum/attribute/skill/combat/wrestling = 20,
		/datum/attribute/skill/combat/unarmed = 20,
		/datum/attribute/skill/combat/swords = 30,
		/datum/attribute/skill/combat/polearms = 10,
		/datum/attribute/skill/combat/whipsflails = 10,
		/datum/attribute/skill/misc/reading = 10,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/combat/shields = 10
	)

/datum/job/advclass/combat/adventurer_fighter/calishite_mercenary
	title = "Calishite Mercenary"
	tutorial = "A hardened sellsword from the deserts of Calimshan, you learned early that steel and nerve matter more than honor. \
	Whether guarding caravans out of Calimport or fighting in border wars along the Calim Desert, \
	you proved your worth in blood and coin."

	outfit = /datum/outfit/adventurer_fighter/calishite_mercenary
	category_tags = list(CAT_ADVENTURER_FIGHTER)
	give_bank_account = TRUE

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_fighter/calishite_mercenary


	traits = list(
		TRAIT_MEDIUMARMOR,
		TRAIT_HEAVYARMOR,
		TRAIT_DUALWIELDER
	)

/datum/outfit/adventurer_fighter/calishite_mercenary
	name = "Calishite Mercenary"
	name = "Sample Outfit"
	head = /obj/item/clothing/head/helmet/sallet/zalad
	mask = null
	neck = /obj/item/clothing/neck/keffiyeh/colored/red
	cloak = null
	armor = /obj/item/clothing/armor/brigandine/coatplates
	shirt = /obj/item/clothing/shirt/undershirt/colored/black
	wrists = null
	gloves = /obj/item/clothing/gloves/angle
	pants = /obj/item/clothing/pants/tights/colored/red
	shoes = /obj/item/clothing/shoes/shalal
	backr = null
	backl = /obj/item/storage/backpack/satchel
	belt = /obj/item/storage/belt/leather/shalal/adventurers_subclasses
	beltr = /obj/item/weapon/sword/long/rider
	beltl = /obj/item/flashlight/flare/torch/lantern
	ring = null
	l_hand = null
	r_hand = null

	scabbards = list(/obj/item/weapon/scabbard/sword)
	backpack_contents = list(/obj/item/storage/belt/pouch/cloth/coins/poor = 1)
