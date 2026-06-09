/datum/attribute_holder/sheet/job/advclass/towner/passenger
	raw_attribute_list = list(
		STAT_CONSTITUTION = 1,
		STAT_SPEED = 1,
		STAT_INTELLIGENCE = 1,
		/datum/attribute/skill/misc/athletics = 20,
		/datum/attribute/skill/misc/sneaking = 10,
		/datum/attribute/skill/misc/stealing = 10,
		/datum/attribute/skill/misc/reading = 20,
		/datum/attribute/skill/labor/mathematics = 10,
		/datum/attribute/skill/misc/swimming = 20
	)

/datum/job/advclass/towner/passenger
	title = "Ship Passenger"
	tutorial = "You are a passenger aboard the vessel. \
	Whether merchant, traveler, exile, or opportunist, you have paid or bargained your way onto this voyage."
	outfit = /datum/outfit/towner/passenger
	category_tags = list(CAT_TOWNER)
	give_bank_account = 10

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/towner/passenger

/datum/outfit/towner/passenger
	name = "Ship Passenger"
	head = null
	mask = null
	neck = null
	cloak = null
	armor = null
	shirt = null
	wrists = null
	gloves = null
	pants = null
	shoes = null
	backr = /obj/item/storage/backpack/satchel
	backl = null
	belt = /obj/item/storage/belt/leather/black
	beltl = /obj/item/storage/belt/pouch/cloth/coins/mid
	beltr = null
	ring = null
	l_hand = null
	r_hand = null

	backpack_contents = list(
		/obj/item/reagent_containers/glass/bottle/water = 1,
	)

/datum/outfit/towner/passenger/pre_equip(mob/living/carbon/human/equipped_human, visuals_only)
	. = ..()
	if(equipped_human.gender == MALE)
		armor = /obj/item/clothing/armor/leather/vest/colored/random
		shirt = /obj/item/clothing/shirt/undershirt/formal
		pants = /obj/item/clothing/pants/tights/colored/random
		shoes = /obj/item/clothing/shoes/simpleshoes/buckle
	else
		shirt = /obj/item/clothing/shirt/dress/silkdress/colored/random
		shoes = /obj/item/clothing/shoes/shortboots
