/datum/dungeon_run
	/// Entrance that owns this run
	var/datum/weakref/entrance_ref
	/// Total combat rooms cleared this run; drives mob/loot scaling
	var/depth = 0
	/// Combat rooms between break rooms
	var/stretch_length = DUNGEON_RUN_STRETCH_LENGTH
	/// Optional DUNGEON_THEME_* lock from the entrance
	var/theme
	/// The break room the party last secured; the only place with an overworld exit
	var/datum/pocket_dimension/dungeon/current_break_room
	/// Combat rooms instantiated since the last break room
	var/list/stretch_rooms = list()
	/// Monotonic counter for unique instance keys
	var/room_serial = 0
	/// world.time we last saw a client-bearing occupant anywhere in the run
	var/last_seen_occupied = 0
	/// Reentrancy guard for teardown
	var/ending = FALSE

/datum/dungeon_run/New(obj/structure/dungeon_entrance/entrance, theme = null)
	..()
	entrance_ref = WEAKREF(entrance)
	src.theme = theme
	last_seen_occupied = world.time

/datum/dungeon_run/Destroy(force)
	ending = TRUE
	var/obj/structure/dungeon_entrance/entrance = get_entrance()
	var/atom/eject_target = entrance ? get_turf(entrance) : null
	var/list/doomed = get_all_rooms()
	current_break_room = null
	stretch_rooms = null
	for(var/datum/pocket_dimension/dungeon/room as anything in doomed)
		if(QDELETED(room))
			continue
		room.owning_run = null
		SSpocket_dimensions.delete_instance(room, "The dungeon convulses and spits everything back out!", eject_target)
	entrance?.on_run_ended(src)
	entrance_ref = null
	return ..()

/datum/dungeon_run/proc/get_entrance()
	var/obj/structure/dungeon_entrance/entrance = entrance_ref?.resolve()
	if(entrance && !QDELETED(entrance))
		return entrance
	return null

/datum/dungeon_run/proc/get_all_rooms()
	var/list/rooms = list()
	if(current_break_room && !QDELETED(current_break_room))
		rooms += current_break_room
	for(var/datum/pocket_dimension/dungeon/room as anything in stretch_rooms)
		if(!QDELETED(room))
			rooms |= room
	return rooms

/datum/dungeon_run/proc/start()
	var/datum/map_template/pocket/dungeon/break_template = pick_dungeon_template(DUNGEON_ROOM_BREAK, theme)
	if(!break_template)
		return FALSE
	current_break_room = create_room_instance(break_template, 0)
	if(!current_break_room)
		return FALSE
	build_room_gates(current_break_room, null)
	return TRUE

/// Creates a dungeon room instance with depth/run wired up BEFORE activate(),
/// which get_or_create_instance cannot do; mirrors its registration steps.
/datum/dungeon_run/proc/create_room_instance(datum/map_template/pocket/dungeon/room_template, room_depth)
	var/instance_key = "dungeon_run::[REF(src)]::room[++room_serial]"
	var/datum/pocket_dimension/dungeon/room = new(room_template, instance_key, SSpocket_dimensions.next_instance_id++, POCKET_LIFECYCLE_COLLAPSE, DUNGEON_DEFAULT_IDLE_TIMEOUT, get_entrance())
	room.depth = room_depth
	room.owning_run = src
	if(!room.activate())
		qdel(room)
		return null
	SSpocket_dimensions.register_instance(room)
	return room

/// Builds gates on the turfs recorded from the room's gate landmarks.
/// predecessor is the room the party came from; back gates lead there.
/datum/dungeon_run/proc/build_room_gates(datum/pocket_dimension/dungeon/room, datum/pocket_dimension/dungeon/predecessor)
	for(var/list/info as anything in room.gate_landmark_info)
		var/turf/gate_turf = info["turf"]
		if(QDELETED(gate_turf) || !room.contains_turf(gate_turf))
			continue
		var/obj/structure/dungeon_gate/gate = new(gate_turf)
		gate.gate_role = info["role"]
		gate.owning_run = src
		gate.source_room = room
		room.gates += gate
		// Created after layout caching - mark native so collapse never ejects it.
		room.native_movables[gate] = TRUE
		if(gate.gate_role == DUNGEON_GATE_FORWARD)
			gate.sealed = !room.cleared
			gate.pre_rolled_template = roll_next_room_template(room)
		else
			gate.sealed = FALSE
			gate.destination_room = predecessor
	room.gate_landmark_info.Cut()

/// Picks the template behind a forward gate of the given room: a break room
/// if the stretch would be complete, otherwise a combat room in the depth's tier band.
/datum/dungeon_run/proc/roll_next_room_template(datum/pocket_dimension/dungeon/room)
	var/next_position = room.stretch_position + 1
	if(next_position > stretch_length)
		return pick_dungeon_template(DUNGEON_ROOM_BREAK, theme)
	var/target_tier = get_target_tier()
	return pick_dungeon_template(DUNGEON_ROOM_COMBAT, theme, max(1, target_tier - 1), target_tier + 1)

/datum/dungeon_run/proc/get_target_tier()
	return clamp(1 + round(depth / 3), 1, 5)

/// Called by a forward gate the first time it is used.
/datum/dungeon_run/proc/instantiate_room_for_gate(obj/structure/dungeon_gate/gate)
	if(ending || !gate?.pre_rolled_template || QDELETED(gate.source_room))
		return null
	var/datum/pocket_dimension/dungeon/room = create_room_instance(gate.pre_rolled_template, depth + 1)
	if(!room)
		return null
	if(gate.pre_rolled_template.room_kind == DUNGEON_ROOM_BREAK)
		room.stretch_position = 0
	else
		room.stretch_position = gate.source_room.stretch_position + 1
		stretch_rooms += room
	build_room_gates(room, gate.source_room)
	return room

/// Called by the dungeon instance when its last guardian dies.
/datum/dungeon_run/proc/on_room_cleared(datum/pocket_dimension/dungeon/room)
	if(ending)
		return
	var/datum/map_template/pocket/dungeon/dungeon_template = room.get_dungeon_template()
	if(dungeon_template?.room_kind == DUNGEON_ROOM_COMBAT)
		depth++
	for(var/obj/structure/dungeon_gate/gate as anything in room.gates)
		if(QDELETED(gate))
			continue
		if(gate.gate_role == DUNGEON_GATE_FORWARD)
			gate.sealed = FALSE

/// Called by gates after moving someone; advances the run when a fresh
/// break room is reached, despawning the finished stretch behind the party.
/datum/dungeon_run/proc/on_room_entered(datum/pocket_dimension/dungeon/room, mob/living/user)
	if(ending)
		return
	last_seen_occupied = world.time
	var/datum/map_template/pocket/dungeon/dungeon_template = room.get_dungeon_template()
	if(dungeon_template?.room_kind == DUNGEON_ROOM_BREAK && room != current_break_room)
		advance_to_break_room(room)

/datum/dungeon_run/proc/advance_to_break_room(datum/pocket_dimension/dungeon/new_break_room)
	var/list/doomed = list()
	if(current_break_room && current_break_room != new_break_room && !QDELETED(current_break_room))
		doomed += current_break_room
	for(var/datum/pocket_dimension/dungeon/room as anything in stretch_rooms)
		if(room != new_break_room && !QDELETED(room))
			doomed += room
	current_break_room = new_break_room
	stretch_rooms = list()

	var/turf/eject_target = new_break_room.get_entry_turf()
	for(var/datum/pocket_dimension/dungeon/room as anything in doomed)
		room.owning_run = null // no re-entrant run callbacks from the teardown
		SSpocket_dimensions.delete_instance(room, "The passages behind grind shut and crumble away!", eject_target)

/datum/dungeon_run/proc/has_client_occupants()
	for(var/datum/pocket_dimension/dungeon/room as anything in get_all_rooms())
		for(var/mob/occupant as anything in room.get_occupants())
			if(occupant.client)
				return TRUE
	return FALSE

/// Called when someone exits via a break room's overworld exit.
/datum/dungeon_run/proc/note_possible_run_end()
	if(ending)
		return
	if(!has_client_occupants())
		qdel(src)

/// Ticked from room process_pocket(); collapses an abandoned run.
/datum/dungeon_run/proc/check_abandonment()
	if(ending)
		return
	if(has_client_occupants())
		last_seen_occupied = world.time
		return
	if(world.time > last_seen_occupied + DUNGEON_RUN_ABANDON_TIMEOUT)
		qdel(src)
