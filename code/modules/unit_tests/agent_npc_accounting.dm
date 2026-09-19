// Reservation lifecycle and outstanding-work bounds.
//
// Written against the defects the status review found: a reservation released
// from the binding ledger but left on the global one, and an admission check
// that counts live requests while ignoring work still running at the provider.

/// A binding plus a started request, without touching the network.
/datum/unit_test/proc/agent_accounting_setup()
	var/datum/agent_binding/binding = agent_test_binding("acct-pawn")
	var/datum/agent_request/request = agent_test_request_for(binding)
	SSagent_npc.open_reservation(binding, request, AGENT_TOKEN_ESTIMATE)
	binding.pending = request
	binding.state = AGENT_BINDING_PENDING
	return binding

/datum/unit_test/agent_npc_abandon_releases_the_global_reservation

/datum/unit_test/agent_npc_abandon_releases_the_global_reservation/Run()
	var/global_before = SSagent_npc.tokens_reserved_total
	var/datum/agent_binding/binding = agent_accounting_setup()

	TEST_ASSERT_EQUAL(SSagent_npc.tokens_reserved_total, global_before + AGENT_TOKEN_ESTIMATE, "Starting a request must reserve against the global ledger.")
	TEST_ASSERT_EQUAL(binding.tokens_reserved, AGENT_TOKEN_ESTIMATE, "Starting a request must reserve against the binding ledger.")

	binding.abandon_pending("test")

	// The defect: the binding ledger was released and the global one was not,
	// so every timeout, supersession and kill-switch press leaked admission.
	TEST_ASSERT_EQUAL(SSagent_npc.tokens_reserved_total, global_before, "Abandoning must release the GLOBAL reservation, not only the binding's. Leaking here eventually starves admission with no live requests.")
	TEST_ASSERT_EQUAL(binding.tokens_reserved, 0, "Abandoning must release the binding reservation.")

	qdel(binding)

/datum/unit_test/agent_npc_abandoned_work_is_recorded_as_unsettled

/datum/unit_test/agent_npc_abandoned_work_is_recorded_as_unsettled/Run()
	var/unsettled_before = SSagent_npc.tokens_unsettled
	var/datum/agent_binding/binding = agent_accounting_setup()

	binding.abandon_pending("test")

	// The provider may still bill work we walked away from. Releasing the hold
	// is right; pretending it cost nothing is not.
	TEST_ASSERT_EQUAL(SSagent_npc.tokens_unsettled, unsettled_before + AGENT_TOKEN_ESTIMATE, "Abandoned work must be recorded as unsettled rather than silently vanishing from both ledgers.")

	qdel(binding)

/datum/unit_test/agent_npc_reservation_closes_exactly_once

/datum/unit_test/agent_npc_reservation_closes_exactly_once/Run()
	var/global_before = SSagent_npc.tokens_reserved_total
	var/spent_before = SSagent_npc.tokens_spent

	var/datum/agent_binding/binding = agent_test_binding("acct-once")
	var/datum/agent_request/request = agent_test_request_for(binding)
	SSagent_npc.open_reservation(binding, request, AGENT_TOKEN_ESTIMATE)

	TEST_ASSERT(SSagent_npc.close_reservation(binding, request, 500), "The first close must perform the release.")
	TEST_ASSERT(!SSagent_npc.close_reservation(binding, request, 500), "A second close must be a no-op, or a reservation released twice credits the ledger for tokens that were never held.")

	TEST_ASSERT_EQUAL(SSagent_npc.tokens_reserved_total, global_before, "The global ledger must end where it started.")
	TEST_ASSERT_EQUAL(SSagent_npc.tokens_spent, spent_before + 500, "Spend must be recorded once, not twice.")

	qdel(request)
	qdel(binding)

/datum/unit_test/agent_npc_outstanding_work_bounds_admission

/datum/unit_test/agent_npc_outstanding_work_bounds_admission/Run()
	var/list/saved_flight = SSagent_npc.in_flight.Copy()
	var/list/saved_drain = SSagent_npc.draining.Copy()
	SSagent_npc.in_flight.Cut()
	SSagent_npc.draining.Cut()

	TEST_ASSERT(SSagent_npc.has_outstanding_capacity(), "An idle subsystem must have capacity.")

	// Nothing is in flight, so max_concurrent alone would happily admit more.
	// These are abandoned transports still running at the provider.
	for(var/i in 1 to AGENT_MAX_OUTSTANDING)
		SSagent_npc.draining[new /datum/http_request()] = world.time + AGENT_DRAIN_TIMEOUT

	TEST_ASSERT_EQUAL(length(SSagent_npc.in_flight), 0, "Setup failed: nothing should be in flight.")
	TEST_ASSERT(!SSagent_npc.has_outstanding_capacity(), "Draining transports are real outstanding work and must count against admission. Counting only in_flight lets supersession free capacity that was never actually freed.")

	for(var/datum/http_request/transport as anything in SSagent_npc.draining)
		qdel(transport)
	SSagent_npc.draining.Cut()
	SSagent_npc.in_flight.Cut()
	for(var/entry in saved_flight)
		SSagent_npc.in_flight += entry
	for(var/entry in saved_drain)
		SSagent_npc.draining[entry] = saved_drain[entry]

/datum/unit_test/agent_npc_timeouts_form_a_ladder

/datum/unit_test/agent_npc_timeouts_form_a_ladder/Run()
	// The ordering that failed on 2026-09-17: the sidecar allowed the model 30s
	// against a 15s deadline, so a good answer arrived after DM had stopped
	// listening. The sidecar logged a 200 and the game showed nothing.
	TEST_ASSERT(AGENT_TRANSPORT_TIMEOUT_SECONDS * 10 < AGENT_DEFAULT_DEADLINE, "rust-g must give up before the deadline. Above it, DM abandons a call that is still running and drains the answer unread.")

	// The sidecar budgets its own call from the deadline_ds it is sent, less a
	// margin for parsing and the trip home. Too tight a deadline leaves none.
	TEST_ASSERT(AGENT_DEFAULT_DEADLINE >= (10 SECONDS), "The deadline must leave the sidecar a workable budget once its own margin is taken off.")

/datum/unit_test/agent_npc_transport_carries_a_native_timeout

/datum/unit_test/agent_npc_transport_carries_a_native_timeout/Run()
	var/datum/agent_binding/binding = agent_test_binding("acct-timeout")
	var/datum/agent_request/request = new()
	request.prepare(binding, "test-session", 1, list(), list(), null)

	// Guarded step by step on purpose. A runtime inside Run() aborts the proc and
	// the test is still recorded as passing, so an unguarded decode of a null
	// would make this test vacuous exactly when it should be failing.
	var/raw_options = request.build_transport_options()
	TEST_ASSERT_NOTNULL(raw_options, "The request must send transport options at all.")

	var/list/options = json_decode(raw_options)
	TEST_ASSERT_NOTNULL(options, "Transport options must be decodable JSON.")

	// Without this, a stalled provider is bounded only by our own drain give-up,
	// and the native job keeps running behind it.
	TEST_ASSERT_EQUAL(options["timeout_seconds"], AGENT_TRANSPORT_TIMEOUT_SECONDS, "The request must carry rust-g's own timeout, not rely solely on the DM-side deadline.")

	qdel(request)
	qdel(binding)
