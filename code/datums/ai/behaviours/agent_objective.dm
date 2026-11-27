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

	// Snapshot enough to tell whether a pickup actually happened. Deliberately
	// narrow: this verifies one specific outcome, it is not a general
	// click-succeeded detector, and anything else stays unverified.
	var/was_carried = isitem(target) && (target.loc == living_pawn)

	controller.ai_interact(target = target, combat_mode = null, modifiers = list())

	// On the blackboard, not on src: ai_behavior instances are singletons shared
	// by every pawn, so a var here would leak one NPC's result into another's.
	controller.set_blackboard_key(BB_AGENT_PICKED_UP,
		isitem(target) && !was_carried && (target.loc == living_pawn))
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
	if(!succeeded)
		agent.binding.finish_intent(AGENT_RESULT_FAILED, "could not reach it")
		return

	// A pickup has a checkable outcome, so say so honestly. Everything else is
	// dispatched-and-unknown: ClickOn returns silently on cooldown, windup,
	// obscuration, facing and incapacitation.
	var/picked_up = agent.blackboard[BB_AGENT_PICKED_UP]
	agent.clear_blackboard_key(BB_AGENT_PICKED_UP)
	if(picked_up)
		agent.binding.finish_intent(AGENT_RESULT_SUCCEEDED, "picked it up")
		return

	agent.binding.finish_intent(AGENT_RESULT_UNVERIFIED, "click dispatched; no postcondition to verify")

/// Walk to something, then do one thing to it without clicking. Subtypes say what, in act_on().
/datum/ai_behavior/agent_approach/act

/datum/ai_behavior/agent_approach/act/perform(delta_time, datum/ai_controller/controller, target_key)
	var/mob/living/living_pawn = controller.pawn
	var/atom/target = controller.blackboard[target_key]

	if(!isliving(living_pawn) || QDELETED(target))
		finish_action(controller, FALSE, target_key)
		return

	if(agent_objective_timed_out(controller))
		finish_action(controller, FALSE, target_key)
		return

	// Distance, like use: a table between us is the executor's failure to report, not a reason to walk forever.
	if(get_dist(living_pawn, target) > AGENT_REACH_DISTANCE)
		set_movement_target(controller, target)
		return

	controller.set_blackboard_key(BB_AGENT_ACTION_RESULT, act_on(controller, living_pawn, target))
	finish_action(controller, TRUE, target_key)

/// Do the thing, once, beside the target. Returns an agent_result list.
/datum/ai_behavior/agent_approach/act/proc/act_on(datum/ai_controller/controller, mob/living/pawn, atom/target)
	return agent_result(AGENT_RESULT_REJECTED, "nothing to do")

/datum/ai_behavior/agent_approach/act/report_outcome(datum/ai_controller/controller, succeeded)
	var/datum/ai_controller/agent_social/agent = controller
	if(!istype(agent) || !agent.binding || QDELETED(agent.binding))
		return
	var/list/outcome = agent.blackboard[BB_AGENT_ACTION_RESULT]
	agent.clear_blackboard_key(BB_AGENT_ACTION_RESULT)
	// Never got there: the parent tells a reflex interruption from a failure to reach.
	if(!succeeded || !islist(outcome))
		return ..()
	agent.binding.finish_intent(outcome["state"], outcome["detail"])

/// Touch someone gently. Never a click: whatever is in hand, it stays a touch.
/datum/ai_behavior/agent_approach/act/touch

/datum/ai_behavior/agent_approach/act/touch/act_on(datum/ai_controller/controller, mob/living/pawn, atom/target)
	var/datum/ai_controller/agent_social/agent = controller
	var/list/intent = istype(agent) ? agent.binding?.current_intent : null
	return agent_execute_touch(pawn, target, intent ? intent["key"] : AGENT_TOUCH_TAP)

/// Sit on a chair, stool, bench or bed.
/datum/ai_behavior/agent_approach/act/sit

/datum/ai_behavior/agent_approach/act/sit/act_on(datum/ai_controller/controller, mob/living/pawn, atom/target)
	return agent_execute_sit(controller, pawn, target)

/// Hold the chosen item out to someone, then watch whether they take it.
/datum/ai_behavior/agent_approach/act/give

/datum/ai_behavior/agent_approach/act/give/act_on(datum/ai_controller/controller, mob/living/pawn, atom/target)
	var/obj/item/item = controller.blackboard[BB_AGENT_GIVE_ITEM]
	controller.clear_blackboard_key(BB_AGENT_GIVE_ITEM)
	. = agent_execute_give(pawn, target, item)
	var/datum/ai_controller/agent_social/agent = controller
	var/list/outcome = .
	if(istype(agent) && outcome["state"] == AGENT_RESULT_SUCCEEDED)
		agent.watch_offer(item)
