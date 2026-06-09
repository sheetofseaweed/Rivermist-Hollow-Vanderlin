/datum/attribute_holder/sheet/job/advclass/towner/hunter
	raw_attribute_list = list(
		STAT_PERCEPTION = 3,
		/datum/attribute/skill/craft/crafting = 20,
		/datum/attribute/skill/craft/tanning = 30,
		/datum/attribute/skill/combat/bows = 30,
		/datum/attribute/skill/combat/crossbows = 20,
		/datum/attribute/skill/combat/knives = 20,
		/datum/attribute/skill/craft/cooking = 10,
		/datum/attribute/skill/labor/butchering = 20,
		/datum/attribute/skill/labor/taming = 30,
		/datum/attribute/skill/misc/medicine = 10,
		/datum/attribute/skill/misc/sewing = 20,
		/datum/attribute/skill/misc/sneaking = 20,
		/datum/attribute/skill/craft/traps = 30,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/misc/climbing = 20,
		/datum/attribute/skill/misc/swimming = 10,
		/datum/attribute/skill/misc/reading = 10
	)

/datum/job/advclass/towner/hunter
	title = "Hunter"
	f_title = "Huntress"
	tutorial = "The wetlands and woodlands near Rivermist Hollow are rich with game, \
	if you know where to look and when to tread lightly. \
	You track deer, boar, and smaller beasts, supplying meat, hides, and bone to the town."
	total_positions = 5
	spawn_positions = 5

	outfit = /datum/outfit/towner/hunter
	category_tags = list(CAT_TOWNER)
	give_bank_account = 15

	job_bitflag = BITFLAG_CONSTRUCTOR

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/towner/hunter


	traits = list(
		TRAIT_FORAGER
	)

/datum/outfit/towner/hunter
	name = "Hunter"
	head = /obj/item/clothing/head/brimmed
	mask = null
	neck = /obj/item/storage/belt/pouch/cloth/coins/poor
	cloak = /obj/item/clothing/cloak/raincloak/furcloak/colored/brown
	armor = null
	shirt = /obj/item/clothing/shirt/shortshirt/colored/random
	wrists = null
	gloves = /obj/item/clothing/gloves/leather
	pants = /obj/item/clothing/pants/tights/colored/random
	shoes = /obj/item/clothing/shoes/boots/leather
	backr = /obj/item/storage/backpack/backpack/longhike/with_bedroll
	backl = /obj/item/gun/ballistic/revolver/grenadelauncher/bow
	belt = /obj/item/storage/belt/leather
	beltl = /obj/item/ammo_holder/quiver/arrows
	beltr = /obj/item/storage/meatbag
	ring = null
	l_hand = null
	r_hand = null

	backpack_contents = list(
		/obj/item/flint = 1,
		/obj/item/bait = 1,
		/obj/item/weapon/knife/hunting = 1,
		/obj/item/flashlight/flare/torch/lantern = 1
	)
