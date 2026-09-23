// Who was that said to?
//
// The whole thing is lopsided on purpose. A wasted decision costs a fraction of
// a penny; an NPC that ignores a player talking to it reads as broken. Speech is
// only set aside on positive evidence that it belonged to somebody else.
//
// The classifier is driven entirely by a context list, so these tests state the
// scene exactly rather than depending on where allocate() happens to put a mob.

/// A speech scene, described rather than staged.
/datum/unit_test/proc/agent_test_speech_context(distance = 1, whispered = FALSE, volume = "0", nearby_people = 0, named_someone_else = FALSE, script = AGENT_SCRIPT_LATIN, focused = FALSE, focused_elsewhere = FALSE)
	return list(
		"focused" = focused,
		"focused_elsewhere" = focused_elsewhere,
		"distance" = distance,
		"whispered" = whispered,
		"volume" = volume,
		"script" = script,
		"nearby_people" = nearby_people,
		"named_someone_else" = named_someone_else,
	)

// ------------------------------------------------------------ name matching

/datum/unit_test/agent_npc_loose_matching_finds_the_name

/datum/unit_test/agent_npc_loose_matching_finds_the_name/Run()
	// Loose is for deciding we WERE addressed, where a false positive costs one
	// decision, so it accepts any part of the name as a whole word.
	TEST_ASSERT(agent_name_matches_loosely("Isaac Brown", "Isaac Brown, over here"), "A full name must match.")
	TEST_ASSERT(agent_name_matches_loosely("Isaac Brown", "hey isaac, got a moment?"), "A first name must match, case insensitively.")
	TEST_ASSERT(agent_name_matches_loosely("Isaac Brown", "morning, Brown"), "A family name must match.")

	TEST_ASSERT(!agent_name_matches_loosely("Isaac Brown", "nice weather today"), "An unrelated line must not match.")
	// Whole words only. Without that, "Isaac" answers to "Isaacson".
	TEST_ASSERT(!agent_name_matches_loosely("Isaac Brown", "that is Isaacson over there"), "A name inside a longer word must not match.")
	TEST_ASSERT(!agent_name_matches_loosely("Bo Smith", "I am bored of both"), "A name part of two characters or fewer must never match.")

	TEST_ASSERT(!agent_name_matches_loosely(null, "anything"), "A missing name must not match.")
	TEST_ASSERT(!agent_name_matches_loosely("Isaac", null), "Missing text must not match.")

/datum/unit_test/agent_npc_vocative_matching_is_strict

/datum/unit_test/agent_npc_vocative_matching_is_strict/Run()
	// Strict is for deciding SOMEBODY ELSE was addressed, which silences us, so
	// it wants a vocative or the whole name and nothing less.
	TEST_ASSERT(agent_name_in_vocative("Bob Miller", "Bob, pass the ale"), "A name with a trailing comma is a vocative and must match.")
	TEST_ASSERT(agent_name_in_vocative("Bob Miller", "have you seen Bob Miller today"), "Every part of a multi-part name present must match.")

	// The defect this proc exists for: "Will" is an ordinary English word, and
	// a mob named Will used to silence the NPC every time anyone used it.
	TEST_ASSERT(!agent_name_in_vocative("Will Baker", "I will go now"), "A common word that happens to be someone's name must not suppress.")

	// Prose is not address. "Tell Bob" is a line spoken TO us about Bob.
	TEST_ASSERT(!agent_name_in_vocative("Bob", "tell Bob I will be late"), "A name in prose must not suppress.")
	TEST_ASSERT(agent_name_in_vocative("Bob", "Bob, come here"), "A single-part name in vocative position must still suppress.")

	TEST_ASSERT(!agent_name_in_vocative("Bo", "Bo, come here"), "A name of two characters or fewer must never suppress.")
	TEST_ASSERT(!agent_name_in_vocative(null, "Bob, come here"), "A missing name must not suppress.")

/datum/unit_test/agent_npc_punctuation_is_trimmed_around_names

/datum/unit_test/agent_npc_punctuation_is_trimmed_around_names/Run()
	TEST_ASSERT_EQUAL(agent_trim_punctuation("isaac,"), "isaac", "A trailing comma must be trimmed.")
	TEST_ASSERT_EQUAL(agent_trim_punctuation("\"isaac!\""), "isaac", "Wrapping punctuation must be trimmed.")
	TEST_ASSERT_EQUAL(agent_trim_punctuation("isaac"), "isaac", "Clean text must be left alone.")
	TEST_ASSERT_EQUAL(agent_trim_punctuation(",,,"), "", "Punctuation alone must trim to nothing.")
	TEST_ASSERT_EQUAL(agent_trim_punctuation(null), "", "A missing token must trim to empty text, not null.")

	// Players end a vocative with a comma far more often than not.
	TEST_ASSERT(agent_text_has_word("Isaac, over here!", "isaac"), "Punctuation must not stop a whole-word match.")

/datum/unit_test/agent_npc_shouting_is_read_from_punctuation

/datum/unit_test/agent_npc_shouting_is_read_from_punctuation/Run()
	// say_test drives the engine's own range extension: +5 tiles for "!" and
	// +10 for "!!". This must agree with it or the two disagree about reach.
	TEST_ASSERT(agent_speech_is_shouted(say_test("Isaac!")), "A single exclamation mark is a shout.")
	TEST_ASSERT(agent_speech_is_shouted(say_test("Isaac!!")), "A double exclamation mark is a shout.")
	TEST_ASSERT(!agent_speech_is_shouted(say_test("Isaac?")), "A question is not a shout.")
	TEST_ASSERT(!agent_speech_is_shouted(say_test("Hello Isaac")), "Ordinary speech is not a shout.")

// --------------------------------------------------- transliterated names

/datum/unit_test/agent_npc_folding_normalises_spellings

/datum/unit_test/agent_npc_folding_normalises_spellings/Run()
	// The whole Cyrillic answer rests on these two landing on the same string.
	TEST_ASSERT_EQUAL(agent_fold_name("Isaac"), "isak", "A Latin name must fold to its bare shape.")
	TEST_ASSERT_EQUAL(agent_fold_name("Исаак"), "isak", "The Cyrillic spelling of the same name must fold to the same shape.")

	// c and k are the commonest transliteration fork, and doubled letters are
	// where one speller writes Isaac and another writes Исак.
	TEST_ASSERT_EQUAL(agent_fold_name("Mccoy"), agent_fold_name("Mkoy"), "c and k must fold together.")
	TEST_ASSERT_EQUAL(agent_fold_name(""), "", "Empty text must fold to empty text.")
	TEST_ASSERT_EQUAL(agent_fold_name(null), "", "Missing text must fold to empty text, not null.")

/datum/unit_test/agent_npc_script_detection

/datum/unit_test/agent_npc_script_detection/Run()
	TEST_ASSERT_EQUAL(agent_text_script("hello there"), AGENT_SCRIPT_LATIN, "Plain English must read as Latin.")
	TEST_ASSERT_EQUAL(agent_text_script("подойди сюда"), AGENT_SCRIPT_CYRILLIC, "Plain Russian must read as Cyrillic.")

	// Mixed lines are ordinary on this server, so the count decides, not the
	// first character.
	TEST_ASSERT_EQUAL(agent_text_script("Исаак, come here"), AGENT_SCRIPT_MIXED, "A line in both scripts must read as mixed.")
	TEST_ASSERT_EQUAL(agent_text_script("!!! ..."), AGENT_SCRIPT_NONE, "Punctuation alone has no script.")
	TEST_ASSERT_EQUAL(agent_text_script(null), AGENT_SCRIPT_NONE, "Missing text has no script.")

	// A script we cannot match a Latin name against must be flagged, because a
	// failed match there is not evidence of anything.
	TEST_ASSERT(agent_script_is_matchable(AGENT_SCRIPT_CYRILLIC), "Cyrillic must be matchable; that is what folding is for.")
	TEST_ASSERT(!agent_script_is_matchable(AGENT_SCRIPT_OTHER), "An unsupported script must not be treated as matchable.")

/datum/unit_test/agent_npc_cyrillic_address_is_recognised

/datum/unit_test/agent_npc_cyrillic_address_is_recognised/Run()
	// The reported problem: players transliterate, and plain matching sees none
	// of it, so the distance rule silenced them.
	TEST_ASSERT(agent_name_matches_loosely("Isaac Brown", "Исаак, подойди"), "A transliterated first name must be recognised.")

	// Russian inflects, so the name arrives with a case ending attached.
	TEST_ASSERT(agent_name_matches_loosely("Isaac Brown", "Исааку надо идти"), "A dative case ending must not defeat the match.")
	TEST_ASSERT(agent_name_matches_loosely("Isaac Brown", "с Исааком всё хорошо"), "An instrumental case ending must not defeat the match.")

	TEST_ASSERT(!agent_name_matches_loosely("Isaac Brown", "погода хорошая"), "Unrelated Russian must not match.")

/datum/unit_test/agent_npc_latin_text_gets_no_suffix_tolerance

/datum/unit_test/agent_npc_latin_text_gets_no_suffix_tolerance/Run()
	// Inflection tolerance exists for Russian case endings. Applied to English it
	// wakes an NPC named Mark every time somebody mentions a market.
	TEST_ASSERT(!agent_name_matches_loosely("Mark Fisher", "the market is open today"), "A longer English word must not match a name by prefix.")
	TEST_ASSERT(agent_name_matches_loosely("Mark Fisher", "Mark, over here"), "The name itself must still match.")

/datum/unit_test/agent_npc_folded_matches_never_suppress

/datum/unit_test/agent_npc_folded_matches_never_suppress/Run()
	// The safety rule the whole design rests on: a fuzzy match may wake the NPC,
	// never silence it. Suppression uses exact tokens and no folding at all.
	TEST_ASSERT(agent_name_matches_loosely("Isaac Brown", "Исаак, подойди"), "Setup failed: this is a folded match.")
	TEST_ASSERT(!agent_name_in_vocative("Isaac Brown", "Исаак, подойди"), "A folded match must never be able to suppress a response.")

// ------------------------------------------------------------- the identity

/datum/unit_test/agent_npc_addressing_uses_the_visible_name

/datum/unit_test/agent_npc_addressing_uses_the_visible_name/Run()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = allocate(/mob/living/carbon/human/species/human/northern/agent_social)
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller, "Setup failed: the pawn must carry an agent controller.")

	pawn.name_override = "Masked Stranger"
	TEST_ASSERT(pawn.get_visible_name() != pawn.name, "Setup failed: the visible name and the real name must differ.")

	// Everything else in the pipeline reports get_visible_name, and a disguised
	// NPC should answer to what people can actually call it.
	TEST_ASSERT_EQUAL(controller.addressable_name(), "Masked Stranger", "Addressing must use the visible name, not the hidden one.")

// -------------------------------------------------------------- classifying

/datum/unit_test/agent_npc_speech_defaults_to_being_for_us

/datum/unit_test/agent_npc_speech_defaults_to_being_for_us/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller, "Setup failed: the pawn must carry an agent controller.")
	controller.binding?.end_continuation()
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)

	// Close by, no name, other people around. Nothing proves it was ours and
	// nothing proves it was not, so it must be treated as ours.
	TEST_ASSERT_EQUAL(controller.classify_speech(speaker, "nice weather", agent_test_speech_context(distance = 1, nearby_people = 3)), AGENT_SPEECH_AMBIGUOUS, "With no evidence either way, speech must be ambiguous rather than claimed as ours.")
	TEST_ASSERT(agent_speech_wakes_us(AGENT_SPEECH_AMBIGUOUS), "Ambiguous speech must still wake the NPC. Silence is the worse failure.")

	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_speech_naming_someone_else_is_not_ours

/datum/unit_test/agent_npc_speech_naming_someone_else_is_not_ours/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller, "Setup failed: the pawn must carry an agent controller.")
	controller.binding?.end_continuation()
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)

	TEST_ASSERT_EQUAL(controller.classify_speech(speaker, "Bob, pass the ale", agent_test_speech_context(distance = 1, nearby_people = 2, named_someone_else = TRUE)), AGENT_SPEECH_OVERHEARD, "Addressing someone else who is present is evidence the line was not ours.")

	// Our own name outranks it, because both names can appear in one line.
	TEST_ASSERT_EQUAL(controller.classify_speech(speaker, "[controller.addressable_name()], tell Bob to sit", agent_test_speech_context(distance = 1, nearby_people = 2, named_someone_else = TRUE)), AGENT_SPEECH_DIRECTED, "Our own name must outrank someone else's being addressed.")

	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_whisper_is_ours_only_within_range

/datum/unit_test/agent_npc_whisper_is_ours_only_within_range/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller, "Setup failed: the pawn must carry an agent controller.")
	controller.binding?.end_continuation()
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)

	// A whisper carries exactly one tile to the person it is meant for.
	TEST_ASSERT_EQUAL(controller.classify_speech(speaker, "Bob, pass the ale", agent_test_speech_context(distance = AGENT_WHISPER_INTENDED_RANGE, whispered = TRUE, nearby_people = 5, named_someone_else = TRUE)), AGENT_SPEECH_DIRECTED, "A whisper within its intended range must be ours, whatever else the line looks like.")

	// Past that is the eavesdrop band, where what arrives is a starred copy.
	// Being close enough to overhear is not the same as being spoken to.
	TEST_ASSERT_EQUAL(controller.classify_speech(speaker, "Bob, pass the ale", agent_test_speech_context(distance = AGENT_WHISPER_INTENDED_RANGE + 1, whispered = TRUE, nearby_people = 5, named_someone_else = TRUE)), AGENT_SPEECH_OVERHEARD, "An eavesdropped whisper must fall through to the ordinary rules, not count as ours.")

	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_shouting_beats_distance

/datum/unit_test/agent_npc_shouting_beats_distance/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller, "Setup failed: the pawn must carry an agent controller.")
	controller.binding?.end_continuation()
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)
	var/far = AGENT_DIRECT_SPEECH_RANGE + 3

	TEST_ASSERT_EQUAL(controller.classify_speech(speaker, "nice weather", agent_test_speech_context(distance = far, nearby_people = 2)), AGENT_SPEECH_OVERHEARD, "Setup failed: ordinary distant speech should be set aside.")

	// The engine gives a shout +5 or +10 tiles of range precisely so it carries.
	// Judging it by speaking distance is how a player yelling gets ignored.
	TEST_ASSERT_EQUAL(controller.classify_speech(speaker, "over here!", agent_test_speech_context(distance = far, volume = "2", nearby_people = 2)), AGENT_SPEECH_AMBIGUOUS, "A shout must beat the distance rule. Loud and public is worth attention, not certainty.")
	TEST_ASSERT_EQUAL(controller.classify_speech(speaker, "over here!!", agent_test_speech_context(distance = far, volume = "3", nearby_people = 2)), AGENT_SPEECH_AMBIGUOUS, "A loud shout must beat the distance rule.")

	agent_test_restore_subsystem(saved, controller.binding)

/// A partner established the way play establishes one: asked, then answered.
/datum/unit_test/proc/agent_test_engage(datum/agent_binding/binding, atom/movable/speaker)
	binding.note_candidate(speaker)
	return binding.engage_candidate()

/datum/unit_test/agent_npc_partner_reply_is_ours

/datum/unit_test/agent_npc_partner_reply_is_ours/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human)
	var/list/crowded = agent_test_speech_context(distance = 1, nearby_people = 2)

	TEST_ASSERT(agent_test_engage(controller.binding, partner), "Setup failed: answering should engage the speaker.")
	TEST_ASSERT(controller.binding.is_partner(partner), "Setup failed: the speaker should now be the partner.")

	// A reply does not carry your name.
	TEST_ASSERT_EQUAL(controller.classify_speech(partner, "yes please", crowded), AGENT_SPEECH_DIRECTED, "A nameless line from the partner must be read as a reply.")

	// The old bare timer made everyone in the room count as addressing the NPC once it spoke.
	TEST_ASSERT_EQUAL(controller.classify_speech(stranger, "yes please", crowded), AGENT_SPEECH_AMBIGUOUS, "The same line from someone else must not borrow the partner's conversation.")

	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_partner_turning_away_is_overheard

/datum/unit_test/agent_npc_partner_turning_away_is_overheard/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human)
	agent_test_engage(controller.binding, partner)
	TEST_ASSERT(controller.binding.is_partner(partner), "Setup failed: the speaker should be the partner.")

	// However recently they spoke to us, "Bob, pass the ale" is for Bob. The rule order is deliberate.
	TEST_ASSERT_EQUAL(controller.classify_speech(partner, "Bob, pass the ale", agent_test_speech_context(distance = 1, nearby_people = 2, named_someone_else = TRUE)), AGENT_SPEECH_OVERHEARD, "A partner addressing someone else must be heard as talking to them.")

	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_partner_lapses_after_silence

/datum/unit_test/agent_npc_partner_lapses_after_silence/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human)
	agent_test_engage(controller.binding, partner)

	controller.binding.partner_until = world.time - 1

	// Someone who walked off and came back later is not mid-sentence.
	TEST_ASSERT(!controller.binding.is_partner(partner), "A conversation must lapse once its window has passed.")
	TEST_ASSERT_EQUAL(controller.classify_speech(partner, "yes please", agent_test_speech_context(distance = 1, nearby_people = 2)), AGENT_SPEECH_AMBIGUOUS, "A lapsed partner must be treated like anyone else.")

	// Speaking again inside the window keeps a live conversation open.
	agent_test_engage(controller.binding, partner)
	controller.binding.partner_until = world.time + 5
	controller.binding.note_candidate(partner)
	TEST_ASSERT(controller.binding.partner_until >= world.time + AGENT_REPLY_WINDOW, "The partner speaking again must extend the conversation.")

	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_answering_engages_and_waiting_declines

/datum/unit_test/agent_npc_answering_engages_and_waiting_declines/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	var/datum/agent_binding/binding = controller.binding
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)
	binding.end_conversation()
	binding.end_continuation()

	// Through the real dispatch path, where answering or waiting is actually decided.
	var/datum/agent_response/waiting = new()
	waiting.ok = TRUE
	waiting.action = list("name" = "wait")
	binding.note_candidate(speaker)
	SSagent_npc.dispatch_decision(binding, waiting)

	// Waiting declines the line, and a declined line must not engage through a later unrelated action.
	TEST_ASSERT(!binding.is_partner(speaker), "Choosing to wait must not make the speaker a partner.")
	TEST_ASSERT_NULL(binding.candidate_ref, "Waiting must drop the candidate, not leave it to engage later.")

	var/datum/agent_response/answering = new()
	answering.ok = TRUE
	answering.action = list("name" = "say", "text" = "Good day to you.")
	binding.note_candidate(speaker)
	SSagent_npc.dispatch_decision(binding, answering)

	TEST_ASSERT(binding.is_partner(speaker), "Answering must make the speaker the partner.")
	TEST_ASSERT(binding.in_interaction(), "Answering must begin an interaction, so the NPC can follow through.")

	qdel(waiting)
	qdel(answering)
	agent_test_restore_subsystem(saved, binding)

/datum/unit_test/agent_npc_unclear_speech_buys_turns_only_when_answered

/datum/unit_test/agent_npc_unclear_speech_buys_turns_only_when_answered/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	TEST_ASSERT_NOTNULL(SSagent_npc.telemetry, "Setup failed: the subsystem must hold telemetry.")
	var/datum/agent_binding/binding = controller.binding
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human)
	var/saved_requests = SSagent_npc.telemetry.ambiguous_requests
	SSagent_npc.telemetry.ambiguous_requests = 0
	binding.ambiguous_at = 0
	binding.take_events()
	binding.end_continuation()

	var/route = controller.route_speech(AGENT_SPEECH_AMBIGUOUS, "Ivan", "hello there", list("speaker" = "Ivan", "text" = "hello there"), FALSE, stranger)
	var/turns_on_hearing = binding.in_interaction()
	var/engaged = binding.engage_candidate()
	var/turns_on_answering = binding.in_interaction()
	// Restored before asserting: a failed assertion returns from Run().
	SSagent_npc.telemetry.ambiguous_requests = saved_requests

	TEST_ASSERT_EQUAL(route, "sent", "Setup failed: the unclear line should buy its one decision.")

	// A stranger's passing remark must not start a two-minute chain on its own.
	TEST_ASSERT(!turns_on_hearing, "An unclear line must not buy self-driven turns just by being heard.")

	// Answering is evidence it was ours, and a nameless "fetch the salt" needs its three steps.
	TEST_ASSERT(engaged, "The unclear line's speaker must be the candidate.")
	TEST_ASSERT(turns_on_answering, "Answering an unclear line must begin the interaction it did not get on hearing.")

	agent_test_restore_subsystem(saved, binding)

/datum/unit_test/agent_npc_directed_speech_buys_turns_on_hearing

/datum/unit_test/agent_npc_directed_speech_buys_turns_on_hearing/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)
	controller.binding.take_events()
	controller.binding.end_continuation()

	TEST_ASSERT_EQUAL(controller.route_speech(AGENT_SPEECH_DIRECTED, "Ivan", "Isaac, fetch the salt", list("speaker" = "Ivan", "text" = "Isaac, fetch the salt"), FALSE, speaker), "sent", "Setup failed: a directed line should buy a decision.")

	// Being named is the strongest evidence; the chain must not wait for the NPC to answer first.
	TEST_ASSERT(controller.binding.in_interaction(), "Directed speech must buy self-driven turns as soon as it is heard.")

	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_another_agent_is_never_given_turns

/datum/unit_test/agent_npc_another_agent_is_never_given_turns/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/mob/living/carbon/human/species/human/northern/agent_social/other = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/ai_controller/agent_social/other_controller = other.ai_controller
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	TEST_ASSERT_NOTNULL(other_controller?.binding, "Setup failed: the other agent must be bound.")
	TEST_ASSERT_NOTNULL(SSagent_npc.bindings["[REF(other)]"], "Setup failed: the other agent must be registered.")
	controller.binding.end_continuation()

	var/engaged = agent_test_engage(controller.binding, other)
	var/given_turns = controller.binding.in_interaction()
	SSagent_npc.unregister_pawn(other_controller.binding, "test teardown")

	TEST_ASSERT(engaged, "Answering another agent must still be allowed.")

	// Two agents buying each other turns never stops. Engaging is fine; the turns are not.
	TEST_ASSERT(!given_turns, "Answering another agent must never begin an interaction.")

	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_revoke_ends_the_conversation

/datum/unit_test/agent_npc_revoke_ends_the_conversation/Run()
	var/datum/agent_binding/binding = agent_test_binding("conversation-revoke")
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human)
	agent_test_engage(binding, partner)
	TEST_ASSERT(binding.is_partner(partner), "Setup failed: the speaker should be the partner.")

	binding.revoke("test")

	TEST_ASSERT(!binding.is_partner(partner), "A revoked binding must not keep a conversation open.")
	TEST_ASSERT_NULL(binding.partner_ref, "Revoking must drop the partner reference.")

	qdel(binding)

/datum/unit_test/agent_npc_speech_alone_with_us_is_ours

/datum/unit_test/agent_npc_speech_alone_with_us_is_ours/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller, "Setup failed: the pawn must carry an agent controller.")
	controller.binding?.end_continuation()
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)
	var/far = AGENT_DIRECT_SPEECH_RANGE + 3

	// Stated out of range, or this proves nothing: a nearby speaker is ours by
	// the distance rule whether or not this rule exists. Found by mutation.
	TEST_ASSERT_EQUAL(controller.classify_speech(speaker, "nice weather", agent_test_speech_context(distance = far, nearby_people = 0)), AGENT_SPEECH_DIRECTED, "With nobody else present, distant speech must still be ours.")

	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_unconscious_mobs_are_not_an_audience

/datum/unit_test/agent_npc_unconscious_mobs_are_not_an_audience/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller, "Setup failed: the pawn must carry an agent controller.")
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/sleeper = allocate(/mob/living/carbon/human)

	// Counted as a delta, because other tests leave mobs standing around.
	var/list/awake = controller.build_speech_context(speaker, "hello", "hello", null)
	TEST_ASSERT_NOTNULL(awake, "Setup failed: a context must be built.")
	TEST_ASSERT(awake["nearby_people"] >= 1, "Setup failed: a conscious third mob should be counted.")

	sleeper.stat = UNCONSCIOUS
	var/list/asleep = controller.build_speech_context(speaker, "hello", "hello", null)

	// Somebody who cannot hear is not somebody the speaker could have meant, so
	// counting them makes the NPC hold its tongue for an audience that is not there.
	TEST_ASSERT_EQUAL(asleep["nearby_people"], awake["nearby_people"] - 1, "An unconscious mob must not count as an alternative audience.")

	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_unmatchable_script_keeps_distant_speech

/datum/unit_test/agent_npc_unmatchable_script_keeps_distant_speech/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller, "Setup failed: the pawn must carry an agent controller.")
	controller.binding?.end_continuation()
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)
	var/far = AGENT_DIRECT_SPEECH_RANGE + 3

	TEST_ASSERT_EQUAL(controller.classify_speech(speaker, "nice weather", agent_test_speech_context(distance = far, nearby_people = 2, script = AGENT_SCRIPT_LATIN)), AGENT_SPEECH_OVERHEARD, "Setup failed: distant Latin speech should be set aside.")

	// The name rule is the escape hatch that lets a distant call through. In a
	// script we cannot match a Latin name against, that rule can never fire, so
	// applying the distance rule anyway silences exactly one language group.
	TEST_ASSERT_EQUAL(controller.classify_speech(speaker, "nice weather", agent_test_speech_context(distance = far, nearby_people = 2, script = AGENT_SCRIPT_OTHER)), AGENT_SPEECH_AMBIGUOUS, "Distance must not suppress speech in a script whose names we cannot match.")

	agent_test_restore_subsystem(saved, controller.binding)

// ----------------------------------------------------------------- routing

/datum/unit_test/agent_npc_ambiguous_speech_is_rationed

/datum/unit_test/agent_npc_ambiguous_speech_is_rationed/Run()
	var/datum/agent_binding/binding = agent_test_binding("ration-pawn")
	binding.ambiguous_at = 0

	TEST_ASSERT(binding.may_spend_on_ambiguous(), "Setup failed: a fresh binding should be allowed one.")
	binding.note_ambiguous_spend()

	// Unbounded, a busy tavern is an unlimited stream of paid decisions: one
	// pawn answering chatter can outspend a whole round on its own.
	TEST_ASSERT(!binding.may_spend_on_ambiguous(), "A second unclear line must be rationed while the cooldown runs.")

	binding.ambiguous_at = world.time - AGENT_AMBIGUOUS_INTERVAL - 1
	TEST_ASSERT(binding.may_spend_on_ambiguous(), "Once the cooldown has passed, another unclear line may be answered.")

	// The per-pawn cooldown is not the only bound. Without the round limit, a
	// pawn in a busy room answers one unclear line every twelve seconds forever.
	var/blocked_by_round = FALSE
	if(SSagent_npc.telemetry)
		var/saved_requests = SSagent_npc.telemetry.ambiguous_requests
		SSagent_npc.telemetry.ambiguous_requests = AGENT_AMBIGUOUS_ROUND_LIMIT
		blocked_by_round = !binding.may_spend_on_ambiguous()
		// Restored before asserting: a failed assertion returns from Run().
		SSagent_npc.telemetry.ambiguous_requests = saved_requests
	TEST_ASSERT(blocked_by_round, "The round limit must stop a pawn whose own cooldown has expired.")

	qdel(binding)

/datum/unit_test/agent_npc_directed_speech_is_never_rationed

/datum/unit_test/agent_npc_directed_speech_is_never_rationed/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")

	// Spend the allowance, then address the NPC by name.
	controller.binding.note_ambiguous_spend()
	TEST_ASSERT(!controller.binding.may_spend_on_ambiguous(), "Setup failed: the allowance should be spent.")

	TEST_ASSERT_EQUAL(controller.route_speech(AGENT_SPEECH_AMBIGUOUS, "Ivan", "something vague", list("speaker" = "Ivan", "text" = "something vague")), "rationed", "An unclear line must be rationed once the allowance is spent.")

	// The whole point of classifying: being spoken to directly must never be
	// rationed, however much ambient chatter came before it.
	TEST_ASSERT_EQUAL(controller.route_speech(AGENT_SPEECH_DIRECTED, "Ivan", "a clear question", list("speaker" = "Ivan", "text" = "a clear question")), "sent", "Directed speech must bypass the ration entirely.")

	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_rationed_speech_is_kept_not_dropped

/datum/unit_test/agent_npc_rationed_speech_is_kept_not_dropped/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	controller.binding.take_events()
	controller.binding.note_ambiguous_spend()

	var/before = length(controller.binding.events)
	TEST_ASSERT_EQUAL(controller.route_speech(AGENT_SPEECH_AMBIGUOUS, "Ivan", "rationed line", list("speaker" = "Ivan", "text" = "rationed line")), "rationed", "Setup failed: this line should be rationed.")

	// Rationed means "does not buy a decision", never "is thrown away". The line
	// still reaches the agent with whatever it does next.
	TEST_ASSERT_EQUAL(length(controller.binding.events), before + 1, "A rationed line must still be remembered.")
	TEST_ASSERT(!controller.binding.dirty, "A rationed line must not schedule a request.")

	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_repeated_lines_are_not_buffered_twice

/datum/unit_test/agent_npc_repeated_lines_are_not_buffered_twice/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	controller.binding.take_events()

	var/list/detail = list("speaker" = "Ivan", "text" = "hello hello")
	TEST_ASSERT_EQUAL(controller.route_speech(AGENT_SPEECH_OVERHEARD, "Ivan", "hello hello", detail), "buffered", "Setup failed: the first copy should be buffered.")

	// The ring holds twelve. Somebody repeating themselves must not push out the
	// question a third player actually asked.
	TEST_ASSERT_EQUAL(controller.route_speech(AGENT_SPEECH_OVERHEARD, "Ivan", "hello hello", detail), "duplicate", "An identical line already waiting must not be buffered again.")
	TEST_ASSERT_EQUAL(length(controller.binding.events), 1, "Only one copy of a repeated line may be held.")

	// A different speaker saying the same words is a different event.
	TEST_ASSERT_EQUAL(controller.route_speech(AGENT_SPEECH_OVERHEARD, "Anna", "hello hello", list("speaker" = "Anna", "text" = "hello hello")), "buffered", "The same words from someone else must still be kept.")

	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_ambiguous_budget_is_bounded_per_round

/datum/unit_test/agent_npc_ambiguous_budget_is_bounded_per_round/Run()
	TEST_ASSERT_NOTNULL(SSagent_npc.telemetry, "Setup failed: the subsystem must hold telemetry.")
	var/saved_requests = SSagent_npc.telemetry.ambiguous_requests

	SSagent_npc.telemetry.ambiguous_requests = 0
	TEST_ASSERT(SSagent_npc.ambiguous_budget_left(), "An unused round must have budget.")

	SSagent_npc.telemetry.ambiguous_requests = AGENT_AMBIGUOUS_ROUND_LIMIT
	TEST_ASSERT(!SSagent_npc.ambiguous_budget_left(), "The round limit must stop further unclear lines buying decisions.")

	SSagent_npc.telemetry.ambiguous_requests = saved_requests

/datum/unit_test/agent_npc_rationing_fails_open_without_telemetry

/datum/unit_test/agent_npc_rationing_fails_open_without_telemetry/Run()
	var/datum/agent_telemetry/saved = SSagent_npc.telemetry
	SSagent_npc.telemetry = null

	var/caught = FALSE
	var/allowed = FALSE
	try
		allowed = SSagent_npc.ambiguous_budget_left()
		SSagent_npc.note_ambiguous_request()
		SSagent_npc.note_ambiguous_deferred()
	catch
		caught = TRUE

	SSagent_npc.telemetry = saved

	TEST_ASSERT(!caught, "Rationing must tolerate absent telemetry rather than runtime.")
	// Not being able to count is not a reason for an NPC to start ignoring people.
	TEST_ASSERT(allowed, "With nothing measuring, the budget check must fail open.")



/datum/unit_test/agent_npc_overheard_speech_does_not_schedule_a_request

/datum/unit_test/agent_npc_overheard_speech_does_not_schedule_a_request/Run()
	var/datum/agent_binding/binding = agent_test_binding("addressing-pawn")
	binding.clear_dirty()
	binding.end_continuation()

	TEST_ASSERT(binding.push_event("overheard_speech", AGENT_EVENT_LOW, list("text" = "Bob, pass the ale")), "An ambient push must be accepted.")

	// The whole point: remembered and delivered with the next real decision,
	// rather than buying one of its own.
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

// ------------------------------------------------------------- explicit focus

/datum/unit_test/agent_npc_focus_outranks_every_rule

/datum/unit_test/agent_npc_focus_outranks_every_rule/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	controller.binding.end_conversation()
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)
	var/list/elsewhere = agent_test_speech_context(distance = AGENT_DIRECT_SPEECH_RANGE + 2, nearby_people = 3, named_someone_else = TRUE)

	TEST_ASSERT_EQUAL(controller.classify_speech(speaker, "Bob, pass the ale", elsewhere), AGENT_SPEECH_OVERHEARD, "Setup failed: without focus this line belongs to Bob.")

	// Talk To, checked by the server: the one answer to "who was this for" that is not a guess.
	elsewhere["focused"] = TRUE
	TEST_ASSERT_EQUAL(controller.classify_speech(speaker, "Bob, pass the ale", elsewhere), AGENT_SPEECH_DIRECTED, "Explicit focus must outrank every inferred rule, including someone else being named.")

	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_focus_elsewhere_is_overheard

/datum/unit_test/agent_npc_focus_elsewhere_is_overheard/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	controller.binding.end_conversation()
	pawn.name_override = "Anna Smith"
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)
	var/list/elsewhere = agent_test_speech_context(distance = 1, nearby_people = 2, focused_elsewhere = TRUE)

	TEST_ASSERT_EQUAL(controller.classify_speech(speaker, "nice weather", agent_test_speech_context(distance = 1, nearby_people = 2)), AGENT_SPEECH_AMBIGUOUS, "Setup failed: without focus elsewhere this line is unclear.")

	// The player picked another NPC. Two NPCs both answering is what Talk To exists to prevent.
	TEST_ASSERT_EQUAL(controller.classify_speech(speaker, "nice weather", elsewhere), AGENT_SPEECH_OVERHEARD, "A line from a player focused on another NPC must be overheard.")

	// Explicit focus outranks the whisper heuristic: standing close is not choosing.
	var/list/whispered = agent_test_speech_context(distance = AGENT_WHISPER_INTENDED_RANGE, whispered = TRUE, nearby_people = 2, focused_elsewhere = TRUE)
	TEST_ASSERT_EQUAL(controller.classify_speech(speaker, "nice weather", whispered), AGENT_SPEECH_OVERHEARD, "A whisper from a player focused elsewhere must still be overheard.")

	// Our own name said strongly still wins: someone talking to Isaac who says "Anna, come here" means Anna.
	TEST_ASSERT_EQUAL(controller.classify_speech(speaker, "Anna, come here", elsewhere), AGENT_SPEECH_DIRECTED, "Our own name said strongly must outrank focus on someone else.")

	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_focus_elsewhere_reaches_the_context

/datum/unit_test/agent_npc_focus_elsewhere_reaches_the_context/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/chosen = agent_test_bound_pawn()
	var/mob/living/carbon/human/species/human/northern/agent_social/other = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/chosen_controller = chosen.ai_controller
	var/datum/ai_controller/agent_social/other_controller = other.ai_controller
	TEST_ASSERT_NOTNULL(chosen_controller?.binding, "Setup failed: the chosen NPC must be bound.")
	TEST_ASSERT_NOTNULL(other_controller?.binding, "Setup failed: the other NPC must be bound.")
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)

	TEST_ASSERT_NULL(agent_focus_on(speaker, chosen), "Setup failed: turning to the chosen NPC should succeed.")

	var/list/at_chosen = chosen_controller.build_speech_context(speaker, "hello", "hello", null)
	var/list/at_other = other_controller.build_speech_context(speaker, "hello", "hello", null)
	var/counts_own_focus = agent_focus_held_elsewhere(speaker, chosen_controller.binding)

	// Measured from the chosen NPC: walk away from it and everyone else must hear you again.
	var/turf/here = get_turf(chosen)
	var/turf/far = locate(here.x + AGENT_FOCUS_RANGE + 2, here.y, here.z)
	var/list/after_leaving = null
	if(far)
		speaker.forceMove(far)
		after_leaving = other_controller.build_speech_context(speaker, "hello", "hello", null)

	SSagent_npc.unregister_pawn(other_controller.binding, "test teardown")

	TEST_ASSERT(at_chosen["focused"], "The chosen NPC must read the line as focused on it.")
	TEST_ASSERT(!at_chosen["focused_elsewhere"], "The chosen NPC must not read its own focus as elsewhere.")
	TEST_ASSERT(!counts_own_focus, "A focus on this very NPC must not count as focus elsewhere.")
	TEST_ASSERT(!at_other["focused"], "Another NPC must not read the line as focused on it.")
	TEST_ASSERT(at_other["focused_elsewhere"], "Another NPC must know the player turned to someone else.")

	TEST_ASSERT_NOTNULL(after_leaving, "Setup failed: need a turf beyond focus range.")
	TEST_ASSERT(!after_leaving["focused_elsewhere"], "A player who walked away from the chosen NPC must be heard by others again.")

	agent_test_restore_subsystem(saved, chosen_controller.binding)

/datum/unit_test/agent_npc_focus_on_validates_the_target

/datum/unit_test/agent_npc_focus_on_validates_the_target/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/target = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = target.ai_controller
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the target must be bound.")
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/ordinary = allocate(/mob/living/carbon/human)

	// Nothing the verb passes is trusted. Each of these is refused on the server.
	TEST_ASSERT_NOTNULL(agent_focus_on(speaker, speaker), "A player must not be able to focus on themselves.")
	// Wrapped: a runtime here would abort Run() and record a pass. try/catch is what sees it.
	var/caught = FALSE
	var/ordinary_refusal
	try
		ordinary_refusal = agent_focus_on(speaker, ordinary)
	catch
		caught = TRUE
	TEST_ASSERT(!caught, "Focusing a mob with no agent controller must be refused cleanly, not runtime.")
	TEST_ASSERT_NOTNULL(ordinary_refusal, "A mob with no agent controller must not accept focus.")
	TEST_ASSERT_NOTNULL(agent_focus_on(speaker, null), "A missing target must be refused.")

	speaker.stat = UNCONSCIOUS
	var/unconscious_refusal = agent_focus_on(speaker, target)
	speaker.stat = CONSCIOUS
	TEST_ASSERT_NOTNULL(unconscious_refusal, "An unconscious player must not be able to start a conversation.")

	TEST_ASSERT_NULL(agent_focus_on(speaker, target), "A conscious player beside an agent NPC must be able to turn to it.")
	TEST_ASSERT(controller.binding.has_focus_from(speaker), "Accepted focus must be recorded on the NPC.")

	// Distance is checked here too, not only at the moment of speech.
	agent_focus_off(speaker)
	var/turf/here = get_turf(target)
	TEST_ASSERT_NOTNULL(here, "Setup failed: the target must be standing somewhere.")
	var/turf/far = locate(here.x + AGENT_FOCUS_RANGE + 2, here.y, here.z)
	TEST_ASSERT_NOTNULL(far, "Setup failed: need a turf beyond focus range.")
	speaker.forceMove(far)
	TEST_ASSERT_NOTNULL(agent_focus_on(speaker, target), "A target beyond focus range must be refused.")
	TEST_ASSERT(!controller.binding.has_focus_from(speaker), "A refused focus must not be recorded.")

	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_focus_is_one_at_a_time

/datum/unit_test/agent_npc_focus_is_one_at_a_time/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/first = agent_test_bound_pawn()
	var/mob/living/carbon/human/species/human/northern/agent_social/second = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/first_controller = first.ai_controller
	var/datum/ai_controller/agent_social/second_controller = second.ai_controller
	TEST_ASSERT_NOTNULL(first_controller?.binding, "Setup failed: the first NPC must be bound.")
	TEST_ASSERT_NOTNULL(second_controller?.binding, "Setup failed: the second NPC must be bound.")
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)

	TEST_ASSERT_NULL(agent_focus_on(speaker, first), "Setup failed: focusing the first NPC should succeed.")
	TEST_ASSERT_NULL(agent_focus_on(speaker, second), "Setup failed: focusing the second NPC should succeed.")

	var/still_on_first = first_controller.binding.has_focus_from(speaker)
	var/on_second = second_controller.binding.has_focus_from(speaker)
	var/mob/living/current = agent_focus_target_of(speaker)
	SSagent_npc.unregister_pawn(second_controller.binding, "test teardown")

	// Otherwise both NPCs believe every line is meant for them.
	TEST_ASSERT(!still_on_first, "Turning to a second NPC must release the first.")
	TEST_ASSERT(on_second, "The second NPC must hold the focus.")
	TEST_ASSERT(current == second, "The player's current focus must be the NPC they turned to last.")

	agent_test_restore_subsystem(saved, first_controller.binding)

/datum/unit_test/agent_npc_focus_lapses_in_silence

/datum/unit_test/agent_npc_focus_lapses_in_silence/Run()
	var/datum/agent_binding/binding = agent_test_binding("focus-lapse")
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)

	TEST_ASSERT(binding.set_focus(speaker), "Setup failed: focus should be accepted.")
	TEST_ASSERT(binding.has_focus_from(speaker), "Setup failed: focus should be in force.")

	binding.focusers[WEAKREF(speaker)] = world.time - 1

	TEST_ASSERT(!binding.has_focus_from(speaker), "Focus must lapse once its time has passed.")
	TEST_ASSERT(isnull(binding.focusers[WEAKREF(speaker)]), "A lapsed focus must be pruned, not kept forever.")

	// Speaking keeps it alive: it lapses in silence, never mid-conversation.
	binding.set_focus(speaker)
	binding.focusers[WEAKREF(speaker)] = world.time + 5
	binding.note_candidate(speaker)
	TEST_ASSERT(binding.focusers[WEAKREF(speaker)] >= world.time + AGENT_FOCUS_DURATION, "Speaking under focus must renew it.")

	qdel(binding)

/datum/unit_test/agent_npc_focus_reaches_the_speech_context

/datum/unit_test/agent_npc_focus_reaches_the_speech_context/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)

	var/list/unfocused = controller.build_speech_context(speaker, "hello", "hello", null)
	TEST_ASSERT_NOTNULL(unfocused, "Setup failed: a context must be built.")
	TEST_ASSERT(!unfocused["focused"], "Speech from a player who has not turned to the NPC must not read as focused.")

	controller.binding.set_focus(speaker)
	var/list/focused = controller.build_speech_context(speaker, "hello", "hello", null)
	TEST_ASSERT(focused["focused"], "Speech from a player who turned to the NPC must read as focused.")

	// Walking away should end it, whatever the timer says.
	var/turf/here = get_turf(pawn)
	var/turf/far = locate(here.x + AGENT_FOCUS_RANGE + 2, here.y, here.z)
	TEST_ASSERT_NOTNULL(far, "Setup failed: need a turf beyond focus range.")
	speaker.forceMove(far)
	var/list/walked_off = controller.build_speech_context(speaker, "hello", "hello", null)
	TEST_ASSERT(!walked_off["focused"], "Focus must not count once the player is out of range.")

	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_revoke_clears_focus

/datum/unit_test/agent_npc_revoke_clears_focus/Run()
	var/datum/agent_binding/binding = agent_test_binding("focus-revoke")
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)
	binding.set_focus(speaker)
	TEST_ASSERT(binding.has_focus_from(speaker), "Setup failed: focus should be in force.")

	binding.revoke("test")

	TEST_ASSERT(!binding.has_focus_from(speaker), "A revoked NPC must not keep anyone's focus.")

	qdel(binding)

/datum/unit_test/agent_npc_repeated_line_is_upgraded_not_dropped

/datum/unit_test/agent_npc_repeated_line_is_upgraded_not_dropped/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)
	controller.binding.take_events()

	TEST_ASSERT_EQUAL(controller.route_speech(AGENT_SPEECH_OVERHEARD, "Ivan", "hello", list("speaker" = "Ivan", "text" = "hello")), "buffered", "Setup failed: the first copy should be set aside.")

	// Said again with Talk To. The old early duplicate check dropped it, silencing the NPC when it mattered most.
	var/route = controller.route_speech(AGENT_SPEECH_DIRECTED, "Ivan", "hello", list("speaker" = "Ivan", "text" = "hello"), FALSE, speaker)

	var/copies = 0
	var/heard_copies = 0
	for(var/list/entry as anything in controller.binding.events)
		var/list/detail = entry["detail"]
		if(!islist(detail) || detail["text"] != "hello")
			continue
		copies++
		if(entry["event"] == "heard_speech")
			heard_copies++

	TEST_ASSERT_EQUAL(route, "sent", "A directed repeat of an overheard line must be sent, not dropped as a duplicate.")
	TEST_ASSERT_EQUAL(copies, 1, "Exactly one copy of the line may be kept.")
	TEST_ASSERT_EQUAL(heard_copies, 1, "The copy kept must be the one to answer, not the one set aside.")

	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_rationed_repeats_are_not_kept_twice

/datum/unit_test/agent_npc_rationed_repeats_are_not_kept_twice/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	controller.binding.take_events()
	controller.binding.note_ambiguous_spend()

	TEST_ASSERT_EQUAL(controller.route_speech(AGENT_SPEECH_AMBIGUOUS, "Ivan", "anyone there", list("speaker" = "Ivan", "text" = "anyone there")), "rationed", "Setup failed: the first copy should be rationed.")

	// The duplicate check must still guard the rationed path after moving.
	TEST_ASSERT_EQUAL(controller.route_speech(AGENT_SPEECH_AMBIGUOUS, "Ivan", "anyone there", list("speaker" = "Ivan", "text" = "anyone there")), "duplicate", "A rationed repeat must not be kept twice.")

	agent_test_restore_subsystem(saved, controller.binding)

// ----------------------------------------------- re-evaluation, 2026-09-23

/datum/unit_test/agent_npc_placeholder_names_never_match

/datum/unit_test/agent_npc_placeholder_names_never_match/Run()
	// A hidden face reads "Unknown Man"; matching it woke a masked NPC on every "man".
	TEST_ASSERT(!agent_name_matches_loosely("Unknown Man", "that man over there"), "A placeholder name must not wake the NPC on its ordinary words.")
	TEST_ASSERT(!agent_name_matches_loosely("Unknown", "unknown to me"), "The bare placeholder must not match either.")

	// Worse, a masked bystander made any line starting "Man," read as addressed to them.
	TEST_ASSERT(!agent_name_in_vocative("Unknown Man", "Man, that was close"), "A placeholder bystander must never suppress a response.")
	TEST_ASSERT(!agent_name_in_vocative("Unknown Woman", "Woman, come here"), "No placeholder form may suppress.")

	TEST_ASSERT(agent_name_is_placeholder("Unknown Figure"), "Every placeholder form must be recognised.")
	TEST_ASSERT(!agent_name_is_placeholder("Isaac Brown"), "A real name must not read as a placeholder.")

/datum/unit_test/agent_npc_filler_words_are_not_name_parts

/datum/unit_test/agent_npc_filler_words_are_not_name_parts/Run()
	// Mob names carry articles. "the" is not how anyone addresses "the goat".
	TEST_ASSERT(!agent_name_matches_loosely("the goat", "the weather is fine"), "An article in a mob's name must not match ordinary speech.")
	TEST_ASSERT(agent_name_matches_loosely("the goat", "goat, come here"), "The real part of the name must still match.")

/datum/unit_test/agent_npc_self_address_has_strength

/datum/unit_test/agent_npc_self_address_has_strength/Run()
	// Any match used to be directed, unrationed: an NPC named Will answered every "I will go now".
	TEST_ASSERT_EQUAL(agent_self_address_strength("Will Baker", "I will go now"), AGENT_NAMED_WEAK, "A common-word name in the middle of a sentence must be a weak mention.")

	TEST_ASSERT_EQUAL(agent_self_address_strength("Will Baker", "Will, come here"), AGENT_NAMED_STRONG, "A vocative must be strong.")
	// Mid-sentence, so only the comma can make it strong.
	TEST_ASSERT_EQUAL(agent_self_address_strength("Will Baker", "hey Will, come here"), AGENT_NAMED_STRONG, "A vocative mid-sentence must be strong.")
	TEST_ASSERT_EQUAL(agent_self_address_strength("Will Baker", "come here Will"), AGENT_NAMED_STRONG, "The last word must be strong.")
	TEST_ASSERT_EQUAL(agent_self_address_strength("Will Baker", "Will you help me"), AGENT_NAMED_STRONG, "The first word must be strong.")
	TEST_ASSERT_EQUAL(agent_self_address_strength("Will Baker", "have you met Will Baker today"), AGENT_NAMED_STRONG, "The whole name must be strong wherever it falls.")
	TEST_ASSERT_EQUAL(agent_self_address_strength("Will Baker", "nothing to see here"), AGENT_NAMED_NONE, "No mention must be none.")

	// Transliterated names get the same grading.
	TEST_ASSERT_EQUAL(agent_self_address_strength("Isaac Brown", "Исаак, подойди сюда"), AGENT_NAMED_STRONG, "A transliterated vocative must be strong.")
	TEST_ASSERT_EQUAL(agent_self_address_strength("Isaac Brown", "с Исааком всё хорошо"), AGENT_NAMED_WEAK, "A transliterated name mid-sentence must be weak.")

/datum/unit_test/agent_npc_weak_mentions_are_rationed_not_certain

/datum/unit_test/agent_npc_weak_mentions_are_rationed_not_certain/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	controller.binding.end_conversation()
	pawn.name_override = "Will Baker"
	TEST_ASSERT_EQUAL(controller.addressable_name(), "Will Baker", "Setup failed: the NPC should be called Will Baker.")
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)
	var/list/crowded = agent_test_speech_context(distance = 1, nearby_people = 3)
	var/far = AGENT_DIRECT_SPEECH_RANGE + 3

	// Unclear, so it still wakes the NPC, but through the ration.
	TEST_ASSERT_EQUAL(controller.classify_speech(speaker, "I will go now", crowded), AGENT_SPEECH_AMBIGUOUS, "A weak mention must be unclear, not directed.")
	TEST_ASSERT_EQUAL(controller.classify_speech(speaker, "Will, come here", crowded), AGENT_SPEECH_DIRECTED, "A strong mention must still be directed.")

	// People react to their own name, even in a line to someone else. Attention, not silence.
	TEST_ASSERT_EQUAL(controller.classify_speech(speaker, "Bob, I will ask him", agent_test_speech_context(distance = 1, nearby_people = 3, named_someone_else = TRUE)), AGENT_SPEECH_AMBIGUOUS, "Our name in a line to someone else must earn attention.")
	TEST_ASSERT_EQUAL(controller.classify_speech(speaker, "Bob, pass the ale", agent_test_speech_context(distance = 1, nearby_people = 3, named_someone_else = TRUE)), AGENT_SPEECH_OVERHEARD, "A line to someone else without our name must stay overheard.")
	TEST_ASSERT_EQUAL(controller.classify_speech(speaker, "I will go now", agent_test_speech_context(distance = far, nearby_people = 3)), AGENT_SPEECH_AMBIGUOUS, "Our name from across the room must earn attention.")
	TEST_ASSERT_EQUAL(controller.classify_speech(speaker, "nice weather today", agent_test_speech_context(distance = far, nearby_people = 3)), AGENT_SPEECH_OVERHEARD, "Distant chatter without our name must stay overheard.")

	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_masked_npc_ignores_its_placeholder

/datum/unit_test/agent_npc_masked_npc_ignores_its_placeholder/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	controller.binding.end_conversation()
	pawn.name_override = "Unknown Man"
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)

	TEST_ASSERT_EQUAL(controller.classify_speech(speaker, "that man over there is odd", agent_test_speech_context(distance = 1, nearby_people = 3)), AGENT_SPEECH_AMBIGUOUS, "A masked NPC must not treat the word man as its own name.")

	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_long_lines_are_searched_at_the_edges

/datum/unit_test/agent_npc_long_lines_are_searched_at_the_edges/Run()
	var/list/filler = list()
	for(var/i in 1 to 100)
		filler += "word"
	var/middle = filler.Join(" ") + " Isaac " + filler.Join(" ")
	var/edges = "Isaac, " + filler.Join(" ") + " " + filler.Join(" ")

	// Only the edges of a long line are searched. A name mid-monologue reads as unclear, which still wakes.
	TEST_ASSERT_EQUAL(agent_self_address_strength("Isaac Brown", middle), AGENT_NAMED_NONE, "The middle of a long line must not be searched.")
	TEST_ASSERT_EQUAL(agent_self_address_strength("Isaac Brown", edges), AGENT_NAMED_STRONG, "The start of a long line must still be searched.")

/datum/unit_test/agent_npc_script_is_decided_from_a_sample

/datum/unit_test/agent_npc_script_is_decided_from_a_sample/Run()
	var/latin = ""
	for(var/i in 1 to AGENT_SCRIPT_SAMPLE + 10)
		latin += "a"
	// A sample decides the script; per-word matching still finds a late Cyrillic name.
	TEST_ASSERT_EQUAL(agent_text_script(latin + " Исаак"), AGENT_SCRIPT_LATIN, "Script must be decided from the opening sample.")
	TEST_ASSERT(agent_name_matches_loosely("Isaac Brown", latin + " Исаак"), "A transliterated name after the sample must still be recognised.")
