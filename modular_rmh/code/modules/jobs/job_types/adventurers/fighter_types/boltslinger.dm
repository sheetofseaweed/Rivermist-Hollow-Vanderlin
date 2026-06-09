/datum/attribute_holder/sheet/job/advclass/combat/adventurer_fighter/boltslinger
	raw_attribute_list = list(
		STAT_PERCEPTION = 2,
		STAT_ENDURANCE = 1,
		STAT_STRENGTH = 1,
		/datum/attribute/skill/combat/knives = 20,
		/datum/attribute/skill/combat/swords = 30,
		/datum/attribute/skill/combat/polearms = 10,
		/datum/attribute/skill/combat/crossbows = 30,
		/datum/attribute/skill/craft/tanning = 10,
		/datum/attribute/skill/combat/wrestling = 10,
		/datum/attribute/skill/combat/unarmed = 10,
		/datum/attribute/skill/craft/crafting = 10,
		/datum/attribute/skill/misc/swimming = 20,
		/datum/attribute/skill/misc/climbing = 20,
		/datum/attribute/skill/misc/riding = 30,
		/datum/attribute/skill/misc/sewing = 30,
		/datum/attribute/skill/misc/medicine = 20,
		/datum/attribute/skill/craft/cooking = 10,
		/datum/attribute/skill/misc/reading = 10,
		/datum/attribute/skill/misc/athletics = 30
	)

/datum/job/advclass/combat/adventurer_fighter/boltslinger
	title = "Boltslinger"
	tutorial = "A mercenary who has honed the deadly art of crossbows across the Sword Coast, \
	the Boltmaster strikes from afar with precision, claiming coin and leaving corpses in their wake."

	outfit = /datum/outfit/adventurer_fighter/boltslinger
	category_tags = list(CAT_ADVENTURER_FIGHTER)
	give_bank_account = TRUE

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_fighter/boltslinger


	traits = list(
		TRAIT_MEDIUMARMOR
	)

/datum/job/advclass/combat/adventurer_fighter/boltslinger/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()

/datum/outfit/adventurer_fighter/boltslinger
	name = "Boltslinger"
	head = /obj/item/clothing/head/helmet/sallet
	mask = null
	neck = /obj/item/clothing/neck/chaincoif
	cloak = /obj/item/clothing/cloak/half
	armor = /obj/item/clothing/armor/cuirass
	shirt = /obj/item/clothing/shirt/undershirt/colored/black
	wrists = null
	gloves = /obj/item/clothing/gloves/angle
	pants = /obj/item/clothing/pants/tights/colored/black
	shoes = /obj/item/clothing/shoes/boots/leather
	backr = /obj/item/gun/ballistic/revolver/grenadelauncher/crossbow
	backl = /obj/item/storage/backpack/satchel
	belt = /obj/item/storage/belt/leather/adventurers_subclasses
	beltl = /obj/item/ammo_holder/quiver/bolts
	beltr = /obj/item/weapon/sword/iron
	ring = null
	l_hand = null
	r_hand = null
	scabbards = list(/obj/item/weapon/scabbard/sword)

	backpack_contents = list(
		/obj/item/storage/belt/pouch/cloth/coins/poor = 1,
		/obj/item/weapon/knife/hunting = 1
	)
