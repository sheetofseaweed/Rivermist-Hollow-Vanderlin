// Phase 2 exit criterion: every fault the fake sidecar can emit must be refused
// before it reaches an executor. These drive agent_validate_response directly,
// so no sidecar and no model spend are involved.

/// Wrap a body in the rust-g response envelope that into_response() expects.
/proc/agent_test_raw(list/body, status_code = 200)
	return json_encode(list("status_code" = status_code, "headers" = list(), "body" = json_encode(body)))

/// Same, but the body is raw text rather than an encoded list.
/proc/agent_test_raw_text(body_text, status_code = 200)
	return json_encode(list("status_code" = status_code, "headers" = list(), "body" = body_text))

/// A binding with no pawn. Protocol checks never resolve one.
/proc/agent_test_binding(pawn_id = "test-pawn", epoch = 1)
	var/datum/agent_binding/binding = new(null, null)
	binding.pawn_id = pawn_id
	binding.epoch = epoch
	return binding

/// A prepared request whose transport is inert, so is_complete() reads TRUE.
/proc/agent_test_request_for(datum/agent_binding/binding, serial = 1)
	var/datum/agent_request/request = new()
	request.prepare(binding, "test-session", serial, list(), list())
	request.transport = new /datum/http_request()
	return request

/// The echo block a well-behaved sidecar returns for this request.
/proc/agent_test_echo(datum/agent_request/request)
	return list(
		"protocol_version" = AGENT_PROTOCOL_VERSION,
		"round_id" = request.round_id,
		"session_id" = request.session_id,
		"pawn_id" = request.pawn_id,
		"binding_epoch" = request.binding_epoch,
		"binding_generation" = request.binding_generation,
		"request_id" = request.request_id,
		"observation_revision" = request.observation_revision,
	)

/proc/agent_test_say_action()
	return list("name" = "say", "text" = "Well met.")

// ---------------------------------------------------------------- happy path

/datum/unit_test/agent_npc_valid_response_is_accepted

/datum/unit_test/agent_npc_valid_response_is_accepted/Run()
	var/datum/agent_binding/binding = agent_test_binding()
	var/datum/agent_request/request = agent_test_request_for(binding)
	request.transport._raw_response = agent_test_raw(list(
		"echo" = agent_test_echo(request),
		"action" = agent_test_say_action(),
	))

	var/datum/agent_response/response = agent_validate_response(request, binding)

	TEST_ASSERT(response.ok, "A current, well-formed response must be accepted. Refusal: [response.refusal]")
	TEST_ASSERT_EQUAL(response.action["name"], "say", "The validated action should survive intact.")

// ------------------------------------------------------------ identity guards

/datum/unit_test/agent_npc_stale_generation_is_refused

/datum/unit_test/agent_npc_stale_generation_is_refused/Run()
	var/datum/agent_binding/binding = agent_test_binding()
	var/datum/agent_request/request = agent_test_request_for(binding)
	request.transport._raw_response = agent_test_raw(list(
		"echo" = agent_test_echo(request),
		"action" = agent_test_say_action(),
	))

	// This is what disable_all() does. The reply is already on the wire.
	binding.revoke("test revoke")

	var/datum/agent_response/response = agent_validate_response(request, binding)

	TEST_ASSERT(!response.ok, "A reply from before a revoke must never execute.")
	TEST_ASSERT_EQUAL(response.refusal, AGENT_REFUSE_GENERATION, "Revoked binding should refuse on generation.")

/datum/unit_test/agent_npc_stale_revision_is_refused

/datum/unit_test/agent_npc_stale_revision_is_refused/Run()
	var/datum/agent_binding/binding = agent_test_binding()
	var/datum/agent_request/request = agent_test_request_for(binding)
	request.transport._raw_response = agent_test_raw(list(
		"echo" = agent_test_echo(request),
		"action" = agent_test_say_action(),
	))

	// The world moved on and a newer observation was built while this was in flight.
	binding.observation_revision++

	var/datum/agent_response/response = agent_validate_response(request, binding)

	TEST_ASSERT_EQUAL(response.refusal, AGENT_REFUSE_REVISION, "A reply about a superseded observation must be refused.")

/datum/unit_test/agent_npc_foreign_request_id_is_refused

/datum/unit_test/agent_npc_foreign_request_id_is_refused/Run()
	var/datum/agent_binding/binding = agent_test_binding()
	var/datum/agent_request/request = agent_test_request_for(binding)
	var/list/echo = agent_test_echo(request)
	echo["request_id"] = "some-other-request"
	request.transport._raw_response = agent_test_raw(list("echo" = echo, "action" = agent_test_say_action()))

	var/datum/agent_response/response = agent_validate_response(request, binding)

	TEST_ASSERT_EQUAL(response.refusal, AGENT_REFUSE_UNKNOWN, "Duplicate and stale replies echo a different request id and must be refused.")

/datum/unit_test/agent_npc_session_mismatch_is_refused

/datum/unit_test/agent_npc_session_mismatch_is_refused/Run()
	var/datum/agent_binding/binding = agent_test_binding()
	var/datum/agent_request/request = agent_test_request_for(binding)
	var/list/echo = agent_test_echo(request)
	echo["session_id"] = "a-previous-subsystem-run"
	request.transport._raw_response = agent_test_raw(list("echo" = echo, "action" = agent_test_say_action()))

	var/datum/agent_response/response = agent_validate_response(request, binding)

	TEST_ASSERT_EQUAL(response.refusal, AGENT_REFUSE_SESSION, "A reply from an older subsystem run must be refused.")

/datum/unit_test/agent_npc_protocol_mismatch_is_refused

/datum/unit_test/agent_npc_protocol_mismatch_is_refused/Run()
	var/datum/agent_binding/binding = agent_test_binding()
	var/datum/agent_request/request = agent_test_request_for(binding)
	var/list/echo = agent_test_echo(request)
	echo["protocol_version"] = AGENT_PROTOCOL_VERSION + 1
	request.transport._raw_response = agent_test_raw(list("echo" = echo, "action" = agent_test_say_action()))

	var/datum/agent_response/response = agent_validate_response(request, binding)

	TEST_ASSERT_EQUAL(response.refusal, AGENT_REFUSE_PROTOCOL, "A sidecar speaking another protocol version must be refused.")

// -------------------------------------------------------------- body integrity

/datum/unit_test/agent_npc_malformed_body_is_refused

/datum/unit_test/agent_npc_malformed_body_is_refused/Run()
	var/datum/agent_binding/binding = agent_test_binding()
	var/datum/agent_request/request = agent_test_request_for(binding)
	request.transport._raw_response = agent_test_raw_text("{this is not json")

	var/datum/agent_response/response = agent_validate_response(request, binding)

	TEST_ASSERT_EQUAL(response.refusal, AGENT_REFUSE_MALFORMED, "Non-JSON bodies must be refused, not crash the consume pass.")

/datum/unit_test/agent_npc_oversized_body_is_refused

/datum/unit_test/agent_npc_oversized_body_is_refused/Run()
	var/datum/agent_binding/binding = agent_test_binding()
	var/datum/agent_request/request = agent_test_request_for(binding)

	var/list/padding = list()
	for(var/i in 1 to 700)
		padding += "0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789"

	request.transport._raw_response = agent_test_raw(list(
		"echo" = agent_test_echo(request),
		"action" = agent_test_say_action(),
		"padding" = padding.Join(""),
	))

	var/datum/agent_response/response = agent_validate_response(request, binding)

	TEST_ASSERT_EQUAL(response.refusal, AGENT_REFUSE_OVERSIZED, "Bodies over the cap must be rejected before they are parsed.")

/datum/unit_test/agent_npc_http_error_is_refused

/datum/unit_test/agent_npc_http_error_is_refused/Run()
	var/datum/agent_binding/binding = agent_test_binding()
	var/datum/agent_request/request = agent_test_request_for(binding)
	request.transport._raw_response = agent_test_raw(list("error" = "boom"), 500)

	var/datum/agent_response/response = agent_validate_response(request, binding)

	TEST_ASSERT_EQUAL(response.refusal, AGENT_REFUSE_TRANSPORT, "A non-200 status must be refused.")

/datum/unit_test/agent_npc_rustg_failure_is_refused

/datum/unit_test/agent_npc_rustg_failure_is_refused/Run()
	var/datum/agent_binding/binding = agent_test_binding()
	var/datum/agent_request/request = agent_test_request_for(binding)
	// rust-g reports its own failures as a bare string, not a response envelope.
	request.transport._raw_response = "Proc error: connection refused"

	var/datum/agent_response/response = agent_validate_response(request, binding)

	TEST_ASSERT_EQUAL(response.refusal, AGENT_REFUSE_TRANSPORT, "A rust-g transport failure must be refused.")

// ------------------------------------------------------------- action schema

/datum/unit_test/agent_npc_unknown_action_is_refused

/datum/unit_test/agent_npc_unknown_action_is_refused/Run()
	var/datum/agent_binding/binding = agent_test_binding()
	var/datum/agent_request/request = agent_test_request_for(binding)
	request.transport._raw_response = agent_test_raw(list(
		"echo" = agent_test_echo(request),
		"action" = list("name" = "detonate", "handle" = "h1"),
	))

	var/datum/agent_response/response = agent_validate_response(request, binding)

	TEST_ASSERT_EQUAL(response.refusal, AGENT_REFUSE_SCHEMA, "An action outside the allowlist must be refused.")

/datum/unit_test/agent_npc_model_refusal_carries_no_action

/datum/unit_test/agent_npc_model_refusal_carries_no_action/Run()
	var/datum/agent_binding/binding = agent_test_binding()
	var/datum/agent_request/request = agent_test_request_for(binding)
	request.transport._raw_response = agent_test_raw(list(
		"echo" = agent_test_echo(request),
		"refusal" = "declined",
	))

	var/datum/agent_response/response = agent_validate_response(request, binding)

	TEST_ASSERT(response.ok, "A model refusal is a valid protocol outcome, not a protocol error.")
	TEST_ASSERT_NULL(response.action, "A refusal must not carry an action.")
	TEST_ASSERT_NOTNULL(response.model_refusal, "The refusal text should be recorded.")

/datum/unit_test/agent_npc_action_validator_shapes

/datum/unit_test/agent_npc_action_validator_shapes/Run()
	TEST_ASSERT_NOTNULL(agent_validate_action(list("name" = "say", "text" = "hi")), "say with text is valid.")
	TEST_ASSERT_NOTNULL(agent_validate_action(list("name" = "emote", "key" = "wave")), "emote with a key is valid.")
	TEST_ASSERT_NOTNULL(agent_validate_action(list("name" = "approach", "handle" = "h1")), "approach with a handle is valid.")
	TEST_ASSERT_NOTNULL(agent_validate_action(list("name" = "use", "handle" = "h1")), "use with a handle is valid.")

	TEST_ASSERT_NULL(agent_validate_action(list("name" = "say", "text" = "")), "Empty speech must be rejected.")
	TEST_ASSERT_NULL(agent_validate_action(list("name" = "approach")), "approach without a handle must be rejected.")
	TEST_ASSERT_NULL(agent_validate_action(list("name" = "click", "handle" = "h1")), "click was deliberately removed from the vocabulary.")
	TEST_ASSERT_NULL(agent_validate_action(null), "A null action must be rejected.")

// ------------------------------------------------------------ binding control

/datum/unit_test/agent_npc_deadline_expires

/datum/unit_test/agent_npc_deadline_expires/Run()
	var/datum/agent_binding/binding = agent_test_binding()
	var/datum/agent_request/request = agent_test_request_for(binding)

	TEST_ASSERT(!request.is_expired(), "A fresh request must not be expired.")
	request.deadline = world.time - 1
	TEST_ASSERT(request.is_expired(), "A request past its deadline must report expired.")

/datum/unit_test/agent_npc_revoke_then_reinstate_moves_generation

/datum/unit_test/agent_npc_revoke_then_reinstate_moves_generation/Run()
	var/datum/agent_binding/binding = agent_test_binding()
	var/starting_generation = binding.generation

	binding.revoke("test")
	TEST_ASSERT_EQUAL(binding.state, AGENT_BINDING_DISABLED, "Revoke must disable the binding.")
	var/after_revoke = binding.generation
	TEST_ASSERT(after_revoke > starting_generation, "Revoke must advance the generation.")

	TEST_ASSERT(binding.reinstate(), "Reinstate should succeed on a disabled binding.")
	TEST_ASSERT_EQUAL(binding.state, AGENT_BINDING_IDLE, "Reinstate must return the binding to idle.")
	TEST_ASSERT(binding.generation > after_revoke, "Reinstate must advance the generation again, so replies from the disabled window stay dead.")

/datum/unit_test/agent_npc_disabled_binding_ignores_events

/datum/unit_test/agent_npc_disabled_binding_ignores_events/Run()
	var/datum/agent_binding/binding = agent_test_binding()
	binding.revoke("test")

	TEST_ASSERT(!binding.mark_dirty("heard_speech"), "A disabled binding must not accept events.")
	TEST_ASSERT(!binding.dirty, "A disabled binding must not become dirty.")

/datum/unit_test/agent_npc_high_urgency_abandons_in_flight

/datum/unit_test/agent_npc_high_urgency_abandons_in_flight/Run()
	var/datum/agent_binding/binding = agent_test_binding()
	binding.pending = agent_test_request_for(binding)
	binding.state = AGENT_BINDING_PENDING

	binding.mark_dirty("attacked", AGENT_EVENT_HIGH)

	TEST_ASSERT_NULL(binding.pending, "A high urgency event must abandon the in-flight request.")
	TEST_ASSERT_EQUAL(binding.state, AGENT_BINDING_IDLE, "Abandoning must return the binding to idle so it can re-ask.")

/datum/unit_test/agent_npc_low_urgency_waits_for_in_flight

/datum/unit_test/agent_npc_low_urgency_waits_for_in_flight/Run()
	var/datum/agent_binding/binding = agent_test_binding()
	binding.pending = agent_test_request_for(binding)
	binding.state = AGENT_BINDING_PENDING

	binding.mark_dirty("heard_speech", AGENT_EVENT_LOW)

	TEST_ASSERT_NOTNULL(binding.pending, "A low urgency event must not abandon an in-flight request.")
	TEST_ASSERT(binding.dirty, "It should still mark the binding dirty for the next round trip.")

/datum/unit_test/agent_npc_event_ring_keeps_urgent_entries

/datum/unit_test/agent_npc_event_ring_keeps_urgent_entries/Run()
	var/datum/agent_binding/binding = agent_test_binding()

	binding.mark_dirty("attacked", AGENT_EVENT_HIGH)
	for(var/i in 1 to AGENT_MAX_EVENTS_PER_PAWN * 2)
		binding.mark_dirty("ambient_[i]", AGENT_EVENT_LOW)

	TEST_ASSERT(length(binding.events) <= AGENT_MAX_EVENTS_PER_PAWN, "The event ring must stay bounded. Got [length(binding.events)].")

	var/kept_urgent = FALSE
	for(var/list/entry as anything in binding.events)
		if(entry["urgency"] >= AGENT_EVENT_HIGH)
			kept_urgent = TRUE
			break

	TEST_ASSERT(kept_urgent, "Overflow must drop ambient chatter, never the attack that mattered.")

/datum/unit_test/agent_npc_take_events_clears_buffer

/datum/unit_test/agent_npc_take_events_clears_buffer/Run()
	var/datum/agent_binding/binding = agent_test_binding()
	binding.mark_dirty("heard_speech")
	binding.mark_dirty("attacked", AGENT_EVENT_HIGH)

	var/list/taken = binding.take_events()

	TEST_ASSERT_EQUAL(length(taken), 2, "take_events must hand back everything buffered.")
	TEST_ASSERT_EQUAL(length(binding.events), 0, "take_events must clear the buffer so events are not resent.")
	TEST_ASSERT(!binding.dirty, "take_events must clear the dirty flag.")

/datum/unit_test/agent_npc_token_reservation_settles

/datum/unit_test/agent_npc_token_reservation_settles/Run()
	var/datum/agent_binding/binding = agent_test_binding()

	binding.reserve_tokens(500)
	TEST_ASSERT_EQUAL(binding.tokens_reserved, 500, "Reservation must be recorded before the request is sent.")

	binding.settle_tokens(500, 320)
	TEST_ASSERT_EQUAL(binding.tokens_reserved, 0, "Settling must release the reservation.")
	TEST_ASSERT_EQUAL(binding.tokens_settled, 320, "Settling must record what was actually spent.")

	binding.settle_tokens(9999, 0)
	TEST_ASSERT_EQUAL(binding.tokens_reserved, 0, "Over-releasing must clamp at zero rather than go negative.")

// ------------------------------------------------------------- the kill switch

/// Put the subsystem into a state where registration is allowed.
/proc/agent_test_arm_subsystem()
	var/list/saved = list(
		"enabled" = SSagent_npc.enabled,
		"globally_disabled" = SSagent_npc.globally_disabled,
	)
	SSagent_npc.enabled = TRUE
	SSagent_npc.globally_disabled = FALSE
	return saved

/proc/agent_test_restore_subsystem(list/saved, datum/agent_binding/binding)
	if(binding)
		SSagent_npc.unregister_pawn(binding, "test teardown")
	SSagent_npc.enabled = saved["enabled"]
	SSagent_npc.globally_disabled = saved["globally_disabled"]

/datum/unit_test/agent_npc_disable_all_revokes_bindings

/datum/unit_test/agent_npc_disable_all_revokes_bindings/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile)
	var/list/saved = agent_test_arm_subsystem()

	var/datum/agent_binding/binding = SSagent_npc.register_pawn(pawn, pawn.ai_controller)
	TEST_ASSERT_NOTNULL(binding, "register_pawn should return a binding when the subsystem is armed.")

	binding.mark_dirty("heard_speech")
	binding.pending = agent_test_request_for(binding)
	binding.state = AGENT_BINDING_PENDING
	SSagent_npc.in_flight += binding
	var/generation_before = binding.generation

	SSagent_npc.disable_all("unit test")

	TEST_ASSERT(SSagent_npc.globally_disabled, "disable_all must latch the subsystem off.")
	TEST_ASSERT_EQUAL(binding.state, AGENT_BINDING_DISABLED, "disable_all must disable every binding.")
	TEST_ASSERT(binding.generation > generation_before, "disable_all must advance the generation so in-flight replies die.")
	TEST_ASSERT_NULL(binding.pending, "disable_all must abandon the in-flight request.")
	TEST_ASSERT_EQUAL(length(SSagent_npc.in_flight), 0, "disable_all must empty the in-flight list.")
	TEST_ASSERT_EQUAL(length(binding.events), 0, "disable_all must discard buffered events.")

	agent_test_restore_subsystem(saved, binding)

/datum/unit_test/agent_npc_disable_all_clears_movement_target

/datum/unit_test/agent_npc_disable_all_clears_movement_target/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile)
	var/datum/ai_controller/controller = pawn.ai_controller
	if(!controller)
		controller = allocate(/datum/ai_controller, pawn)

	var/list/saved = agent_test_arm_subsystem()
	var/datum/agent_binding/binding = SSagent_npc.register_pawn(pawn, controller)
	TEST_ASSERT_NOTNULL(binding, "register_pawn should return a binding.")

	controller.set_movement_target(type, get_turf(pawn))
	TEST_ASSERT_NOTNULL(controller.current_movement_target, "Setup failed: the movement target was not set.")

	SSagent_npc.disable_all("unit test")

	TEST_ASSERT_NULL(controller.current_movement_target, "A disabled agent must not leave its pawn still walking somewhere.")

	agent_test_restore_subsystem(saved, binding)

/datum/unit_test/agent_npc_enable_all_reinstates_bindings

/datum/unit_test/agent_npc_enable_all_reinstates_bindings/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile)
	var/list/saved = agent_test_arm_subsystem()

	var/datum/agent_binding/binding = SSagent_npc.register_pawn(pawn, pawn.ai_controller)
	TEST_ASSERT_NOTNULL(binding, "register_pawn should return a binding.")

	SSagent_npc.disable_all("unit test")
	var/generation_while_disabled = binding.generation

	SSagent_npc.enable_all("unit test")

	TEST_ASSERT(!SSagent_npc.globally_disabled, "enable_all must unlatch the subsystem.")
	TEST_ASSERT_EQUAL(binding.state, AGENT_BINDING_IDLE, "enable_all must return bindings to idle.")
	TEST_ASSERT(binding.generation > generation_while_disabled, "Re-enabling must advance the generation again, so replies from the disabled window stay dead.")

	agent_test_restore_subsystem(saved, binding)

/datum/unit_test/agent_npc_registration_refused_while_disabled

/datum/unit_test/agent_npc_registration_refused_while_disabled/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile)
	var/list/saved = agent_test_arm_subsystem()
	SSagent_npc.globally_disabled = TRUE

	var/datum/agent_binding/binding = SSagent_npc.register_pawn(pawn, pawn.ai_controller)

	TEST_ASSERT_NULL(binding, "A disabled subsystem must refuse new registrations, not quietly accept them.")

	agent_test_restore_subsystem(saved, null)

// ------------------------------------------------- transport drain (review #1)

/datum/unit_test/agent_npc_abandoning_hands_transport_to_drain

/datum/unit_test/agent_npc_abandoning_hands_transport_to_drain/Run()
	var/datum/agent_binding/binding = agent_test_binding()
	binding.pending = agent_test_request_for(binding)
	binding.state = AGENT_BINDING_PENDING
	// Track the specific transport. The drain list is shared, so length deltas
	// are not a reliable assertion when other tests have left entries in it.
	var/datum/http_request/transport = binding.pending.transport

	binding.abandon_pending("test")

	TEST_ASSERT_NULL(binding.pending, "Abandoning must clear the pending request.")
	TEST_ASSERT(transport in SSagent_npc.draining, "The transport must be handed to the drain, not dropped. rust-g keeps the native job until its result is collected.")

	SSagent_npc.drain_pass()

	TEST_ASSERT(!(transport in SSagent_npc.draining), "drain_pass must collect a completed transport and release it.")

/datum/unit_test/agent_npc_request_destroy_warns_on_live_transport

/datum/unit_test/agent_npc_request_destroy_warns_on_live_transport/Run()
	var/datum/agent_binding/binding = agent_test_binding()
	var/datum/agent_request/request = agent_test_request_for(binding)

	TEST_ASSERT_NOTNULL(request.release_transport(), "release_transport must hand the transport over.")
	TEST_ASSERT_NULL(request.transport, "release_transport must clear the field so Destroy does not warn.")
	qdel(request)

// --------------------------------------------- identity across rebind (#3)

/datum/unit_test/agent_npc_stale_epoch_is_refused

/datum/unit_test/agent_npc_stale_epoch_is_refused/Run()
	var/datum/agent_binding/rebuilt = agent_test_binding("same-pawn", epoch = 7)
	var/datum/agent_request/request = agent_test_request_for(rebuilt, serial = 42)

	// A reply aimed at the previous binding for this same pawn. Generation is 1
	// on both, because a rebuilt binding starts fresh; only epoch separates them.
	var/list/echo = agent_test_echo(request)
	echo["binding_epoch"] = 6
	request.transport._raw_response = agent_test_raw(list("echo" = echo, "action" = agent_test_say_action()))

	var/datum/agent_response/response = agent_validate_response(request, rebuilt)

	TEST_ASSERT_EQUAL(response.refusal, AGENT_REFUSE_GENERATION, "A reply for a previous binding of the same pawn must be refused on epoch.")

/datum/unit_test/agent_npc_request_ids_are_unique_per_session

/datum/unit_test/agent_npc_request_ids_are_unique_per_session/Run()
	var/datum/agent_binding/first = agent_test_binding("same-pawn", epoch = 1)
	var/datum/agent_binding/rebuilt = agent_test_binding("same-pawn", epoch = 2)

	var/datum/agent_request/first_request = agent_test_request_for(first, serial = 1)
	var/datum/agent_request/second_request = agent_test_request_for(rebuilt, serial = 2)

	TEST_ASSERT_NOTEQUAL(first_request.request_id, second_request.request_id, "Request ids must come from a session counter, not from per-binding state that resets on rebind.")

// ------------------------------------------------------- usage bounds (#5)

/datum/unit_test/agent_npc_negative_token_usage_is_refused

/datum/unit_test/agent_npc_negative_token_usage_is_refused/Run()
	var/datum/agent_binding/binding = agent_test_binding()
	var/datum/agent_request/request = agent_test_request_for(binding)
	request.transport._raw_response = agent_test_raw(list(
		"echo" = agent_test_echo(request),
		"action" = agent_test_say_action(),
		"tokens_used" = -100,
	))

	var/datum/agent_response/response = agent_validate_response(request, binding)

	TEST_ASSERT_EQUAL(response.refusal, AGENT_REFUSE_SCHEMA, "Negative usage would subtract from round spend and must be refused.")

/datum/unit_test/agent_npc_absurd_token_usage_is_refused

/datum/unit_test/agent_npc_absurd_token_usage_is_refused/Run()
	var/datum/agent_binding/binding = agent_test_binding()
	var/datum/agent_request/request = agent_test_request_for(binding)
	request.transport._raw_response = agent_test_raw(list(
		"echo" = agent_test_echo(request),
		"action" = agent_test_say_action(),
		"tokens_used" = AGENT_MAX_TOKENS_PER_RESPONSE + 1,
	))

	var/datum/agent_response/response = agent_validate_response(request, binding)

	TEST_ASSERT_EQUAL(response.refusal, AGENT_REFUSE_SCHEMA, "Usage above the sanity ceiling must be refused.")

/datum/unit_test/agent_npc_budget_counts_live_reservations

/datum/unit_test/agent_npc_budget_counts_live_reservations/Run()
	var/saved_budget = SSagent_npc.round_token_budget
	var/saved_spent = SSagent_npc.tokens_spent
	var/saved_reserved = SSagent_npc.tokens_reserved_total

	SSagent_npc.round_token_budget = AGENT_TOKEN_ESTIMATE + 500
	SSagent_npc.tokens_spent = 0
	SSagent_npc.tokens_reserved_total = 0
	TEST_ASSERT(SSagent_npc.can_afford_request(), "One request must fit inside a budget larger than one estimate.")

	SSagent_npc.tokens_reserved_total = AGENT_TOKEN_ESTIMATE
	TEST_ASSERT(!SSagent_npc.can_afford_request(), "Admission must count live reservations. Counting only settled spend lets concurrent requests overshoot together.")

	SSagent_npc.round_token_budget = saved_budget
	SSagent_npc.tokens_spent = saved_spent
	SSagent_npc.tokens_reserved_total = saved_reserved

// ---------------------------------------------- pacing and quiescence (#7)

/datum/unit_test/agent_npc_result_does_not_schedule_another_request

/datum/unit_test/agent_npc_result_does_not_schedule_another_request/Run()
	var/datum/agent_binding/binding = agent_test_binding()

	binding.record_result(AGENT_RESULT_UNVERIFIED, "no executor yet")

	TEST_ASSERT(!binding.dirty, "Recording an outcome must not schedule another decision, or every reply produces a result which produces another reply.")
	TEST_ASSERT_EQUAL(length(binding.events), 1, "The outcome must still be buffered for the next real request.")

/datum/unit_test/agent_npc_pacing_floor_blocks_immediate_restart

/datum/unit_test/agent_npc_pacing_floor_blocks_immediate_restart/Run()
	var/datum/agent_binding/binding = agent_test_binding()
	binding.mark_dirty("heard_speech")

	TEST_ASSERT(binding.can_start_request(), "A dirty idle binding should be startable.")

	binding.next_request_at = world.time + AGENT_MIN_REQUEST_INTERVAL
	TEST_ASSERT(!binding.can_start_request(), "The pacing floor must hold a pawn back even while dirty.")

/datum/unit_test/agent_npc_wait_action_is_accepted

/datum/unit_test/agent_npc_wait_action_is_accepted/Run()
	var/list/validated = agent_validate_action(list("name" = "wait"))
	TEST_ASSERT_NOTNULL(validated, "wait must be a legal action, or a conversation can never settle.")
	TEST_ASSERT_EQUAL(validated["name"], "wait", "wait must survive validation intact.")

// ------------------------------------------------- failure recovery (#8)

/datum/unit_test/agent_npc_failed_submission_restores_events

/datum/unit_test/agent_npc_failed_submission_restores_events/Run()
	var/datum/agent_binding/binding = agent_test_binding()
	binding.mark_dirty("heard_speech")
	var/list/taken = binding.take_events()

	TEST_ASSERT_EQUAL(length(binding.events), 0, "Setup failed: take_events should have emptied the buffer.")

	binding.note_failure(taken)

	TEST_ASSERT_EQUAL(length(binding.events), 1, "A failed submission must put the trigger back, or a heard request vanishes during an outage.")
	TEST_ASSERT(binding.dirty, "A failed submission must leave the binding due for a retry.")
	TEST_ASSERT(binding.next_request_at > world.time, "A failed submission must back off rather than retry instantly.")

/datum/unit_test/agent_npc_repeated_failures_stop_rapid_retries

/datum/unit_test/agent_npc_repeated_failures_stop_rapid_retries/Run()
	var/datum/agent_binding/binding = agent_test_binding()

	for(var/i in 1 to AGENT_MAX_CONSECUTIVE_FAILURES)
		binding.mark_dirty("heard_speech")
		binding.note_failure(null)

	// Quiet, not dead. This test used to assert the binding went clean, which is
	// what made the ceiling permanent. The cooldown is what stops the hammering
	// now; staying dirty is what lets a later probe carry the trigger.
	// See agent_npc_breaker.dm for the probe side.
	TEST_ASSERT(!binding.can_start_request(), "A pawn past the retry ceiling must not be startable while its cooldown runs.")
	TEST_ASSERT(binding.next_request_at >= world.time + AGENT_BREAKER_COOLDOWN, "The ceiling must impose a long cooldown, or the pawn hammers a sidecar that is down.")

	binding.note_success()
	binding.next_request_at = 0
	binding.mark_dirty("heard_speech")
	TEST_ASSERT(binding.can_start_request(), "A success must clear the failure count so the pawn recovers.")

// --------------------------------------------- ownership on receipt (#2)

/datum/unit_test/agent_npc_deleted_pawn_loses_ownership

/datum/unit_test/agent_npc_deleted_pawn_loses_ownership/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile)
	// Simple animals ship no controller, and ownership requires both directions
	// of the pawn/controller link, so one has to be attached explicitly.
	var/datum/ai_controller/controller = pawn.ai_controller
	if(!controller)
		controller = allocate(/datum/ai_controller, pawn)

	var/list/saved = agent_test_arm_subsystem()
	var/datum/agent_binding/binding = SSagent_npc.register_pawn(pawn, controller)
	TEST_ASSERT_NOTNULL(binding, "register_pawn should return a binding.")

	TEST_ASSERT(binding.still_owns_pawn(), "A freshly registered live pawn must be owned.")

	qdel(pawn)

	TEST_ASSERT(binding.pawn_gone, "The deletion signal must flag the binding.")
	TEST_ASSERT(!binding.still_owns_pawn(), "A deleted pawn must not still be owned.")

	agent_test_restore_subsystem(saved, binding)

/datum/unit_test/agent_npc_valid_decision_dropped_when_pawn_gone

/datum/unit_test/agent_npc_valid_decision_dropped_when_pawn_gone/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile)
	var/datum/ai_controller/controller = pawn.ai_controller
	if(!controller)
		controller = allocate(/datum/ai_controller, pawn)

	var/list/saved = agent_test_arm_subsystem()
	var/datum/agent_binding/binding = SSagent_npc.register_pawn(pawn, controller)
	TEST_ASSERT_NOTNULL(binding, "register_pawn should return a binding.")

	var/datum/agent_response/response = new()
	response.ok = TRUE
	response.action = agent_test_say_action()

	// Prove the decision dispatches while the pawn is alive, so the assertion
	// after deletion cannot pass for some unrelated reason.
	var/refusals_before = SSagent_npc.refusal_counts[AGENT_REFUSE_PAWN] || 0
	SSagent_npc.handle_response(binding, response)
	TEST_ASSERT_EQUAL(SSagent_npc.refusal_counts[AGENT_REFUSE_PAWN] || 0, refusals_before, "Setup failed: a live, owned pawn should not have been refused.")
	TEST_ASSERT_EQUAL(length(binding.events), 1, "Setup failed: dispatching should have recorded an action result.")

	qdel(pawn)

	SSagent_npc.handle_response(binding, response)

	TEST_ASSERT_EQUAL(SSagent_npc.refusal_counts[AGENT_REFUSE_PAWN] || 0, refusals_before + 1, "A structurally valid decision must still be dropped when its pawn is gone. Weak references stop retention, not dispatch.")

	qdel(response)
	agent_test_restore_subsystem(saved, binding)

// ------------------------------------------- movement deregistration (#6)

/datum/unit_test/agent_npc_disable_all_deregisters_movement

/datum/unit_test/agent_npc_disable_all_deregisters_movement/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile)
	var/datum/ai_controller/controller = pawn.ai_controller
	if(!controller)
		controller = allocate(/datum/ai_controller, pawn)

	var/list/saved = agent_test_arm_subsystem()
	var/datum/agent_binding/binding = SSagent_npc.register_pawn(pawn, controller)
	TEST_ASSERT_NOTNULL(binding, "register_pawn should return a binding.")

	// Register movement without any current behavior, so behavior cleanup cannot
	// be what deregisters it. This is the case the movement-target test missed.
	controller.ai_movement.start_moving_towards(controller, get_turf(pawn))
	TEST_ASSERT(controller in controller.ai_movement.moving_controllers, "Setup failed: the controller was not registered for movement.")

	SSagent_npc.disable_all("unit test")

	TEST_ASSERT(!(controller in controller.ai_movement.moving_controllers), "Clearing the movement target is not enough. A registered controller keeps being processed until it is deregistered.")

	agent_test_restore_subsystem(saved, binding)
