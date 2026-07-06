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
	/// DUNGEON_JOIN_APPROVAL_* — how many present members must approve a petitioner
	var/join_approval_mode = DUNGEON_JOIN_APPROVAL_MODE
	/// Shared in-run currency pool
	var/motes = 0
	/// Active /datum/dungeon_boon instances, applied to all roster members
	var/list/active_boons = list()
	/// REF text -> TRUE for mobs currently carrying the run's boon stack.
	/// Guards against re-applying on every room entry (additive boons would
	/// stack) and against double-stripping (additive removes would drain).
	var/list/boon_carriers = list()
	/// Open /datum/dungeon_boon_offer sessions (unanswered pick windows)
	var/list/open_boon_offers = list()
	/// world.time of the last presence sweep (throttles validate_presence)
	var/last_presence_validation = 0
	/// Multiplier on mote drops from boons like Greed
	var/mote_multiplier = 1
	/// The stretch's shuffled door-reward deck (DUNGEON_REWARD_* strings)
	var/list/stretch_deck = list()
	/// Combat template ids used recently, excluded from rolls (anti-repeat)
	var/list/recent_template_ids = list()
	/// Break rooms reached on the current floor (drives is_final_stretch)
	var/stretches_completed_this_floor = 0
	/// Motes accumulated since the last buffered announce
	var/pending_mote_announce = 0
	/// Whether a mote announce flush is already scheduled
	var/mote_announce_scheduled = FALSE
	/// Patron typepaths of the three gods watching this run
	var/list/watching_god_types = list()
	/// ckeys already told which gods watch the delve
	var/list/gaze_announced_ckeys = list()
	/// Epic-rarity pity counter; rises per offer without an epic
	var/epic_pity = 0
	/// Bonus fraction on mote->echo conversion (Echo Affinity boon)
	var/echo_conversion_bonus = 0
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
	/// TRUE when the run ended in a full party wipe (skips mote banking)
	var/wiped = FALSE
	/// Armed wipe-grace timer id, null when the party stands
	var/wipe_timer
	/// Message rooms use when the run tears down (wipe uses a darker one)
	var/teardown_message = "The dungeon convulses and spits everything back out!"
	/// Becomes TRUE once the party progresses past the starting break room
	var/run_was_meaningful = FALSE
	/// Snapshot of the founding player's purchased unlock ids (read on start())
	var/list/run_unlocks = list()
	/// Heat dial ranks chosen at assembly (assoc dial id -> rank); immutable once the run exists
	var/list/heat_ranks = list()
	/// Cursed rooms still owed from dark bargains; each new combat room pays one down
	var/cursed_rooms_owed = 0
	/// Stretch position (1-based) of this stretch's special room, 0 = none
	var/special_room_position = 0
	/// DUNGEON_POP_* kind of the special room; null once built
	var/special_room_kind

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
	if(wipe_timer)
		deltimer(wipe_timer)
		wipe_timer = null
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
	// A full party wipe forfeits everything unbanked - that is the contract.
	if(run_was_meaningful && motes > 0 && !wiped)
		var/list/mob/banking_clients = list()
		for(var/datum/pocket_dimension/dungeon/room as anything in doomed)
			if(QDELETED(room))
				continue
			for(var/mob/occupant as anything in room.get_occupants())
				if(occupant.client && occupant.ckey)
					banking_clients += occupant
		if(length(banking_clients))
			var/share = round((motes * get_echo_conversion()) / length(banking_clients))
			for(var/mob/banker as anything in banking_clients)
				var/datum/dungeon_progress/progress = get_dungeon_progress(banker.ckey)
				progress?.add_echoes(share)
				progress?.record_run_complete(floor, share)
				grant_dungeon_milestones(banker, floor, FALSE)
				to_chat(banker, span_info("<b>Dungeon run complete.</b> Reached floor [floor]. Banked [share] echoes."))
		motes = 0
	for(var/datum/pocket_dimension/dungeon/room as anything in doomed)
		if(QDELETED(room))
			continue
		room.owning_run = null
		SSpocket_dimensions.delete_instance(room, teardown_message, eject_target)
	QDEL_LIST(open_boon_offers)
	QDEL_LIST(active_boons)
	active_boons = null
	boon_carriers = null
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
	stretch_length = floor_config.stretch_length + get_heat_rank(DUNGEON_HEAT_FORCED_MARCH)
	if(run_unlocks["deep_start"])
		floor = 2
		floor_config = get_dungeon_floor_config(floor)
		stretch_length = floor_config.stretch_length + get_heat_rank(DUNGEON_HEAT_FORCED_MARCH)
	if(run_unlocks["starting_motes"])
		motes += 50
	var/datum/map_template/pocket/dungeon/break_template = pick_dungeon_template(DUNGEON_ROOM_BREAK, pick_floor_theme())
	if(!break_template)
		return FALSE
	roll_run_watching_gods()
	build_stretch_deck()
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

/// Builds the stretch's door-reward deck: guaranteed boon + treasure, weighted
/// remainder, one shuffle. Gates draw from the top as rooms are built, so every
/// stretch always holds a boon and a treasure *somewhere*.
/datum/dungeon_run/proc/build_stretch_deck()
	stretch_deck = list()
	stretch_deck += DUNGEON_REWARD_BOON
	stretch_deck += prob(50) ? DUNGEON_REWARD_VAULT : DUNGEON_REWARD_LOOT
	var/expected = max(4, stretch_length * 2)
	var/list/remainder_weights = get_deck_remainder_weights()
	while(length(stretch_deck) < expected)
		stretch_deck += pickweight(remainder_weights.Copy())
	shuffle_inplace(stretch_deck)
	// One mid-stretch room may be special: never the first door, never the
	// stretch-capping one.
	special_room_position = 0
	special_room_kind = null
	if(stretch_length >= 3 && prob(DUNGEON_SPECIAL_ROOM_CHANCE))
		special_room_position = rand(2, stretch_length - 1)
		special_room_kind = pickweight(list(DUNGEON_POP_TRADER = 40, DUNGEON_POP_MYSTERY = 35, DUNGEON_POP_WAVES = 25))

/// Weighted remainder for deck fills; Sealed Mercy strips HEAL doors entirely.
/datum/dungeon_run/proc/get_deck_remainder_weights()
	var/list/weights = DUNGEON_DECK_REMAINDER_WEIGHTS
	if(get_heat_rank(DUNGEON_HEAT_SEALED_MERCY))
		weights -= DUNGEON_REWARD_HEAL
	return weights

/// Draws the next door reward; an exhausted deck re-rolls from the weighted
/// remainder (no more guarantees, no vaults).
/datum/dungeon_run/proc/draw_door_reward()
	if(length(stretch_deck))
		var/reward = stretch_deck[1]
		stretch_deck.Cut(1, 2)
		return reward
	var/list/remainder_weights = get_deck_remainder_weights()
	return pickweight(remainder_weights.Copy())

/// Rolls the three gods whose gaze follows this run. Worship in the descending
/// party weights the roll (see get_watching_god_weights).
/datum/dungeon_run/proc/roll_run_watching_gods()
	var/list/mob/living/members = list()
	var/datum/party/party = get_party()
	if(party)
		for(var/member_ckey in party.members)
			var/mob/living/member = get_mob_by_ckey(member_ckey)
			if(istype(member))
				members += member
	watching_god_types = list()
	for(var/datum/dungeon_god_profile/profile as anything in roll_watching_gods(members))
		watching_god_types += profile.patron_type

/datum/dungeon_run/proc/get_watching_god_names()
	var/list/names = list()
	for(var/god_type in watching_god_types)
		var/datum/patron/patron = GLOB.patron_list[god_type]
		if(patron?.name)
			names += patron.name
	return names

/datum/dungeon_run/proc/announce_gaze(mob/living/user)
	if(!user?.client || !user.ckey || !length(watching_god_types))
		return
	if(ckey(user.ckey) in gaze_announced_ckeys)
		return
	gaze_announced_ckeys += ckey(user.ckey)
	var/list/names = get_watching_god_names()
	if(length(names))
		to_chat(user, span_boldnotice("Three gazes settle upon the delve: [english_list(names)]."))

/// Rolls a boon rarity with an epic pity escalator.
/datum/dungeon_run/proc/roll_boon_rarity()
	if(prob(5 + epic_pity * 10))
		epic_pity = 0
		return DUNGEON_BOON_EPIC
	epic_pity++
	if(prob(30))
		return DUNGEON_BOON_RARE
	return DUNGEON_BOON_COMMON

/datum/dungeon_run/proc/get_rarity_magnitude(rarity)
	switch(rarity)
		if(DUNGEON_BOON_EPIC)
			return 2.25
		if(DUNGEON_BOON_RARE)
			return 1.5
	return 1

/// Remembers a combat template id and trims the memory ring.
/datum/dungeon_run/proc/remember_template(template_id)
	if(!template_id)
		return
	recent_template_ids -= template_id
	recent_template_ids += template_id
	if(length(recent_template_ids) > DUNGEON_RECENT_TEMPLATE_MEMORY)
		recent_template_ids.Cut(1, 2)

/datum/dungeon_run/proc/award_motes(amount, atom/source)
	amount = round(amount * mote_multiplier)
	if(amount <= 0)
		return
	motes += amount
	if(source)
		var/turf/source_turf = get_turf(source)
		if(source_turf)
			source_turf.visible_message(span_nicegreen("[amount] motes of dungeon-light scatter loose!"))
	// Buffered announce: one combined chat line per client after a burst,
	// instead of a line per kill (swarm rooms would flood chat otherwise).
	pending_mote_announce += amount
	if(!mote_announce_scheduled)
		mote_announce_scheduled = TRUE
		addtimer(CALLBACK(src, PROC_REF(flush_mote_announce)), 2 SECONDS)

/datum/dungeon_run/proc/flush_mote_announce()
	mote_announce_scheduled = FALSE
	if(ending || pending_mote_announce <= 0)
		pending_mote_announce = 0
		return
	var/gained = pending_mote_announce
	pending_mote_announce = 0
	for(var/datum/pocket_dimension/dungeon/room as anything in get_all_rooms())
		for(var/mob/occupant as anything in room.get_occupants())
			if(occupant.client)
				to_chat(occupant, span_small("Motes: [motes] (+[gained])"))

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
	var/carrier_key = "[REF(target)]"
	if(boon_carriers[carrier_key])
		return // already carrying the stack - never re-apply per room entry
	boon_carriers[carrier_key] = TRUE
	for(var/datum/dungeon_boon/boon as anything in active_boons)
		boon.apply(src, target)

/datum/dungeon_run/proc/strip_boons_from(mob/living/target)
	if(!istype(target))
		return
	var/carrier_key = "[REF(target)]"
	if(!boon_carriers[carrier_key])
		return // never applied (or already stripped) - don't drain twice
	boon_carriers -= carrier_key
	for(var/datum/dungeon_boon/boon as anything in active_boons)
		boon.remove(src, target)

/// Crystallizes a user's run motes into persistent echoes at a shrine.
/datum/dungeon_run/proc/bank_motes_now(mob/user)
	if(!istype(user) || !user.ckey)
		return
	if(motes <= 0)
		to_chat(user, span_warning("There are no motes to bank."))
		return
	var/converted = round(motes * get_echo_conversion())
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
/datum/dungeon_run/proc/create_room_instance(datum/map_template/pocket/dungeon/room_template, room_depth, incoming_path = DUNGEON_PATH_COMBAT, promised_reward = DUNGEON_REWARD_MOTES, population_mode = DUNGEON_POP_COMBAT)
	var/instance_key = "dungeon_run::[REF(src)]::room[++room_serial]"
	var/datum/pocket_dimension/dungeon/room = new(room_template, instance_key, SSpocket_dimensions.next_instance_id++, POCKET_LIFECYCLE_COLLAPSE, DUNGEON_DEFAULT_IDLE_TIMEOUT, get_entrance())
	room.depth = room_depth
	room.owning_run = src
	// Set before activate(): setup_dungeon_contents spawns guardians during
	// activation and reads incoming_path_type (elites) and promised_reward (vaults).
	room.incoming_path_type = incoming_path
	room.promised_reward = promised_reward
	room.population_mode = population_mode
	room.delete_foreign_on_collapse = TRUE // run rooms swallow what's left behind
	if(!room.activate())
		qdel(room)
		return null
	SSpocket_dimensions.register_instance(room)
	return room

/// Builds gates on the turfs recorded from the room's gate landmarks.
/// predecessor is the room the party came from; back gates lead there.
/// Forward-gate reward draws are deferred so a special door never consumes a
/// deck card (its telegraph replaces the promise).
/datum/dungeon_run/proc/build_room_gates(datum/pocket_dimension/dungeon/room, datum/pocket_dimension/dungeon/predecessor)
	var/list/obj/structure/dungeon_gate/forward_gates = list()
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
			forward_gates += gate
		else
			gate.sealed = FALSE
			gate.destination_room = predecessor
	room.gate_landmark_info.Cut()

	if(!length(forward_gates))
		return
	// One door per stretch may lead somewhere other than a fight. It replaces
	// its reward promise with a telegraph of what waits beyond; skipping it
	// forsakes it like any other unchosen door.
	if(special_room_kind && room.stretch_position + 1 == special_room_position)
		var/obj/structure/dungeon_gate/special_gate = pick(forward_gates)
		special_gate.special_kind = special_room_kind
		special_gate.reward_type = null
		forward_gates -= special_gate
	for(var/obj/structure/dungeon_gate/gate as anything in forward_gates)
		gate.reward_type = draw_door_reward()

/// Builds shrines on the turfs recorded from a room's shrine landmarks.
/datum/dungeon_run/proc/build_room_shrines(datum/pocket_dimension/dungeon/room)
	for(var/turf/shrine_turf as anything in room.shrine_turfs)
		if(QDELETED(shrine_turf) || !room.contains_turf(shrine_turf))
			continue
		var/obj/structure/dungeon_shrine/shrine = new(shrine_turf)
		shrine.owning_run = src
		room.native_movables[shrine] = TRUE
	room.shrine_turfs.Cut()

/// Grows a dark bargain altar on an open turf. Returns the altar (tests force it).
/datum/dungeon_run/proc/spawn_bargain_altar(datum/pocket_dimension/dungeon/room)
	var/list/turf/open = room.get_open_dungeon_turfs()
	if(!length(open))
		return null
	var/obj/structure/dungeon_bargain_altar/altar = new(pick(open))
	altar.owning_run = src
	altar.build_offers()
	room.native_movables[altar] = TRUE
	return altar

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
			return pick_dungeon_template(DUNGEON_ROOM_COMBAT, theme_to_use, 1, target_tier, recent_template_ids)
		if(DUNGEON_PATH_HAZARD, DUNGEON_PATH_ELITE)
			return pick_dungeon_template(DUNGEON_ROOM_COMBAT, theme_to_use, target_tier, target_tier + 2, recent_template_ids)
	return pick_dungeon_template(DUNGEON_ROOM_COMBAT, theme_to_use, max(1, target_tier - 1), target_tier + 1, recent_template_ids)

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
	return pick_dungeon_template(DUNGEON_ROOM_COMBAT, theme_to_use, max(1, target_tier - 1), target_tier + 1, recent_template_ids)

/// Whether the current stretch is the floor's last (its end rolls the boss).
/// Earlier stretches end in ordinary break rooms.
/datum/dungeon_run/proc/is_final_stretch()
	var/per_floor = floor_config ? max(1, floor_config.stretches_per_floor) : 1
	return stretches_completed_this_floor >= per_floor - 1

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
	var/datum/pocket_dimension/dungeon/room = create_room_instance(gate.pre_rolled_template, depth + 1, gate.path_type, gate.special_kind ? null : gate.reward_type, gate.special_kind || DUNGEON_POP_COMBAT)
	if(!room)
		return null
	var/new_room_kind = gate.pre_rolled_template.room_kind
	if(new_room_kind == DUNGEON_ROOM_BREAK || new_room_kind == DUNGEON_ROOM_DESCENT)
		room.stretch_position = 0
	else
		room.stretch_position = gate.source_room.stretch_position + 1
		stretch_rooms += room
		remember_template(gate.pre_rolled_template.id)
	build_room_gates(room, gate.source_room)
	build_room_shrines(room)
	if(new_room_kind == DUNGEON_ROOM_BREAK && floor >= DUNGEON_BARGAIN_MIN_FLOOR && prob(DUNGEON_BARGAIN_ALTAR_CHANCE))
		spawn_bargain_altar(room)
	if(gate.special_kind)
		special_room_kind = null // consumed; unchosen siblings are forsaken anyway
	return room

/// Called by the dungeon instance when its last guardian dies.
/datum/dungeon_run/proc/on_room_cleared(datum/pocket_dimension/dungeon/room)
	if(ending)
		return
	var/datum/map_template/pocket/dungeon/dungeon_template = room.get_dungeon_template()
	if(dungeon_template?.room_kind == DUNGEON_ROOM_COMBAT)
		switch(room.population_mode)
			if(DUNGEON_POP_COMBAT)
				depth++
				deliver_door_reward(room)
				var/datum/dungeon_room_trait/cleared_trait = room.current_trait
				cleared_trait?.on_room_cleared(src, room)
				for(var/datum/dungeon_boon/boon as anything in active_boons)
					boon.on_room_cleared(src, room)
			if(DUNGEON_POP_WAVES)
				depth++
				award_motes(DUNGEON_WAVE_PAYOUT_BASE + (floor - 1) * DUNGEON_WAVE_PAYOUT_FLOOR, null)
				room.spawn_bonus_loot_cache(sealed = FALSE)
				for(var/datum/dungeon_boon/boon as anything in active_boons)
					boon.on_room_cleared(src, room)
			// Trader/mystery rooms are freebies: no depth, no door reward.
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

/// Pays out the reward the door into this room promised.
/datum/dungeon_run/proc/deliver_door_reward(datum/pocket_dimension/dungeon/room)
	switch(room.promised_reward)
		if(DUNGEON_REWARD_BOON)
			var/mob/living/chooser
			for(var/mob/living/member as anything in get_members_in_room(room))
				if(member.client)
					chooser = member
					break
			if(chooser)
				INVOKE_ASYNC(src, PROC_REF(offer_break_room_boon), chooser)
		if(DUNGEON_REWARD_MOTES)
			award_motes(30 + (floor - 1) * 10, null)
		if(DUNGEON_REWARD_LOOT)
			room.spawn_bonus_loot_cache(sealed = FALSE)
			for(var/mob/occupant as anything in room.get_occupants())
				if(occupant.client)
					to_chat(occupant, span_nicegreen("The door's promise is kept - a cache of spoils appears!"))
		if(DUNGEON_REWARD_HEAL)
			for(var/mob/living/member as anything in get_members_in_room(room))
				member.adjustBruteLoss(-30)
				member.adjustFireLoss(-30)
				if(member.client)
					to_chat(member, span_nicegreen("Warm light washes over you, knitting your wounds."))
		if(DUNGEON_REWARD_VAULT)
			// Sealed cache; the keyholder's dropped key opens it.
			room.spawn_bonus_loot_cache(sealed = TRUE, bonus_delve = 2, cache_key_id = room.vault_key_id)
			for(var/mob/occupant as anything in room.get_occupants())
				if(occupant.client)
					to_chat(occupant, span_nicegreen("A locked vault-cache grinds up from the floor. Its key lies with the fallen."))

/datum/dungeon_run/proc/on_boss_killed(datum/pocket_dimension/dungeon/room)
	for(var/mob/occupant as anything in room.get_occupants())
		to_chat(occupant, span_nicegreen("The floor's guardian falls! A way down has opened."))
		if(occupant.client && occupant.ckey)
			var/datum/dungeon_progress/progress = get_dungeon_progress(occupant.ckey)
			progress?.record_boss_kill()
			progress?.record_floor(floor)
			grant_dungeon_milestones(occupant, floor, TRUE)

/// Grants milestone achievements to a client-bearing mob based on progress.
/datum/dungeon_run/proc/grant_dungeon_milestones(mob/user, milestone_floor, boss_killed)
	if(!user?.client)
		return
	if(boss_killed)
		user.client.give_award(/datum/award/achievement/dungeon/first_boss, user)
	if(milestone_floor >= 5)
		user.client.give_award(/datum/award/achievement/dungeon/floor_five, user)
	if(milestone_floor >= 10)
		user.client.give_award(/datum/award/achievement/dungeon/floor_ten, user)

/// Called by gates after moving someone; advances the run when a fresh
/// break room is reached, despawning the finished stretch behind the party.
/datum/dungeon_run/proc/on_room_entered(datum/pocket_dimension/dungeon/room, mob/living/user)
	if(ending)
		return
	last_seen_occupied = world.time
	mark_present(user)
	apply_boons_to(user)
	announce_gaze(user)
	var/datum/dungeon_room_trait/room_trait = room.current_trait
	room_trait?.on_mob_entered(room, user)
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
	stretch_length = floor_config.stretch_length + get_heat_rank(DUNGEON_HEAT_FORCED_MARCH)
	stretches_completed_this_floor = -1 // advance_to_break_room below counts it back to 0
	// Reaching a descent room is also a break-room moment: despawn the old floor.
	advance_to_break_room(new_floor_room)
	for(var/mob/occupant as anything in new_floor_room.get_occupants())
		to_chat(occupant, span_notice("<b>[floor_config.floor_name]</b> — I have descended to floor [floor]."))

/datum/dungeon_run/proc/advance_to_break_room(datum/pocket_dimension/dungeon/new_break_room)
	run_was_meaningful = TRUE
	stretches_completed_this_floor++
	build_stretch_deck()
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

/// Anyone carrying the run's boon stack who is no longer inside any run room
/// was extracted by something that bypassed exit_mob - a defeat-rune return,
/// a kidnap haul, an admin teleport. Strip their boons so nothing ever leaks
/// outside the dungeon (the sandbox guarantee), and mark them absent.
/// Walking back in re-applies the stack through the normal entry path.
/datum/dungeon_run/proc/validate_presence()
	if(ending || !length(boon_carriers))
		return
	if(world.time < last_presence_validation + 5 SECONDS)
		return
	last_presence_validation = world.time
	var/list/rooms = get_all_rooms()
	for(var/carrier_key in boon_carriers.Copy())
		var/mob/living/carrier = locate(carrier_key)
		if(!istype(carrier) || QDELETED(carrier))
			boon_carriers -= carrier_key
			continue
		var/turf/carrier_turf = get_turf(carrier)
		var/inside = FALSE
		for(var/datum/pocket_dimension/dungeon/room as anything in rooms)
			if(room.contains_turf(carrier_turf))
				inside = TRUE
				break
		if(inside)
			continue
		strip_boons_from(carrier)
		mark_absent(carrier)

/// The run's unique kidnap-lair tag (see the larder landmark).
/datum/dungeon_run/proc/get_larder_tag()
	return "dungeon_[REF(src)]"

/// The larder tag when a live larder exists somewhere in the run, else null.
/// Guardians tagged with a dead larder can't haul anyway (no entrance markers),
/// but null keeps their AI from even trying.
/datum/dungeon_run/proc/get_live_larder_tag()
	var/run_tag = get_larder_tag()
	return length(GLOB.kidnap_entrance_markers[run_tag]) ? run_tag : null

/// One line to every present client in the run.
/datum/dungeon_run/proc/notify_roster(message, span_proc = "warning")
	for(var/mob/living/member as anything in get_present_members())
		if(!member.client)
			continue
		switch(span_proc)
			if("nicegreen")
				to_chat(member, span_nicegreen(message))
			if("userdanger")
				to_chat(member, span_userdanger(message))
			else
				to_chat(member, span_warning(message))

/// A present member has been defeat-knocked-out: tell the party, check the wipe.
/datum/dungeon_run/proc/on_member_defeated(mob/living/source)
	SIGNAL_HANDLER
	if(ending)
		return
	notify_roster("[source.real_name || source.name] has fallen! Stabilize them, or press on and leave them to the dark.")
	maybe_arm_wipe()

/// TRUE when every present client member is dead or defeat-knocked-out.
/// No client members at all is not a wipe - abandonment owns that case.
/datum/dungeon_run/proc/is_party_wiped()
	var/any_client = FALSE
	for(var/mob/living/member as anything in get_present_members())
		if(!member.client)
			continue
		any_client = TRUE
		if(member.stat != DEAD && !member.has_status_effect(/datum/status_effect/defeat_knockout))
			return FALSE
	return any_client

/// Arms the wipe grace when the whole party is down. Anyone recovering before
/// it expires (revive, struggle-up, rune) grants a reprieve.
/datum/dungeon_run/proc/maybe_arm_wipe()
	if(ending || wipe_timer)
		return
	if(!is_party_wiped())
		return
	notify_roster("The whole party is down! The walls begin to grind inward - someone must rise, or the dungeon claims this run.", "userdanger")
	wipe_timer = addtimer(CALLBACK(src, PROC_REF(resolve_wipe)), get_wipe_grace(), TIMER_STOPPABLE)

/datum/dungeon_run/proc/resolve_wipe()
	wipe_timer = null
	if(ending)
		return
	if(!is_party_wiped())
		notify_roster("The grinding stops. The dungeon, disappointed, lets the run continue.", "nicegreen")
		return
	wiped = TRUE
	teardown_message = "The dungeon closes over the fallen and spits out what is left of them!"
	qdel(src)

/// Ticked from room process_pocket(); collapses an abandoned run.
/datum/dungeon_run/proc/check_abandonment()
	if(ending)
		return
	validate_presence()
	maybe_arm_wipe() // covers deaths and disconnects the defeat signal misses
	if(has_client_occupants())
		last_seen_occupied = world.time
		return
	if(world.time > last_seen_occupied + DUNGEON_RUN_ABANDON_TIMEOUT)
		qdel(src)
