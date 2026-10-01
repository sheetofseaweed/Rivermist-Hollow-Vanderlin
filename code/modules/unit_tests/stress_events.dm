/datum/stress_event/unit_test_stacking
	stress_change = 3
	max_stacks = 3
	stress_change_per_extra_stack = 2
	timer = 5 MINUTES

/datum/stress_event/unit_test_untimed
	stress_change = 2

/datum/stress_event/unit_test_forever
	stress_change = 1
	timer = -1

/datum/stress_event/unit_test_calm
	stress_change = -2
	timer = 5 MINUTES

/datum/unit_test/stress_event_stacks/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/base_stress = human.stress
	// The fourth hit is past max_stacks and must not add anything.
	var/list/expected_stress = list(3, 5, 7, 7)
	for(var/hit in 1 to length(expected_stress))
		human.add_stress(/datum/stress_event/unit_test_stacking)
		var/datum/stress_event/event = human.has_stress_type(/datum/stress_event/unit_test_stacking)
		TEST_ASSERT_NOTNULL(event, "Hit [hit] should leave the event on the mob.")
		TEST_ASSERT_EQUAL(event.stacks, min(hit, event.max_stacks), "Hit [hit] should count as [min(hit, event.max_stacks)] stacks.")
		TEST_ASSERT_EQUAL(event.get_stress(), expected_stress[hit], "Hit [hit] should give [expected_stress[hit]] stress.")
		TEST_ASSERT_EQUAL(human.stress - base_stress, expected_stress[hit], "Hit [hit] should add its stress to the mob.")

	human.remove_stress(/datum/stress_event/unit_test_stacking)
	TEST_ASSERT_NULL(human.has_stress_type(/datum/stress_event/unit_test_stacking), "Removing the event should clear it.")
	TEST_ASSERT_EQUAL(human.stress, base_stress, "Removing the event should undo all of its stacked stress.")

/datum/unit_test/stress_event_malaguero_spares_tieflings/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.set_species(/datum/species/tieberian)
	var/base_stress = human.stress
	human.add_stress(/datum/stress_event/malaguero)
	human.add_stress(/datum/stress_event/malaguero)
	var/datum/stress_event/event = human.has_stress_type(/datum/stress_event/malaguero)
	TEST_ASSERT_NOTNULL(event, "Tieflings should still feel the malaguero.")
	TEST_ASSERT_EQUAL(event.get_stress(), 0, "Malaguero should give a tiefling no stress.")
	TEST_ASSERT_EQUAL(event.quality_modifier, 0, "Malaguero should not lower a tiefling's quality.")
	TEST_ASSERT_EQUAL(human.stress, base_stress, "Malaguero should not change a tiefling's stress.")

	human.remove_stress(/datum/stress_event/malaguero)
	TEST_ASSERT_EQUAL(human.stress, base_stress, "Removing malaguero should leave a tiefling's stress unchanged.")

/datum/unit_test/stress_event_untimed_lasts_until_removed/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/base_stress = human.stress
	human.add_stress(/datum/stress_event/unit_test_untimed)
	human.add_stress(/datum/stress_event/unit_test_forever)
	human.update_stress()
	TEST_ASSERT_NOTNULL(human.has_stress_type(/datum/stress_event/unit_test_untimed), "An event with no timer should outlast a stress update.")
	TEST_ASSERT_NOTNULL(human.has_stress_type(/datum/stress_event/unit_test_forever), "An event with a negative timer should outlast a stress update.")

	human.add_stress(/datum/stress_event/unit_test_untimed)
	human.update_stress()
	TEST_ASSERT_NOTNULL(human.has_stress_type(/datum/stress_event/unit_test_untimed), "Refreshing an event with no timer should not give it one.")
	TEST_ASSERT_EQUAL(human.stress - base_stress, 3, "Both events should keep their stress.")

	human.remove_stress(list(/datum/stress_event/unit_test_untimed, /datum/stress_event/unit_test_forever))
	TEST_ASSERT_NULL(human.has_stress_type(/datum/stress_event/unit_test_untimed), "remove_stress should end an event with no timer.")
	TEST_ASSERT_NULL(human.has_stress_type(/datum/stress_event/unit_test_forever), "remove_stress should end an event with a negative timer.")
	TEST_ASSERT_EQUAL(human.stress, base_stress, "Removing both events should undo their stress.")

/datum/unit_test/stress_event_timed_expires/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/base_stress = human.stress
	human.add_stress(/datum/stress_event/unit_test_stacking)
	var/datum/stress_event/event = human.has_stress_type(/datum/stress_event/unit_test_stacking)
	TEST_ASSERT_EQUAL(event.timer, world.time + 5 MINUTES, "A timed event should end one timer length from now.")
	human.update_stress()
	TEST_ASSERT_NOTNULL(human.has_stress_type(/datum/stress_event/unit_test_stacking), "A timed event should last until its timer ends.")

	event.timer = world.time
	human.update_stress()
	TEST_ASSERT_NULL(human.has_stress_type(/datum/stress_event/unit_test_stacking), "A timed event should end once its timer passes.")
	TEST_ASSERT_EQUAL(human.stress, base_stress, "An expired event should undo its stress.")

/datum/unit_test/stress_event_disgust_keeps_one_level/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/datum/organ_process/stomach/stomach_process = GLOB.organ_processes_by_slot[ORGAN_SLOT_STOMACH]
	TEST_ASSERT_NOTNULL(stomach_process, "The stomach organ process should exist.")
	var/list/disgust_by_level = list(
		/datum/stress_event/gross = DISGUST_LEVEL_GROSS + 10,
		/datum/stress_event/verygross = DISGUST_LEVEL_VERYGROSS + 10,
		/datum/stress_event/disgusted = DISGUST_LEVEL_DISGUSTED + 10,
	)
	// A zero delta_time makes every DT_PROB roll fail, so no random puking.
	for(var/level_type in disgust_by_level)
		human.disgust = disgust_by_level[level_type]
		stomach_process.handle_disgust(human, 0, 1)
		for(var/other_type in disgust_by_level)
			var/datum/stress_event/event = human.has_stress_type(other_type)
			if(other_type != level_type)
				TEST_ASSERT_NULL(event, "Disgust [human.disgust] should clear [other_type].")
				continue
			TEST_ASSERT_NOTNULL(event, "Disgust [human.disgust] should apply [level_type].")
			TEST_ASSERT(event.get_stress() > 0, "[level_type] should add stress, not relieve it.")

	human.disgust = 0
	stomach_process.handle_disgust(human, 0, 1)
	for(var/level_type in disgust_by_level)
		TEST_ASSERT_NULL(human.has_stress_type(level_type), "No disgust should clear [level_type].")

/datum/unit_test/stress_event_positive_and_negative_lists/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.add_stress(/datum/stress_event/unit_test_stacking)
	human.add_stress(/datum/stress_event/unit_test_calm)
	var/datum/stress_event/bad_event = human.has_stress_type(/datum/stress_event/unit_test_stacking)
	var/datum/stress_event/good_event = human.has_stress_type(/datum/stress_event/unit_test_calm)
	var/list/negative = human.get_negative_stressors()
	var/list/positive = human.get_positive_stressors()
	TEST_ASSERT(bad_event in negative, "A stressful event should be a negative stressor.")
	TEST_ASSERT(!(good_event in negative), "A calming event should not be a negative stressor.")
	TEST_ASSERT(good_event in positive, "A calming event should be a positive stressor.")
	TEST_ASSERT(!(bad_event in positive), "A stressful event should not be a positive stressor.")

/datum/unit_test/stress_event_fishface_desc_reads_viewer/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/datum/stress_event/fishface/event = new
	ADD_TRAIT(human, TRAIT_FISHFACE, TRAIT_GENERIC)
	TEST_ASSERT_EQUAL(event.get_desc(human), "Eh, I've seen worse faces than that.", "A fishface viewer should shrug off another fishface.")
	REMOVE_TRAIT(human, TRAIT_FISHFACE, TRAIT_GENERIC)
	ADD_TRAIT(human, TRAIT_TOLERANT, TRAIT_GENERIC)
	TEST_ASSERT_EQUAL(event.get_desc(human), "Poor thing. It's how they look I guess.", "A tolerant viewer should pity a fishface.")
	qdel(event)
