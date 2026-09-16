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
	/// Set by external events only. Results never set it, or NPCs loop forever.
	var/dirty = FALSE
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
	var/requests_refused = 0

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
	LAZYCLEARLIST(events)
	dirty = FALSE
	pending_urgency = AGENT_EVENT_LOW

/// Re-enable after a revoke. The new generation means old replies stay dead.
/datum/agent_binding/proc/reinstate()
	if(state != AGENT_BINDING_DISABLED)
		return FALSE
	if(pawn_gone)
		return FALSE
	generation++
	state = AGENT_BINDING_IDLE
	return TRUE

/// Drop the in-flight request. The transport is drained, never simply dropped.
/datum/agent_binding/proc/abandon_pending(reason)
	if(!pending)
		return
	// Release the budget reservation; the provider may still bill it, so this is
	// optimistic. Conservative settlement is a phase 5 problem with a real bill.
	release_reservation(pending.tokens_reserved)
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
	record_result(state_name, detail)
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
	return TRUE

/// Record an external event. High urgency abandons an in-flight request.
/datum/agent_binding/proc/mark_dirty(event_name, urgency = AGENT_EVENT_LOW, list/detail)
	if(state == AGENT_BINDING_DISABLED)
		return FALSE

	push_event(event_name, urgency, detail)
	dirty = TRUE
	pending_urgency = max(pending_urgency, urgency)

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
	dirty = FALSE
	pending_urgency = AGENT_EVENT_LOW
	return taken

/// Put the events back after a failed submission, so a trigger is not lost.
/datum/agent_binding/proc/restore_events(list/taken)
	if(!length(taken))
		return
	for(var/list/entry as anything in taken)
		push_event(entry["event"], entry["urgency"], entry["detail"])

/datum/agent_binding/proc/can_start_request()
	if(state != AGENT_BINDING_IDLE || !dirty || pawn_gone)
		return FALSE
	if(world.time < next_request_at)
		return FALSE
	if(consecutive_failures >= AGENT_MAX_CONSECUTIVE_FAILURES)
		return FALSE
	return TRUE

/// Called after a transport-level failure. Retries, then gives up and stays quiet.
/datum/agent_binding/proc/note_failure(list/unsent_events)
	consecutive_failures++
	restore_events(unsent_events)
	next_request_at = world.time + (AGENT_FAILURE_BACKOFF * consecutive_failures)
	if(consecutive_failures >= AGENT_MAX_CONSECUTIVE_FAILURES)
		dirty = FALSE
		return FALSE
	dirty = TRUE
	return TRUE

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
