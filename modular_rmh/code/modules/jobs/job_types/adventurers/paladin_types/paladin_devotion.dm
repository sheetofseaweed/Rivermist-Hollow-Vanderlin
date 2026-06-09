/datum/attribute_holder/sheet/job/advclass/combat/adventurer_paladin/devotion
	raw_attribute_list = list(
		STAT_STRENGTH = 2,
		STAT_PERCEPTION = 2,
		STAT_INTELLIGENCE = 2,
		STAT_CONSTITUTION = 1,
		STAT_ENDURANCE = 1,
		STAT_SPEED = -2,
		STAT_FORTUNE = 1,
		/datum/attribute/skill/combat/axesmaces = 20,
		/datum/attribute/skill/combat/wrestling = 20,
		/datum/attribute/skill/combat/unarmed = 30,
		/datum/attribute/skill/combat/swords = 30,
		/datum/attribute/skill/combat/shields = 30,
		/datum/attribute/skill/misc/climbing = 10,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/misc/reading = 30,
		/datum/attribute/skill/magic/holy = 20,
		/datum/attribute/skill/craft/cooking = 10,
		/datum/attribute/skill/labor/mathematics = 30
	)

/datum/job/advclass/combat/adventurer_paladin/devotion
	title = "Oath Of Devotion"
	tutorial = "Following the ideal of the knight in shining armour, \
	you act with honour and virtue to protect the weak and pursue the greater good."

	outfit = /datum/outfit/adventurer_paladin/devotion
	category_tags = list(CAT_ADVENTURER_PALADIN)
	give_bank_account = TRUE

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_paladin/devotion


	traits = list(
		TRAIT_HEAVYARMOR,
		TRAIT_NOBLE,
		TRAIT_STEELHEARTED,
		TRAIT_HOLY,
	)

	spells = list(
		/datum/action/cooldown/spell/undirected/touch/orison,
		/datum/action/cooldown/spell/status/guidance,
		/datum/action/cooldown/spell/essence/purify_water,
		/datum/action/cooldown/spell/healing,
		/datum/action/cooldown/spell/sacred_flame,
		/datum/action/cooldown/spell/undirected/blade_ward,
	)

/datum/job/advclass/combat/adventurer_paladin/devotion/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()
	spawned.grant_language(/datum/language/celestial)

	if(spawned.dna?.species.id == SPEC_ID_HUMEN)
		spawned.dna.species.soundpack_m = new /datum/voicepack/male/knight()

	var/holder = spawned.patron?.devotion_holder
	if(holder)
		var/datum/devotion/devotion = new holder()
		devotion.make_templar()
		devotion.grant_to(spawned)

/datum/outfit/adventurer_paladin/devotion
	name = "Oath Of Devotion"
	head = /obj/item/clothing/head/helmet/heavy/holysee
	mask = null
	neck = /obj/item/clothing/neck/chaincoif
	cloak = /obj/item/clothing/cloak/holysee
	armor = /obj/item/clothing/armor/plate/full/holysee
	shirt = /obj/item/clothing/armor/chainmail
	wrists = null
	gloves = /obj/item/clothing/gloves/plate
	pants = /obj/item/clothing/pants/platelegs/holysee
	shoes = /obj/item/clothing/shoes/boots/armor
	backr = /obj/item/storage/backpack/satchel
	backl = /obj/item/weapon/sword/long/martyr
	belt = /obj/item/storage/belt/leather/steel/adventurers_subclasses
	beltl = /obj/item/storage/belt/pouch/cloth/coins/mid
	beltr = null
	ring = /obj/item/clothing/ring/silver/gemerald
	l_hand = null
	r_hand = null

/datum/outfit/adventurer_paladin/devotion/pre_equip(mob/living/carbon/human/equipped_human, visuals_only)
	. = ..()
	equipped_human.mana_pool?.set_intrinsic_recharge(MANA_ALL_LEYLINES)
