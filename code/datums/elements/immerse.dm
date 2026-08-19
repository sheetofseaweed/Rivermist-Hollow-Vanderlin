/// Gives movables a single, event-driven immersion state while they occupy an active water turf.
/datum/element/immerse
	element_flags = ELEMENT_DETACH | ELEMENT_BESPOKE
	id_arg_index = 2
	/// Depth represented by this element instance.
	var/water_height
	/// Whether this depth permits active swimming.
	var/allows_swimming
	/// Movables currently owned by this element instance.
	var/list/atom/movable/immersed_contents = list()

/datum/element/immerse/Destroy(force)
	immersed_contents = null
	return ..()

/datum/element/immerse/Attach(turf/target, water_height = WATER_HEIGHT_ANKLE, allows_swimming = FALSE)
	. = ..()
	if(!isturf(target))
		return ELEMENT_INCOMPATIBLE

	src.water_height = water_height
	src.allows_swimming = allows_swimming
	RegisterSignals(target, list(COMSIG_ATOM_ENTERED, COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZED_ON), PROC_REF(enter_water))
	RegisterSignal(target, COMSIG_TURF_EXITED, PROC_REF(exit_water))

	for(var/atom/movable/movable as anything in target.contents)
		if(!(movable.flags_1 & INITIALIZED_1))
			continue
		enter_water(target, movable)

/datum/element/immerse/Detach(turf/source)
	UnregisterSignal(source, list(COMSIG_ATOM_ENTERED, COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZED_ON, COMSIG_TURF_EXITED))
	for(var/atom/movable/movable as anything in source.contents)
		stop_tracking(movable, remove_traits = TRUE)
	return ..()

/datum/element/immerse/proc/enter_water(atom/source, atom/movable/entered)
	SIGNAL_HANDLER

	if(QDELETED(entered) || HAS_TRAIT(source, TRAIT_IMMERSE_STOPPED))
		return
	if(entered in immersed_contents)
		return

	immersed_contents |= entered
	RegisterSignal(entered, COMSIG_PARENT_QDELETING, PROC_REF(on_content_deleted))
	ADD_TRAIT(entered, TRAIT_IMMERSED, ELEMENT_TRAIT(/datum/element/immerse))
	if(allows_swimming)
		ADD_TRAIT(entered, TRAIT_MOVE_SWIMMING, ELEMENT_TRAIT(/datum/element/immerse))

/datum/element/immerse/proc/exit_water(atom/source, atom/movable/gone, atom/new_loc)
	SIGNAL_HANDLER

	var/turf/open/water/next_water = new_loc
	if(istype(next_water) && next_water.is_immersing())
		stop_tracking(gone, remove_traits = FALSE)
		if(!next_water.is_swimmable())
			REMOVE_TRAIT(gone, TRAIT_MOVE_SWIMMING, ELEMENT_TRAIT(/datum/element/immerse))
		return
	stop_tracking(gone, remove_traits = TRUE)

/datum/element/immerse/proc/on_content_deleted(atom/movable/source)
	SIGNAL_HANDLER
	stop_tracking(source, remove_traits = TRUE)

/datum/element/immerse/proc/stop_tracking(atom/movable/movable, remove_traits)
	if(movable in immersed_contents)
		UnregisterSignal(movable, COMSIG_PARENT_QDELETING)
		immersed_contents -= movable
	if(!remove_traits)
		return
	REMOVE_TRAIT(movable, TRAIT_MOVE_SWIMMING, ELEMENT_TRAIT(/datum/element/immerse))
	REMOVE_TRAIT(movable, TRAIT_IMMERSED, ELEMENT_TRAIT(/datum/element/immerse))
