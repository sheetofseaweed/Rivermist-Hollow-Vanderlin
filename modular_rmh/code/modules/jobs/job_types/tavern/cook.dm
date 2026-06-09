/datum/attribute_holder/sheet/job/cook
	raw_attribute_list = list(
		STAT_ENDURANCE = 1,
		STAT_INTELLIGENCE = 1,
		STAT_CONSTITUTION = 1,
		/datum/attribute/skill/combat/knives = 20,
		/datum/attribute/skill/misc/reading = 10,
		/datum/attribute/skill/craft/cooking = 40,
		/datum/attribute/skill/craft/crafting = 10,
		/datum/attribute/skill/misc/sewing = 10,
		/datum/attribute/skill/labor/butchering = 30,
		/datum/attribute/skill/labor/taming = 10,
		/datum/attribute/skill/labor/farming = 10
	)

/datum/job/cook
	title = "Inn Cook"
	tutorial = "The heart of the Drunken Dwarf’s kitchen. \
	You prepare hot meals, fresh bread, and hearty fare for adventurers and guests, \
	working closely with the innkeep to keep morale high and stomachs full. \
	Long hours and sharp knives are part of the trade — but a well-fed guild is a loyal one."
	department_flag = TAVERN
	faction = FACTION_TOWN
	total_positions = 2
	spawn_positions = 2
	job_flags = (JOB_ANNOUNCE_ARRIVAL | JOB_SHOW_IN_CREDITS | JOB_EQUIP_RANK | JOB_NEW_PLAYER_JOINABLE)
	display_order = JDO_COOK

	allowed_races = ALL_RACES_LIST
	allowed_ages = list(AGE_ADULT, AGE_MIDDLEAGED, AGE_OLD, AGE_IMMORTAL)

	selection_color = JCOLOR_TAVERN

	outfit = /datum/outfit/cook

	give_bank_account = 20
	job_bitflag = BITFLAG_CONSTRUCTOR

	attribute_sheet = /datum/attribute_holder/sheet/job/cook


	traits = list(
		TRAIT_EXTEROCEPTION
	)

/datum/outfit/cook
	name = "Cook"
	head = /obj/item/clothing/head/cookhat
	mask = null
	neck = /obj/item/storage/belt/pouch/cloth/coins/poor
	cloak = /obj/item/clothing/cloak/apron/cook
	armor = null
	shirt = null
	wrists = null
	gloves = null
	pants = null
	shoes = /obj/item/clothing/shoes/simpleshoes
	backr = null
	backl = null
	belt = /obj/item/storage/belt/leather/rope
	beltr = /obj/item/weapon/knife/villager
	beltl = /obj/item/key/tavern
	ring = null
	l_hand = null
	r_hand = null

	backpack_contents = list(
		/obj/item/recipe_book/cooking = 1
	)

/datum/outfit/cook/pre_equip(mob/living/carbon/human/equipped_human, visuals_only)
	. = ..()
	if(equipped_human.gender == MALE)
		shirt = /obj/item/clothing/shirt/shortshirt/colored/random
		pants = /obj/item/clothing/pants/tights/colored/random
	else
		armor = /obj/item/clothing/armor/corset
		shirt = /obj/item/clothing/shirt/undershirt/lowcut
		pants = /obj/item/clothing/pants/skirt/colored/red
