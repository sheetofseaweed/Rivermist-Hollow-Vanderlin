/datum/job/waterdeep_guild_assistant
	title = "Waterdeep Guild Assistant"
	tutorial = "A junior employee of the Waterdeep Trading Guild stationed in Rivermist Hollow. \
	You handle records, errands, and routine work under senior guild officials. \
	Your duties depend on assignment — shop or bank — but discretion and obedience are always expected."
	department_flag = TRADERS
	faction = FACTION_TOWN
	total_positions = 2
	spawn_positions = 2
	job_flags = (JOB_ANNOUNCE_ARRIVAL | JOB_SHOW_IN_CREDITS | JOB_EQUIP_RANK | JOB_NEW_PLAYER_JOINABLE)
	display_order = JDO_WATERDEEP_ASSISTANT

	allowed_races = ALL_RACES_LIST
	allowed_ages = list(AGE_ADULT)

	selection_color = JCOLOR_TRADERS
	advclass_cat_rolls = list(CAT_SHOPHAND = 20)

	give_bank_account = 30
	exp_type = list(EXP_TYPE_LIVING)
	exp_types_granted = list(EXP_TYPE_MERCHANT_COMPANY)
	exp_requirements = list(
		EXP_TYPE_LIVING = 200
	)

	job_subclasses = list(
		/datum/job/advclass/waterdeep_guild_assistant/shophand,
		/datum/job/advclass/waterdeep_guild_assistant/banker_assistant
	)

// ─────────────────────────────
// SUBCLASSES
// ─────────────────────────────

/datum/attribute_holder/sheet/job/advclass/waterdeep_guild_assistant/shophand
	raw_attribute_list = list(
		STAT_SPEED = 1,
		STAT_STRENGTH = 1,
		/datum/attribute/skill/misc/stealing = 40,
		/datum/attribute/skill/misc/sneaking = 20,
		/datum/attribute/skill/misc/reading = 30,
		/datum/attribute/skill/combat/knives = 20,
		/datum/attribute/skill/misc/athletics = 20,
		/datum/attribute/skill/labor/mathematics = 30
	)

/datum/job/advclass/waterdeep_guild_assistant/shophand
	title = "Guild Shophand"
	tutorial = "Assigned to the guild shop and warehouse. \
	You manage inventory, assist customers, accompany shipments, and support guild merchants."

	outfit = /datum/outfit/waterdeep_guild_assistant/shophand
	category_tags = list(CAT_SHOPHAND)

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/waterdeep_guild_assistant/shophand



	traits = list(
		TRAIT_SEEPRICES
	)

/datum/outfit/waterdeep_guild_assistant/shophand
	name = "Guild Shophand"
	head = null
	mask = null
	neck = null
	cloak = null
	armor = null
	shirt = null
	wrists = /obj/item/storage/keyring/waterdeep_guild
	gloves = null
	pants = null
	shoes = /obj/item/clothing/shoes/simpleshoes
	backr = /obj/item/storage/backpack/satchel
	backl = null
	belt = /obj/item/storage/belt/leather
	beltr = /obj/item/storage/belt/pouch/cloth/coins/poor
	beltl = null
	ring = null
	l_hand = null
	r_hand = null

	backpack_contents = list(
		/obj/item/storage/belt/pouch/coins/rich = 1,
		/obj/item/lockpickring/mundane = 1
	)

/datum/outfit/waterdeep_guild_assistant/shophand/pre_equip(mob/living/carbon/human/equipped_human, visuals_only)
	. = ..()
	if(equipped_human.gender == MALE)
		shirt = shirt = /obj/item/clothing/shirt/undershirt/colored/blue
		pants = /obj/item/clothing/pants/tights
	else
		shirt = /obj/item/clothing/shirt/dress/silkdress/colored/waterdeep_guild

// ─────────────────────────────

/datum/attribute_holder/sheet/job/advclass/waterdeep_guild_assistant/banker_assistant
	raw_attribute_list = list(
		STAT_INTELLIGENCE = 2,
		STAT_SPEED = 1,
		/datum/attribute/skill/misc/reading = 50,
		/datum/attribute/skill/misc/lockpicking = 30,
		/datum/attribute/skill/misc/sneaking = 10,
		/datum/attribute/skill/labor/mathematics = 50
	)

/datum/job/advclass/waterdeep_guild_assistant/banker_assistant
	title = "Guild Banker Assistant"
	tutorial = "Assigned to the guild bank. \
	You maintain ledgers, assist with accounts, handle minor loans, and observe enforcement procedures."

	outfit = /datum/outfit/waterdeep_guild_assistant/banker_assistant
	category_tags = list(CAT_SHOPHAND)

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/waterdeep_guild_assistant/banker_assistant


	traits = list(
		TRAIT_SEEPRICES
	)


/datum/outfit/waterdeep_guild_assistant/banker_assistant
	name = "Guild Banker Assistant"
	head = null
	mask = /obj/item/clothing/face/spectacles
	neck = null
	cloak = null
	armor = /obj/item/clothing/shirt/clothvest/colored/waterdeep_guild
	shirt = null
	wrists = /obj/item/storage/keyring/waterdeep_guild
	gloves = null
	pants = null
	shoes = null
	backr = /obj/item/storage/backpack/satchel
	backl = null
	belt = null
	beltr = null
	beltl = null
	ring = null
	l_hand = null
	r_hand = null

/datum/outfit/waterdeep_guild_assistant/banker_assistant/pre_equip(mob/living/carbon/human/equipped_human, visuals_only)
	. = ..()
	if(equipped_human.gender == MALE)
		shirt = /obj/item/clothing/shirt/undershirt/fancy
		pants = /obj/item/clothing/pants/tights/colored/black
		shoes = /obj/item/clothing/shoes/nobleboot
		belt = /obj/item/storage/belt/leather/suspenders
		beltr = /obj/item/storage/belt/pouch/cloth/coins/poor
	else
		shirt = /obj/item/clothing/shirt/undershirt/blouse
		pants = /obj/item/clothing/pants/skirt/pencil
		shoes = /obj/item/clothing/shoes/heels
		belt = /obj/item/storage/belt/leather/plaquesilver
		beltr = /obj/item/storage/belt/pouch/cloth/coins/poor
