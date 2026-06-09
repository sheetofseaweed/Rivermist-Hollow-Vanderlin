/datum/attribute_holder/sheet/job/advclass/artisan/carpenter
	raw_attribute_list = list(
		STAT_STRENGTH = 1,
		STAT_ENDURANCE = 1,
		STAT_INTELLIGENCE = 1,
		STAT_CONSTITUTION = 1,
		STAT_SPEED = -1,
		/datum/attribute/skill/misc/medicine = 10,
		/datum/attribute/skill/combat/axesmaces = 20,
		/datum/attribute/skill/combat/wrestling = 10,
		/datum/attribute/skill/combat/unarmed = 10,
		/datum/attribute/skill/craft/crafting = 30,
		/datum/attribute/skill/craft/cooking = 10,
		/datum/attribute/skill/craft/carpentry = 50,
		/datum/attribute/skill/misc/swimming = 10,
		/datum/attribute/skill/misc/climbing = 20,
		/datum/attribute/skill/misc/sewing = 10,
		/datum/attribute/skill/misc/reading = 10,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/labor/lumberjacking = 30
	)

/datum/job/advclass/artisan/carpenter
	title = "Carpenter"
	tutorial = "From forest timber to finished beam, you shape the bones of the town."

	apprentice_name = "Carpenter Apprentice"
	can_have_apprentices = TRUE

	outfit = /datum/outfit/carpenter
	category_tags = list(CAT_ARTISAN)

	give_bank_account = 8
	job_bitflag = BITFLAG_CONSTRUCTOR

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/artisan/carpenter


	traits = list(
		TRAIT_TUTELAGE,
		)

/datum/outfit/carpenter
	name = "Carpenter"
	head = null
	mask = null
	neck = /obj/item/clothing/neck/coif
	cloak = null
	armor = /obj/item/clothing/armor/gambeson/light/striped
	shirt = /obj/item/clothing/shirt/undershirt/colored/random
	wrists = /obj/item/clothing/wrists/bracers/leather
	gloves = null
	pants = /obj/item/clothing/pants/trou
	shoes = /obj/item/clothing/shoes/boots/leather
	backr = /obj/item/weapon/axe/iron
	backl = /obj/item/storage/backpack/backpack
	belt = /obj/item/storage/belt/leather
	beltr = /obj/item/storage/belt/pouch/cloth/coins/mid
	beltl = /obj/item/weapon/hammer/steel
	ring = /obj/item/clothing/ring/silver/makers_guild
	l_hand = /obj/item/storage/keyring/guild_artisan
	r_hand = null

	backpack_contents = list(
		/obj/item/flint = 1,
		/obj/item/weapon/knife/villager = 1,
		/obj/item/recipe_book/carpentry = 1,
	)

/datum/outfit/carpenter/pre_equip(mob/living/carbon/human/H, visuals_only)
	. = ..()
	head = pick(
		/obj/item/clothing/head/hatfur,
		/obj/item/clothing/head/hatblu,
		/obj/item/clothing/head/brimmed,
	)
