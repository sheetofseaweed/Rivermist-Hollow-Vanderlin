/datum/preference/text/selected_title
	savefile_key = "selected_title"
	savefile_identifier = PREF_CHARACTER
	category = "character"
	maximum_value_length = 0
	can_randomize = FALSE
	should_apply = FALSE

/datum/preference/text/selected_title/create_default_value(datum/preferences/prefs)
	return "None"
