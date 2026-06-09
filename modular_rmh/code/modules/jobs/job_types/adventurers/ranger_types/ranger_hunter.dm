/datum/attribute_holder/sheet/job/advclass/combat/adventurer_ranger/ranger_hunter
	raw_attribute_list = list(
		STAT_ENDURANCE = 1,
		STAT_PERCEPTION = 3,
		STAT_SPEED = 3,
		/datum/attribute/skill/combat/knives = 30,
		/datum/attribute/skill/combat/bows = 30,
		/datum/attribute/skill/craft/tanning = 20,
		/datum/attribute/skill/combat/unarmed = 20,
		/datum/attribute/skill/combat/wrestling = 10,
		/datum/attribute/skill/craft/crafting = 20,
		/datum/attribute/skill/misc/swimming = 30,
		/datum/attribute/skill/misc/climbing = 40,
		/datum/attribute/skill/labor/taming = 20,
		/datum/attribute/skill/misc/sewing = 30,
		/datum/attribute/skill/misc/sneaking = 20,
		/datum/attribute/skill/craft/traps = 10,
		/datum/attribute/skill/misc/athletics = 20,
		/datum/attribute/skill/misc/medicine = 20,
		/datum/attribute/skill/craft/cooking = 10,
		/datum/attribute/skill/misc/reading = 10
	)

/datum/job/advclass/combat/adventurer_ranger/ranger_hunter
	title = "Ranger Hunter"
	tutorial = "You seek the most dangerous prey in Faerûn, from ancient dragons to massive hordes of undead, and excel at slaying them all."

	outfit = /datum/outfit/adventurer_ranger/ranger_hunter
	category_tags = list(CAT_ADVENTURER_RANGER)
	give_bank_account = TRUE

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_ranger/ranger_hunter


	traits = list(
		TRAIT_DODGEEXPERT,
		TRAIT_SEEDKNOW,
		TRAIT_FORAGER,
		TRAIT_DEADNOSE,
		TRAIT_BESTIALSENSE,
	)

/datum/outfit/adventurer_ranger/ranger_hunter
	name = "Ranger Hunter"
	head = null
	mask = null
	neck = null
	cloak = /obj/item/clothing/cloak/raincloak/colored/green
	armor = /obj/item/clothing/armor/leather/hide
	shirt = /obj/item/clothing/shirt/undershirt
	wrists = /obj/item/clothing/wrists/bracers/leather
	gloves = /obj/item/clothing/gloves/leather
	pants = /obj/item/clothing/pants/trou/leather
	shoes = /obj/item/clothing/shoes/boots/leather
	backr = /obj/item/gun/ballistic/revolver/grenadelauncher/bow/long
	backl = /obj/item/storage/backpack/backpack/longhike/with_bedroll
	belt = /obj/item/storage/belt/leather/adventurers_subclasses
	beltr = /obj/item/flashlight/flare/torch/lantern
	beltl = /obj/item/ammo_holder/quiver/arrows
	ring = null
	l_hand = null
	r_hand = null

	backpack_contents = list(
		/obj/item/bait = 1,
		/obj/item/weapon/knife/hunting = 1,
	)

/datum/job/advclass/combat/adventurer_ranger/ranger_hunter/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()
	spawned.update_sight()
