/// A floor's identity: which themes its rooms pull from, its base tier band,
/// stretch length, boss pool, and ambient name. One per designed floor depth;
/// when several configs claim the same floor, the highest priority wins.
/datum/dungeon_floor_config
	abstract_type = /datum/dungeon_floor_config
	/// Floor number this config applies to (1-based)
	var/floor = 1
	/// Wins floor-number collisions (test fixtures outrank content in test builds)
	var/priority = 0
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
	/// Stretches (break-room intervals) before this floor's boss caps a stretch
	var/stretches_per_floor = 1
	/// % chance a combat room on this floor rolls a room trait
	var/trait_chance = DUNGEON_ROOM_TRAIT_CHANCE

// -- The Sunken Warrens: underground swamp goblin floors (starter content) --

/datum/dungeon_floor_config/swampgob
	floor = 1
	floor_name = "The Sunken Warrens"
	themes = list(DUNGEON_THEME_SWAMPGOB)
	tier = 1
	stretch_length = 4
	boss_pool = list(/mob/living/carbon/human/species/goblin/npc/ambush = 10)

/datum/dungeon_floor_config/swampgob/New()
	. = ..()
	combat_mob_pool = list(
		new /datum/dungeon_spawn_entry(/mob/living/carbon/human/species/goblin/npc/ambush, 12, DUNGEON_STYLE_MELEE),
		new /datum/dungeon_spawn_entry(/mob/living/carbon/human/species/goblin/npc, 8, DUNGEON_STYLE_MELEE),
		new /datum/dungeon_spawn_entry(/mob/living/simple_animal/hostile/retaliate/bogbug, 5, DUNGEON_STYLE_MELEE),
		new /datum/dungeon_spawn_entry(/mob/living/simple_animal/hostile/retaliate/frog, 3, DUNGEON_STYLE_MELEE),
	)

/datum/dungeon_floor_config/swampgob/deep
	floor = 2
	floor_name = "The Drowned Warrens"
	tier = 2
	stretch_length = 5
	density_min = 3
	density_max = 5
	elite_chance = 12

#ifdef UNIT_TESTS
// Deterministic fixture floor: outranks content configs on floor 1 so the unit
// tests aren't subject to random elite/affix/trait variance. Trait behavior is
// forced directly in the trait tests.
/datum/dungeon_floor_config/test
	floor = 1
	priority = 100
	floor_name = "The Testing Halls"
	themes = list(DUNGEON_THEME_TEST)
	tier = 1
	stretch_length = DUNGEON_RUN_STRETCH_LENGTH
	boss_pool = list(/mob/living/simple_animal/hostile/boss/dungeon/test = 10)
	enhance_chance = 0
	elite_chance = 0
	trait_chance = 0

/datum/dungeon_floor_config/test/New()
	. = ..()
	combat_mob_pool = list(
		new /datum/dungeon_spawn_entry(/mob/living/simple_animal/hostile/retaliate/wolf, 10, DUNGEON_STYLE_MELEE),
		new /datum/dungeon_spawn_entry(/mob/living/simple_animal/hostile/retaliate/wolf, 10, DUNGEON_STYLE_RANGED),
	)
#endif

GLOBAL_LIST_EMPTY(dungeon_floor_configs) // assoc floor number (as text) -> /datum/dungeon_floor_config instance
GLOBAL_VAR_INIT(dungeon_deepest_floor_config, 0)

/proc/build_dungeon_floor_configs()
	GLOB.dungeon_floor_configs = list()
	GLOB.dungeon_deepest_floor_config = 0
	for(var/datum/dungeon_floor_config/config_type as anything in subtypesof(/datum/dungeon_floor_config))
		if(IS_ABSTRACT(config_type))
			continue
		var/datum/dungeon_floor_config/config = new config_type
		var/datum/dungeon_floor_config/existing = GLOB.dungeon_floor_configs["[config.floor]"]
		if(existing && existing.priority >= config.priority)
			qdel(config)
			continue
		GLOB.dungeon_floor_configs["[config.floor]"] = config
		GLOB.dungeon_deepest_floor_config = max(GLOB.dungeon_deepest_floor_config, config.floor)

/// Returns the config for a floor. Beyond the deepest designed floor the
/// deepest config repeats (with a rising tier via get_dungeon_floor_tier),
/// so floors are effectively endless.
/proc/get_dungeon_floor_config(floor)
	if(!length(GLOB.dungeon_floor_configs))
		build_dungeon_floor_configs()
	floor = max(1, floor)
	var/datum/dungeon_floor_config/config = GLOB.dungeon_floor_configs["[floor]"]
	if(config)
		return config
	return GLOB.dungeon_floor_configs["[GLOB.dungeon_deepest_floor_config]"] || GLOB.dungeon_floor_configs["1"]

/// Tier band for a given floor: past the deepest designed config, its tier
/// keeps climbing with the overflow.
/proc/get_dungeon_floor_tier(floor)
	var/datum/dungeon_floor_config/config = get_dungeon_floor_config(floor)
	if(!config)
		return 1
	if(floor <= GLOB.dungeon_deepest_floor_config)
		return config.tier
	return config.tier + (floor - GLOB.dungeon_deepest_floor_config)
