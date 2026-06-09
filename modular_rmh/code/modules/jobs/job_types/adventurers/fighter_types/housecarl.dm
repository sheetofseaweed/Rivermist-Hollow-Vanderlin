/datum/attribute_holder/sheet/job/advclass/combat/adventurer_fighter/housecarl
	raw_attribute_list = list(
		STAT_STRENGTH = 2,
		STAT_CONSTITUTION = 2,
		STAT_ENDURANCE = 2,
		STAT_PERCEPTION = 1,
		STAT_INTELLIGENCE = -1,
		STAT_SPEED = -2,
		/datum/attribute/skill/combat/axesmaces = 30,
		/datum/attribute/skill/misc/swimming = 20,
		/datum/attribute/skill/misc/climbing = 30,
		/datum/attribute/skill/combat/wrestling = 20,
		/datum/attribute/skill/combat/unarmed = 30,
		/datum/attribute/skill/combat/swords = 20,
		/datum/attribute/skill/combat/shields = 30,
		/datum/attribute/skill/misc/reading = 10,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/misc/medicine = 20
	)

/datum/job/advclass/combat/adventurer_fighter/housecarl
	title = "Housecarl"
	tutorial = "Once sworn to guard the lords of a Sword Coast \
	hold or a merchant prince in Waterdeep, you now travel as a freelance protector. \
	From escorting caravans along the High Road to standing watch in crowded city streets, \
	your skill with sword, shield, and polearm is sought wherever coin can be earned."

	outfit = /datum/outfit/adventurer_fighter/housecarl
	category_tags = list(CAT_ADVENTURER_FIGHTER)
	give_bank_account = TRUE

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_fighter/housecarl


	traits = list(
		TRAIT_MEDIUMARMOR,
	)

/datum/outfit/adventurer_fighter/housecarl
	name = "Housecarl"
	head = /obj/item/clothing/head/helmet/nasal
	mask = null
	neck = /obj/item/clothing/neck/highcollier/iron
	cloak = /obj/item/clothing/cloak/raincloak/furcloak/colored/brown
	armor = /obj/item/clothing/armor/chainmail/hauberk/iron
	shirt = /obj/item/clothing/armor/gambeson
	wrists = /obj/item/clothing/wrists/bracers/leather
	gloves = /obj/item/clothing/gloves/leather/black
	pants = /obj/item/clothing/pants/trou/leather
	shoes = /obj/item/clothing/shoes/boots
	backr = /obj/item/weapon/polearm/halberd/bardiche/woodcutter
	backl = /obj/item/weapon/shield/wood
	belt = /obj/item/storage/belt/leather/black/adventurers_subclasses
	beltr = /obj/item/storage/belt/pouch/cloth/coins/poor
	beltl = /obj/item/weapon/sword/short/iron
	ring = null
	l_hand = null
	r_hand = null
