/datum/unit_test/non_craving_vices_do_not_create_generic_addiction
#ifdef FOCUS_QUIRKS_TEST
	focus = TRUE
#endif

/datum/unit_test/non_craving_vices_do_not_create_generic_addiction/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)

	TEST_ASSERT(human.add_quirk(/datum/quirk/vice/wanted), "Test human should accept the Wanted vice.")
	var/datum/quirk/vice/wanted/wanted = human.get_quirk(/datum/quirk/vice/wanted)
	TEST_ASSERT_NOTNULL(wanted, "Test human should have the Wanted vice.")

	wanted.next_sate = world.time - 1
	wanted.on_life(human)

	TEST_ASSERT_NULL(human.has_status_effect(/datum/status_effect/debuff/addiction), "Non-craving vices should not create generic addiction status effects.")
	TEST_ASSERT_NULL(human.has_stress_type(/datum/stress_event/vice1), "Non-craving vices should not create generic vice stress.")
	TEST_ASSERT_NULL(human.has_stress_type(/datum/stress_event/vice2), "Non-craving vices should not create generic vice stress.")
	TEST_ASSERT_NULL(human.has_stress_type(/datum/stress_event/vice3), "Non-craving vices should not create generic vice stress.")

/datum/unit_test/craving_vices_still_create_specific_addiction
#ifdef FOCUS_QUIRKS_TEST
	focus = TRUE
#endif

/datum/unit_test/craving_vices_still_create_specific_addiction/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)

	TEST_ASSERT(human.add_quirk(/datum/quirk/vice/smoker), "Test human should accept the Smoker vice.")
	var/datum/quirk/vice/smoker/smoker = human.get_quirk(/datum/quirk/vice/smoker)
	TEST_ASSERT_NOTNULL(smoker, "Test human should have the Smoker vice.")

	smoker.next_sate = world.time - 1
	smoker.on_life(human)

	TEST_ASSERT_NOTNULL(human.has_status_effect(/datum/status_effect/debuff/addiction/smoker), "Craving vices should keep creating their specific addiction status effects.")
	TEST_ASSERT_NOTNULL(human.has_stress_type(/datum/stress_event/vice1), "Craving vices should keep creating generic vice stress.")
