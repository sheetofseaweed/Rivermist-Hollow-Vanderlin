/obj/effect/landmark
	name = "landmark"
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x2"
	anchored = TRUE
	layer = MID_LANDMARK_LAYER
	invisibility = INVISIBILITY_ABSTRACT
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

// Please stop bombing the Observer-Start landmark.
/obj/effect/landmark/ex_act()
	return

INITIALIZE_IMMEDIATE(/obj/effect/landmark)

/obj/effect/landmark/Initialize()
	. = ..()
	GLOB.landmarks_list += src

/obj/effect/landmark/Destroy()
	GLOB.landmarks_list -= src
	return ..()

/obj/effect/landmark/start
	name = "start"
	icon = 'icons/mob/landmarks.dmi'
	icon_state = "x"
	anchored = TRUE
	layer = MOB_LAYER
	var/list/jobspawn_override = list()
	var/delete_after_roundstart = TRUE
	var/used = FALSE

/obj/effect/landmark/start/Initialize(mapload)
	. = ..()
	GLOB.start_landmarks_list += src

	if(length(jobspawn_override))
		for(var/X in jobspawn_override)
			if(!GLOB.jobspawn_overrides[X])
				GLOB.jobspawn_overrides[X] = list()
			GLOB.jobspawn_overrides[X] += src

	if(name != "start")
		tag = "start*[name]"

/obj/effect/landmark/start/Destroy(force)
	GLOB.start_landmarks_list -= src
	for(var/X in jobspawn_override)
		GLOB.jobspawn_overrides[X] -= src
	return ..()

/obj/effect/landmark/start/proc/after_round_start()
	if(delete_after_roundstart)
		qdel(src)

/obj/effect/landmark/events/haunts
	name = "hauntz"
	icon_state = MAP_SWITCH("", "generic_event")

/obj/effect/landmark/events/haunts/Initialize(mapload)
	. = ..()
	GLOB.hauntstart |= src

/obj/effect/landmark/events/haunts/Destroy()
	GLOB.hauntstart -= src
	return ..()

/obj/effect/landmark/events/testportal
	name = "testserverportal"
	icon_state = "x4"
	var/aportalloc = "a"

/obj/effect/landmark/events/testportal/Initialize(mapload)
	. = ..()
//	GLOB.hauntstart += loc
#ifdef TESTSERVER
	var/obj/structure/fluff/testportal/T = new /obj/structure/fluff/testportal(loc)
	T.aportalloc = aportalloc
	GLOB.testportals += T
#endif
	return INITIALIZE_HINT_QDEL

//JOBS START

/obj/effect/landmark/start/adventurerlate
	name = "Adventurerlate"
	icon_state = "arrow"
	jobspawn_override = list("Adventurer Barbarian",
		"Adventurer Bard",
		"Adventurer Cleric",
		"Adventurer Druid",
		"Adventurer Fighter",
		"Adventurer Monk",
		"Adventurer Paladin",
		"Adventurer Ranger",
		"Adventurer Rogue",
		"Adventurer Sorcerer",
		"Adventurer Warlock",
		"Adventurer Wizard")
	delete_after_roundstart = FALSE

//TOWNHALL

/obj/effect/landmark/start/burgmeister
	name = "Burgmeister"
	icon_state = "arrow"

/obj/effect/landmark/start/councilor
	name = "Councilor"
	icon_state = "arrow"

/obj/effect/landmark/start/servant
	name = "Town Hall Servant"
	icon_state = "arrow"

//TOWNWATCH

/obj/effect/landmark/start/watch_captain
	name = "Town Watch Captain"
	icon_state = "arrow"

/obj/effect/landmark/start/watch_sergeant
	name = "Town Watch Sergeant"
	icon_state = "arrow"

/obj/effect/landmark/start/watch_veteran
	name = "Town Watch Veteran"
	icon_state = "arrow"

/obj/effect/landmark/start/watch_warden
	name = "Town Watch Warden"
	icon_state = "arrow"

/obj/effect/landmark/start/watch_guard
	name = "Town Watch Guard"
	icon_state = "arrow"

//CHAPEL

/obj/effect/landmark/start/moon_priest
	name = "Moon Priest"
	icon_state = "arrow"

/obj/effect/landmark/start/heart_priest
	name = "Heart Priest"
	icon_state = "arrow"

/obj/effect/landmark/start/acolyte
	name = "Chapel Acolyte"
	icon_state = "arrow"

//SCHOLARS

/obj/effect/landmark/start/guild_master_wizard
	name = "Guild Master Wizard"
	icon_state = "arrow"

/obj/effect/landmark/start/guild_wizard
	name = "Guild Wizard"
	icon_state = "arrow"

/obj/effect/landmark/start/guild_wizard_apprentice
	name = "Guild Wizard Apprentice"
	icon_state = "arrow"

/obj/effect/landmark/start/town_apothecary
	name = "Town Physician"
	icon_state = "arrow"

/obj/effect/landmark/start/town_apothecary_apprentice
	name = "Town Physician Apprentice"
	icon_state = "arrow"

/obj/effect/landmark/start/town_scholar
	name = "Town Scholar"
	icon_state = "arrow"

//TRADERS

/obj/effect/landmark/start/waterdeep_merchant
	name = "Waterdeep Guild Merchant"
	icon_state = "arrow"

/obj/effect/landmark/start/waterdeep_banker
	name = "Waterdeep Guild Banker"
	icon_state = "arrow"

/obj/effect/landmark/start/waterdeep_guild_guard
	name = "Waterdeep Guild Guard"
	icon_state = "arrow"

/obj/effect/landmark/start/waterdeep_guild_assistant
	name = "Waterdeep Guild Assistant"
	icon_state = "arrow"

//TAVERN

/obj/effect/landmark/start/adventurers_guildmaster
	name = "Adventurers Guildmaster"
	icon_state = "arrow"

/obj/effect/landmark/start/adventurers_assistant
	name = "Adventurers Guildmaster Assistant"
	icon_state = "arrow"

/obj/effect/landmark/start/innkeep
	name = "Innkeep"
	icon_state = "arrow"

/obj/effect/landmark/start/cook
	name = "Inn Cook"
	icon_state = "arrow"

/obj/effect/landmark/start/matron
	name = "Matron"
	icon_state = "arrow"

/obj/effect/landmark/start/tavern_wench
	name = "Tavern Wench"
	icon_state = "arrow"

//TOWN

/obj/effect/landmark/start/towner
	name = "Towner"
	icon_state = "arrow"

/obj/effect/landmark/start/barber_surgeon
	name = "Barber-Surgeon"
	icon_state = "arrow"

/obj/effect/landmark/start/town_mouth
	name = "Town Mouth"
	icon_state = "arrow"

/obj/effect/landmark/start/town_performer
	name = "Town Performer"
	icon_state = "arrow"

/obj/effect/landmark/start/artisan
	name = "Artisan"
	icon_state = "arrow"

/obj/effect/landmark/start/artisan_apprentice
	name = "Artisan Apprentice"
	icon_state = "arrow"

/obj/effect/landmark/start/miner
	name = "Miner"
	icon_state = "arrow"

/obj/effect/landmark/start/farmhand
	name = "Farmhand"
	icon_state = "arrow"

/obj/effect/landmark/start/hunter
	name = "Hunter"
	icon_state = "arrow"

/obj/effect/landmark/start/fisher
	name = "Fisher"
	icon_state = "arrow"

//OUTSIDERS

/obj/effect/landmark/start/forest_warden
	name = "Forest Warden"
	icon_state = "arrow"

/obj/effect/landmark/start/forest_ranger
	name = "Forest Ranger"
	icon_state = "arrow"

/obj/effect/landmark/start/grove_druid
	name = "Grove Druid"
	icon_state = "arrow"

/obj/effect/landmark/start/swamp_witch
	name = "Swamp Witch"
	icon_state = "arrow"

//ADVENTURERS

/obj/effect/landmark/start/adventurer
	name = "Adventurer"
	icon_state = "arrow"
	jobspawn_override = list("Adventurer Barbarian",
		"Adventurer Bard",
		"Adventurer Cleric",
		"Adventurer Druid",
		"Adventurer Fighter",
		"Adventurer Monk",
		"Adventurer Paladin",
		"Adventurer Ranger",
		"Adventurer Rogue",
		"Adventurer Sorcerer",
		"Adventurer Warlock",
		"Adventurer Wizard")

//JOBS FINISH


/obj/effect/landmark/start/evilskeleton	// Trying to make EVIL SKELTON actually spawn
	name = "Skeleton"
	icon = 'icons/mob/actions/roguespells.dmi'
	icon_state = "raiseskele"
	alpha = 20
	delete_after_roundstart = FALSE

//Antagonist spawns

/obj/effect/landmark/start/bandit
	name = "Bandit"
	icon = 'icons/mob/landmarks.dmi'
	icon_state = "arrow"
	jobspawn_override = list("Bandit")
	delete_after_roundstart = FALSE

/obj/effect/landmark/start/bandit/Initialize()
	. = ..()
	GLOB.bandit_starts += loc

/obj/effect/landmark/start/lich
	name = "Lich"
	icon = 'icons/mob/landmarks.dmi'
	icon_state = "arrow"
	jobspawn_override = list("Lich")
	delete_after_roundstart = FALSE

/obj/effect/landmark/start/lich/Initialize()
	. = ..()
	GLOB.lich_starts += loc

/obj/effect/landmark/admin
	name = "admin"
	icon = 'icons/mob/landmarks.dmi'
	icon_state = "arrow"

/obj/effect/landmark/admin/Initialize()
	. = ..()
	GLOB.admin_warp += loc

/obj/effect/landmark/start/delf
	name = "delf"
	icon = 'icons/mob/landmarks.dmi'
	icon_state = "arrow"

/obj/effect/landmark/start/delf/Initialize()
	. = ..()
	GLOB.delf_starts += loc

// Must be immediate because players will
// join before SSatom initializes everything.
INITIALIZE_IMMEDIATE(/obj/effect/landmark/start/new_player)

/obj/effect/landmark/start/new_player
	name = "New Player"

/obj/effect/landmark/start/new_player/Initialize()
	. = ..()
	GLOB.newplayer_start += loc

/obj/effect/landmark/latejoin
	name = "JoinLate"

/obj/effect/landmark/latejoin/Initialize(mapload)
	..()
	SSjob.latejoin_trackers += loc
	return INITIALIZE_HINT_QDEL

//space carps, magicarps, lone ops, slaughter demons, possibly revenants spawn here
/obj/effect/landmark/carpspawn
	name = "carpspawn"
	icon_state = "carp_spawn"

//observer start
/obj/effect/landmark/observer_start
	name = "Observer-Start"
	icon_state = "x"


//players that get put in admin jail show up here
/obj/effect/landmark/prisonwarp
	name = "prisonwarp"
	icon_state = "prisonwarp"

/obj/effect/landmark/prisonwarp/Initialize(mapload)
	..()
	GLOB.prisonwarp += loc
	return INITIALIZE_HINT_QDEL

/obj/effect/landmark/ert_spawn
	name = "Emergencyresponseteam"
	icon_state = "ert_spawn"

/obj/effect/landmark/ert_spawn/Initialize(mapload)
	..()
	GLOB.emergencyresponseteamspawn += loc
	return INITIALIZE_HINT_QDEL


//generic event spawns
/obj/effect/landmark/event_spawn
	name = "generic event spawn"
	icon_state = "generic_event"
	layer = HIGH_LANDMARK_LAYER


/obj/effect/landmark/event_spawn/Initialize(mapload)
	. = ..()
	GLOB.generic_event_spawns += src

/obj/effect/landmark/event_spawn/Destroy()
	GLOB.generic_event_spawns -= src
	return ..()

/obj/effect/landmark/ruin
	var/datum/map_template/ruin/ruin_template

/obj/effect/landmark/ruin/Initialize(mapload, my_ruin_template)
	. = ..()
	name = "ruin_[length(GLOB.ruin_landmarks) + 1]"
	ruin_template = my_ruin_template
	GLOB.ruin_landmarks |= src

/obj/effect/landmark/ruin/Destroy()
	GLOB.ruin_landmarks -= src
	ruin_template = null
	. = ..()

/// Marks the bottom left of the testing zone.
/// In landmarks.dm and not unit_test.dm so it is always active in the mapping tools.
/obj/effect/landmark/unit_test_bottom_left
	name = "unit test zone bottom left"

/// Marks the top right of the testing zone.
/// In landmarks.dm and not unit_test.dm so it is always active in the mapping tools.
/obj/effect/landmark/unit_test_top_right
	name = "unit test zone top right"

//Underworld landmarks

/obj/effect/landmark/underworld_spawnpoint
	name = "underworld spawnpoint"

/obj/effect/landmark/underworld_spawnpoint/Initialize(mapload)
	. = ..()
	GLOB.underworldspiritspawns |= loc
	return INITIALIZE_HINT_QDEL

/obj/effect/landmark/underworld_pull_location
	name = "coin pull teleport zone"

/obj/effect/landmark/underworld_pull_location/Initialize()
	. = ..()
	GLOB.underworld_coinpull_locs |= loc
	return INITIALIZE_HINT_QDEL

/obj/effect/landmark/death_arena
	name = "Death arena spawn 1"

/obj/effect/landmark/death_arena/Initialize()
	. = ..()
	SSdeath_arena.assign_death_spawn(src)
	return INITIALIZE_HINT_QDEL

/obj/effect/landmark/death_arena/second
	name = "Death arena spawn 2"
