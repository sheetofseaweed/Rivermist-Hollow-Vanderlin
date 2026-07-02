
/datum/component/container_craft
	/// Recipe types that can be used with this container
	var/list/viable_recipe_types = list()
	/// Low priority recipes (craft_priority = FALSE)
	var/list/fallback_recipe_types = list()
	/// Callback when craft starts
	var/datum/callback/on_craft_start
	/// Callback when craft fails
	var/datum/callback/on_craft_failed
	/// Callback when craft is successful
	var/datum/callback/on_craft_finished

/**
 * Initialize the component
 */
/datum/component/container_craft/Initialize(list/recipes, temperature_listener, datum/callback/start, datum/callback/fail, datum/callback/success)
	. = ..()
	if(!length(recipes))
		return COMPONENT_INCOMPATIBLE

	viable_recipe_types = list()
	fallback_recipe_types = list()

	for(var/datum/container_craft/recipe as anything in recipes)
		var/datum/container_craft/singleton = GLOB.container_craft_to_singleton[recipe]
		if(!singleton)
			continue
		if(IS_ABSTRACT(singleton))
			continue

		if(singleton.craft_priority)
			viable_recipe_types += recipe
		else
			fallback_recipe_types += recipe

	on_craft_start = start
	on_craft_failed = fail
	on_craft_finished = success
	RegisterSignal(parent, COMSIG_STORAGE_CLOSED, PROC_REF(async_start))
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(async_start))
	// BUGFIX (cooking): COMSIG_STORAGE_CLOSED only fires when nobody is looking at the storage UI,
	// so cooking never started while the player stood next to the oven/pan with the inventory open.
	// React to items physically entering the container instead.
	RegisterSignal(parent, COMSIG_ATOM_ENTERED, PROC_REF(on_entered))
	if(temperature_listener)
		RegisterSignal(parent, COMSIG_REAGENTS_EXPOSE_TEMPERATURE, PROC_REF(async_start))

/**
 * Asynchronously start crafting
 */
/datum/component/container_craft/proc/async_start(datum/source, mob/user)
	INVOKE_ASYNC(src, PROC_REF(attempt_crafts), source, user)

/**
 * BUGFIX (cooking): an item was placed inside the container - try to start crafting
 * immediately, even if someone is still looking at the storage UI.
 * user is passed as null on purpose: attempt_crafts() will resolve the cook
 * via fingerprintslast (set by handle_item_insertion), so skill bonuses still apply.
 */
/datum/component/container_craft/proc/on_entered(datum/source, atom/movable/arrived, atom/old_loc)
	SIGNAL_HANDLER
	if(!isitem(arrived))
		return
	INVOKE_ASYNC(src, PROC_REF(attempt_crafts), source, null)

/**
 * Attempt to craft all possible recipes - try normal priority first, then fallbacks
 */
/datum/component/container_craft/proc/attempt_crafts(datum/source, mob/user)
	var/obj/item/host = parent
	if(!length(host.contents))
		return

	if(!istype(user))
		user = get_mob_by_ckey(host.fingerprintslast)

	//RMH EDITED START
	// BUGFIX (cooking): the old code returned after the first successful craft, so a
	// pan holding several different foods (e.g. mince + sausage + meat) only started
	// one recipe per craft trigger and the rest waited for the next signal - they
	// cooked one type at a time. Now every viable recipe is tried in a single pass,
	// then fallbacks, so all distinct foods start cooking together. Quantity of a
	// single food type is still handled by the craft multiplier, so each recipe only
	// needs to start once here.
	var/list/stored_items = get_unreserved_items(host)

	for(var/datum/container_craft/recipe as anything in viable_recipe_types)
		var/datum/container_craft/singleton = GLOB.container_craft_to_singleton[recipe]
		if(!singleton)
			continue
		if(singleton.try_craft(host, stored_items.Copy(), user, on_craft_start, on_craft_failed))
			stored_items = get_unreserved_items(host)

	for(var/datum/container_craft/recipe as anything in fallback_recipe_types)
		var/datum/container_craft/singleton = GLOB.container_craft_to_singleton[recipe]
		if(!singleton)
			continue
		if(singleton.try_craft(host, stored_items.Copy(), user, on_craft_start, on_craft_failed))
			stored_items = get_unreserved_items(host)
	//RMH EDITED END

//RMH EDITED START
/**
 * Returns a type -> count list of items in the container that are not already
 * reserved by an active crafting operation. Used so multiple recipes can start in
 * one attempt_crafts pass without two recipes claiming the same physical item.
 */
/datum/component/container_craft/proc/get_unreserved_items(obj/item/host)
	var/list/stored_items = list()

	// Build list of all items in container by type
	for(var/obj/item/item in host.contents)
		stored_items |= item.type
		stored_items[item.type]++

	// Subtract items already reserved by active crafts in this container
	for(var/datum/container_craft_operation/op in GLOB.active_container_crafts)
		if(op.crafter != host)
			continue
		for(var/obj/item/reserved_item in op.stored_items)
			if(QDELETED(reserved_item))
				continue
			var/item_type = reserved_item.type
			if(stored_items[item_type])
				stored_items[item_type]--
				if(stored_items[item_type] <= 0)
					stored_items -= item_type

	return stored_items
//RMH EDITED END
