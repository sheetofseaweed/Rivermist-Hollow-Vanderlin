/// Settings rows save at once, so a reconnect keeps them without pressing Save.
/datum/unit_test/preferences_settings_autosave
	var/save_path

/datum/unit_test/preferences_settings_autosave/Destroy()
	if(save_path)
		fdel(save_path)
	return ..()

/datum/unit_test/preferences_settings_autosave/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/datum/preferences/prefs = allocate(/datum/preferences)
	save_path = "[GLOB.log_directory]/settings_autosave_test.sav"
	fdel(save_path)
	prefs.path = save_path

	var/occlusion_before = prefs.read_preference(/datum/preference/toggle/ambientocclusion)
	var/runechat_off_before = prefs.preference_has_flag(/datum/preference/bitwise/toggles_maptext, DISABLE_RUNECHAT)
	var/ambience_before = prefs.preference_has_flag(/datum/preference/bitwise/toggles, SOUND_AMBIENCE)
	TEST_ASSERT(prefs.process_native_preference_link(user, list("preference" = "ambientocclusion")), "The ambient occlusion row should be handled.")
	TEST_ASSERT(prefs.process_native_preference_link(user, list("preference" = "runechat")), "The runechat row should be handled.")
	TEST_ASSERT(prefs.process_native_preference_link(user, list("preference" = "ambience")), "The ambience row should be handled.")

	var/datum/preferences/reloaded = allocate(/datum/preferences)
	reloaded.path = save_path
	TEST_ASSERT(reloaded.load_preferences(), "The account savefile should exist without pressing Save.")
	TEST_ASSERT_EQUAL(reloaded.read_preference(/datum/preference/toggle/ambientocclusion), !occlusion_before, "Ambient occlusion should survive a reconnect.")
	TEST_ASSERT_EQUAL(reloaded.preference_has_flag(/datum/preference/bitwise/toggles_maptext, DISABLE_RUNECHAT), !runechat_off_before, "Runechat should survive a reconnect.")
	TEST_ASSERT_EQUAL(reloaded.preference_has_flag(/datum/preference/bitwise/toggles, SOUND_AMBIENCE), !ambience_before, "Ambience should survive a reconnect.")

/// Each plain toggle row must flip its preference both ways.
/datum/unit_test/preferences_settings_toggles_flip/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/datum/preferences/prefs = allocate(/datum/preferences)
	var/list/rows = list(
		"see_chat_non_mob" = /datum/preference/toggle/see_chat_non_mob,
		"action_buttons" = /datum/preference/toggle/buttons_locked,
		"tgui_fancy" = /datum/preference/toggle/tgui_fancy,
		"tgui_lock" = /datum/preference/toggle/tgui_lock,
		"winflash" = /datum/preference/toggle/windowflashing,
		"ambientocclusion" = /datum/preference/toggle/ambientocclusion,
		"auto_fit_viewport" = /datum/preference/toggle/auto_fit_viewport,
	)
	for(var/row in rows)
		var/before = prefs.read_preference(rows[row])
		prefs.process_native_preference_link(user, list("preference" = row))
		TEST_ASSERT_EQUAL(prefs.read_preference(rows[row]), !before, "The [row] row should flip its preference.")
		prefs.process_native_preference_link(user, list("preference" = row))
		TEST_ASSERT_EQUAL(prefs.read_preference(rows[row]), before, "The [row] row should flip back.")

/// Every value the Scaling Method and Pixel Size rows cycle through must be storable.
/datum/unit_test/preferences_display_cycle_values/Run()
	var/datum/preferences/prefs = allocate(/datum/preferences)
	for(var/method in list(SCALING_METHOD_NORMAL, SCALING_METHOD_DISTORT, SCALING_METHOD_BLUR))
		TEST_ASSERT(prefs.write_preference(/datum/preference/choiced/scaling_method, method), "Scaling method [method] should be accepted.")
		TEST_ASSERT_EQUAL(prefs.read_preference(/datum/preference/choiced/scaling_method), method, "Scaling method [method] should be stored as given.")
	for(var/pixel_size in list(PIXEL_SCALING_AUTO, PIXEL_SCALING_1X, PIXEL_SCALING_1_2X, PIXEL_SCALING_2X, PIXEL_SCALING_3X))
		TEST_ASSERT(prefs.write_preference(/datum/preference/numeric/pixel_size, pixel_size), "Pixel size [pixel_size] should be accepted.")
		TEST_ASSERT_EQUAL(prefs.read_preference(/datum/preference/numeric/pixel_size), pixel_size, "Pixel size [pixel_size] should be stored as given.")
