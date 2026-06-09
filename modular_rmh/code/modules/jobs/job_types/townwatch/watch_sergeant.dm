/datum/attribute_holder/sheet/job/watch_sergeant
	raw_attribute_list = list(
		STAT_STRENGTH = 3,
		STAT_PERCEPTION = 2,
		STAT_INTELLIGENCE = 1,
		STAT_CONSTITUTION = 3,
		STAT_ENDURANCE = 3,
		STAT_SPEED = 2,
		/datum/attribute/skill/combat/swords = 30,
		/datum/attribute/skill/combat/shields = 30,
		/datum/attribute/skill/combat/wrestling = 40,
		/datum/attribute/skill/combat/unarmed = 30,
		/datum/attribute/skill/combat/axesmaces = 30,
		/datum/attribute/skill/combat/polearms = 30,
		/datum/attribute/skill/combat/bows = 30,
		/datum/attribute/skill/combat/crossbows = 30,
		/datum/attribute/skill/combat/firearms = 30,
		/datum/attribute/skill/misc/athletics = 40,
		/datum/attribute/skill/misc/swimming = 20,
		/datum/attribute/skill/misc/climbing = 30,
		/datum/attribute/skill/misc/reading = 20
	)

/datum/job/watch_sergeant
	title = "Town Watch Sergeant"
	tutorial = "You are a Sergeant of the Town Watch of Rivermist Hollow. \
	You lead patrols, enforce discipline among the watchmen, and act as the Captain’s right hand in the streets. \
	You are responsible for training recruits, responding to disturbances, and ensuring the Captain’s orders are followed. \
	While you do not command the Watch, you are its backbone."
	department_flag = TOWNWATCH
	job_flags = (JOB_ANNOUNCE_ARRIVAL | JOB_SHOW_IN_CREDITS | JOB_EQUIP_RANK | JOB_NEW_PLAYER_JOINABLE)
	display_order = JDO_WATCH_SERGEANT
	faction = FACTION_TOWN
	total_positions = 1
	spawn_positions = 1

	allowed_ages = list(AGE_ADULT, AGE_MIDDLEAGED, AGE_OLD, AGE_IMMORTAL)
	allowed_races = ALL_RACES_LIST
	selection_color = JCOLOR_TOWNWATCH

	outfit = /datum/outfit/watch_sergeant

	give_bank_account = 55

	exp_type = list(EXP_TYPE_LIVING)
	exp_types_granted = list(EXP_TYPE_GARRISON, EXP_TYPE_COMBAT)
	exp_requirements = list(
		EXP_TYPE_LIVING = 450
	)

	job_bitflag = BITFLAG_GARRISON

	attribute_sheet = /datum/attribute_holder/sheet/job/watch_sergeant


	traits = list(
		TRAIT_HEAVYARMOR,
		TRAIT_MEDIUMARMOR,
		TRAIT_KNOWBANDITS,
		TRAIT_RECOGNIZED,
		TRAIT_BREADY
	)

/datum/outfit/watch_sergeant
	name = "Town Watch Sergeant"
	head = /obj/item/clothing/head/helmet/kettle/slit/atarms/town_watch
	mask = null
	neck = /obj/item/clothing/neck/gorget
	cloak = /obj/item/clothing/cloak/half/guard
	armor = /obj/item/clothing/armor/cuirass
	shirt = /obj/item/clothing/armor/gambeson/heavy/colored/town_watch
	wrists = /obj/item/clothing/wrists/bracers/jackchain
	gloves = /obj/item/clothing/gloves/chain/iron
	pants = /obj/item/clothing/pants/chainlegs/iron
	shoes = /obj/item/clothing/shoes/boots/armor/light
	backr = /obj/item/storage/backpack/satchel/black
	backl = /obj/item/weapon/shield/heater
	belt = /obj/item/storage/belt/leather/town_watch
	beltr = /obj/item/weapon/scabbard/sword
	beltl = /obj/item/weapon/mace/stunmace
	ring = /obj/item/clothing/ring/slave_control
	l_hand = /obj/item/weapon/sword/sabre
	r_hand = null

	backpack_contents = list(
		/obj/item/storage/belt/pouch/cloth/bullets,
		/obj/item/reagent_containers/glass/bottle/aflask,
		/obj/item/gun/ballistic/revolver/grenadelauncher/pistol,
		/obj/item/clothing/neck/slave_collar,
		/obj/item/reagent_containers/glass/bottle/stronghealthpot,
		/obj/item/flashlight/flare/torch/lantern,
	)

/datum/job/watch_sergeant/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()
	spawned.verbs |= /mob/proc/haltyell
