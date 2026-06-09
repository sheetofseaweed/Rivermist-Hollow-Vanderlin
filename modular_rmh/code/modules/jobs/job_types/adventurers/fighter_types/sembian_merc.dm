/datum/attribute_holder/sheet/job/advclass/combat/adventurer_fighter/sembian_merc
	raw_attribute_list = list(
		STAT_STRENGTH = 2,
		STAT_ENDURANCE = 2,
		STAT_CONSTITUTION = 2,
		STAT_SPEED = -1,
		/datum/attribute/skill/combat/swords = 30,
		/datum/attribute/skill/combat/axesmaces = 20,
		/datum/attribute/skill/combat/wrestling = 20,
		/datum/attribute/skill/combat/unarmed = 30,
		/datum/attribute/skill/misc/reading = 10,
		/datum/attribute/skill/misc/climbing = 30,
		/datum/attribute/skill/misc/athletics = 30
	)

/datum/job/advclass/combat/adventurer_fighter/sembian_merc
	title = "Sembian Mercenary"
	tutorial = "A claymore-wielding mercenary from the nation of Sembia, \
	fleeing internal strife, they sell their sword to the highest bidder, \
	leading cohorts of trained retainers into battle across the Sword Coast."

	outfit = /datum/outfit/adventurer_fighter/sembian_merc
	category_tags = list(CAT_ADVENTURER_FIGHTER)
	give_bank_account = TRUE

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_fighter/sembian_merc


	traits = list(
		TRAIT_HEAVYARMOR
	)

/datum/outfit/adventurer_fighter/sembian_merc
	name = "Sembian Mercenary"
	head = /obj/item/clothing/head/helmet/gallowglass
	mask = null
	neck = /obj/item/clothing/neck/chaincoif/iron
	cloak = /obj/item/clothing/shirt/undershirt/sash/colored/sembian
	armor = /obj/item/clothing/armor/chainmail/iron
	shirt = /obj/item/clothing/armor/gambeson/light/striped
	wrists = /obj/item/clothing/wrists/bracers/leather
	gloves = /obj/item/clothing/gloves/leather
	pants = /obj/item/clothing/pants/skirt/patkilt/colored/sembian
	shoes = /obj/item/clothing/shoes/boots/leather
	backr = /obj/item/storage/backpack/satchel
	backl = /obj/item/weapon/sword/long/greatsword/claymore
	belt = /obj/item/storage/belt/leather/black/adventurers_subclasses
	beltl = /obj/item/weapon/mace/cudgel
	beltr = /obj/item/storage/belt/pouch/cloth/coins/poor
	ring = null
	l_hand = null
	r_hand = null
