/datum/attribute_holder/sheet/job/waterdeep_merchant
	raw_attribute_list = list(
		STAT_INTELLIGENCE = 2,
		STAT_PERCEPTION = 1,
		STAT_STRENGTH = -1,
		/datum/attribute/skill/combat/swords = 20,
		/datum/attribute/skill/combat/knives = 10,
		/datum/attribute/skill/misc/reading = 60,
		/datum/attribute/skill/misc/sneaking = 10,
		/datum/attribute/skill/misc/stealing = 50,
		/datum/attribute/skill/misc/lockpicking = 20,
		/datum/attribute/skill/misc/riding = 20,
		/datum/attribute/skill/labor/mathematics = 60
	)

/datum/job/waterdeep_merchant
	title = "Waterdeep Guild Merchant"
	tutorial = "You are a licensed merchant of the Waterdeep Trading Guild, operating in Rivermist Hollow. \
	You manage trade deliveries, warehouses, and financial dealings on behalf of Waterdeep Merchant's Guild. \
	Guild loans are legal and enforceable — unpaid debts may result in seizure, punishment, or contract restitution. \
	Formality is required. Mercy is optional. Profit is mandatory."
	department_flag = TRADERS
	faction = FACTION_TOWN
	total_positions = 1
	spawn_positions = 1
	job_flags = (JOB_ANNOUNCE_ARRIVAL | JOB_SHOW_IN_CREDITS | JOB_EQUIP_RANK | JOB_NEW_PLAYER_JOINABLE)
	display_order = JDO_WATERDEEP_MERCHANT

	allowed_races = ALL_RACES_LIST
	allowed_ages = list(AGE_ADULT, AGE_MIDDLEAGED, AGE_OLD, AGE_IMMORTAL)

	outfit = /datum/outfit/waterdeep_merchant
	selection_color = JCOLOR_TRADERS

	give_bank_account = 300
	exp_type = list(EXP_TYPE_LIVING, EXP_TYPE_MERCHANT_COMPANY)
	exp_types_granted = list(EXP_TYPE_MERCHANT_COMPANY)
	exp_requirements = list(
		EXP_TYPE_LIVING = 800,
		EXP_TYPE_MERCHANT_COMPANY = 500,
	)

	attribute_sheet = /datum/attribute_holder/sheet/job/waterdeep_merchant


	traits = list(
		TRAIT_SEEPRICES,
		TRAIT_NOBLE
	)

/datum/job/waterdeep_merchant/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()
	if(SSmerchant.merchant_preferences_applied || !player_client?.prefs)
		return
	SSmerchant.merchant_preferences_applied = TRUE
	var/datum/preference/list_type/role_setting/picker/faction_standing/standing_preference = GLOB.preference_entries[/datum/preference/list_type/role_setting/picker/faction_standing]
	if(standing_preference)
		standing_preference.apply_to_market(player_client.prefs.read_preference(standing_preference.type))
	var/datum/preference/list_type/role_setting/picker/supply_pack/supply_preference = GLOB.preference_entries[/datum/preference/list_type/role_setting/picker/supply_pack]
	if(supply_preference)
		supply_preference.apply_to_market(player_client.prefs.read_preference(supply_preference.type))

/datum/outfit/waterdeep_merchant
	name = "Waterdeep Guild Merchant"
	head = /obj/item/clothing/head/chaperon/colored/greyscale/silk/random
	mask = null
	neck = /obj/item/clothing/neck/mercator
	cloak = null
	armor = /obj/item/clothing/shirt/robe/merchant
	shirt = /obj/item/clothing/shirt/tunic/noblecoat
	wrists = /obj/item/storage/keyring/waterdeep_guild
	gloves = null
	pants = null
	shoes = /obj/item/clothing/shoes/nobleboot
	backr = /obj/item/storage/backpack/satchel
	backl = null
	belt = /obj/item/storage/belt/leather/plaquegold
	beltr = /obj/item/weapon/mace/cane/merchant
	beltl = /obj/item/weapon/scabbard/sword/noble
	ring = /obj/item/clothing/ring/gold/guild_mercator
	l_hand = /obj/item/weapon/sword/rapier
	r_hand = null

	backpack_contents = list(
		/obj/item/book/secret/ledger = 1,
		/obj/item/storage/belt/pouch/coins/veryrich = 1,
		/obj/item/merctoken = 1
	)

/datum/outfit/waterdeep_merchant/pre_equip(mob/living/carbon/human/equipped_human, visuals_only)
	. = ..()
	if(equipped_human.gender == MALE)
		pants = /obj/item/clothing/pants/tights/colored/white
