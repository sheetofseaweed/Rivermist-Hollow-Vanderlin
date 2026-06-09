/datum/attribute_holder/sheet/job/advclass/towner/miner
	raw_attribute_list = list(
		STAT_STRENGTH = 1,
		STAT_INTELLIGENCE = -2,
		STAT_ENDURANCE = 2,
		STAT_CONSTITUTION = 1,
		STAT_FORTUNE = 1,
		/datum/attribute/skill/combat/axesmaces = 20,
		/datum/attribute/skill/labor/mining = 40,
		/datum/attribute/skill/combat/wrestling = 10,
		/datum/attribute/skill/combat/unarmed = 20,
		/datum/attribute/skill/craft/crafting = 20,
		/datum/attribute/skill/misc/swimming = 10,
		/datum/attribute/skill/misc/climbing = 20,
		/datum/attribute/skill/misc/medicine = 10,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/craft/traps = 10,
		/datum/attribute/skill/craft/engineering = 20,
		/datum/attribute/skill/craft/blacksmithing = 10,
		/datum/attribute/skill/craft/smelting = 20,
		/datum/attribute/skill/misc/reading = 10
	)

/datum/job/advclass/towner/miner
	title = "Miner"
	tutorial = "In the hills near Rivermist Hollow, \
	you work the patient labor of stone and earth. \
	Salt, iron, and useful rock are your livelihood, \
	and you know the land well enough to hear when it shifts or settles. \
	It is honest work, often shared with a mug of ale at day’s end, \
	and the town relies on what you bring up from below."
	total_positions = 5
	spawn_positions = 5

	outfit = /datum/outfit/towner/miner
	category_tags = list(CAT_TOWNER)
	give_bank_account = 6

	job_bitflag = BITFLAG_CONSTRUCTOR

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/towner/miner


/datum/outfit/towner/miner
	name = "Miner"
	head = /obj/item/clothing/head/helmet/leather/minershelm
	mask = null
	neck = /obj/item/storage/belt/pouch/cloth/coins/poor
	cloak = null
	armor = /obj/item/clothing/armor/gambeson/light/striped
	shirt = /obj/item/clothing/shirt/undershirt/colored/random
	wrists = /obj/item/storage/keyring/guild_artisan
	gloves = null
	pants = /obj/item/clothing/pants/trou
	shoes = /obj/item/clothing/shoes/boots/leather
	backr = /obj/item/weapon/shovel
	backl = /obj/item/storage/backpack/backpack
	belt = /obj/item/storage/belt/leather
	beltl = /obj/item/weapon/pick
	beltr = /obj/item/flashlight/flare/torch/lantern
	ring = /obj/item/clothing/ring/silver/makers_guild
	l_hand = null
	r_hand = null

	backpack_contents = list(
		/obj/item/flint = 1,
		/obj/item/weapon/knife/villager = 1,
	)
