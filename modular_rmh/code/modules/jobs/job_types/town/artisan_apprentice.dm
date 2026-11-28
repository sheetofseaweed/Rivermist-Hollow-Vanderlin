/datum/job/artisan_apprentice
	title = "Artisan Apprentice"
	tutorial = "You are learning under a master artisan. \
	You assist, observe, practice, and make mistakes — all while dreaming of the day \
	your name will stand on finished work of your own."
	department_flag = TOWN
	faction = FACTION_TOWN
	total_positions = 4
	spawn_positions = 4
	job_flags = (JOB_ANNOUNCE_ARRIVAL | JOB_SHOW_IN_CREDITS | JOB_EQUIP_RANK | JOB_NEW_PLAYER_JOINABLE)
	display_order = JDO_ARTISAN_APPRENTICE

	allowed_ages = list(AGE_ADULT)
	allowed_races = list("human", "dwarf", "duergar", "aasimar", "elf", "wood elf", "halfelf", "halfling", "gnome", "deep gnome", "drow", "drider", "halfdrow", "tiefling", "dullahan", "harpy", "rakshari", "triton", "medicator", "fluvian", "seelie", "kobold", "hollowkin", "beastkin", "beastkin small", "half-beastkin small", "taurkin", "dragonborn", "yuan-ti", "tabaxi", "lizardfolk", "halforc", "construct", "doll", "goblin", "ooze", "seelie")

	selection_color = JCOLOR_TOWN
	advclass_cat_rolls = list(CAT_ARTISANAP = 20)

	give_bank_account = 5
	job_subclasses = list(
		/datum/job/advclass/artisan_apprentice/blacksmith,
		/datum/job/advclass/artisan_apprentice/carpenter,
		/datum/job/advclass/artisan_apprentice/mason,
		/datum/job/advclass/artisan_apprentice/tailor
	)
