/datum/attribute_holder/sheet/job/advclass/combat/adventurer_fighter/longbeard
	raw_attribute_list = list(
		STAT_STRENGTH = 2,
		// Same stat spread as lancer/swordmaster, but no -1 speed at the cost of 1 point of endurance. A very powerful dwarf indeed
		STAT_CONSTITUTION = 2,
		STAT_ENDURANCE = 1,
		/datum/attribute/skill/combat/axesmaces = 40,
		/datum/attribute/skill/combat/polearms = 30,
		/datum/attribute/skill/combat/wrestling = 20,
		/datum/attribute/skill/craft/crafting = 20,
		/datum/attribute/skill/combat/unarmed = 20,
		/datum/attribute/skill/misc/swimming = 20,
		/datum/attribute/skill/misc/climbing = 20,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/craft/blacksmithing = 20,
		/datum/attribute/skill/craft/armorsmithing = 20,
		/datum/attribute/skill/craft/weaponsmithing = 20,
		/datum/attribute/skill/misc/reading = 20
	)

/datum/job/advclass/combat/adventurer_fighter/longbeard
	title = "Longbeard"
	tutorial = "An elder dwarf warrior, hammer in hand, a steadfast enforcer of tradition and justice."

	allowed_ages = list(AGE_MIDDLEAGED, AGE_OLD)
	allowed_races = list(SPEC_ID_DWARF, SPEC_ID_DUERGAR)

	outfit = /datum/outfit/adventurer_fighter/longbeard
	category_tags = list(CAT_ADVENTURER_FIGHTER)
	give_bank_account = TRUE

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_fighter/longbeard


	traits = list(
		TRAIT_HEAVYARMOR,
		TRAIT_STEELHEARTED, // Nothing fazes a longbeard
	)

/datum/outfit/adventurer_fighter/longbeard
	name = "Longbeard"
	head = /obj/item/clothing/head/rare/dwarfplate
	mask = null
	neck = /obj/item/clothing/neck/chaincoif
	cloak = null
	armor = /obj/item/clothing/armor/rare/dwarfplate
	shirt = /obj/item/clothing/shirt/undershirt/colored/black
	wrists = null
	gloves = null
	pants = /obj/item/clothing/pants/tights/colored/black
	shoes = /obj/item/clothing/shoes/boots/rare/dwarfplate
	backr = /obj/item/weapon/mace/goden/steel/warhammer
	backl = /obj/item/storage/backpack/satchel
	belt = /obj/item/storage/belt/leather/adventurers_subclasses
	beltl = /obj/item/storage/belt/pouch/cloth/coins/mid
	beltr = null
	ring = null
	l_hand = null
	r_hand = null
