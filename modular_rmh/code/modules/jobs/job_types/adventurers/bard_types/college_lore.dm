/datum/attribute_holder/sheet/job/advclass/combat/adventurer_bard/college_lore
	raw_attribute_list = list(
		STAT_PERCEPTION = 1,
		STAT_SPEED = 2,
		STAT_STRENGTH = -1,
		/datum/attribute/skill/combat/knives = 10,
		/datum/attribute/skill/combat/unarmed = 20,
		/datum/attribute/skill/craft/crafting = 10,
		/datum/attribute/skill/misc/swimming = 20,
		/datum/attribute/skill/misc/climbing = 20,
		/datum/attribute/skill/misc/riding = 30,
		/datum/attribute/skill/misc/sewing = 10,
		/datum/attribute/skill/misc/reading = 30,
		/datum/attribute/skill/craft/cooking = 10,
		/datum/attribute/skill/misc/sneaking = 30,
		/datum/attribute/skill/misc/stealing = 10,
		/datum/attribute/skill/misc/lockpicking = 10,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/misc/music = 40
	)

/datum/job/advclass/combat/adventurer_bard/college_lore
	title = "College of Lore"
	tutorial = "You pursue beauty and truth, collecting knowledge from scholarly tomes to peasants' tales, \
	and use your gifts to hold both audiences and enemies spellbound."

	outfit = /datum/outfit/adventurer_bard/college_lore
	category_tags = list(CAT_ADVENTURER_BARD)
	give_bank_account = TRUE

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_bard/college_lore


	traits = list(
		TRAIT_DODGEEXPERT,
		TRAIT_BARDIC_TRAINING,
	)

	spells = list(
		/datum/action/cooldown/spell/vicious_mockery,
		/datum/action/cooldown/spell/bardic_inspiration,
	)

/datum/job/advclass/combat/adventurer_bard/college_lore/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()
	spawned.select_equippable(player_client, list(
		"Harp" = /obj/item/instrument/harp,
		"Lute" = /obj/item/instrument/lute,
		"Accordion" = /obj/item/instrument/accord,
		"Guitar" = /obj/item/instrument/guitar,
		"Flute" = /obj/item/instrument/flute,
		"Drum" = /obj/item/instrument/drum,
		"Hurdy-Gurdy" = /obj/item/instrument/hurdygurdy,
		"Viola" = /obj/item/instrument/viola
		),
		message = "Choose your instrument.",
		title = "BARD"
	)
	spawned.inspiration = new /datum/inspiration(spawned)

/datum/outfit/adventurer_bard/college_lore
	name = "College of Lore"
	head = /obj/item/clothing/head/bardhat
	mask = null
	neck = /obj/item/storage/belt/pouch/cloth/coins/poor
	cloak = /obj/item/clothing/cloak/raincloak/colored/blue
	armor = /obj/item/clothing/armor/leather/vest
	shirt = /obj/item/clothing/shirt/tunic/noblecoat
	wrists = null
	gloves = null
	pants = /obj/item/clothing/pants/tights/colored/random
	shoes = /obj/item/clothing/shoes/boots
	backr = null
	backl = /obj/item/storage/backpack/satchel
	belt = /obj/item/storage/belt/leather/adventurers_subclasses
	beltl = /obj/item/storage/belt/pouch/cloth/coins/poor
	beltr = /obj/item/weapon/knife/dagger/steel/special
	ring = null
	l_hand = null
	r_hand = null

	backpack_contents = list(/obj/item/flint)
	scabbards = list(/obj/item/weapon/scabbard/knife)

/datum/outfit/adventurer_bard/college_lore/pre_equip(mob/living/carbon/human/equipped_human, visuals_only)
	. = ..()
	equipped_human.mana_pool?.set_intrinsic_recharge(MANA_ALL_LEYLINES)
	if(prob(30))
		gloves = /obj/item/clothing/gloves/fingerless

	cloak = /obj/item/clothing/cloak/raincloak/colored/blue
	if(prob(50))
		cloak = /obj/item/clothing/cloak/raincloak/colored/red
