/datum/erp_preference
	abstract_type = /datum/erp_preference
	/// User facing name of the preference
	var/name = "ERP Preference"
	/// Description shown to the user
	var/description = ""
	/// Whether this preference is enabled by default
	var/default_value = FALSE
	/// Category for organization in menus
	var/category = "General"

/datum/erp_preference/proc/get_value(datum/preferences/prefs)
	if(isnull(prefs.erp_preferences[type]))
		return default_value
	else
		return prefs.erp_preferences[type]

/datum/erp_preference/proc/set_value(datum/preferences/prefs, value)
	if(!prefs.erp_preferences)
		prefs.erp_preferences = list()
	prefs.erp_preferences[type] = value

/datum/erp_preference/proc/show_pref_ui(datum/preferences/prefs)
	return

/datum/erp_preference/proc/handle_topic(mob/user, list/href_list, datum/preferences/prefs)
	return

/datum/erp_preference/proc/show_session_ui(datum/preferences/prefs, editable = FALSE, session)
	var/current_value = get_value(prefs)
	if(editable)
		return "<div class='pref-toggle enabled'>[current_value]</div>"
	else
		return "<div class='pref-toggle disabled'>[current_value]</div>"

/datum/erp_preference/proc/handle_session_topic(mob/user, list/href_list, datum/preferences/prefs, session)
	// Return TRUE if the topic was handled, FALSE otherwise
	return FALSE
