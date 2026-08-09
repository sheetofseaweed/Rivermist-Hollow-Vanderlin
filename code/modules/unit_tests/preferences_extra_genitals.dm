/// The Extra Genitals quirk lets a character keep masculine and feminine genital entries
/// enabled at the same time. Loading a character has to read the quirk list before the genital
/// set rules are enforced, or the mixed selection is stripped back to the gendered default.
/datum/unit_test/preferences_extra_genitals_savefile/Run()
	var/savefile_path = "data/unit_test_extra_genitals.sav"
	fdel(savefile_path)

	var/datum/preferences/prefs = allocate(/datum/preferences)
	prefs.gender = FEMALE
	prefs.age = AGE_ADULT
	prefs.pref_species = new /datum/species/human/northern
	prefs.quirks = list(/datum/quirk/peculiarity/extra_genitals)
	prefs.validate_customizer_entries()

	prefs.set_customizer_entry_type_enabled(/datum/customizer_entry/organ/genitals/vagina, TRUE)
	prefs.set_customizer_entry_type_enabled(/datum/customizer_entry/organ/genitals/breasts, TRUE)
	prefs.set_customizer_entry_type_enabled(/datum/customizer_entry/organ/genitals/penis, TRUE)
	prefs.set_customizer_entry_type_enabled(/datum/customizer_entry/organ/genitals/testicles, TRUE)

	TEST_ASSERT(prefs.has_masculine_genital_set(), "Expected the masculine set to stay enabled while the quirk is selected.")
	TEST_ASSERT(prefs.has_feminine_genital_set(), "Expected the feminine set to stay enabled while the quirk is selected.")

	var/savefile/S = new /savefile(savefile_path)
	S.cd = "/character1"
	WRITE_FILE(S["customizer_entries"], prefs.customizer_entries)
	prefs.save_quirks(S)

	// Loading starts from a blank slate, which is what lets a stale quirk list clobber the entries.
	prefs.customizer_entries = list()
	prefs.quirks = list()

	prefs.load_customizer_and_quirk_data(S)

	TEST_ASSERT(prefs.has_selected_quirk(/datum/quirk/peculiarity/extra_genitals), "Expected the Extra Genitals quirk to survive loading.")
	TEST_ASSERT(prefs.has_feminine_genital_set(), "Expected the loaded character to keep its feminine genital set.")
	TEST_ASSERT(prefs.has_masculine_genital_set(), "Expected the loaded character to keep its masculine genital set instead of losing it to the gendered default.")

	fdel(savefile_path)

/// Without the quirk the mixed selection is not legal, so loading has to collapse it back to one set.
/datum/unit_test/preferences_extra_genitals_savefile_without_quirk/Run()
	var/savefile_path = "data/unit_test_extra_genitals_no_quirk.sav"
	fdel(savefile_path)

	var/datum/preferences/prefs = allocate(/datum/preferences)
	prefs.gender = FEMALE
	prefs.age = AGE_ADULT
	prefs.pref_species = new /datum/species/human/northern
	prefs.quirks = list(/datum/quirk/peculiarity/extra_genitals)
	prefs.validate_customizer_entries()

	prefs.set_customizer_entry_type_enabled(/datum/customizer_entry/organ/genitals/vagina, TRUE)
	prefs.set_customizer_entry_type_enabled(/datum/customizer_entry/organ/genitals/breasts, TRUE)
	prefs.set_customizer_entry_type_enabled(/datum/customizer_entry/organ/genitals/penis, TRUE)
	prefs.set_customizer_entry_type_enabled(/datum/customizer_entry/organ/genitals/testicles, TRUE)

	var/savefile/S = new /savefile(savefile_path)
	S.cd = "/character1"
	WRITE_FILE(S["customizer_entries"], prefs.customizer_entries)
	prefs.quirks = list()
	prefs.save_quirks(S)

	prefs.customizer_entries = list()

	prefs.load_customizer_and_quirk_data(S)

	TEST_ASSERT(prefs.has_feminine_genital_set(), "Expected a female character without the quirk to keep the feminine set.")
	TEST_ASSERT(!prefs.has_masculine_genital_set(), "Expected the masculine set to be stripped without the Extra Genitals quirk.")

	fdel(savefile_path)

/// The full save_character() / load_character() round trip, which is what a player actually does
/// when they save a mixed set and then switch slots and come back.
/datum/unit_test/preferences_extra_genitals_character_round_trip/Run()
	var/savefile_path = "data/unit_test_extra_genitals_round_trip.sav"
	fdel(savefile_path)

	var/datum/preferences/prefs = allocate(/datum/preferences)
	prefs.path = savefile_path
	prefs.default_slot = 1
	prefs.gender = FEMALE
	prefs.real_name = "Round Trip"
	prefs.age = AGE_ADULT
	prefs.pref_species = new /datum/species/human/northern
	prefs.validate_customizer_entries()

	prefs.quirks = list(/datum/quirk/peculiarity/extra_genitals)
	prefs.set_genital_set("feminine")
	prefs.set_customizer_entry_type_enabled(/datum/customizer_entry/organ/genitals/penis, TRUE)
	prefs.set_customizer_entry_type_enabled(/datum/customizer_entry/organ/genitals/testicles, TRUE)

	TEST_ASSERT(prefs.has_masculine_genital_set(), "Expected the masculine set to be enabled before saving.")
	TEST_ASSERT(prefs.has_feminine_genital_set(), "Expected the feminine set to be enabled before saving.")

	TEST_ASSERT(prefs.save_character(), "Expected save_character() to write the savefile.")
	TEST_ASSERT(prefs.load_character(1), "Expected load_character() to read the savefile back.")

	TEST_ASSERT(prefs.has_selected_quirk(/datum/quirk/peculiarity/extra_genitals), "Expected the Extra Genitals quirk to survive a save/load round trip.")
	TEST_ASSERT(prefs.has_feminine_genital_set(), "Expected the feminine set to survive a save/load round trip.")
	TEST_ASSERT(prefs.has_masculine_genital_set(), "Expected the masculine set to survive a save/load round trip.")

	fdel(savefile_path)

/// The Toggle Genitals button sits above the genital cards and is always clickable. Without the
/// quirk it swaps between the two complete sets; with the quirk it has to cycle through the mixed
/// state rather than throwing away half of a selection the player deliberately built.
/datum/unit_test/preferences_extra_genitals_toggle_cycle/Run()
	var/datum/preferences/prefs = allocate(/datum/preferences)
	prefs.gender = FEMALE
	prefs.age = AGE_ADULT
	prefs.pref_species = new /datum/species/human/northern
	prefs.quirks = list(/datum/quirk/peculiarity/extra_genitals)
	prefs.validate_customizer_entries()
	prefs.set_mixed_genital_set()

	TEST_ASSERT(prefs.has_masculine_genital_set() && prefs.has_feminine_genital_set(), "Expected a mixed set to start from.")

	prefs.toggle_genital_set()
	TEST_ASSERT(prefs.has_masculine_genital_set(), "Expected mixed to cycle to masculine.")
	TEST_ASSERT(!prefs.has_feminine_genital_set(), "Expected mixed to cycle to masculine only.")

	prefs.toggle_genital_set()
	TEST_ASSERT(prefs.has_feminine_genital_set(), "Expected masculine to cycle to feminine.")
	TEST_ASSERT(!prefs.has_masculine_genital_set(), "Expected masculine to cycle to feminine only.")

	prefs.toggle_genital_set()
	TEST_ASSERT(prefs.has_masculine_genital_set() && prefs.has_feminine_genital_set(), "Expected feminine to cycle back to mixed instead of stranding the player outside their quirk's state.")

/// Without the quirk the toggle keeps its plain two-state behaviour.
/datum/unit_test/preferences_extra_genitals_toggle_without_quirk/Run()
	var/datum/preferences/prefs = allocate(/datum/preferences)
	prefs.gender = FEMALE
	prefs.age = AGE_ADULT
	prefs.pref_species = new /datum/species/human/northern
	prefs.quirks = list()
	prefs.validate_customizer_entries()
	prefs.set_genital_set("feminine")

	prefs.toggle_genital_set()
	TEST_ASSERT(prefs.has_masculine_genital_set(), "Expected feminine to toggle to masculine.")
	TEST_ASSERT(!prefs.has_feminine_genital_set(), "Expected feminine to toggle to masculine only.")

	prefs.toggle_genital_set()
	TEST_ASSERT(prefs.has_feminine_genital_set(), "Expected masculine to toggle back to feminine.")
	TEST_ASSERT(!prefs.has_masculine_genital_set(), "Expected masculine to toggle back to feminine only.")

/// The same round trip driven through the menu procs a player actually hits: the quirk menu's
/// add_quirk() and the customizer tab's toggle_missing topic.
/datum/unit_test/preferences_extra_genitals_menu_flow/Run()
	var/savefile_path = "data/unit_test_extra_genitals_menu_flow.sav"
	fdel(savefile_path)

	var/datum/preferences/prefs = allocate(/datum/preferences)
	prefs.path = savefile_path
	prefs.default_slot = 1
	prefs.gender = FEMALE
	prefs.real_name = "Menu Flow"
	prefs.age = AGE_ADULT
	prefs.pref_species = new /datum/species/human/northern
	prefs.quirks = list()
	prefs.validate_customizer_entries()
	prefs.set_genital_set("feminine")

	TEST_ASSERT(prefs.add_quirk(/datum/quirk/peculiarity/extra_genitals), "Expected the Extra Genitals quirk to be addable to a female character.")

	var/datum/customizer_entry/penis_entry = prefs.get_customizer_entry_for_entry_type(/datum/customizer_entry/organ/genitals/penis)
	var/datum/customizer_entry/testicles_entry = prefs.get_customizer_entry_for_entry_type(/datum/customizer_entry/organ/genitals/testicles)
	TEST_ASSERT(penis_entry && testicles_entry, "Expected the species to provide penis and testicles customizer entries.")

	prefs.handle_customizer_topic(null, list("customizer" = "[penis_entry.customizer_type]", "customizer_task" = "toggle_missing"))
	prefs.handle_customizer_topic(null, list("customizer" = "[testicles_entry.customizer_type]", "customizer_task" = "toggle_missing"))

	TEST_ASSERT(prefs.has_feminine_genital_set(), "Expected the feminine set to stay enabled after the masculine toggles.")
	TEST_ASSERT(prefs.has_masculine_genital_set(), "Expected the customizer toggles to enable the masculine set.")

	TEST_ASSERT(prefs.save_character(), "Expected save_character() to write the savefile.")

	// Switching to another character and back is what the player actually does.
	prefs.load_character(2)
	TEST_ASSERT(prefs.load_character(1), "Expected load_character() to read the savefile back.")

	TEST_ASSERT(prefs.has_selected_quirk(/datum/quirk/peculiarity/extra_genitals), "Expected the Extra Genitals quirk to survive the menu round trip.")
	TEST_ASSERT(prefs.has_feminine_genital_set(), "Expected the feminine set to survive the menu round trip.")
	TEST_ASSERT(prefs.has_masculine_genital_set(), "Expected the masculine set to survive the menu round trip.")

	fdel(savefile_path)
