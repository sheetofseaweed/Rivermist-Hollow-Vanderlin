//RMH EDITED START - zone cave generation
/**
 * Zone-scoped procedural terrain.
 *
 * A mapper paints an area subtype that carries a `map_generator` typepath.
 * After the map is loaded, SSterrain_generation walks every area that has one
 * and hands the generator that area's turfs, one z-level at a time.
 *
 * The generator never sees a turf outside the painted area, so generation
 * physically cannot leak into hand-built rooms next door.
 */
/datum/map_generator
	var/name = "Map Generator"

/**
 * Carve one contiguous batch of turfs.
 * `turfs` is a flat list of turfs from a single area on a single z-level.
 * Return TRUE if anything was actually generated.
 */
/datum/map_generator/proc/generate_terrain(list/turfs, area/target_area)
	return FALSE

/area
	/// Typepath of a map generator that carves this area at roundstart. Replaced by the instance once it runs.
	var/datum/map_generator/map_generator = null

/// Runs this area's map generator over every z-level the area occupies.
/area/proc/run_map_generation()
	if(!map_generator)
		return FALSE

	if(ispath(map_generator))
		map_generator = new map_generator()

	// Deliberately NOT turfs_by_zlevel: the map loader only fills that list when
	// loading into an already existing z-level (`if(!new_z)` in reader.dm). Every
	// area that came in with the main map load sits on a freshly created z-level,
	// so its turfs_by_zlevel is empty and only `contents` is populated.
	var/list/turfs_by_z = list()
	var/counted = 0
	for(var/turf/candidate in contents)
		LISTASSERTLEN(turfs_by_z, candidate.z, list())
		turfs_by_z[candidate.z] += candidate
		counted++
		if(!(counted % 400))
			CHECK_TICK

	if(!counted)
		log_world("RMH cavegen: [type] has a map_generator but no turfs, skipping")
		return FALSE

	var/generated = FALSE
	for(var/zlevel in 1 to length(turfs_by_z))
		var/list/zone_turfs = turfs_by_z[zlevel]
		if(!length(zone_turfs))
			continue
		if(map_generator.generate_terrain(zone_turfs, src))
			generated = TRUE
		else
			log_world("RMH cavegen: [type] on z[zlevel] had [length(zone_turfs)] turfs but generated nothing (region too small?)")
		CHECK_TICK

	return generated

/**
 * Debug entry point. Safe to call from VV on a live round to re-roll a zone,
 * but it will destroy anything standing on the old floor tiles, so only use it
 * on an empty test area.
 */
/area/proc/rmh_regenerate_caves()
	if(!map_generator)
		return FALSE
	if(!ispath(map_generator))
		var/datum/map_generator/old_generator = map_generator
		map_generator = old_generator.type
		qdel(old_generator)
	return run_map_generation()

/**
 * Entry point, called once from SSterrain_generation/Initialize().
 *
 * That subsystem already owns worldgen ordering (INIT_ORDER_TERRAIN: after
 * SSmapping has read the map, before SSatoms initializes anything) so painted
 * zones piggyback on it instead of adding another subsystem. DM will not let us
 * override Initialize() on the same type from a second file, so the call itself
 * lives in code/controllers/subsystem/voyage.dm behind an //RMH EDITED marker.
 */
/datum/controller/subsystem/terrain_generation/proc/run_area_map_generation()
	var/started_at = REALTIMEOFDAY
	var/found_areas = 0
	var/generated_areas = 0

	for(var/area/candidate as anything in GLOB.areas)
		if(!candidate.map_generator)
			continue
		found_areas++
		if(candidate.run_map_generation())
			generated_areas++
		CHECK_TICK

	log_world("RMH cavegen: [found_areas] zone(s) with a generator, [generated_areas] generated, [(REALTIMEOFDAY - started_at) / 10]s")
//RMH EDITED END
