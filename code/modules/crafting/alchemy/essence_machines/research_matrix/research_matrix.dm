
/obj/machinery/essence/research_matrix
	name = "Alchemical Engine"
	desc = "A black iconosphere radiating alchemic heat. It hums expectantly."
	icon = 'icons/roguetown/misc/alchemy.dmi'
	icon_state = "placeholder"
	network_priority = 5

	var/datum/thaumic_research_node/selected_research = null
	var/datum/weakref/current_user

/obj/machinery/essence/research_matrix/Initialize()
	. = ..()
	storage.max_total = INFINITY
	storage.max_types = 10

/obj/machinery/essence/research_matrix/Destroy()
	QDEL_NULL(selected_research)
	current_user = null
	return ..()

/obj/machinery/essence/research_matrix/build_allowed_types()
	if(!selected_research)
		return list()
	var/list/result = list()
	for(var/etype in selected_research.required_essences)
		var/deficit = selected_research.required_essences[etype] - storage.get(etype)
		if(deficit > 0)
			result[etype] = deficit
	return result

/obj/machinery/essence/research_matrix/push_to_linked(datum/essence_storage/from_storage)
	push_surplus_to_linked(from_storage)

/obj/machinery/essence/research_matrix/attack_hand(mob/user, list/modifiers)
	current_user = WEAKREF(user)
	open_research_interface(user)

/obj/machinery/essence/research_matrix/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(user.cmode || !istype(tool, /obj/item/essence_vial))
		return NONE
	var/obj/item/essence_vial/vial = tool
	if(!vial.contained_essence || vial.essence_amount <= 0)
		to_chat(user, span_warning("The vial is empty."))
		return ITEM_INTERACT_BLOCKING
	if(!selected_research)
		to_chat(user, span_warning("No research selected."))
		return ITEM_INTERACT_BLOCKING
	var/etype = vial.contained_essence.type
	if(!accepts_essence(etype))
		to_chat(user, span_warning("This essence is not needed for the current research."))
		return ITEM_INTERACT_BLOCKING
	var/deficit = selected_research.required_essences[etype] - storage.get(etype)
	var/poured = storage.add(etype, min(vial.essence_amount, deficit))
	if(poured <= 0)
		return ITEM_INTERACT_BLOCKING
	vial.essence_amount -= poured
	if(vial.essence_amount <= 0)
		vial.contained_essence = null
	vial.update_appearance(UPDATE_OVERLAYS)
	to_chat(user, span_info("You pour [poured] units into the engine."))
	current_user = WEAKREF(user)
	check_completion(user)
	return ITEM_INTERACT_SUCCESS

/obj/machinery/essence/research_matrix/on_storage_changed(essence_type, amount, added)
	..()
	if(!added)
		return
	var/mob/user = current_user?.resolve()
	if(user)
		check_completion(user)

/obj/machinery/essence/research_matrix/proc/check_completion(mob/user)
	if(!selected_research)
		return
	for(var/etype in selected_research.required_essences)
		if(storage.get(etype) < selected_research.required_essences[etype])
			return
	complete_research(user)

/obj/machinery/essence/research_matrix/proc/complete_research(mob/user)
	if(!selected_research)
		return
	for(var/etype in selected_research.required_essences)
		storage.remove(etype, selected_research.required_essences[etype])
	GLOB.thaumic_research.unlock_research(selected_research.type)
	visible_message(span_notice("[src] hums and rumbles with satisfied alchemic energy!"))
	if(user)
		var/boon = user.get_learning_boon(/datum/attribute/skill/craft/alchemy)
		user.adjust_experience(/datum/attribute/skill/craft/alchemy,
			selected_research.experience_reward * boon, FALSE)
	qdel(selected_research)
	selected_research = null
	network?.invalidate_cache()
	addtimer(CALLBACK(src, PROC_REF(open_research_interface), user), 1)

/obj/machinery/essence/research_matrix/proc/open_research_interface(mob/user)
	if(QDELETED(src) || QDELETED(user) || !user.default_can_use_topic(src))
		return
	var/datum/research_interface/iface = new(src, user)
	iface.show()

/obj/machinery/essence/research_matrix/Topic(href, href_list)
	. = ..()
	if(.)
		return
	if(href_list["action"] != "select_research")
		return
	var/mob/living/user = usr
	if(!istype(user) || !user.default_can_use_topic(src))
		return
	var/node_type = text2path(href_list["node"])
	var/static/list/valid_nodes = subtypesof(/datum/thaumic_research_node)
	if(!node_type || !(node_type in valid_nodes))
		return
	var/datum/thaumic_research_node/node = new node_type
	if(GLOB.thaumic_research.has_research(node_type))
		to_chat(user, span_warning("Already researched."))
		qdel(node)
		return
	if(!GLOB.thaumic_research.can_research(node_type))
		to_chat(user, span_warning("Prerequisites not met."))
		qdel(node)
		return
	QDEL_NULL(selected_research)
	selected_research = node
	current_user = WEAKREF(user)
	network?.invalidate_cache()
	// No network to invalidate since accepts_input = FALSE,
	// but push out anything the old research needed that the new one doesn't
	push_surplus_to_linked(storage)
	to_chat(user, span_info("Selected: [node.name]"))
	addtimer(CALLBACK(src, PROC_REF(open_research_interface), user), 0.1 SECONDS)

/obj/machinery/essence/research_matrix/get_mechanics_examine(mob/user)
	. = ..()
	. += span_notice("Unlocked research nodes: [GLOB.thaumic_research.unlocked_research.len]")
	if(selected_research)
		. += span_notice("Selected: [selected_research.name]")
		for(var/etype in selected_research.required_essences)
			var/needed = selected_research.required_essences[etype]
			var/have = storage.get(etype)
			var/datum/thaumaturgical_essence/e = new etype
			. += span_notice("  [e.name]: [have]/[needed]")
			qdel(e)
