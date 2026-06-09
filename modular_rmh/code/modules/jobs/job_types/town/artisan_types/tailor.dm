/datum/attribute_holder/sheet/job/advclass/artisan/tailor
	raw_attribute_list = list(
		STAT_INTELLIGENCE = 2,
		STAT_SPEED = 1,
		STAT_PERCEPTION = 1,
		STAT_STRENGTH = -1,
		/datum/attribute/skill/misc/sewing = 50,
		/datum/attribute/skill/craft/tanning = 50,
		/datum/attribute/skill/craft/crafting = 30,
		/datum/attribute/skill/combat/knives = 20,
		/datum/attribute/skill/misc/sneaking = 20,
		/datum/attribute/skill/labor/taming = 30,
		/datum/attribute/skill/misc/medicine = 20,
		/datum/attribute/skill/misc/reading = 10,
		/datum/attribute/skill/craft/carpentry = 10,
		/datum/attribute/skill/misc/stealing = 10,
		/datum/attribute/skill/labor/mathematics = 20
	)

/datum/job/advclass/artisan/tailor
	title = "Tailor"
	f_title = "Seamstress"
	tutorial = "Cloth, linen, silk, and leather pass through your hands each day."

	apprentice_name = "Tailor Apprentice"
	can_have_apprentices = TRUE

	outfit = /datum/outfit/tailor
	category_tags = list(CAT_ARTISAN)

	give_bank_account = 25
	job_bitflag = BITFLAG_CONSTRUCTOR

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/artisan/tailor


	traits = list(
		TRAIT_TUTELAGE,
		TRAIT_SEEPRICES,
	)

/datum/outfit/tailor
	name = "Tailor"
	head = /obj/item/clothing/head/courtierhat
	mask = null
	neck = /obj/item/storage/belt/pouch/cloth/coins/mid
	cloak = null
	armor = null
	shirt = null
	wrists = /obj/item/storage/keyring/guild_artisan
	gloves = null
	pants = null
	shoes = /obj/item/clothing/shoes/nobleboot
	backr = /obj/item/storage/backpack/satchel
	backl = null
	belt = /obj/item/storage/belt/leather
	beltr = /obj/item/weapon/knife/scissors
	beltl = null
	ring = /obj/item/clothing/ring/silver/makers_guild
	l_hand = null
	r_hand = null

	backpack_contents = list(
		/obj/item/needle = 1,
		/obj/item/natural/bundle/cloth/full = 1,
		/obj/item/natural/bundle/fibers/full = 1,
		/obj/item/dye_pack/luxury = 1,
		/obj/item/recipe_book/sewing_leather = 1,
		/obj/item/weapon/knife/villager = 1
	)

/datum/outfit/tailor/pre_equip(mob/living/carbon/human/equipped_human, visuals_only)
	. = ..()
	if(equipped_human.gender == MALE)
		cloak = /obj/item/clothing/cloak/raincloak/furcloak
		shirt = /obj/item/clothing/shirt/undershirt/fancy
		pants = /obj/item/clothing/pants/tights/colored/red
	else
		cloak = /obj/item/clothing/cloak/raincloak/furcloak
		armor = /obj/item/clothing/armor/corset
		shirt = /obj/item/clothing/shirt/undershirt/fancy
		pants = /obj/item/clothing/pants/skirt/colored/red
