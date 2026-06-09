/datum/attribute_holder/sheet/job/watch_captain
	raw_attribute_list = list(
		STAT_STRENGTH = 3,
		STAT_PERCEPTION = 3,
		STAT_INTELLIGENCE = 2,
		STAT_CONSTITUTION = 3,
		STAT_ENDURANCE = 3,
		STAT_SPEED = 2,
		/datum/attribute/skill/combat/swords = 40,
		/datum/attribute/skill/combat/shields = 40,
		/datum/attribute/skill/combat/wrestling = 30,
		/datum/attribute/skill/combat/unarmed = 30,
		/datum/attribute/skill/combat/axesmaces = 30,
		/datum/attribute/skill/combat/polearms = 30,
		/datum/attribute/skill/combat/bows = 30,
		/datum/attribute/skill/combat/crossbows = 30,
		/datum/attribute/skill/combat/firearms = 30,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/misc/swimming = 20,
		/datum/attribute/skill/misc/climbing = 20,
		/datum/attribute/skill/misc/riding = 20,
		/datum/attribute/skill/misc/reading = 30,
		/datum/attribute/skill/labor/mathematics = 20
	)

/datum/job/watch_captain
	title = "Town Watch Captain"
	tutorial = "You are the Captain of the Town Watch of Rivermist Hollow. \
	You are responsible for organizing patrols, maintaining order, and coordinating the defense of the town. \
	You command the city watchmen, veterans, militia, and any hired auxiliaries. \
	You answer directly to the Burgmeister and guard them with your life."
	department_flag = TOWNWATCH
	job_flags = (JOB_ANNOUNCE_ARRIVAL | JOB_SHOW_IN_CREDITS | JOB_EQUIP_RANK | JOB_NEW_PLAYER_JOINABLE)
	display_order = JDO_WATCH_CAPTAIN
	faction = FACTION_TOWN
	total_positions = 1
	spawn_positions = 1

	allowed_ages = list(AGE_ADULT, AGE_MIDDLEAGED, AGE_OLD, AGE_IMMORTAL)
	allowed_races = ALL_RACES_LIST
	selection_color = JCOLOR_TOWNWATCH

	outfit = /datum/outfit/watch_captain
	spells = list(/datum/action/cooldown/spell/undirected/list_target/convert_role/town_watch)

	give_bank_account = 80

	exp_type = list(EXP_TYPE_LIVING)
	exp_types_granted = list(EXP_TYPE_GARRISON, EXP_TYPE_COMBAT, EXP_TYPE_LEADERSHIP)
	exp_requirements = list(
		EXP_TYPE_LIVING = 800
	)

	job_bitflag = BITFLAG_GARRISON

	attribute_sheet = /datum/attribute_holder/sheet/job/watch_captain


	traits = list(
		TRAIT_HEAVYARMOR,
		TRAIT_MEDIUMARMOR,
		TRAIT_KNOWBANDITS,
		TRAIT_RECOGNIZED,
		TRAIT_BREADY
	)

/datum/job/watch_captain/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()
	grant_outlaw_decree(spawned)
	spawned.verbs |= /mob/proc/haltyell

/mob/proc/haltyell()
	set name = "HALT!"
	set category = "Noises"
	emote("haltyell")

/datum/outfit/watch_captain
	name = "Town Watch Captain"
	head = /obj/item/clothing/head/helmet/sargebarbute
	mask = null
	neck = /obj/item/clothing/neck/gorget
	cloak = /obj/item/clothing/cloak/captain/town_watch
	armor = /obj/item/clothing/armor/plate
	shirt = /obj/item/clothing/armor/gambeson/heavy/colored/town_watch
	wrists = /obj/item/clothing/wrists/bracers/jackchain
	gloves = /obj/item/clothing/gloves/plate
	pants = /obj/item/clothing/pants/chainlegs
	shoes = /obj/item/clothing/shoes/boots/armor/light
	backr = /obj/item/storage/backpack/satchel/black
	backl = /obj/item/weapon/shield/tower/metal
	belt = /obj/item/storage/belt/leather/steel/watch_captain
	beltr = /obj/item/weapon/scabbard/sword/noble
	beltl = /obj/item/weapon/mace/stunmace
	ring = /obj/item/clothing/ring/slave_control
	l_hand = /obj/item/weapon/sword/decorated
	r_hand = null

	backpack_contents = list(
		/obj/item/storage/belt/pouch/cloth/bullets,
		/obj/item/reagent_containers/glass/bottle/aflask,
		/obj/item/gun/ballistic/revolver/grenadelauncher/pistol,
		/obj/item/clothing/neck/slave_collar,
		/obj/item/reagent_containers/glass/bottle/stronghealthpot,
		/obj/item/flashlight/flare/torch/lantern,
	)

/datum/outfit/watch_captain/pre_equip(mob/living/carbon/human/equipped_human, visuals_only)
	. = ..()

//CONVERSION

/datum/action/cooldown/spell/undirected/list_target/convert_role/town_watch
	name = "Recruit Town Watch"
	button_icon_state = "recruit_guard"

	new_role = "Town Watch Militia"
	recruitment_faction = "Town Watch"
	recruitment_message = "Join the Town Watch, %RECRUIT!"
	accept_message = "I swear fealty to the Burgmeister and the Town Watch!"
	refuse_message = "I refuse."

/datum/action/cooldown/spell/undirected/list_target/convert_role/town_watch/on_conversion(mob/living/cast_on)
	. = ..()
	cast_on.verbs |= /mob/proc/haltyell
