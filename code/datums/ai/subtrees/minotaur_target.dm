/// Minotaur targeting subtree — finds aggro targets only.
/// Rage buildup and phase transitions are handled in minotaur_enrage subtree.
/datum/ai_planning_subtree/minotaur_targeting
/datum/ai_planning_subtree/minotaur_targeting/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	if(!controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET])
		controller.queue_behavior(/datum/ai_behavior/find_aggro_targets, BB_BASIC_MOB_CURRENT_TARGET, BB_TARGETTING_DATUM)
		return
