/datum/wave_defense_coordinator
	/// Ordered turfs the wave attacks and occupies in sequence.
	var/list/turf/wave_points = list()
	var/current_point_index = 1
	/// AI controllers currently assigned to this wave.
	var/list/datum/ai_controller/participants = list()
	/// Original controller movement settings restored when the wave ends.
	var/list/original_movement_types = list()
	var/list/original_max_target_distances = list()
	/// How long the wave must occupy each point before advancing.
	var/occupy_duration = 3 MINUTES
	var/occupy_started_at = 0
	var/wave_state = WAVE_ADVANCING
	var/datum/callback/on_complete
	var/datum/callback/on_failed

/datum/wave_defense_coordinator/New(set_id, list/mob/living/wave_mobs, occupy_duration = 3 MINUTES, datum/callback/on_complete, datum/callback/on_failed)
	src.occupy_duration = max(occupy_duration, 1 SECONDS)
	src.on_complete = on_complete
	src.on_failed = on_failed
	wave_points = get_wave_defense_points(set_id)

	if(!length(wave_points))
		stack_trace("wave_defense_coordinator: no waypoints found for set_id [set_id].")
		fail_wave()
		return

	for(var/mob/living/wave_mob as anything in wave_mobs)
		if(!wave_mob?.ai_controller)
			stack_trace("wave_defense_coordinator: [wave_mob] has no ai_controller, skipping.")
			continue
		register_participant(wave_mob.ai_controller)

	if(!length(participants))
		fail_wave()

/datum/wave_defense_coordinator/Destroy(force, ...)
	if(wave_state != WAVE_COMPLETE && wave_state != WAVE_FAILED)
		wave_state = WAVE_FAILED
	for(var/datum/ai_controller/controller as anything in participants.Copy())
		unregister_participant(controller, restore_controller = !QDELETED(controller))
	wave_points = null
	participants = null
	original_movement_types = null
	original_max_target_distances = null
	on_complete = null
	on_failed = null
	return ..()

/datum/wave_defense_coordinator/proc/get_current_point()
	if(current_point_index < 1 || current_point_index > length(wave_points))
		return null
	return wave_points[current_point_index]

/datum/wave_defense_coordinator/proc/register_participant(datum/ai_controller/controller)
	if(!controller?.pawn || QDELETED(controller) || controller.blackboard_key_exists(BB_WAVE_COORDINATOR))
		return FALSE

	participants |= controller
	original_movement_types[controller] = controller.ai_movement?.type
	original_max_target_distances[controller] = controller.max_target_distance

	controller.CancelActions()
	controller.change_ai_movement_type(/datum/ai_movement/hybrid_pathing/wave_defense)
	controller.max_target_distance = max(controller.max_target_distance, WAVE_DEFENSE_MAX_TRAVEL_DISTANCE)
	controller.set_blackboard_key(BB_WAVE_COORDINATOR, src)
	controller.add_subtree_at(/datum/ai_planning_subtree/wave_defense, 1)
	controller.recalculate_idle()

	RegisterSignal(controller, COMSIG_PARENT_QDELETING, PROC_REF(on_controller_removed))
	RegisterSignal(controller.pawn, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING), PROC_REF(on_pawn_removed))
	return TRUE

/datum/wave_defense_coordinator/proc/unregister_participant(datum/ai_controller/controller, restore_controller = TRUE)
	if(!(controller in participants))
		return
	participants -= controller

	UnregisterSignal(controller, COMSIG_PARENT_QDELETING)
	if(controller.pawn)
		UnregisterSignal(controller.pawn, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))

	if(restore_controller)
		controller.CancelActions()
		if(controller.blackboard[BB_WAVE_COORDINATOR] == src)
			controller.clear_blackboard_key(BB_WAVE_COORDINATOR)
		controller.clear_blackboard_key(BB_WAVE_TARGET_POINT)
		controller.clear_blackboard_key(BB_WAVE_ATTACK_TARGET)
		controller.remove_subtree(/datum/ai_planning_subtree/wave_defense)

		var/original_movement_type = original_movement_types[controller]
		if(original_movement_type && istype(controller.ai_movement, /datum/ai_movement/hybrid_pathing/wave_defense))
			controller.change_ai_movement_type(original_movement_type)
		if(controller.max_target_distance == max(original_max_target_distances[controller], WAVE_DEFENSE_MAX_TRAVEL_DISTANCE))
			controller.max_target_distance = original_max_target_distances[controller]
		controller.recalculate_idle()

	original_movement_types -= controller
	original_max_target_distances -= controller

	if(wave_state != WAVE_COMPLETE && wave_state != WAVE_FAILED && !length(participants))
		fail_wave()

/datum/wave_defense_coordinator/proc/on_controller_removed(datum/ai_controller/source)
	SIGNAL_HANDLER
	unregister_participant(source, restore_controller = FALSE)

/datum/wave_defense_coordinator/proc/on_pawn_removed(mob/living/source)
	SIGNAL_HANDLER
	var/datum/ai_controller/controller = source.ai_controller
	if(!controller || !(controller in participants))
		for(var/datum/ai_controller/participant as anything in participants)
			if(participant.pawn == source)
				controller = participant
				break
	if(controller)
		unregister_participant(controller, restore_controller = !QDELETED(controller))

/datum/wave_defense_coordinator/proc/fail_wave()
	if(wave_state == WAVE_COMPLETE || wave_state == WAVE_FAILED)
		return
	wave_state = WAVE_FAILED
	on_failed?.Invoke(src)
	qdel(src)

/datum/wave_defense_coordinator/proc/advance_point()
	if(current_point_index >= length(wave_points))
		wave_state = WAVE_COMPLETE
		on_complete?.Invoke(src)
		qdel(src)
		return FALSE
	current_point_index++
	wave_state = WAVE_ADVANCING
	return TRUE

/datum/wave_defense_coordinator/proc/check_occupy_progress()
	if(wave_state == WAVE_OCCUPYING && world.time >= occupy_started_at + occupy_duration)
		advance_point()

/datum/wave_defense_coordinator/proc/begin_occupying()
	if(wave_state != WAVE_ADVANCING)
		return
	wave_state = WAVE_OCCUPYING
	occupy_started_at = world.time
	addtimer(CALLBACK(src, PROC_REF(occupy_timeout_check)), occupy_duration + 1 SECONDS, TIMER_DELETE_ME)

/datum/wave_defense_coordinator/proc/occupy_timeout_check()
	if(wave_state == WAVE_OCCUPYING && world.time >= occupy_started_at + occupy_duration)
		advance_point()
