/// A floor's identity: which themes its rooms pull from, its base tier band,
/// stretch length, boss pool, and ambient name. One per designed floor depth.
/datum/dungeon_floor_config
	/// Floor number this config applies to (1-based)
	var/floor = 1
	/// Ambient name shown to players ("The Gnawed Hollows")
	var/floor_name = "The Unmapped Dark"
	/// DUNGEON_THEME_* tags this floor's rooms may pull from
	var/list/themes = list(DUNGEON_THEME_TEST)
	/// Base difficulty tier for this floor (1-5+)
	var/tier = 1
	/// Combat rooms between break rooms on this floor
	var/stretch_length = DUNGEON_RUN_STRETCH_LENGTH
	/// Boss mob typepaths (weighted) that can cap this floor
	var/list/boss_pool = list()
	/// list of /datum/dungeon_spawn_entry — the floor's combat roster
	var/list/combat_mob_pool = list()
	/// Baseline guardian count for a scatter room
	var/density_min = 2
	var/density_max = 4
	/// % chance per spawned mob to receive affixes (when depth > 0)
	var/enhance_chance = 25
	/// % chance per spawned mob to become an elite champion
	var/elite_chance = 8

/datum/dungeon_floor_config/test
	floor = 1
	floor_name = "The Testing Halls"
	themes = list(DUNGEON_THEME_TEST)
	tier = 1
	stretch_length = DUNGEON_RUN_STRETCH_LENGTH
	boss_pool = list(/mob/living/simple_animal/hostile/boss/dungeon/test = 10)

// Deterministic chances on the test floor so foundation unit tests aren't subject
// to random elite/affix variance. Production floors set real values. The random
// elite path is covered deterministically by /datum/unit_test/dungeon_elite_path.
/datum/dungeon_floor_config/test
	enhance_chance = 0
	elite_chance = 0

/datum/dungeon_floor_config/test/New()
	. = ..()
	combat_mob_pool = list(
		new /datum/dungeon_spawn_entry(/mob/living/simple_animal/hostile/retaliate/wolf, 10, DUNGEON_STYLE_MELEE),
		new /datum/dungeon_spawn_entry(/mob/living/simple_animal/hostile/retaliate/wolf, 10, DUNGEON_STYLE_RANGED),
	)

GLOBAL_LIST_EMPTY(dungeon_floor_configs) // assoc floor number (as text) -> /datum/dungeon_floor_config instance

/proc/build_dungeon_floor_configs()
	GLOB.dungeon_floor_configs = list()
	for(var/config_type in subtypesof(/datum/dungeon_floor_config))
		var/datum/dungeon_floor_config/config = new config_type
		GLOB.dungeon_floor_configs["[config.floor]"] = config

/// Returns the config for a floor, falling back to the deepest designed config
/// with its tier raised by the overflow, so floors are effectively endless.
/proc/get_dungeon_floor_config(floor)
	if(!length(GLOB.dungeon_floor_configs))
		build_dungeon_floor_configs()
	floor = max(1, floor)
	var/datum/dungeon_floor_config/config = GLOB.dungeon_floor_configs["[floor]"]
	if(config)
		return config
	var/datum/dungeon_floor_config/deepest = GLOB.dungeon_floor_configs["[DUNGEON_MAX_DESIGNED_FLOOR]"]
	if(!deepest)
		return GLOB.dungeon_floor_configs["1"]
	return deepest

/// Tier band for a given floor: the deepest designed config's tier plus the
/// number of floors past the designed range.
/proc/get_dungeon_floor_tier(floor)
	var/datum/dungeon_floor_config/config = get_dungeon_floor_config(floor)
	if(!config)
		return 1
	if(floor <= DUNGEON_MAX_DESIGNED_FLOOR)
		return config.tier
	return config.tier + (floor - DUNGEON_MAX_DESIGNED_FLOOR)
