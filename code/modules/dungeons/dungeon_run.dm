/datum/dungeon_run
	/// Entrance that owns this run
	var/datum/weakref/entrance_ref
	/// Total combat rooms cleared this run; drives mob/loot scaling
	var/depth = 0
	/// Combat rooms between break rooms
	var/stretch_length = DUNGEON_RUN_STRETCH_LENGTH
	/// Optional DUNGEON_THEME_* lock from the entrance
	var/theme
	/// Current floor (1-based); rises on boss/descent
	var/floor = 1
	/// Active floor config (themes, tier, stretch length, boss pool)
	var/datum/dungeon_floor_config/floor_config
	/// The party this run belongs to (the roster). May be null for a lone delver.
	var/datum/weakref/party_ref
	/// ckeys of members physically inside the run right now
	var/list/present_ckeys = list()
	/// weakrefs of outsiders waiting at the entrance to join at the next rest area
	var/list/waiting_petitioners = list()
	/// Shared in-run currency pool
	var/motes = 0
	/// Active /datum/dungeon_boon instances, applied to all roster members
	var/list/active_boons = list()
	/// Multiplier on mote drops from boons like Greed
	var/mote_multiplier = 1
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
	/// Becomes TRUE once the party progresses past the starting break room
	var/run_was_meaningful = FALSE
	/// Snapshot of the founding player's purchased unlock ids (read on start())
	var/list/run_unlocks = list()

GLOBAL_LIST_EMPTY(active_dungeon_runs)

/proc/get_active_dungeon_runs()
	return GLOB.active_dungeon_runs

/datum/dungeon_run/New(obj/structure/dungeon_entrance/entrance, theme = null)
	..()
	entrance_ref = WEAKREF(entrance)
	src.theme = theme
	last_seen_occupied = world.time
	GLOB.active_dungeon_runs += src

/datum/dungeon_run/Destroy(force)
	ending = TRUE
	GLOB.active_dungeon_runs -= src
	var/obj/structure/dungeon_entrance/entrance = get_entrance()
	var/atom/eject_target = entrance ? get_turf(entrance) : null
	var/list/doomed = get_all_rooms()
	current_break_room = null
	stretch_rooms = null
	// Strip run boons from everyone still inside (sandbox guarantee).
	for(var/datum/pocket_dimension/dungeon/room as anything in doomed)
		if(QDELETED(room))
			continue
		for(var/mob/living/occupant as anything in room.get_occupants())
			strip_boons_from(occupant)
	// Bank a share of unspent motes as echoes for present clients on a real run.
	if(run_was_meaningful && motes > 0)
		var/list/mob/banking_clients = list()
		for(var/datum/pocket_dimension/dungeon/room as anything in doomed)
			if(QDELETED(room))
				continue
			for(var/mob/occupant as anything in room.get_occupants())
				if(occupant.client && occupant.ckey)
					banking_clients += occupant
		if(length(banking_clients))
			var/share = round((motes * DUNGEON_ECHO_CONVERSION) / length(banking_clients))
			for(var/mob/banker as anything in banking_clients)
				var/datum/dungeon_progress/progress = get_dungeon_progress(banker.ckey)
				progress?.add_echoes(share)
				progress?.record_run_complete(floor, share)
				to_chat(banker, span_info("<b>Dungeon run complete.</b> Reached floor [floor]. Banked [share] echoes."))
		motes = 0
	for(var/datum/pocket_dimension/dungeon/room as anything in doomed)
		if(QDELETED(room))
			continue
		room.owning_run = null
		SSpocket_dimensions.delete_instance(room, "The dungeon convulses and spits everything back out!", eject_target)
	QDEL_LIST(active_boons)
	active_boons = null
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

/datum/dungeon_run/proc/seed_from_progress(datum/dungeon_progress/progress)
	if(!progress)
		return
	run_unlocks = progress.purchased_unlocks?.Copy() || list()

/datum/dungeon_run/proc/start()
	floor = 1
	floor_config = get_dungeon_floor_config(floor)
	stretch_length = floor_config.stretch_length
	if(run_unlocks["deep_start"])
		floor = 2
		floor_config = get_dungeon_floor_config(floor)
		stretch_length = floor_config.stretch_length
	if(run_unlocks["starting_motes"])
		motes += 50
	var/datum/map_template/pocket/dungeon/break_template = pick_dungeon_template(DUNGEON_ROOM_BREAK, pick_floor_theme())
	if(!break_template)
		return FALSE
	current_break_room = create_room_instance(break_template, 0)
	if(!current_break_room)
		return FALSE
	build_room_gates(current_break_room, null)
	build_room_shrines(current_break_room)
	if(run_unlocks["start_boon"])
		var/list/datum/dungeon_boon/choices = get_dungeon_boon_choices(src, 1)
		if(length(choices))
			add_boon(choices[1])
	return TRUE

/datum/dungeon_run/proc/pick_floor_theme()
	if(floor_config && length(floor_config.themes))
		return pick(floor_config.themes)
	return theme

/datum/dungeon_run/proc/award_motes(amount, atom/source)
	amount = round(amount * mote_multiplier)
	if(amount <= 0)
		return
	motes += amount
	if(source)
		var/turf/source_turf = get_turf(source)
		if(source_turf)
			source_turf.visible_message(span_nicegreen("[amount] motes of dungeon-light scatter loose!"))
	for(var/datum/pocket_dimension/dungeon/room as anything in get_all_rooms())
		for(var/mob/occupant as anything in room.get_occupants())
			if(occupant.client)
				to_chat(occupant, span_small("Motes: [motes] (+[amount])"))

/datum/dungeon_run/proc/spend_motes(amount)
	if(amount <= 0 || motes < amount)
		return FALSE
	motes -= amount
	return TRUE

/datum/dungeon_run/proc/add_boon(datum/dungeon_boon/boon)
	if(!istype(boon))
		return
	active_boons += boon
	for(var/datum/pocket_dimension/dungeon/room as anything in get_all_rooms())
		for(var/mob/living/occupant as anything in room.get_occupants())
			if(occupant.client || occupant.mind)
				boon.apply(src, occupant)

/datum/dungeon_run/proc/apply_boons_to(mob/living/target)
	if(!istype(target))
		return
	for(var/datum/dungeon_boon/boon as anything in active_boons)
		boon.apply(src, target)

/datum/dungeon_run/proc/strip_boons_from(mob/living/target)
	if(!istype(target))
		return
	for(var/datum/dungeon_boon/boon as anything in active_boons)
		boon.remove(src, target)

/// Crystallizes a user's run motes into persistent echoes at a shrine.
/datum/dungeon_run/proc/bank_motes_now(mob/user)
	if(!istype(user) || !user.ckey)
		return
	if(motes <= 0)
		to_chat(user, span_warning("There are no motes to bank."))
		return
	var/converted = round(motes * DUNGEON_ECHO_CONVERSION)
	motes = 0
	if(converted <= 0)
		to_chat(user, span_warning("Too few motes to crystallize into an echo."))
		return
	var/datum/dungeon_progress/progress = get_dungeon_progress(user.ckey)
	if(!progress)
		return
	progress.add_echoes(converted)
	to_chat(user, span_nicegreen("You crystallize [converted] echoes from the run's light."))

/// Creates a dungeon room instance with depth/run wired up BEFORE activate(),
/// which get_or_create_instance cannot do; mirrors its registration steps.
/datum/dungeon_run/proc/create_room_instance(datum/map_template/pocket/dungeon/room_template, room_depth, incoming_path = DUNGEON_PATH_COMBAT)
	var/instance_key = "dungeon_run::[REF(src)]::room[++room_serial]"
	var/datum/pocket_dimension/dungeon/room = new(room_template, instance_key, SSpocket_dimensions.next_instance_id++, POCKET_LIFECYCLE_COLLAPSE, DUNGEON_DEFAULT_IDLE_TIMEOUT, get_entrance())
	room.depth = room_depth
	room.owning_run = src
	// Set before activate(): setup_dungeon_contents spawns guardians during
	// activation and reads incoming_path_type to decide elite spawns.
	room.incoming_path_type = incoming_path
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
		gate.path_type = info["path"] || DUNGEON_PATH_COMBAT
		gate.requires_key = info["requires_key"]
		gate.key_id = info["key_id"] || "default"
		gate.owning_run = src
		gate.source_room = room
		room.gates += gate
		// Created after layout caching - mark native so collapse never ejects it.
		room.native_movables[gate] = TRUE
		if(gate.gate_role == DUNGEON_GATE_FORWARD)
			gate.sealed = !room.cleared
			gate.pre_rolled_template = roll_path_room_template(room, gate.path_type)
		else
			gate.sealed = FALSE
			gate.destination_room = predecessor
	room.gate_landmark_info.Cut()

/// Builds shrines on the turfs recorded from a room's shrine landmarks.
/datum/dungeon_run/proc/build_room_shrines(datum/pocket_dimension/dungeon/room)
	for(var/turf/shrine_turf as anything in room.shrine_turfs)
		if(QDELETED(shrine_turf) || !room.contains_turf(shrine_turf))
			continue
		var/obj/structure/dungeon_shrine/shrine = new(shrine_turf)
		shrine.owning_run = src
		room.native_movables[shrine] = TRUE
	room.shrine_turfs.Cut()

/// Picks a forward room template biased by the gate's path type. Falls back to
/// the generic stretch roll (which handles boss/break at stretch end).
/datum/dungeon_run/proc/roll_path_room_template(datum/pocket_dimension/dungeon/room, path_type)
	var/next_position = room.stretch_position + 1
	if(next_position > stretch_length)
		return roll_next_room_template(room)
	var/theme_to_use = pick_floor_theme()
	var/target_tier = get_target_tier()
	switch(path_type)
		if(DUNGEON_PATH_TREASURE, DUNGEON_PATH_SHORTCUT)
			return pick_dungeon_template(DUNGEON_ROOM_COMBAT, theme_to_use, 1, target_tier)
		if(DUNGEON_PATH_HAZARD, DUNGEON_PATH_ELITE)
			return pick_dungeon_template(DUNGEON_ROOM_COMBAT, theme_to_use, target_tier, target_tier + 2)
	return pick_dungeon_template(DUNGEON_ROOM_COMBAT, theme_to_use, max(1, target_tier - 1), target_tier + 1)

/// Picks the template behind a forward gate of the given room: a break room
/// if the stretch would be complete, otherwise a combat room in the depth's tier band.
/datum/dungeon_run/proc/roll_next_room_template(datum/pocket_dimension/dungeon/room)
	var/next_position = room.stretch_position + 1
	var/theme_to_use = pick_floor_theme()
	if(next_position > stretch_length)
		// End of stretch: a boss caps the floor's final stretch, else a break room.
		if(is_final_stretch())
			var/datum/map_template/pocket/dungeon/boss_room = pick_dungeon_template(DUNGEON_ROOM_BOSS, theme_to_use)
			if(boss_room)
				return boss_room
		return pick_dungeon_template(DUNGEON_ROOM_BREAK, theme_to_use)
	var/target_tier = get_target_tier()
	return pick_dungeon_template(DUNGEON_ROOM_COMBAT, theme_to_use, max(1, target_tier - 1), target_tier + 1)

/// Whether the current stretch should end in a boss. For the starter build every
/// floor's stretch ends in a boss; tune later (e.g. boss only on the last stretch).
/datum/dungeon_run/proc/is_final_stretch()
	return TRUE

/datum/dungeon_run/proc/get_target_tier()
	var/floor_tier = get_dungeon_floor_tier(floor)
	// small in-floor nudge as depth rises within the floor
	return clamp(floor_tier + round(stretch_position_estimate() / 3), 1, 10)

/// Rough progress within the current stretch, for the in-floor tier nudge.
/datum/dungeon_run/proc/stretch_position_estimate()
	var/highest = 0
	for(var/datum/pocket_dimension/dungeon/room as anything in stretch_rooms)
		if(QDELETED(room))
			continue
		highest = max(highest, room.stretch_position)
	return highest

/// Called by a forward gate the first time it is used.
/datum/dungeon_run/proc/instantiate_room_for_gate(obj/structure/dungeon_gate/gate)
	if(ending || !gate?.pre_rolled_template || QDELETED(gate.source_room))
		return null
	var/datum/pocket_dimension/dungeon/room = create_room_instance(gate.pre_rolled_template, depth + 1, gate.path_type)
	if(!room)
		return null
	var/new_room_kind = gate.pre_rolled_template.room_kind
	if(new_room_kind == DUNGEON_ROOM_BREAK || new_room_kind == DUNGEON_ROOM_DESCENT)
		room.stretch_position = 0
	else
		room.stretch_position = gate.source_room.stretch_position + 1
		stretch_rooms += room
	build_room_gates(room, gate.source_room)
	build_room_shrines(room)
	return room

/// Called by the dungeon instance when its last guardian dies.
/datum/dungeon_run/proc/on_room_cleared(datum/pocket_dimension/dungeon/room)
	if(ending)
		return
	var/datum/map_template/pocket/dungeon/dungeon_template = room.get_dungeon_template()
	if(dungeon_template?.room_kind == DUNGEON_ROOM_COMBAT)
		depth++
	var/is_boss_room = dungeon_template?.room_kind == DUNGEON_ROOM_BOSS
	for(var/obj/structure/dungeon_gate/gate as anything in room.gates)
		if(QDELETED(gate))
			continue
		if(gate.gate_role != DUNGEON_GATE_FORWARD)
			continue
		gate.sealed = FALSE
		if(is_boss_room)
			// Boss death turns the way onward into a descent to the next floor.
			gate.gate_role = DUNGEON_GATE_DESCENT
			gate.pre_rolled_template = pick_dungeon_template(DUNGEON_ROOM_DESCENT, pick_floor_theme()) || pick_dungeon_template(DUNGEON_ROOM_BREAK, pick_floor_theme())
	if(is_boss_room)
		on_boss_killed(room)

/datum/dungeon_run/proc/on_boss_killed(datum/pocket_dimension/dungeon/room)
	for(var/mob/occupant as anything in room.get_occupants())
		to_chat(occupant, span_nicegreen("The floor's guardian falls! A way down has opened."))
		if(occupant.client && occupant.ckey)
			var/datum/dungeon_progress/progress = get_dungeon_progress(occupant.ckey)
			progress?.record_boss_kill()
			progress?.record_floor(floor)

/// Called by gates after moving someone; advances the run when a fresh
/// break room is reached, despawning the finished stretch behind the party.
/datum/dungeon_run/proc/on_room_entered(datum/pocket_dimension/dungeon/room, mob/living/user)
	if(ending)
		return
	last_seen_occupied = world.time
	mark_present(user)
	apply_boons_to(user)
	var/datum/map_template/pocket/dungeon/dungeon_template = room.get_dungeon_template()
	if(!dungeon_template)
		return
	switch(dungeon_template.room_kind)
		if(DUNGEON_ROOM_BREAK)
			if(room != current_break_room)
				advance_to_break_room(room)
				INVOKE_ASYNC(src, PROC_REF(offer_break_room_boon), user)
		if(DUNGEON_ROOM_DESCENT)
			if(room != current_break_room)
				advance_floor(room)

/datum/dungeon_run/proc/advance_floor(datum/pocket_dimension/dungeon/new_floor_room)
	run_was_meaningful = TRUE
	floor++
	floor_config = get_dungeon_floor_config(floor)
	stretch_length = floor_config.stretch_length
	// Reaching a descent room is also a break-room moment: despawn the old floor.
	advance_to_break_room(new_floor_room)
	for(var/mob/occupant as anything in new_floor_room.get_occupants())
		to_chat(occupant, span_notice("<b>[floor_config.floor_name]</b> — I have descended to floor [floor]."))

/datum/dungeon_run/proc/advance_to_break_room(datum/pocket_dimension/dungeon/new_break_room)
	run_was_meaningful = TRUE
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

	// Reaching a fresh rest area lets waiting outsiders petition to join.
	notify_waiting_petitioners()

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
