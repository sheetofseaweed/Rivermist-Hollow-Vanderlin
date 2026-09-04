/**
 * Tray handling.
 *
 * Right-click in hand cycles how the tray gathers (one / same type / the whole
 * tile), the current mode shows on examine, left-click in hand sets everything
 * out onto a table in front of you, and clicking a pan or pot on the fire tips
 * the tray's food straight into it.
 *
 * Mode cycling deliberately does not use middle-click: /mob/living/MiddleClickOn
 * only forwards to MiddleClick when the user has no mmb_intent selected and the
 * target is Adjacent, neither of which holds for an item in your own hand.
 */

#define TRAY_MODE_COLOUR "#d4af37"

/obj/item/tray/proc/get_tray_storage()
	return GetComponent(/datum/component/storage)

/obj/item/tray/examine(mob/user)
	. = ..()
	var/datum/component/storage/storage = get_tray_storage()
	if(!storage)
		return
	var/mode_text
	switch(storage.collection_mode)
		if(COLLECT_ONE)
			mode_text = "Set to pick up a single item."
		if(COLLECT_SAME)
			mode_text = "Set to pick up every item of the type clicked."
		if(COLLECT_EVERYTHING)
			mode_text = "Set to pick up everything on the tile at once."
	. += "<font color='[TRAY_MODE_COLOUR]'>[mode_text] Right-click it in hand to change.</font>"

/obj/item/tray/attack_self_secondary(mob/user, list/modifiers)
	. = ..()
	var/datum/component/storage/storage = get_tray_storage()
	if(!storage)
		return
	storage.gather_mode_switch(user)

/obj/item/tray/attack_self(mob/user, list/modifiers)
	. = ..()
	if(!length(contents))
		return
	var/obj/structure/table/table = locate(/obj/structure/table) in get_step(user, user.dir)
	if(!table)
		to_chat(user, span_warning("There's no table in front of me to set this down on."))
		return
	var/turf/table_turf = get_turf(table)
	// Must go out through the storage component: a raw forceMove leaves the item
	// still registered with the storage, so it keeps its inventory screen object
	// (the grid outline, the hover name stuck at the old screen slot) and can't
	// be picked up off the table.
	for(var/obj/item/carried as anything in contents.Copy())
		SEND_SIGNAL(src, COMSIG_TRY_STORAGE_TAKE, carried, table_turf, TRUE)
	user.visible_message(span_notice("[user] sets out everything from [src] onto [table]."), span_notice("I set everything out onto [table]."))
	update_appearance(UPDATE_OVERLAYS)

/**
 * Resolves what we're tipping food into. Clicking a hearth hits the hearth,
 * not the pot hung on it, so unwrap the attachment.
 */
/obj/item/tray/proc/get_tip_target(atom/target)
	if(istype(target, /obj/machinery/light/fueled/hearth))
		var/obj/machinery/light/fueled/hearth/hearth = target
		target = hearth.attachment
	if(istype(target, /obj/item/cooking/pan))
		return target
	if(istype(target, /obj/item/reagent_containers/glass/bucket/pot))
		return target
	return null

/obj/item/tray/pre_attack(atom/target, mob/living/user, list/modifiers)
	var/obj/item/vessel = get_tip_target(target)
	if(!vessel)
		return ..()
	if(!length(contents))
		return ..()

	var/tipped = 0
	for(var/obj/item/reagent_containers/food/snacks/food in contents.Copy())
		if(!SEND_SIGNAL(src, COMSIG_TRY_STORAGE_TAKE, food, get_turf(user), TRUE))
			continue
		if(!SEND_SIGNAL(vessel, COMSIG_TRY_STORAGE_INSERT, food, user, TRUE, TRUE))
			// Wouldn't fit after all - put it back rather than dropping it.
			SEND_SIGNAL(src, COMSIG_TRY_STORAGE_INSERT, food, user, TRUE, TRUE)
			continue
		tipped++

	if(!tipped)
		to_chat(user, span_warning("Nothing on [src] will fit into [vessel]."))
		return TRUE

	user.visible_message(span_notice("[user] tips [tipped] thing\s from [src] into [vessel]."), span_notice("I tip [tipped] thing\s into [vessel]."))
	update_appearance(UPDATE_OVERLAYS)
	return TRUE

#undef TRAY_MODE_COLOUR

/**
 * Draws what's on the tray.
 *
 * Offsets are laid out on a fixed grid rather than randomised, so an item does
 * not jump to a new spot every time anything is added or taken off.
 */
/obj/item/tray/update_overlays()
	. = ..()
	var/index = 0
	for(var/obj/item/carried in contents)
		var/mutable_appearance/carried_appearance = new(carried)
		// The grid storage paints its inventory-slot background into the item's
		// underlays while it is stored (and clears it on removal). Copying the
		// appearance verbatim drags that backing square onto the tray, so strip
		// it and the stack-count maptext from our copy.
		carried_appearance.underlays = null
		carried_appearance.maptext = ""
		carried_appearance.plane = FLOAT_PLANE
		carried_appearance.layer = FLOAT_LAYER
		carried_appearance.pixel_x = -9 + ((index % 4) * 6)
		carried_appearance.pixel_y = 5 - (round(index / 4) * 7)
		. += carried_appearance
		index++

/obj/item/tray/Entered(atom/movable/arrived, atom/old_loc)
	. = ..()
	update_appearance(UPDATE_OVERLAYS)

/obj/item/tray/Exited(atom/movable/gone, atom/new_loc)
	. = ..()
	update_appearance(UPDATE_OVERLAYS)
