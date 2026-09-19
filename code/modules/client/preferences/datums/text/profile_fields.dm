/datum/preference/text/nsfw_headshot_link
	savefile_key = "nsfw_headshot_link"
	savefile_identifier = PREF_CHARACTER
	category = "character_ooc"
	maximum_value_length = 0
	can_randomize = FALSE
	should_update_preview = FALSE

/datum/preference/text/nsfw_headshot_link/is_valid(value, datum/preferences/prefs)
	if(!length(value))
		return TRUE
	return ..() && prefs.is_valid_nsfw_headshot_link(null, value, TRUE)

/datum/preference/text/nsfw_headshot_link/apply_to_human(mob/living/carbon/human/human, value, datum/preferences/prefs)
	human.nsfw_headshot_link = value

/datum/preference/text/nsfwflavortext
	savefile_key = "nsfwflavortext"
	savefile_identifier = PREF_CHARACTER
	category = "character_ooc"
	maximum_value_length = 0
	can_randomize = FALSE
	should_update_preview = FALSE

/datum/preference/text/nsfwflavortext/apply_to_human(mob/living/carbon/human/human, value, datum/preferences/prefs)
	human.nsfwflavortext = value

/datum/preference/text/erpprefs_flavor
	savefile_key = "erpprefs_flavor"
	savefile_identifier = PREF_CHARACTER
	category = "character_ooc"
	maximum_value_length = 0
	can_randomize = FALSE
	should_update_preview = FALSE

/datum/preference/text/erpprefs_flavor/apply_to_human(mob/living/carbon/human/human, value, datum/preferences/prefs)
	human.erpprefs_flavor = value

/datum/preference/text/song_link
	savefile_key = "song_link"
	savefile_identifier = PREF_CHARACTER
	category = "character_ooc"
	maximum_value_length = 0
	can_randomize = FALSE
	should_update_preview = FALSE

/datum/preference/text/song_link/apply_to_human(mob/living/carbon/human/human, value, datum/preferences/prefs)
	human.song_link = value

/datum/preference/text/song_artist
	savefile_key = "song_artist"
	savefile_identifier = PREF_CHARACTER
	category = "character_ooc"
	maximum_value_length = 0
	can_randomize = FALSE
	should_update_preview = FALSE

/datum/preference/text/song_artist/apply_to_human(mob/living/carbon/human/human, value, datum/preferences/prefs)
	human.song_artist = value

/datum/preference/text/song_title
	savefile_key = "song_title"
	savefile_identifier = PREF_CHARACTER
	category = "character_ooc"
	maximum_value_length = 0
	can_randomize = FALSE
	should_update_preview = FALSE

/datum/preference/text/song_title/apply_to_human(mob/living/carbon/human/human, value, datum/preferences/prefs)
	human.song_title = value
