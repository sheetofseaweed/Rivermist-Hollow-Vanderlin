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
