// Emotes reaching agent NPCs. visible_message skips clientless mobs, so before 2026-09-23 none arrived at all.

/// An emote scene, described rather than staged, like the speech context helper.
/datum/unit_test/proc/agent_test_emote_context(distance = 1, nearby_people = 0, named_us = AGENT_NAMED_NONE, named_someone_else = FALSE, focused = FALSE, focused_elsewhere = FALSE)
	return list(
		"distance" = distance,
		"nearby_people" = nearby_people,
		"named_us" = named_us,
		"named_someone_else" = named_someone_else,
		"focused" = focused,
		"focused_elsewhere" = focused_elsewhere,
	)

/// The events of one kind in a taken list.
/proc/agent_test_events_named(list/events, event_name)
	var/list/found = list()
	for(var/list/entry as anything in events)
		if(entry["event"] == event_name)
			found += list(entry)
	return found

/datum/unit_test/agent_npc_custom_emote_reaches_the_agent

/datum/unit_test/agent_npc_custom_emote_reaches_the_agent/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	controller.binding.take_events()
	var/mob/living/carbon/human/emoter = allocate(/mob/living/carbon/human/species/human/northern)

	// The real verb path, so the hook in run_emote is what is being tested.
	emoter.emote("me", EMOTE_VISIBLE, "juggles three apples", TRUE, custom_me = TRUE)
	var/was_dirty = controller.binding.dirty
	var/list/seen = agent_test_events_named(controller.binding.take_events(), "saw_emote")
	agent_test_restore_subsystem(saved, controller.binding)

	TEST_ASSERT_EQUAL(length(seen), 1, "A custom emote beside a lone NPC must reach it as something to answer.")
	var/list/entry = seen[1]
	var/list/detail = entry["detail"]
	TEST_ASSERT_EQUAL(detail["text"], "juggles three apples", "The emote must arrive as written, without the name or markup.")
	TEST_ASSERT(was_dirty, "An emote aimed at the NPC must buy a decision.")

/datum/unit_test/agent_npc_involuntary_emote_is_only_noticed

/datum/unit_test/agent_npc_involuntary_emote_is_only_noticed/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	controller.binding.take_events()
	var/mob/living/carbon/human/emoter = allocate(/mob/living/carbon/human/species/human/northern)

	// Not intentional: the path a cough or a pain scream takes.
	emoter.emote("blush")
	var/was_dirty = controller.binding.dirty
	var/list/events = controller.binding.take_events()
	agent_test_restore_subsystem(saved, controller.binding)

	var/list/noticed = agent_test_events_named(events, "noticed_emote")
	TEST_ASSERT_EQUAL(length(noticed), 1, "An involuntary emote must still be noticed, so the NPC knows it happened.")
	var/list/entry = noticed[1]
	var/list/detail = entry["detail"]
	TEST_ASSERT(detail["involuntary"], "It must be marked involuntary, so the model does not answer a cough.")
	// The whole point: coughs, sneezes and screams must not spend tokens.
	TEST_ASSERT(!was_dirty, "An involuntary emote must never buy a decision, even beside a lone NPC.")

/datum/unit_test/agent_npc_unseen_emote_is_ignored

/datum/unit_test/agent_npc_unseen_emote_is_ignored/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	var/mob/living/carbon/human/emoter = allocate(/mob/living/carbon/human/species/human/northern)

	emoter.invisibility = INVISIBILITY_ABSTRACT
	var/hidden = controller.on_emote_perceived(emoter, "waves.", TRUE, FALSE)
	emoter.invisibility = 0
	var/own = controller.on_emote_perceived(pawn, "waves.", TRUE, FALSE)
	agent_test_restore_subsystem(saved, controller.binding)

	TEST_ASSERT_EQUAL(hidden, "unseen", "An emoter the NPC cannot see must not reach it.")
	TEST_ASSERT_EQUAL(own, "unseen", "An NPC must not react to its own emotes.")

/datum/unit_test/agent_npc_emote_classification

/datum/unit_test/agent_npc_emote_classification/Run()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = allocate(/mob/living/carbon/human/species/human/northern/agent_social)
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/mob/living/carbon/human/emoter = allocate(/mob/living/carbon/human/species/human/northern)

	TEST_ASSERT_EQUAL(controller.classify_emote(emoter, TRUE, agent_test_emote_context(distance = 2)), AGENT_SPEECH_DIRECTED, "Alone together, an emote is for us.")
	TEST_ASSERT_EQUAL(controller.classify_emote(emoter, TRUE, agent_test_emote_context(distance = 5)), AGENT_SPEECH_OVERHEARD, "Alone but across the room, an emote is someone keeping to themselves.")
	TEST_ASSERT_EQUAL(controller.classify_emote(emoter, TRUE, agent_test_emote_context(distance = 4, nearby_people = 3, named_us = AGENT_NAMED_STRONG)), AGENT_SPEECH_DIRECTED, "An emote naming us is for us, wherever the name falls.")
	TEST_ASSERT_EQUAL(controller.classify_emote(emoter, TRUE, agent_test_emote_context(distance = 1, nearby_people = 3, named_someone_else = TRUE)), AGENT_SPEECH_OVERHEARD, "An emote naming someone else is theirs.")
	TEST_ASSERT_EQUAL(controller.classify_emote(emoter, TRUE, agent_test_emote_context(distance = 1, nearby_people = 3, named_us = AGENT_NAMED_WEAK, named_someone_else = TRUE)), AGENT_SPEECH_AMBIGUOUS, "A lowercase mention of us beside someone else's name is unclear, not theirs.")
	TEST_ASSERT_EQUAL(controller.classify_emote(emoter, TRUE, agent_test_emote_context(distance = 1, nearby_people = 3)), AGENT_SPEECH_AMBIGUOUS, "Right beside us in company, it may be ours; the ration decides.")
	// The cost case. People emote constantly, and a shrug across a crowded room is not a question.
	TEST_ASSERT_EQUAL(controller.classify_emote(emoter, TRUE, agent_test_emote_context(distance = 3, nearby_people = 3)), AGENT_SPEECH_OVERHEARD, "An unaimed emote in company must only be noticed.")
	TEST_ASSERT_EQUAL(controller.classify_emote(emoter, TRUE, agent_test_emote_context(distance = 6, nearby_people = 3, focused = TRUE)), AGENT_SPEECH_DIRECTED, "Talk To makes every emote ours.")
	TEST_ASSERT_EQUAL(controller.classify_emote(emoter, TRUE, agent_test_emote_context(distance = 1, focused_elsewhere = TRUE)), AGENT_SPEECH_OVERHEARD, "Talk To on another NPC makes the emote theirs.")
	TEST_ASSERT_EQUAL(controller.classify_emote(emoter, FALSE, agent_test_emote_context(distance = 1, named_us = AGENT_NAMED_STRONG, focused = TRUE)), AGENT_SPEECH_OVERHEARD, "An involuntary emote is never addressed, whatever else is true.")

/datum/unit_test/agent_npc_emote_mentions_are_case_strict

/datum/unit_test/agent_npc_emote_mentions_are_case_strict/Run()
	TEST_ASSERT(agent_emote_mentions("Will Smith", agent_emote_words("hands Will a cup.")), "A capitalised name in an emote names that person.")
	// The Will problem from speech, in emote form. Suppression must be strict.
	TEST_ASSERT(!agent_emote_mentions("Will Smith", agent_emote_words("says she will sit down.")), "A lowercase common word must not name anyone.")
	TEST_ASSERT(agent_emote_mentions("Isaac", agent_emote_words("pats Isaac's shoulder.")), "A possessive still names the person.")
	TEST_ASSERT(agent_emote_mentions("Isaac", agent_emote_words("обнимает Исаака")), "A transliterated, inflected name must still count.")
	TEST_ASSERT(!agent_emote_mentions("Unknown Man", agent_emote_words("nods at the Man.")), "A placeholder name must never match.")
	TEST_ASSERT(!agent_emote_mentions("Isaac", list()), "No words, no mention.")

/datum/unit_test/agent_npc_emote_text_is_cleaned

/datum/unit_test/agent_npc_emote_text_is_cleaned/Run()
	TEST_ASSERT_EQUAL(agent_clean_emote_text("<b>bows</b> deeply"), "bows deeply", "Markup must be stripped before the model reads it.")
	TEST_ASSERT_EQUAL(agent_clean_emote_text("doesn&#39;t move"), "doesn't move", "Entities must be decoded.")
	TEST_ASSERT_NULL(agent_clean_emote_text("<i></i>  "), "An emote that is only markup is nothing.")
	var/long_text = ""
	for(var/i in 1 to AGENT_EMOTE_TEXT_MAX + 50)
		long_text += "a"
	TEST_ASSERT(length(agent_clean_emote_text(long_text)) < AGENT_EMOTE_TEXT_MAX + 1, "A long emote must be capped; every letter is paid for.")
