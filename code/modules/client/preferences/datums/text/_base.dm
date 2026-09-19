/datum/preference/text
	/// Cap on the stored value's length. Zero means no cap.
	var/maximum_value_length = 256
	var/should_strip_html = TRUE
	abstract_type = /datum/preference/text

/datum/preference/text/deserialize(input, datum/preferences/prefs)
	return should_strip_html ? STRIP_HTML_SIMPLE(input, maximum_value_length) : copytext(input, 1, maximum_value_length)

/datum/preference/text/create_default_value(datum/preferences/prefs)
	return ""

/datum/preference/text/is_valid(value, datum/preferences/prefs)
	if(!istext(value))
		return FALSE
	return !maximum_value_length || length(value) < maximum_value_length

/datum/preference/text/compile_constant_data()
	return list("maximum_length" = maximum_value_length)
