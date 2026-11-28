/datum/attribute_holder/sheet/job/waterdeep_banker
	raw_attribute_list = list(
		STAT_STRENGTH = -2,
		STAT_INTELLIGENCE = 5,
		STAT_CONSTITUTION = -1,
		/datum/attribute/skill/combat/knives = 20,
		/datum/attribute/skill/misc/reading = 70,
		/datum/attribute/skill/misc/riding = 10,
		/datum/attribute/skill/misc/stealing = 20,
		/datum/attribute/skill/misc/sneaking = 10,
		/datum/attribute/skill/misc/lockpicking = 50,
		/datum/attribute/skill/labor/mathematics = 70
	)

/datum/job/waterdeep_banker
	title = "Waterdeep Guild Banker"
	tutorial = "You are a certified banker of the Waterdeep Merchant's Guild, entrusted with accounts, contracts, and taxation in Rivermist Hollow. \
	You oversee deposits, currency exchange, and guild-approved loans. \
	Every ledger you keep is law — debt is enforceable, defaults are punished, and coin must always flow."
	department_flag = TRADERS
	faction = FACTION_TOWN
	total_positions = 1
	spawn_positions = 1
	job_flags = (JOB_ANNOUNCE_ARRIVAL | JOB_SHOW_IN_CREDITS | JOB_EQUIP_RANK | JOB_NEW_PLAYER_JOINABLE)
	display_order = JDO_WATERDEEP_BANKER

	allowed_races = list("human", "dwarf", "duergar", "aasimar", "elf", "wood elf", "halfelf", "halfling", "gnome", "deep gnome", "drow", "drider", "halfdrow", "tiefling", "dullahan", "harpy", "triton", "medicator", "fluvian", "seelie", "hollowkin", "beastkin", "beastkin small", "half-beastkin small", "taurkin", "dragonborn", "yuan-ti", "tabaxi", "lizardfolk", "construct", "doll", "ooze", "seelie")
	allowed_ages = list(AGE_ADULT, AGE_MIDDLEAGED, AGE_OLD, AGE_IMMORTAL)

	outfit = /datum/outfit/waterdeep_banker
	selection_color = JCOLOR_TRADERS

	give_bank_account = 400
	job_bitflag = BITFLAG_ROYALTY
	exp_type = list(EXP_TYPE_LIVING, EXP_TYPE_MERCHANT_COMPANY)
	exp_types_granted = list(EXP_TYPE_MERCHANT_COMPANY)
	exp_requirements = list(
		EXP_TYPE_LIVING = 700,
		EXP_TYPE_MERCHANT_COMPANY = 600,
	)

	attribute_sheet = /datum/attribute_holder/sheet/job/waterdeep_banker


	traits = list(
		TRAIT_SEEPRICES,
		TRAIT_NOBLE
	)


/datum/outfit/waterdeep_banker
	name = "Waterdeep Guild Banker"
	head = /obj/item/clothing/head/stewardtophat
	mask = /obj/item/clothing/face/spectacles/monocle
	neck = null
	cloak = null
	armor = /obj/item/clothing/armor/gambeson/steward/townhall
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
	ring = /obj/item/clothing/ring/gold/guild_mercator
	l_hand = /obj/item/weapon/knife/dagger/steel
	r_hand = /obj/item/weapon/mace/cane/noble

	backpack_contents = list(
		/obj/item/storage/belt/pouch/coins/rich = 1,
		/obj/item/lockpickring/mundane = 1
	)

/datum/outfit/waterdeep_banker/pre_equip(mob/living/carbon/human/equipped_human, visuals_only)
	. = ..()
	if(equipped_human.gender == MALE)
		shirt = /obj/item/clothing/shirt/undershirt/fancy
		pants = /obj/item/clothing/pants/tights/colored/white
		shoes = /obj/item/clothing/shoes/nobleboot
		belt = /obj/item/storage/belt/leather/suspenders
		beltl = /obj/item/weapon/scabbard/knife/noble
	else
		shirt = /obj/item/clothing/shirt/undershirt/blouse
		pants = /obj/item/clothing/pants/skirt/pencil
		shoes = /obj/item/clothing/shoes/heels
		belt = /obj/item/storage/belt/leather/plaquegold
		beltl = /obj/item/weapon/scabbard/knife/noble
