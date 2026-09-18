/datum/quest/custom/item_collection
	issue_label = "Item collection"
	commission_type = "Item Collection"
	var/obj/item/custom_item_type
	var/custom_item_name = ""
	var/custom_item_count = 1

/datum/quest/custom/item_collection/get_title()
	return title ? title : "Procure [custom_item_count > 1 ? "[custom_item_count]x " : ""][custom_item_name]"

/datum/quest/custom/item_collection/get_objective_text()
	return "Bring [custom_item_count] [custom_item_name] to the marked area beside the contract ledger."

/datum/quest/custom/item_collection/generate(obj/effect/landmark/quest_spawner/landmark)
	. = ..()
	progress_required = custom_item_count

/datum/quest/custom/item_collection/build_from_user(mob/user)
	if(!fill_common_fields(user))
		return FALSE
	var/search_query = tgui_input_text(user, "Search for the requested item:", "Item Search", "", 60)
	if(!search_query)
		return FALSE
	var/list/results = search_quest_item_types(search_query)
	if(!length(results))
		to_chat(user, span_warning("No matching items were found."))
		return FALSE
	var/chosen_name = tgui_input_list(user, "Select the requested item:", "Item Search Results", results)
	if(!chosen_name)
		return FALSE
	custom_item_type = results[chosen_name]
	custom_item_name = initial(custom_item_type.name)
	custom_item_count = tgui_input_number(user, "How many [custom_item_name] are required?", "Item Count", 1, 20, 1)
	if(!custom_item_count)
		return FALSE
	title = tgui_input_text(user, "Give the commission a title (leave blank for an automatic title):", "Commission Title", "", 80)
	if(!title)
		title = get_title()
	return TRUE

/datum/quest/custom/item_collection/build_from_pledge(obj/item/paper/scroll/quest/pledge/pledge, mob/steward)
	if(!..())
		return FALSE
	custom_item_type = pledge.pledge_item_type
	custom_item_name = pledge.pledge_item_name
	custom_item_count = pledge.pledge_item_count
	progress_required = custom_item_count
	return ispath(custom_item_type, /obj/item) && custom_item_count > 0

/datum/quest/custom/item_collection/build_pledge(obj/item/paper/scroll/quest/pledge/pledge)
	..()
	pledge.pledge_item_type = custom_item_type
	pledge.pledge_item_name = custom_item_name
	pledge.pledge_item_count = custom_item_count

/datum/quest/custom/item_collection/validate(mob/steward, turf/input_point, obj/structure/fake_machine/contractledger/ledger)
	if(!ledger?.is_quest_handler(steward) || !custom_item_type || !input_point)
		return FALSE
	var/list/matching_items = list()
	for(var/obj/item/item in input_point)
		if(istype(item, custom_item_type))
			matching_items += item
	if(length(matching_items) < custom_item_count)
		return FALSE

	var/obj/item/quest_package/package = new(input_point)
	package.name = "commission parcel ([custom_item_name])"
	package.quest_title = title
	package.pledge_ref = pledge_ref
	for(var/index in 1 to custom_item_count)
		var/obj/item/item = matching_items[index]
		item.forceMove(package)
	progress_current = progress_required
	mark_complete()
	return TRUE

/proc/search_quest_item_types(query)
	var/list/results = list()
	query = LOWER_TEXT(query)
	for(var/obj/item/item_type as anything in subtypesof(/obj/item))
		if(IS_ABSTRACT(item_type))
			continue
		var/item_name = initial(item_type.name)
		if(!item_name || !findtext(LOWER_TEXT(item_name), query))
			continue
		results["[item_name] ([item_type])"] = item_type
		if(length(results) >= 30)
			break
	return results
