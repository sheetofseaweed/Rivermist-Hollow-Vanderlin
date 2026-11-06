// The failure circuit breaker.
//
// Written against a defect the telemetry exposed in a live round: at the failure
// limit can_start_request() refused forever. No request could start, so none
// could succeed, so the failure count never fell. A pawn that lost three
// requests to a struggling provider was mute for the rest of the round, and
// nothing short of the admin Poke verb brought it back.

/// A binding parked at the failure limit, dirty and otherwise ready to send.
/datum/unit_test/proc/agent_broken_binding(pawn_id = "breaker-pawn")
	var/datum/agent_binding/binding = agent_test_binding(pawn_id)
	binding.state = AGENT_BINDING_IDLE
	binding.consecutive_failures = AGENT_MAX_CONSECUTIVE_FAILURES
	binding.set_dirty()
	return binding

/datum/unit_test/agent_npc_breaker_probes_after_its_cooldown

/datum/unit_test/agent_npc_breaker_probes_after_its_cooldown/Run()
	var/datum/agent_binding/binding = agent_broken_binding()

	TEST_ASSERT(binding.is_probe(), "Setup failed: the binding must be at the failure limit.")
	TEST_ASSERT(binding.dirty, "Setup failed: the binding must have work waiting.")

	binding.next_request_at = world.time + 100
	TEST_ASSERT(!binding.can_start_request(), "A broken binding must wait out its cooldown before probing.")

	binding.next_request_at = 0

	// The regression. This assertion failed for every value of the cooldown
	// before the breaker existed, because the block was on the failure count.
	TEST_ASSERT(binding.can_start_request(), "Once the cooldown has passed, a broken binding must be allowed one probe. Blocking on the failure count alone can never lift: no request can start, so none can succeed, so the count never falls.")

	qdel(binding)

/datum/unit_test/agent_npc_breaker_keeps_the_trigger_for_the_probe

/datum/unit_test/agent_npc_breaker_keeps_the_trigger_for_the_probe/Run()
	var/datum/agent_binding/binding = agent_test_binding("breaker-trigger")
	binding.state = AGENT_BINDING_IDLE
	binding.consecutive_failures = AGENT_MAX_CONSECUTIVE_FAILURES - 1
	binding.clear_dirty()

	TEST_ASSERT(!binding.is_probe(), "Setup failed: the binding must start below the limit.")

	// The failure that opens the breaker, carrying the events that never got sent.
	binding.note_failure(list(list("event" = "player_spoke", "urgency" = AGENT_EVENT_LOW, "detail" = null)))

	TEST_ASSERT(binding.is_probe(), "One more failure must reach the limit and open the breaker.")

	// Both matter. Clearing dirty means the probe never fires however long we
	// wait; losing the events means it fires having forgotten what prompted it.
	TEST_ASSERT(binding.dirty, "Opening the breaker must leave work pending, or the probe has nothing to trigger it.")
	TEST_ASSERT_EQUAL(length(binding.events), 1, "The unanswered trigger must be restored, so the probe carries what the player said.")

	qdel(binding)

/datum/unit_test/agent_npc_breaker_cooldown_grows_and_caps

/datum/unit_test/agent_npc_breaker_cooldown_grows_and_caps/Run()
	var/datum/agent_binding/binding = agent_test_binding("breaker-cooldown")

	binding.consecutive_failures = AGENT_MAX_CONSECUTIVE_FAILURES
	TEST_ASSERT_EQUAL(binding.breaker_cooldown(), AGENT_BREAKER_COOLDOWN, "The first probe must wait exactly one cooldown.")

	binding.consecutive_failures = AGENT_MAX_CONSECUTIVE_FAILURES + 1
	TEST_ASSERT_EQUAL(binding.breaker_cooldown(), AGENT_BREAKER_COOLDOWN * 2, "Each failed probe must push the next one further out, rather than hammering a provider that is down.")

	// Without a ceiling a long outage parks the pawn for longer than the round.
	binding.consecutive_failures = AGENT_MAX_CONSECUTIVE_FAILURES + 1000
	TEST_ASSERT_EQUAL(binding.breaker_cooldown(), AGENT_BREAKER_COOLDOWN_MAX, "The growing cooldown must cap, or a long outage silences the pawn permanently by another route.")

	qdel(binding)

/datum/unit_test/agent_npc_breaker_closes_on_a_reply

/datum/unit_test/agent_npc_breaker_closes_on_a_reply/Run()
	var/datum/agent_binding/binding = agent_broken_binding("breaker-close")

	TEST_ASSERT(binding.is_probe(), "Setup failed: the breaker must be open.")

	binding.note_success()

	TEST_ASSERT(!binding.is_probe(), "A reply must close the breaker and return the pawn to ordinary pacing.")
	TEST_ASSERT_EQUAL(binding.consecutive_failures, 0, "A reply must clear the failure count, not merely reduce it.")

	qdel(binding)

/datum/unit_test/agent_npc_reinstate_closes_the_breaker

/datum/unit_test/agent_npc_reinstate_closes_the_breaker/Run()
	var/datum/agent_binding/binding = agent_broken_binding("breaker-reinstate")
	binding.next_request_at = world.time + AGENT_BREAKER_COOLDOWN_MAX
	binding.revoke("test")

	TEST_ASSERT_EQUAL(binding.state, AGENT_BINDING_DISABLED, "Setup failed: revoke must disable the binding.")

	TEST_ASSERT(binding.reinstate(), "A revoked binding with a live pawn reference must reinstate.")

	// An operator turning agents back on means a fresh start. Leaving the pawn
	// parked behind a ten minute cooldown makes the kill switch look one-way.
	TEST_ASSERT(!binding.is_probe(), "Reinstating must close the breaker.")
	TEST_ASSERT_EQUAL(binding.next_request_at, 0, "Reinstating must clear the cooldown, not only the failure count.")

	qdel(binding)

/datum/unit_test/agent_npc_probe_is_counted_not_timed

/datum/unit_test/agent_npc_probe_is_counted_not_timed/Run()
	TEST_ASSERT_NOTNULL(SSagent_npc.telemetry, "Setup failed: the subsystem must hold a telemetry datum.")
	var/datum/agent_stat/waits = SSagent_npc.telemetry.queue_wait
	TEST_ASSERT_NOTNULL(waits, "Setup failed: telemetry must hold a queue wait stat.")

	var/probes_before = SSagent_npc.telemetry.breaker_probes
	var/waits_before = waits.count

	var/datum/agent_binding/healthy = agent_test_binding("breaker-healthy")
	healthy.set_dirty()
	SSagent_npc.note_request_started(healthy)

	TEST_ASSERT_EQUAL(waits.count, waits_before + 1, "An ordinary request must be timed as a queue wait.")
	TEST_ASSERT_EQUAL(SSagent_npc.telemetry.breaker_probes, probes_before, "An ordinary request is not a probe.")

	var/datum/agent_binding/broken = agent_broken_binding("breaker-probe-count")
	SSagent_npc.note_request_started(broken)

	// A probe waits out the cooldown, which is minutes. Timing it would drag the
	// pacing figure so far that the statistic stops answering its own question.
	TEST_ASSERT_EQUAL(SSagent_npc.telemetry.breaker_probes, probes_before + 1, "A probe must be counted.")
	TEST_ASSERT_EQUAL(waits.count, waits_before + 1, "A probe must NOT be timed as a queue wait.")

	qdel(healthy)
	qdel(broken)

/datum/unit_test/agent_npc_expiries_are_counted_apart_from_refusals

/datum/unit_test/agent_npc_expiries_are_counted_apart_from_refusals/Run()
	var/list/saved_flight = SSagent_npc.in_flight.Copy()
	SSagent_npc.in_flight.Cut()

	var/datum/agent_binding/binding = agent_test_binding("breaker-expiry")
	var/datum/agent_request/request = agent_test_request_for(binding)
	request.deadline = world.time - 1
	binding.pending = request
	binding.state = AGENT_BINDING_PENDING
	SSagent_npc.in_flight += binding

	TEST_ASSERT(request.is_expired(), "Setup failed: the request must be past its deadline.")

	SSagent_npc.expire_pass()

	// The defect this reads against: a timeout never reaches handle_response, so
	// requests_refused stayed at 0 while every request was being lost. The status
	// line read "requests 8 refused 0" for a pawn that had gone completely silent.
	TEST_ASSERT_EQUAL(binding.requests_expired, 1, "A request that never came back must be counted on its pawn.")
	TEST_ASSERT_EQUAL(binding.requests_refused, 0, "An expiry is not a refusal; counting it as one hides which of the two is happening.")

	for(var/datum/http_request/transport as anything in SSagent_npc.draining)
		qdel(transport)
	SSagent_npc.draining.Cut()
	SSagent_npc.in_flight.Cut()
	for(var/entry in saved_flight)
		SSagent_npc.in_flight += entry

	qdel(binding)
