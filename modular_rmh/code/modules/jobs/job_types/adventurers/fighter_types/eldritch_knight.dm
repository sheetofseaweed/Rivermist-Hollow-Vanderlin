/datum/attribute_holder/sheet/job/advclass/combat/adventurer_fighter/eldritch_knight
	raw_attribute_list = list(
		STAT_STRENGTH = 1,
		STAT_INTELLIGENCE = 1,
		STAT_SPEED = -1,
		/datum/attribute/skill/combat/swords = 30,
		/datum/attribute/skill/combat/wrestling = 10,
		/datum/attribute/skill/combat/unarmed = 20,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/combat/knives = 10,
		/datum/attribute/skill/misc/swimming = 10,
		/datum/attribute/skill/misc/climbing = 20,
		/datum/attribute/skill/misc/reading = 30,
		/datum/attribute/skill/misc/medicine = 10,
		/datum/attribute/skill/misc/sewing = 10,
		/datum/attribute/skill/magic/arcane = 10,
		/datum/attribute/skill/craft/alchemy = 10
	)

/datum/job/advclass/combat/adventurer_fighter/eldritch_knight
	title = "Eldritch Knight"
	tutorial = "You are a warrior of spell and sword, weaving incantations that supplement your extensive martial expertise."

	outfit = /datum/outfit/adventurer_fighter/eldritch_knight
	category_tags = list(CAT_ADVENTURER_FIGHTER)
	give_bank_account = TRUE
	exp_types_granted = list(EXP_TYPE_MERCENARY, EXP_TYPE_COMBAT, EXP_TYPE_MAGICK)

	magic_user = TRUE
	spell_points = 25
	attunements_max = 10
	attunements_min = 5

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_fighter/eldritch_knight


	traits = list(
		TRAIT_MEDIUMARMOR,
		TRAIT_HEAVYARMOR,
		TRAIT_STEELHEARTED,
	)

	spells = list(
		/datum/action/cooldown/spell/projectile/acid_splash,
		/datum/action/cooldown/spell/projectile/arcyne_bolt,
		/datum/action/cooldown/spell/undirected/blade_ward
	)

/datum/job/advclass/combat/adventurer_fighter/eldritch_knight/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()
	var/boundweapons = list("Spear", "Rapier", "Arming Sword", "Longsword", "Greatsword", "Axe", "Greataxe", "Mace", "Flail", "Greatflail")
	var/boundweapon_choice = browser_input_list(spawned, "CHOOSE YOUR WEAPON.", "WHAT DID YOU BIND", boundweapons)

	switch(boundweapon_choice)
		if("Spear")
			spawned.add_spell(/datum/action/cooldown/spell/undirected/conjure_item/conjure_spear)
			spawned.adjust_skillrank(/datum/skill/combat/polearms, 1, TRUE)
		if("Rapier")
			spawned.add_spell(/datum/action/cooldown/spell/undirected/conjure_item/conjure_rapier)
			spawned.adjust_skillrank(/datum/skill/combat/swords, 1, TRUE)
		if("Arming Sword")
			spawned.add_spell(/datum/action/cooldown/spell/undirected/conjure_item/conjure_armingsword)
			spawned.adjust_skillrank(/datum/skill/combat/swords, 1, TRUE)
		if("Longsword")
			spawned.add_spell(/datum/action/cooldown/spell/undirected/conjure_item/conjure_longsword)
			spawned.adjust_skillrank(/datum/skill/combat/swords, 1, TRUE)
		if("Greatsword")
			spawned.add_spell(/datum/action/cooldown/spell/undirected/conjure_item/conjure_greatsword)
			spawned.adjust_skillrank(/datum/skill/combat/swords, 1, TRUE)
		if("Axe")
			spawned.add_spell(/datum/action/cooldown/spell/undirected/conjure_item/conjure_axe)
			spawned.adjust_skillrank(/datum/skill/combat/axesmaces, 1, TRUE)
		if("Greataxe")
			spawned.add_spell(/datum/action/cooldown/spell/undirected/conjure_item/conjure_greataxe)
			spawned.adjust_skillrank(/datum/skill/combat/axesmaces, 1, TRUE)
		if("Mace")
			spawned.add_spell(/datum/action/cooldown/spell/undirected/conjure_item/conjure_mace)
			spawned.adjust_skillrank(/datum/skill/combat/axesmaces, 1, TRUE)
		if("Flail")
			spawned.add_spell(/datum/action/cooldown/spell/undirected/conjure_item/conjure_flail)
			spawned.adjust_skillrank(/datum/skill/combat/whipsflails, 1, TRUE)
		if("Greatflail")
			spawned.add_spell(/datum/action/cooldown/spell/undirected/conjure_item/conjure_greatflail)
			spawned.adjust_skillrank(/datum/skill/combat/whipsflails, 1, TRUE)

/datum/outfit/adventurer_fighter/eldritch_knight
	name = "Eldritch Knight"
	head = null
	mask = null
	neck = /obj/item/clothing/neck/gorget
	cloak = null
	armor = /obj/item/clothing/armor/plate
	shirt = /obj/item/clothing/shirt/tunic
	wrists = /obj/item/clothing/wrists/bracers/leather
	gloves = /obj/item/clothing/gloves/leather
	pants = /obj/item/clothing/pants/trou/leather
	shoes = /obj/item/clothing/shoes/boots/leather
	backr = null
	backl = /obj/item/storage/backpack/satchel
	belt = /obj/item/storage/belt/leather/adventurers_subclasses
	beltl = /obj/item/storage/magebag/poor
	beltr = /obj/item/weapon/sword
	ring = null
	l_hand = null
	r_hand = null
	scabbards = list(/obj/item/weapon/scabbard/sword)

	backpack_contents = list(
		/obj/item/storage/belt/pouch/cloth/coins/poor = 1,
		/obj/item/weapon/knife/dagger = 1,
		/obj/item/reagent_containers/glass/bottle/manapot = 1,
		/obj/item/book/granter/spellbook/apprentice = 1,
		/obj/item/chalk = 1
	)

/datum/outfit/adventurer_fighter/eldritch_knight/pre_equip(mob/living/carbon/human/equipped_human, visuals_only)
	. = ..()
	equipped_human.mana_pool?.set_intrinsic_recharge(MANA_ALL_LEYLINES)
