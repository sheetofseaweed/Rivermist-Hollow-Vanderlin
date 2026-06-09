/datum/attribute_holder/sheet/job/advclass/combat/adventurer_fighter/hedgeknight
	raw_attribute_list = list(
		STAT_STRENGTH = 2,
		STAT_ENDURANCE = 2,
		STAT_CONSTITUTION = 2,
		STAT_SPEED = -1,
		/datum/attribute/skill/combat/wrestling = 20,
		/datum/attribute/skill/combat/unarmed = 30,
		/datum/attribute/skill/combat/swords = 40,
		/datum/attribute/skill/misc/climbing = 10,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/misc/reading = 20
	)

/datum/job/advclass/combat/adventurer_fighter/hedgeknight
	title = "Hedge Knight"
	tutorial = "A wandering hedge knight, mastering the sword and upholding the code of honor across Faerûn."

	allowed_races = list(SPEC_ID_HUMEN, SPEC_ID_AASIMAR)
	allowed_sexes = list(MALE)

	outfit = /datum/outfit/adventurer_fighter/hedgeknight
	category_tags = list(CAT_ADVENTURER_FIGHTER)
	give_bank_account = TRUE
	honorary = "Sir"
	honorary_f = "Dame"

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_fighter/hedgeknight


	traits = list(
		TRAIT_HEAVYARMOR,
		TRAIT_STEELHEARTED,
	)

/datum/job/advclass/combat/adventurer_fighter/hedgeknight/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()
	var/datum/species/species = spawned.dna?.species
	if(species && species.id == SPEC_ID_HUMEN)
		species.soundpack_m = new /datum/voicepack/male/knight()

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

/datum/outfit/adventurer_fighter/hedgeknight
	name = "Hedge Knight (Folkhero)"
	head = /obj/item/clothing/head/rare/grenzelplate
	mask = null
	neck = /obj/item/clothing/neck/chaincoif
	cloak = null
	armor = /obj/item/clothing/armor/rare/grenzelplate
	shirt = /obj/item/clothing/armor/gambeson
	wrists = /obj/item/clothing/wrists/bracers
	gloves = /obj/item/clothing/gloves/rare/grenzelplate
	pants = /obj/item/clothing/pants/tights/colored/black
	shoes = /obj/item/clothing/shoes/boots/rare/grenzelplate
	backr = /obj/item/weapon/sword/long/greatsword/flamberge
	backl = /obj/item/storage/backpack/satchel
	belt = /obj/item/storage/belt/leather/adventurers_subclasses
	beltl = /obj/item/storage/belt/pouch/cloth/coins/mid
	beltr = null
	ring = null
	l_hand = null
	r_hand = null
