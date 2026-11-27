// Measurement. Nothing here talks to a sidecar or spends a token.
//
// The awkward one is the null-telemetry test. A runtime inside Run() aborts the
// proc and the test is still recorded as passing, so "does this runtime?" cannot
// be asserted directly. It is wrapped in try/catch instead, which in BYOND does
// catch runtime errors, and the flag is asserted after the fact.

/datum/unit_test/agent_npc_stat_refuses_non_numbers

/datum/unit_test/agent_npc_stat_refuses_non_numbers/Run()
	var/datum/agent_stat/stat = new()

	TEST_ASSERT(stat.record(40), "A number must be recorded.")
	TEST_ASSERT(!stat.record(null), "A null must be refused, not coerced.")
	TEST_ASSERT(!stat.record("later"), "Text must be refused, not coerced.")

	// In DM `null < 5` is true and `sum += null` is silent, so one bad caller
	// would quietly drag the range to zero and never be noticed.
	TEST_ASSERT_EQUAL(stat.count, 1, "Refused values must not be counted.")
	TEST_ASSERT_EQUAL(stat.lowest, 40, "A refused null must not become the new minimum.")
	TEST_ASSERT_EQUAL(stat.sum, 40, "A refused value must not be added to the total.")

	qdel(stat)

/datum/unit_test/agent_npc_stat_tracks_its_range

/datum/unit_test/agent_npc_stat_tracks_its_range/Run()
	var/datum/agent_stat/stat = new()

	// The first sample must set both ends. lowest starts at 0, so without an
	// explicit first-sample case every minimum below would read as 0.
	stat.record(7)
	TEST_ASSERT_EQUAL(stat.lowest, 7, "The first sample must become the minimum, not leave it at the initial 0.")
	TEST_ASSERT_EQUAL(stat.highest, 7, "The first sample must become the maximum.")

	stat.record(500)
	stat.record(100)

	TEST_ASSERT_EQUAL(stat.lowest, 7, "The minimum must survive later, larger samples.")
	TEST_ASSERT_EQUAL(stat.highest, 500, "The maximum must be the largest sample seen.")
	TEST_ASSERT_EQUAL(stat.count, 3, "Every accepted sample must be counted.")
	TEST_ASSERT_EQUAL(stat.mean(), 607 / 3, "The mean must be the total over the count.")

	qdel(stat)

/datum/unit_test/agent_npc_stat_ring_is_bounded

/datum/unit_test/agent_npc_stat_ring_is_bounded/Run()
	var/datum/agent_stat/stat = new()
	var/overflow = AGENT_STAT_SAMPLES + 5

	for(var/i in 1 to overflow)
		stat.record(i)

	TEST_ASSERT_NOTNULL(stat.samples, "The sample ring must exist.")
	TEST_ASSERT_EQUAL(length(stat.samples), AGENT_STAT_SAMPLES, "The ring must stay bounded, or a long round grows it without limit.")

	// Lifetime figures must outlive the ring. Deriving them from the samples
	// would silently make them "recent" rather than "for the round".
	TEST_ASSERT_EQUAL(stat.count, overflow, "The lifetime count must not be capped by the ring size.")
	TEST_ASSERT_EQUAL(stat.highest, overflow, "The lifetime maximum must not be capped by the ring size.")
	TEST_ASSERT_EQUAL(stat.lowest, 1, "The lifetime minimum must survive being dropped from the ring.")

	TEST_ASSERT_EQUAL(stat.samples[1], 6, "The ring must drop oldest first, keeping recent samples.")
	TEST_ASSERT_EQUAL(stat.samples[length(stat.samples)], overflow, "The newest sample must be retained.")

	qdel(stat)

/datum/unit_test/agent_npc_stat_percentile_is_nearest_rank

/datum/unit_test/agent_npc_stat_percentile_is_nearest_rank/Run()
	var/datum/agent_stat/stat = new()

	TEST_ASSERT_EQUAL(stat.percentile(0.95), 0, "An empty stat must report 0 rather than runtime on an empty list.")

	// Deliberately out of order: the percentile must sort, not index arrival order.
	for(var/value in list(5, 1, 9, 3, 7, 2, 10, 4, 8, 6))
		stat.record(value)

	TEST_ASSERT_EQUAL(stat.percentile(0.5), 5, "The median of 1..10 is the 5th ranked value.")
	TEST_ASSERT_EQUAL(stat.percentile(0.95), 10, "The 95th percentile of 1..10 is the 10th ranked value.")
	TEST_ASSERT_EQUAL(stat.percentile(0.1), 1, "The 10th percentile of 1..10 is the 1st ranked value.")

	qdel(stat)

/datum/unit_test/agent_npc_queue_clock_keeps_the_oldest_trigger

/datum/unit_test/agent_npc_queue_clock_keeps_the_oldest_trigger/Run()
	var/datum/agent_binding/binding = agent_test_binding("tele-queue")

	TEST_ASSERT_EQUAL(binding.dirty_since, 0, "Setup failed: a fresh binding must be clean.")

	binding.mark_dirty("first")
	TEST_ASSERT(binding.dirty, "Setup failed: marking must make the binding dirty.")
	TEST_ASSERT(binding.dirty_since > 0, "Becoming dirty must stamp the wait clock.")

	// A distinctly older stamp, so a re-stamp is unmistakable without waiting
	// for world.time to move inside a test.
	binding.dirty_since = 12345
	binding.mark_dirty("second")

	// Re-stamping would measure the newest trigger. What matters is how long the
	// oldest unserved one has waited, which is the number a player feels.
	TEST_ASSERT_EQUAL(binding.dirty_since, 12345, "A second event must not restart the wait clock while the first is still unserved.")

	qdel(binding)

/datum/unit_test/agent_npc_queue_clock_clears_when_sent

/datum/unit_test/agent_npc_queue_clock_clears_when_sent/Run()
	var/datum/agent_binding/binding = agent_test_binding("tele-clear")

	binding.mark_dirty("trigger")
	TEST_ASSERT(binding.dirty_since > 0, "Setup failed: the clock must be running.")

	binding.take_events()

	// take_events() is what clears the clock, and start_request reads it just
	// before calling that. If it were not cleared, the next wait would be
	// measured from a trigger that has already been served.
	TEST_ASSERT_EQUAL(binding.dirty_since, 0, "Taking the events for sending must stop the wait clock.")
	TEST_ASSERT_EQUAL(binding.queued_time(), 0, "A cleared clock must report no wait.")

	qdel(binding)

/datum/unit_test/agent_npc_telemetry_tolerates_being_absent

/datum/unit_test/agent_npc_telemetry_tolerates_being_absent/Run()
	var/datum/agent_telemetry/saved = SSagent_npc.telemetry
	SSagent_npc.telemetry = null

	var/caught = FALSE
	try
		SSagent_npc.note_decision(10, 100)
		SSagent_npc.note_queue_wait(10)
		SSagent_npc.note_observation_age(10)
		SSagent_npc.note_chain_depth(2)
		SSagent_npc.note_action("say")
		SSagent_npc.note_result(AGENT_RESULT_SUCCEEDED)
	catch
		caught = TRUE

	// Restored before asserting: a failed assertion returns from Run(), so
	// cleanup placed after it would never happen and would poison later tests.
	SSagent_npc.telemetry = saved

	// `telemetry?.round_trip.record(x)` still runtimes when telemetry is null,
	// because the null-conditional guards only the access it is written on.
	TEST_ASSERT(!caught, "Recording must tolerate an absent telemetry rather than runtime. A runtime here would abort a real fire loop mid-pass.")

/datum/unit_test/agent_npc_chain_depth_counts_only_real_chains

/datum/unit_test/agent_npc_chain_depth_counts_only_real_chains/Run()
	TEST_ASSERT_NOTNULL(SSagent_npc.telemetry, "Setup failed: the subsystem must hold a telemetry datum.")
	var/datum/agent_stat/depth = SSagent_npc.telemetry.chain_depth
	TEST_ASSERT_NOTNULL(depth, "Setup failed: telemetry must hold a chain depth stat.")

	var/datum/agent_binding/binding = agent_test_binding("tele-chain")
	var/before = depth.count

	// Never began, so there is no chain to measure. Recording a zero here would
	// drag the average down with interactions that never happened.
	binding.end_continuation()
	TEST_ASSERT_EQUAL(depth.count, before, "Ending a chain that never started must record nothing.")

	binding.begin_interaction()
	binding.end_continuation()
	TEST_ASSERT_EQUAL(depth.count, before, "A chain that took no step must record nothing.")

	binding.begin_interaction()
	binding.continuation_budget = AGENT_CONTINUATION_BUDGET - 2
	binding.end_continuation()

	TEST_ASSERT_EQUAL(depth.count, before + 1, "A chain that ran must be recorded exactly once.")
	TEST_ASSERT_EQUAL(depth.samples[length(depth.samples)], 2, "The recorded depth must be the steps taken, not the budget left.")

	qdel(binding)

/datum/unit_test/agent_npc_outcomes_are_counted

/datum/unit_test/agent_npc_outcomes_are_counted/Run()
	TEST_ASSERT_NOTNULL(SSagent_npc.telemetry, "Setup failed: the subsystem must hold a telemetry datum.")
	var/list/counts = SSagent_npc.telemetry.result_counts
	TEST_ASSERT_NOTNULL(counts, "Setup failed: telemetry must hold an outcome list.")

	var/datum/agent_binding/binding = agent_test_binding("tele-outcome")
	var/before = counts[AGENT_RESULT_SUCCEEDED] || 0

	binding.record_result(AGENT_RESULT_SUCCEEDED, "test")
	TEST_ASSERT_EQUAL(counts[AGENT_RESULT_SUCCEEDED], before + 1, "Every terminal state must be counted, or the outcome mix is guesswork.")

	// A revoked binding records nothing, so its outcomes must not be counted
	// either. Counting them would report work that never reached the pawn.
	binding.state = AGENT_BINDING_DISABLED
	binding.record_result(AGENT_RESULT_SUCCEEDED, "test")
	TEST_ASSERT_EQUAL(counts[AGENT_RESULT_SUCCEEDED], before + 1, "A disabled binding rejects the result, so it must not be counted.")

	qdel(binding)

/datum/unit_test/agent_npc_silent_usage_is_not_averaged_in

/datum/unit_test/agent_npc_silent_usage_is_not_averaged_in/Run()
	var/datum/agent_telemetry/measured = new()

	measured.note_decision(50, 800)
	measured.note_decision(60, 0)

	TEST_ASSERT_EQUAL(measured.decisions, 2, "Every consumed reply counts as a decision, reported usage or not.")
	TEST_ASSERT_EQUAL(measured.round_trip.count, 2, "Every consumed reply costs wall time and must be timed.")

	// A provider that stays silent about usage must not be recorded as a free
	// decision, or the cost per decision reads far lower than it really is.
	TEST_ASSERT_EQUAL(measured.tokens.count, 1, "A decision that reported no usage must not be recorded as costing zero.")
	TEST_ASSERT_EQUAL(measured.tokens.mean(), 800, "The mean cost must be over the decisions that actually reported.")

	qdel(measured)
