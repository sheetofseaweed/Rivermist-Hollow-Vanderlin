/**
 * Clear a threat the pawn has finished running from.
 *
 * Sits directly above flee_target. run_away_from_target finishes successfully
 * once the pawn can no longer see its target, but it never clears the target.
 * Left alone that pins should_idle() awake forever and re-queues a flee every
 * plan, so the recovery rule has to live somewhere. Here is that somewhere.
 */
/datum/ai_planning_subtree/agent_flee_recovery

/datum/ai_planning_subtree/agent_flee_recovery/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	var/datum/ai_controller/agent_social/agent = controller
	if(!istype(agent))
		return

	var/atom/target = agent.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	if(isnull(target))
		return

	if(QDELETED(target))
		agent.clear_threat()
		return

	if(isliving(target))
		var/mob/living/living_target = target
		if(living_target.stat >= DEAD)
			agent.clear_threat()
			return

	// Still within the window this attack bought: keep running regardless.
	if(world.time <= agent.blackboard[BB_AGENT_FLEE_UNTIL])
		return

	if(!can_see(agent.pawn, target, AGENT_FLEE_SIGHT_RANGE))
		agent.clear_threat()

/**
 * The agent's own slot in the plan.
 *
 * Deliberately not first. Reflex subtrees above it own survival, and this one
 * only claims the pawn when no reflex is active. It also never blocks planning
 * when there is no intent, so an NPC with the sidecar down behaves like an
 * ordinary, if very passive, mob.
 */
/datum/ai_planning_subtree/agent_intent

/datum/ai_planning_subtree/agent_intent/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	var/datum/ai_controller/agent_social/agent = controller
	if(!istype(agent))
		return

	// A pawn can spawn before SSagent_npc initialises, so registration retries
	// here rather than only once at possession.
	agent.ensure_registered()

	var/datum/agent_binding/binding = agent.binding
	if(!binding || QDELETED(binding))
		return

	var/list/intent = binding.current_intent
	if(!intent)
		return

	var/atom/target = agent.blackboard[BB_AGENT_OBJECTIVE_TARGET]
	if(QDELETED(target))
		binding.finish_intent(AGENT_RESULT_FAILED, "the target is gone")
		return

	// An objective that never got moving still has to end, or it hangs forever
	// waiting for a guard that may never clear.
	if(world.time > (binding.intent_started_at + AGENT_OBJECTIVE_TIMEOUT))
		agent.cancel_agent_objective()
		binding.finish_intent(AGENT_RESULT_EXPIRED, "gave up before starting")
		return

	if(!agent.reflex_guard_clear())
		// Cancelling reports the interruption. With nothing running there is
		// nothing to cancel, so latch a single report instead.
		if(!agent.cancel_agent_objective())
			binding.suspend_intent("a reflex has the pawn")
		return

	binding.resume_intent()
	agent.queue_behavior(
		intent["name"] == "use" ? /datum/ai_behavior/agent_approach/use : /datum/ai_behavior/agent_approach,
		BB_AGENT_OBJECTIVE_TARGET,
	)
	return SUBTREE_RETURN_FINISH_PLANNING
