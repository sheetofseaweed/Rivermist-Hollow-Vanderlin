/datum/attribute_holder/sheet/job/advclass/town_scholar/artificer
	raw_attribute_list = list(
		STAT_STRENGTH = 1,
		STAT_INTELLIGENCE = 2,
		STAT_ENDURANCE = 1,
		STAT_SPEED = -1,
		/datum/attribute/skill/combat/axesmaces = 20,
		/datum/attribute/skill/craft/masonry = 30,
		/datum/attribute/skill/craft/crafting = 40,
		/datum/attribute/skill/craft/engineering = 40,
		/datum/attribute/skill/misc/lockpicking = 30,
		/datum/attribute/skill/misc/swimming = 10,
		/datum/attribute/skill/misc/climbing = 20,
		/datum/attribute/skill/misc/athletics = 20,
		/datum/attribute/skill/labor/mining = 20,
		/datum/attribute/skill/craft/smelting = 40,
		/datum/attribute/skill/misc/reading = 20,
		/datum/attribute/skill/labor/mathematics = 20,
		/datum/attribute/skill/craft/bombs = 30
	)

/datum/job/advclass/town_scholar/artificer
	title = "Artificer"
	tutorial = "You are a learned craftsperson of mechanisms and materials. \
	Gears, pulleys, constructs, and clever devices answer to your hand."

	apprentice_name = "Artificer Apprentice"
	can_have_apprentices = TRUE

	total_positions = 1
	spawn_positions = 1

	outfit = /datum/outfit/town_scholar/artificer
	category_tags = list(CAT_ARCHIVIST)

	give_bank_account = 8
	job_bitflag = BITFLAG_CONSTRUCTOR

	exp_type = list(EXP_TYPE_LIVING)
	exp_requirements = list(EXP_TYPE_LIVING = 600)

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/town_scholar/artificer


	traits = list(
		TRAIT_TUTELAGE,
		)

/datum/outfit/town_scholar/artificer
	name = "Artificer"
	head = /obj/item/clothing/head/articap
	mask = /obj/item/clothing/face/goggles
	neck = null
	cloak = null
	armor = /obj/item/clothing/armor/leather/jacket/artijacket
	shirt = /obj/item/clothing/shirt/undershirt/artificer
	wrists = /obj/item/storage/keyring/guild_artisan
	gloves = null
	pants = /obj/item/clothing/pants/trou/artipants
	shoes = /obj/item/clothing/shoes/simpleshoes/buckle
	backr = null
	backl = /obj/item/storage/backpack/backpack/artibackpack
	belt = /obj/item/storage/belt/leather
	beltr = /obj/item/storage/belt/pouch/cloth/coins/mid
	beltl = /obj/item/weapon/mace/cane/bronze
	ring = /obj/item/clothing/ring/silver/makers_guild
	l_hand = null
	r_hand = null

	backpack_contents = list(
		/obj/item/weapon/hammer/steel = 1,
		/obj/item/flashlight/flare/torch/lantern = 1,
		/obj/item/weapon/knife/villager = 1,
		/obj/item/weapon/chisel = 1,
	)
