/datum/attribute_holder/sheet/job/advclass/town_scholar/ship_doctor
	raw_attribute_list = list(
		STAT_INTELLIGENCE = 4,
		STAT_PERCEPTION = 1,
		STAT_STRENGTH = -1,
		STAT_CONSTITUTION = -1,
		/datum/attribute/skill/craft/alchemy = 50,
		/datum/attribute/skill/misc/medicine = 50,
		/datum/attribute/skill/misc/reading = 50,
		/datum/attribute/skill/misc/sewing = 30,
		/datum/attribute/skill/labor/mathematics = 30,
		/datum/attribute/skill/labor/farming = 30,
		/datum/attribute/skill/craft/crafting = 20,
		/datum/attribute/skill/combat/knives = 20,
		/datum/attribute/skill/combat/wrestling = 20,
		/datum/attribute/skill/misc/climbing = 20,
		/datum/attribute/skill/misc/athletics = 20,
		/datum/attribute/skill/misc/sneaking = 20,
		/datum/attribute/skill/combat/unarmed = 10
	)

/datum/job/advclass/town_scholar/ship_doctor
	title = "Ship Doctor"
	tutorial = "You are the Ship Doctor, responsible for the health and survival of the crew at sea."

	total_positions = 1
	spawn_positions = 1

	outfit = /datum/outfit/town_scholar/ship_doctor
	category_tags = list(CAT_ARCHIVIST)

	trainable_skills = list(/datum/skill/craft/alchemy)
	max_apprentices = 2
	apprentice_name = "Ship Doctor Apprentice"
	can_have_apprentices = TRUE

	give_bank_account = 100
	job_bitflag = BITFLAG_CONSTRUCTOR

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/town_scholar/ship_doctor

	traits = list(
		TRAIT_FORAGER,
		TRAIT_LEGENDARY_ALCHEMIST,
		TRAIT_EMPATH,
		TRAIT_STEELHEARTED,
		TRAIT_DEADNOSE,
		TRAIT_TUTELAGE,
	)

	spells = list(
		/datum/action/cooldown/spell/diagnose,
	)

/datum/outfit/town_scholar/ship_doctor
	name = "Ship Doctor"
	head = /obj/item/clothing/head/helmet/leather/tricorn/treasure_island
	mask = /obj/item/clothing/head/wig
	neck = /obj/item/clothing/neck/formal
	cloak = null
	armor = /obj/item/clothing/armor/gambeson/treasure_island/green
	shirt = /obj/item/clothing/shirt/undershirt/fancy
	wrists = /obj/item/storage/keyring/clinic
	gloves = /obj/item/clothing/gloves/leather
	pants = /obj/item/clothing/pants/tights/colored/black
	shoes = /obj/item/clothing/shoes/simpleshoes/buckle
	backr = /obj/item/storage/backpack/satchel
	backl = /obj/item/storage/backpack/satchel/surgbag
	belt = /obj/item/storage/belt/leather/plaquesilver
	beltr = /obj/item/storage/belt/pouch/coins/rich
	beltl = /obj/item/weapon/scabbard/sword/noble
	ring = /obj/item/clothing/ring/feldsher_ring
	l_hand = null
	r_hand = /obj/item/weapon/sword/sabre

	backpack_contents = list(
		/obj/item/storage/belt/pouch/cloth/bullets,
		/obj/item/reagent_containers/glass/bottle/aflask,
		/obj/item/gun/ballistic/revolver/grenadelauncher/pistol,
	)
