/proc/sanitize_defeat_mode(defeat_mode)
	switch(defeat_mode)
		if(DEFEAT_MODE_KO_RUNE, DEFEAT_MODE_KO_ONLY, DEFEAT_MODE_NO_RETURN)
			return defeat_mode
	return DEFEAT_MODE_DEFAULT

/proc/sanitize_defeat_damage_threshold(threshold)
	threshold = text2num("[threshold]")
	switch(threshold)
		if(150, 200, 250, 300)
			return threshold
	return DEFEAT_DAMAGE_THRESHOLD_DEFAULT

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
