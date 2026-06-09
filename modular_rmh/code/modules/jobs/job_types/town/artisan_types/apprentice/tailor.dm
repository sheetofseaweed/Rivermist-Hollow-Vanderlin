/datum/attribute_holder/sheet/job/advclass/artisan_apprentice/tailor
	raw_attribute_list = list(
		STAT_INTELLIGENCE = 1,
		STAT_SPEED = 1,
		STAT_PERCEPTION = 1,
		STAT_STRENGTH = -1,
		/datum/attribute/skill/misc/sewing = 20,
		/datum/attribute/skill/craft/tanning = 10,
		/datum/attribute/skill/craft/crafting = 20,
		/datum/attribute/skill/combat/knives = 10,
		/datum/attribute/skill/misc/sneaking = 10,
		/datum/attribute/skill/misc/reading = 10,
		/datum/attribute/skill/labor/mathematics = 10
	)

/datum/job/advclass/artisan_apprentice/tailor
	title = "Tailor Apprentice"
	f_title = "Seamstress Apprentice"
	tutorial = "You mend seams, cut patterns, and learn patience one stitch at a time."

	outfit = /datum/outfit/artisan_apprentice/tailor
	category_tags = list(CAT_ARTISANAP)

	give_bank_account = 6
	job_bitflag = BITFLAG_CONSTRUCTOR

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/artisan_apprentice/tailor


/datum/outfit/artisan_apprentice/tailor
	name = "Tailor"
	head = null
	mask = null
	neck = /obj/item/storage/belt/pouch/cloth/coins/poor
	cloak = null
	armor = null
	shirt = null
	wrists = /obj/item/storage/keyring/guild_artisan
	gloves = null
	pants = null
	shoes = /obj/item/clothing/shoes/simpleshoes
	backr = /obj/item/storage/backpack/satchel
	backl = null
	belt = /obj/item/storage/belt/leather
	beltr = /obj/item/weapon/knife/scissors
	beltl = null
	ring = null
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

/datum/outfit/artisan_apprentice/tailor/pre_equip(mob/living/carbon/human/equipped_human, visuals_only)
	. = ..()
	if(equipped_human.gender == MALE)
		shirt = /obj/item/clothing/shirt/undershirt
		pants = /obj/item/clothing/pants/tights/colored/red
	else
		armor = /obj/item/clothing/armor/corset
		shirt = /obj/item/clothing/shirt/undershirt
		pants = /obj/item/clothing/pants/skirt/colored/red
