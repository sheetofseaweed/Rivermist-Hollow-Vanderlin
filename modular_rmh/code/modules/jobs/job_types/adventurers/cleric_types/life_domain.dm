/datum/attribute_holder/sheet/job/advclass/combat/adventurer_cleric/life_domain
	raw_attribute_list = list(
		STAT_STRENGTH = 1,
		STAT_INTELLIGENCE = 2,
		STAT_CONSTITUTION = 2,
		STAT_ENDURANCE = 2,
		STAT_SPEED = -1,
		/datum/attribute/skill/combat/wrestling = 20,
		/datum/attribute/skill/combat/unarmed = 20,
		/datum/attribute/skill/misc/climbing = 20,
		/datum/attribute/skill/misc/swimming = 10,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/misc/reading = 30,
		/datum/attribute/skill/magic/holy = 40,
		/datum/attribute/skill/craft/cooking = 10,
		/datum/attribute/skill/misc/sewing = 10,
		/datum/attribute/skill/misc/medicine = 20,
		/datum/attribute/skill/labor/mathematics = 20
	)

/datum/job/advclass/combat/adventurer_cleric/life_domain
	title = "Life Domain"
	tutorial = "Tasked with the holy edict of preserving the body, mind, and soul, your god grants you a plethora of healing magics."

	outfit = /datum/outfit/adventurer_cleric/life_domain
	category_tags = list(CAT_ADVENTURER_CLERIC)
	give_bank_account = TRUE

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_cleric/life_domain


	traits = list(
		TRAIT_MEDIUMARMOR,
		TRAIT_STEELHEARTED,
		TRAIT_HOLY,
	)

	languages = list(/datum/language/celestial)

	spells = list(
		/datum/action/cooldown/spell/undirected/touch/orison,
		/datum/action/cooldown/spell/healing,
		/datum/action/cooldown/spell/healing/greater,
		/datum/action/cooldown/spell/attach_bodypart,
		/datum/action/cooldown/spell/diagnose/holy,
		/datum/action/cooldown/spell/cure_rot,
		/datum/action/cooldown/spell/revive,
		/datum/action/cooldown/spell/essence/healing_spring,
		/datum/action/cooldown/spell/status/guidance,
		/datum/action/cooldown/spell/sacred_flame,
		/datum/action/cooldown/spell/undirected/blade_ward,
	)

/datum/job/advclass/combat/adventurer_cleric/life_domain/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()

	var/holder = spawned.patron?.devotion_holder
	if(holder)
		var/datum/devotion/devotion = new holder()
		devotion.make_cleric()
		devotion.grant_to(spawned)

	var/list/selectableweapon = list(
		"Sword" = /obj/item/weapon/sword/iron,
		"Axe" = /obj/item/weapon/axe/iron,
		"Mace" = /obj/item/weapon/mace/bludgeon,
		"Spear" = /obj/item/weapon/polearm/spear,
		"Flail" = /obj/item/weapon/flail,
		"Great flail" = /obj/item/weapon/flail/peasant,
		"Goedendag" = /obj/item/weapon/mace/goden,
		"Great axe" = /obj/item/weapon/polearm/halberd/bardiche/woodcutter,
	)

	var/weaponchoice = spawned.select_equippable(player_client, selectableweapon, message = "Choose Your Specialisation", title = "Warrior of the gods!")
	if(!weaponchoice)
		return

	var/grant_shield = TRUE
	var/weapon_skill_path

	switch(weaponchoice)
		if("Sword")
			weapon_skill_path = /datum/skill/combat/swords
		if("Axe", "Mace", "Goedendag", "Great axe")
			weapon_skill_path = /datum/skill/combat/axesmaces
		if("Spear")
			weapon_skill_path = /datum/skill/combat/polearms
		if("Flail", "Great flail")
			weapon_skill_path = /datum/skill/combat/whipsflails

	if(weapon_skill_path)
		spawned.adjust_skillrank(weapon_skill_path, 3, TRUE)

	switch(weaponchoice)
		if("Great flail", "Goedendag", "Great axe")
			grant_shield = FALSE
		if("Spear")
			var/obj/item/weapon/shield/tower/buckleriron/buckler = new /obj/item/weapon/shield/tower/buckleriron()
			if(!spawned.equip_to_appropriate_slot(buckler))
				qdel(buckler)
			grant_shield = FALSE

	if(grant_shield)
		var/shield_path = /obj/item/weapon/shield/wood
		var/obj/item/shield = new shield_path()
		if(!spawned.equip_to_appropriate_slot(shield))
			qdel(shield)


/datum/outfit/adventurer_cleric/life_domain
	name = "Life Domain"
	head = /obj/item/clothing/head/helmet/leather/headscarf
	mask = null
	neck = /obj/item/clothing/neck/highcollier/iron
	cloak = /obj/item/clothing/cloak/tabard
	armor = /obj/item/clothing/armor/chainmail/iron
	shirt = /obj/item/clothing/armor/gambeson
	wrists = /obj/item/clothing/wrists/bracers/leather
	gloves = /obj/item/clothing/gloves/leather
	pants = /obj/item/clothing/pants/chainlegs/iron
	shoes = /obj/item/clothing/shoes/boots/leather
	backr = null
	backl = /obj/item/storage/backpack/satchel
	belt = /obj/item/storage/belt/leather/adventurers_subclasses
	beltl = null
	beltr = null
	ring = null
	l_hand = null
	r_hand = /obj/item/flashlight/flare/torch/prelit

	backpack_contents = list(/obj/item/storage/belt/pouch/cloth/coins/poor = 1, /obj/item/reagent_containers/food/snacks/hardtack = 1)

/datum/outfit/adventurer_cleric/life_domain/pre_equip(mob/living/carbon/human/equipped_human, visuals_only)
	. = ..()
	equipped_human.mana_pool?.set_intrinsic_recharge(MANA_ALL_LEYLINES)

