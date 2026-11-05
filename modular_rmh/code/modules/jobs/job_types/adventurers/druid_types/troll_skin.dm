/datum/attribute_holder/sheet/job/advclass/combat/adventurer_druid/troll_skin
	raw_attribute_list = list(
		STAT_STRENGTH = 1,
		STAT_ENDURANCE = 1,
		STAT_INTELLIGENCE = -1,
		/datum/attribute/skill/combat/axesmaces = 20,
		/datum/attribute/skill/combat/knives = 10,
		/datum/attribute/skill/combat/unarmed = 20,
		/datum/attribute/skill/combat/wrestling = 10,
		/datum/attribute/skill/misc/athletics = 20,
		/datum/attribute/skill/magic/holy = 30,
		/datum/attribute/skill/magic/druidic = 30,
		/datum/attribute/skill/labor/taming = 40,
		/datum/attribute/skill/craft/tanning = 20,
		/datum/attribute/skill/misc/riding = 10,
		/datum/attribute/skill/labor/butchering = 20,
		/datum/attribute/skill/labor/farming = 30,
		/datum/attribute/skill/craft/crafting = 10,
		/datum/attribute/skill/craft/cooking = 10,
		/datum/attribute/skill/misc/sewing = 10,
		/datum/attribute/skill/misc/swimming = 20
	)

/datum/job/advclass/combat/adventurer_druid/troll_skin
	title = "Trollskin Druid"
	tutorial = "A druid who learned forbidden rites to wear the flesh of trolls, embracing regeneration and monstrous strength."

	outfit = /datum/outfit/adventurer_druid/troll_skin
	category_tags = list(CAT_ADVENTURER_DRUID)
	give_bank_account = TRUE
	total_positions = 2

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_druid/troll_skin


	traits = list(
		TRAIT_SEEDKNOW,
		TRAIT_FORAGER,
		TRAIT_DEADNOSE,
		TRAIT_BESTIALSENSE,
	)

	spells = list(
		/datum/action/cooldown/spell/undirected/touch/entangler,
		/datum/action/cooldown/spell/conjure/garden_fae,
		/datum/action/cooldown/spell/conjure/kneestingers,
		/datum/action/cooldown/spell/undirected/jaunt/bush_jaunt,
		/datum/action/cooldown/spell/undirected/bless_crops,
		/datum/action/cooldown/spell/undirected/conjure_item/briar_claw,
		/datum/action/cooldown/spell/projectile/falcon_disrupt,
		/datum/action/cooldown/spell/healing,
		/datum/action/cooldown/spell/undirected/shapeshift/troll_form,
		/datum/action/cooldown/spell/undirected/troll_shape,
	)


/datum/outfit/adventurer_druid/troll_skin
	name = "Trollskin Druid"
	head = null
	mask = /obj/item/clothing/face/druid
	neck = null
	cloak = null
	armor = /obj/item/clothing/shirt/robe/dendor
	shirt = /obj/item/clothing/armor/leather/vest
	wrists = /obj/item/clothing/wrists/bracers/leather
	gloves = null
	pants = null
	shoes = null
	backr = null
	backl = /obj/item/weapon/mace/goden/shillelagh
	belt = /obj/item/storage/belt/leather/rope/adventurers_subclasses
	beltl = /obj/item/weapon/knife/stone
	beltr = null
	ring = null
	l_hand = null
	r_hand = null

/datum/outfit/adventurer_druid/troll_skin/pre_equip(mob/living/carbon/human/equipped_human, visuals_only)
	. = ..()
	equipped_human.mana_pool?.set_intrinsic_recharge(MANA_ALL_LEYLINES)

/datum/job/advclass/combat/adventurer_druid/troll_skin/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()
	spawned.update_sight()
