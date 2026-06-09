/datum/attribute_holder/sheet/job/advclass/artisan_apprentice/blacksmith
	raw_attribute_list = list(
		STAT_STRENGTH = 1,
		STAT_ENDURANCE = 1,
		STAT_SPEED = -1,
		/datum/attribute/skill/craft/blacksmithing = 20,
		/datum/attribute/skill/craft/smelting = 20,
		/datum/attribute/skill/craft/crafting = 20,
		/datum/attribute/skill/misc/athletics = 20,
		/datum/attribute/skill/combat/unarmed = 10,
		/datum/attribute/skill/misc/reading = 10
	)

/datum/job/advclass/artisan_apprentice/blacksmith
	title = "Smithy Apprentice"
	tutorial = "You pump bellows, haul iron, and learn how heat and hammer shape steel."

	outfit = /datum/outfit/artisan_apprentice/blacksmith
	category_tags = list(CAT_ARTISANAP)

	give_bank_account = 5
	job_bitflag = BITFLAG_CONSTRUCTOR

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/artisan_apprentice/blacksmith


	traits = list(
		TRAIT_MALUMFIRE,
	)

/datum/outfit/artisan_apprentice/blacksmith
	name = "Smithy Apprentice"
	head = null
	mask = null
	neck = null
	cloak = /obj/item/clothing/cloak/apron/brown
	armor = null
	shirt = null
	wrists = /obj/item/storage/keyring/guild_artisan
	gloves = null
	pants = /obj/item/clothing/pants/trou
	shoes = /obj/item/clothing/shoes/simpleshoes
	backr = null
	backl = /obj/item/weapon/hammer/sledgehammer
	belt = /obj/item/storage/belt/leather
	beltl = /obj/item/storage/belt/pouch/cloth/coins/poor
	beltr = null
	ring = null
	l_hand = null
	r_hand = null

	backpack_contents = list(
		/obj/item/recipe_book/blacksmithing = 1,
	)

/datum/outfit/artisan_apprentice/blacksmith/pre_equip(mob/living/carbon/human/equipped_human, visuals_only)
	. = ..()
	if(equipped_human.gender == FEMALE)
		armor = /obj/item/clothing/shirt/dress/gen/colored/random
