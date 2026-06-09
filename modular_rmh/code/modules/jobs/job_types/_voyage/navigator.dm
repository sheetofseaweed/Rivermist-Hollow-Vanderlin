/datum/attribute_holder/sheet/job/navigator
	raw_attribute_list = list(
		STAT_STRENGTH = 1,
		STAT_ENDURANCE = 2,
		STAT_CONSTITUTION = 1,
		STAT_PERCEPTION = 3,
		STAT_INTELLIGENCE = 4,
		STAT_SPEED = 1,
		/datum/attribute/skill/combat/swords = 20,
		/datum/attribute/skill/combat/wrestling = 20,
		/datum/attribute/skill/combat/unarmed = 20,
		/datum/attribute/skill/combat/firearms = 20,
		/datum/attribute/skill/misc/athletics = 20,
		/datum/attribute/skill/misc/climbing = 20,
		/datum/attribute/skill/misc/swimming = 40,
		/datum/attribute/skill/misc/reading = 50,
		/datum/attribute/skill/labor/mathematics = 50
	)

/datum/job/navigator
	title = "Navigator"
	tutorial = "You are the Navigator aboard the vessel. \
	You chart courses, judge reefs and currents, and keep the ship moving when the Lord Captain is absent or occupied."
	department_flag = TOWNHALL
	job_flags = (JOB_ANNOUNCE_ARRIVAL | JOB_SHOW_IN_CREDITS | JOB_EQUIP_RANK | JOB_NEW_PLAYER_JOINABLE)
	display_order = JDO_NAVIGATOR
	faction = FACTION_TOWN
	total_positions = 0
	spawn_positions = 0

	allowed_ages = list(AGE_ADULT, AGE_MIDDLEAGED, AGE_OLD, AGE_IMMORTAL)
	allowed_races = ALL_RACES_LIST
	selection_color = JCOLOR_TOWNHALL

	outfit = /datum/outfit/navigator
	give_bank_account = 60

	exp_type = list(EXP_TYPE_LIVING)
	exp_types_granted = list(EXP_TYPE_LEADERSHIP)
	exp_requirements = list(
		EXP_TYPE_LIVING = 300
	)

	attribute_sheet = /datum/attribute_holder/sheet/job/navigator

	traits = list(
		TRAIT_CAN_STEER_SHIP,
		TRAIT_BREADY
	)

/datum/outfit/navigator
	name = "Navigator"
	head = /obj/item/clothing/head/helmet/leather/tricorn/treasure_island
	mask = null
	neck = /obj/item/clothing/neck/formal
	cloak = null
	armor = /obj/item/clothing/armor/gambeson/treasure_island/navigator
	shirt = /obj/item/clothing/shirt/undershirt/fancy
	wrists = null
	gloves = /obj/item/clothing/gloves/leather
	pants = /obj/item/clothing/pants/tights/colored/green
	shoes = /obj/item/clothing/shoes/simpleshoes/buckle
	backr = /obj/item/storage/backpack/satchel
	backl = null
	belt = /obj/item/storage/belt/leather/plaquesilver
	beltr = /obj/item/storage/belt/pouch/coins/rich
	beltl = /obj/item/weapon/scabbard/sword
	ring = null
	l_hand = null
	r_hand = /obj/item/weapon/sword/sabre

	backpack_contents = list(
		/obj/item/reagent_containers/glass/bottle/aflask,
		/obj/item/flashlight/flare/torch/lantern,
	)
