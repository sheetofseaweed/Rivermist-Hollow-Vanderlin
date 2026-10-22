/datum/attribute_holder/sheet/job/guild_wizard_apprentice
	raw_attribute_list = list(
		STAT_INTELLIGENCE = 1,
		STAT_SPEED = -1,
		/datum/attribute/skill/magic/arcane = 10,
		/datum/attribute/skill/misc/reading = 30,
		/datum/attribute/skill/combat/knives = 20,
		/datum/attribute/skill/misc/swimming = 20,
		/datum/attribute/skill/misc/climbing = 20,
		/datum/attribute/skill/misc/athletics = 10,
		/datum/attribute/skill/combat/polearms = 20
	)

/datum/job/guild_wizard_apprentice
	title = "Guild Wizard Apprentice"
	tutorial = "You are learning the arcane arts. Study hard, assist your mentors, and practice your magic to become a fully fledged guild wizard."
	department_flag = SCHOLARS
	faction = FACTION_TOWN
	total_positions = 4
	spawn_positions = 4
	job_flags = (JOB_ANNOUNCE_ARRIVAL | JOB_SHOW_IN_CREDITS | JOB_EQUIP_RANK | JOB_NEW_PLAYER_JOINABLE)
	display_order = JDO_GUILD_WIZARD_APPRENTICE

	allowed_races = ALL_RACES_LIST
	allowed_ages = list(AGE_ADULT)

	outfit = /datum/outfit/guild_wizard_apprentice
	selection_color = JCOLOR_SCHOLARS

	give_bank_account = 20
	exp_types_granted = list(EXP_TYPE_MAGICK, EXP_TYPE_ADVENTURER)

	attribute_sheet = /datum/attribute_holder/sheet/job/guild_wizard_apprentice


	magic_user = TRUE
	spell_points = 15
	caster_archetype = CASTER_FULL
	prepares_spells = TRUE
	form_points = 3
	technique_points = 1
	spells = list(
		/datum/action/cooldown/spell/undirected/touch/prestidigitation,
		/datum/action/cooldown/spell/undirected/conjure_item/light,
	)

/datum/outfit/guild_wizard_apprentice
	name = "Apprentice Wizard"
	head = null
	mask = null
	neck = null
	cloak = null
	armor = null
	shirt = null
	wrists = null
	gloves = null
	pants = null
	shoes = /obj/item/clothing/shoes/shortboots
	backr = /obj/item/storage/backpack/satchel
	backl = null
	belt = /obj/item/storage/belt/leather/rope
	beltr = /obj/item/storage/magebag/apprentice
	beltl = /obj/item/storage/keyring/master_wizard
	ring = null
	l_hand = null
	r_hand = /obj/item/weapon/polearm/woodstaff

	backpack_contents = list(
		/obj/item/book/granter/spellbook/apprentice = 1,
		/obj/item/spellbook/apprentice/starter/arcane = 1,
		/obj/item/chalk = 1,
		/obj/item/storage/belt/pouch/cloth/coins/mid,
	)

/datum/outfit/guild_wizard_apprentice/pre_equip(mob/living/carbon/human/equipped_human, visuals_only)
	. = ..()
	equipped_human.mana_pool?.set_intrinsic_recharge(MANA_ALL_LEYLINES)

/datum/job/guild_wizard_apprentice/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()
	var/static/list/selectablehat = list(
		"Mage hood" = /obj/item/clothing/head/roguehood/colored/mage,
		"None" = null,
	)
	spawned.select_equippable(player_client, selectablehat, message = "Choose your hat of choice", title = "APPRENTICE")
	if(QDELETED(spawned))
		return

	var/static/list/selectablerobe = list(
		"Mage robes" = /obj/item/clothing/shirt/robe/colored/mage,
		"Mage robes Alt" = /obj/item/clothing/shirt/robe/skyrim_mage,
		"Tunic" = /obj/item/clothing/shirt/tunic,
		"Lowcut tunic" = /obj/item/clothing/shirt/undershirt/lowcut,
		"Silk dress" = /obj/item/clothing/shirt/dress/silkdress/colored/random,
	)
	spawned.select_equippable(player_client, selectablerobe, message = "Choose your attire of choice", title = "APPRENTICE")
