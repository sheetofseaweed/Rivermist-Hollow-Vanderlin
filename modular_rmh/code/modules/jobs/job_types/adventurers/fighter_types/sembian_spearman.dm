/datum/attribute_holder/sheet/job/advclass/combat/adventurer_fighter/sembian_spearman
	raw_attribute_list = list(
		STAT_SPEED = 2,
		STAT_ENDURANCE = 1,
		STAT_STRENGTH = 1,
		/datum/attribute/skill/combat/polearms = 30,
		/datum/attribute/skill/combat/bows = 30,
		/datum/attribute/skill/combat/wrestling = 20,
		/datum/attribute/skill/combat/unarmed = 20,
		/datum/attribute/skill/misc/reading = 10,
		/datum/attribute/skill/misc/climbing = 30,
		/datum/attribute/skill/misc/athletics = 30
	)

/datum/job/advclass/combat/adventurer_fighter/sembian_spearman
	title = "Sembian Spearman"
	f_title = "Sembian Spearwoman"
	tutorial = "Once a soldier from the borderlands of Sembia, \
	you have taken to the road as a sellsword. Skilled with spear and bow, you strike quickly and move with purpose, \
	guarding caravans or harrying foes wherever coin—or honor—calls you."

	outfit = /datum/outfit/adventurer_fighter/sembian_spearman
	category_tags = list(CAT_ADVENTURER_FIGHTER)
	give_bank_account = TRUE

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_fighter/sembian_spearman


	traits = list(
		TRAIT_MEDIUMARMOR
	)

/datum/outfit/adventurer_fighter/sembian_spearman
	name = "Sembian Spearman"
	head = /obj/item/clothing/head/roguehood/colored/black
	mask = null
	neck = /obj/item/clothing/neck/gorget
	cloak = /obj/item/clothing/shirt/undershirt/sash/colored/sembian
	armor = /obj/item/clothing/armor/chainmail/iron
	shirt = /obj/item/clothing/armor/gambeson/light/striped
	wrists = /obj/item/clothing/wrists/bracers/leather
	gloves = /obj/item/clothing/gloves/leather
	pants = /obj/item/clothing/pants/skirt/patkilt/colored/sembian
	shoes = /obj/item/clothing/shoes/boots/leather
	backl = /obj/item/weapon/polearm/spear
	backr = /obj/item/gun/ballistic/revolver/grenadelauncher/bow
	belt = /obj/item/storage/belt/leather/black/adventurers_subclasses
	beltr = /obj/item/storage/belt/pouch/cloth/coins/poor
	beltl = /obj/item/ammo_holder/quiver/arrows
	ring = null
	l_hand = null
	r_hand = null

	backpack_contents = list(/obj/item/weapon/knife/villager = 1)
