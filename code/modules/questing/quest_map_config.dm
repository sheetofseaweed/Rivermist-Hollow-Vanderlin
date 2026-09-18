// Map-specific quest configuration: difficulty multipliers, reward multipliers, and ambush pools.
// Each map file is mapped to a config datum that modifies quest behavior when the quest spawns on that map.
// Difficulty and reward values are defined in code/__DEFINES/quests.dm (QUEST_MAP_DIFFICULTY_*, QUEST_MAP_REWARD_*).

/datum/quest_map_config
	/// The map file name (lowercased, e.g. "bogforest.dmm") this config applies to
	var/map_file = ""
	/// Human-readable name for display
	var/map_name = "Unknown"
	/// Difficulty multiplier — drives ambush chance and mob scaling. Defined in quests.dm.
	var/difficulty_modifier = 1.0
	/// Reward multiplier — globally scales quest payout on this map. Defined in quests.dm.
	var/reward_modifier = 1.0
	/// Which QUEST_MAP_FLAG_* bitfield this map corresponds to for mob filtering
	var/map_flag = QUEST_MAP_FLAG_ALL
	/// List of /datum/ambush_config paths that can spawn as quest ambushes on this map
	var/list/ambush_pools = list()
	/// Weight modifier for easy quests (ROUTINE/RISKY) being placed on this map. 1.0 = normal.
	var/easy_quest_weight = 1.0
	/// Weight modifier for medium quests (DANGEROUS/DEADLY) on this map.
	var/medium_quest_weight = 1.0
	/// Weight modifier for hard quests (LETHAL/MYTHIC) on this map.
	var/hard_quest_weight = 1.0

/// Returns the effective ambush chance for this map, derived from difficulty_modifier.
/// Formula: clamp(QUEST_AMBUSH_BASE_CHANCE * difficulty_modifier, MIN, MAX)
/datum/quest_map_config/proc/get_ambush_chance()
	return clamp(round(QUEST_AMBUSH_BASE_CHANCE * difficulty_modifier), QUEST_AMBUSH_MIN_CHANCE, QUEST_AMBUSH_MAX_CHANCE)

/datum/quest_map_config/town
	map_file = "hsector.dmm"
	map_name = "Rivermist City"
	difficulty_modifier = QUEST_MAP_DIFFICULTY_TOWN
	reward_modifier = QUEST_MAP_REWARD_TOWN
	map_flag = QUEST_MAP_FLAG_TOWN
	easy_quest_weight = 1.6   // Easy quests appear 60% more often on the starter map
	medium_quest_weight = 0.7 // Medium quests appear 30% less often
	hard_quest_weight = 0.5   // Hard quests appear 50% less often
	ambush_pools = list(
		/datum/ambush_config/raccoon_swarm,
		/datum/ambush_config/highwayman_duo,
	)

/datum/quest_map_config/town_snow
	map_file = "hsector_snow.dmm"
	map_name = "Rivermist City (Winter)"
	difficulty_modifier = QUEST_MAP_DIFFICULTY_TOWN_SNOW
	reward_modifier = QUEST_MAP_REWARD_TOWN_SNOW
	map_flag = QUEST_MAP_FLAG_TOWN
	easy_quest_weight = 1.6   // Same starter map treatment as non-winter town
	medium_quest_weight = 0.7
	hard_quest_weight = 0.5
	ambush_pools = list(
		/datum/ambush_config/wolf_pack,
		/datum/ambush_config/highwayman_duo,
	)

/datum/quest_map_config/bog
	map_file = "bogforest.dmm"
	map_name = "Bog Forest"
	difficulty_modifier = QUEST_MAP_DIFFICULTY_BOG
	reward_modifier = QUEST_MAP_REWARD_BOG
	map_flag = QUEST_MAP_FLAG_BOG
	ambush_pools = list(
		/datum/ambush_config/bog_guard_deserters,
		/datum/ambush_config/mirespiders_ambush,
		/datum/ambush_config/mirespiders_crawlers,
		/datum/ambush_config/goblin_ambush_party,
	)

/datum/quest_map_config/desert
	map_file = "desert.dmm"
	map_name = "Desert"
	difficulty_modifier = QUEST_MAP_DIFFICULTY_DESERT
	reward_modifier = QUEST_MAP_REWARD_DESERT
	map_flag = QUEST_MAP_FLAG_DESERT
	ambush_pools = list(
		/datum/ambush_config/goblin_ambush_party,
		/datum/ambush_config/deserter_patrol,
		/datum/ambush_config/highwayman_gang,
	)

/datum/quest_map_config/frozen
	map_file = "frozen_mountains.dmm"
	map_name = "Frozen Mountains"
	difficulty_modifier = QUEST_MAP_DIFFICULTY_FROZEN
	reward_modifier = QUEST_MAP_REWARD_FROZEN
	map_flag = QUEST_MAP_FLAG_FROZEN
	ambush_pools = list(
		/datum/ambush_config/wolf_pack,
		/datum/ambush_config/troll_and_wolves,
		/datum/ambush_config/deserter_patrol,
	)

/datum/quest_map_config/underdark
	map_file = "underdark.dmm"
	map_name = "Underdark"
	difficulty_modifier = QUEST_MAP_DIFFICULTY_UNDERDARK
	reward_modifier = QUEST_MAP_REWARD_UNDERDARK
	map_flag = QUEST_MAP_FLAG_UNDERDARK
	ambush_pools = list(
		/datum/ambush_config/goblin_raid_party,
		/datum/ambush_config/mixed_wildlife,
	)

/// Global singleton cache of map configs keyed by lowercased map_file name.
GLOBAL_LIST_EMPTY(quest_map_configs)

/proc/get_quest_map_config(map_file)
	if(!map_file)
		return null

	var/key = LOWER_TEXT("[map_file]")

	if(!length(GLOB.quest_map_configs))
		initialize_quest_map_configs()

	return GLOB.quest_map_configs[key]

/proc/initialize_quest_map_configs()
	for(var/config_type in subtypesof(/datum/quest_map_config))
		var/datum/quest_map_config/config = new config_type
		if(!config.map_file)
			qdel(config)
			continue
		GLOB.quest_map_configs[LOWER_TEXT("[config.map_file]")] = config

/proc/get_quest_map_config_for_turf(turf/target_turf)
	if(!target_turf)
		return null
	var/map_file = SSmapping.level_trait(target_turf.z, ZTRAIT_MAP_FILE)
	if(!map_file)
		return null
	return get_quest_map_config(map_file)

/proc/get_quest_map_flag_for_turf(turf/target_turf)
	var/datum/quest_map_config/config = get_quest_map_config_for_turf(target_turf)
	if(!config)
		return QUEST_MAP_FLAG_ALL
	return config.map_flag
