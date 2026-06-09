/datum/attribute_holder/sheet/job/advclass/combat/adventurer_paladin/conquest
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

/datum/job/advclass/combat/adventurer_paladin/conquest
	title = "Oath Of Conquest"
	tutorial = "You bring order through dominance, crushing foes and inspiring fear to impose your will."

	outfit = /datum/outfit/adventurer_paladin/conquest
	category_tags = list(CAT_ADVENTURER_PALADIN)
	give_bank_account = TRUE

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_paladin/conquest


	traits = list(
		TRAIT_HEAVYARMOR,
		TRAIT_NOBLE,
		TRAIT_STEELHEARTED,
		TRAIT_HOLY,
	)

	spells = list(
		/datum/action/cooldown/spell/undirected/touch/orison,
		/datum/action/cooldown/spell/status/guidance,
		/datum/action/cooldown/spell/essence/silence,
		/datum/action/cooldown/spell/healing,
		/datum/action/cooldown/spell/diagnose/holy,
		/datum/action/cooldown/spell/essence/neutralize,
		/datum/action/cooldown/spell/sacred_flame,
	)

/datum/job/advclass/combat/adventurer_paladin/conquest/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()
	spawned.grant_language(/datum/language/celestial)

	if(spawned.dna?.species.id == SPEC_ID_HUMEN)
		spawned.dna.species.soundpack_m = new /datum/voicepack/male/knight()

	var/holder = spawned.patron?.devotion_holder
	if(holder)
		var/datum/devotion/devotion = new holder()
		devotion.make_templar()
		devotion.grant_to(spawned)

/datum/outfit/adventurer_paladin/conquest
	name = "Oath Of Conquest"
	head = /obj/item/clothing/head/helmet/heavy/crusader
	mask = null
	neck = /obj/item/clothing/neck/coif/cloth
	cloak = /obj/item/clothing/cloak/cape/crusader
	armor = /obj/item/clothing/armor/plate/full/silver
	shirt = /obj/item/clothing/armor/chainmail/hauberk
	wrists = null
	gloves = /obj/item/clothing/gloves/plate
	pants = /obj/item/clothing/pants/platelegs/silver
	shoes = /obj/item/clothing/shoes/boots/armor
	backr = /obj/item/storage/backpack/satchel/black
	backl = /obj/item/weapon/shield/tower/metal
	belt = /obj/item/storage/belt/leather/plaquesilver/adventurers_subclasses
	beltl = /obj/item/storage/belt/pouch/cloth/coins/mid
	beltr = /obj/item/weapon/sword/silver
	ring = /obj/item/clothing/ring/silver/saffira
	l_hand = null
	r_hand = null

/datum/outfit/adventurer_paladin/conquest/pre_equip(mob/living/carbon/human/equipped_human, visuals_only)
	. = ..()
	equipped_human.mana_pool?.set_intrinsic_recharge(MANA_ALL_LEYLINES)
