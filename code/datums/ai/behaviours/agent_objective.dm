/**
 * Walk to whatever the agent asked for.
 *
 * CAN_PLAN_DURING_EXECUTION is not optional here. able_to_plan() refuses to
 * plan at all while any running behavior lacks it, so without the flag this
 * behavior would block the reflex subtrees sitting above it — the agent's own
 * objective would suppress the safety layer it is meant to yield to.
 */
/datum/ai_behavior/agent_approach
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_MOVE_AND_PERFORM | AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION
	required_distance = AGENT_REACH_DISTANCE
	/// Terminal state handed back to the agent when this finishes.
	var/outcome_detail = "approach"

/datum/ai_behavior/agent_approach/setup(datum/ai_controller/controller, target_key)
	. = ..()
	var/atom/target = controller.blackboard[target_key]
	if(QDELETED(target))
		return FALSE
	set_movement_target(controller, target)
	return TRUE

/datum/ai_behavior/agent_approach/perform(delta_time, datum/ai_controller/controller, target_key)
	. = ..()
	var/mob/living/living_pawn = controller.pawn
	var/atom/target = controller.blackboard[target_key]

	if(!isliving(living_pawn) || QDELETED(target))
		finish_action(controller, FALSE, target_key)
		return

	if(agent_objective_timed_out(controller))
		finish_action(controller, FALSE, target_key)
		return

	// The postcondition, checked rather than assumed.
	if(get_dist(living_pawn, target) <= AGENT_REACH_DISTANCE)
		finish_action(controller, TRUE, target_key)
		return

	set_movement_target(controller, target)

/datum/ai_behavior/agent_approach/finish_action(datum/ai_controller/controller, succeeded, target_key)
	. = ..()
	report_outcome(controller, succeeded)
	controller.clear_blackboard_key(target_key)

/**
 * Hand a real terminal state back, never a bare "dispatched".
 *
 * This is also where a reflex interruption gets reported. A reflex subtree
 * above us can return FINISH_PLANNING, in which case the agent subtree never
 * runs this plan and cannot report anything itself — but the planner then
 * finishes this behavior as unplanned, which lands here. One owner, one report.
 */
/datum/ai_behavior/agent_approach/proc/report_outcome(datum/ai_controller/controller, succeeded)
	var/datum/ai_controller/agent_social/agent = controller
	if(!istype(agent) || !agent.binding || QDELETED(agent.binding))
		return

	if(succeeded)
		agent.binding.finish_intent(AGENT_RESULT_SUCCEEDED, "arrived")
		return

	// Not a failure to reach if a reflex simply took the wheel.
	if(!agent.reflex_guard_clear())
		agent.binding.finish_intent(AGENT_RESULT_INTERRUPTED, "a reflex took over")
		return

	agent.binding.finish_intent(AGENT_RESULT_FAILED, "could not reach it")

/datum/ai_behavior/agent_approach/proc/agent_objective_timed_out(datum/ai_controller/controller)
	var/datum/ai_controller/agent_social/agent = controller
	if(!istype(agent) || !agent.binding || QDELETED(agent.binding))
		return FALSE
	return world.time > (agent.binding.intent_started_at + AGENT_OBJECTIVE_TIMEOUT)

/**
 * Walk to something, then click it once.
 *
 * The click goes through ai_interact, which is how the existing AI already
 * synthesises player input. Modifiers are deliberately empty so only the plain
 * click path is reachable.
 */
/datum/ai_behavior/agent_approach/use

/datum/ai_behavior/agent_approach/use/perform(delta_time, datum/ai_controller/controller, target_key)
	var/mob/living/living_pawn = controller.pawn
	var/atom/target = controller.blackboard[target_key]

	if(!isliving(living_pawn) || QDELETED(target))
		finish_action(controller, FALSE, target_key)
		return

	if(agent_objective_timed_out(controller))
		finish_action(controller, FALSE, target_key)
		return

	if(get_dist(living_pawn, target) > AGENT_REACH_DISTANCE)
		set_movement_target(controller, target)
		return

	if(!controller.ai_can_interact())
		finish_action(controller, FALSE, target_key)
		return

	controller.ai_interact(target = target, combat_mode = null, modifiers = list())
	finish_action(controller, TRUE, target_key)

/**
 * A click has no generic checkable postcondition.
 *
 * Reporting success here would be a lie: ClickOn returns silently on cooldown,
 * windup, obscuration, facing and incapacitation. Say it was dispatched and
 * leave it at that.
 */
/datum/ai_behavior/agent_approach/use/report_outcome(datum/ai_controller/controller, succeeded)
	var/datum/ai_controller/agent_social/agent = controller
	if(!istype(agent) || !agent.binding || QDELETED(agent.binding))
		return
	agent.binding.finish_intent(
		succeeded ? AGENT_RESULT_UNVERIFIED : AGENT_RESULT_FAILED,
		succeeded ? "click dispatched; no postcondition to verify" : "could not reach it",
	)
