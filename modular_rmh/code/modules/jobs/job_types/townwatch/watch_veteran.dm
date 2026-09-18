/datum/attribute_holder/sheet/job/watch_veteran
	raw_attribute_list = list(
		STAT_STRENGTH = 2,
		STAT_CONSTITUTION = 2,
		STAT_ENDURANCE = 2,
		STAT_PERCEPTION = 1,
		STAT_INTELLIGENCE = 1,
		STAT_SPEED = 1,
		/datum/attribute/skill/combat/swords = 30,
		/datum/attribute/skill/combat/shields = 30,
		/datum/attribute/skill/combat/wrestling = 20,
		/datum/attribute/skill/combat/unarmed = 20,
		/datum/attribute/skill/combat/axesmaces = 30,
		/datum/attribute/skill/combat/polearms = 30,
		/datum/attribute/skill/combat/bows = 20,
		/datum/attribute/skill/combat/crossbows = 20,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/misc/climbing = 20,
		/datum/attribute/skill/misc/swimming = 20,
		/datum/attribute/skill/misc/reading = 10
	)

/datum/job/watch_veteran
	title = "Town Watch Veteran"
	tutorial = "You are a seasoned veteran of the Town Watch. \
	Years of patrols, riots, night watches, and close calls have hardened you. \
	You train new watchmen, steady patrols in dangerous moments, and serve as an example of discipline. \
	You are not in command — but when trouble starts, others look to you."
	department_flag = TOWNWATCH
	job_flags = (JOB_ANNOUNCE_ARRIVAL | JOB_SHOW_IN_CREDITS | JOB_EQUIP_RANK | JOB_NEW_PLAYER_JOINABLE)
	display_order = JDO_WATCH_VETERAN
	faction = FACTION_TOWN
	total_positions = 1
	spawn_positions = 1

	allowed_ages = list(AGE_MIDDLEAGED, AGE_OLD, AGE_IMMORTAL)
	allowed_races = ALL_RACES_LIST
	selection_color = JCOLOR_TOWNWATCH

	outfit = /datum/outfit/watch_veteran

	give_bank_account = 45

	exp_type = list(EXP_TYPE_LIVING)
	exp_types_granted = list(EXP_TYPE_GARRISON, EXP_TYPE_COMBAT)
	exp_requirements = list(
		EXP_TYPE_LIVING = 500
	)

	job_bitflag = BITFLAG_GARRISON

	attribute_sheet = /datum/attribute_holder/sheet/job/watch_veteran


	traits = list(
		TRAIT_HEAVYARMOR,
		TRAIT_MEDIUMARMOR,
		TRAIT_STEELHEARTED,
		TRAIT_KNOWBANDITS,
		TRAIT_RECOGNIZED,
		TRAIT_TUTELAGE,
		TRAIT_OLDPARTY
	)

/datum/outfit/watch_veteran
	name = "Town Watch Veteran"
	head = /obj/item/clothing/head/helmet/townbarbute
	mask = null
	neck = /obj/item/clothing/neck/gorget
	cloak = /obj/item/clothing/cloak/half/guard
	armor = /obj/item/clothing/armor/plate/iron
	shirt = /obj/item/clothing/armor/gambeson/heavy/colored/town_watch
	wrists = /obj/item/clothing/wrists/bracers/jackchain
	gloves = /obj/item/clothing/gloves/chain/iron
	pants = /obj/item/clothing/pants/chainlegs/iron
	shoes = /obj/item/clothing/shoes/boots/leather/advanced
	backr = /obj/item/storage/backpack/satchel/black
	backl = null
	belt = /obj/item/storage/belt/leather/town_watch
	beltr = null
	beltl = /obj/item/weapon/mace/stunmace
	ring = /obj/item/clothing/ring/slave_control
	l_hand = null
	r_hand = null

	backpack_contents = list(
		/obj/item/clothing/neck/slave_collar,
		/obj/item/reagent_containers/glass/bottle/stronghealthpot,
		/obj/item/flashlight/flare/torch/lantern,
	)

/datum/job/watch_veteran/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()
	var/weapons = list("Sword + Shield", "Sword + Longbow", "Sword + Crossbow", "Zweihander", "Halberd")
	var/weapon_choice = browser_input_list(spawned, "CHOOSE YOUR WEAPON.", "TAKE UP ARMS", weapons)

	switch(weapon_choice)
		if("Sword + Shield")
			spawned.put_in_hands(new /obj/item/weapon/sword/arming(get_turf(spawned)), TRUE)
			spawned.put_in_hands(new /obj/item/weapon/scabbard/sword(get_turf(spawned)), TRUE)
			spawned.equip_to_slot_or_del(new /obj/item/weapon/shield/heater, ITEM_SLOT_BACK_L, TRUE)
		if("Sword + Longbow")
			spawned.put_in_hands(new /obj/item/weapon/sword/arming(get_turf(spawned)), TRUE)
			spawned.put_in_hands(new /obj/item/weapon/scabbard/sword(get_turf(spawned)), TRUE)
			spawned.equip_to_slot_or_del(new /obj/item/ammo_holder/quiver/arrows, ITEM_SLOT_BELT_L, TRUE)
			spawned.equip_to_slot_or_del(new /obj/item/gun/ballistic/revolver/grenadelauncher/bow/long, ITEM_SLOT_BACK_L, TRUE)
		if("Sword + Crossbow")
			spawned.put_in_hands(new /obj/item/weapon/sword/arming(get_turf(spawned)), TRUE)
			spawned.put_in_hands(new /obj/item/weapon/scabbard/sword(get_turf(spawned)), TRUE)
			spawned.equip_to_slot_or_del(new /obj/item/gun/ballistic/revolver/grenadelauncher/crossbow, ITEM_SLOT_BACK_L, TRUE)
			spawned.equip_to_slot_or_del(new /obj/item/ammo_holder/quiver/bolts, ITEM_SLOT_BELT_L, TRUE)
		if("Zweihander")
			spawned.put_in_hands(new /obj/item/weapon/sword/long/greatsword/zwei(get_turf(spawned)), TRUE)
		if("Halberd")
			spawned.put_in_hands(new /obj/item/weapon/polearm/halberd(get_turf(spawned)), TRUE)

	spawned.verbs |= /mob/proc/haltyell
