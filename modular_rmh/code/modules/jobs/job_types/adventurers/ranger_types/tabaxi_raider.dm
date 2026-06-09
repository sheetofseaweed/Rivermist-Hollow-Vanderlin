/datum/attribute_holder/sheet/job/advclass/combat/adventurer_ranger/tabaxi_raider
	raw_attribute_list = list(
		STAT_STRENGTH = 1,
		STAT_PERCEPTION = 2,
		STAT_SPEED = 1,
		STAT_ENDURANCE = 1,
		/datum/attribute/skill/combat/knives = 20,
		/datum/attribute/skill/combat/swords = 30,
		/datum/attribute/skill/combat/crossbows = 20,
		/datum/attribute/skill/combat/bows = 30,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/misc/riding = 30,
		/datum/attribute/skill/labor/taming = 20,
		/datum/attribute/skill/combat/wrestling = 20,
		/datum/attribute/skill/combat/unarmed = 20,
		/datum/attribute/skill/misc/climbing = 10,
		/datum/attribute/skill/misc/reading = 10,
		/datum/attribute/skill/misc/sneaking = 20,
		/datum/attribute/skill/craft/traps = 10
	)

/datum/job/advclass/combat/adventurer_ranger/tabaxi_raider
	title = "Tabaxi Desert Raider"
	tutorial = "Hailing from the sun-baked dunes near Chult’s western fringe, \
	you are a Tabaxi raider. Swift of foot and sharp of eye, you and your kin live by the bow and sabre, \
	striking where settlements and caravans are weakest, and vanishing before retaliation can find you."

	allowed_races = list(SPEC_ID_RAKSHARI)
	outfit = /datum/outfit/adventurer_ranger/tabaxi_raider
	category_tags = list(CAT_ADVENTURER_RANGER)
	give_bank_account = TRUE

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_ranger/tabaxi_raider


	traits = list(
		TRAIT_DODGEEXPERT,
		TRAIT_STEELHEARTED
	)

/datum/outfit/adventurer_ranger/tabaxi_raider
	name = "Tabaxi Desert Raider"
	head = /obj/item/clothing/neck/keffiyeh/colored/uncolored
	mask = null
	neck = null
	cloak = null
	armor = /obj/item/clothing/armor/leather/splint
	shirt = /obj/item/clothing/shirt/undershirt/colored/uncolored
	wrists = /obj/item/rope/chain //Seems fitting for slavers
	gloves = /obj/item/clothing/gloves/angle
	pants = /obj/item/clothing/pants/trou/leather
	shoes = /obj/item/clothing/shoes/ridingboots
	backr = /obj/item/storage/backpack/satchel
	backl = /obj/item/gun/ballistic/revolver/grenadelauncher/bow/short
	belt = /obj/item/storage/belt/leather/shalal/adventurers_subclasses
	beltl = /obj/item/ammo_holder/quiver/arrows
	beltr = /obj/item/weapon/sword/sabre
	ring = null
	l_hand = null
	r_hand = null

	scabbards = list(/obj/item/weapon/scabbard/sword)
	backpack_contents = list(
		/obj/item/storage/belt/pouch/cloth/coins/poor = 1,
		/obj/item/weapon/knife/dagger = 1
	)
