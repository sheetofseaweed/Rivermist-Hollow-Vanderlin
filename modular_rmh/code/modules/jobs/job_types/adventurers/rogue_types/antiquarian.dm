/datum/attribute_holder/sheet/job/advclass/combat/adventurer_rogue/antiquarian
	raw_attribute_list = list(
		STAT_CONSTITUTION = -1,
		STAT_ENDURANCE = -1,
		STAT_STRENGTH = -2, // These are all relatively low, the class requires cantrips to work around these.
		/datum/attribute/skill/combat/axesmaces = SKILL_LEVEL_JOURNEYMAN,
		// Needed just for NPC's.
		/datum/attribute/skill/misc/swimming = SKILL_LEVEL_MASTER,
		/datum/attribute/skill/combat/wrestling = SKILL_LEVEL_JOURNEYMAN,
		/datum/attribute/skill/combat/unarmed = SKILL_LEVEL_EXPERT,
		// They're not meant to kill.
		/datum/attribute/skill/misc/climbing = SKILL_LEVEL_MASTER,
		/datum/attribute/skill/craft/crafting = SKILL_LEVEL_JOURNEYMAN,
		/datum/attribute/skill/misc/athletics = SKILL_LEVEL_EXPERT,
		/datum/attribute/skill/misc/reading = SKILL_LEVEL_JOURNEYMAN,
		/datum/attribute/skill/misc/sneaking = SKILL_LEVEL_LEGENDARY,
		/datum/attribute/skill/misc/stealing = SKILL_LEVEL_LEGENDARY,
		/datum/attribute/skill/misc/lockpicking = SKILL_LEVEL_MASTER,
		/datum/attribute/skill/misc/sewing = SKILL_LEVEL_JOURNEYMAN,
		/datum/attribute/skill/craft/bombs = SKILL_LEVEL_JOURNEYMAN // To craft Smoke Bombs.
	)

/datum/job/advclass/combat/adventurer_rogue/antiquarian
	title = "Shadow Antiquarian"
	tutorial = "A streetwise antiquarian, skilled in stealth, subterfuge, and minor magics, \
	who recovers relics and secrets from Faerûn's alleys and ruins."

	outfit = /datum/outfit/adventurer_rogue/antiquarian
	category_tags = list(CAT_ADVENTURER_ROGUE)
	give_bank_account = TRUE

// The idea is that they're a slippery bastard. Cantrip focused, stealth-focused. They rely on their spells.
	languages = list(/datum/language/thievescant)

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/combat/adventurer_rogue/antiquarian

	traits = list(
		TRAIT_DEADNOSE,
		TRAIT_THIEVESGUILD,
		TRAIT_DODGEEXPERT,
		TRAIT_LIGHT_STEP
	)


	spells = list(
		/datum/action/cooldown/spell/undirected/conjure_item/smoke_bomb,
		/datum/action/cooldown/spell/undirected/adrenalinerush,
		/datum/action/cooldown/spell/undirected/secondsight,
		/datum/action/cooldown/spell/undirected/jaunt/ethereal_jaunt,
		/datum/action/cooldown/spell/undirected/conjure_item/summon_lockpick,
		/datum/action/cooldown/spell/projectile/flashpowder,
		/datum/action/cooldown/spell/aoe/snuff,
		/datum/action/cooldown/spell/undirected/conjure_item/calling_card
	)
	var/list/honoraries = list(
		"Acquisitions Expert" = HONORARY_PREFIX,
		"the Cleptologist" = HONORARY_SUFFIX,
		"the One Who Walks" = HONORARY_SUFFIX,
		"of Deadly Shadows" = HONORARY_SUFFIX,
		"the Prince of Shadows" = HONORARY_SUFFIX,
		"the Recovery Specialist" = HONORARY_SUFFIX,
		"the Acquirer" = HONORARY_SUFFIX,
		"the Antiquarian" = HONORARY_SUFFIX,
		"the Art Critic" = HONORARY_SUFFIX,
		"the Collector" = HONORARY_SUFFIX,
		"the Courier" = HONORARY_SUFFIX,
		"the Crow" = HONORARY_SUFFIX,
		"the Fence" = HONORARY_SUFFIX,
		"the Filcher" = HONORARY_SUFFIX,
		"the Ghost" = HONORARY_SUFFIX,
		"the Grifter" = HONORARY_SUFFIX,
		"the Infiltrator" = HONORARY_SUFFIX,
		"the Intruder" = HONORARY_SUFFIX,
		"the Invisible" = HONORARY_SUFFIX,
		"the Keeper" = HONORARY_SUFFIX,
		"the Locksmith" = HONORARY_SUFFIX,
		"the Lurker" = HONORARY_SUFFIX,
		"the Magpie" = HONORARY_SUFFIX,
		"the Mask" = HONORARY_SUFFIX,
		"the Master Thief" = HONORARY_SUFFIX,
		"the Night Watch" = HONORARY_SUFFIX,
		"the Phantom" = HONORARY_SUFFIX,
		"the Raven" = HONORARY_SUFFIX,
		"the Respectable Citizen" = HONORARY_SUFFIX,
		"the Shadow" = HONORARY_SUFFIX,
		"the Skeleton Key" = HONORARY_SUFFIX,
		"the Specialist" = HONORARY_SUFFIX,
		"the Stalker" = HONORARY_SUFFIX,
		"the Trickster" = HONORARY_SUFFIX,
		"the Watcher" = HONORARY_SUFFIX,
	)

/datum/outfit/adventurer_rogue/antiquarian
	name = "Shadow Antiquarian"
	head = /obj/item/clothing/head/roguehood/faceless
	mask = /obj/item/clothing/face/antiq
	neck = /obj/item/clothing/neck/coif
	cloak = /obj/item/clothing/cloak/raincloak/colored/mortus
	armor = /obj/item/clothing/armor/leather/splint
	shirt = /obj/item/clothing/shirt/tunic/colored/purple
	wrists = null
	gloves = /obj/item/clothing/gloves/bandages/pugilist
	pants = /obj/item/clothing/pants/trou/leather
	shoes = /obj/item/clothing/shoes/boots/leather
	backr = /obj/item/storage/backpack/backpack/longhike/with_bedroll
	backl = null
	belt = /obj/item/storage/belt/leather/black/adventurers_subclasses
	beltl = /obj/item/weapon/mace/cudgel
	beltr = null
	ring = null
	l_hand = null
	r_hand = null

	backpack_contents = list(
		/obj/item/lockpick = 1,
		/obj/item/grapplinghook = 1,
		/obj/item/reagent_containers/glass/bottle/stronghealthpot = 1,
	)

/datum/outfit/adventurer_rogue/antiquarian/pre_equip(mob/living/carbon/human/equipped_human, visuals_only)
	. = ..()
	equipped_human.mana_pool?.set_intrinsic_recharge(MANA_ALL_LEYLINES)

/datum/job/advclass/combat/adventurer_rogue/antiquarian/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()
	if(length(honoraries) && alert("Do you wish for a random title? You will not receive one if you click No.", "", "Yes", "No") == "Yes")
		var/selected_honorary = pick(honoraries)
		if(honoraries[selected_honorary] == HONORARY_SUFFIX)
			spawned.honorary_suffix = selected_honorary
		else
			spawned.honorary = selected_honorary
