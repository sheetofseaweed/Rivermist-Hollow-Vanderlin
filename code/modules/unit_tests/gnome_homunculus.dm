/// The gnome hear handler read the hear payload as loose args, so friends never taught it words.
/datum/unit_test/gnome_learns_words_from_friends

/datum/unit_test/gnome_learns_words_from_friends/Run()
	var/mob/living/simple_animal/hostile/gnome_homunculus/gnome = allocate(/mob/living/simple_animal/hostile/gnome_homunculus)
	var/mob/living/carbon/human/friend = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human)
	TEST_ASSERT(istype(gnome.ai_controller, /datum/ai_controller/basic_controller/gnome_homunculus), "Test setup: the gnome should have its own AI controller.")

	SEND_SIGNAL(gnome, COMSIG_FRIENDSHIP_CHANGE, friend, 100)
	TEST_ASSERT(SEND_SIGNAL(gnome, COMSIG_FRIENDSHIP_CHECK_LEVEL, friend, "friend"), "Test setup: the friend should pass the gnome's friendship check.")
	TEST_ASSERT(!SEND_SIGNAL(gnome, COMSIG_FRIENDSHIP_CHECK_LEVEL, stranger, "friend"), "Test setup: the stranger should fail the gnome's friendship check.")
	var/datum/component/emotion_buffer/emotions = gnome.GetComponent(/datum/component/emotion_buffer)
	TEST_ASSERT_NOTNULL(emotions, "Test setup: the gnome should have an emotion buffer.")
	emotions.current_emotion = EMOTION_HAPPY
	gnome.learned_words.Cut()

	// Same argument order as send_speech; say() sanitizes, so the raw message is html-encoded.
	gnome.Hear("rendered", friend, null, sanitize("Hello, \"friend\"! *Waves* don't"), null, list())
	TEST_ASSERT_EQUAL(gnome.learned_words["hello"], 1, "A happy gnome should learn a word its friend says.")
	TEST_ASSERT_EQUAL(gnome.learned_words["friend"], 1, "Quoted words should be decoded and stripped, not learned as html entities.")
	TEST_ASSERT_EQUAL(gnome.learned_words["waves"], 1, "Asterisks should be stripped from learned words.")
	TEST_ASSERT_EQUAL(gnome.learned_words["don't"], 1, "Apostrophes inside a word should be kept.")
	TEST_ASSERT_EQUAL(length(gnome.learned_words), 4, "Only the four long words should be learned.")

	gnome.Hear("rendered", stranger, null, sanitize("Stranger danger"), null, list())
	TEST_ASSERT_NULL(gnome.learned_words["stranger"], "A gnome should not learn words from someone who is not its friend.")
