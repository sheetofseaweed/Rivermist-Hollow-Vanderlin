/// Whether a hunger-driven subtree should stand down for now.
/// A ridden animal only breaks off for food once its meter is genuinely empty, so it can't wrench the
/// reins away from its rider over a passing snack. Loose animals forage as soon as they're peckish.
/datum/ai_planning_subtree/proc/too_fed_to_forage(datum/ai_controller/controller)
	if(!isliving(controller.pawn))
		return FALSE
	var/hunger = SEND_SIGNAL(controller.pawn, COMSIG_MOB_RETURN_HUNGER)
	if(controller.blackboard[BB_IS_BEING_RIDDEN])
		return hunger > 0
	return hunger >= 50

/// similar to finding a target but looks for food types in the // the what?
/datum/ai_planning_subtree/find_food
	var/vision_range = 9

/datum/ai_planning_subtree/find_food/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	. = ..()
	if(too_fed_to_forage(controller))
		return

	var/atom/target = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	if(!QDELETED(target))
		// Busy with something
		return

	var/list/food_targets = controller.blackboard[BB_BASIC_FOODS]
	if(!length(food_targets))
		return

	controller.queue_behavior(/datum/ai_behavior/find_and_set/in_list, BB_BASIC_MOB_CURRENT_TARGET, food_targets, vision_range)


/datum/ai_planning_subtree/find_dead_bodies
	var/vision_range = 9
	var/datum/ai_behavior/find_and_set/dead_bodies/behavior = /datum/ai_behavior/find_and_set/dead_bodies

/datum/ai_planning_subtree/find_dead_bodies/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	. = ..()
	if(too_fed_to_forage(controller))
		return

	var/atom/target = controller.blackboard[BB_BASIC_MOB_FOOD_TARGET]
	if(!QDELETED(target))
		// Busy with something
		return

	controller.queue_behavior(behavior, BB_BASIC_MOB_FOOD_TARGET, controller.blackboard[BB_BASIC_FOODS], vision_range)


/datum/ai_planning_subtree/find_dead_bodies/mole
	vision_range = 7

/datum/ai_planning_subtree/find_food/rat
	vision_range = 2

/datum/ai_planning_subtree/find_food/spider
	vision_range = 5

/datum/ai_planning_subtree/find_food/mole
	vision_range = 7

/datum/ai_planning_subtree/find_food/troll
	vision_range = 7

/datum/ai_planning_subtree/find_food/gator
	vision_range = 9


/datum/ai_planning_subtree/find_dead_bodies/bog_troll
	vision_range = 7
	behavior = /datum/ai_behavior/find_and_set/dead_bodies/bog_troll

/datum/ai_planning_subtree/find_dead_bodies/mimic
	vision_range = 2
	behavior = /datum/ai_behavior/find_and_set/dead_bodies/mimic

/datum/ai_planning_subtree/find_food/saiga/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	if(too_fed_to_forage(controller))
		return

	var/atom/target = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	if(!QDELETED(target))
		// Busy with something
		return

	var/list/food_targets = controller.blackboard[BB_BASIC_FOODS]
	if(!length(food_targets))
		return

	controller.queue_behavior(/datum/ai_behavior/find_and_set/in_list/saiga, BB_BASIC_MOB_CURRENT_TARGET, food_targets, vision_range)
