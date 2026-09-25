#define MAX_SPARKLE_EMITTERS_PER_TURF 4

GLOBAL_VAR_INIT(sparkle_turf_cache_time, -1)
GLOBAL_LIST_EMPTY(sparkle_turf_cache)

/datum/component/particle_spewer/sparkle/process()
	var/atom/movable/sparkling = source_object
	if(!isturf(sparkling?.loc))
		return
	if(!(sparkling in get_allowed_sparklers(sparkling.loc)))
		count = 0
		return
	return ..()

/datum/component/particle_spewer/sparkle/proc/get_allowed_sparklers(turf/sparkle_turf)
	if(GLOB.sparkle_turf_cache_time != world.time)
		GLOB.sparkle_turf_cache_time = world.time
		GLOB.sparkle_turf_cache.Cut()
	var/list/allowed = GLOB.sparkle_turf_cache[sparkle_turf]
	if(allowed)
		return allowed
	allowed = list()
	for(var/obj/item/candidate in sparkle_turf)
		if(!LAZYACCESS(candidate._datum_components, /datum/component/particle_spewer/sparkle))
			continue
		allowed += candidate
		if(length(allowed) >= MAX_SPARKLE_EMITTERS_PER_TURF)
			break
	GLOB.sparkle_turf_cache[sparkle_turf] = allowed
	return allowed

#undef MAX_SPARKLE_EMITTERS_PER_TURF
