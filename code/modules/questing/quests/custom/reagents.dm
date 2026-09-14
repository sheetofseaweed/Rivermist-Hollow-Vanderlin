/datum/quest/custom/reagent
	issue_label = "Liquid collection"
	commission_type = "Liquid Collection"
	var/datum/reagent/reagent_type_path
	var/reagent_name = ""
	var/reagent_volume_required = 10

/datum/quest/custom/reagent/get_title()
	return title ? title : "Procure [reagent_volume_required] units of [reagent_name ? reagent_name : "reagent"]"

/datum/quest/custom/reagent/get_objective_text()
	return "Bring [reagent_volume_required] units of [reagent_name] in containers to the marked area beside the contract ledger."

/datum/quest/custom/reagent/generate(obj/effect/landmark/quest_spawner/landmark)
	. = ..()
	progress_required = reagent_volume_required

/datum/quest/custom/reagent/build_from_user(mob/user)
	if(!fill_common_fields(user))
		return FALSE
	var/search_query = tgui_input_text(user, "Search for the requested liquid:", "Reagent Search", "", 60)
	if(!search_query)
		return FALSE
	var/list/results = search_quest_reagent_types(search_query)
	if(!length(results))
		to_chat(user, span_warning("No matching liquids were found."))
		return FALSE
	var/chosen_name = tgui_input_list(user, "Select the requested liquid:", "Reagent Search Results", results)
	if(!chosen_name)
		return FALSE
	reagent_type_path = results[chosen_name]
	reagent_name = initial(reagent_type_path.name)
	reagent_volume_required = tgui_input_number(user, "How many units of [reagent_name] are required?", "Liquid Volume", 10, 200, 1)
	if(!reagent_volume_required)
		return FALSE
	title = tgui_input_text(user, "Give the commission a title (leave blank for an automatic title):", "Commission Title", "", 80)
	if(!title)
		title = get_title()
	return TRUE

/datum/quest/custom/reagent/build_from_pledge(obj/item/paper/scroll/quest/pledge/pledge, mob/steward)
	if(!..())
		return FALSE
	reagent_type_path = pledge.pledge_reagent_type
	reagent_name = pledge.pledge_reagent_name
	reagent_volume_required = pledge.pledge_reagent_volume
	progress_required = reagent_volume_required
	return ispath(reagent_type_path, /datum/reagent) && reagent_volume_required > 0

/datum/quest/custom/reagent/build_pledge(obj/item/paper/scroll/quest/pledge/pledge)
	..()
	pledge.pledge_reagent_type = reagent_type_path
	pledge.pledge_reagent_name = reagent_name
	pledge.pledge_reagent_volume = reagent_volume_required

/datum/quest/custom/reagent/validate(mob/steward, turf/input_point, obj/structure/fake_machine/contractledger/ledger)
	if(!ledger?.is_quest_handler(steward) || !reagent_type_path || !input_point)
		return FALSE
	var/available_volume = 0
	var/list/matching_containers = list()
	for(var/obj/item/container in input_point)
		if(!container.reagents?.has_reagent(reagent_type_path))
			continue
		available_volume += container.reagents.get_reagent_amount(reagent_type_path)
		matching_containers += container
	if(available_volume < reagent_volume_required)
		return FALSE

	var/obj/item/quest_package/package = new(input_point)
	package.name = "commission parcel ([reagent_name])"
	package.quest_title = title
	package.pledge_ref = pledge_ref
	for(var/obj/item/container as anything in matching_containers)
		container.forceMove(package)
	progress_current = progress_required
	mark_complete()
	return TRUE

/proc/search_quest_reagent_types(query)
	var/list/results = list()
	query = LOWER_TEXT(query)
	for(var/datum/reagent/reagent_type as anything in subtypesof(/datum/reagent))
		if(IS_ABSTRACT(reagent_type))
			continue
		var/reagent_name = initial(reagent_type.name)
		if(!reagent_name || !findtext(LOWER_TEXT(reagent_name), query))
			continue
		results[reagent_name] = reagent_type
		if(length(results) >= 30)
			break
	return results
