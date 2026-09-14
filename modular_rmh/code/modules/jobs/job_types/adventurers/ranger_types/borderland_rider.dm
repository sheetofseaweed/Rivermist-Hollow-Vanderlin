/datum/attribute_holder/sheet/job/advclass/combat/adventurer_ranger/borderland_rider
	raw_attribute_list = list(
		/datum/attribute/skill/misc/hunting = 10,
		/datum/attribute/skill/misc/tracking = 20,
		STAT_STRENGTH = 1,
		STAT_SPEED = 2,
		STAT_ENDURANCE = 2,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/combat/swords = 40,
		/datum/attribute/skill/combat/whipsflails = 20,
		// Makes sense enough for an animal tamer
		/datum/attribute/skill/combat/wrestling = 20,
		/datum/attribute/skill/combat/unarmed = 20,
		/datum/attribute/skill/misc/swimming = 20,
		/datum/attribute/skill/misc/climbing = 30,
		/datum/attribute/skill/misc/riding = 50,
		/datum/attribute/skill/labor/taming = 40,
		// How did they not have this skill before?!
		/datum/attribute/skill/craft/cooking = 10,
		/datum/attribute/skill/misc/sneaking = 30,
		/datum/attribute/skill/misc/stealing = 40,
		/datum/attribute/skill/misc/lockpicking = 10,
		/datum/attribute/skill/misc/reading = 20,
		/datum/attribute/skill/misc/music = 20
	)

/datum/job/advclass/combat/adventurer_ranger/borderland_rider
	title = "Borderland Rider"
	tutorial = "A wandering Tiefling rider and beast master, swift of foot and deadly with whip and sword across the wilds."

	allowed_races = list(SPEC_ID_TIEFLING)
	outfit = /datum/outfit/adventurer_ranger/borderland_rider
	category_tags = list(CAT_ADVENTURER_RANGER)
	give_bank_account = TRUE

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_ranger/borderland_rider


	traits = list(
		TRAIT_DODGEEXPERT,
	)

/datum/outfit/adventurer_ranger/borderland_rider
	name = "Borderland Rider"
	head = /obj/item/clothing/head/bardhat
	mask = /obj/item/alch/herb/rosa
	neck = /obj/item/clothing/neck/chaincoif
	cloak = /obj/item/clothing/cloak/half/colored/red
	armor = /obj/item/clothing/armor/leather/vest
	shirt = /obj/item/clothing/shirt/undershirt
	wrists = null
	gloves = null
	pants = /obj/item/clothing/pants/tights/colored/random
	shoes = /obj/item/clothing/shoes/boots
	backr = null
	backl = /obj/item/storage/backpack/satchel
	belt = /obj/item/storage/belt/leather/adventurers_subclasses
	beltl = /obj/item/weapon/sword/rapier
	beltr = /obj/item/weapon/whip
	ring = null
	l_hand = null
	r_hand = null

/datum/job/advclass/combat/adventurer_ranger/borderland_rider/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()
	spawned.update_sight()
	var/mounts = list("White Female", "White Male", "Black Female", "Black Male", "Brown Female", "Brown Male")
	var/mount_choice = browser_input_list(spawned, "CHOOSE YOUR MOUNT.", "YOUR HORSE", mounts)

	switch(mount_choice)
		if("White Female")
			spawned.add_spell(/datum/action/cooldown/spell/conjure/summon_horse)
		if("White Male")
			spawned.add_spell(/datum/action/cooldown/spell/conjure/summon_horse/male)
		if("Black Female")
			spawned.add_spell(/datum/action/cooldown/spell/conjure/summon_horse/black)
		if("Black Male")
			spawned.add_spell(/datum/action/cooldown/spell/conjure/summon_horse/black_male)
		if("Brown Female")
			spawned.add_spell(/datum/action/cooldown/spell/conjure/summon_horse/brown)
		if("Brown Male")
			spawned.add_spell(/datum/action/cooldown/spell/conjure/summon_horse/brown_male)
