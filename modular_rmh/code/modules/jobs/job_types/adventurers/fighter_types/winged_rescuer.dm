/datum/attribute_holder/sheet/job/advclass/combat/adventurer_fighter/winged_rescuer
	raw_attribute_list = list(
		STAT_STRENGTH = 2,
		STAT_SPEED = 3,
		/datum/attribute/skill/combat/bows = 20,
		/datum/attribute/skill/combat/swords = 30,
		/datum/attribute/skill/combat/knives = 20,
		/datum/attribute/skill/misc/medicine = 20,
		/datum/attribute/skill/misc/sewing = 20,
		/datum/attribute/skill/combat/unarmed = 20,
		/datum/attribute/skill/craft/tanning = 20,
		/datum/attribute/skill/combat/wrestling = 20,
		/datum/attribute/skill/craft/crafting = 10,
		/datum/attribute/skill/misc/climbing = 10,
		/datum/attribute/skill/misc/reading = 10,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/craft/alchemy = 30
	)

/datum/job/advclass/combat/adventurer_fighter/winged_rescuer
	title = "Winged Rescuer"
	tutorial = "You've seen countless battles and earned your fair share of riches from them. \
	Flying above the battlefield, you seek those who are injured and come to their aid, for a price."

	allowed_races = list(SPEC_ID_HARPY)
	outfit = /datum/outfit/adventurer_fighter/winged_rescuer
	category_tags = list(CAT_ADVENTURER_FIGHTER)
	give_bank_account = TRUE


	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_fighter/winged_rescuer


	traits = list(
		TRAIT_DEADNOSE,
		TRAIT_STEELHEARTED
	)

/datum/outfit/adventurer_fighter/winged_rescuer
	name = "Winged Rescuer"
	head = /obj/item/clothing/head/roguehood/colored/red
	mask = /obj/item/clothing/face/shepherd/rag
	neck = null
	cloak = /obj/item/clothing/cloak/raincloak/colored/red
	armor = /obj/item/clothing/armor/leather
	shirt = /obj/item/clothing/armor/gambeson/light
	wrists = null
	gloves = /obj/item/clothing/gloves/leather
	pants = /obj/item/clothing/pants/trou/leather
	shoes = /obj/item/clothing/shoes/boots/leather
	backr = null
	backl = /obj/item/storage/backpack/satchel
	belt = /obj/item/storage/belt/leather/adventurers_subclasses
	beltr = /obj/item/weapon/sword
	beltl = /obj/item/reagent_containers/glass/bottle/stronghealthpot
	ring = null
	l_hand = null
	r_hand = null

	backpack_contents = list(
		/obj/item/storage/belt/pouch/cloth/coins/mid = 1,
		/obj/item/reagent_containers/glass/bottle/healthpot = 3,
		/obj/item/weapon/knife/hunting = 1
	)
