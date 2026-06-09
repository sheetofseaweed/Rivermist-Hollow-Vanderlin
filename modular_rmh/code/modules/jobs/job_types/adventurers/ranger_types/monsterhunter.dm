/datum/attribute_holder/sheet/job/advclass/combat/adventurer_ranger/monster_hunter
	raw_attribute_list = list(
		STAT_INTELLIGENCE = 1,
		STAT_STRENGTH = 1,
		STAT_PERCEPTION = 2,
		STAT_CONSTITUTION = 2,
		/datum/attribute/skill/misc/sewing = 20,
		/datum/attribute/skill/misc/medicine = 20,
		/datum/attribute/skill/combat/unarmed = 20,
		/datum/attribute/skill/combat/wrestling = 30,
		/datum/attribute/skill/misc/reading = 30,
		/datum/attribute/skill/combat/swords = 40,
		/datum/attribute/skill/combat/axesmaces = 20,
		/datum/attribute/skill/combat/crossbows = 30,
		/datum/attribute/skill/combat/whipsflails = 40,
		/datum/attribute/skill/combat/knives = 20,
		/datum/attribute/skill/misc/climbing = 20,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/craft/cooking = 10
	)

/datum/job/advclass/combat/adventurer_ranger/monster_hunter
	title = "Monster Hunter"
	tutorial = "A vigilant hunter of the unnatural, armed with silver and skill to purge evil from the realms of Faerûn."

	outfit = /datum/outfit/adventurer_ranger/monster_hunter
	category_tags = list(CAT_ADVENTURER_RANGER)
	give_bank_account = TRUE

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_ranger/monster_hunter


	traits = list(
		TRAIT_DODGEEXPERT,
		TRAIT_STEELHEARTED,
	)

/datum/outfit/adventurer_ranger/monster_hunter
	name = "Monster Hunter"
	head = /obj/item/clothing/head/helmet/leather/inquisitor
	mask = null
	neck = /obj/item/clothing/neck/chaincoif
	cloak = /obj/item/clothing/cloak/cape/puritan
	armor = /obj/item/clothing/armor/leather/splint
	shirt = /obj/item/clothing/shirt/undershirt/puritan
	wrists = /obj/item/clothing/wrists/bracers/leather
	gloves = /obj/item/clothing/gloves/angle
	pants = /obj/item/clothing/pants/tights/colored/black
	shoes = /obj/item/clothing/shoes/boots
	backr = null
	backl = /obj/item/storage/backpack/satchel
	belt = /obj/item/storage/belt/leather/adventurers_subclasses
	beltl = /obj/item/weapon/sword/rapier/silver
	beltr = /obj/item/weapon/whip/silver
	ring = null
	l_hand = null
	r_hand = null

	backpack_contents = list(/obj/item/storage/belt/pouch/cloth/coins/mid = 1)
