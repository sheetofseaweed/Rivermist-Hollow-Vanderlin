/datum/unit_test/preferences_body_sizes
	abstract_type = /datum/unit_test/preferences_body_sizes

/// Saves a northern human with every body size at its maximum, under the given quirk list.
/datum/unit_test/preferences_body_sizes/proc/save_max_body_sizes(savefile_path, list/saved_quirks)
	var/datum/preferences/prefs = allocate(/datum/preferences)
	prefs.write_preference(/datum/preference/choiced/gender, FEMALE)
	prefs.write_preference(/datum/preference/choiced/age, AGE_ADULT)
	prefs.set_species_preference(/datum/species/human/northern)
	prefs.quirks = list(/datum/quirk/peculiarity/generous_figure)
	prefs.validate_customizer_entries()

	var/datum/customizer_entry/organ/genitals/breasts/breasts_entry = prefs.get_customizer_entry_for_entry_type(/datum/customizer_entry/organ/genitals/breasts)
	var/datum/customizer_entry/organ/genitals/butt/butt_entry = prefs.get_customizer_entry_for_entry_type(/datum/customizer_entry/organ/genitals/butt)
	var/datum/customizer_entry/organ/genitals/belly/belly_entry = prefs.get_customizer_entry_for_entry_type(/datum/customizer_entry/organ/genitals/belly)
	breasts_entry.breast_size = MAX_BREASTS_SIZE
	butt_entry.butt_size = MAX_BUTT_SIZE
	belly_entry.belly_size = MAX_BELLY_SIZE

	var/savefile/S = new /savefile(savefile_path)
	S.cd = "/character1"
	WRITE_FILE(S["customizer_entries"], prefs.customizer_entries)
	prefs.quirks = saved_quirks
	prefs.save_quirks(S)
	return S

/// Loads the slot with an empty quirk list, like the first load of a session.
/datum/unit_test/preferences_body_sizes/proc/load_body_sizes(savefile/S)
	var/datum/preferences/prefs = allocate(/datum/preferences)
	prefs.write_preference(/datum/preference/choiced/gender, FEMALE)
	prefs.set_species_preference(/datum/species/human/northern)
	prefs.customizer_entries = list()
	prefs.quirks = list()
	prefs.load_customizer_and_quirk_data(S)
	return prefs

/// Generous Figure sizes must survive a load; the size caps read the quirk list.
/datum/unit_test/preferences_body_sizes/survive_load_with_quirk/Run()
	var/savefile_path = "data/unit_test_generous_figure_sizes.sav"
	fdel(savefile_path)
	var/datum/preferences/prefs = load_body_sizes(save_max_body_sizes(savefile_path, list(/datum/quirk/peculiarity/generous_figure)))

	var/datum/customizer_entry/organ/genitals/breasts/breasts_entry = prefs.get_customizer_entry_for_entry_type(/datum/customizer_entry/organ/genitals/breasts)
	var/datum/customizer_entry/organ/genitals/butt/butt_entry = prefs.get_customizer_entry_for_entry_type(/datum/customizer_entry/organ/genitals/butt)
	var/datum/customizer_entry/organ/genitals/belly/belly_entry = prefs.get_customizer_entry_for_entry_type(/datum/customizer_entry/organ/genitals/belly)
	TEST_ASSERT(prefs.has_selected_quirk(/datum/quirk/peculiarity/generous_figure), "Generous Figure should survive loading.")
	TEST_ASSERT_EQUAL(breasts_entry.breast_size, MAX_BREASTS_SIZE, "Enormous breasts should survive loading with Generous Figure.")
	TEST_ASSERT_EQUAL(butt_entry.butt_size, MAX_BUTT_SIZE, "The largest butt size should survive loading with Generous Figure.")
	TEST_ASSERT_EQUAL(belly_entry.belly_size, MAX_BELLY_SIZE, "The largest belly size should survive loading with Generous Figure.")

	fdel(savefile_path)

/// Without Generous Figure the loaded sizes must still drop to the normal caps.
/datum/unit_test/preferences_body_sizes/capped_without_quirk/Run()
	var/savefile_path = "data/unit_test_body_sizes_no_quirk.sav"
	fdel(savefile_path)
	var/datum/preferences/prefs = load_body_sizes(save_max_body_sizes(savefile_path, list()))

	var/datum/customizer_entry/organ/genitals/breasts/breasts_entry = prefs.get_customizer_entry_for_entry_type(/datum/customizer_entry/organ/genitals/breasts)
	var/datum/customizer_entry/organ/genitals/butt/butt_entry = prefs.get_customizer_entry_for_entry_type(/datum/customizer_entry/organ/genitals/butt)
	var/datum/customizer_entry/organ/genitals/belly/belly_entry = prefs.get_customizer_entry_for_entry_type(/datum/customizer_entry/organ/genitals/belly)
	TEST_ASSERT_EQUAL(breasts_entry.breast_size, BREAST_SIZE_LARGE, "Breasts should drop to Large without Generous Figure.")
	TEST_ASSERT_EQUAL(butt_entry.butt_size, BUTT_SIZE_MEDIUM, "Butt size should drop to Medium without Generous Figure.")
	TEST_ASSERT_EQUAL(belly_entry.belly_size, BELLY_SIZE_MEDIUM, "Belly size should drop to Medium without Generous Figure.")

	fdel(savefile_path)
