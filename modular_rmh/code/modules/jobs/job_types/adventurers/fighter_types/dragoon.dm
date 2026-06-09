/datum/attribute_holder/sheet/job/advclass/combat/adventurer_fighter/dragoon
	raw_attribute_list = list(
		STAT_STRENGTH = 2,
		STAT_ENDURANCE = 2,
		STAT_SPEED = -1,
		STAT_INTELLIGENCE = -1,
		/datum/attribute/skill/misc/riding = 40,
		/datum/attribute/skill/combat/polearms = 30,
		/datum/attribute/skill/labor/taming = 30,
		/datum/attribute/skill/combat/bows = 20,
		/datum/attribute/skill/combat/swords = 20,
		/datum/attribute/skill/combat/unarmed = 20,
		/datum/attribute/skill/craft/tanning = 20,
		/datum/attribute/skill/combat/wrestling = 20,
		/datum/attribute/skill/craft/crafting = 10,
		/datum/attribute/skill/misc/climbing = 10,
		/datum/attribute/skill/misc/reading = 10,
		/datum/attribute/skill/misc/athletics = 30
	)

/datum/job/advclass/combat/adventurer_fighter/dragoon
	title = "Dragoon"
	tutorial = "Hailing from the plains near Elturel, this mounted warrior rides into battle with lance and sword, \
	offering their martial skill to any who can pay. Clad in salvaged armor, they are as disciplined on horseback as they are deadly on foot"

	outfit = /datum/outfit/adventurer_fighter/dragoon
	category_tags = list(CAT_ADVENTURER_FIGHTER)
	give_bank_account = TRUE

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_fighter/dragoon


	traits = list(
		TRAIT_HEAVYARMOR,
		TRAIT_DEADNOSE
	)

/datum/outfit/adventurer_fighter/dragoon
	name = "Dragoon"
	head = /obj/item/clothing/head/helmet/heavy/rust
	mask = null
	neck = /obj/item/clothing/neck/gorget
	cloak = null
	armor = /obj/item/clothing/armor/plate/rust
	shirt = /obj/item/clothing/armor/gambeson/light
	wrists = /obj/item/clothing/wrists/bracers/leather
	gloves = /obj/item/clothing/gloves/plate/rust
	pants = /obj/item/clothing/pants/platelegs/rust
	shoes = /obj/item/clothing/shoes/boots/armor/light/rust
	backl = /obj/item/storage/backpack/satchel
	backr = /obj/item/weapon/polearm/spear
	belt = /obj/item/storage/belt/leather/adventurers_subclasses
	beltl = /obj/item/weapon/sword
	beltr = /obj/item/flashlight/flare/torch/lantern
	ring = null
	l_hand = null
	r_hand = null

	scabbards = list(/obj/item/weapon/scabbard/sword)

	backpack_contents = list(
		/obj/item/storage/belt/pouch/cloth/coins/poor = 1,
		/obj/item/weapon/knife/dagger = 1
	)

/datum/job/advclass/combat/adventurer_fighter/dragoon/after_spawn(mob/living/carbon/human/spawned, client/player_client)
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
