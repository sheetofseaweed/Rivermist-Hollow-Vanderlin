/// One weighted, style-tagged mob option in a floor's combat pool.
/datum/dungeon_spawn_entry
	var/mob_type
	var/weight = 10
	var/style = DUNGEON_STYLE_MELEE
	var/min_tier = 1
	/// Per-entry nudge to enhancement odds (added to the floor's enhance_chance)
	var/enhance_bias = 0

/datum/dungeon_spawn_entry/New(mob_type, weight = 10, style = DUNGEON_STYLE_MELEE, min_tier = 1, enhance_bias = 0)
	src.mob_type = mob_type
	src.weight = weight
	src.style = style
	src.min_tier = min_tier
	src.enhance_bias = enhance_bias

/// Builds a weighted assoc list (entry -> weight) from a floor config's pool,
/// filtered by optional style and current tier.
/proc/get_floor_spawn_pool(datum/dungeon_floor_config/config, style_filter = null, tier = 1)
	var/list/pool = list()
	if(!config || !length(config.combat_mob_pool))
		return pool
	for(var/datum/dungeon_spawn_entry/entry as anything in config.combat_mob_pool)
		if(!ispath(entry.mob_type, /mob/living))
			continue
		if(style_filter && entry.style != style_filter)
			continue
		if(entry.min_tier > tier)
			continue
		pool[entry] = max(1, entry.weight)
	return pool

/// Weighted-picks a spawn entry, relaxing the style filter (then the tier gate)
/// before giving up, so a sparse pool still yields something.
/proc/pick_floor_spawn_entry(datum/dungeon_floor_config/config, style_filter = null, tier = 1)
	var/list/pool = get_floor_spawn_pool(config, style_filter, tier)
	if(!length(pool))
		pool = get_floor_spawn_pool(config, style_filter, 999)
	if(!length(pool))
		pool = get_floor_spawn_pool(config, null, tier)
	if(!length(pool))
		return null
	return pickweight(pool)
