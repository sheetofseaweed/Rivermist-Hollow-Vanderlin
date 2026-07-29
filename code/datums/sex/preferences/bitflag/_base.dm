/datum/erp_preference/bitflag
	abstract_type = /datum/erp_preference/bitflag
	var/list/flags = list() // List of flag names and their bit values
	var/list/flag_descriptions = list() // Optional descriptions for each flag

/datum/erp_preference/bitflag/New()
	..()
	if(!length(flags))
		CRASH("Bitflag preference [type] must define flags list")


/datum/erp_preference/bitflag/New()
	..()
	if(!length(flags))
		CRASH("Bitflag preference [type] must define flags list")

/datum/erp_preference/bitflag/show_pref_ui(datum/preferences/prefs, lock_reason = null)
	var/current_value = get_value(prefs)
	var/list/output = list()

	output += "<div class='bitflag-pref'>"
	output += "<b>[html_encode(name)]:</b><br>"

	for(var/flag_name in flags)
		var/flag_bit = flags[flag_name]
		var/is_enabled = (current_value & flag_bit)
		var/status_text = is_enabled ? "On" : "Off"
		var/link_class = is_enabled ? "linkOn" : "linkOff"
		var/description = flag_descriptions[flag_name] || ""
		var/title_attr = description ? " title='[escape_html_attribute(description)]'" : ""
		var/toggle_html = "<a href='?_src_=prefs;task=erp_pref;pref_type=[type];action=toggle_flag;flag=[flag_bit]' class='[link_class]'>[status_text]</a>"
		if(lock_reason)
			toggle_html = wrap_with_tooltip("<a class='linkOff'>[status_text]</a>", lock_reason)

		output += "<div class='bitflag-option'>"
		output += "<span[title_attr]>[html_encode(flag_name)]</span>: "
		output += toggle_html
		output += "</div>"

	output += "</div>"
	return jointext(output, "")

/datum/erp_preference/bitflag/handle_topic(mob/user, list/href_list, datum/preferences/prefs)
	if(href_list["action"] == "toggle_flag")
		if(!ensure_editable(user, prefs))
			return TRUE
		var/flag_bit = text2num(href_list["flag"])
		if(!flag_bit)
			return FALSE

		var/current_value = get_value(prefs)
		current_value ^= flag_bit // XOR to toggle the specific bit
		set_value(prefs, current_value)
		return TRUE
	return FALSE

// Helper procs for checking flags
/datum/erp_preference/bitflag/proc/has_flag(datum/preferences/prefs, flag_bit)
	var/current_value = get_value(prefs)
	return (current_value & flag_bit)

/datum/erp_preference/bitflag/proc/has_any_flags(datum/preferences/prefs, list/check_flags)
	var/current_value = get_value(prefs)
	for(var/flag in check_flags)
		if(current_value & flag)
			return TRUE
	return FALSE

/datum/erp_preference/bitflag/proc/has_all_flags(datum/preferences/prefs, list/check_flags)
	var/current_value = get_value(prefs)
	for(var/flag in check_flags)
		if(!(current_value & flag))
			return FALSE
	return TRUE
