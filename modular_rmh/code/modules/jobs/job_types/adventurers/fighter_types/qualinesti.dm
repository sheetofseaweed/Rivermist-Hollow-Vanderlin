/datum/attribute_holder/sheet/job/advclass/combat/adventurer_fighter/qualinesti
	raw_attribute_list = list(
		STAT_ENDURANCE = 2,
		STAT_STRENGTH = 1,
		STAT_SPEED = 2,
		/datum/attribute/skill/combat/knives = 30,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/combat/unarmed = 20,
		/datum/attribute/skill/combat/wrestling = 20,
		/datum/attribute/skill/misc/sneaking = 10,
		/datum/attribute/skill/misc/swimming = 20,
		/datum/attribute/skill/misc/climbing = 30,
		/datum/attribute/skill/misc/medicine = 10,
		/datum/attribute/skill/combat/swords = 30,
		/datum/attribute/skill/combat/shields = 30,
		/datum/attribute/skill/misc/reading = 20,
		/datum/attribute/skill/misc/riding = 30
	)

/datum/job/advclass/combat/adventurer_fighter/qualinesti
	title = "Fallen Qualinesti Knight"
	tutorial = "Once a proud knight of the Qualinesti elves, skilled in sword and shield and trained for aerial combat, \
	this elf now wanders Faerûn as a sellsword, offering martial discipline to the highest bidder."

	allowed_races = RACES_PLAYER_ELF_ALL
	outfit = /datum/outfit/adventurer_fighter/qualinesti
	category_tags = list(CAT_ADVENTURER_FIGHTER)
	give_bank_account = TRUE

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_fighter/qualinesti


	traits = list(
		TRAIT_MEDIUMARMOR
	)

/datum/outfit/adventurer_fighter/qualinesti
	name = "Fallen Qualinesti Knight"
	head = /obj/item/clothing/head/helmet/pegasusknight
	mask = null
	neck = null
	cloak = /obj/item/clothing/cloak/pegasusknight
	armor = /obj/item/clothing/armor/gambeson
	shirt = /obj/item/clothing/armor/chainmail/iron
	wrists = /obj/item/clothing/wrists/bracers/leather
	gloves = /obj/item/clothing/gloves/angle
	pants = /obj/item/clothing/pants/trou/leather
	shoes = /obj/item/clothing/shoes/ridingboots
	backl = /obj/item/storage/backpack/satchel
	backr = /obj/item/weapon/shield/tower/buckleriron
	belt = /obj/item/storage/belt/leather/black/adventurers_subclasses
	beltr = /obj/item/weapon/sword/long/shotel
	beltl = /obj/item/weapon/knife/dagger/steel/njora
	ring = null
	l_hand = null
	r_hand = null

	backpack_contents = list(/obj/item/storage/belt/pouch/cloth/coins/poor = 1)

/datum/job/advclass/combat/adventurer_fighter/qualinesti/after_spawn(mob/living/carbon/human/spawned, client/player_client)
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
