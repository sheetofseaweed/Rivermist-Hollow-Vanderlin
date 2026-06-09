/datum/attribute_holder/sheet/job/advclass/towner/farmhand
	raw_attribute_list = list(
		STAT_STRENGTH = 1,
		STAT_CONSTITUTION = 1,
		STAT_ENDURANCE = 1,
		STAT_INTELLIGENCE = -1,
		/datum/attribute/skill/combat/wrestling = 20,
		/datum/attribute/skill/combat/unarmed = 20,
		/datum/attribute/skill/combat/knives = 20,
		/datum/attribute/skill/combat/polearms = 20,
		/datum/attribute/skill/combat/whipsflails = 10,
		/datum/attribute/skill/craft/crafting = 20,
		/datum/attribute/skill/misc/sewing = 10,
		/datum/attribute/skill/labor/farming = 40,
		/datum/attribute/skill/labor/taming = 50,
		/datum/attribute/skill/misc/reading = 10,
		/datum/attribute/skill/craft/cooking = 10,
		/datum/attribute/skill/craft/carpentry = 10,
		/datum/attribute/skill/misc/medicine = 10,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/craft/tanning = 20,
		/datum/attribute/skill/misc/riding = 10,
		/datum/attribute/skill/labor/butchering = 40
	)

/datum/job/advclass/towner/farmhand
	title = "Farmhand"
	tutorial = "You live by the turning of seasons and the moods of the soil. \
	The fields of Rivermist Hollow answer to steady hands and patient care, \
	and you know when to plant, when to rest, and when to harvest. \
	Your work feeds the town, keeps markets full, and brings comfort in lean years. \
	It's a peaceful life."
	total_positions = 5
	spawn_positions = 5

	outfit = /datum/outfit/towner/farmhand
	category_tags = list(CAT_TOWNER)

	give_bank_account = 20

	job_bitflag = BITFLAG_CONSTRUCTOR

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/towner/farmhand


	traits = list(
		TRAIT_DEADNOSE,
		TRAIT_SEEDKNOW
	)

/datum/outfit/towner/farmhand
	name = "Farmhand"
	head = null
	mask = null
	neck = /obj/item/storage/belt/pouch/cloth/coins/poor
	cloak = null
	armor = null
	shirt = null
	wrists = null
	gloves = null
	pants = null
	shoes = /obj/item/clothing/shoes/simpleshoes
	backr = null
	backl = /obj/item/storage/backpack/satchel/cloth
	belt = /obj/item/storage/belt/leather/rope
	beltl = /obj/item/key/soilson
	beltr = /obj/item/weapon/knife/villager
	ring = null
	l_hand = null
	r_hand = null

	backpack_contents = list(
		/obj/item/recipe_book/cooking = 1,
		/obj/item/bottle_kit = 1,
		/obj/item/recipe_book/agriculture = 1
	)

/datum/outfit/towner/farmhand/pre_equip(mob/living/carbon/human/equipped_human, visuals_only)
	. = ..()
	if(equipped_human.gender == MALE)
		head = /obj/item/clothing/head/strawhat
		armor = /obj/item/clothing/armor/gambeson/light/striped
		shirt = /obj/item/clothing/shirt/undershirt/colored/random
		pants = /obj/item/clothing/pants/tights/colored/random
	else
		head = /obj/item/clothing/head/armingcap
		armor = /obj/item/clothing/shirt/dress/gen/colored/random
		shirt = /obj/item/clothing/shirt/undershirt
