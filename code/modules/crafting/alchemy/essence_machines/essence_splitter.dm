/obj/machinery/essence/splitter
	name = "essence splitter"
	desc = "A rather mundane machine used to extract alchemical essences from natural materials. Can process multiple items at once for efficiency."
	icon = 'icons/roguetown/misc/splitter.dmi'
	icon_state = "splitter"
	accepts_input = FALSE  // Splitters don't receive essence from the network; they produce it
	accepts_output = TRUE
	network_priority = 3   // Process before most consumers

	var/list/current_items = list()
	var/max_items = 6
	var/processing = FALSE
	var/splitting_timer

/obj/machinery/essence/splitter/Initialize()
	. = ..()
	storage.max_total = 5000 //okay
	storage.max_types = 15

	if(GLOB.thaumic_research.has_research(/datum/thaumic_research_node/splitter_efficiency/six))
		max_items = 12
	else if(GLOB.thaumic_research.has_research(/datum/thaumic_research_node/splitter_efficiency/five))
		max_items = 8
	START_PROCESSING(SSobj, src)

/obj/machinery/essence/splitter/Destroy()
	STOP_PROCESSING(SSobj, src)
	if(splitting_timer)
		deltimer(splitting_timer)
		splitting_timer = null
	for(var/obj/item/item as anything in current_items)
		if(!QDELETED(item))
			item.forceMove(drop_location())
	current_items = list()
	return ..()

// The splitter produces essence; it should push outward each tick rather than pull.
/obj/machinery/essence/splitter/process()
	if(!processing)
		push_to_linked(storage)

/obj/machinery/essence/splitter/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	var/parent_result = ..()
	if(parent_result)
		return parent_result
	if(istype(tool, /obj/item/essence_connector) || user.cmode)
		return NONE

	// Research bonuses are re-evaluated on each interaction
	if(GLOB.thaumic_research.has_research(/datum/thaumic_research_node/splitter_efficiency/six))
		max_items = 12
		storage.max_total = 12000
	else if(GLOB.thaumic_research.has_research(/datum/thaumic_research_node/splitter_efficiency/five))
		max_items = 8
		storage.max_total = 8000

	if(processing)
		to_chat(user, span_warning("The splitter is currently processing."))
		return ITEM_INTERACT_BLOCKING

	if(current_items.len >= max_items)
		to_chat(user, span_warning("The splitter is full. Maximum [max_items] items can be processed at once."))
		return ITEM_INTERACT_BLOCKING

	var/datum/natural_precursor/precursor = get_precursor_data(tool)
	if(!precursor)
		to_chat(user, span_warning("[tool] cannot be processed by the essence splitter."))
		return ITEM_INTERACT_BLOCKING

	if(!user.transferItemToLoc(tool, src))
		to_chat(user, span_warning("[tool] is stuck to your hand!"))
		return ITEM_INTERACT_BLOCKING

	current_items += tool
	to_chat(user, span_info("You place [tool] into the essence splitter. ([current_items.len]/[max_items] slots used)"))
	return ITEM_INTERACT_SUCCESS

/obj/machinery/essence/splitter/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(processing)
		to_chat(user, span_warning("The splitter is currently processing."))
		return
	begin_bulk_splitting(user)

/obj/machinery/essence/splitter/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return
	if(processing)
		to_chat(user, span_warning("The splitter is currently processing."))
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	remove_all_items(user)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/machinery/essence/splitter/proc/remove_all_items(mob/user)
	for(var/obj/item/I in current_items)
		I.forceMove(get_turf(src))
	to_chat(user, span_info("You remove all items from the splitter."))
	current_items = list()

/obj/machinery/essence/splitter/proc/begin_bulk_splitting(mob/user)
	if(!current_items.len)
		return

	var/total_essence_yield = 0
	var/list/all_precursors = list()

	var/efficiency_bonus = GLOB.thaumic_research.get_research_bonus(/datum/thaumic_research_node/splitter_efficiency)
	for(var/obj/item/I in current_items)
		var/datum/natural_precursor/precursor = get_precursor_data(I)
		if(precursor)
			all_precursors += precursor
			for(var/essence_type in precursor.essence_yields)
				total_essence_yield += round(precursor.essence_yields[essence_type] * efficiency_bonus, 1)

	if(storage.space() < total_essence_yield)
		to_chat(user, span_warning("The splitter doesn't have enough storage space for this bulk operation."))
		return

	processing = TRUE
	user.visible_message(span_info("[user] activates the essence splitter."))
	update_appearance(UPDATE_OVERLAYS)

	var/speed_divide = GLOB.thaumic_research.get_research_bonus(/datum/thaumic_research_node/splitter_speed)
	var/process_time = (3 SECONDS + (length(current_items) * 1 SECONDS)) / speed_divide
	var/datum/weakref/user_ref = WEAKREF(user)
	splitting_timer = addtimer(CALLBACK(src, PROC_REF(finish_bulk_splitting), all_precursors, user_ref), process_time, TIMER_STOPPABLE)

/obj/machinery/essence/splitter/proc/finish_bulk_splitting(list/precursors, datum/weakref/user_ref)
	splitting_timer = null
	flick_overlay_view(mutable_appearance(icon, "split", ABOVE_MOB_LAYER), 1.2 SECONDS)

	var/efficiency_bonus = GLOB.thaumic_research.get_research_bonus(/datum/thaumic_research_node/splitter_efficiency)
	for(var/datum/natural_precursor/precursor in precursors)
		for(var/essence_type in precursor.essence_yields)
			var/amount = round(precursor.essence_yields[essence_type] * efficiency_bonus, 1)
			storage.add(essence_type, amount)

	for(var/obj/item/I in current_items)
		qdel(I)
	current_items = list()
	processing = FALSE

	// Invalidate the network cache now that our storage contents changed
	if(network)
		network.invalidate_cache()

	visible_message(span_info("The essence splitter sparks."))

	var/mob/living/user = user_ref?.resolve()
	if(user)
		var/boon = user.get_learning_boon(/datum/attribute/skill/craft/alchemy)
		var/amt2raise = (GET_MOB_ATTRIBUTE_VALUE(user, STAT_INTELLIGENCE) * precursors.len) / 2
		user.adjust_experience(/datum/attribute/skill/craft/alchemy, amt2raise * boon, FALSE)

/obj/machinery/essence/splitter/examine(mob/user)
	. = ..()
	. += span_notice("Processing slots: [current_items.len]/[max_items] used")

// Splitters don't accept incoming essence from the network; they only push out.
/obj/machinery/essence/splitter/build_allowed_types()
	return list()
