/datum/ai_planning_subtree/wave_defense
	operational_datums = list(
		/datum/ai_behavior/wave_attack_point,
		/datum/ai_behavior/wave_attack_target,
		/datum/ai_behavior/wave_occupy_point,
	)

/datum/ai_planning_subtree/wave_defense/SelectBehaviors(datum/ai_controller/controller, delta_time)
	var/datum/wave_defense_coordinator/coordinator = controller.blackboard[BB_WAVE_COORDINATOR]
	if(!coordinator || coordinator.wave_state == WAVE_FAILED || coordinator.wave_state == WAVE_COMPLETE)
		return

	var/atom/wave_attack_target = controller.blackboard[BB_WAVE_ATTACK_TARGET]
	if(wave_attack_target && !QDELETED(wave_attack_target))
		controller.queue_behavior(/datum/ai_behavior/wave_attack_target, BB_WAVE_ATTACK_TARGET)
		return SUBTREE_RETURN_FINISH_PLANNING
	if(wave_attack_target)
		controller.clear_blackboard_key(BB_WAVE_ATTACK_TARGET)

	// Let the participant's native combat subtrees handle ordinary enemies.
	if(controller.blackboard_key_exists(BB_HIGHEST_THREAT_MOB) || controller.blackboard_key_exists(BB_BASIC_MOB_CURRENT_TARGET))
		return

	var/atom/target_point = coordinator.get_current_point()
	if(!target_point)
		return

	controller.set_blackboard_key(BB_WAVE_TARGET_POINT, target_point)
	switch(coordinator.wave_state)
		if(WAVE_ADVANCING)
			controller.queue_behavior(/datum/ai_behavior/wave_attack_point, BB_WAVE_TARGET_POINT)
		if(WAVE_OCCUPYING)
			controller.queue_behavior(/datum/ai_behavior/wave_occupy_point, BB_WAVE_TARGET_POINT)

	return SUBTREE_RETURN_FINISH_PLANNING
