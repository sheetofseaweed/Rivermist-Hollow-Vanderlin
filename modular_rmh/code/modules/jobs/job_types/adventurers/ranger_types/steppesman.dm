/datum/attribute_holder/sheet/job/advclass/combat/adventurer_ranger/steppesman
	raw_attribute_list = list(
		STAT_STRENGTH = 1,
		STAT_ENDURANCE = 1,
		STAT_PERCEPTION = 1,
		/datum/attribute/skill/combat/whipsflails = 20,
		/datum/attribute/skill/combat/knives = 10,
		/datum/attribute/skill/combat/wrestling = 20,
		/datum/attribute/skill/combat/unarmed = 20,
		/datum/attribute/skill/misc/riding = 50,
		// I don't think riding skill has that big of an effect
		/datum/attribute/skill/misc/sewing = 10,
		/datum/attribute/skill/craft/crafting = 10,
		/datum/attribute/skill/craft/tanning = 20,
		/datum/attribute/skill/misc/swimming = 10,
		/datum/attribute/skill/misc/reading = 10,
		/datum/attribute/skill/craft/cooking = 10,
		/datum/attribute/skill/misc/climbing = 30,
		/datum/attribute/skill/misc/sneaking = 30,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/combat/swords = 30,
		/datum/attribute/skill/combat/bows = 30,
		/datum/attribute/skill/labor/taming = 30
	)

/datum/job/advclass/combat/adventurer_ranger/steppesman
	title = "Steppesman"
	tutorial = "A mercenary hailing from the wild frontier steppes. There are three things you value most; mounts, freedom, and coin."

	outfit = /datum/outfit/adventurer_ranger/steppesman
	category_tags = list(CAT_ADVENTURER_RANGER)
	give_bank_account = TRUE


	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_ranger/steppesman


	traits = list(
		TRAIT_DUALWIELDER,
		TRAIT_DODGEEXPERT,
	)

/datum/outfit/adventurer_ranger/steppesman
	name = "Steppesman"
	head = /obj/item/clothing/head/helmet/bascinet/steppe
	mask = /obj/item/clothing/face/facemask/steel/steppe
	neck = null
	cloak = null
	armor = /obj/item/clothing/armor/medium/scale/steppe
	shirt = /obj/item/clothing/armor/gambeson/light/steppe
	wrists = /obj/item/clothing/wrists/bracers/leather
	gloves = /obj/item/clothing/gloves/leather
	pants = /obj/item/clothing/pants/tights/colored/red
	shoes = /obj/item/clothing/shoes/boots/leather
	backl = /obj/item/gun/ballistic/revolver/grenadelauncher/bow/short
	backr = /obj/item/storage/backpack/backpack/longhike/with_bedroll
	belt = /obj/item/storage/belt/leather/black/adventurers_subclasses
	beltr = /obj/item/weapon/sword/long/rider/steppe
	beltl = /obj/item/ammo_holder/quiver/arrows
	ring = null
	l_hand = null
	r_hand = null

	scabbards = list(/obj/item/weapon/scabbard/sword)
	backpack_contents = list(
		/obj/item/weapon/knife/hunting = 1,
		/obj/item/tent_kit = 1
	)

/datum/job/advclass/combat/adventurer_ranger/steppesman/after_spawn(mob/living/carbon/human/spawned, client/player_client)
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
