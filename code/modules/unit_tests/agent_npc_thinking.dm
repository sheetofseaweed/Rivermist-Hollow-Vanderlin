// The thinking bubble: shown exactly while a decision is in flight, and never left behind.

/// Put a bound pawn into the pending state the way start_request does, bar the HTTP.
/proc/agent_test_make_pending(datum/agent_binding/binding)
	binding.pending = agent_test_request_for(binding)
	binding.state = AGENT_BINDING_PENDING
	binding.update_thinking()

/datum/unit_test/agent_npc_thinking_shows_while_pending

/datum/unit_test/agent_npc_thinking_shows_while_pending/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/agent_binding/binding = controller?.binding
	TEST_ASSERT_NOTNULL(binding, "Setup failed: the pawn must be bound.")
	var/overlays_before = length(pawn.overlays)

	agent_test_make_pending(binding)
	var/shown = controller.thinking
	var/overlays_while = length(pawn.overlays)
	binding.abandon_pending("test")
	var/cleared = !controller.thinking
	var/overlays_after = length(pawn.overlays)
	agent_test_restore_subsystem(saved, binding)

	// LLM replies take seconds. Without a sign, a player cannot tell heard from ignored.
	TEST_ASSERT(shown, "A request in flight must show the thinking bubble.")
	TEST_ASSERT_EQUAL(overlays_while, overlays_before + 1, "The bubble must actually be on the pawn.")
	TEST_ASSERT(cleared, "An abandoned request must clear the bubble.")
	TEST_ASSERT_EQUAL(overlays_after, overlays_before, "Clearing must take the overlay off again.")

/datum/unit_test/agent_npc_thinking_clears_on_revoke

/datum/unit_test/agent_npc_thinking_clears_on_revoke/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/agent_binding/binding = controller?.binding
	TEST_ASSERT_NOTNULL(binding, "Setup failed: the pawn must be bound.")

	agent_test_make_pending(binding)
	binding.revoke("test")
	var/still_thinking = controller.thinking
	agent_test_restore_subsystem(saved, binding)

	TEST_ASSERT(!still_thinking, "The kill switch must never leave NPCs looking mid-reply.")

/datum/unit_test/agent_npc_thinking_clears_on_detach

/datum/unit_test/agent_npc_thinking_clears_on_detach/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	var/overlays_before = length(pawn.overlays)

	controller.show_thinking(TRUE)
	TEST_ASSERT_EQUAL(length(pawn.overlays), overlays_before + 1, "Setup failed: the bubble must be on.")
	var/refusal = agent_detach_controller(pawn)
	agent_test_restore_subsystem(saved, null)

	TEST_ASSERT_NULL(refusal, "Setup failed: detaching must succeed.")
	// Nothing would ever clear it afterwards: the controller that owned it is gone.
	TEST_ASSERT_EQUAL(length(pawn.overlays), overlays_before, "Detaching must not leave a bubble behind.")
