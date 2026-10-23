// Spending bounds: the agent-to-agent cap and each NPC's share of the unclear-speech budget.

/// Two bound agent NPCs, the second registered, for the first to hear.
/datum/unit_test/proc/agent_test_agent_pair()
	var/mob/living/carbon/human/species/human/northern/agent_social/listener = agent_test_bound_pawn()
	var/mob/living/carbon/human/species/human/northern/agent_social/talker = agent_test_bound_pawn()
	return list(listener, talker)

/datum/unit_test/agent_npc_agent_exchanges_are_capped

/datum/unit_test/agent_npc_agent_exchanges_are_capped/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/pair = agent_test_agent_pair()
	var/mob/living/carbon/human/species/human/northern/agent_social/listener = pair[1]
	var/mob/living/carbon/human/species/human/northern/agent_social/talker = pair[2]
	var/datum/ai_controller/agent_social/controller = listener.ai_controller
	var/datum/ai_controller/agent_social/talker_controller = talker.ai_controller
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the listener must be bound.")
	TEST_ASSERT_NOTNULL(SSagent_npc.bindings["[REF(talker)]"], "Setup failed: the talker must be a registered agent.")
	TEST_ASSERT_NOTNULL(SSagent_npc.telemetry, "Setup failed: the subsystem must hold telemetry.")
	controller.binding.take_events()
	var/capped_before = SSagent_npc.telemetry.agent_exchanges_capped

	// Distinct lines, so the duplicate check cannot be what stops them.
	var/list/routes = list()
	for(var/i in 1 to AGENT_MAX_AGENT_EXCHANGES + 1)
		var/text = "line [i]"
		routes += controller.route_speech(AGENT_SPEECH_DIRECTED, "Anna", text, list("speaker" = "Anna", "text" = text), TRUE, talker)

	var/capped_after = SSagent_npc.telemetry.agent_exchanges_capped
	SSagent_npc.unregister_pawn(talker_controller.binding, "test teardown")

	for(var/i in 1 to AGENT_MAX_AGENT_EXCHANGES)
		TEST_ASSERT_EQUAL(routes[i], "sent", "Exchange [i] between two agents is background life and must be answered.")

	// Past the cap the line waits, rather than buying a decision that buys the other agent one.
	TEST_ASSERT_EQUAL(routes[AGENT_MAX_AGENT_EXCHANGES + 1], "capped", "Past the cap, another agent's line must be held back.")
	TEST_ASSERT_EQUAL(capped_after, capped_before + 1, "A held-back line must be counted, so an operator can see NPCs were left talking.")

	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_agent_cap_is_per_speaker

/datum/unit_test/agent_npc_agent_cap_is_per_speaker/Run()
	var/datum/agent_binding/binding = agent_test_binding("cap-per-speaker")
	var/mob/living/carbon/human/first = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/second = allocate(/mob/living/carbon/human)

	for(var/i in 1 to AGENT_MAX_AGENT_EXCHANGES)
		binding.note_agent_exchange(first)

	TEST_ASSERT(!binding.agent_exchange_allowed(first), "Setup failed: the first speaker should have used its exchanges.")
	// One chatty pair must not silence every other agent in the room.
	TEST_ASSERT(binding.agent_exchange_allowed(second), "A different agent must have its own count.")

	qdel(binding)

/datum/unit_test/agent_npc_agent_exchanges_lapse_after_quiet

/datum/unit_test/agent_npc_agent_exchanges_lapse_after_quiet/Run()
	var/datum/agent_binding/binding = agent_test_binding("cap-lapse")
	var/mob/living/carbon/human/talker = allocate(/mob/living/carbon/human)

	for(var/i in 1 to AGENT_MAX_AGENT_EXCHANGES)
		binding.note_agent_exchange(talker)
	TEST_ASSERT(!binding.agent_exchange_allowed(talker), "Setup failed: the talker should have used its exchanges.")

	var/list/entry = binding.agent_exchanges[WEAKREF(talker)]
	TEST_ASSERT_NOTNULL(entry, "Setup failed: the exchange should be recorded.")
	entry[2] = world.time - AGENT_AGENT_EXCHANGE_WINDOW - 1

	// Two NPCs may chat again later; the cap stops a runaway, not a friendship.
	TEST_ASSERT(binding.agent_exchange_allowed(talker), "After a quiet spell, two agents must be allowed to talk again.")

	binding.note_agent_exchange(talker)
	var/list/fresh = binding.agent_exchanges[WEAKREF(talker)]
	TEST_ASSERT_EQUAL(fresh[1], 1, "A lapsed count must start again from one, not continue.")

	qdel(binding)

/datum/unit_test/agent_npc_npc_chatter_cannot_reset_the_cap

/datum/unit_test/agent_npc_npc_chatter_cannot_reset_the_cap/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/pair = agent_test_agent_pair()
	var/mob/living/carbon/human/species/human/northern/agent_social/listener = pair[1]
	var/mob/living/carbon/human/species/human/northern/agent_social/talker = pair[2]
	var/datum/ai_controller/agent_social/controller = listener.ai_controller
	var/datum/ai_controller/agent_social/talker_controller = talker.ai_controller
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the listener must be bound.")
	var/mob/living/carbon/human/bystander_npc = allocate(/mob/living/carbon/human)
	TEST_ASSERT_NULL(bystander_npc.client, "Setup failed: the bystander must be clientless.")

	for(var/i in 1 to AGENT_MAX_AGENT_EXCHANGES)
		controller.binding.note_agent_exchange(talker)

	// A clientless NPC's line must not reset the count, or any talkative NPC reopens the loop.
	controller.route_speech(AGENT_SPEECH_DIRECTED, "Guard", "move along", list("speaker" = "Guard", "text" = "move along"), FALSE, bystander_npc)
	var/still_capped = !controller.binding.agent_exchange_allowed(talker)
	SSagent_npc.unregister_pawn(talker_controller.binding, "test teardown")

	TEST_ASSERT(still_capped, "Speech from a clientless NPC must not reset the agent-to-agent cap. Only a player may.")

	// The reset itself. A unit test cannot give a mob a client, so that branch is covered only in play.
	controller.binding.reset_agent_exchanges()
	TEST_ASSERT(controller.binding.agent_exchange_allowed(talker), "Resetting must clear the count.")

	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_revoke_clears_agent_exchanges

/datum/unit_test/agent_npc_revoke_clears_agent_exchanges/Run()
	var/datum/agent_binding/binding = agent_test_binding("cap-revoke")
	var/mob/living/carbon/human/talker = allocate(/mob/living/carbon/human)
	for(var/i in 1 to AGENT_MAX_AGENT_EXCHANGES)
		binding.note_agent_exchange(talker)

	binding.revoke("test")

	TEST_ASSERT_NULL(binding.agent_exchanges, "Revoking must clear the agent exchange counts.")

	qdel(binding)

/datum/unit_test/agent_npc_unclear_speech_has_a_per_npc_share

/datum/unit_test/agent_npc_unclear_speech_has_a_per_npc_share/Run()
	TEST_ASSERT_NOTNULL(SSagent_npc.telemetry, "Setup failed: the subsystem must hold telemetry.")
	var/datum/agent_binding/binding = agent_test_binding("share-pawn")
	var/saved_requests = SSagent_npc.telemetry.ambiguous_requests
	SSagent_npc.telemetry.ambiguous_requests = 0
	binding.ambiguous_at = 0

	var/allowed_fresh = binding.may_spend_on_ambiguous()
	binding.ambiguous_spent = AGENT_AMBIGUOUS_PAWN_LIMIT
	var/allowed_at_share = binding.may_spend_on_ambiguous()
	var/round_has_budget = SSagent_npc.ambiguous_budget_left()
	// Restored before asserting: a failed assertion returns from Run().
	SSagent_npc.telemetry.ambiguous_requests = saved_requests

	TEST_ASSERT(allowed_fresh, "Setup failed: a fresh NPC should be allowed an unclear line.")
	TEST_ASSERT(round_has_budget, "Setup failed: the round limit should still have room.")
	// Without a share, one NPC in a busy room could spend the shared limit for everyone.
	TEST_ASSERT(!allowed_at_share, "An NPC that has used its share must be rationed even while the round has budget left.")

	qdel(binding)

/datum/unit_test/agent_npc_spending_an_unclear_line_counts_toward_the_share

/datum/unit_test/agent_npc_spending_an_unclear_line_counts_toward_the_share/Run()
	var/datum/agent_binding/binding = agent_test_binding("share-count")
	var/before = binding.ambiguous_spent
	var/saved_requests = SSagent_npc.telemetry?.ambiguous_requests

	binding.note_ambiguous_spend()
	var/after = binding.ambiguous_spent
	if(SSagent_npc.telemetry)
		SSagent_npc.telemetry.ambiguous_requests = saved_requests

	TEST_ASSERT_EQUAL(after, before + 1, "Spending on an unclear line must count toward this NPC's share.")

	qdel(binding)

/datum/unit_test/agent_npc_token_reserve_covers_measured_cost

/datum/unit_test/agent_npc_token_reserve_covers_measured_cost/Run()
	// Measured 2026-09-18: 3540 tokens a decision. Reserving less admits work the budget cannot pay for.
	TEST_ASSERT(AGENT_TOKEN_ESTIMATE >= 3540, "The per-request reservation must cover the measured average cost.")

// ------------------------- one speaker's allowance, across every NPC (review F4, 2026-10-16)

/datum/unit_test/agent_npc_speaker_allowance_spans_every_npc

/datum/unit_test/agent_npc_speaker_allowance_spans_every_npc/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/first = agent_test_bound_pawn()
	var/mob/living/carbon/human/species/human/northern/agent_social/second = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/first_agent = first.ai_controller
	var/datum/ai_controller/agent_social/second_agent = second.ai_controller
	TEST_ASSERT_NOTNULL(first_agent?.binding, "Setup failed: the first NPC must be bound.")
	TEST_ASSERT_NOTNULL(second_agent?.binding, "Setup failed: the second NPC must be bound.")
	TEST_ASSERT_NOTNULL(SSagent_npc.telemetry, "Setup failed: the subsystem must hold telemetry.")
	var/mob/living/carbon/human/player = allocate(/mob/living/carbon/human/species/human/northern)
	var/mob/living/carbon/human/other = allocate(/mob/living/carbon/human/species/human/northern)
	var/deferred_before = SSagent_npc.telemetry.speaker_deferred

	// Spread over two NPCs, so only a count across both can hold back the next line.
	var/list/routes = list()
	for(var/i in 1 to AGENT_SPEAKER_DECISIONS)
		var/datum/ai_controller/agent_social/hearer = (i % 2) ? first_agent : second_agent
		var/text = "line [i]"
		routes += hearer.route_speech(AGENT_SPEECH_DIRECTED, "Bob", text, list("speaker" = "Bob", "text" = text), FALSE, player)
	first_agent.binding.take_events()
	var/over = first_agent.route_speech(AGENT_SPEECH_DIRECTED, "Bob", "one more", list("speaker" = "Bob", "text" = "one more"), FALSE, player)
	var/over_dirty = first_agent.binding.dirty
	var/list/kept = agent_test_events_named(first_agent.binding.take_events(), "overheard_speech")
	var/someone_else = first_agent.route_speech(AGENT_SPEECH_DIRECTED, "Ann", "hello", list("speaker" = "Ann", "text" = "hello"), FALSE, other)
	// The window slides: once the old spends age out, the speaker is heard again.
	var/list/stamps = SSagent_npc.speaker_spends?[WEAKREF(player)]
	for(var/i in 1 to length(stamps))
		stamps[i] -= AGENT_SPEAKER_WINDOW
	var/later = first_agent.route_speech(AGENT_SPEECH_DIRECTED, "Bob", "later", list("speaker" = "Bob", "text" = "later"), FALSE, player)
	var/deferred_after = SSagent_npc.telemetry.speaker_deferred
	SSagent_npc.unregister_pawn(second_agent.binding, "test teardown")
	agent_test_restore_subsystem(saved, first_agent.binding)

	for(var/i in 1 to AGENT_SPEAKER_DECISIONS)
		TEST_ASSERT_EQUAL(routes[i], "sent", "Line [i] is inside the allowance and must buy a decision.")
	TEST_ASSERT_EQUAL(over, "allowance", "Past the allowance, counted across both NPCs, a line must wait.")
	TEST_ASSERT(!over_dirty, "A held-back line must not schedule a decision.")
	TEST_ASSERT_EQUAL(length(kept), 1, "Buffered, not dropped: it rides along with the next decision.")
	TEST_ASSERT_EQUAL(someone_else, "sent", "Another speaker has an allowance of their own.")
	TEST_ASSERT_EQUAL(later, "sent", "The window slides, so the speaker is heard again later.")
	TEST_ASSERT_EQUAL(deferred_after, deferred_before + 1, "A held-back line is counted, so the allowance can be tuned.")

/datum/unit_test/agent_npc_speaker_allowance_covers_touches

/datum/unit_test/agent_npc_speaker_allowance_covers_touches/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/pair = agent_test_pawn_and_person()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = pair[1]
	var/mob/living/carbon/human/person = pair[2]
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/agent_binding/binding = controller?.binding
	TEST_ASSERT_NOTNULL(binding, "Setup failed: the pawn must be bound.")

	// Taken between touches, so coalescing cannot be what stops them.
	var/list/routes = list()
	for(var/i in 1 to AGENT_SPEAKER_DECISIONS)
		binding.take_events()
		routes += controller.note_stimulus(AGENT_STIMULUS_TOUCHED, person)
	binding.take_events()
	var/over = controller.note_stimulus(AGENT_STIMULUS_SHOVED, person)
	var/over_dirty = binding.dirty
	var/list/kept = agent_test_events_named(binding.take_events(), "physical")
	var/list/kept_entry = length(kept) ? kept[1] : list()
	agent_test_restore_subsystem(saved, binding)

	for(var/i in 1 to AGENT_SPEAKER_DECISIONS)
		TEST_ASSERT_EQUAL(routes[i], "sent", "Touch [i] is inside the allowance and must buy a decision.")
	TEST_ASSERT_EQUAL(over, "allowance", "Touches spend the same allowance as lines; a poke every two seconds once spent the round.")
	TEST_ASSERT(!over_dirty, "A held-back touch must not schedule a decision.")
	TEST_ASSERT_EQUAL(length(kept), 1, "Buffered, not dropped.")
	TEST_ASSERT_EQUAL(kept_entry["urgency"], AGENT_EVENT_HIGH, "A held-back shove keeps its urgency, so chatter cannot push it out of the ring.")

/datum/unit_test/agent_npc_speaker_allowance_forgets_old_speakers

/datum/unit_test/agent_npc_speaker_allowance_forgets_old_speakers/Run()
	var/mob/living/carbon/human/gone_quiet = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/talking = allocate(/mob/living/carbon/human)
	SSagent_npc.note_speaker_spend(gone_quiet)
	var/list/stamps = SSagent_npc.speaker_spends[WEAKREF(gone_quiet)]
	TEST_ASSERT_EQUAL(length(stamps), 1, "Setup failed: the spend must be recorded.")
	stamps[1] -= AGENT_SPEAKER_WINDOW

	SSagent_npc.note_speaker_spend(talking)

	// Rounds run forty hours and more; a speaker map that only grows is a leak.
	TEST_ASSERT(!(WEAKREF(gone_quiet) in SSagent_npc.speaker_spends), "A speaker with nothing left in the window must be pruned.")
	SSagent_npc.speaker_spends -= WEAKREF(talking)

/datum/unit_test/agent_npc_unconscious_pawn_buys_nothing

/datum/unit_test/agent_npc_unconscious_pawn_buys_nothing/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/pair = agent_test_pawn_and_person()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = pair[1]
	var/mob/living/carbon/human/person = pair[2]
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/agent_binding/binding = controller?.binding
	TEST_ASSERT_NOTNULL(binding, "Setup failed: the pawn must be bound.")
	binding.take_events()
	binding.next_request_at = 0
	binding.mark_dirty("heard_speech")

	var/awake_may = binding.can_start_request()
	pawn.set_stat(UNCONSCIOUS)
	var/out_cold_may = binding.can_start_request()
	binding.take_events()
	controller.on_pawn_touched(pawn, person, null)
	var/touch_dirty = binding.dirty
	var/touch_events = length(binding.events)
	binding.mark_dirty("heard_speech")
	pawn.set_stat(DEAD)
	var/dead_may = binding.can_start_request()
	pawn.set_stat(CONSCIOUS)
	var/woken_may = binding.can_start_request()
	agent_test_restore_subsystem(saved, binding)

	TEST_ASSERT(awake_may, "Setup failed: an awake, dirty pawn may ask.")
	TEST_ASSERT(!out_cold_may, "An unconscious NPC decides nothing.")
	TEST_ASSERT(!touch_dirty, "A touch on a body that cannot feel it must not buy a decision.")
	TEST_ASSERT_EQUAL(touch_events, 0, "Nor be kept for later: it never felt it.")
	TEST_ASSERT(!dead_may, "Nor does a dead one.")
	TEST_ASSERT(woken_may, "What it heard before waits, and goes out once it wakes.")

/datum/unit_test/agent_npc_spent_budget_tells_the_admins

/datum/unit_test/agent_npc_spent_budget_tells_the_admins/Run()
	var/list/saved_bindings = SSagent_npc.bindings
	var/list/saved_flight = SSagent_npc.in_flight.Copy()
	var/saved_disabled = SSagent_npc.globally_disabled
	var/saved_budget = SSagent_npc.round_token_budget
	var/saved_spent = SSagent_npc.tokens_spent
	SSagent_npc.bindings = list()
	SSagent_npc.globally_disabled = FALSE
	SSagent_npc.round_token_budget = 1000
	SSagent_npc.tokens_spent = 999

	var/early = SSagent_npc.check_round_budget()
	var/logged_before = length(GLOB.admin_log)
	SSagent_npc.tokens_spent = 1000
	var/spent = SSagent_npc.check_round_budget()
	var/disabled = SSagent_npc.globally_disabled
	var/list/told = GLOB.admin_log.Copy(logged_before + 1)
	SSagent_npc.bindings = saved_bindings
	SSagent_npc.in_flight = saved_flight
	SSagent_npc.globally_disabled = saved_disabled
	SSagent_npc.round_token_budget = saved_budget
	SSagent_npc.tokens_spent = saved_spent

	TEST_ASSERT(!early, "Setup failed: a budget with room left must not trip.")
	TEST_ASSERT(spent && disabled, "A spent budget turns every NPC off.")
	// message_admins needs a client to observe; the admin log line is written beside it.
	TEST_ASSERT(length(told) && findtext(told[length(told)], "token budget"), "And the admins are told, or a forty-hour round stays mute with nobody knowing why.")
