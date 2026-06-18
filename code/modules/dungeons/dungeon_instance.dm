/datum/pocket_dimension/dungeon
	/// TRUE once every guardian is dead
	var/cleared = FALSE
	/// Number of rooms cleared before this one in an infinite run; 0 for one-bite dungeons
	var/depth = 0
	/// How many combat rooms into the current stretch this room sits; 0 for break rooms
	var/stretch_position = 0
	/// DUNGEON_PATH_* of the gate that leads into this room; drives elite spawns
	var/incoming_path_type = DUNGEON_PATH_COMBAT
	/// REF text -> weakref of living guardians that must die for the room to clear
	var/list/guardian_refs = list()
	/// REF text -> TRUE for mobs that belong to the dungeon; qdel'd on collapse instead of ejected
	var/list/native_mob_refs = list()
	/// REF text -> TRUE for guardians flagged elite (bigger mote drop)
	var/list/elite_guardian_refs = list()
	/// REF text -> key_id for guardians that drop a key on death
	var/list/keyholder_drops = list()
	/// Owning infinite-dungeon run, if any
	var/datum/dungeon_run/owning_run
	/// Reward caches to unlock on clear
	var/list/obj/structure/dungeon_loot_cache/loot_caches = list()
	/// Gates created in this room by the run controller
	var/list/obj/structure/dungeon_gate/gates = list()
	/// list(list("turf" = T, "role" = DUNGEON_GATE_*)) collected from gate landmarks
	var/list/gate_landmark_info = list()
	/// Turfs where shrines should be built (break rooms)
	var/list/shrine_turfs = list()
	var/contents_setup_done = FALSE

/datum/pocket_dimension/dungeon/Destroy(force)
	var/obj/structure/dungeon_entrance/entrance = get_pocket_holder()
	owning_run = null
	guardian_refs = null
	native_mob_refs = null
	elite_guardian_refs = null
	keyholder_drops = null
	loot_caches = null
	QDEL_LIST(gates)
	gate_landmark_info = null
	shrine_turfs = null
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
	var/list/forced_elites = list()
	var/list/shrine_landmark_turfs = list()

	for(var/turf/current_turf as anything in affected_turfs)
		for(var/obj/effect/landmark/dungeon/guardian/guardian_marker in current_turf)
			var/mob/living/spawned
			if(istype(guardian_marker, /obj/effect/landmark/dungeon/guardian/boss))
				spawned = spawn_floor_boss(guardian_marker, current_turf)
			else
				spawned = guardian_marker.spawn_guardian(current_turf)
			if(spawned)
				mobs_to_register += spawned
				if(guardian_marker.force_elite)
					forced_elites[spawned] = TRUE
				if(istype(guardian_marker, /obj/effect/landmark/dungeon/guardian/keyholder))
					var/obj/effect/landmark/dungeon/guardian/keyholder/kh = guardian_marker
					keyholder_drops["[REF(spawned)]"] = kh.key_id
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
			gate_landmark_info += list(list("turf" = current_turf, "role" = gate_marker.gate_role, "path" = gate_marker.path_type, "requires_key" = gate_marker.requires_key, "key_id" = gate_marker.key_id))
			qdel(gate_marker)

		for(var/obj/effect/landmark/dungeon/shrine/shrine_marker in current_turf)
			shrine_landmark_turfs += current_turf
			qdel(shrine_marker)

		// Hostile mobs mapped directly into the .dmm count as guardians too.
		for(var/mob/living/simple_animal/hostile/mapped_mob in current_turf)
			mobs_to_register |= mapped_mob

	shrine_turfs = shrine_landmark_turfs

	for(var/mob/living/guardian as anything in mobs_to_register)
		var/is_elite = forced_elites[guardian] || (incoming_path_type == DUNGEON_PATH_ELITE)
		register_guardian(guardian, is_elite)

	if(!length(guardian_refs))
		on_cleared(silent = TRUE)

/datum/pocket_dimension/dungeon/proc/spawn_floor_boss(obj/effect/landmark/dungeon/guardian/boss/boss_marker, turf/spawn_turf)
	var/boss_type
	if(boss_marker.use_floor_boss_pool && owning_run?.floor_config && length(owning_run.floor_config.boss_pool))
		boss_type = pickweight(owning_run.floor_config.boss_pool.Copy())
	else if(length(boss_marker.mob_pool))
		boss_type = pickweight(boss_marker.mob_pool.Copy())
	if(!ispath(boss_type, /mob/living))
		return null
	var/mob/living/simple_animal/hostile/boss/dungeon/boss = new boss_type(spawn_turf)
	if(istype(boss) && owning_run)
		scale_dungeon_boss(boss, owning_run.floor)
	return boss

/datum/pocket_dimension/dungeon/proc/register_guardian(mob/living/guardian, elite = FALSE)
	if(QDELETED(guardian) || guardian.stat == DEAD || guardian.mind || guardian.client)
		return
	native_mob_refs["[REF(guardian)]"] = TRUE
	guardian_refs["[REF(guardian)]"] = WEAKREF(guardian)
	if(depth > 0 || elite)
		SSmobs.enhance_mob_elite(guardian, depth, elite ? 2 : 0)
	if(elite)
		elite_guardian_refs["[REF(guardian)]"] = TRUE
		guardian.add_atom_colour("#ffcc33", TEMPORARY_COLOUR_PRIORITY)
		guardian.name = "Champion [guardian.name]"
	// Party scaling: a bigger present party makes guardians tougher.
	var/party_size = owning_run ? max(1, length(owning_run.present_ckeys)) : 1
	if(party_size > 1 && istype(guardian, /mob/living/simple_animal))
		var/party_factor = 1 + min(party_size - 1, 4) * 0.4 // +40% hp per extra member, capped at 5
		guardian.maxHealth = round(guardian.maxHealth * party_factor)
		guardian.health = guardian.maxHealth
	RegisterSignals(guardian, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING), PROC_REF(on_guardian_death))

/datum/pocket_dimension/dungeon/proc/on_guardian_death(mob/living/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
	var/source_ref = "[REF(source)]"
	if(keyholder_drops[source_ref])
		var/turf/drop_turf = get_turf(source)
		if(drop_turf)
			var/obj/item/dungeon_key/key = new(drop_turf)
			key.key_id = keyholder_drops[source_ref]
			native_movables[key] = TRUE
		keyholder_drops -= source_ref
	if(owning_run)
		var/floor_for_drops = owning_run.floor
		var/drop = DUNGEON_MOTE_GUARDIAN_BASE + (floor_for_drops - 1) * DUNGEON_MOTE_FLOOR_BONUS
		if(istype(source, /mob/living/simple_animal/hostile/boss/dungeon))
			var/mob/living/simple_animal/hostile/boss/dungeon/boss = source
			drop = boss.mote_bounty + (floor_for_drops - 1) * DUNGEON_MOTE_FLOOR_BONUS * 5
		else if(elite_guardian_refs[source_ref])
			drop *= DUNGEON_MOTE_ELITE_MULT
		owning_run.award_motes(drop, source)
	elite_guardian_refs -= source_ref
	guardian_refs -= source_ref
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
	if(owning_run && isliving(user))
		owning_run.strip_boons_from(user)
	. = ..()
	if(. && owning_run)
		owning_run.note_possible_run_end()

/datum/pocket_dimension/dungeon/process_pocket()
	owning_run?.check_abandonment()
	return ..()
