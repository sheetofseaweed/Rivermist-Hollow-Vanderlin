// Who was that said to?
//
// The whole thing is lopsided on purpose. A wasted decision costs a fraction of
// a penny; an NPC that ignores a player talking to it reads as broken. Speech is
// only set aside on positive evidence that it belonged to somebody else.
//
// The classifier is driven entirely by a context list, so these tests state the
// scene exactly rather than depending on where allocate() happens to put a mob.

/// A speech scene, described rather than staged.
/datum/unit_test/proc/agent_test_speech_context(distance = 1, whispered = FALSE, volume = "0", nearby_people = 0, named_someone_else = FALSE, script = AGENT_SCRIPT_LATIN)
	return list(
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

/datum/unit_test/agent_npc_speech_mid_conversation_is_ours

/datum/unit_test/agent_npc_speech_mid_conversation_is_ours/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)
	var/list/elsewhere = agent_test_speech_context(distance = 1, nearby_people = 2, named_someone_else = TRUE)

	controller.binding.end_continuation()
	TEST_ASSERT_EQUAL(controller.classify_speech(speaker, "Bob, pass the ale", elsewhere), AGENT_SPEECH_OVERHEARD, "Setup failed: this line should read as someone else's.")

	controller.binding.begin_interaction()
	TEST_ASSERT(controller.binding.in_interaction(), "Setup failed: begin_interaction should start one.")

	// A reply does not carry your name.
	TEST_ASSERT_EQUAL(controller.classify_speech(speaker, "Bob, pass the ale", elsewhere), AGENT_SPEECH_DIRECTED, "While a conversation is running, speech must be read as part of it.")

	agent_test_restore_subsystem(saved, controller.binding)

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
