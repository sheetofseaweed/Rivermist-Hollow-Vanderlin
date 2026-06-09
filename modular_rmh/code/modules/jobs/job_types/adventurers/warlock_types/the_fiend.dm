/datum/attribute_holder/sheet/job/advclass/combat/adventurer_warlock/the_fiend
	raw_attribute_list = list(
		STAT_INTELLIGENCE = 2,
		STAT_CONSTITUTION = 1,
		STAT_ENDURANCE = -1,
		STAT_STRENGTH = -1,
		/datum/attribute/skill/magic/arcane = 30,
		/datum/attribute/skill/misc/reading = 30,
		/datum/attribute/skill/misc/medicine = 10,
		/datum/attribute/skill/misc/sewing = 10,
		/datum/attribute/skill/misc/athletics = 10,
		/datum/attribute/skill/combat/knives = 10
	)

/datum/job/advclass/combat/adventurer_warlock/the_fiend
	title = "The Fiend"
	tutorial = "You have pledged your soul to the Hells or Abyss in return for a deadly arsenal of fiendish arcana."

	give_bank_account = TRUE
	outfit = /datum/outfit/adventurer_warlock/the_fiend
	category_tags = list(CAT_ADVENTURER_WARLOCK)

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_warlock/the_fiend


	traits = list(
		TRAIT_STEELHEARTED,
	)

	spells = list(
		/datum/action/cooldown/spell/cone/staggered/eldritch_blast,
		/datum/action/cooldown/spell/status/guidance,
		/datum/action/cooldown/spell/essence/toxic_cleanse,
		/datum/action/cooldown/spell/essence/silence,
		/datum/action/cooldown/spell/essence/neutralize,
		/datum/action/cooldown/spell/projectile/fire_flare,
		/datum/action/cooldown/spell/projectile/fireball,
		/datum/action/cooldown/spell/essence/flame_jet,
		/datum/action/cooldown/spell/enrapture,
		/datum/action/cooldown/spell/forced_orgasm,
	)


/datum/outfit/adventurer_warlock/the_fiend
	name = "The Fiend"
	head = /obj/item/clothing/head/crown/circlet/vision
	mask = null
	neck = null
	cloak = /obj/item/clothing/cloak/half/duelcape/townhall
	armor = /obj/item/clothing/shirt/robe/colored/red
	shirt = /obj/item/clothing/shirt/tunic/colored/red
	wrists = null
	gloves = /obj/item/clothing/gloves/essence_gauntlet
	pants = null
	shoes = /obj/item/clothing/shoes/nobleboot
	backr = null
	backl = /obj/item/storage/backpack/satchel/black
	belt = /obj/item/storage/belt/leather/adventurers_subclasses
	beltr = /obj/item/reagent_containers/glass/bottle/manapot
	beltr = null
	ring = null
	l_hand = null
	r_hand = null

	backpack_contents = list(
		/obj/item/storage/belt/pouch/cloth/coins/poor = 1,
	)

/datum/outfit/adventurer_warlock/the_fiend/pre_equip(mob/living/carbon/human/equipped_human, visuals_only)
	. = ..()
	equipped_human.mana_pool?.set_intrinsic_recharge(MANA_ALL_LEYLINES)
