/datum/attribute_holder/sheet/job/advclass/town_scholar_apprentice/artificer
	raw_attribute_list = list(
		STAT_INTELLIGENCE = 1,
		STAT_CONSTITUTION = 1,
		STAT_SPEED = -1,
		/datum/attribute/skill/craft/crafting = 20,
		/datum/attribute/skill/craft/engineering = 20,
		/datum/attribute/skill/craft/masonry = 10,
		/datum/attribute/skill/craft/smelting = 10,
		/datum/attribute/skill/misc/reading = 10,
		/datum/attribute/skill/labor/mathematics = 10,
		/datum/attribute/skill/misc/athletics = 10
	)

/datum/job/advclass/town_scholar_apprentice/artificer
	title = "Artificer Apprentice"
	tutorial = "You assist a master artificer, cleaning tools, assembling simple parts, \
	and learning how clever mechanisms truly work."
	total_positions = 2
	spawn_positions = 2

	outfit = /datum/outfit/town_scholar_apprentice/artificer
	category_tags = list(CAT_ARCHIVISTAP)

	give_bank_account = 3
	job_bitflag = BITFLAG_CONSTRUCTOR

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/town_scholar_apprentice/artificer


/datum/outfit/town_scholar_apprentice/artificer
	name = "Artificer Apprentice"
	head = null
	mask = /obj/item/clothing/face/goggles
	neck = null
	cloak = null
	armor = /obj/item/clothing/armor/leather/jacket
	shirt = /obj/item/clothing/shirt/undershirt
	wrists = /obj/item/storage/keyring/guild_artisan
	gloves = null
	pants = /obj/item/clothing/pants/trou/leather
	shoes = /obj/item/clothing/shoes/simpleshoes
	backr = null
	backl = /obj/item/storage/backpack/backpack
	belt = /obj/item/storage/belt/leather
	beltr = /obj/item/storage/belt/pouch/cloth/coins/poor
	beltl = null
	ring = null
	l_hand = null
	r_hand = null

	backpack_contents = list(
		/obj/item/weapon/hammer/steel = 1,
		/obj/item/flashlight/flare/torch/lantern = 1,
		/obj/item/weapon/knife/villager = 1,
		/obj/item/weapon/chisel = 1,
	)
