/datum/attribute_holder/sheet/job/advclass/combat/adventurer_cleric/war_domain
	raw_attribute_list = list(
		STAT_STRENGTH = 2,
		STAT_CONSTITUTION = 2,
		STAT_ENDURANCE = 2,
		STAT_SPEED = -1,
		/datum/attribute/skill/combat/wrestling = 30,
		/datum/attribute/skill/combat/unarmed = 30,
		/datum/attribute/skill/misc/climbing = 20,
		/datum/attribute/skill/misc/swimming = 20,
		/datum/attribute/skill/misc/athletics = 40,
		/datum/attribute/skill/misc/reading = 10,
		/datum/attribute/skill/magic/holy = 20,
		/datum/attribute/skill/labor/mathematics = 10
	)

/datum/job/advclass/combat/adventurer_cleric/war_domain
	title = "War Domain"
	tutorial = "Fortified by holy zeal, you brandish an arsenal of sacramental savagery to use against those you deem unrighteous."

	outfit = /datum/outfit/adventurer_cleric/war_domain
	category_tags = list(CAT_ADVENTURER_CLERIC)
	give_bank_account = TRUE

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_cleric/war_domain


	traits = list(
		TRAIT_MEDIUMARMOR,
		TRAIT_HEAVYARMOR,
		TRAIT_STEELHEARTED,
		TRAIT_HOLY,
	)

	languages = list(/datum/language/celestial)

	spells = list(
		/datum/action/cooldown/spell/undirected/touch/orison,
		/datum/action/cooldown/spell/healing,
		/datum/action/cooldown/spell/essence/silence,
		/datum/action/cooldown/spell/status/guidance,
		/datum/action/cooldown/spell/sacred_flame,
		/datum/action/cooldown/spell/undirected/blade_ward,
		/datum/action/cooldown/spell/aoe/churn_undead,
		/datum/action/cooldown/spell/undirected/divine_strike
	)

/datum/job/advclass/combat/adventurer_cleric/war_domain/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()

	var/holder = spawned.patron?.devotion_holder
	if(holder)
		var/datum/devotion/devotion = new holder()
		devotion.make_cleric()
		devotion.grant_to(spawned)

	var/list/selectableweapon = list(
		"Messer" = /obj/item/weapon/sword/scimitar/messer,
		"Axe" = /obj/item/weapon/axe/iron,
		"Warhammer" = /obj/item/weapon/mace/warhammer,
		"Spear" = /obj/item/weapon/polearm/spear,
		"Flail" = /obj/item/weapon/flail,
		"Great flail" = /obj/item/weapon/flail/peasant,
		"Goedendag" = /obj/item/weapon/mace/goden,
		"Claymor" = /obj/item/weapon/sword/long/greatsword/claymore/iron,
	)

	var/weaponchoice = spawned.select_equippable(player_client, selectableweapon, message = "Choose Your Specialisation", title = "Warrior of the gods!")
	if(!weaponchoice)
		return

	var/grant_shield = TRUE
	var/weapon_skill_path

	switch(weaponchoice)
		if("Messer","Claymor")
			weapon_skill_path = /datum/skill/combat/swords
		if("Axe", "Warhammer", "Goedendag")
			weapon_skill_path = /datum/skill/combat/axesmaces
		if("Spear")
			weapon_skill_path = /datum/skill/combat/polearms
		if("Flail", "Great flail")
			weapon_skill_path = /datum/skill/combat/whipsflails

	if(weapon_skill_path)
		spawned.adjust_skillrank(weapon_skill_path, 3, TRUE)

	switch(weaponchoice)
		if("Great flail", "Goedendag", "Claymor")
			grant_shield = FALSE
		if("Spear")
			var/obj/item/weapon/shield/tower/buckleriron/buckler = new /obj/item/weapon/shield/tower/buckleriron()
			if(!spawned.equip_to_appropriate_slot(buckler))
				qdel(buckler)
			grant_shield = FALSE

	if(grant_shield)
		var/shield_path = /obj/item/weapon/shield/heater
		var/obj/item/shield = new shield_path()
		if(!spawned.equip_to_appropriate_slot(shield))
			qdel(shield)


/datum/outfit/adventurer_cleric/war_domain
	name = "War Domain"
	head = /obj/item/clothing/head/helmet/visored/sallet/iron
	mask = null
	neck = /obj/item/clothing/neck/bevor/iron
	cloak = /obj/item/clothing/cloak/tabard
	armor = /obj/item/clothing/armor/plate/iron
	shirt = /obj/item/clothing/armor/gambeson/light
	wrists = /obj/item/clothing/wrists/bracers/iron
	gloves = /obj/item/clothing/gloves/chain/iron
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

/datum/outfit/adventurer_cleric/war_domain/pre_equip(mob/living/carbon/human/equipped_human, visuals_only)
	. = ..()
	equipped_human.mana_pool?.set_intrinsic_recharge(MANA_ALL_LEYLINES)
