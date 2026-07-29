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
