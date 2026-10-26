// Inline tattoo editor in the character creator's Markings window. Uses the tattoo.dm helpers and tattoo_rules().

/// Offered pigment hex matching a colour case-insensitively, or null. Loaded colours are lowercased.
/proc/tattoo_offered_pigment(color)
	if(!istext(color))
		return null
	for(var/pigment_name in GLOB.tattoo_ink_colors)
		var/pigment_color = GLOB.tattoo_ink_colors[pigment_name]
		if(cmptext(pigment_color, color))
			return pigment_color
	return null

/// Inline editor data: zones this body has, grouped by limb, with saved entries, pigments and caps.
/datum/preferences/proc/character_creator_tattoo_data()
	var/list/rules = tattoo_rules()
	var/max_per_zone = rules["max_per_zone"]
	var/list/limbs = list()
	for(var/limb in GLOB.tattoo_zones_by_limb)
		var/list/zones = list()
		for(var/zone in GLOB.tattoo_zones_by_limb[limb])
			var/list/saved = LAZYACCESS(tattoos, zone)
			var/present = !!preview_has_tattoo_zone(zone)
			// A zone the body lost still lists its saved tattoos, so they can be removed.
			if(!present && !length(saved))
				continue
			var/list/entries = list()
			for(var/index in 1 to length(saved))
				var/list/entry = saved[index]
				var/shown_color = tattoo_offered_pigment(entry["color"]) || entry["color"]
				entries += list(list(
					"index" = index,
					"text" = html_decode(entry["text"]),
					"style" = entry["style"],
					"color" = shown_color,
					"pigment" = tattoo_pigment_name(shown_color),
					"medium" = entry["medium"],
				))
			zones += list(list(
				"id" = zone,
				"name" = capitalize(tattoo_zone_name(zone)),
				"intimate" = tattoo_zone_is_intimate(zone),
				"present" = present,
				"full" = length(saved) >= max_per_zone,
				"entries" = entries,
			))
		if(length(zones))
			limbs += list(list(
				"id" = limb,
				"name" = capitalize(tattoo_zone_name(limb)),
				"zones" = zones,
			))
	var/list/pigments = list()
	for(var/pigment_name in GLOB.tattoo_ink_colors)
		pigments += list(list(
			"name" = pigment_name,
			"color" = GLOB.tattoo_ink_colors[pigment_name],
		))
	return list(
		"limbs" = limbs,
		"styles" = list(rules["lettering"], rules["design"]),
		"pigments" = pigments,
		"max_per_zone" = max_per_zone,
		"max_length" = rules["max_length"],
	)

/// Index of a saved tattoo in a zone from a client param, or 0 when there is none.
/datum/preferences/proc/character_creator_tattoo_index(zone, raw_index)
	var/list/entries = LAZYACCESS(tattoos, zone)
	var/index = text2num("[raw_index]")
	if(!islist(entries) || !isnum(index) || index != round(index) || index < 1 || index > length(entries))
		return 0
	return index

/// Asks for tattoo text and cleans it like the tattoo window does; null when cancelled or blank.
/datum/preferences/proc/character_creator_prompt_tattoo_text(mob/user, zone, default_text)
	var/list/rules = tattoo_rules()
	var/max_length = rules["max_length"]
	var/raw_text = tgui_input_text(user, "Describe the tattoo (max [max_length] characters)?", "Tattoo - [tattoo_zone_name(zone)]", default_text, max_length = max_length, encode = FALSE)
	if(!istext(raw_text))
		return null
	var/clean_text = trim(sanitize(raw_text), max_length)
	return length(clean_text) ? clean_text : null

/// Inline editor tasks: add, edit, set_style, set_color, remove. TRUE when the saved tattoos changed.
/datum/preferences/proc/character_creator_tattoo_act(mob/user, list/params)
	var/zone = params["zone"]
	if(!istext(zone) || !(zone in GLOB.tattoo_zone_data))
		return FALSE
	var/list/rules = tattoo_rules()
	var/task = params["task"]
	var/index = character_creator_tattoo_index(zone, params["index"])
	// Removal stays possible on a zone the body lost; every other task needs the zone.
	if(task != "remove" && !preview_has_tattoo_zone(zone))
		return FALSE
	var/style = (params["style"] == rules["lettering"]) ? rules["lettering"] : rules["design"]
	switch(task)
		if("add")
			if(length(LAZYACCESS(tattoos, zone)) >= rules["max_per_zone"])
				return FALSE
			// Only the offered pigments, never an arbitrary hex from the client.
			var/color = tattoo_offered_pigment(params["color"])
			if(!color)
				return FALSE
			var/slot = default_slot
			var/text = character_creator_prompt_tattoo_text(user, zone)
			// The prompt sleeps, so the slot, body or zone may have changed meanwhile.
			if(!text || slot != default_slot || !preview_has_tattoo_zone(zone) || length(LAZYACCESS(tattoos, zone)) >= rules["max_per_zone"])
				return FALSE
			LAZYINITLIST(tattoos)
			if(!tattoos[zone])
				tattoos[zone] = list()
			tattoos[zone] += list(list(
				"zone" = zone,
				"text" = text,
				"style" = style,
				"color" = color,
				"medium" = rules["ink"],
				"state" = rules["fresh"],
			))
		if("edit")
			if(!index)
				return FALSE
			var/list/entry = tattoos[zone][index]
			var/text = character_creator_prompt_tattoo_text(user, zone, html_decode(entry["text"]))
			if(!text)
				return FALSE
			// The prompt sleeps, so the entry may have moved or the slot changed meanwhile.
			var/list/entries = LAZYACCESS(tattoos, zone)
			if(!islist(entries) || index > length(entries) || entries[index] != entry)
				return FALSE
			entry["text"] = text
		if("set_style")
			if(!index)
				return FALSE
			var/list/entry = tattoos[zone][index]
			if(entry["style"] == style)
				return FALSE
			entry["style"] = style
		if("set_color")
			if(!index)
				return FALSE
			var/color = tattoo_offered_pigment(params["color"])
			if(!color)
				return FALSE
			var/list/entry = tattoos[zone][index]
			if(entry["color"] == color)
				return FALSE
			entry["color"] = color
		if("remove")
			if(!index)
				return FALSE
			var/list/entries = tattoos[zone]
			entries.Cut(index, index + 1)
			if(!length(entries))
				tattoos -= zone
		else
			return FALSE
	update_menu_data(user)
	return TRUE
