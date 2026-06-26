/proc/sanitize_defeat_mode(defeat_mode)
	switch(defeat_mode)
		if(DEFEAT_MODE_KO_RUNE, DEFEAT_MODE_KO_ONLY, DEFEAT_MODE_NO_RETURN)
			return defeat_mode
	return DEFEAT_MODE_DEFAULT

/proc/sanitize_defeat_damage_threshold(threshold)
	threshold = text2num("[threshold]")
	switch(threshold)
		if(100, 150, 200, 250, 300)
			return threshold
	return DEFEAT_DAMAGE_THRESHOLD_DEFAULT

/// Labelled threshold choices so the numbers mean something to the player in the pref menu.
/// The number is total wound damage (brute+burn+tox+oxy) endured before you tap out into defeat.
/// Lower = fall sooner (safer); higher = soak more punishment first.
/proc/defeat_threshold_choice_map()
	return list(
		"Fragile (100 - fall early)" = 100,
		"Frail (150)" = 150,
		"Standard (200)" = 200,
		"Hardy (250)" = 250,
		"Unyielding (300 - endure the most)" = 300,
	)

/proc/defeat_threshold_display_label(threshold)
	threshold = sanitize_defeat_damage_threshold(threshold)
	var/list/choices = defeat_threshold_choice_map()
	for(var/label in choices)
		if(choices[label] == threshold)
			return label
	return "Standard (200)"

/proc/defeat_mode_display_name(defeat_mode)
	switch(sanitize_defeat_mode(defeat_mode))
		if(DEFEAT_MODE_KO_RUNE)
			return "Knockout + Rune"
		if(DEFEAT_MODE_KO_ONLY)
			return "Knockout Only"
		if(DEFEAT_MODE_NO_RETURN)
			return "No Return"
	return "Knockout + Rune"

/proc/defeat_mode_choice_map()
	return list(
		"Knockout + Rune" = DEFEAT_MODE_KO_RUNE,
		"Knockout Only" = DEFEAT_MODE_KO_ONLY,
		"No Return" = DEFEAT_MODE_NO_RETURN,
	)

/datum/preferences/proc/get_defeat_mode()
	defeat_mode = sanitize_defeat_mode(defeat_mode)
	return defeat_mode

/datum/preferences/proc/set_defeat_mode(new_defeat_mode)
	defeat_mode = sanitize_defeat_mode(new_defeat_mode)

/datum/preferences/proc/get_defeat_damage_threshold()
	defeat_damage_threshold = sanitize_defeat_damage_threshold(defeat_damage_threshold)
	return defeat_damage_threshold

/datum/preferences/proc/set_defeat_damage_threshold(new_threshold)
	defeat_damage_threshold = sanitize_defeat_damage_threshold(new_threshold)
