/datum/preference/choiced/selected_accent
	savefile_key = "selected_accent"
	savefile_identifier = PREF_CHARACTER
	category = "character"
	should_apply = FALSE

/datum/preference/choiced/selected_accent/init_possible_values(datum/preferences/prefs)
	return GLOB.accent_list

/datum/preference/choiced/selected_accent/create_default_value(datum/preferences/prefs)
	return ACCENT_NONE

/datum/preference/choiced/selected_accent/apply_to_human(mob/living/carbon/human/H, value, datum/preferences/prefs)
	H.accent = value

/datum/preference/choiced/selected_accent/handle_link(datum/preferences/prefs, mob/user)
	var/list/available = list(ACCENT_NONE)

	// Accent selection is free for everyone on RMH. Keep culture support generic so
	// cultures can opt into it without importing upstream's English accent content.
	for(var/accent_name in GLOB.accent_list)
		available |= accent_name

	var/culture_type = prefs.read_preference(/datum/preference/choiced/culture)
	var/datum/culture/culture_datum = GLOB.culture_singletons[culture_type]
	if(culture_datum?.accent)
		available |= culture_datum.accent

	prefs.change_accent = length(available) > 1
	var/accent = browser_input_list(user, "CHOOSE YOUR HERO'S ACCENT", "VOICE OF THE WORLD", available, prefs.read_preference(/datum/preference/choiced/selected_accent))
	if(accent)
		prefs.write_preference(/datum/preference/choiced/selected_accent, accent)
