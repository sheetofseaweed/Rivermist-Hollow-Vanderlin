/datum/unit_test/aroused_slur_has_no_drunk_interjections
#ifdef FOCUS_SPEECH_SLUR_TEST
	focus = TRUE
#endif

/datum/unit_test/aroused_slur_has_no_drunk_interjections/Run()
	var/message = ""
	for(var/i in 1 to 200)
		message += "soft. "

	var/slurred = aroused_slur(message)
	TEST_ASSERT(!findtext(uppertext(slurred), "BURP"), "Aroused slurring should not add drunk burps.")
	TEST_ASSERT(!findtext(LOWER_TEXT(slurred), "huuuhhh"), "Aroused slurring should not add drunk filler interjections.")

/datum/unit_test/cumbrained_uses_aroused_slurring
#ifdef FOCUS_SPEECH_SLUR_TEST
	focus = TRUE
#endif

/datum/unit_test/cumbrained_uses_aroused_slurring/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	patient.apply_status_effect(/datum/status_effect/debuff/cumbrained)

	TEST_ASSERT_EQUAL(patient.slurring, 0, "Cum-brained arousal should not use regular drunk slurring.")
	TEST_ASSERT(patient.aroused_slurring >= 4, "Cum-brained arousal should use aroused slurring.")

	var/message = patient.treat_message("soft.")
	TEST_ASSERT(!findtext(uppertext(message), "BURP"), "Cum-brained speech should not add drunk burps.")
