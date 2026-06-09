/datum/attribute_holder/sheet/job/advclass/councilor/first_mate
	raw_attribute_list = list(
		STAT_STRENGTH = 2,
		STAT_ENDURANCE = 3,
		STAT_CONSTITUTION = 2,
		STAT_PERCEPTION = 3,
		STAT_INTELLIGENCE = 2,
		STAT_SPEED = 2,
		/datum/attribute/skill/combat/swords = 30,
		/datum/attribute/skill/combat/axesmaces = 20,
		/datum/attribute/skill/combat/shields = 20,
		/datum/attribute/skill/combat/wrestling = 30,
		/datum/attribute/skill/combat/unarmed = 20,
		/datum/attribute/skill/combat/bows = 20,
		/datum/attribute/skill/combat/crossbows = 20,
		/datum/attribute/skill/combat/firearms = 20,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/misc/reading = 30,
		/datum/attribute/skill/misc/climbing = 30,
		/datum/attribute/skill/misc/swimming = 30,
		/datum/attribute/skill/labor/mathematics = 20
	)

/datum/job/advclass/councilor/first_mate
	title = "First Mate"
	tutorial = "You are the First Mate, second only to the Lord Captain. \
	You keep the crew in line, enforce discipline, and ensure every order is carried out without hesitation."
	outfit = /datum/outfit/councilor/first_mate
	category_tags = list(CAT_COUNCILOR)

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/councilor/first_mate

	traits = list(
		TRAIT_CAN_STEER_SHIP,
		TRAIT_MEDIUMARMOR,
		TRAIT_DODGEEXPERT,
		TRAIT_BREADY,
		TRAIT_EMPATH,
	)

/datum/outfit/councilor/first_mate
	name = "First Mate"
	head = /obj/item/clothing/head/helmet/leather/tricorn/treasure_island
	mask = /obj/item/clothing/head/wig
	neck = /obj/item/clothing/neck/formal
	cloak = null
	armor = /obj/item/clothing/armor/gambeson/treasure_island/red
	shirt = /obj/item/clothing/shirt/undershirt/fancy
	wrists = /obj/item/storage/keyring/rmh_councilor
	gloves = null
	pants = /obj/item/clothing/pants/tights/colored/red
	shoes = /obj/item/clothing/shoes/simpleshoes/buckle
	backr = /obj/item/storage/backpack/satchel
	backl = null
	belt = /obj/item/storage/belt/leather/plaquegold
	beltr = /obj/item/storage/belt/pouch/coins/veryrich
	beltl = /obj/item/clothing/shoes/simpleshoes/buckle
	ring = /obj/item/clothing/ring/slave_control/master
	l_hand = /obj/item/weapon/lordscepter
	r_hand = /obj/item/weapon/sword/sabre

	backpack_contents = list(
		/obj/item/storage/belt/pouch/cloth/bullets,
		/obj/item/reagent_containers/glass/bottle/aflask,
		/obj/item/gun/ballistic/revolver/grenadelauncher/pistol,
		/obj/item/clothing/neck/slave_collar,
	)
