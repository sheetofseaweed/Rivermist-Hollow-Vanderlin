// Who was that said to?
//
// The whole test is lopsided on purpose, and so is the code it covers. A wasted
// decision costs a fraction of a penny; an NPC that ignores a player talking to
// it reads as broken. Speech is only set aside on positive evidence that it
// belonged to someone else.

/// An audience description, without needing real mobs standing in view.
/datum/unit_test/proc/agent_test_audience(bystanders = 0, named_another = FALSE)
	return list("bystanders" = bystanders, "named_another" = named_another)

/datum/unit_test/agent_npc_name_matching_handles_first_names

/datum/unit_test/agent_npc_name_matching_handles_first_names/Run()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = allocate(/mob/living/carbon/human/species/human/northern/agent_social)
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller, "Setup failed: the pawn must carry an agent controller.")

	TEST_ASSERT(controller.name_appears_in("Isaac Brown", "Isaac Brown, over here"), "A full name must match.")
	// Players address NPCs by first name far more often than by full name.
	TEST_ASSERT(controller.name_appears_in("Isaac Brown", "hey isaac, got a moment?"), "A first name must match, case insensitively.")
	TEST_ASSERT(!controller.name_appears_in("Isaac Brown", "nice weather today"), "An unrelated line must not match.")

	// A two-letter fragment matches half the words in the language, so it is not
	// evidence of anything. Without this guard an NPC named "Bo Smith" answers
	// every sentence containing "both", "about" or "bore".
	TEST_ASSERT(!controller.name_appears_in("Bo Smith", "I am bored of both of them"), "A very short first name must not match loosely.")

	TEST_ASSERT(!controller.name_appears_in(null, "anything"), "A missing name must not match.")
	TEST_ASSERT(!controller.name_appears_in("Isaac", null), "Missing text must not match.")
	TEST_ASSERT(!controller.name_appears_in("", ""), "Empty strings must not match.")

/datum/unit_test/agent_npc_speech_defaults_to_being_for_us

/datum/unit_test/agent_npc_speech_defaults_to_being_for_us/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller, "Setup failed: the pawn must carry an agent controller.")
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)

	// Stated, not assumed: this test is about the fall-through, so the speaker
	// has to be inside near-speech range for the distance rule to be silent.
	TEST_ASSERT(get_dist(pawn, speaker) <= AGENT_DIRECT_SPEECH_RANGE, "Setup failed: the speaker must be within near-speech range.")

	// Someone standing right here, saying something with no name in it, with
	// other people around. Nothing proves it was for us, and nothing proves it
	// was not, so it must be treated as ours.
	TEST_ASSERT(controller.speech_is_directed(speaker, "nice weather", FALSE, agent_test_audience(bystanders = 3)), "With no evidence either way, speech must be treated as directed at us.")

	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_speech_naming_someone_else_is_not_ours

/datum/unit_test/agent_npc_speech_naming_someone_else_is_not_ours/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller, "Setup failed: the pawn must carry an agent controller.")
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)

	// The one confident case: they named someone else who is standing here.
	TEST_ASSERT(!controller.speech_is_directed(speaker, "Bob, pass the ale", FALSE, agent_test_audience(bystanders = 2, named_another = TRUE)), "Naming someone else who is present is evidence the line was not ours.")

	// Being named ourselves outranks it, because both names can appear at once.
	TEST_ASSERT(controller.speech_is_directed(speaker, "[pawn.name], tell Bob to sit", FALSE, agent_test_audience(bystanders = 2, named_another = TRUE)), "Our own name must outrank someone else's being present.")

	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_speech_whisper_is_always_ours

/datum/unit_test/agent_npc_speech_whisper_is_always_ours/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller, "Setup failed: the pawn must carry an agent controller.")
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)

	// Whispering carries only to who you meant it for, so hearing one at all
	// means it was ours, whatever else the line looks like.
	TEST_ASSERT(controller.speech_is_directed(speaker, "Bob, pass the ale", TRUE, agent_test_audience(bystanders = 5, named_another = TRUE)), "A whisper we can hear must be treated as ours even when it names someone else.")

	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_speech_mid_conversation_is_ours

/datum/unit_test/agent_npc_speech_mid_conversation_is_ours/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller, "Setup failed: the pawn must carry an agent controller.")
	TEST_ASSERT_NOTNULL(controller.binding, "Setup failed: the pawn must be bound.")
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)

	controller.binding.end_continuation()
	TEST_ASSERT(!controller.binding.in_interaction(), "Setup failed: there should be no interaction running.")
	TEST_ASSERT(!controller.speech_is_directed(speaker, "Bob, pass the ale", FALSE, agent_test_audience(bystanders = 2, named_another = TRUE)), "Setup failed: this line should read as someone else's.")

	controller.binding.begin_interaction()
	TEST_ASSERT(controller.binding.in_interaction(), "Setup failed: begin_interaction should start one.")

	// A reply does not carry your name. Mid-conversation, an unaddressed line is
	// far more likely to be the next thing the person is saying to you.
	TEST_ASSERT(controller.speech_is_directed(speaker, "Bob, pass the ale", FALSE, agent_test_audience(bystanders = 2, named_another = TRUE)), "While a conversation is running, speech must be read as part of it.")

	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_speech_alone_with_us_is_ours

/datum/unit_test/agent_npc_speech_alone_with_us_is_ours/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller, "Setup failed: the pawn must carry an agent controller.")
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)
	controller.binding?.end_continuation()

	// The speaker must be moved out of near-speech range, or this proves
	// nothing: a nearby speaker is treated as ours by the distance rule whether
	// or not the "nobody else present" rule exists at all. Found by mutation.
	var/turf/here = get_turf(pawn)
	TEST_ASSERT_NOTNULL(here, "Setup failed: the pawn must be standing somewhere.")
	var/turf/far = locate(here.x + AGENT_DIRECT_SPEECH_RANGE + 2, here.y, here.z)
	TEST_ASSERT_NOTNULL(far, "Setup failed: need a turf beyond near-speech range.")
	speaker.forceMove(far)
	TEST_ASSERT(get_dist(pawn, speaker) > AGENT_DIRECT_SPEECH_RANGE, "Setup failed: the speaker must be beyond near-speech range.")

	// Nobody else is here, so there is nobody else it could have been for.
	TEST_ASSERT(controller.speech_is_directed(speaker, "nice weather", FALSE, agent_test_audience(bystanders = 0)), "With nobody else present, distant speech must still be ours.")

	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_overheard_speech_does_not_schedule_a_request

/datum/unit_test/agent_npc_overheard_speech_does_not_schedule_a_request/Run()
	var/datum/agent_binding/binding = agent_test_binding("addressing-pawn")
	binding.clear_dirty()
	binding.end_continuation()

	TEST_ASSERT(binding.push_event("overheard_speech", AGENT_EVENT_LOW, list("text" = "Bob, pass the ale")), "An ambient push must be accepted.")

	// The whole point: it is remembered and delivered with the next real
	// decision, rather than buying one of its own.
	TEST_ASSERT(!binding.dirty, "Overheard speech must not schedule a request.")
	TEST_ASSERT_EQUAL(length(binding.events), 1, "Overheard speech must still be remembered.")
	TEST_ASSERT(!binding.in_interaction(), "Overheard speech must not extend the interaction, or bystanders keep the NPC awake forever.")

	qdel(binding)

/datum/unit_test/agent_npc_revoked_bindings_refuse_ambient_events

/datum/unit_test/agent_npc_revoked_bindings_refuse_ambient_events/Run()
	var/datum/agent_binding/binding = agent_test_binding("addressing-revoked")
	binding.revoke("test")

	TEST_ASSERT_EQUAL(binding.state, AGENT_BINDING_DISABLED, "Setup failed: revoke must disable the binding.")

	// mark_dirty and record_result already check this. Ambient speech reaches
	// push_event directly, so without its own guard a revoked pawn quietly
	// accumulates events nobody will ever send.
	TEST_ASSERT(!binding.push_event("overheard_speech", AGENT_EVENT_LOW, list("text" = "anything")), "A revoked binding must refuse ambient events.")
	TEST_ASSERT_EQUAL(length(binding.events), 0, "A revoked binding must not accumulate events.")

	qdel(binding)
