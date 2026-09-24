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
	/// Reserved for work we walked away from. Possibly billed, cost unknown.
	var/tokens_unsettled = 0
	/// Transports we stopped draining before rust-g handed the result back.
	var/drain_abandoned = 0
	/// AGENT_REFUSE_* -> count. The first thing to read when something is wrong.
	var/list/refusal_counts
	/// Measured latency, cost and outcome mix. Never null once initialised.
	var/datum/agent_telemetry/telemetry

/datum/controller/subsystem/agent_npc/Initialize()
	bindings = list()
	in_flight = list()
	draining = list()
	refusal_counts = list()
	// Built before the config gate. Tests and the status verb read it whether or
	// not the subsystem was allowed to turn on.
	telemetry = new()
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
	telemetry = SSagent_npc.telemetry
	next_epoch = SSagent_npc.next_epoch
	next_serial = SSagent_npc.next_serial
	max_concurrent = SSagent_npc.max_concurrent
	round_token_budget = SSagent_npc.round_token_budget
	tokens_spent = SSagent_npc.tokens_spent
	tokens_reserved_total = SSagent_npc.tokens_reserved_total
	tokens_unsettled = SSagent_npc.tokens_unsettled
	drain_abandoned = SSagent_npc.drain_abandoned

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
			drain_abandoned++
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
		binding.requests_expired++
		// Logged, because this is where a good answer goes to die. Anything the
		// sidecar sends after this point is drained unread, so without a line
		// here the only symptom is a 200 in the sidecar log and silence in game.
		log_agent("expired [binding.pawn_id]: no reply within [AGENT_DEFAULT_DEADLINE / 10]s; a later answer will be discarded")
		binding.record_result(AGENT_RESULT_EXPIRED, "deadline passed")
		// A timeout is a transport failure: back off rather than retry instantly,
		// and restore the trigger the timed-out request was carrying.
		binding.note_failure(binding.pending.sent_events?.Copy())
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

		// Read before the request is destroyed below. Every consumed reply is
		// measured, refused or not: a refusal still costs the same wall time.
		note_decision(world.time - request.started_at, response.tokens_used)

		// One close, both ledgers, with the real cost.
		close_reservation(binding, request, response.tokens_used)

		// The events this request carried, kept past the request's own life so
		// a transport failure can restore the trigger rather than lose it.
		var/list/sent_events = request.sent_events?.Copy()

		in_flight -= binding
		binding.pending = null
		binding.state = AGENT_BINDING_IDLE
		binding.update_thinking()
		qdel(request.release_transport())
		qdel(request)

		handle_response(binding, response, sent_events)
		qdel(response)

		if(round_token_budget > 0 && tokens_spent >= round_token_budget)
			disable_all("round token budget exhausted")
			return

		if(MC_TICK_CHECK)
			return

/// Decide what a validated response means, after re-checking the world.
/datum/controller/subsystem/agent_npc/proc/handle_response(datum/agent_binding/binding, datum/agent_response/response, list/sent_events)
	if(!response.ok)
		binding.requests_refused++
		note_refusal(response.refusal)
		log_agent("refused [binding.pawn_id]: [response.refusal]")
		// Transport-level failures are worth retrying; a bad payload is not.
		if(response.refusal == AGENT_REFUSE_TRANSPORT)
			// Put the trigger back. take_events() emptied the ring at send, so
			// without this a retry asks the agent what to do having forgotten
			// the speech that prompted it.
			binding.note_failure(sent_events)
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
		log_agent("dropped a valid decision for [binding.pawn_id]: binding is disabled")
		return

	if(response.model_refusal)
		// Counted and logged. This is the likeliest way a working pipeline
		// produces nothing in game, so it must never be silent.
		note_refusal(AGENT_REFUSE_MODEL)
		log_agent("model refusal for [binding.pawn_id]: [response.model_refusal]")
		binding.record_result(AGENT_RESULT_REJECTED, response.model_refusal)
		return

	dispatch_decision(binding, response)

/// Start work for dirty bindings, bounded by both caps.
/datum/controller/subsystem/agent_npc/proc/start_pass()
	var/started = 0
	for(var/pawn_id in bindings)
		if(started >= AGENT_MAX_STARTS_PER_FIRE || length(in_flight) >= max_concurrent)
			return
		if(!has_outstanding_capacity())
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

/**
 * Is there room for more outstanding work?
 *
 * max_concurrent bounds decisions we are waiting on. Draining holds transports
 * we abandoned but which may still be running at the provider - real work that
 * freeing a decision slot does not stop.
 */
/datum/controller/subsystem/agent_npc/proc/has_outstanding_capacity()
	return (length(in_flight) + length(draining)) < AGENT_MAX_OUTSTANDING

/**
 * Open a reservation on both ledgers at once.
 *
 * Two ledgers with independent release calls is what produced the leak this
 * replaces. Open and close are now the only two places either ledger moves.
 */
/datum/controller/subsystem/agent_npc/proc/open_reservation(datum/agent_binding/binding, datum/agent_request/request, amount)
	request.tokens_reserved = amount
	request.reservation_open = TRUE
	binding.reserve_tokens(amount)
	tokens_reserved_total += amount

/**
 * Close a reservation. Exactly once, on both ledgers.
 *
 * Returns TRUE only for the call that performed the release, so a double close
 * cannot credit back tokens that were never held.
 *
 * unsettled marks work we walked away from: the hold is released so admission
 * recovers, but the cost is recorded as unknown rather than assumed to be zero.
 */
/datum/controller/subsystem/agent_npc/proc/close_reservation(datum/agent_binding/binding, datum/agent_request/request, actual_tokens = 0, unsettled = FALSE)
	if(QDELETED(request) || !request.reservation_open)
		return FALSE
	request.reservation_open = FALSE

	binding?.settle_tokens(request.tokens_reserved, actual_tokens)
	tokens_reserved_total = max(0, tokens_reserved_total - request.tokens_reserved)
	tokens_spent += actual_tokens
	if(unsettled)
		tokens_unsettled += request.tokens_reserved
	return TRUE

/datum/controller/subsystem/agent_npc/proc/start_request(datum/agent_binding/binding)
	binding.observation_revision++
	binding.requests_made++
	binding.next_request_at = world.time + AGENT_MIN_REQUEST_INTERVAL

	// Read before take_events(), which clears the clock it is measured from.
	note_request_started(binding)

	var/list/events = binding.take_events()
	var/datum/agent_request/request = new()
	var/list/body = request.prepare(binding, session_id, next_serial++, build_observation(binding), events, binding.profile_payload())

	// Reserve before sending. Settling only completed spend lets concurrent
	// requests overshoot the ceiling together.
	open_reservation(binding, request, AGENT_TOKEN_ESTIMATE)

	if(!request.begin(endpoint, default_headers, body))
		note_refusal(AGENT_REFUSE_TRANSPORT)
		// Nothing was sent, so nothing can have been billed: settle at zero.
		close_reservation(binding, request, 0)
		drain_transport(request.release_transport())
		qdel(request)
		// Submission never happened, so the trigger must not be lost.
		binding.note_failure(events)
		return FALSE

	// Keep the events with the request. If it times out or the transport fails
	// after submission, the trigger can be restored instead of vanishing.
	request.sent_events = events
	binding.pending = request
	binding.state = AGENT_BINDING_PENDING
	binding.update_thinking()
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

	// Counted before authorisation on purpose: a model repeatedly asking for an
	// action its profile forbids is a prompt problem, and this is where it shows.
	note_action(name)

	// Authorisation check one: is this action permitted for this NPC's role?
	// The action vocabulary is global; the profile narrows it per character.
	if(!binding.profile_permits(name))
		note_refusal(AGENT_REFUSE_SCHEMA)
		binding.record_result(AGENT_RESULT_REJECTED, "[name] is not permitted for this character")
		return

	// Answering makes a conversation, waiting declines it. After the permission check, so forbidden actions engage nobody.
	if(name == "wait")
		binding.decline_candidate()
	else
		binding.engage_candidate()

	switch(name)
		if("wait")
			// Choosing to wait ends the self-driven chain. Buffered events stay.
			binding.complete_action(AGENT_RESULT_SUCCEEDED, "waiting", was_wait = TRUE)
			return
		if("say")
			var/list/outcome = agent_execute_say(pawn, response.action["text"])
			binding.complete_action(outcome["state"], outcome["detail"])
			return
		if("emote")
			var/list/outcome = agent_execute_emote(pawn, response.action["key"])
			binding.complete_action(outcome["state"], outcome["detail"])
			return
		if("me")
			var/list/outcome = agent_execute_me(pawn, response.action["text"])
			binding.complete_action(outcome["state"], outcome["detail"])
			return
		if("stand")
			var/list/outcome = agent_execute_stand(pawn)
			binding.complete_action(outcome["state"], outcome["detail"])
			return

	// Every action from here names a handle, authorised only here against the observation actually sent.
	var/atom/target = binding.resolve_handle(response.action["handle"])
	if(isnull(target))
		note_refusal(AGENT_REFUSE_SCHEMA)
		binding.record_result(AGENT_RESULT_REJECTED, "handle was never offered, or its target is gone")
		return

	// Carried items get handles so give can name them. They are never somewhere to walk or click.
	var/atom/movable/movable_target = target
	if(ismovable(movable_target) && movable_target.loc == pawn)
		binding.record_result(AGENT_RESULT_REJECTED, "that is in your own hands")
		return

	// The offerer is already beside us and must stay there, so taking is immediate.
	if(name == "take")
		if(!isliving(target) || target == pawn)
			binding.record_result(AGENT_RESULT_REJECTED, "take accepts what a person is offering you")
			return
		var/list/taken = agent_execute_take(pawn, target)
		binding.complete_action(taken["state"], taken["detail"])
		return

	// use clicks with whatever is held; on a person, a knife makes that a stab, and this NPC cannot fight.
	if(name == "use" && isliving(target))
		binding.record_result(AGENT_RESULT_REJECTED, "use is for things; to lay a hand on a person, use touch")
		return

	// Checked before walking anywhere, so a bad request costs no trip.
	if(name == "touch")
		if(!isliving(target) || target == pawn)
			binding.record_result(AGENT_RESULT_REJECTED, "touch is for other people; use 'use' for things")
			return
		if(!(response.action["key"] in agent_touch_ways()))
			binding.record_result(AGENT_RESULT_REJECTED, "not a way to touch someone")
			return

	if(name == "sit" && !agent_is_seat(target))
		binding.record_result(AGENT_RESULT_REJECTED, "that is not something to sit on")
		return

	// Resolved now and kept on the blackboard: by the time the NPC arrives, the handle may mean something else.
	var/obj/item/give_item
	if(name == "give")
		if(!isliving(target) || target == pawn)
			binding.record_result(AGENT_RESULT_REJECTED, "give hands something to a person")
			return
		var/item_handle = response.action["key"]
		give_item = length(item_handle) ? binding.resolve_handle(item_handle) : pawn.get_active_held_item()
		if(!isitem(give_item) || !(give_item in pawn.held_items))
			binding.record_result(AGENT_RESULT_REJECTED, "you are not holding that")
			return

	var/datum/ai_controller/agent_social/agent = binding.resolve_controller()
	if(!istype(agent))
		binding.record_result(AGENT_RESULT_REJECTED, "this pawn cannot act on objectives")
		return

	// Walking anywhere means getting up first. Sitting down on the seat already taken does not.
	if(pawn.buckled && agent_is_seat(pawn.buckled) && !(name == "sit" && pawn.buckled == target))
		agent_execute_stand(pawn)

	// Only the agent's own behavior is cancelled: CancelActions() would also end a resist or restraint break.
	agent.cancel_agent_objective()
	agent.set_blackboard_key(BB_AGENT_OBJECTIVE_TARGET, target)
	if(give_item)
		agent.set_blackboard_key(BB_AGENT_GIVE_ITEM, give_item)
	binding.begin_intent(response.action)

/datum/controller/subsystem/agent_npc/proc/note_refusal(reason)
	if(!reason)
		return
	refusal_counts[reason] = (refusal_counts[reason] || 0) + 1

/**
 * Telemetry seam.
 *
 * Each of these null-checks telemetry explicitly rather than chaining `?.`. In
 * DM the null-conditional guards only the access it is written on, so
 * `telemetry?.round_trip.record(x)` still runtimes when telemetry is null.
 */
/datum/controller/subsystem/agent_npc/proc/note_decision(latency_ds, tokens_used)
	if(!telemetry)
		return FALSE
	telemetry.note_decision(latency_ds, tokens_used)
	return TRUE

/datum/controller/subsystem/agent_npc/proc/note_queue_wait(wait_ds)
	if(!telemetry)
		return FALSE
	return telemetry.queue_wait.record(wait_ds)

/**
 * Record the wait a starting request sat through.
 *
 * A probe is counted rather than timed. Its wait is the breaker cooldown, which
 * would swamp the pacing figure the queue statistic exists to give.
 */
/datum/controller/subsystem/agent_npc/proc/note_request_started(datum/agent_binding/binding)
	if(binding.is_probe())
		return note_breaker_probe()
	return note_queue_wait(binding.queued_time())

/**
 * Is there round budget left for speech we could not classify?
 *
 * Fails open when telemetry is absent. Not being able to count is not a reason
 * for an NPC to start ignoring people.
 */
/datum/controller/subsystem/agent_npc/proc/ambiguous_budget_left()
	if(!telemetry)
		return TRUE
	return telemetry.ambiguous_requests < AGENT_AMBIGUOUS_ROUND_LIMIT

/datum/controller/subsystem/agent_npc/proc/note_ambiguous_request()
	if(!telemetry)
		return FALSE
	telemetry.ambiguous_requests++
	return TRUE

/datum/controller/subsystem/agent_npc/proc/note_ambiguous_deferred()
	if(!telemetry)
		return FALSE
	telemetry.ambiguous_deferred++
	return TRUE

/datum/controller/subsystem/agent_npc/proc/note_agent_exchange_capped()
	if(!telemetry)
		return FALSE
	telemetry.agent_exchanges_capped++
	return TRUE

/// Called by run_emote for every emote. Returns how many agent NPCs took it in, for tests.
/datum/controller/subsystem/agent_npc/proc/notice_emote(mob/emoter, datum/emote/emote, text, intentional)
	SHOULD_NOT_SLEEP(TRUE)
	if(!length(bindings) || QDELETED(emoter) || !istext(text))
		return 0
	var/audible = emote && (emote.emote_type & EMOTE_AUDIBLE)
	var/taken = 0
	for(var/pawn_id in bindings)
		var/datum/agent_binding/binding = bindings[pawn_id]
		if(QDELETED(binding))
			continue
		var/datum/ai_controller/agent_social/agent = binding.resolve_controller()
		if(!istype(agent))
			continue
		var/route = agent.on_emote_perceived(emoter, text, intentional, audible)
		if(route != "unseen" && route != "unbound")
			taken++
	return taken

/datum/controller/subsystem/agent_npc/proc/note_breaker_probe()
	if(!telemetry)
		return FALSE
	telemetry.breaker_probes++
	return TRUE

/datum/controller/subsystem/agent_npc/proc/note_observation_age(age_ds)
	if(!telemetry)
		return FALSE
	return telemetry.observation_age.record(age_ds)

/datum/controller/subsystem/agent_npc/proc/note_chain_depth(depth)
	if(!telemetry)
		return FALSE
	return telemetry.chain_depth.record(depth)

/datum/controller/subsystem/agent_npc/proc/note_action(action_name)
	if(!telemetry)
		return FALSE
	return telemetry.note_action(action_name)

/datum/controller/subsystem/agent_npc/proc/note_result(state_name)
	if(!telemetry)
		return FALSE
	return telemetry.note_result(state_name)

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
