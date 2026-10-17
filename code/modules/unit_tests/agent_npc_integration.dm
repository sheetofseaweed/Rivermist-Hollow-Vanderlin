/**
 * End-to-end DM to sidecar tests.
 *
 * Everything else drives agent_validate_response with an inert transport. These
 * run the real loop over real HTTP: start_request, rust-g, consume_pass. They
 * are the only place the wire is actually exercised.
 *
 * Compiled only when AGENT_NPC_INTEGRATION is defined, because they need a fake
 * sidecar listening. Run them with tools/agent_sidecar/integration_test.py,
 * which starts the sidecar and defines that symbol. They are deliberately not
 * part of the normal suite: a test that silently passes when its dependency is
 * missing is worse than no test.
 */
#ifdef AGENT_NPC_INTEGRATION

/// Must match the port the harness starts the sidecar on.
#define AGENT_INTEGRATION_BASE "http://127.0.0.1:1341"
/// Generous: a real round trip plus the deliberate delay faults.
#define AGENT_INTEGRATION_WAIT (25 SECONDS)

/// Arm a fault on the live sidecar. Query params, so no quoting to get wrong.
/proc/agent_integration_arm(fault)
	var/datum/http_request/request = new()
	request.prepare(RUSTG_HTTP_METHOD_POST, "[AGENT_INTEGRATION_BASE]/control?fault=[fault]&count=1", "", null)
	request.execute_blocking()
	var/datum/http_response/response = request.into_response()
	if(response.errored || text2num(response.status_code) != 200)
		return FALSE
	var/list/body = json_decode(response.body)
	// Confirm the sidecar armed what we asked for, rather than trusting a 200.
	return body["armed"] == fault

/// Point the subsystem at the fake sidecar and hand back a registered binding.
/datum/unit_test/proc/agent_integration_setup()
	SSagent_npc.enabled = TRUE
	SSagent_npc.globally_disabled = FALSE
	SSagent_npc.endpoint = "[AGENT_INTEGRATION_BASE]/decide"
	SSagent_npc.default_headers = list("Content-Type" = "application/json")
	SSagent_npc.round_token_budget = 0

	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = allocate(/mob/living/carbon/human/species/human/northern/agent_social)
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	controller.register_cooldown = 0
	controller.ensure_registered()
	return controller.binding

/// Drive one full request and return the terminal state that came out of it.
/datum/unit_test/proc/agent_integration_cycle(datum/agent_binding/binding)
	binding.next_request_at = 0
	binding.consecutive_failures = 0
	binding.mark_dirty("integration_probe", AGENT_EVENT_LOW)
	binding.take_events()
	binding.dirty = TRUE

	SSagent_npc.start_pass()
	if(!binding.pending)
		return "never_started"

	UNTIL_OR_TIMEOUT(binding.pending?.is_complete() || !binding.pending, AGENT_INTEGRATION_WAIT)
	SSagent_npc.consume_pass()

	if(!length(binding.events))
		return "no_result"
	var/list/last = binding.events[length(binding.events)]
	return last["detail"]?["state"] || last["event"]

/datum/unit_test/agent_integration_valid_roundtrip

/datum/unit_test/agent_integration_valid_roundtrip/Run()
	var/datum/agent_binding/binding = agent_integration_setup()
	TEST_ASSERT_NOTNULL(binding, "Setup failed: the pawn must register.")
	TEST_ASSERT(agent_integration_arm("none"), "Could not arm the sidecar. Is it running on [AGENT_INTEGRATION_BASE]?")

	var/state = agent_integration_cycle(binding)

	// With no handles offered the fake answers with speech, which the executor
	// actually says. Speech has a checkable outcome, so this is a real success,
	// not a bare "dispatched".
	TEST_ASSERT_EQUAL(state, AGENT_RESULT_SUCCEEDED, "A clean round trip should execute the decision. Got [state].")
	TEST_ASSERT_EQUAL(binding.requests_refused, 0, "A clean round trip should refuse nothing.")

	SSagent_npc.unregister_pawn(binding, "test teardown")

/datum/unit_test/agent_integration_malformed_body_is_refused

/datum/unit_test/agent_integration_malformed_body_is_refused/Run()
	var/datum/agent_binding/binding = agent_integration_setup()
	TEST_ASSERT(agent_integration_arm("malformed"), "Could not arm the sidecar.")

	agent_integration_cycle(binding)

	TEST_ASSERT_EQUAL(SSagent_npc.refusal_counts[AGENT_REFUSE_MALFORMED], 1, "Non-JSON must be refused across the wire, not just in the validator.")

	SSagent_npc.unregister_pawn(binding, "test teardown")

/datum/unit_test/agent_integration_oversized_body_is_refused

/datum/unit_test/agent_integration_oversized_body_is_refused/Run()
	var/datum/agent_binding/binding = agent_integration_setup()
	TEST_ASSERT(agent_integration_arm("oversized"), "Could not arm the sidecar.")

	agent_integration_cycle(binding)

	TEST_ASSERT_EQUAL(SSagent_npc.refusal_counts[AGENT_REFUSE_OVERSIZED], 1, "A two megabyte body must be rejected before it is parsed.")

	SSagent_npc.unregister_pawn(binding, "test teardown")

/datum/unit_test/agent_integration_http_error_is_refused

/datum/unit_test/agent_integration_http_error_is_refused/Run()
	var/datum/agent_binding/binding = agent_integration_setup()
	TEST_ASSERT(agent_integration_arm("http_500"), "Could not arm the sidecar.")

	agent_integration_cycle(binding)

	TEST_ASSERT(SSagent_npc.refusal_counts[AGENT_REFUSE_TRANSPORT] >= 1, "A 500 must be refused as a transport failure.")
	TEST_ASSERT(binding.consecutive_failures >= 1, "A transport failure must count toward the retry ceiling.")

	SSagent_npc.unregister_pawn(binding, "test teardown")

/datum/unit_test/agent_integration_stale_reply_is_refused

/datum/unit_test/agent_integration_stale_reply_is_refused/Run()
	var/datum/agent_binding/binding = agent_integration_setup()

	// Give the sidecar some history to reach back into, then make it answer with
	// an older request's identity.
	TEST_ASSERT(agent_integration_arm("none"), "Could not arm the sidecar.")
	agent_integration_cycle(binding)
	TEST_ASSERT(agent_integration_arm("stale"), "Could not arm the sidecar.")

	agent_integration_cycle(binding)

	TEST_ASSERT(SSagent_npc.refusal_counts[AGENT_REFUSE_UNKNOWN] >= 1, "A reply echoing an older request id must be refused across the wire.")

	SSagent_npc.unregister_pawn(binding, "test teardown")

/datum/unit_test/agent_integration_negative_usage_is_refused

/datum/unit_test/agent_integration_negative_usage_is_refused/Run()
	var/datum/agent_binding/binding = agent_integration_setup()
	TEST_ASSERT(agent_integration_arm("neg_tokens"), "Could not arm the sidecar.")
	var/spent_before = SSagent_npc.tokens_spent

	agent_integration_cycle(binding)

	TEST_ASSERT_EQUAL(SSagent_npc.refusal_counts[AGENT_REFUSE_SCHEMA], 1, "Negative reported usage must be refused.")
	TEST_ASSERT_EQUAL(SSagent_npc.tokens_spent, spent_before, "A refused response must not move the spend counter at all, let alone backwards.")

	SSagent_npc.unregister_pawn(binding, "test teardown")

/datum/unit_test/agent_integration_disable_survives_inflight_reply

/datum/unit_test/agent_integration_disable_survives_inflight_reply/Run()
	var/datum/agent_binding/binding = agent_integration_setup()
	TEST_ASSERT(agent_integration_arm("delay"), "Could not arm the sidecar.")

	binding.next_request_at = 0
	binding.dirty = TRUE
	SSagent_npc.start_pass()
	TEST_ASSERT_NOTNULL(binding.pending, "Setup failed: a request should be in flight.")

	// Pull the switch while the sidecar is still thinking.
	SSagent_npc.disable_all("integration test")

	TEST_ASSERT_NULL(binding.pending, "Disabling must abandon the in-flight request.")
	TEST_ASSERT_EQUAL(binding.state, AGENT_BINDING_DISABLED, "Disabling must disable the binding.")

	// The transport is still alive out there. Drain it so rust-g can free the job.
	UNTIL_OR_TIMEOUT(!length(SSagent_npc.draining), AGENT_INTEGRATION_WAIT)
	SSagent_npc.drain_pass()

	TEST_ASSERT_EQUAL(length(SSagent_npc.draining), 0, "The abandoned transport must be drained, not leaked.")

	SSagent_npc.globally_disabled = FALSE
	SSagent_npc.unregister_pawn(binding, "test teardown")

#undef AGENT_INTEGRATION_BASE
#undef AGENT_INTEGRATION_WAIT

#endif
