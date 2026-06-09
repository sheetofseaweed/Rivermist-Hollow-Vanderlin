/datum/attribute_holder/sheet/job/advclass/combat/adventurer_bard/college_swords
	raw_attribute_list = list(
		STAT_PERCEPTION = 1,
		STAT_SPEED = 2,
		STAT_ENDURANCE = -1,
		/datum/attribute/skill/combat/swords = 30,
		/datum/attribute/skill/combat/knives = 20,
		/datum/attribute/skill/combat/unarmed = 20,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/combat/wrestling = 20,
		/datum/attribute/skill/misc/music = 40,
		/datum/attribute/skill/misc/reading = 10,
		/datum/attribute/skill/misc/sewing = 20,
		/datum/attribute/skill/misc/medicine = 10,
		/datum/attribute/skill/misc/climbing = 30,
		/datum/attribute/skill/craft/crafting = 10,
		/datum/attribute/skill/craft/cooking = 40
	)

/datum/job/advclass/combat/adventurer_bard/college_swords
	title = "College Of Swords"
	tutorial = "A highly trained and skilled warrior, you use your prowess with words and weapons to fight and entertain in equal measure."

	outfit = /datum/outfit/adventurer_bard/college_swords
	category_tags = list(CAT_ADVENTURER_BARD)
	give_bank_account = TRUE

	spells = list(
		/datum/action/cooldown/spell/vicious_mockery,
		/datum/action/cooldown/spell/bardic_inspiration,
	)

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_bard/college_swords


	traits = list(
		TRAIT_DODGEEXPERT,
		TRAIT_BARDIC_TRAINING
	)

/datum/job/advclass/combat/adventurer_bard/college_swords/after_spawn(mob/living/carbon/human/spawned, client/player_client)
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

/datum/outfit/adventurer_bard/college_swords
	name = "College Of Swords"
	head = /obj/item/clothing/head/bardhat
	mask = null
	neck = null
	cloak = /obj/item/clothing/cloak/cape
	armor = /obj/item/clothing/armor/leather/jacket
	shirt = /obj/item/clothing/shirt/tunic/noblecoat
	wrists = null
	gloves = /obj/item/clothing/gloves/fingerless
	pants = /obj/item/clothing/pants/tights/colored/random
	shoes = /obj/item/clothing/shoes/boots
	backr = null
	backl = /obj/item/storage/backpack/satchel
	belt = /obj/item/storage/belt/leather/adventurers_subclasses
	beltr = /obj/item/weapon/knife/dagger/steel/special
	beltl = /obj/item/weapon/sword/rapier
	ring = null
	l_hand = null
	r_hand = null

	backpack_contents = list(/obj/item/storage/belt/pouch/cloth/coins/poor = 1)

/datum/outfit/adventurer_bard/college_swords/pre_equip(mob/living/carbon/human/equipped_human, visuals_only)
	. = ..()
	equipped_human.mana_pool?.set_intrinsic_recharge(MANA_ALL_LEYLINES)

/datum/outfit/adventurer_bard/college_swords/post_equip(mob/living/carbon/human/equipped_human, visuals_only)
	. = ..()
	var/obj/item/clothing/cloak/cape/C = equipped_human.get_item_by_slot(ITEM_SLOT_CLOAK)
	if(C)
		C.color = CLOTHING_MUSTARD_YELLOW
