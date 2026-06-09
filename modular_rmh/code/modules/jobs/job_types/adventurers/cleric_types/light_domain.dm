/datum/attribute_holder/sheet/job/advclass/combat/adventurer_cleric/light_domain
	raw_attribute_list = list(
		STAT_STRENGTH = 1,
		STAT_INTELLIGENCE = 1,
		STAT_CONSTITUTION = 1,
		STAT_ENDURANCE = 2,
		STAT_SPEED = -1,
		/datum/attribute/skill/combat/wrestling = 20,
		/datum/attribute/skill/combat/unarmed = 20,
		/datum/attribute/skill/misc/climbing = 20,
		/datum/attribute/skill/misc/swimming = 10,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/misc/reading = 30,
		/datum/attribute/skill/magic/holy = 30,
		/datum/attribute/skill/craft/cooking = 10,
		/datum/attribute/skill/misc/sewing = 10,
		/datum/attribute/skill/misc/medicine = 10,
		/datum/attribute/skill/labor/mathematics = 20
	)

/datum/job/advclass/combat/adventurer_cleric/light_domain
	title = "Light Domain"
	tutorial = "Gods of primordial flame bathe you in resplendent light, providing magics to dispel darkness and immolate enemies."

	outfit = /datum/outfit/adventurer_cleric/light_domain
	category_tags = list(CAT_ADVENTURER_CLERIC)
	give_bank_account = TRUE

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_cleric/light_domain


	traits = list(
		TRAIT_MEDIUMARMOR,
		TRAIT_STEELHEARTED,
		TRAIT_HOLY,
	)

	languages = list(/datum/language/celestial)

	spells = list(
		/datum/action/cooldown/spell/undirected/touch/orison,
		/datum/action/cooldown/spell/healing,
		/datum/action/cooldown/spell/status/guidance,
		/datum/action/cooldown/spell/sacred_flame,
		/datum/action/cooldown/spell/undirected/divine_strike,
		/datum/action/cooldown/spell/essence/purify_water,
		/datum/action/cooldown/spell/essence/neutralize,
		/datum/action/cooldown/spell/undirected/conjure_item/light,
	)

/datum/job/advclass/combat/adventurer_cleric/light_domain/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()

	var/static/list/selectable = list( \
		"Morningstar" = /obj/item/weapon/mace/steel/morningstar, \
		"Scimitar" = /obj/item/weapon/sword/scimitar \
	)
	var/choice = spawned.select_equippable(player_client, selectable, message = "What is your weapon of choice?")
	if(!choice)
		return

	switch(choice)
		if("Morningstar")
			spawned.adjust_skillrank(/datum/skill/combat/axesmaces, 4, TRUE)
		if("Scimitar")
			spawned.adjust_skillrank(/datum/skill/combat/swords, 4, TRUE)

	var/holder = spawned.patron?.devotion_holder
	if(holder)
		var/datum/devotion/devotion = new holder()
		devotion.make_cleric()
		devotion.grant_to(spawned)


/datum/outfit/adventurer_cleric/light_domain
	name = "Light Domain"
	head = /obj/item/clothing/head/roguehood/colored/red
	mask = /obj/item/clothing/face/ambermask
	neck = /obj/item/clothing/neck/chaincoif/iron
	cloak = /obj/item/clothing/cloak/cape/colored/brown
	armor = /obj/item/clothing/armor/chainmail/iron
	shirt = /obj/item/clothing/armor/gambeson
	wrists = /obj/item/clothing/wrists/bracers/leather
	gloves = /obj/item/clothing/gloves/leather
	pants = /obj/item/clothing/pants/trou/leather
	shoes = /obj/item/clothing/shoes/boots/leather
	backr = null
	backl = /obj/item/storage/backpack/satchel
	belt = /obj/item/storage/belt/leather/adventurers_subclasses
	beltl = null
	beltr = null
	ring = null
	l_hand = null
	r_hand = /obj/item/flashlight/flare/torch/lantern/bronzelamptern

	backpack_contents = list(/obj/item/storage/belt/pouch/cloth/coins/poor = 1, /obj/item/reagent_containers/food/snacks/hardtack = 1)

/datum/outfit/adventurer_cleric/light_domain/pre_equip(mob/living/carbon/human/equipped_human, visuals_only)
	. = ..()
	equipped_human.mana_pool?.set_intrinsic_recharge(MANA_ALL_LEYLINES)
