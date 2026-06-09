/datum/attribute_holder/sheet/job/advclass/combat/adventurer_wizard/necromancer
	raw_attribute_list = list(
		STAT_STRENGTH = -1,
		STAT_CONSTITUTION = -1,
		STAT_INTELLIGENCE = 4,
		/datum/attribute/skill/combat/polearms = 30,
		/datum/attribute/skill/misc/climbing = 30,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/combat/wrestling = 30,
		/datum/attribute/skill/combat/unarmed = 30,
		/datum/attribute/skill/misc/reading = 50,
		/datum/attribute/skill/craft/alchemy = 40,
		/datum/attribute/skill/magic/arcane = 40
	)

/datum/job/advclass/combat/adventurer_wizard/necromancer
	title = "Necromancer Wizard"
	tutorial = "Shunned, hunted, and feared, you have embraced the dark arts of death and undeath. \
	Society calls your magic unnatural, yet through forbidden study, you wield dominion over souls and corpses. \
	Your loyalty is to the Cabal, and your ambition surpasses mortal morality."

	give_bank_account = TRUE
	outfit = /datum/outfit/adventurer_wizard/necromancer
	category_tags = list(CAT_ADVENTURER_WIZARD)
	exp_types_granted = list(EXP_TYPE_COMBAT, EXP_TYPE_MAGICK)

	languages = list(/datum/language/undead)

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_wizard/necromancer


	traits = list(
		TRAIT_CABAL,
		TRAIT_GRAVEROBBER,
		TRAIT_DEADNOSE
	)

	spells = list(
		/datum/action/cooldown/spell/undirected/touch/prestidigitation,
		/datum/action/cooldown/spell/eyebite,
		/datum/action/cooldown/spell/chill_touch,
		/datum/action/cooldown/spell/projectile/sickness,
		/datum/action/cooldown/spell/conjure/raise_lesser_undead/necromancer,
		/datum/action/cooldown/spell/gravemark,
		/datum/action/cooldown/spell/control_undead,
		/datum/action/cooldown/spell/enrapture,
		/datum/action/cooldown/spell/forced_orgasm,
	)

/datum/job/advclass/combat/adventurer_wizard/necromancer/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()

	spawned.mana_pool?.intrinsic_recharge_sources &= ~MANA_ALL_LEYLINES
	spawned.mana_pool?.set_intrinsic_recharge(MANA_SOULS)
	spawned.mana_pool?.ethereal_recharge_rate += 0.1

/datum/outfit/adventurer_wizard/necromancer
	name = "Necromancer Wizard"
	head = null
	mask = null
	neck = /obj/item/clothing/neck/chaincoif
	cloak = null
	armor = null
	shirt = /obj/item/clothing/shirt/tunic/colored
	wrists = /obj/item/clothing/wrists/bracers
	gloves = /obj/item/clothing/gloves/chain
	pants = /obj/item/clothing/pants/chainlegs
	shoes = /obj/item/clothing/shoes/shortboots
	backr = null
	backl = null
	belt = /obj/item/storage/belt/leather/black/adventurers_subclasses
	backl = /obj/item/storage/backpack/satchel
	beltr = /obj/item/reagent_containers/glass/bottle/manapot
	ring = null
	l_hand = null
	r_hand = /obj/item/weapon/polearm/woodstaff

	backpack_contents = list(
		/obj/item/book/granter/spellbook/adept = 1,
		/obj/item/chalk = 1,
		/obj/item/rope/chain = 1,
		/obj/item/reagent_containers/glass/bottle/stronghealthpot = 1,
		/obj/item/storage/belt/pouch/cloth/coins/poor = 1,
		/obj/item/weapon/knife/dagger/silver/arcyne = 1
	)

/datum/outfit/adventurer_wizard/necromancer/post_equip(mob/living/carbon/human/H, visuals_only)
	. = ..()
	var/static/list/selectablehat = list(
		"Witch hat" = /obj/item/clothing/head/wizhat/witch,
		"Random Wizard hat" = /obj/item/clothing/head/wizhat/random,
		"Mage hood" = /obj/item/clothing/head/roguehood/colored/mage,
		"Generic Wizard hat" = /obj/item/clothing/head/wizhat/gen,
		"Mage hood" = /obj/item/clothing/head/roguehood/colored/mage,
		"Black hood" = /obj/item/clothing/head/roguehood/colored/black,
		"Ominous hood (skullcap)" = /obj/item/clothing/head/helmet/skullcap/cult,
	)
	H.select_equippable(H, selectablehat, message = "Choose your hat of choice", title = "NECROMANCER")
	var/static/list/selectablerobe = list(
		"Black robes" = /obj/item/clothing/shirt/robe/colored/black,
		"Mage robes" = /obj/item/clothing/shirt/robe/colored/mage,
		"Necromancer robes" = /obj/item/clothing/shirt/robe/necromancer
	)
	H.select_equippable(H, selectablerobe, message = "Choose your robe of choice", title = "NECROMANCER")
