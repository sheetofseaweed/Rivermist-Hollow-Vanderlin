/datum/attribute_holder/sheet/job/advclass/combat/adventurer_fighter/amnian_merc
	raw_attribute_list = list(
		STAT_CONSTITUTION = 2,
		/datum/attribute/skill/misc/swimming = 20,
		/datum/attribute/skill/misc/climbing = 30,
		/datum/attribute/skill/misc/sneaking = 30,
		/datum/attribute/skill/combat/wrestling = 20,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/combat/unarmed = 20,
		/datum/attribute/skill/combat/swords = 20,
		/datum/attribute/skill/combat/whipsflails = 10,
		/datum/attribute/skill/combat/shields = 10,
		/datum/attribute/skill/misc/reading = 10,
		/datum/attribute/skill/craft/cooking = 10
	)

/datum/job/advclass/combat/adventurer_fighter/amnian_merc
	title = "Amnian Mercenary"
	tutorial = "Hailing from the mercenary guilds of Amn, \
	these soldiers of fortune care for little beyond coin, \
	wielding blade or firearm with equal skill, and serving any lord who can pay their price."

	outfit = /datum/outfit/adventurer_fighter/amnian_merc
	category_tags = list(CAT_ADVENTURER_FIGHTER)
	give_bank_account = TRUE

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_fighter/amnian_merc
	traits = list(TRAIT_MEDIUMARMOR)

/datum/outfit/adventurer_fighter/amnian_merc
	name = "Amnian Mercenary"
	head = /obj/item/clothing/head/helmet/skullcap/grenzelhoft
	mask = null
	neck = /obj/item/clothing/neck/chaincoif
	cloak = null
	armor = /obj/item/clothing/armor/cuirass/grenzelhoft
	shirt = /obj/item/clothing/shirt/grenzelhoft
	wrists = null
	gloves = /obj/item/clothing/gloves/angle/grenzel
	pants = /obj/item/clothing/pants/grenzelpants
	shoes = /obj/item/clothing/shoes/rare/grenzelhoft
	backr = null
	backl = null
	belt = /obj/item/storage/belt/leather/adventurers_subclasses
	beltl = null
	beltr = null
	ring = null
	l_hand = null
	r_hand = null

/datum/job/advclass/combat/adventurer_fighter/amnian_merc/after_spawn(mob/living/carbon/human/H)
	. = ..()

	var/weapons = list("Zweihander", "Musket",)
	var/weapon_choice = input(H,"CHOOSE YOUR WEAPON.", "GO EARN SOME COIN.") as anything in weapons
	switch(weapon_choice)
		if("Zweihander")
			H.equip_to_slot_or_del(new /obj/item/weapon/sword/long/greatsword/zwei, ITEM_SLOT_BACK_R, TRUE)
			H.equip_to_slot_or_del(new /obj/item/storage/backpack/satchel, ITEM_SLOT_BACK_L, TRUE)
			H.equip_to_slot_or_del(new /obj/item/storage/belt/pouch/cloth/coins/poor, ITEM_SLOT_BELT_R, TRUE)
			H.equip_to_slot_or_del(new /obj/item/weapon/mace/cudgel, ITEM_SLOT_BELT_L, TRUE)
			H.adjust_stat_modifier(STATMOD_JOB, STATKEY_STR, 2) // They need this to roll at least min STR for the Zwei.
			H.adjust_skillrank(/datum/skill/combat/axesmaces, pick(2,3), TRUE) // Equal chance between skilled and average, can use a cudgel to beat less dangerous targets into submission
			H.adjust_skillrank(/datum/skill/combat/swords, 1, TRUE)
		if("Musket")
			H.equip_to_slot_or_del(new /obj/item/gun/ballistic/revolver/grenadelauncher/pistol/musket, ITEM_SLOT_BACK_R, TRUE)
			H.equip_to_slot_or_del(new /obj/item/ammo_holder/bullet/bullets, ITEM_SLOT_BELT_R, TRUE)
			H.equip_to_slot_or_del(new /obj/item/storage/backpack/satchel/musketeer, ITEM_SLOT_BACK_L, TRUE)
			H.equip_to_slot_or_del(new /obj/item/weapon/sword/sabre/dec, ITEM_SLOT_BELT_L, TRUE)
			H.adjust_skillrank(/datum/skill/combat/firearms, 3, TRUE)
			H.adjust_skillrank(/datum/skill/combat/polearms, 3, TRUE)
