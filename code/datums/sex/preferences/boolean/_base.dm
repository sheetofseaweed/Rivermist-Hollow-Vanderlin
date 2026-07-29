/datum/erp_preference/boolean
	abstract_type = /datum/erp_preference/boolean

/datum/erp_preference/boolean/show_pref_ui(datum/preferences/prefs, lock_reason = null)
	var/current_value = get_value(prefs)
	var/status_text = current_value ? "Enabled" : "Disabled"
	var/link_class = current_value ? "linkOn" : "linkOff"
	if(lock_reason)
		return wrap_with_tooltip("<a class='linkOff'>[status_text]</a>", lock_reason)
	return "<a href='?_src_=prefs;task=erp_pref;pref_type=[type];action=toggle' class='[link_class]'>[status_text]</a>"

/datum/erp_preference/boolean/handle_topic(mob/user, list/href_list, datum/preferences/prefs)
	if(href_list["action"] == "toggle")
		if(!ensure_editable(user, prefs))
			return
		var/current_value = get_value(prefs)
		set_value(prefs, !current_value)

