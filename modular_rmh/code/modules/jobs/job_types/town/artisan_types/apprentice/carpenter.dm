/datum/attribute_holder/sheet/job/advclass/artisan_apprentice/carpenter
	raw_attribute_list = list(
		STAT_STRENGTH = 1,
		STAT_ENDURANCE = 1,
		STAT_CONSTITUTION = 1,
		STAT_SPEED = -1,
		/datum/attribute/skill/craft/carpentry = 30,
		/datum/attribute/skill/craft/crafting = 20,
		/datum/attribute/skill/labor/lumberjacking = 20,
		/datum/attribute/skill/misc/athletics = 20,
		/datum/attribute/skill/misc/climbing = 10,
		/datum/attribute/skill/misc/reading = 10
	)

/datum/job/advclass/artisan_apprentice/carpenter
	title = "Carpenter Apprentice"
	tutorial = "You carry timber, measure beams, and learn to cut straight — eventually."

	outfit = /datum/outfit/artisan_apprentice/carpenter
	category_tags = list(CAT_ARTISANAP)

	give_bank_account = 3
	job_bitflag = BITFLAG_CONSTRUCTOR

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/artisan_apprentice/carpenter


/datum/outfit/artisan_apprentice/carpenter
	name = "Carpenter Apprentice"
	head = null
	mask = null
	neck = null
	cloak = null
	armor = null
	shirt = /obj/item/clothing/shirt/undershirt/colored/random
	wrists = /obj/item/storage/keyring/guild_artisan
	gloves = null
	pants = /obj/item/clothing/pants/trou
	shoes = /obj/item/clothing/shoes/simpleshoes
	backr = /obj/item/weapon/axe/iron
	backl = /obj/item/storage/backpack/backpack
	belt = /obj/item/storage/belt/leather
	beltr = /obj/item/storage/belt/pouch/cloth/coins/poor
	beltl = /obj/item/weapon/hammer/steel
	ring = null
	l_hand = null
	r_hand = null

	backpack_contents = list(
		/obj/item/flint = 1,
		/obj/item/weapon/knife/villager = 1,
		/obj/item/recipe_book/carpentry = 1,
	)
