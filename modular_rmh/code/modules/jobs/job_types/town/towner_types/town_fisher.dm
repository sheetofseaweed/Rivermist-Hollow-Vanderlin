/datum/attribute_holder/sheet/job/advclass/towner/fisher
	raw_attribute_list = list(
		STAT_CONSTITUTION = 2,
		STAT_PERCEPTION = 1,
		/datum/attribute/skill/combat/knives = 20,
		/datum/attribute/skill/misc/swimming = 30,
		/datum/attribute/skill/craft/cooking = 20,
		/datum/attribute/skill/craft/crafting = 20,
		/datum/attribute/skill/misc/sewing = 10,
		/datum/attribute/skill/labor/fishing = 40,
		/datum/attribute/skill/misc/medicine = 10,
		/datum/attribute/skill/misc/athletics = 20,
		/datum/attribute/skill/misc/reading = 10
	)

/datum/job/advclass/towner/fisher
	title = "Fisher"
	tutorial = "Rivers and marshwaters sustain Rivermist Hollow, \
	and you know their currents, shallows, and quiet eddies. \
	With net, line, or trap, you bring in fish enough for tables and trade alike."
	total_positions = 5
	spawn_positions = 5

	allowed_races = RACES_PLAYER_ALL

	outfit = /datum/outfit/towner/fisher
	category_tags = list(CAT_TOWNER)
	give_bank_account = 8

	job_bitflag = BITFLAG_CONSTRUCTOR

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/towner/fisher


	traits = list(
		TRAIT_DEADNOSE,
	)

/datum/outfit/towner/fisher
	name = "Fisher"
	head = /obj/item/clothing/head/fisherhat
	mask = null
	neck = /obj/item/storage/belt/pouch/cloth/coins/poor
	cloak = null
	armor = /obj/item/clothing/armor/gambeson/light/striped
	shirt = null
	wrists = null
	gloves = null
	pants = null
	shoes = null
	backr = /obj/item/fishingrod/fisher
	backl = /obj/item/storage/backpack/satchel
	belt = /obj/item/storage/belt/leather
	beltl = /obj/item/flint
	beltr = /obj/item/cooking/pan
	ring = null
	l_hand = null
	r_hand = null

	backpack_contents = list(
		/obj/item/weapon/shovel/small = 1,
		/obj/item/natural/worms = 1
	)

/datum/outfit/towner/fisher/pre_equip(mob/living/carbon/human/equipped_human, visuals_only)
	. = ..()
	if(equipped_human.gender == MALE)
		pants = /obj/item/clothing/pants/tights/colored/random
		shirt = /obj/item/clothing/shirt/shortshirt/colored/random
		shoes = /obj/item/clothing/shoes/boots/leather
		backpack_contents += list(
			/obj/item/weapon/knife/villager = 1,
			/obj/item/recipe_book/survival = 1
		)
	else
		shirt = /obj/item/clothing/shirt/dress/gen/colored/random
		shoes = /obj/item/clothing/shoes/boots/leather
		backpack_contents += list(
			/obj/item/weapon/knife/hunting = 1
		)
