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

/obj/item/tray/pre_attack(atom/target, mob/living/user, list/modifiers)
	if(!istype(target, /obj/item/cooking/pan) && !istype(target, /obj/item/reagent_containers/glass/bucket/pot))
		return ..()
	if(!length(contents))
		return ..()

	var/tipped = 0
	for(var/obj/item/reagent_containers/food/snacks/food as anything in contents.Copy())
		if(!SEND_SIGNAL(src, COMSIG_TRY_STORAGE_TAKE, food, get_turf(user), TRUE))
			continue
		if(!SEND_SIGNAL(target, COMSIG_TRY_STORAGE_INSERT, food, user, TRUE, TRUE))
			// Wouldn't fit after all - put it back rather than dropping it.
			SEND_SIGNAL(src, COMSIG_TRY_STORAGE_INSERT, food, user, TRUE, TRUE)
			continue
		tipped++

	if(!tipped)
		to_chat(user, span_warning("Nothing on [src] will fit into [target]."))
		return TRUE

	user.visible_message(span_notice("[user] tips [tipped] thing\s from [src] into [target]."), span_notice("I tip [tipped] thing\s into [target]."))
	update_appearance(UPDATE_OVERLAYS)
	return TRUE

#undef TRAY_MODE_COLOUR
