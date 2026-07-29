/datum/erp_preference/numeric
	abstract_type = /datum/erp_preference/numeric
	/// Minimum allowed value
	var/min_value = 0
	/// Maximum allowed value
	var/max_value = 100
	/// Default numeric value
	var/default_numeric = 0
	/// Step size for increment/decrement
	var/step_size = 1

/datum/erp_preference/numeric/New()
	. = ..()
	if(default_numeric < min_value || default_numeric > max_value)
		CRASH("ERP preference [type] has a default value outside its allowed range.")

/datum/erp_preference/numeric/get_value(datum/preferences/prefs)
	return get_value_from_list(prefs?.erp_preferences)

/datum/erp_preference/numeric/get_value_from_list(list/stored_preferences)
	var/stored_value = stored_preferences?[type]
	if(!isnum(stored_value))
		return get_default_value()
	return clamp(stored_value, min_value, max_value)

/datum/erp_preference/numeric/get_default_value()
	return default_numeric

/datum/erp_preference/numeric/show_pref_ui(datum/preferences/prefs, lock_reason = null)
	var/current_value = get_value(prefs)
	if(lock_reason)
		var/dec_link = wrap_with_tooltip("<a class='linkOff'>&lt;</a>", lock_reason)
		var/inc_link = wrap_with_tooltip("<a class='linkOff'>&gt;</a>", lock_reason)
		var/value_link = wrap_with_tooltip("<a class='linkOff'>[html_encode("[current_value]")]</a>", lock_reason)
		return "[dec_link][value_link][inc_link]"

	var/dec_link = "<a href='?_src_=prefs;task=erp_pref;pref_type=[type];action=decrease'>&lt;</a>"
	var/inc_link = "<a href='?_src_=prefs;task=erp_pref;pref_type=[type];action=increase'>&gt;</a>"
	var/value_link = "<a href='?_src_=prefs;task=erp_pref;pref_type=[type];action=set'>[html_encode("[current_value]")]</a>"

	return "[dec_link][value_link][inc_link]"

/datum/erp_preference/numeric/handle_topic(mob/user, list/href_list, datum/preferences/prefs)
	if(!ensure_editable(user, prefs))
		return

	switch(href_list["action"])
		if("set")
			var/new_value = input(user, "Enter value ([min_value] to [max_value]):", "ERP Preference", get_value(prefs)) as num|null
			if(isnum(new_value))
				if(!ensure_editable(user, prefs))
					return
				set_value(prefs, clamp(new_value, min_value, max_value))
		if("increase")
			var/current_value = get_value(prefs)
			var/new_value = min(current_value + step_size, max_value)
			set_value(prefs, new_value)
		if("decrease")
			var/current_value = get_value(prefs)
			var/new_value = max(current_value - step_size, min_value)
			set_value(prefs, new_value)

