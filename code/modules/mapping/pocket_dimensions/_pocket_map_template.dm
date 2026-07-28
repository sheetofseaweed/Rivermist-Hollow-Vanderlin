/datum/map_template/pocket
	name = "_pocket_base"
	id = "_pocket_base"
	keep_cached_map = TRUE
	var/padding = 1
	var/lifecycle_policy = POCKET_LIFECYCLE_KEEP_LOADED
	var/idle_timeout = POCKET_DEFAULT_IDLE_TIMEOUT
	var/persistence_mode = POCKET_PERSISTENCE_NONE
	var/instance_type = /datum/pocket_dimension
	var/exit_structure_type = /obj/structure/pocket_dimension_exit

/proc/is_valid_pocket_lifecycle_policy(policy)
	return policy == POCKET_LIFECYCLE_KEEP_LOADED || policy == POCKET_LIFECYCLE_HIBERNATE || policy == POCKET_LIFECYCLE_COLLAPSE

/proc/format_pocket_lifecycle_policy(policy)
	switch(policy)
		if(POCKET_LIFECYCLE_KEEP_LOADED)
			return "keep loaded"
		if(POCKET_LIFECYCLE_HIBERNATE)
			return "hibernate"
		if(POCKET_LIFECYCLE_COLLAPSE)
			return "collapse"
	return "unknown"

/proc/is_valid_pocket_persistence_mode(mode)
	return mode == POCKET_PERSISTENCE_NONE || mode == POCKET_PERSISTENCE_MOVABLES

/proc/format_pocket_persistence_mode(mode)
	switch(mode)
		if(POCKET_PERSISTENCE_NONE)
			return "none"
		if(POCKET_PERSISTENCE_MOVABLES)
			return "movables"
	return "unknown"
