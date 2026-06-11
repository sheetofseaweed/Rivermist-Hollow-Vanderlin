/datum/pocket_dimension/dungeon
	/// TRUE once every guardian is dead
	var/cleared = FALSE
	/// Number of rooms cleared before this one in an infinite run; 0 for one-bite dungeons
	var/depth = 0
	/// How many combat rooms into the current stretch this room sits; 0 for break rooms
	var/stretch_position = 0
	/// REF text -> weakref of living guardians that must die for the room to clear
	var/list/guardian_refs = list()
	/// REF text -> TRUE for mobs that belong to the dungeon; qdel'd on collapse instead of ejected
	var/list/native_mob_refs = list()
	/// Owning infinite-dungeon run, if any
	var/datum/dungeon_run/owning_run
	/// Reward caches to unlock on clear
	var/list/obj/structure/dungeon_loot_cache/loot_caches = list()
	/// Gates created in this room by the run controller
	var/list/obj/structure/dungeon_gate/gates = list()
	/// list(list("turf" = T, "role" = DUNGEON_GATE_*)) collected from gate landmarks
	var/list/gate_landmark_info = list()
	var/contents_setup_done = FALSE

/datum/pocket_dimension/dungeon/Destroy(force)
	var/obj/structure/dungeon_entrance/entrance = get_pocket_holder()
	owning_run = null
	guardian_refs = null
	native_mob_refs = null
	loot_caches = null
	QDEL_LIST(gates)
	gate_landmark_info = null
	. = ..()
	if(istype(entrance))
		entrance.on_dungeon_collapsed(src)

/datum/pocket_dimension/dungeon/proc/get_dungeon_template()
	var/datum/map_template/pocket/dungeon/dungeon_template = template
	return istype(dungeon_template) ? dungeon_template : null

/datum/pocket_dimension/dungeon/activate()
	. = ..()
	if(. && !contents_setup_done)
		contents_setup_done = TRUE
		setup_dungeon_contents()

// Combat rooms in a run must not get the automatic fallback exit seam -
// the only way out of a stretch is forward or back through gates.
/datum/pocket_dimension/dungeon/create_exit_object(obj/effect/landmark/pocket_dimension/exit/exit_marker, turf/current_turf)
	var/datum/map_template/pocket/dungeon/dungeon_template = get_dungeon_template()
	if(!exit_marker && dungeon_template?.room_kind == DUNGEON_ROOM_COMBAT)
		return null
	return ..()

/datum/pocket_dimension/dungeon/proc/setup_dungeon_contents()
	var/list/mobs_to_register = list()

	for(var/turf/current_turf as anything in affected_turfs)
		for(var/obj/effect/landmark/dungeon/guardian/guardian_marker in current_turf)
			var/mob/living/spawned = guardian_marker.spawn_guardian(current_turf)
			if(spawned)
				mobs_to_register += spawned
			qdel(guardian_marker)

		for(var/obj/effect/landmark/dungeon/loot/loot_marker in current_turf)
			var/obj/structure/dungeon_loot_cache/cache = loot_marker.create_cache(current_turf, src)
			if(cache)
				loot_caches += cache
				// Created after layout caching, so mark it native by hand or it
				// would be ejected outside as a "foreign movable" on collapse.
				native_movables[cache] = TRUE
			qdel(loot_marker)

		for(var/obj/effect/landmark/dungeon/gate/gate_marker in current_turf)
			gate_landmark_info += list(list("turf" = current_turf, "role" = gate_marker.gate_role))
			qdel(gate_marker)

		// Hostile mobs mapped directly into the .dmm count as guardians too.
		for(var/mob/living/simple_animal/hostile/mapped_mob in current_turf)
			mobs_to_register |= mapped_mob

	for(var/mob/living/guardian as anything in mobs_to_register)
		register_guardian(guardian)

	if(!length(guardian_refs))
		on_cleared(silent = TRUE)

/datum/pocket_dimension/dungeon/proc/register_guardian(mob/living/guardian)
	if(QDELETED(guardian) || guardian.stat == DEAD || guardian.mind || guardian.client)
		return
	native_mob_refs["[REF(guardian)]"] = TRUE
	guardian_refs["[REF(guardian)]"] = WEAKREF(guardian)
	if(depth > 0)
		SSmobs.enhance_mob(guardian, depth)
	RegisterSignals(guardian, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING), PROC_REF(on_guardian_death))

/datum/pocket_dimension/dungeon/proc/on_guardian_death(mob/living/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
	guardian_refs -= "[REF(source)]"
	if(!cleared && !length(guardian_refs))
		on_cleared()

/datum/pocket_dimension/dungeon/proc/on_cleared(silent = FALSE)
	if(cleared)
		return
	cleared = TRUE
	idle_timeout = DUNGEON_CLEARED_IDLE_TIMEOUT
	for(var/obj/structure/dungeon_loot_cache/cache as anything in loot_caches)
		if(!QDELETED(cache))
			cache.unseal()
	if(!silent)
		for(var/mob/occupant as anything in get_occupants())
			to_chat(occupant, span_notice("The hostile presence fades. The walls give a long, grinding groan - this place will not hold its shape forever."))
	owning_run?.on_room_cleared(src)

/datum/pocket_dimension/dungeon/proc/is_native_dungeon_mob(mob/subject)
	if(subject.mind || subject.client)
		return FALSE
	return !!native_mob_refs?["[REF(subject)]"]

// Native dungeon mobs die with the dungeon instead of being dumped outside.
/datum/pocket_dimension/dungeon/eject_occupants(message = null, atom/override_destination = null)
	for(var/mob/occupant as anything in get_occupants())
		if(QDELETED(occupant))
			continue
		if(is_native_dungeon_mob(occupant))
			qdel(occupant)
	return ..()

// Only break rooms (and standalone one-bite dungeons) allow stepping back out.
/datum/pocket_dimension/dungeon/can_exit_mob(mob/user, obj/structure/pocket_dimension_exit/exit_object, show_feedback = TRUE)
	var/datum/map_template/pocket/dungeon/dungeon_template = get_dungeon_template()
	if(owning_run && dungeon_template?.room_kind != DUNGEON_ROOM_BREAK)
		if(show_feedback)
			to_chat(user, span_warning("The dungeon's grip is too strong here. I can only leave from a place of respite."))
		return FALSE
	return TRUE

/datum/pocket_dimension/dungeon/exit_mob(mob/user)
	. = ..()
	if(. && owning_run)
		owning_run.note_possible_run_end()

/datum/pocket_dimension/dungeon/process_pocket()
	owning_run?.check_abandonment()
	return ..()
