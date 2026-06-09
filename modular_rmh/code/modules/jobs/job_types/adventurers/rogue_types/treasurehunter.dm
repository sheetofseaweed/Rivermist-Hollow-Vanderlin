/datum/attribute_holder/sheet/job/advclass/combat/adventurer_rogue/treasurehunter
	raw_attribute_list = list(
		STAT_STRENGTH = 1,
		STAT_PERCEPTION = 2,
		STAT_INTELLIGENCE = 1,
		STAT_ENDURANCE = 2,
		STAT_SPEED = 1,
		STAT_FORTUNE = -1,
		/datum/attribute/skill/misc/medicine = 10,
		/datum/attribute/skill/combat/whipsflails = 30,
		/datum/attribute/skill/combat/wrestling = 10,
		/datum/attribute/skill/combat/knives = 20,
		/datum/attribute/skill/combat/unarmed = 10,
		/datum/attribute/skill/craft/crafting = 10,
		/datum/attribute/skill/craft/cooking = 10,
		/datum/attribute/skill/misc/swimming = 30,
		/datum/attribute/skill/misc/climbing = 50,
		/datum/attribute/skill/misc/sewing = 10,
		/datum/attribute/skill/misc/lockpicking = 20,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/misc/reading = 10
	)

/datum/job/advclass/combat/adventurer_rogue/treasurehunter
	title = "Treasure Hunter"
	tutorial = "A tomb delver who robs the dead and survives by cunning, grit, and a strong stomach."

	outfit = /datum/outfit/adventurer_rogue/treasurehunter
	category_tags = list(CAT_ADVENTURER_ROGUE)
	give_bank_account = TRUE

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_rogue/treasurehunter


	traits = list(
		TRAIT_DEADNOSE,
		TRAIT_DODGEEXPERT,
		TRAIT_GRAVEROBBER,
	)

/datum/outfit/adventurer_rogue/treasurehunter
	name = "Treasure Hunter"
	head = /obj/item/clothing/head/explorer
	mask = null
	neck = /obj/item/storage/belt/pouch/cloth
	cloak = /obj/item/clothing/cloak/raincloak/colored/mortus
	armor = /obj/item/clothing/armor/gambeson/explorer
	shirt = /obj/item/clothing/shirt/undershirt/colored/black
	wrists = null
	gloves = /obj/item/clothing/gloves/fingerless
	pants = /obj/item/clothing/pants/trou/leather/explorer
	shoes = /obj/item/clothing/shoes/boots/leather
	backr = /obj/item/weapon/shovel
	backl = /obj/item/storage/backpack/backpack/longhike/with_bedroll
	belt = /obj/item/storage/belt/leather/adventurers_subclasses
	beltl = /obj/item/weapon/whip // You know why.
	beltr = /obj/item/flashlight/flare/torch/lantern
	ring = null
	l_hand = null
	r_hand = null

	backpack_contents = list(
		/obj/item/weapon/pick = 1,
		/obj/item/weapon/knife/dagger = 1,
		/obj/item/lockpickring/mundane = 1
	)
