/**
 * Build mode undo: the last BM_UNDO_STEPS placements, paints, erases and deletions can be undone
 * (Ctrl + Z, or the Undo button in the catalogue).
 *
 * Placed objects are deleted on undo; changed turfs get their previous type back. Deleted objects
 * are not destroyed at once: they wait in nullspace while their step can still be undone, and are
 * destroyed for good when the step falls off the stack or the admin leaves build mode.
 * Mobs removed by an area erase cannot be brought back.
 */

#define BM_UNDO_STEPS 20
/// Deleted objects one step keeps for undo. Past this they are destroyed at once: a huge erase
/// must not leave thousands of objects (some still processing) waiting in nullspace.
#define BM_UNDO_TRASH_LIMIT 300

/datum/buildmode_undo
	var/label
	/// Weakrefs to what this step created.
	var/list/created = list()
	/// list(turf, previous turf type), oldest first.
	var/list/turf_changes = list()
	/// Objects this step removed: object -> turf it was on.
	var/list/trashed = list()
	/// TRUE when some deletions of this step could not be kept for undo.
	var/partial = FALSE

/datum/buildmode_undo/New(label)
	src.label = label

/datum/buildmode_undo/proc/is_empty()
	return !length(created) && !length(turf_changes) && !length(trashed)

/// Destroys what this step kept aside: called when the step can no longer be undone.
/datum/buildmode_undo/proc/expire()
	for(var/atom/movable/thing as anything in trashed)
		if(!QDELETED(thing))
			qdel(thing)
	trashed.Cut()

/datum/buildmode_undo/proc/undo()
	var/restored = 0
	for(var/datum/weakref/ref as anything in created)
		var/atom/movable/thing = ref.resolve()
		if(!QDELETED(thing))
			qdel(thing)
			restored++
	for(var/index in length(turf_changes) to 1 step -1)
		var/list/change = turf_changes[index]
		var/turf/target = change[1]
		if(target)
			target.ChangeTurf(change[2])
			restored++
	for(var/atom/movable/thing as anything in trashed)
		var/turf/home = trashed[thing]
		if(!QDELETED(thing) && home)
			thing.forceMove(home)
			restored++
	trashed.Cut()
	return restored

/datum/buildmode
	/// Undo steps, newest last.
	var/list/undo_stack = list()
	/// The step being recorded while an action runs.
	var/datum/buildmode_undo/recording

/// Starts recording an action. Every placement, turf change and deletion until end_undo() joins it.
/datum/buildmode/proc/begin_undo(label)
	recording = new /datum/buildmode_undo(label)

/datum/buildmode/proc/end_undo()
	var/datum/buildmode_undo/step = recording
	recording = null
	if(!step || step.is_empty())
		return
	undo_stack += step
	while(length(undo_stack) > BM_UNDO_STEPS)
		var/datum/buildmode_undo/oldest = undo_stack[1]
		undo_stack.Cut(1, 2)
		oldest.expire()
	item_browser?.send_selection()

/datum/buildmode/proc/undo_note_created(atom/movable/thing)
	recording?.created += WEAKREF(thing)

/datum/buildmode/proc/undo_note_turf(turf/target)
	recording?.turf_changes += list(list(target, target.type))

/// Removes thing in an undoable way when a step is recording, deletes it otherwise.
/datum/buildmode/proc/undoable_delete(atom/movable/thing)
	if(!recording || ismob(thing))
		qdel(thing)
		return
	if(length(recording.trashed) >= BM_UNDO_TRASH_LIMIT)
		recording.partial = TRUE
		qdel(thing)
		return
	var/turf/home = get_turf(thing)
	thing.moveToNullspace()
	recording.trashed[thing] = home

/datum/buildmode/proc/undo_last()
	if(!length(undo_stack))
		item_browser?.set_status("Nothing to undo.")
		return FALSE
	var/datum/buildmode_undo/step = undo_stack[length(undo_stack)]
	undo_stack.len--
	var/restored = step.undo()
	log_admin("Build Mode: [key_name(holder)] undid \"[step.label]\" ([restored] changes).")
	item_browser?.set_status("Undone: [step.label].[step.partial ? " Only the first [BM_UNDO_TRASH_LIMIT] deleted objects could be restored." : ""]")
	return TRUE

/datum/buildmode/proc/undo_label()
	if(!length(undo_stack))
		return null
	var/datum/buildmode_undo/step = undo_stack[length(undo_stack)]
	return step.label

/datum/buildmode/proc/clear_undo()
	for(var/datum/buildmode_undo/step as anything in undo_stack)
		step.expire()
	undo_stack.Cut()
	recording?.expire()
	recording = null

#undef BM_UNDO_STEPS
#undef BM_UNDO_TRASH_LIMIT
