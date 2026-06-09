/datum/attribute_holder/sheet/job/advclass/artisan/mason
	raw_attribute_list = list(
		STAT_STRENGTH = 1,
		STAT_INTELLIGENCE = 2,
		STAT_ENDURANCE = 1,
		STAT_CONSTITUTION = 1,
		STAT_SPEED = -1,
		/datum/attribute/skill/combat/axesmaces = 20,
		/datum/attribute/skill/labor/mining = 30,
		/datum/attribute/skill/combat/wrestling = 10,
		/datum/attribute/skill/combat/unarmed = 10,
		/datum/attribute/skill/craft/crafting = 30,
		/datum/attribute/skill/craft/masonry = 40,
		/datum/attribute/skill/craft/engineering = 10,
		/datum/attribute/skill/misc/swimming = 20,
		/datum/attribute/skill/misc/climbing = 30,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/misc/reading = 10
	)

/datum/job/advclass/artisan/mason
	title = "Mason"
	tutorial = "Stone remembers every chisel strike, and you are the one who gives it purpose."

	apprentice_name = "Mason Apprentice"
	can_have_apprentices = TRUE

	outfit = /datum/outfit/mason
	category_tags = list(CAT_ARTISAN)

	give_bank_account = 8
	job_bitflag = BITFLAG_CONSTRUCTOR

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/artisan/mason


	traits = list(
		TRAIT_TUTELAGE,
		)

/datum/outfit/mason
	name = "Mason"
	head = /obj/item/clothing/head/hatfur
	mask = null
	neck = /obj/item/storage/belt/pouch/cloth/coins/mid
	cloak = /obj/item/clothing/cloak/apron/waist/colored/brown
	armor = /obj/item/clothing/armor/leather/vest
	shirt = /obj/item/clothing/shirt/undershirt/colored/random
	wrists = /obj/item/storage/keyring/guild_artisan
	gloves = null
	pants = /obj/item/clothing/pants/trou
	shoes = /obj/item/clothing/shoes/boots/leather
	backr = null
	backl = /obj/item/storage/backpack/backpack
	belt = /obj/item/storage/belt/leather
	beltl = /obj/item/weapon/hammer
	beltr = /obj/item/weapon/chisel
	ring = /obj/item/clothing/ring/silver/makers_guild
	l_hand = null
	r_hand = null

/datum/outfit/mason/pre_equip(mob/living/carbon/human/H)
	..()
	head = pick(/obj/item/clothing/head/hatfur, /obj/item/clothing/head/hatblu)
	shirt = pick(/obj/item/clothing/shirt/undershirt/colored/random, /obj/item/clothing/shirt/tunic/colored/random)
