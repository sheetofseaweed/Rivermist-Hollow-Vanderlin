/datum/attribute_holder/sheet/job/advclass/towner/bard
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
		/datum/attribute/skill/misc/music = 40,
		/datum/attribute/skill/misc/athletics = 30
	)

/datum/job/advclass/towner/bard
	title = "Bard"
	tutorial = "You are a keeper of stories and song. \
	Through music and word, you turn lives into legends and moments into memory. \
	Your performances inspire, mock, and uplift in equal measure."
	total_positions = 2
	spawn_positions = 2

	outfit = /datum/outfit/towner/bard
	category_tags = list(CAT_TOWNER)
	give_bank_account = 20

	exp_types_granted = list(EXP_TYPE_BARD)

	spells = list(
		/datum/action/cooldown/spell/vicious_mockery,
		/datum/action/cooldown/spell/bardic_inspiration
	)

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/towner/bard


	traits = list(
		TRAIT_DODGEEXPERT,
		TRAIT_BARDIC_TRAINING
	)

/datum/job/advclass/towner/bard/after_spawn(mob/living/carbon/human/spawned, client/player_client)
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
	spawned.clamped_adjust_skillrank(/datum/skill/misc/music, 4, 4, TRUE)

/datum/outfit/towner/bard
	name = "Bard"
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
	belt = /obj/item/storage/belt/leather
	beltl = /obj/item/storage/belt/pouch/cloth/coins/poor
	beltr = /obj/item/weapon/knife/dagger/steel/special
	ring = null
	l_hand = null
	r_hand = null

	backpack_contents = list(/obj/item/flint)
	scabbards = list(/obj/item/weapon/scabbard/knife)

/datum/outfit/towner/bard/pre_equip(mob/living/carbon/human/H)
	. = ..()
	if(prob(50))
		cloak = /obj/item/clothing/cloak/raincloak/colored/red
	if(prob(30))
		gloves = /obj/item/clothing/gloves/fingerless
