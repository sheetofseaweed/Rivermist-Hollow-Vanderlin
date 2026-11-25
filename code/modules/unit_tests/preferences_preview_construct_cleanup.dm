/datum/unit_test/preferences_preview_construct_cleanup/Run()
	var/dummy_key = "unit_test_preview_construct_cleanup"
	var/datum/preferences/prefs = allocate(/datum/preferences)

	prefs.write_preference(/datum/preference/choiced/gender, FEMALE)
	prefs.write_preference(/datum/preference/choiced/age, AGE_ADULT)
	prefs.write_preference(/datum/preference/choiced/patron, /datum/patron/faerun/good_gods/Lathander)

	prefs.set_species_preference(/datum/species/automaton/construct)
	prefs.features = prefs.pref_species.get_random_features()
	prefs.body_markings = prefs.pref_species.get_random_body_markings(prefs.features)
	prefs.write_preference(/datum/preference/text/real_name, prefs.pref_species.random_name(prefs.read_preference(/datum/preference/choiced/gender), TRUE))

	get_flat_human_icon(null, null, prefs, dummy_key, list(SOUTH))

	var/mob/living/carbon/human/dummy/body = GLOB.human_dummy_list[dummy_key]
	TEST_ASSERT_NOTNULL(body, "Expected the preview helper to reuse a pooled human dummy.")

	var/has_robotic_bodypart = FALSE
	for(var/obj/item/bodypart/bodypart as anything in body.bodyparts)
		if(bodypart.status == BODYPART_ROBOTIC)
			has_robotic_bodypart = TRUE
			break
	TEST_ASSERT(has_robotic_bodypart, "Expected construct previews to roboticize the pooled dummy's bodyparts.")

	prefs.set_species_preference(/datum/species/human/northern)
	prefs.features = prefs.pref_species.get_random_features()
	prefs.body_markings = prefs.pref_species.get_random_body_markings(prefs.features)
	prefs.write_preference(/datum/preference/text/real_name, prefs.pref_species.random_name(prefs.read_preference(/datum/preference/choiced/gender), TRUE))

	get_flat_human_icon(null, null, prefs, dummy_key, list(SOUTH))

	has_robotic_bodypart = FALSE
	for(var/obj/item/bodypart/bodypart as anything in body.bodyparts)
		if(bodypart.status == BODYPART_ROBOTIC)
			has_robotic_bodypart = TRUE
			break
	TEST_ASSERT(!has_robotic_bodypart, "Expected non-construct previews to clear any robotic bodypart state left on the pooled dummy.")

	delete_human_dummy(dummy_key)
