/**
 * One agent-controlled pawn.
 *
 * Owns the binding epoch and generation, the event buffer and the budget
 * counters. Two separate identities matter here:
 *
 * - epoch is allocated once by the subsystem and never reused, so a binding
 *   rebuilt for the same pawn cannot inherit the previous one's identity.
 * - generation is bumped by revoke(), invalidating replies already in flight.
 */
/datum/agent_binding
	/// Stable identity for this binding across its life. Sent on the wire.
	var/pawn_id
	/// Subsystem-allocated and never reused. Survives binding replacement.
	var/epoch = 0
	/// Weak so a binding never pins a mob alive.
	var/datum/weakref/pawn_ref
	/// Weak for the same reason. Phase 3 uses it to queue behaviors.
	var/datum/weakref/controller_ref
	/// Bumped by revoke(). Responses carrying an older value are discarded.
	var/generation = 1
	var/state = AGENT_BINDING_IDLE
	/// The request currently in flight, if any.
	var/datum/agent_request/pending
	/// Monotonic per binding. Guards against acting on a stale world view.
	var/observation_revision = 0
	/// The observation actually sent. Handles resolve against this and nothing else.
	var/datum/agent_observation/last_observation
	/// The objective being pursued, or null. Only approach and use set one.
	var/list/current_intent
	var/intent_started_at = 0
	/// Latch so a reflex interruption is reported once per intent, not per plan.
	var/intent_suspended = FALSE
	/// Pending events, oldest first. Bounded by AGENT_MAX_EVENTS_PER_PAWN.
	var/list/events
	/// Set by external events, and by continuation while budget remains.
	var/dirty = FALSE
	/// world.time this binding most recently became dirty. 0 while clean.
	/// Measures the wait a trigger sits through before a request is sent.
	var/dirty_since = 0
	/// world.time the observation now in play was built. Drives staleness.
	var/observation_built_at = 0
	/// Self-driven decisions left in this interaction. Refreshed by real events.
	var/continuation_budget = 0
	/// world.time at which the interaction lapses, budget or not.
	var/continuation_expires_at = 0
	/// Highest urgency currently buffered.
	var/pending_urgency = AGENT_EVENT_LOW
	/// world.time floor for the next request. Enforces pacing and backoff.
	var/next_request_at = 0
	/// Reset by any accepted response. Drives backoff and the retry ceiling.
	var/consecutive_failures = 0
	/// Set when the pawn is deleted. The subsystem sweeps these each fire.
	var/pawn_gone = FALSE
	/// Reserved before sending, settled on receipt. Drift means bad accounting.
	var/tokens_reserved = 0
	var/tokens_settled = 0
	var/requests_made = 0
	/// Responses that arrived and were rejected. A timeout is not one of these.
	var/requests_refused = 0
	/// Requests that never came back. Counted apart, or a pawn losing every
	/// request reads as "refused 0" and looks healthy.
	var/requests_expired = 0

/datum/agent_binding/New(mob/living/new_pawn, datum/ai_controller/new_controller)
	. = ..()
	pawn_ref = WEAKREF(new_pawn)
	controller_ref = WEAKREF(new_controller)
	pawn_id = "[REF(new_pawn)]"
	events = list()
	if(new_pawn)
		RegisterSignal(new_pawn, COMSIG_PARENT_QDELETING, PROC_REF(on_pawn_deleted))

/datum/agent_binding/Destroy(force, ...)
	var/mob/living/pawn = resolve_pawn()
	if(pawn)
		UnregisterSignal(pawn, COMSIG_PARENT_QDELETING)
	revoke("binding destroyed")
	QDEL_NULL(last_observation)
	pawn_ref = null
	controller_ref = null
	events = null
	return ..()

/// Replace the observation the agent is answering about.
/datum/agent_binding/proc/set_observation(datum/agent_observation/new_observation)
	QDEL_NULL(last_observation)
	last_observation = new_observation
	observation_built_at = world.time

/**
 * Mark work pending, stamping the wait clock on the clean -> dirty edge only.
 *
 * Re-stamping on every event would measure the newest trigger. What matters is
 * how long the oldest unserved one has been waiting, so the first stamp stands.
 */
/datum/agent_binding/proc/set_dirty()
	if(!dirty)
		dirty_since = world.time
	dirty = TRUE

/datum/agent_binding/proc/clear_dirty()
	dirty = FALSE
	dirty_since = 0

/// How long the pending trigger has waited, in deciseconds.
/datum/agent_binding/proc/queued_time()
	return dirty_since ? max(0, world.time - dirty_since) : 0

/// How stale the observation in play is, in deciseconds.
/datum/agent_binding/proc/observation_age()
	return observation_built_at ? max(0, world.time - observation_built_at) : 0

/// Resolve a handle the model returned, against the observation it was shown.
/datum/agent_binding/proc/resolve_handle(handle)
	RETURN_TYPE(/atom)
	return last_observation?.resolve(handle)

/// The character brief, or null if this pawn has no profile.
/datum/agent_binding/proc/profile_payload()
	var/datum/ai_controller/agent_social/agent = resolve_controller()
	if(!istype(agent) || !agent.profile)
		return null
	return agent.profile.to_payload()

/// A profile narrows the global action vocabulary. No profile, no objectives.
/datum/agent_binding/proc/profile_permits(action_name)
	var/datum/ai_controller/agent_social/agent = resolve_controller()
	if(!istype(agent) || !agent.profile)
		return FALSE
	return agent.profile.permits(action_name)

/// Flag only. Tearing a binding down inside another datum's Destroy is asking
/// for trouble, so the subsystem sweeps flagged bindings on its next fire.
/datum/agent_binding/proc/on_pawn_deleted(datum/source)
	SIGNAL_HANDLER
	pawn_gone = TRUE
	revoke("pawn deleted")

/datum/agent_binding/proc/resolve_pawn()
	RETURN_TYPE(/mob/living)
	var/mob/living/resolved = pawn_ref?.resolve()
	return QDELETED(resolved) ? null : resolved

/datum/agent_binding/proc/resolve_controller()
	RETURN_TYPE(/datum/ai_controller)
	var/datum/ai_controller/resolved = controller_ref?.resolve()
	return QDELETED(resolved) ? null : resolved

/**
 * Is this binding still entitled to act on its pawn?
 *
 * Checked at consumption as well as at start, because the world moves while a
 * request is in flight. Both directions of the pawn/controller link are checked:
 * a controller can be repossessed onto a different mob.
 */
/datum/agent_binding/proc/still_owns_pawn()
	if(pawn_gone)
		return FALSE
	var/mob/living/pawn = resolve_pawn()
	if(!pawn)
		return FALSE
	var/datum/ai_controller/controller = resolve_controller()
	if(!controller)
		return FALSE
	if(controller.pawn != pawn || pawn.ai_controller != controller)
		return FALSE
	// A player took the wheel. The agent does not share control.
	if(pawn.client)
		return FALSE
	return TRUE

/// Revoke this binding. Every outstanding response becomes invalid immediately.
/datum/agent_binding/proc/revoke(reason)
	generation++
	state = AGENT_BINDING_DISABLED
	abandon_pending(reason)
	current_intent = null
	intent_suspended = FALSE
	// A revoked binding must not keep driving itself.
	end_continuation()
	LAZYCLEARLIST(events)
	clear_dirty()
	pending_urgency = AGENT_EVENT_LOW

/// Re-enable after a revoke. The new generation means old replies stay dead.
/datum/agent_binding/proc/reinstate()
	if(state != AGENT_BINDING_DISABLED)
		return FALSE
	if(pawn_gone)
		return FALSE
	generation++
	state = AGENT_BINDING_IDLE
	// An operator turning agents back on means a fresh start, so the breaker
	// closes too. Otherwise re-enabling leaves a broken pawn still waiting.
	consecutive_failures = 0
	next_request_at = 0
	return TRUE

/// Drop the in-flight request. The transport is drained, never simply dropped.
/datum/agent_binding/proc/abandon_pending(reason)
	if(!pending)
		return
	// One close, both ledgers, exactly once. Releasing only the binding's side
	// left the global reservation held forever, which eventually starved
	// admission while nothing was actually in flight.
	//
	// Marked unsettled: the hold is released so admission recovers, but the
	// provider may still bill work we walked away from, so the cost is recorded
	// as unknown rather than assumed to be zero.
	//
	// Logged for the same reason expire_pass logs: past this point the sidecar's
	// answer is drained unread, so the loss is otherwise invisible from DM.
	SSagent_npc?.log_agent("abandoned the in-flight request for [pawn_id]: [reason]")
	SSagent_npc?.close_reservation(src, pending, 0, unsettled = TRUE)
	SSagent_npc?.drain_transport(pending.release_transport())
	QDEL_NULL(pending)
	if(state == AGENT_BINDING_PENDING)
		state = AGENT_BINDING_IDLE

/// Take on a new objective. Replaces any previous one.
/datum/agent_binding/proc/begin_intent(list/action)
	current_intent = action
	intent_started_at = world.time
	intent_suspended = FALSE

/// End the objective with a real terminal state, not a bare "dispatched".
/datum/agent_binding/proc/finish_intent(state_name, detail)
	if(!current_intent)
		return FALSE
	current_intent = null
	intent_suspended = FALSE
	// An objective finishes long after its observation was built, so this is the
	// point where staleness at execution is real rather than theoretical.
	SSagent_npc?.note_observation_age(observation_age())
	// A finished objective is a completed step, so it may continue the chain.
	complete_action(state_name, detail)
	return TRUE

/**
 * A reflex took the pawn away from its objective.
 *
 * Reported once per intent rather than once per plan, otherwise a long flee
 * would bury the agent in identical interruption events.
 */
/datum/agent_binding/proc/suspend_intent(reason)
	if(intent_suspended || !current_intent)
		return FALSE
	intent_suspended = TRUE
	record_result(AGENT_RESULT_INTERRUPTED, reason)
	return TRUE

/datum/agent_binding/proc/resume_intent()
	intent_suspended = FALSE

/// Start or refresh a bounded interaction.
/datum/agent_binding/proc/begin_interaction()
	continuation_budget = AGENT_CONTINUATION_BUDGET
	continuation_expires_at = world.time + AGENT_CONTINUATION_WINDOW

/// Stop self-driven work. Buffered events are left alone on purpose: settling
/// down must not erase something a player said while the NPC was busy.
/datum/agent_binding/proc/end_continuation()
	// Measure a chain that actually ran. One that never took a step is not a
	// chain, and recording zeroes for it would flatten the average into noise.
	if(continuation_expires_at && continuation_budget < AGENT_CONTINUATION_BUDGET)
		SSagent_npc?.note_chain_depth(AGENT_CONTINUATION_BUDGET - continuation_budget)
	continuation_budget = 0
	continuation_expires_at = 0

/**
 * Finish an action, and decide whether to keep going.
 *
 * A completed step schedules the next decision while budget remains, which is
 * what lets "fetch the salt" run to completion unaided. `wait` ends the chain,
 * so an NPC with nothing to do settles instead of spinning.
 */
/datum/agent_binding/proc/complete_action(state_name, detail, was_wait = FALSE)
	if(!record_result(state_name, detail))
		return FALSE

	if(was_wait)
		end_continuation()
		return FALSE
	if(continuation_budget <= 0 || world.time > continuation_expires_at)
		end_continuation()
		return FALSE

	continuation_budget--
	set_dirty()
	return TRUE

/// Append to the event ring without scheduling anything.
/datum/agent_binding/proc/push_event(event_name, urgency = AGENT_EVENT_LOW, list/detail)
	LAZYINITLIST(events)
	events += list(list("event" = event_name, "urgency" = urgency, "at" = world.time, "detail" = detail))
	trim_events()

/**
 * Record an outcome for the model to see next time it is asked.
 *
 * Deliberately does NOT mark the binding dirty. A result that schedules its own
 * follow-up request is a loop: every reply produces a result, every result
 * produces a reply, and nothing external ever has to happen.
 */
/datum/agent_binding/proc/record_result(state_name, detail)
	if(state == AGENT_BINDING_DISABLED)
		return FALSE
	push_event("action_result", AGENT_EVENT_LOW, list("state" = state_name, "detail" = detail))
	// The single funnel every terminal state passes through, so the outcome mix
	// is counted here rather than at each of the five call sites.
	SSagent_npc?.note_result(state_name)
	return TRUE

/**
 * Record an external event. High urgency abandons an in-flight request.
 *
 * replenish refreshes the continuation budget. Speech from another agent NPC
 * passes FALSE: two agents refreshing each other's budget is an unbounded
 * conversation that no per-turn cap can stop.
 */
/datum/agent_binding/proc/mark_dirty(event_name, urgency = AGENT_EVENT_LOW, list/detail, replenish = TRUE)
	if(state == AGENT_BINDING_DISABLED)
		return FALSE

	push_event(event_name, urgency, detail)
	set_dirty()
	pending_urgency = max(pending_urgency, urgency)
	if(replenish)
		begin_interaction()

	if(urgency >= AGENT_EVENT_HIGH && state == AGENT_BINDING_PENDING)
		abandon_pending("superseded by [event_name]")
	return TRUE

/// Bound the ring. Drop oldest low-urgency first so interruptions survive.
/datum/agent_binding/proc/trim_events()
	while(length(events) > AGENT_MAX_EVENTS_PER_PAWN)
		var/dropped = FALSE
		for(var/i in 1 to length(events))
			var/list/entry = events[i]
			if(entry["urgency"] < AGENT_EVENT_HIGH)
				events.Cut(i, i + 1)
				dropped = TRUE
				break
		if(!dropped)
			events.Cut(1, 2)

/// Snapshot and clear the buffer for sending.
/datum/agent_binding/proc/take_events()
	var/list/taken = events?.Copy() || list()
	LAZYCLEARLIST(events)
	clear_dirty()
	pending_urgency = AGENT_EVENT_LOW
	return taken

/// Put the events back after a failed submission, so a trigger is not lost.
/datum/agent_binding/proc/restore_events(list/taken)
	if(!length(taken))
		return
	for(var/list/entry as anything in taken)
		push_event(entry["event"], entry["urgency"], entry["detail"])

/**
 * May this binding send now?
 *
 * There is deliberately no permanent failure block here. The failure limit is
 * enforced as a long wait on next_request_at instead, so a pawn past the limit
 * still gets a probe. A hard block could never lift: no request could start,
 * so none could succeed, so the failure count never fell.
 */
/datum/agent_binding/proc/can_start_request()
	if(state != AGENT_BINDING_IDLE || !dirty || pawn_gone)
		return FALSE
	if(world.time < next_request_at)
		return FALSE
	return TRUE

/// Is the next request a lone probe against a provider we have given up on?
/datum/agent_binding/proc/is_probe()
	return consecutive_failures >= AGENT_MAX_CONSECUTIVE_FAILURES

/// How long a broken binding waits before its next probe. Grows, then caps.
/datum/agent_binding/proc/breaker_cooldown()
	var/steps = max(0, consecutive_failures - AGENT_MAX_CONSECUTIVE_FAILURES)
	return min(AGENT_BREAKER_COOLDOWN * (steps + 1), AGENT_BREAKER_COOLDOWN_MAX)

/**
 * Called after a transport-level failure.
 *
 * Under the limit this is ordinary backoff. At or past it the breaker opens: one
 * probe per cooldown rather than silence. The events stay buffered and the
 * binding stays dirty, so the probe carries the trigger we failed to answer.
 */
/datum/agent_binding/proc/note_failure(list/unsent_events)
	consecutive_failures++
	restore_events(unsent_events)
	if(is_probe())
		next_request_at = world.time + breaker_cooldown()
		set_dirty()
		return FALSE
	next_request_at = world.time + (AGENT_FAILURE_BACKOFF * consecutive_failures)
	set_dirty()
	return TRUE

/// A reply of any kind closes the breaker. This is the only path that does.
/datum/agent_binding/proc/note_success()
	consecutive_failures = 0

/datum/agent_binding/proc/reserve_tokens(amount)
	tokens_reserved += amount

/// Release a reservation without recording spend. Used when work is abandoned.
/datum/agent_binding/proc/release_reservation(reserved)
	tokens_reserved = max(0, tokens_reserved - reserved)

/// Settle a reservation against what was actually spent.
/datum/agent_binding/proc/settle_tokens(reserved, actual)
	release_reservation(reserved)
	tokens_settled += actual
