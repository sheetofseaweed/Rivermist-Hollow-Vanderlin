GLOBAL_LIST_EMPTY(cached_loadout_flat_icons)

/proc/get_cached_loadout_flat_icon(obj/item/item_type)
	var/cache_key = "[item_type]"
	if(!GLOB.cached_loadout_flat_icons[cache_key])
		var/image/dummy = image(initial(item_type.icon), null, initial(item_type.icon_state), initial(item_type.layer))
		GLOB.cached_loadout_flat_icons[cache_key] = "<img src='data:image/png;base64, [icon2base64(getFlatIcon(dummy))]'>"
	return GLOB.cached_loadout_flat_icons[cache_key]

/datum/preferences/proc/open_loadout_menu_selection(mob/user, slot)
	if(!user || !user.client)
		return
	if(slot)
		current_loadout_slot = slot

	user << browse(generate_loadout_menu_html(user), "window=loadout_menu; size=1000x700")

/datum/preferences/proc/generate_loadout_menu_html(mob/user, href_list)

	var/title ="Select loadout"
	var/datum/browser/popup = new(user, "loadout_selection", "<div align='center'>[title]</div>", 400, 600)
	var/list/dat = list()
	dat += "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">"
	dat += "<style>"
	dat += ".loadout-item { display: flex; align-items: center; margin-bottom: 5px; }"
	dat += ".loadout-icon { vertical-align: middle; }"
	dat += ".loadout-text { vertical-align: middle; line-height: 32px; }"
	dat += "</style>"


	for(var/datum/loadout_item/item in GLOB.loadout_items)
		if(item.nobility_check(user))
			var/item_type = item.item_path
			var/loadout_type = item.type
			if(item_type)
				var/loadout_name = item.name
				var/loadout_cost = item.point_cost
				var/display_name = capitalize(loadout_name)
				var/loadout_icon = get_cached_loadout_flat_icon(item_type)
				dat += "<div class='loadout-item'><span class='loadout-icon'>[loadout_icon]</span> <span class='loadout-text'><a href='byond://?_src_=prefs;preference=choose_item;loadout_type=[loadout_type];task=change_loadout_preferences;popup=[REF(popup)];slot=[current_loadout_slot]'>[encode_special_chars(display_name)] | Cost: [loadout_cost]</a></span></div>"
			else
				var/display_name = "None"
				dat += "<div class='loadout-item'><span class='loadout-text'><a href='byond://?_src_=prefs;preference=choose_item;loadout_type=[loadout_type];task=change_loadout_preferences;popup=[REF(popup)];slot=[current_loadout_slot]'>[encode_special_chars(display_name)]</a></span></div>"

	popup.set_content(dat.Join())
	popup.open(FALSE)

/datum/preferences/proc/handle_loadout_topic(mob/user, href_list)

	var/datum/preferences/prefs = user.client?.prefs
	if(!prefs)
		var/datum/browser/B = locate(href_list["popup"])
		if(B)
			B.close()
		return

	switch(href_list["preference"])
		if("choose_item")
			var/path = text2path(href_list["loadout_type"])
			current_loadout_slot = text2num(href_list["slot"])
			var/datum/loadout_item/item = new path
			if(!istype(item))
				var/datum/browser/B = locate(href_list["popup"])
				if(B)
					B.close()
				prefs.open_loadout_menu(user)
				return TRUE
			var/total_points = prefs.get_base_points()
			var/spent_points = 0
			for(var/slot = 1 to 10)
				if(slot == current_loadout_slot)
					continue
				var/datum/loadout_item/other_item = prefs.vars["loadout[slot]"]
				if(other_item)
					if(other_item.type == item.type)
						to_chat(usr, span_warning("[item.name] is already in slot [slot]."))
						prefs.open_loadout_menu(user)
						var/datum/browser/B = locate(href_list["popup"])
						if(B)
							B.close()
						prefs.open_loadout_menu(user)
						return TRUE
					spent_points += other_item.point_cost
			if(spent_points + item.point_cost > total_points)
				to_chat(usr, span_warning("Not enough points! Need [item.point_cost], but only have [total_points - spent_points] remaining."))
				prefs.temp_loadout_selection = null
				var/datum/browser/B = locate(href_list["popup"])
				if(B)
					B.close()
				prefs.open_loadout_menu(user)
				return TRUE
			// apply item to loadout
			var/slot_var = "loadout[current_loadout_slot]"
			prefs.vars[slot_var] = item
			to_chat(usr, span_notice("Selected [item.name] for slot [current_loadout_slot]."))
			prefs.temp_loadout_selection = null
			var/datum/browser/B = locate(href_list["popup"])
			if(B)
				B.close()
			prefs.open_loadout_menu(user)
