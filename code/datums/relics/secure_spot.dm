/obj/structure/secure_spot
	name = "relic holder"
	desc = "A fitted stand made to hold a sacred relic."
	icon = 'icons/roguetown/items/gadgets.dmi'
	icon_state = "folding_table_deployed"
	var/secure_id = SECURE_SPOT_CHURCH
	var/obj/item/stored_item

/obj/structure/secure_spot/Destroy()
	if(stored_item)
		var/obj/item/dropping = stored_item
		clear_stored_item(dropping, update_visuals = FALSE)
		dropping.forceMove(drop_location())
	return ..()

/obj/structure/secure_spot/attackby(obj/item/attacking_item, mob/user, list/modifiers)
	if(stored_item)
		to_chat(user, span_warning("[src] is already holding something!"))
		return TRUE

	if(!user.transferItemToLoc(attacking_item, src))
		return ..()

	stored_item = attacking_item
	RegisterSignals(stored_item, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING), PROC_REF(handle_item_left))
	update_appearance(UPDATE_OVERLAYS)
	SEND_SIGNAL(stored_item, COMSIG_SECURE_SPOT_ACTIVATED, secure_id)
	to_chat(user, span_notice("You place [stored_item] into [src]."))
	return TRUE

/obj/structure/secure_spot/attack_hand(mob/living/user, list/modifiers)
	if(!stored_item)
		return ..()
	empty_spot(user)
	return TRUE

/// Clears state when the stored item is moved or deleted by something else.
/obj/structure/secure_spot/proc/handle_item_left(obj/item/source)
	SIGNAL_HANDLER
	if(source != stored_item)
		return
	clear_stored_item(source)

/obj/structure/secure_spot/proc/empty_spot(mob/living/user)
	if(!stored_item)
		return

	var/obj/item/dropping = stored_item
	clear_stored_item(dropping)
	if(user.put_in_hands(dropping))
		to_chat(user, span_notice("You remove [dropping] from [src]."))
		return

	dropping.forceMove(user.drop_location())
	to_chat(user, span_warning("Your hands are full, so [dropping] tumbles onto the floor!"))

/// Deactivates the relic and releases all holder-side signal registrations.
/obj/structure/secure_spot/proc/clear_stored_item(obj/item/item, update_visuals = TRUE)
	UnregisterSignal(item, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING))
	SEND_SIGNAL(item, COMSIG_SECURE_SPOT_DEACTIVATED, secure_id)
	stored_item = null
	if(update_visuals)
		update_appearance(UPDATE_OVERLAYS)

/obj/structure/secure_spot/update_overlays()
	. = ..()
	if(stored_item)
		var/mutable_appearance/item_overlay = new(stored_item.appearance)
		. += item_overlay
