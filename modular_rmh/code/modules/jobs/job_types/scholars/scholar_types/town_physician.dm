/datum/attribute_holder/sheet/job/advclass/town_scholar/town_physician
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

/datum/job/advclass/town_scholar/town_physician
	title = "Town Physician"
	tutorial = "You are the town’s physician. \
	You cut hair, shave beards, and keep tools clean to prevent sickness. \
	You brew simple medicines, dress wounds, set bones, and stitch what can be saved. \
	You work with herbs, steel, and steady hands, guided by experience rather than superstition. \
	Your work is quiet, constant, and often thankless — but the town is healthier for it."

	total_positions = 1
	spawn_positions = 1

	outfit = /datum/outfit/town_scholar/town_physician
	category_tags = list(CAT_ARCHIVIST)

	trainable_skills = list(/datum/skill/craft/alchemy)
	max_apprentices = 2
	apprentice_name = "Town Physician Apprentice"
	can_have_apprentices = TRUE

	give_bank_account = 100
	job_bitflag = BITFLAG_CONSTRUCTOR

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/town_scholar/town_physician


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

/datum/outfit/town_scholar/town_physician
	name = "Town Physician"
	head = null
	mask = /obj/item/clothing/face/courtphysician
	neck = /obj/item/storage/belt/pouch/cloth/coins/mid
	cloak = null
	armor = null
	shirt = null
	wrists = null
	gloves = null
	pants = null
	shoes = null
	backr = /obj/item/storage/backpack/satchel
	backl = /obj/item/storage/backpack/satchel/surgbag
	belt = /obj/item/storage/belt/leather
	beltr = /obj/item/storage/keyring/clinic
	beltl = /obj/item/storage/fancy/ifak
	ring = /obj/item/clothing/ring/feldsher_ring
	l_hand = /obj/item/clothing/gloves/leather/thaumgloves
	r_hand = null

/datum/outfit/town_scholar/town_physician/pre_equip(mob/living/carbon/human/equipped_human, visuals_only)
	. = ..()
	if(equipped_human.gender == MALE)
		head = /obj/item/clothing/head/courtphysician
		armor = /obj/item/clothing/armor/leather/courtphysician
		shirt = /obj/item/clothing/shirt/undershirt/courtphysician
		gloves = /obj/item/clothing/gloves/leather/courtphysician
		pants = /obj/item/clothing/pants/trou/leather/courtphysician
		shoes = /obj/item/clothing/shoes/courtphysician
	else
		head = /obj/item/clothing/head/courtphysician/female
		armor = /obj/item/clothing/armor/leather/courtphysician/female
		shirt = /obj/item/clothing/shirt/undershirt/courtphysician/female
		gloves = /obj/item/clothing/gloves/leather/courtphysician/female
		pants = /obj/item/clothing/pants/skirt/courtphysician
		shoes = /obj/item/clothing/shoes/heels/courtphysician/female
