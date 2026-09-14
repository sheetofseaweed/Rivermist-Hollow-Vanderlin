/datum/attribute_holder/sheet/job/advclass/combat/adventurer_ranger/dwarf_ranger
	raw_attribute_list = list(
		/datum/attribute/skill/misc/hunting = 20,
		/datum/attribute/skill/misc/tracking = 20,
		STAT_PERCEPTION = 3,
		STAT_SPEED = 1,
		// Fast... for a dwarf
		/datum/attribute/skill/combat/swords = 30,
		// In line with basic combat classes
		/datum/attribute/skill/combat/wrestling = 10,
		/datum/attribute/skill/combat/unarmed = 20,
		/datum/attribute/skill/craft/crafting = 20,
		/datum/attribute/skill/misc/swimming = 10,
		/datum/attribute/skill/misc/climbing = 30,
		/datum/attribute/skill/combat/crossbows = 30,
		/datum/attribute/skill/craft/tanning = 20,
		/datum/attribute/skill/misc/sewing = 30,
		/datum/attribute/skill/misc/medicine = 20,
		/datum/attribute/skill/craft/cooking = 10,
		/datum/attribute/skill/misc/athletics = 20,
		/datum/attribute/skill/misc/reading = 20
	)

/datum/job/advclass/combat/adventurer_ranger/dwarf_ranger
	title = "Dwarf Ranger"
	tutorial = "Dwarven rangers are scouts, hunters, and wardens of the wild marches beyond the clanholds. \
	They patrol mountain passes, track beasts that threaten trade routes, and map safe paths through untamed lands."

	allowed_races = list(SPEC_ID_DWARF, SPEC_ID_DUERGAR)
	outfit = /datum/outfit/adventurer_ranger/dwarf_ranger
	category_tags = list(CAT_ADVENTURER_RANGER)
	give_bank_account = TRUE

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_ranger/dwarf_ranger


	traits = list(
		TRAIT_MEDIUMARMOR,
	)

/datum/outfit/adventurer_ranger/dwarf_ranger
	name = "Dwarf Ranger (Adventurer)"
	head = /obj/item/clothing/head/roguehood/colored/uncolored
	mask = null
	neck = null
	cloak = /obj/item/clothing/cloak/raincloak/colored/brown
	armor = /obj/item/clothing/armor/chainmail/iron
	shirt = /obj/item/clothing/shirt/undershirt/colored/random
	wrists = /obj/item/clothing/wrists/bracers/leather
	gloves = null
	pants = /obj/item/clothing/pants/trou/leather
	shoes = /obj/item/clothing/shoes/boots/leather
	backr = /obj/item/gun/ballistic/revolver/grenadelauncher/crossbow
	backl = /obj/item/storage/backpack/satchel
	belt = /obj/item/storage/belt/leather/adventurers_subclasses
	beltl = /obj/item/ammo_holder/quiver/bolts
	beltr = /obj/item/flashlight/flare/torch/lantern
	ring = null
	l_hand = null
	r_hand = /obj/item/weapon/sword/scimitar/falchion

	backpack_contents = list(
		/obj/item/bait = 1,
	)
