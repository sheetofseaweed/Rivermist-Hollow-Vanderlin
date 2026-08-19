#define DEFAULT_TIME_SWIMMER 30 SECONDS

///subtree to go and swim!
/datum/ai_planning_subtree/go_for_swim

/datum/ai_planning_subtree/go_for_swim/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	if(controller.blackboard_key_exists(BB_SWIM_ALTERNATE_TURF))
		controller.queue_behavior(/datum/ai_behavior/travel_towards/swimming, BB_SWIM_ALTERNATE_TURF)
		return SUBTREE_RETURN_FINISH_PLANNING

	if(isnull(controller.blackboard[BB_KEY_SWIM_TIME]))
		var/initial_swim_time = controller.blackboard[BB_KEY_SWIMMER_COOLDOWN] || DEFAULT_TIME_SWIMMER
		controller.set_blackboard_key(BB_KEY_SWIM_TIME, world.time + initial_swim_time)

	var/mob/living/living_pawn = controller.pawn
	var/turf/our_turf = get_turf(living_pawn)

	// we have been taken out of water!
	controller.set_blackboard_key(BB_CURRENTLY_SWIMMING, istype(our_turf, /turf/open/water))

	if(controller.blackboard[BB_KEY_SWIM_TIME] < world.time)
		controller.queue_behavior(/datum/ai_behavior/find_and_set/swim_alternate, BB_SWIM_ALTERNATE_TURF, /turf/open)
		return SUBTREE_RETURN_FINISH_PLANNING

	// have some fun in the water
	if(controller.blackboard[BB_CURRENTLY_SWIMMING] && SPT_PROB(5, seconds_per_tick))
		controller.queue_behavior(/datum/ai_behavior/perform_emote, "splashes water all around!")

/datum/ai_behavior/travel_towards/swimming
	clear_target = TRUE

/datum/ai_behavior/travel_towards/swimming/finish_action(datum/ai_controller/controller, succeeded, target_key)
	. = ..()
	var/time_to_add = controller.blackboard[BB_KEY_SWIMMER_COOLDOWN] ? controller.blackboard[BB_KEY_SWIMMER_COOLDOWN] : DEFAULT_TIME_SWIMMER
	controller.set_blackboard_key(BB_KEY_SWIM_TIME, world.time + time_to_add)

#undef DEFAULT_TIME_SWIMMER
