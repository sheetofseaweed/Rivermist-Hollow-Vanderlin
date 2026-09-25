/datum/preference/text/flavortext
	savefile_key = "flavortext"
	savefile_identifier = PREF_CHARACTER
	category = "character_ooc"
	can_randomize = FALSE
	maximum_value_length = 0
	should_update_preview = FALSE

/datum/preference/text/flavortext/deserialize(input, datum/preferences/prefs)
	return STRIP_HTML_SIMPLE(html_decode(input), maximum_value_length)

/datum/preference/text/flavortext/apply_to_human(mob/living/carbon/human/H, value, datum/preferences/prefs)
	H.flavortext = value

/datum/preference/text/flavortext/handle_link(datum/preferences/prefs, mob/user)
	to_chat(user, span_notice("["<span class='bold'>Flavortext should not include nonphysical nonsensory attributes such as backstory or the character's internal thoughts. NSFW descriptions are prohibited.</span>"]"))
	// Keep this raw while editing; we encode it later for the rendered preview.
	var/new_flavortext = tgui_input_text(user, "Input your character description", "DESCRIBE YOURSELF", prefs.read_preference(/datum/preference/text/flavortext), max_length = MAX_FLAVOR_TEXT_LENGTH, multiline = TRUE, encode = FALSE)
	if(new_flavortext == null)
		return
	if(new_flavortext == "")
		prefs.write_preference(/datum/preference/text/flavortext, null)
		prefs.write_preference(/datum/preference/text/flavortext_display, null)
		prefs.update_menu_data(user)
		return
	prefs.write_preference(/datum/preference/text/flavortext, new_flavortext)
	var/ft = prefs.read_preference(/datum/preference/text/flavortext)
	ft = html_encode(ft)
	ft = replacetext(parsemarkdown_basic(ft), "\n", "<BR>")
	prefs.write_preference(/datum/preference/text/flavortext_display, ft)
	to_chat(user, span_notice("Successfully updated flavortext"))
	log_game("[user] has set their flavortext'.")
