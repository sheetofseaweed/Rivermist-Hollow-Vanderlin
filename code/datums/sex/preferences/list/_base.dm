/datum/erp_preference/list_choice
	abstract_type = /datum/erp_preference/list_choice
	/// List of available choices
	var/list/choices = list()
	/// The default choice (should be in choices list)
	var/default_choice = null

/datum/erp_preference/list_choice/New()
	. = ..()
	if(length(choices) && !default_choice)
		default_choice = choices[1]
	if(default_choice && !(default_choice in choices))
		CRASH("ERP preference [type] has a default choice which is unavailable in its choice list.")

/datum/erp_preference/list_choice/get_value(datum/preferences/prefs)
	return get_value_from_list(prefs?.erp_preferences)

/datum/erp_preference/list_choice/get_value_from_list(list/stored_preferences)
	var/stored_value = stored_preferences?[type]
	if(!stored_value || !(stored_value in choices))
		return get_default_value()
	return stored_value

/datum/erp_preference/list_choice/get_default_value()
	return default_choice

/datum/erp_preference/list_choice/show_pref_ui(datum/preferences/prefs, lock_reason = null)
	var/current_value = get_value(prefs)
	var/prev_link = ""
	var/next_link = ""
	var/choice_link = ""

	if(lock_reason)
		prev_link = wrap_with_tooltip("<a class='linkOff'>&lt;</a>", lock_reason)
		next_link = wrap_with_tooltip("<a class='linkOff'>&gt;</a>", lock_reason)
		choice_link = wrap_with_tooltip("<a class='linkOff'>[html_encode("[current_value]")]</a>", lock_reason)
	else if(length(choices) > 1)
		prev_link = "<a href='?_src_=prefs;task=erp_pref;pref_type=[type];action=prev'>&lt;</a>"
		next_link = "<a href='?_src_=prefs;task=erp_pref;pref_type=[type];action=next'>&gt;</a>"
	else
		prev_link = "<a class='linkOff'>&lt;</a>"
		next_link = "<a class='linkOff'>&gt;</a>"

	if(!length(choice_link) && length(choices) > 1)
		choice_link = "<a href='?_src_=prefs;task=erp_pref;pref_type=[type];action=choose'>[html_encode("[current_value]")]</a>"
	else if(!length(choice_link))
		choice_link = "<a class='linkOff'>[html_encode("[current_value]")]</a>"

	return "[prev_link][choice_link][next_link]"

/datum/erp_preference/list_choice/handle_topic(mob/user, list/href_list, datum/preferences/prefs)
	if(!ensure_editable(user, prefs))
		return

	switch(href_list["action"])
		if("choose")
			var/chosen = input(user, "Choose your [lowertext(name)]:", "ERP Preference") as null|anything in choices
			if(chosen)
				if(!ensure_editable(user, prefs))
					return
				set_value(prefs, chosen)
		if("prev", "next")
			var/current_value = get_value(prefs)
			var/current_index = choices.Find(current_value)
			var/target_index = current_index

			if(href_list["action"] == "next")
				target_index++
			else
				target_index--

			if(target_index > length(choices))
				target_index = 1
			else if(target_index <= 0)
				target_index = length(choices)

			set_value(prefs, choices[target_index])

