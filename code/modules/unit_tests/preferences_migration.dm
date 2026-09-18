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
