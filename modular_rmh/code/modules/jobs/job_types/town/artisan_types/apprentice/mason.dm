/datum/attribute_holder/sheet/job/advclass/artisan_apprentice/mason
	raw_attribute_list = list(
		STAT_STRENGTH = 1,
		STAT_ENDURANCE = 1,
		STAT_INTELLIGENCE = 1,
		STAT_SPEED = -1,
		/datum/attribute/skill/craft/masonry = 30,
		/datum/attribute/skill/craft/crafting = 20,
		/datum/attribute/skill/labor/mining = 20,
		/datum/attribute/skill/misc/athletics = 20,
		/datum/attribute/skill/misc/climbing = 10,
		/datum/attribute/skill/misc/reading = 10
	)

/datum/job/advclass/artisan_apprentice/mason
	title = "Mason Apprentice"
	tutorial = "You haul stone, mix mortar, and learn where to strike — and where not to."

	outfit = /datum/outfit/artisan_apprentice/mason
	category_tags = list(CAT_ARTISANAP)

	give_bank_account = 3
	job_bitflag = BITFLAG_CONSTRUCTOR

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/artisan_apprentice/mason


/datum/outfit/artisan_apprentice/mason
	name = "Mason Apprentice"
	head = null
	mask = null
	neck = /obj/item/storage/belt/pouch/cloth/coins/poor
	cloak = /obj/item/clothing/cloak/apron/waist/colored/brown
	armor = null
	shirt = /obj/item/clothing/shirt/undershirt/colored/random
	wrists = /obj/item/storage/keyring/guild_artisan
	gloves = null
	pants = /obj/item/clothing/pants/trou
	shoes = /obj/item/clothing/shoes/simpleshoes
	backr = null
	backl = /obj/item/storage/backpack/backpack
	belt = /obj/item/storage/belt/leather
	beltl = /obj/item/weapon/hammer
	beltr = /obj/item/weapon/chisel
	ring = null
	l_hand = null
	r_hand = null
