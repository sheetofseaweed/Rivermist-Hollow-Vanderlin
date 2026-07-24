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
/// The number is pooled brute, burn, toxin, and clone damage endured before you tap out into defeat.
/// Oxygen, blood loss, brain danger, shock, and immediate rune hazards use their own safety checks.
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

/proc/defeat_mode_help_text()
	return "Defeat stabilizes lethal bleeding and brain danger without erasing ordinary injuries. Allies can wake you manually, with prepared care, or at a player-built campfire; waking leaves configured aftermath trauma. Knockout + Rune also offers the rune route during captivity, Knockout Only relies on in-world recovery, and No Return keeps ordinary death final."

/proc/defeat_threshold_help_text()
	return "This is the pooled total of brute, burn, toxin, and clone damage needed to trigger Defeat. Lower values make you fall sooner. Stabilization makes you safe from an immediate bleed/brain death loop, but it does not wake you or fully heal you. Horny Defeat uses a separate deterministic stat-based resistance; your exact progress and remaining climaxes are shown only to you during an active encounter."

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
