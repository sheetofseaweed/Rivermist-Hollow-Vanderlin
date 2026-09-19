/datum/unit_test/preferences_patron_recovery/Run()
	var/datum/preferences/prefs = allocate(/datum/preferences)
	var/datum/preference/patron_preference = GLOB.preference_entries[/datum/preference/choiced/patron]
	var/datum/patron/default_patron = prefs.read_default_preference(/datum/preference/choiced/patron)
	TEST_ASSERT(istype(default_patron, /datum/patron/faerun/good_gods/Selune), "The default patron must be the registered Selune.")
	TEST_ASSERT(patron_preference.is_valid(default_patron, prefs), "The default patron must pass preference validation.")
	TEST_ASSERT(!patron_preference.is_valid(null, prefs), "A null patron must not pass validation.")

	var/savefile/save = new
	var/list/invalid_values = list(null, "", "invalid patron", /datum/patron/divine/astrata, 123)
	for(var/invalid_value in invalid_values)
		WRITE_FILE(save["selected_patron"], invalid_value)
		prefs.preference_load_from_savefile(save, PREF_CHARACTER)
		TEST_ASSERT_EQUAL(prefs.read_preference(/datum/preference/choiced/patron), default_patron, "Missing and invalid saved patrons must recover to Selune.")

	var/datum/patron/tyr = GLOB.patron_list[/datum/patron/faerun/good_gods/Tyr]
	WRITE_FILE(save["selected_patron"], patron_preference.serialize(tyr))
	prefs.preference_load_from_savefile(save, PREF_CHARACTER)
	TEST_ASSERT_EQUAL(prefs.read_preference(/datum/preference/choiced/patron), tyr, "Loading must preserve a valid selected patron.")
	prefs.reset_patron(null, silent = TRUE)
	TEST_ASSERT_EQUAL(prefs.read_preference(/datum/preference/choiced/patron), default_patron, "Resetting the patron must restore Selune.")
	prefs.preference_save_to_savefile(save, PREF_CHARACTER)
	prefs.preference_load_from_savefile(save, PREF_CHARACTER)
	TEST_ASSERT_EQUAL(prefs.read_preference(/datum/preference/choiced/patron), default_patron, "The repaired patron must survive a save/load round trip.")

#ifdef FOCUS_PATRON_PREFERENCES_TEST
TEST_FOCUS(/datum/unit_test/preferences_patron_recovery)
#endif

/datum/unit_test/preferences_legacy_rendered_html_migration/Run()
	var/savefile_path = "data/unit_test_legacy_rendered_html.sav"
	fdel(savefile_path)

	var/legacy_flavortext_display = "<b>"
	legacy_flavortext_display += repeat_string(1500, "x")
	legacy_flavortext_display += "</b><BR>"
	var/legacy_ooc_notes_display = "<i>Legacy OOC notes</i><BR>"
	var/legacy_ooc_extra = "<div align='center'><img src='https://example.invalid/legacy.png'/></div>"
	var/savefile/legacy_save = new /savefile(savefile_path)
	legacy_save.cd = "/character1"
	WRITE_FILE(legacy_save["version"], 32)
	WRITE_FILE(legacy_save["species"], SPEC_ID_HUMEN)
	WRITE_FILE(legacy_save["flavortext_display"], legacy_flavortext_display)
	WRITE_FILE(legacy_save["ooc_notes_display"], legacy_ooc_notes_display)
	WRITE_FILE(legacy_save["ooc_extra"], legacy_ooc_extra)

	var/datum/preferences/prefs = allocate(/datum/preferences)
	prefs.path = savefile_path
	prefs.default_slot = 1
	TEST_ASSERT(prefs.load_character(1), "Expected the legacy character slot to load.")
	TEST_ASSERT_EQUAL(prefs.read_preference(/datum/preference/text/flavortext_display), legacy_flavortext_display, "Expected rendered flavor text HTML to survive migration.")
	TEST_ASSERT_EQUAL(prefs.read_preference(/datum/preference/text/ooc_notes_display), legacy_ooc_notes_display, "Expected rendered OOC notes HTML to survive migration.")
	TEST_ASSERT_EQUAL(prefs.read_preference(/datum/preference/text/ooc_extra), legacy_ooc_extra, "Expected embedded OOC media HTML to survive migration.")

	TEST_ASSERT(prefs.save_character(), "Expected the migrated character slot to save.")
	var/savefile/migrated_save = new /savefile(savefile_path)
	migrated_save.cd = "/character1"
	var/saved_flavortext_display
	var/saved_ooc_notes_display
	var/saved_ooc_extra
	migrated_save["flavortext_display"] >> saved_flavortext_display
	migrated_save["ooc_notes_display"] >> saved_ooc_notes_display
	migrated_save["ooc_extra"] >> saved_ooc_extra
	TEST_ASSERT_EQUAL(saved_flavortext_display, legacy_flavortext_display, "Expected rendered flavor text HTML to remain intact after saving.")
	TEST_ASSERT_EQUAL(saved_ooc_notes_display, legacy_ooc_notes_display, "Expected rendered OOC notes HTML to remain intact after saving.")
	TEST_ASSERT_EQUAL(saved_ooc_extra, legacy_ooc_extra, "Expected embedded OOC media HTML to remain intact after saving.")

	fdel(savefile_path)

/datum/unit_test/preferences_uncapped_flavor_text/Run()
	var/savefile_path = "data/unit_test_uncapped_flavor_text.sav"
	fdel(savefile_path)

	// Every string here is far past the caps upstream's preference rework put on these fields.
	var/long_flavortext = repeat_string(400, "Tall, scarred, and plainly tired. ")
	var/long_ooc_notes = repeat_string(400, "Happy to play out anything slow. ")
	var/long_nsfwflavortext = repeat_string(400, "Details best left to the panel. ")
	var/long_erpprefs_flavor = repeat_string(400, "Ask first, and mind the limits. ")
	var/long_flavortext_display = "<b>[repeat_string(600, "Tall, scarred, and plainly tired. ")]</b><BR>"

	var/savefile/legacy_save = new /savefile(savefile_path)
	legacy_save.cd = "/character1"
	WRITE_FILE(legacy_save["version"], 32)
	WRITE_FILE(legacy_save["species"], SPEC_ID_HUMEN)
	WRITE_FILE(legacy_save["flavortext"], long_flavortext)
	WRITE_FILE(legacy_save["flavortext_display"], long_flavortext_display)
	WRITE_FILE(legacy_save["ooc_notes"], long_ooc_notes)
	WRITE_FILE(legacy_save["nsfwflavortext"], long_nsfwflavortext)
	WRITE_FILE(legacy_save["erpprefs_flavor"], long_erpprefs_flavor)

	var/datum/preferences/prefs = allocate(/datum/preferences)
	prefs.path = savefile_path
	prefs.default_slot = 1
	TEST_ASSERT(prefs.load_character(1), "Expected the legacy character slot to load.")
	TEST_ASSERT_EQUAL(prefs.read_preference(/datum/preference/text/flavortext), long_flavortext, "Expected long flavor text to survive migration uncut.")
	TEST_ASSERT_EQUAL(prefs.read_preference(/datum/preference/text/flavortext_display), long_flavortext_display, "Expected long rendered flavor text to survive migration uncut.")
	TEST_ASSERT_EQUAL(prefs.read_preference(/datum/preference/text/ooc_notes), long_ooc_notes, "Expected long OOC notes to survive migration uncut.")
	TEST_ASSERT_EQUAL(prefs.read_preference(/datum/preference/text/nsfwflavortext), long_nsfwflavortext, "Expected long NSFW flavor text to survive migration uncut.")
	TEST_ASSERT_EQUAL(prefs.read_preference(/datum/preference/text/erpprefs_flavor), long_erpprefs_flavor, "Expected long ERP preferences to survive migration uncut.")

	// A fresh write has to keep them whole too, not just the migration path.
	TEST_ASSERT(prefs.write_preference(/datum/preference/text/flavortext, long_ooc_notes), "Expected a long flavor text write to be accepted.")
	TEST_ASSERT_EQUAL(prefs.read_preference(/datum/preference/text/flavortext), long_ooc_notes, "Expected a long flavor text write to be stored uncut.")

	TEST_ASSERT(prefs.save_character(), "Expected the migrated character slot to save.")
	var/savefile/migrated_save = new /savefile(savefile_path)
	migrated_save.cd = "/character1"
	var/saved_ooc_notes
	var/saved_nsfwflavortext
	migrated_save["ooc_notes"] >> saved_ooc_notes
	migrated_save["nsfwflavortext"] >> saved_nsfwflavortext
	TEST_ASSERT_EQUAL(saved_ooc_notes, long_ooc_notes, "Expected long OOC notes to remain intact after saving.")
	TEST_ASSERT_EQUAL(saved_nsfwflavortext, long_nsfwflavortext, "Expected long NSFW flavor text to remain intact after saving.")

	fdel(savefile_path)

/datum/unit_test/preferences_accent_reset_migration/Run()
	var/savefile_path = "data/unit_test_accent_reset.sav"
	fdel(savefile_path)

	var/savefile/legacy_save = new /savefile(savefile_path)
	legacy_save.cd = "/character1"
	WRITE_FILE(legacy_save["version"], 36)
	WRITE_FILE(legacy_save["species"], SPEC_ID_HUMEN)
	WRITE_FILE(legacy_save["selected_accent"], ACCENT_PIRATE)

	var/datum/preferences/prefs = allocate(/datum/preferences)
	prefs.path = savefile_path
	prefs.default_slot = 1
	TEST_ASSERT(prefs.load_character(1), "Expected the legacy character slot to load.")
	TEST_ASSERT_EQUAL(prefs.read_preference(/datum/preference/choiced/selected_accent), ACCENT_NONE, "Expected the accent reset migration to clear the stored accent.")

	TEST_ASSERT(prefs.save_character(), "Expected the migrated character slot to save.")
	var/savefile/migrated_save = new /savefile(savefile_path)
	migrated_save.cd = "/character1"
	var/saved_accent
	migrated_save["selected_accent"] >> saved_accent
	TEST_ASSERT_EQUAL(saved_accent, ACCENT_NONE, "Expected the cleared accent to persist to the savefile.")

	fdel(savefile_path)
