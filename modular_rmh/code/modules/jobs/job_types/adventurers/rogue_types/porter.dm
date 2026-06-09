/datum/attribute_holder/sheet/job/advclass/combat/adventurer_rogue/porter
	raw_attribute_list = list(
		STAT_CONSTITUTION = 1,
		STAT_ENDURANCE = 3,
		STAT_INTELLIGENCE = 4,
		//Unique specimen, They learned many things, it basically nullify and give a bonus of +2 to their INT.
		STAT_SPEED = 2,
		//Gee, Why do this kobold get more stats than everyone else? the answer is because they have to at the very least escape from being killed and looted.
		STAT_PERCEPTION = -2,
		//-4 PER with a chance of it being a -5 hit hard
		/datum/attribute/skill/combat/wrestling = 30,
		//To get out of grasps slippery bastard
		/datum/attribute/skill/combat/unarmed = 10,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/misc/climbing = 30,
		/datum/attribute/skill/misc/swimming = 20,
		/datum/attribute/skill/misc/reading = 20,
		/datum/attribute/skill/labor/mathematics = 20,
		//Can't expect those kobolds to not be thieves or assist with such things.
		/datum/attribute/skill/misc/stealing = 20,
		/datum/attribute/skill/misc/lockpicking = 20,
		//Jack of All Trade, Master of None.
		/datum/attribute/skill/misc/sewing = 30,
		/datum/attribute/skill/misc/medicine = 30,
		/datum/attribute/skill/labor/fishing = 30,
		/datum/attribute/skill/labor/butchering = 30,
		/datum/attribute/skill/craft/cooking = 30,
		/datum/attribute/skill/craft/tanning = 30,
		/datum/attribute/skill/craft/crafting = 30,
		/datum/attribute/skill/craft/engineering = 30,
		/datum/attribute/skill/craft/carpentry = 30,
		/datum/attribute/skill/craft/masonry = 30,
		/datum/attribute/skill/craft/traps = 30,
		/datum/attribute/skill/craft/weaponsmithing = 10,
		/datum/attribute/skill/craft/armorsmithing = 10
	)

/datum/job/advclass/combat/adventurer_rogue/porter
	title = "Porter"
	tutorial = "Hailing from the twisting tunnels and forgotten warrens beneath Faerûn, \
	you have survived by being indispensable. You carry the burdens of adventurers, mend broken gear, \
	prepare meals, and even patch wounds when needed. No task is too small, no coin too little, \
	and your skills in stealth, traps, and clever tinkering make you an invaluable companion in any party."

	allowed_races = list(SPEC_ID_KOBOLD, SPEC_ID_HALFLING, SPEC_ID_GNOME, SPEC_ID_GNOME_D)

	outfit = /datum/outfit/adventurer_rogue/porter
	category_tags = list(CAT_ADVENTURER_ROGUE)
	give_bank_account = TRUE

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_rogue/porter


	traits = list(
		TRAIT_AMAZING_BACK,
		TRAIT_FORAGER,
		TRAIT_MIRACULOUS_FORAGING,
		TRAIT_SEEDKNOW,
		TRAIT_SEEPRICES,
		TRAIT_DODGEEXPERT,
	)

/datum/outfit/adventurer_rogue/porter
	name = "Porter"
	head = /obj/item/clothing/head/articap/porter
	mask = /obj/item/clothing/face/goggles
	neck = null
	cloak = null
	armor = /obj/item/clothing/armor/leather/jacket/artijacket/porter
	shirt = /obj/item/clothing/shirt/undershirt/colored/black
	wrists = null
	gloves = null
	pants = /obj/item/clothing/pants/trou
	shoes = /obj/item/clothing/shoes/boots/leather
	backr = /obj/item/fishingrod/fisher
	backl = /obj/item/storage/backpack/backpack/artibackpack/porter //+1 to Row/Columns compared to a regular backpack alongside preserving foods.
	belt = /obj/item/storage/belt/leather/adventurers_subclasses
	beltr = /obj/item/storage/messkit
	beltl = /obj/item/weapon/knife/cleaver
	ring = null
	l_hand = null
	r_hand = null

	backpack_contents = list(/obj/item/kitchen/rollingpin = 1, /obj/item/storage/belt/pouch/cloth/coins/poor, /obj/item/weapon/knife/hunting, /obj/item/weapon/hammer/iron = 1, /obj/item/weapon/shovel/small = 1, /obj/item/recipe_book/survival = 1, /obj/item/recipe_book/cooking = 1, /obj/item/key/mercenary = 1, /obj/item/reagent_containers/glass/bucket/pot = 1)
