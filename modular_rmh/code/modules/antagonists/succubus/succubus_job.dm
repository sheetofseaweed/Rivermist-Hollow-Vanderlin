GLOBAL_LIST_EMPTY(succubus_sewer_insertions)

/datum/job/succubus
	title = ROLE_SUCCUBUS
	tutorial = "You awaken in your infernal home, hungry for mortal essence. Prepare a face, enter their world, and fulfill the contracts that will restore your full power."
	department_flag = VILLAINS
	faction = FACTION_TOWN
	total_positions = 1
	spawn_positions = 1
	antag_job = TRUE
	can_random = FALSE
	selection_color = JCOLOR_VILLAINS
	job_flags = (JOB_EQUIP_RANK | JOB_SHOW_IN_CREDITS | JOB_NEW_PLAYER_JOINABLE)
	allowed_races = ALL_RACES_LIST
	job_whitelist_id = "succubus"
	outfit = /datum/outfit/antagonist/succubus
	antag_role = /datum/antagonist/succubus
	display_order = JDO_SUCCUBUS
	rune_linked = RUNE_LINK_ANTAG

/datum/job/succubus/proc/can_take_succubus_job(player_ckey)
	if(!player_ckey)
		return FALSE
	if(is_total_antag_banned(player_ckey))
		return FALSE
	if(is_antag_banned(player_ckey, ROLE_SUCCUBUS))
		return FALSE
	return TRUE

/datum/job/succubus/proc/get_home_spawn_point()
	var/list/valid_home_spawns = list()
	for(var/obj/effect/landmark/start/succubus/home_spawn in GLOB.jobspawn_overrides[title])
		if(!istype(get_area(home_spawn), /area/indoors/succubus_lair))
			continue
		valid_home_spawns += home_spawn
	if(!length(valid_home_spawns))
		return
	return pick(valid_home_spawns)

/datum/job/succubus/proc/has_required_landmarks()
	if(!get_home_spawn_point())
		return FALSE
	if(!length(GLOB.succubus_sewer_insertions))
		return FALSE
	for(var/obj/effect/landmark/start/spawn_point as anything in GLOB.start_landmarks_list)
		if(istype(spawn_point, /obj/effect/landmark/start/adventurerlate))
			return TRUE
	return FALSE

/datum/job/succubus/special_job_check(mob/dead/new_player/player)
	if(!player?.client)
		return FALSE
	if(!has_required_landmarks())
		return FALSE
	return can_take_succubus_job(player.ckey)

/datum/job/succubus/special_check_latejoin(client/player_client)
	if(!has_required_landmarks())
		return FALSE
	return can_take_succubus_job(player_client?.ckey)

/datum/job/succubus/get_roundstart_spawn_point()
	if(!has_required_landmarks())
		log_world("Refusing to spawn [title]: the map is missing a required Succubus landmark.")
		return
	var/obj/effect/landmark/start/succubus/home_spawn = get_home_spawn_point()
	home_spawn.used = TRUE
	return home_spawn

/datum/job/succubus/get_latejoin_spawn_point()
	if(!has_required_landmarks())
		log_world("Refusing to latejoin [title]: the map is missing a required Succubus landmark.")
		return
	return get_home_spawn_point()

/datum/outfit/antagonist/succubus
	name = "Succubus"
	head = null
	mask = null
	neck = null
	cloak = null
	armor = null
	shirt = /obj/item/clothing/shirt/robe/colored/black
	wrists = null
	gloves = null
	pants = /obj/item/clothing/pants/tights/colored/black
	shoes = /obj/item/clothing/shoes/simpleshoes
	backr = /obj/item/storage/backpack/satchel/black
	backl = null
	belt = /obj/item/storage/belt/leather
	beltl = /obj/item/storage/belt/pouch/cloth/coins/poor
	beltr = null
	ring = null
	l_hand = null
	r_hand = null

/obj/effect/landmark/start/succubus
	name = ROLE_SUCCUBUS
	icon_state = "arrow"
	jobspawn_override = list(ROLE_SUCCUBUS)
	delete_after_roundstart = FALSE

/obj/effect/landmark/succubus_insertion
	name = "succubus insertion"
	icon = 'icons/mob/landmarks.dmi'
	icon_state = "arrow"

/obj/effect/landmark/succubus_insertion/sewers
	name = "Succubus sewer insertion"

/obj/effect/landmark/succubus_insertion/sewers/Initialize(mapload)
	. = ..()
	GLOB.succubus_sewer_insertions += src

/obj/effect/landmark/succubus_insertion/sewers/Destroy()
	GLOB.succubus_sewer_insertions -= src
	return ..()
