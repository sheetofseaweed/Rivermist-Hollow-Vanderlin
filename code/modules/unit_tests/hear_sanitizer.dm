/// A misplaced bracket made the hearing regex strip almost only quotes, so punctuated door phrases never matched.
/datum/unit_test/hear_sanitizer_strips_listed_chars

/datum/unit_test/hear_sanitizer_strips_listed_chars/Run()
	TEST_ASSERT_EQUAL(SANITIZE_HEAR_MESSAGE("a\"b\\c\nd\te/f?g%h*i:j|k<l>m.n,o"), "abcdefghijklmno", "Every listed character should be stripped from heard text.")
	TEST_ASSERT_EQUAL(SANITIZE_HEAR_MESSAGE("don't stop-now 42!"), "don't stop-now 42!", "Characters outside the list should be kept.")

	var/datum/secret_door_manager/manager = allocate(/datum/secret_door_manager, "unit_test_hear_sanitizer", null, list(), "unit test", "open sesame")
	var/obj/structure/door/secret/door = allocate(/obj/structure/door/secret)
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)
	door.use_phrases = TRUE
	manager.add_door(door)
	TEST_ASSERT(!door.door_opened, "Test setup: the secret door should start closed.")

	// Same argument order as send_speech; say() sanitizes, so the raw message is html-encoded.
	door.Hear("rendered", speaker, /datum/language/common, sanitize("Open, sesame."), null, list())
	TEST_ASSERT(door.switching_states, "A door phrase spoken with punctuation should start opening the door.")
	// Signal handlers run async and force_open sleeps through its animation, so wait it out.
	sleep(door.animate_time + 1)
	TEST_ASSERT(door.door_opened, "The secret door should finish opening.")
