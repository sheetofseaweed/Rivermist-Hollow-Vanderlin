/datum/attribute_holder/sheet/job/advclass/artisan/blacksmith
	raw_attribute_list = list(
		STAT_STRENGTH = 1,
		STAT_ENDURANCE = 2,
		STAT_SPEED = -1,
		/datum/attribute/skill/combat/axesmaces = 20,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/combat/wrestling = 20,
		/datum/attribute/skill/combat/unarmed = 20,
		/datum/attribute/skill/craft/crafting = 30,
		/datum/attribute/skill/craft/blacksmithing = 50,
		/datum/attribute/skill/craft/armorsmithing = 50,
		/datum/attribute/skill/craft/weaponsmithing = 50,
		/datum/attribute/skill/craft/smelting = 30,
		/datum/attribute/skill/craft/engineering = 30,
		/datum/attribute/skill/craft/traps = 20,
		/datum/attribute/skill/misc/reading = 20,
		/datum/attribute/skill/labor/mathematics = 20
	)

/datum/job/advclass/artisan/blacksmith
	title = "Blacksmith"
	tutorial = "Steel is your craft, whether shaped for war, work, or protection."

	apprentice_name = "Smithy Apprentice"
	can_have_apprentices = TRUE

	outfit = /datum/outfit/blacksmith
	category_tags = list(CAT_ARTISAN)

	give_bank_account = 30
	job_bitflag = BITFLAG_CONSTRUCTOR

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/artisan/blacksmith


	traits = list(
		TRAIT_TUTELAGE,
		TRAIT_MALUMFIRE,
		TRAIT_SEEPRICES,
	)

/datum/outfit/blacksmith
	name = "Blacksmith"
	head = /obj/item/clothing/head/hatfur
	mask = null
	neck = null
	cloak = /obj/item/clothing/cloak/apron/brown
	armor = null
	shirt = null
	wrists = /obj/item/storage/keyring/guild_artisan
	gloves = null
	pants = /obj/item/clothing/pants/trou
	shoes = null
	backr = null
	backl = /obj/item/weapon/hammer/sledgehammer
	belt = /obj/item/storage/belt/leather
	beltl = /obj/item/storage/belt/pouch/cloth/coins/mid
	beltr = null
	ring = /obj/item/clothing/ring/silver/makers_guild
	l_hand = null
	r_hand = null

	backpack_contents = list(
		/obj/item/recipe_book/blacksmithing = 1,
	)

/datum/outfit/blacksmith/pre_equip(mob/living/carbon/human/equipped_human, visuals_only)
	. = ..()
	if(prob(50))
		head = /obj/item/clothing/head/hatblu
	if(equipped_human.gender == MALE)
		shoes = /obj/item/clothing/shoes/boots/leather
	else
		armor = /obj/item/clothing/shirt/dress/gen/colored/random
		shoes = /obj/item/clothing/shoes/shortboots
