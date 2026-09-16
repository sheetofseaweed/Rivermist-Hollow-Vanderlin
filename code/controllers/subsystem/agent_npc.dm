/**
 * # Agent NPC subsystem
 *
 * Drives agent-controlled NPCs by asking an out-of-process sidecar what to do.
 *
 * The loop is drain / expire / consume / start, bounded per fire. Network
 * waiting is asynchronous, but parsing and validation are ordinary DM work and
 * are held inside the tick budget like anything else.
 *
 * Nothing here executes an action. This stage validates and reports; the
 * executor arrives with the perception layer in phase 3.
 */
SUBSYSTEM_DEF(agent_npc)
	name = "Agent NPC"
	wait = 0.5 SECONDS
	init_order = INIT_ORDER_AGENT_NPC
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME

	/// Config gate. False means the subsystem never fires.
	var/enabled = FALSE
	/// Operator kill switch. Separate from enabled so it survives a config reload.
	var/globally_disabled = FALSE
	var/endpoint = ""
	var/list/default_headers
	/// Identifies this subsystem run. Replies from an older run are refused.
	var/session_id
	/// pawn_id -> /datum/agent_binding
	var/list/bindings
	/// Subset of bindings with a request in flight.
	var/list/in_flight
	/// Orphaned transports still being polled, mapped to their give-up time.
	var/list/draining
	/// Never reused, so a rebuilt binding cannot inherit an old identity.
	var/next_epoch = 1
	/// Never reused, so no two requests in a session share an id.
	var/next_serial = 1
	var/max_concurrent = 4
	var/round_token_budget = 0
	var/tokens_spent = 0
	/// Sum of live reservations. Admission counts this, not just settled spend.
	var/tokens_reserved_total = 0
	/// AGENT_REFUSE_* -> count. The first thing to read when something is wrong.
	var/list/refusal_counts

/datum/controller/subsystem/agent_npc/Initialize()
	bindings = list()
	in_flight = list()
	draining = list()
	refusal_counts = list()
	session_id = "[GLOB.round_id]-[world.timeofday]-[rand(1000, 9999)]"

	if(!CONFIG_GET(flag/agent_npc_enabled))
		enabled = FALSE
		flags |= SS_NO_FIRE
		return TRUE

	endpoint = CONFIG_GET(string/agent_npc_url)
	if(!endpoint)
		enabled = FALSE
		flags |= SS_NO_FIRE
		stack_trace("SSagent_npc is enabled but AGENT_NPC_URL is unset. Staying off.")
		return FALSE

	max_concurrent = max(1, CONFIG_GET(number/agent_npc_max_concurrent))
	round_token_budget = CONFIG_GET(number/agent_npc_round_token_budget)
	default_headers = list("Content-Type" = "application/json")
	enabled = TRUE

	// No readiness probe here on purpose. A blocking check at init is what made
	// SSplexora's fire loop misleading; the first request discovers the truth.
	log_agent("initialised, session [session_id], endpoint [endpoint]")
	return TRUE

/datum/controller/subsystem/agent_npc/Recover()
	flags |= SS_NO_INIT
	enabled = SSagent_npc.enabled
	globally_disabled = SSagent_npc.globally_disabled
	endpoint = SSagent_npc.endpoint
	default_headers = SSagent_npc.default_headers
	session_id = SSagent_npc.session_id
	bindings = SSagent_npc.bindings
	in_flight = SSagent_npc.in_flight
	draining = SSagent_npc.draining
	refusal_counts = SSagent_npc.refusal_counts
	next_epoch = SSagent_npc.next_epoch
	next_serial = SSagent_npc.next_serial
	max_concurrent = SSagent_npc.max_concurrent
	round_token_budget = SSagent_npc.round_token_budget
	tokens_spent = SSagent_npc.tokens_spent
	tokens_reserved_total = SSagent_npc.tokens_reserved_total

/datum/controller/subsystem/agent_npc/Shutdown()
	disable_all("world shutdown")

/datum/controller/subsystem/agent_npc/fire(resumed)
	// Draining runs even while disabled: abandoned native jobs still need
	// collecting, and disabling is exactly what creates them.
	drain_pass()
	if(MC_TICK_CHECK)
		return

	if(!enabled || globally_disabled)
		return

	sweep_pass()
	if(MC_TICK_CHECK)
		return
	expire_pass()
	if(MC_TICK_CHECK)
		return
	consume_pass()
	if(MC_TICK_CHECK)
		return
	start_pass()

/// Take ownership of a transport whose request has been abandoned.
/datum/controller/subsystem/agent_npc/proc/drain_transport(datum/http_request/transport)
	if(!transport)
		return
	LAZYINITLIST(draining)
	draining[transport] = world.time + AGENT_DRAIN_TIMEOUT

/**
 * Poll orphaned transports until rust-g hands the result over.
 *
 * Dropping the DM handle does not free the native job; only collecting the
 * result does. Without this, every timeout and every disable leaks one.
 */
/datum/controller/subsystem/agent_npc/proc/drain_pass()
	var/polled = 0
	for(var/datum/http_request/transport as anything in draining)
		if(polled++ >= AGENT_MAX_DRAIN_PER_FIRE)
			return
		if(transport.is_complete())
			draining -= transport
			qdel(transport)
			continue
		if(world.time > draining[transport])
			draining -= transport
			note_refusal("drain_timeout")
			log_agent("gave up draining a transport after [AGENT_DRAIN_TIMEOUT / 10]s; its native job may be retained")
			qdel(transport)
			continue
		if(MC_TICK_CHECK)
			return

/// Remove bindings whose pawn is gone. The deletion signal only flags them.
/datum/controller/subsystem/agent_npc/proc/sweep_pass()
	for(var/pawn_id in bindings)
		var/datum/agent_binding/binding = bindings[pawn_id]
		if(QDELETED(binding) || binding.pawn_gone || !binding.resolve_pawn())
			unregister_pawn(binding, "pawn gone")
			if(MC_TICK_CHECK)
				return

/// Kill anything past its deadline before looking at what came back.
/datum/controller/subsystem/agent_npc/proc/expire_pass()
	for(var/datum/agent_binding/binding as anything in in_flight)
		if(QDELETED(binding) || !binding.pending)
			in_flight -= binding
			continue
		if(!binding.pending.is_expired())
			continue
		note_refusal(AGENT_REFUSE_DEADLINE)
		binding.record_result(AGENT_RESULT_EXPIRED, "deadline passed")
		// A timeout is a transport failure: back off rather than retry instantly.
		binding.note_failure(null)
		binding.abandon_pending("deadline")
		in_flight -= binding
		if(MC_TICK_CHECK)
			return

/// Validate whatever landed. A response only executes if it is still current.
/datum/controller/subsystem/agent_npc/proc/consume_pass()
	for(var/datum/agent_binding/binding as anything in in_flight)
		if(QDELETED(binding) || !binding.pending)
			in_flight -= binding
			continue
		if(!binding.pending.is_complete())
			continue

		var/datum/agent_request/request = binding.pending
		var/datum/agent_response/response = agent_validate_response(request, binding)

		binding.settle_tokens(request.tokens_reserved, response.tokens_used)
		release_global_reservation(request.tokens_reserved)
		tokens_spent += response.tokens_used
		in_flight -= binding
		binding.pending = null
		binding.state = AGENT_BINDING_IDLE
		qdel(request.release_transport())
		qdel(request)

		handle_response(binding, response)
		qdel(response)

		if(round_token_budget > 0 && tokens_spent >= round_token_budget)
			disable_all("round token budget exhausted")
			return

		if(MC_TICK_CHECK)
			return

/// Decide what a validated response means, after re-checking the world.
/datum/controller/subsystem/agent_npc/proc/handle_response(datum/agent_binding/binding, datum/agent_response/response)
	if(!response.ok)
		binding.requests_refused++
		note_refusal(response.refusal)
		log_agent("refused [binding.pawn_id]: [response.refusal]")
		// Transport-level failures are worth retrying; a bad payload is not.
		if(response.refusal == AGENT_REFUSE_TRANSPORT)
			binding.note_failure(null)
		return

	binding.note_success()

	// The world moved while this was in flight. Registration, liveness,
	// ownership and player takeover are all rechecked here, not just at start.
	if(!binding.still_owns_pawn() || bindings[binding.pawn_id] != binding)
		note_refusal(AGENT_REFUSE_PAWN)
		log_agent("dropped a valid decision for [binding.pawn_id]: no longer owns its pawn")
		return

	if(binding.state == AGENT_BINDING_DISABLED)
		note_refusal(AGENT_REFUSE_GENERATION)
		return

	if(response.model_refusal)
		binding.record_result(AGENT_RESULT_REJECTED, "model declined")
		return

	dispatch_decision(binding, response)

/// Start work for dirty bindings, bounded by both caps.
/datum/controller/subsystem/agent_npc/proc/start_pass()
	var/started = 0
	for(var/pawn_id in bindings)
		if(started >= AGENT_MAX_STARTS_PER_FIRE || length(in_flight) >= max_concurrent)
			return

		var/datum/agent_binding/binding = bindings[pawn_id]
		if(QDELETED(binding) || !binding.can_start_request())
			continue
		if(!binding.still_owns_pawn())
			note_refusal(AGENT_REFUSE_PAWN)
			continue
		if(!can_afford_request())
			continue

		if(start_request(binding))
			started++
		if(MC_TICK_CHECK)
			return

/// Admission counts live reservations, not just settled spend.
/datum/controller/subsystem/agent_npc/proc/can_afford_request()
	if(round_token_budget <= 0)
		return TRUE
	return (tokens_spent + tokens_reserved_total + AGENT_TOKEN_ESTIMATE) <= round_token_budget

/datum/controller/subsystem/agent_npc/proc/release_global_reservation(amount)
	tokens_reserved_total = max(0, tokens_reserved_total - amount)

/datum/controller/subsystem/agent_npc/proc/start_request(datum/agent_binding/binding)
	binding.observation_revision++
	binding.requests_made++
	binding.next_request_at = world.time + AGENT_MIN_REQUEST_INTERVAL

	var/list/events = binding.take_events()
	var/datum/agent_request/request = new()
	var/list/body = request.prepare(binding, session_id, next_serial++, build_observation(binding), events, binding.profile_payload())

	// Reserve before sending. Settling only completed spend lets concurrent
	// requests overshoot the ceiling together.
	request.tokens_reserved = AGENT_TOKEN_ESTIMATE
	binding.reserve_tokens(AGENT_TOKEN_ESTIMATE)
	tokens_reserved_total += AGENT_TOKEN_ESTIMATE

	if(!request.begin(endpoint, default_headers, body))
		note_refusal(AGENT_REFUSE_TRANSPORT)
		binding.release_reservation(AGENT_TOKEN_ESTIMATE)
		release_global_reservation(AGENT_TOKEN_ESTIMATE)
		drain_transport(request.release_transport())
		qdel(request)
		// Submission never happened, so the trigger must not be lost.
		binding.note_failure(events)
		return FALSE

	binding.pending = request
	binding.state = AGENT_BINDING_PENDING
	in_flight += binding
	return TRUE

/// Build the observer-relative scene and keep its handle table for execution.
/datum/controller/subsystem/agent_npc/proc/build_observation(datum/agent_binding/binding)
	var/list/built = agent_build_observation(binding.resolve_pawn(), binding.observation_revision)
	binding.set_observation(built["observation"])
	return built["payload"]

/**
 * Execution seam.
 *
 * Handle authorisation happens here, not at parse time: a structurally valid
 * handle string is not an authorised target until it resolves against the
 * observation that was actually sent. Phase 4 adds the motor actions; this
 * stage resolves, authorises, and reports a real terminal state.
 */
/datum/controller/subsystem/agent_npc/proc/dispatch_decision(datum/agent_binding/binding, datum/agent_response/response)
	var/name = response.action["name"]
	var/mob/living/pawn = binding.resolve_pawn()
	log_agent("decision [binding.pawn_id]: [name]")

	// Authorisation check one: is this action permitted for this NPC's role?
	// The action vocabulary is global; the profile narrows it per character.
	if(!binding.profile_permits(name))
		note_refusal(AGENT_REFUSE_SCHEMA)
		binding.record_result(AGENT_RESULT_REJECTED, "[name] is not permitted for this character")
		return

	switch(name)
		if("wait")
			binding.record_result(AGENT_RESULT_SUCCEEDED, "waiting")
			return
		if("say")
			var/list/outcome = agent_execute_say(pawn, response.action["text"])
			binding.record_result(outcome["state"], outcome["detail"])
			return
		if("emote")
			var/list/outcome = agent_execute_emote(pawn, response.action["key"])
			binding.record_result(outcome["state"], outcome["detail"])
			return

	// approach and use. The handle only becomes an authorised target here,
	// resolved against the observation that was actually sent.
	var/atom/target = binding.resolve_handle(response.action["handle"])
	if(isnull(target))
		note_refusal(AGENT_REFUSE_SCHEMA)
		binding.record_result(AGENT_RESULT_REJECTED, "handle was never offered, or its target is gone")
		return

	var/datum/ai_controller/agent_social/agent = binding.resolve_controller()
	if(!istype(agent))
		binding.record_result(AGENT_RESULT_REJECTED, "this pawn cannot act on objectives")
		return

	// Retargeting cancels only the agent's own behavior. CancelActions() would
	// also finish an active resist or restraint break.
	agent.cancel_agent_objective()
	agent.set_blackboard_key(BB_AGENT_OBJECTIVE_TARGET, target)
	binding.begin_intent(response.action)

/datum/controller/subsystem/agent_npc/proc/note_refusal(reason)
	if(!reason)
		return
	refusal_counts[reason] = (refusal_counts[reason] || 0) + 1

/// Register a pawn. Called from the controller when the mob spawns.
/datum/controller/subsystem/agent_npc/proc/register_pawn(mob/living/pawn, datum/ai_controller/controller)
	if(!enabled || globally_disabled || QDELETED(pawn))
		return null
	if(length(bindings) >= AGENT_MAX_REGISTERED_PAWNS)
		stack_trace("SSagent_npc registry full at [AGENT_MAX_REGISTERED_PAWNS]; refusing [pawn].")
		return null

	var/datum/agent_binding/binding = new(pawn, controller)
	binding.epoch = next_epoch++
	if(bindings[binding.pawn_id])
		unregister_pawn(bindings[binding.pawn_id], "re-registered")
	bindings[binding.pawn_id] = binding
	log_agent("registered [binding.pawn_id] epoch [binding.epoch]")
	return binding

/datum/controller/subsystem/agent_npc/proc/unregister_pawn(datum/agent_binding/binding, reason = "unregistered")
	if(QDELETED(binding))
		return
	binding.revoke(reason)
	in_flight -= binding
	bindings -= binding.pawn_id
	log_agent("unregistered [binding.pawn_id]: [reason]")
	qdel(binding)

/// Operator kill switch. No agent-authorised effect survives this returning.
/datum/controller/subsystem/agent_npc/proc/disable_all(reason = "operator request")
	globally_disabled = TRUE
	for(var/pawn_id in bindings)
		var/datum/agent_binding/binding = bindings[pawn_id]
		if(QDELETED(binding))
			continue
		var/datum/ai_controller/controller = binding.resolve_controller()
		binding.revoke(reason)
		if(!controller)
			continue
		controller.CancelActions()
		controller.set_movement_target(source = type, target = null)
		// Clearing the target is not enough. A controller registered with the
		// movement datum keeps being processed until it is deregistered.
		controller.ai_movement?.stop_moving_towards(controller)
	in_flight.Cut()
	log_agent("DISABLED ALL: [reason]")

/datum/controller/subsystem/agent_npc/proc/enable_all(reason = "operator request")
	globally_disabled = FALSE
	for(var/pawn_id in bindings)
		var/datum/agent_binding/binding = bindings[pawn_id]
		if(!QDELETED(binding))
			binding.reinstate()
	log_agent("RE-ENABLED: [reason]")

/datum/controller/subsystem/agent_npc/proc/log_agent(text)
	log_world("AGENT_NPC: [text]")

/datum/controller/subsystem/agent_npc/stat_entry(msg)
	msg = "P:[length(bindings)] F:[length(in_flight)] D:[length(draining)] T:[tokens_spent][globally_disabled ? " OFF" : ""]"
	return ..()
