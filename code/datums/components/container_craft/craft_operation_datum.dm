/**
 * Datum to track a specific crafting operation in progress
 */
/datum/container_craft_operation
	/// The container being crafted in
	var/obj/item/crafter
	/// The recipe being crafted
	var/datum/container_craft/recipe
	/// The user initiating the craft, if any
	var/mob/initiator
	/// The estimated multiplier for this craft
	var/estimated_multiplier = 1
	/// Progress time in deciseconds
	var/progress = 0
	/// Target time in deciseconds
	var/target_time = 0
	/// Last time progress was made
	var/last_progress_time = 0
	/// If the craft has been aborted
	var/aborted = FALSE
	/// List of actual item references reserved for this craft
	var/list/obj/item/stored_items
	/// Callback for when craft is started
	var/datum/callback/on_craft_start
	/// Callback for when craft fails
	var/datum/callback/on_craft_failed
	/// Time with no progress before auto-aborting (in deciseconds)
	var/timeout_period = 30 SECONDS // 30 seconds default
	/// Grace window for crafts paused by recipe.can_progress()
	var/paused_timeout_period = 2 MINUTES
	///do we need the initator near us
	var/requires_proximity = FALSE
	///Path of looping_sound to use while cooking
	var/datum/looping_sound/cooking_sound
	/// TRUE while the craft is paused and the sound loop is stopped
	var/sound_paused = FALSE
	/// TRUE while progress is held by recipe.can_progress()
	var/stalled = FALSE

/**
 * Initialize a new crafting operation
 */
/datum/container_craft_operation/New(obj/item/crafter, datum/container_craft/recipe, mob/initiator, estimated_multiplier, datum/callback/on_craft_start, datum/callback/on_craft_failed, datum/looping_sound/cooking_sound)
	src.crafter = crafter
	src.recipe = recipe
	src.initiator = initiator
	src.estimated_multiplier = estimated_multiplier
	src.on_craft_start = on_craft_start
	src.on_craft_failed = on_craft_failed

	target_time = recipe.get_real_time(crafter, initiator, estimated_multiplier)
	if(recipe.user_craft)
		src.requires_proximity = TRUE

	stored_items = list()

	// Get all items already reserved by other crafts in this container
	var/list/obj/item/reserved_items = list()
	for(var/datum/container_craft_operation/other_craft in GLOB.active_container_crafts)
		if(other_craft == src || other_craft.crafter != crafter)
			continue
		reserved_items |= other_craft.stored_items

	// Determine which requirements are wildcards
	var/list/wildcard_paths = list()
	if(recipe.wildcard_requirements)
		wildcard_paths |= recipe.wildcard_requirements
	if(recipe.optional_wildcard_requirements)
		wildcard_paths |= recipe.optional_wildcard_requirements

	// Build list of all requirements
	var/list/all_requirements = list()
	if(length(recipe.requirements))
		all_requirements += recipe.requirements
	if(length(recipe.optional_requirements))
		all_requirements += recipe.optional_requirements
	all_requirements += wildcard_paths

	// Reserve actual items from the container
	for(var/requirement_path in all_requirements)
		var/needed = all_requirements[requirement_path] * estimated_multiplier
		var/reserved = 0
		var/is_wildcard = (requirement_path in wildcard_paths)

		for(var/obj/item/item in crafter.contents)
			if(reserved >= needed)
				break

			// Skip if already reserved by another craft
			if(item in reserved_items)
				continue

			// Check if this item matches the requirement
			var/matches = FALSE
			if(is_wildcard)
				// Wildcard: accept exact type or subtypes
				matches = ispath(item.type, requirement_path)
			else
				// Exact: only accept exact type match
				matches = (item.type == requirement_path)

			if(matches)
				stored_items += item
				reserved++

	last_progress_time = world.time

	START_PROCESSING(SSprocessing, src)
	GLOB.active_container_crafts += src

	if(on_craft_start)
		on_craft_start.InvokeAsync(crafter, initiator, estimated_multiplier)

	if(cooking_sound)
		src.cooking_sound = new cooking_sound(crafter, TRUE)

/**
 * Process tick for crafting progress
 */
/datum/container_craft_operation/process()
	// Check if the container or user are still valid
	if(recipe.user_craft)
		if((QDELETED(initiator) || !initiator.can_perform_action(crafter, NEED_DEXTERITY|FORBID_TELEKINESIS_REACH)))
			return FALSE

	if(QDELETED(crafter))
		abort_craft("Container or user no longer valid")
		return

	// Check if reserved items still exist and are in the container
	for(var/obj/item/item in stored_items)
		if(QDELETED(item) || item.loc != crafter)
			abort_craft("Requirements no longer met")
			return

	if(!recipe.can_progress(crafter))
		if(!stalled)
			stalled = TRUE
			announce_stall()
		if(cooking_sound && !sound_paused)
			cooking_sound.stop()
			sound_paused = TRUE
		if((world.time - last_progress_time) > paused_timeout_period)
			abort_craft("Craft paused for too long")
		return
	if(stalled)
		stalled = FALSE
		announce_resume()
	if(sound_paused)
		sound_paused = FALSE
		if(cooking_sound)
			cooking_sound.start()

	// Check for timeout (no progress in a while)
	if((world.time - last_progress_time) > timeout_period)
		abort_craft("Craft timed out")
		return

	if(requires_proximity && !initiator.CanReach(crafter))
		return

	// Update progress
	progress += SSprocessing.wait
	last_progress_time = world.time

	// Check if craft is complete
	if(progress >= target_time)
		complete_craft()

/**
 * Completes the crafting operation successfully
 */
/datum/container_craft_operation/proc/complete_craft()
	STOP_PROCESSING(SSprocessing, src)
	GLOB.active_container_crafts -= src

	// Check for failure one last time
	if(recipe.check_failure(crafter, initiator))
		if(on_craft_failed)
			on_craft_failed.InvokeAsync(crafter, initiator)
		qdel(src)
		return

	// Execute the craft
	recipe.execute_craft_completion(crafter, initiator, estimated_multiplier)
	qdel(src)

/**
 * Aborts the crafting operation
 * @param reason The reason for aborting
 */
/// Told to the room when a craft stops making progress but is not lost.
/datum/container_craft_operation/proc/announce_stall()
	if(QDELETED(crafter))
		return
	crafter.visible_message(span_warning("The [lowertext(recipe.name)] stops cooking."))

/// Told to the room when conditions recover and progress resumes.
/datum/container_craft_operation/proc/announce_resume()
	if(QDELETED(crafter))
		return
	crafter.visible_message(span_notice("The [lowertext(recipe.name)] starts cooking again."))

/**
 * Lets outside code push progress into a running craft, e.g. fanning a fire.
 * Refuses while stalled so fanning a dead fire does nothing.
 */
/datum/container_craft_operation/proc/add_progress(amount)
	if(aborted || stalled || amount <= 0)
		return FALSE
	if(!recipe.can_progress(crafter))
		return FALSE
	progress += amount
	last_progress_time = world.time
	return TRUE

/datum/container_craft_operation/proc/abort_craft(reason)
	if(aborted)
		return

	aborted = TRUE
	STOP_PROCESSING(SSprocessing, src)
	GLOB.active_container_crafts -= src

	if(on_craft_failed)
		on_craft_failed.InvokeAsync(crafter, initiator)

	if(!QDELETED(crafter))
		SEND_SIGNAL(crafter, COMSIG_CONTAINER_CRAFT_ABORTED)

	qdel(src)

/**
 * Clean up when the datum is destroyed
 */
/datum/container_craft_operation/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	GLOB.active_container_crafts -= src
	on_craft_start = null
	on_craft_failed = null
	stored_items = null
	if(cooking_sound)
		QDEL_NULL(cooking_sound)
	return ..()
