/datum/attribute_holder/sheet/job/waterdeep_guild_guard
	raw_attribute_list = list(
		STAT_STRENGTH = 2,
		STAT_ENDURANCE = 2,
		STAT_CONSTITUTION = 2,
		/datum/attribute/skill/combat/swords = 30,
		/datum/attribute/skill/combat/axesmaces = 30,
		/datum/attribute/skill/combat/knives = 20,
		/datum/attribute/skill/combat/wrestling = 30,
		/datum/attribute/skill/combat/unarmed = 30,
		/datum/attribute/skill/combat/shields = 30,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/misc/climbing = 20,
		/datum/attribute/skill/misc/reading = 10
	)

/datum/job/waterdeep_guild_guard
	title = "Waterdeep Guild Guard"
	tutorial = "You are a hired guard of the Waterdeep Trading Guild. \
	Your duty is to protect guild representatives, guild property, and guild facilities.\
	Threats to guild coin, contracts, or personnel are to be deterred swiftly and decisively."
	department_flag = TRADERS
	faction = FACTION_TOWN
	total_positions = 3
	spawn_positions = 3
	job_flags = (JOB_ANNOUNCE_ARRIVAL | JOB_SHOW_IN_CREDITS | JOB_EQUIP_RANK | JOB_NEW_PLAYER_JOINABLE)
	display_order = JDO_WATERDEEP_GUARD

	allowed_races = ALL_RACES_LIST
	allowed_ages = list(AGE_ADULT, AGE_MIDDLEAGED, AGE_OLD, AGE_IMMORTAL)

	outfit = /datum/outfit/waterdeep_guild_guard
	selection_color = JCOLOR_TRADERS

	give_bank_account = 100
	exp_type = list(EXP_TYPE_LIVING)
	exp_types_granted = list(EXP_TYPE_COMBAT, EXP_TYPE_MERCHANT_COMPANY)
	exp_requirements = list(
		EXP_TYPE_LIVING = 300
	)

	attribute_sheet = /datum/attribute_holder/sheet/job/waterdeep_guild_guard


	traits = list(
		TRAIT_MEDIUMARMOR,
		TRAIT_HEAVYARMOR,
		TRAIT_KNOWBANDITS
	)


/datum/job/waterdeep_guild_guard/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()
	spawned.verbs |= /mob/proc/haltyell

// OUTFIT

/datum/outfit/waterdeep_guild_guard
	name = "Waterdeep Guild Guard"
	head = /obj/item/clothing/head/roguetown/helmet/guildguard
	mask = null
	neck = /obj/item/clothing/neck/gorget
	cloak = /obj/item/clothing/cloak/guildguard
	armor = /obj/item/clothing/suit/roguetown/armor/guildguard
	shirt = /obj/item/clothing/armor/gambeson
	wrists = /obj/item/storage/keyring/waterdeep_guild
	gloves = /obj/item/clothing/gloves/leather/advanced
	pants = /obj/item/clothing/pants/trou/leather/splint
	shoes = /obj/item/clothing/shoes/boots/leather/advanced
	backr = /obj/item/storage/backpack/satchel/black
	backl = null
	belt = /obj/item/storage/belt/leather/steel
	beltr = /obj/item/weapon/scabbard/sword
	beltl = /obj/item/weapon/mace/stunmace
	ring = null
	l_hand = null
	r_hand = /obj/item/weapon/sword/sabre

	backpack_contents = list(
		/obj/item/reagent_containers/glass/bottle/stronghealthpot,
		/obj/item/flashlight/flare/torch/lantern,
		/obj/item/storage/belt/pouch/cloth/coins/mid,
		/obj/item/rope/chain,
	)
