/datum/attribute_holder/sheet/job/advclass/combat/adventurer_fighter/verderer
	raw_attribute_list = list(
		STAT_CONSTITUTION = 1,
		STAT_ENDURANCE = 1,
		STAT_STRENGTH = 2,
		/datum/attribute/skill/combat/knives = 20,
		/datum/attribute/skill/combat/axesmaces = 20,
		/datum/attribute/skill/combat/shields = 10,
		/datum/attribute/skill/combat/polearms = 30,
		/datum/attribute/skill/combat/bows = 20,
		/datum/attribute/skill/craft/tanning = 20,
		/datum/attribute/skill/combat/wrestling = 20,
		/datum/attribute/skill/combat/unarmed = 20,
		/datum/attribute/skill/craft/crafting = 10,
		/datum/attribute/skill/misc/swimming = 10,
		/datum/attribute/skill/misc/climbing = 30,
		/datum/attribute/skill/misc/riding = 20,
		/datum/attribute/skill/misc/sewing = 20,
		/datum/attribute/skill/misc/medicine = 10,
		/datum/attribute/skill/misc/reading = 10,
		/datum/attribute/skill/misc/athletics = 30
	)

/datum/job/advclass/combat/adventurer_fighter/verderer
	title = "Verderer"
	tutorial = "Once a verderer sworn to guard the forest marches of the Western Heartlands, \
	you were trained to wield the halberd against beasts, brigands, and invading armies alike. \
	Now you sell your reach, strength, and battlefield control to whoever can afford it."

	outfit = /datum/outfit/adventurer_fighter/verderer
	category_tags = list(CAT_ADVENTURER_FIGHTER)
	give_bank_account = TRUE

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_fighter/verderer


	traits = list(
		TRAIT_MEDIUMARMOR,
		TRAIT_HEAVYARMOR
	)

/datum/outfit/adventurer_fighter/verderer
	name = "Verderer"
	head = /obj/item/clothing/head/helmet/leather/advanced
	mask = null
	neck = /obj/item/clothing/neck/chaincoif
	cloak = /obj/item/clothing/cloak/raincloak/furcloak/colored/brown
	armor = /obj/item/clothing/armor/cuirass/iron/rust
	shirt = /obj/item/clothing/shirt/tribalrag
	wrists = /obj/item/clothing/wrists/bracers/leather/advanced
	gloves = /obj/item/clothing/gloves/plate/rust
	pants = /obj/item/clothing/pants/platelegs/rust
	shoes = /obj/item/clothing/shoes/boots/armor/light/rust
	backr = /obj/item/weapon/polearm/halberd/bardiche
	backl = /obj/item/storage/backpack/satchel
	belt = /obj/item/storage/belt/leather/adventurers_subclasses
	beltl = /obj/item/flashlight/flare/torch/lantern/copper
	beltr = /obj/item/reagent_containers/glass/bottle/waterskin
	ring = null
	l_hand = null
	r_hand = null

	backpack_contents = list(
		/obj/item/storage/belt/pouch/cloth/coins/poor = 1,
		/obj/item/weapon/knife/hunting = 1,
		/obj/item/needle = 1
	)
