/datum/quest/custom/delivery
	issue_label = "Item delivery"
	commission_type = "Item Delivery"
	requires_steward_validation = FALSE
	var/delivery_target_name = ""
	var/delivery_target_ckey = ""
	var/datum/weakref/delivery_parcel_ref

/datum/quest/custom/delivery/get_title()
	return title ? title : (delivery_target_name ? "Deliver a parcel to [delivery_target_name]" : "Delivery Commission")

/datum/quest/custom/delivery/get_objective_text()
	return "Deliver the sealed parcel to [delivery_target_name ? delivery_target_name : "the named recipient"]."

/datum/quest/custom/delivery/get_location_text()
	return "Locate [delivery_target_name ? delivery_target_name : "the recipient"] and make the delivery."

/datum/quest/custom/delivery/build_from_user(mob/user)
	if(!fill_common_fields(user))
		return FALSE
	var/list/player_choices = list()
	for(var/mob/living/carbon/human/player in GLOB.player_list)
		if(player == user || player.stat == DEAD || !player.real_name)
			continue
		player_choices["[length(player_choices) + 1]. [player.real_name] — [player.job ? player.job : "Unknown role"]"] = player
	if(!length(player_choices))
		to_chat(user, span_warning("There are no valid delivery recipients."))
		return FALSE
	var/target_choice = tgui_input_list(user, "Who should receive the parcel?", "Delivery Recipient", player_choices)
	var/mob/living/carbon/human/target_player = player_choices[target_choice]
	if(!target_player)
		return FALSE
	delivery_target_name = target_player.real_name
	delivery_target_ckey = target_player.ckey
	title = tgui_input_text(user, "Give the commission a title (leave blank for an automatic title):", "Commission Title", "", 80)
	if(!title)
		title = get_title()
	return TRUE

/datum/quest/custom/delivery/build_from_pledge(obj/item/paper/scroll/quest/pledge/pledge, mob/steward)
	if(!..())
		return FALSE
	delivery_target_name = pledge.pledge_delivery_target
	delivery_target_ckey = pledge.pledge_delivery_target_ckey
	return !!delivery_target_name && length(pledge.packed_delivery_items)

/datum/quest/custom/delivery/build_pledge(obj/item/paper/scroll/quest/pledge/pledge)
	..()
	pledge.pledge_delivery_target = delivery_target_name
	pledge.pledge_delivery_target_ckey = delivery_target_ckey

/datum/quest/custom/delivery/can_claim(mob/user)
	var/obj/item/paper/scroll/quest/pledge/pledge = pledge_ref?.resolve()
	return pledge && !is_delivery_target(user) && length(pledge.packed_delivery_items)

/datum/quest/custom/delivery/on_claim(mob/user)
	. = ..()
	var/obj/item/paper/scroll/quest/pledge/pledge = pledge_ref?.resolve()
	if(!pledge || !length(pledge.packed_delivery_items))
		return
	var/obj/item/quest_package/parcel = new(get_turf(user))
	parcel.name = "delivery parcel for [delivery_target_name]"
	parcel.quest_title = title
	parcel.delivery_target_name = delivery_target_name
	parcel.delivery_target_ckey = delivery_target_ckey
	for(var/obj/item/item as anything in pledge.packed_delivery_items.Copy())
		if(QDELETED(item))
			continue
		item.forceMove(parcel)
	pledge.packed_delivery_items.Cut()
	delivery_parcel_ref = WEAKREF(parcel)
	RegisterSignal(parcel, COMSIG_OBJ_HANDED_OVER, PROC_REF(on_parcel_handed_over))
	RegisterSignal(parcel, COMSIG_MOVABLE_MOVED, PROC_REF(on_parcel_moved))
	user.put_in_hands(parcel)

/datum/quest/custom/delivery/validate(mob/steward, turf/input_point, obj/structure/fake_machine/contractledger/ledger)
	to_chat(steward, span_warning("Delivery commissions are verified automatically when the named recipient receives the parcel."))
	return FALSE

/datum/quest/custom/delivery/on_return_to_board()
	var/obj/item/paper/scroll/quest/pledge/pledge = pledge_ref?.resolve()
	var/obj/item/quest_package/parcel = delivery_parcel_ref?.resolve()
	if(!pledge || !parcel)
		return
	UnregisterSignal(parcel, list(COMSIG_OBJ_HANDED_OVER, COMSIG_MOVABLE_MOVED))
	for(var/obj/item/item in parcel.contents)
		item.forceMove(pledge)
		pledge.packed_delivery_items += item
	delivery_parcel_ref = null
	qdel(parcel)

/datum/quest/custom/delivery/proc/on_parcel_handed_over(obj/item/quest_package/parcel, mob/offerer, mob/target)
	SIGNAL_HANDLER
	try_complete_delivery(parcel, offerer, target)

/datum/quest/custom/delivery/proc/on_parcel_moved(obj/item/quest_package/parcel)
	SIGNAL_HANDLER
	if(ishuman(parcel.loc))
		try_complete_delivery(parcel, null, parcel.loc)
		return
	if(!isturf(parcel.loc))
		return
	for(var/mob/living/carbon/human/player in parcel.loc)
		if(is_delivery_target(player))
			try_complete_delivery(parcel, null, player)
			return

/datum/quest/custom/delivery/proc/is_delivery_target(mob/possible_target)
	if(!possible_target)
		return FALSE
	if(delivery_target_ckey)
		return possible_target.ckey == delivery_target_ckey
	return possible_target.real_name == delivery_target_name

/datum/quest/custom/delivery/proc/try_complete_delivery(obj/item/quest_package/parcel, mob/deliverer, mob/recipient)
	if(complete || !is_delivery_target(recipient))
		if(deliverer && !is_delivery_target(recipient))
			to_chat(deliverer, span_warning("That is not the named recipient."))
		return
	UnregisterSignal(parcel, list(COMSIG_OBJ_HANDED_OVER, COMSIG_MOVABLE_MOVED))
	progress_current = progress_required
	mark_complete()
	if(deliverer)
		to_chat(deliverer, span_notice("Delivery confirmed. Return the contract scroll to the ledger for payment."))
	to_chat(recipient, span_notice("You receive [parcel]."))

/datum/quest/custom/delivery/Destroy()
	var/obj/item/quest_package/parcel = delivery_parcel_ref?.resolve()
	if(parcel)
		UnregisterSignal(parcel, list(COMSIG_OBJ_HANDED_OVER, COMSIG_MOVABLE_MOVED))
	return ..()
