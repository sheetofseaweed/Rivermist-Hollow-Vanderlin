/datum/attribute_holder/sheet/job/advclass/combat/adventurer_ranger/steppe_wayfarer
	raw_attribute_list = list(
		STAT_PERCEPTION = 2,
		STAT_ENDURANCE = 2,
		/datum/attribute/skill/craft/crafting = 20,
		/datum/attribute/skill/craft/tanning = 30,
		/datum/attribute/skill/combat/bows = 30,
		/datum/attribute/skill/combat/knives = 20,
		/datum/attribute/skill/craft/cooking = 10,
		/datum/attribute/skill/labor/butchering = 20,
		/datum/attribute/skill/labor/taming = 40,
		/datum/attribute/skill/misc/medicine = 10,
		/datum/attribute/skill/misc/sewing = 20,
		/datum/attribute/skill/misc/sneaking = 20,
		/datum/attribute/skill/craft/traps = 30,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/misc/climbing = 20,
		/datum/attribute/skill/misc/swimming = 10,
		/datum/attribute/skill/misc/riding = 40
	)

/datum/job/advclass/combat/adventurer_ranger/steppe_wayfarer
	title = "Steppe Wayfarer"
	tutorial = "A wandering herder from the eastern grasslands, bound to your mounts and the old migration roads."

	outfit = /datum/outfit/adventurer_ranger/steppe_wayfarer
	category_tags = list(CAT_ADVENTURER_RANGER)
	give_bank_account = TRUE

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_ranger/steppe_wayfarer


	traits = list(TRAIT_FORAGER)

/datum/outfit/adventurer_ranger/steppe_wayfarer
	name = "Steppe Wayfarer"
	head = /obj/item/clothing/head/papakha
	mask = null
	neck = /obj/item/storage/belt/pouch/cloth/coins/poor
	cloak = /obj/item/clothing/cloak/volfmantle
	armor = /obj/item/clothing/armor/leather/hide/steppe
	shirt = /obj/item/clothing/armor/gambeson/light/steppe
	wrists = null
	gloves = null
	pants = /obj/item/clothing/pants/tights/colored/random
	shoes = null
	backr = /obj/item/storage/backpack/satchel
	backl = /obj/item/gun/ballistic/revolver/grenadelauncher/bow/short
	belt = /obj/item/storage/belt/leather/adventurers_subclasses
	beltr = /obj/item/ammo_holder/quiver/arrows
	beltl = /obj/item/storage/meatbag
	ring = null
	l_hand = null
	r_hand = null

	backpack_contents = list(/obj/item/bait = 1, /obj/item/weapon/knife/hunting = 1, /obj/item/tent_kit = 1)

/datum/job/advclass/combat/adventurer_ranger/steppe_wayfarer/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()
	spawned.update_sight()
	var/mounts = list("White Female", "White Male", "Black Female", "Black Male", "Brown Female", "Brown Male")
	var/mount_choice = browser_input_list(spawned, "CHOOSE YOUR MOUNT.", "YOUR HORSE", mounts)

	switch(mount_choice)
		if("White Female")
			spawned.add_spell(/datum/action/cooldown/spell/conjure/summon_horse)
		if("White Male")
			spawned.add_spell(/datum/action/cooldown/spell/conjure/summon_horse/male)
		if("Black Female")
			spawned.add_spell(/datum/action/cooldown/spell/conjure/summon_horse/black)
		if("Black Male")
			spawned.add_spell(/datum/action/cooldown/spell/conjure/summon_horse/black_male)
		if("Brown Female")
			spawned.add_spell(/datum/action/cooldown/spell/conjure/summon_horse/brown)
		if("Brown Male")
			spawned.add_spell(/datum/action/cooldown/spell/conjure/summon_horse/brown_male)
