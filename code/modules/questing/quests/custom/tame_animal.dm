/datum/quest/custom/tame_animal
	issue_label = "Tame animal"
	commission_type = "Animal Taming"
	var/mob/living/simple_animal/target_animal_type
	var/target_animal_name = ""

/datum/quest/custom/tame_animal/get_title()
	return title ? title : "Tame a [target_animal_name ? target_animal_name : "beast"]"

/datum/quest/custom/tame_animal/get_objective_text()
	return "Bring a tamed [target_animal_name] to the marked area beside the contract ledger."

/datum/quest/custom/tame_animal/build_from_user(mob/user)
	if(!fill_common_fields(user))
		return FALSE
	var/list/animal_types = list()
	for(var/mob/living/simple_animal/animal_type as anything in subtypesof(/mob/living/simple_animal))
		if(IS_ABSTRACT(animal_type) || !initial(animal_type.tame_chance))
			continue
		var/animal_name = initial(animal_type.name)
		if(animal_name && !animal_types[animal_name])
			animal_types[animal_name] = animal_type
	if(!length(animal_types))
		return FALSE
	target_animal_name = tgui_input_list(user, "Which animal should be tamed?", "Animal Type", animal_types)
	if(!target_animal_name)
		return FALSE
	target_animal_type = animal_types[target_animal_name]
	title = tgui_input_text(user, "Give the commission a title (leave blank for an automatic title):", "Commission Title", "", 80)
	if(!title)
		title = get_title()
	return TRUE

/datum/quest/custom/tame_animal/build_from_pledge(obj/item/paper/scroll/quest/pledge/pledge, mob/steward)
	if(!..())
		return FALSE
	target_animal_type = pledge.pledge_item_type
	target_animal_name = pledge.pledge_item_name
	return ispath(target_animal_type, /mob/living/simple_animal)

/datum/quest/custom/tame_animal/build_pledge(obj/item/paper/scroll/quest/pledge/pledge)
	..()
	pledge.pledge_item_type = target_animal_type
	pledge.pledge_item_name = target_animal_name

/datum/quest/custom/tame_animal/validate(mob/steward, turf/input_point, obj/structure/fake_machine/contractledger/ledger)
	if(!ledger?.is_quest_handler(steward) || !target_animal_type || !input_point)
		return FALSE
	var/mob/living/simple_animal/tamed_animal
	for(var/mob/living/simple_animal/animal in input_point)
		if(istype(animal, target_animal_type) && animal.tame)
			tamed_animal = animal
			break
	if(!tamed_animal)
		return FALSE

	var/mob/living/patron = quest_giver_reference?.resolve()
	if(patron)
		var/list/current_friends = tamed_animal.ai_controller?.blackboard[BB_FRIENDS_LIST]
		for(var/mob/living/friend as anything in current_friends)
			tamed_animal.unfriend(friend)
		tamed_animal.tamed(patron)
	progress_current = progress_required
	mark_complete()
	return TRUE
