// Posts: where an NPC keeps to when it has nothing to do, like a merchant's stall or a guard's gate.

/// Give the NPC a post, or take it away with a null turf.
/datum/ai_controller/agent_social/proc/set_post(turf/where, facing = SOUTH)
	if(!isturf(where))
		clear_blackboard_key(BB_AGENT_POST)
		return
	set_blackboard_key(BB_AGENT_POST, where)
	set_blackboard_key(BB_AGENT_POST_DIR, facing)

/// The post is home, however far: the walk back must not be cancelled as out of range.
/datum/ai_controller/agent_social/is_hot_pursuit_target(atom/target)
	return (target && target == blackboard[BB_AGENT_POST]) || ..()

/// Too busy to go home: fighting, fleeing, on an errand, seated by choice, in a conversation, paid for, or chosen.
/datum/ai_controller/agent_social/proc/busy_away_from_post()
	var/mob/living/living_pawn = pawn
	if(in_combat() || blackboard[BB_BASIC_MOB_CURRENT_TARGET] || living_pawn.buckled)
		return TRUE
	if(binding && !QDELETED(binding) && (binding.current_intent || binding.current_partner()))
		return TRUE
	// A customer with paid time, or someone it said yes to, may take the NPC somewhere quieter.
	if(paying_customer() || has_live_consent())
		return TRUE
	return FALSE

/// Walk back to the post after idling away from it. Last in the plan, so anything else wins.
/datum/ai_planning_subtree/agent_return_to_post

/datum/ai_planning_subtree/agent_return_to_post/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	var/datum/ai_controller/agent_social/agent = controller
	if(!istype(agent))
		return
	var/turf/post = agent.blackboard[BB_AGENT_POST]
	if(!isturf(post))
		return
	if(get_turf(agent.pawn) == post)
		agent.clear_blackboard_key(BB_AGENT_POST_IDLE_SINCE)
		return
	// Lingering after an errand or a chat is natural, so the clock only starts once nothing holds the NPC.
	if(agent.busy_away_from_post())
		agent.clear_blackboard_key(BB_AGENT_POST_IDLE_SINCE)
		return
	if(world.time < agent.blackboard[BB_AGENT_POST_RETRY_AT])
		return
	var/idle_since = agent.blackboard[BB_AGENT_POST_IDLE_SINCE]
	if(!idle_since)
		agent.set_blackboard_key(BB_AGENT_POST_IDLE_SINCE, world.time)
		return
	if(world.time < idle_since + AGENT_POST_RETURN_DELAY)
		return
	agent.queue_behavior(/datum/ai_behavior/agent_return_to_post, BB_AGENT_POST)
	return SUBTREE_RETURN_FINISH_PLANNING

/// The walk home. Gives up after AGENT_POST_RETURN_TIMEOUT, and the subtree waits before trying again.
/datum/ai_behavior/agent_return_to_post
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_MOVE_AND_PERFORM | AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION
	required_distance = 0

/datum/ai_behavior/agent_return_to_post/setup(datum/ai_controller/controller, post_key)
	. = ..()
	var/turf/post = controller.blackboard[post_key]
	if(!isturf(post))
		return FALSE
	set_movement_target(controller, post)
	return TRUE

/datum/ai_behavior/agent_return_to_post/perform(delta_time, datum/ai_controller/controller, post_key)
	. = ..()
	var/turf/post = controller.blackboard[post_key]
	if(!isturf(post) || !isliving(controller.pawn))
		finish_action(controller, FALSE, post_key)
		return
	if(get_turf(controller.pawn) == post)
		finish_action(controller, TRUE, post_key)
		return
	var/idle_since = controller.blackboard[BB_AGENT_POST_IDLE_SINCE]
	if(!idle_since || world.time > idle_since + AGENT_POST_RETURN_DELAY + AGENT_POST_RETURN_TIMEOUT)
		finish_action(controller, FALSE, post_key)
		return
	set_movement_target(controller, post)

/datum/ai_behavior/agent_return_to_post/finish_action(datum/ai_controller/controller, succeeded, post_key)
	. = ..()
	controller.clear_blackboard_key(BB_AGENT_POST_IDLE_SINCE)
	if(!succeeded)
		controller.set_blackboard_key(BB_AGENT_POST_RETRY_AT, world.time + AGENT_POST_RETRY_DELAY)
		return
	var/mob/living/living_pawn = controller.pawn
	living_pawn.setDir(controller.blackboard[BB_AGENT_POST_DIR] || SOUTH)
