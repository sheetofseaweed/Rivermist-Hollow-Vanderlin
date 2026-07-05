// Party & raid management for infinite dungeon runs.
// Binds a run to a /datum/party, tracks who is physically inside (present set),
// gates advancement behind a party muster, and handles the assembly UI plus the
// lockout / petition / approval flow for outsiders.

/datum/dungeon_run/proc/bind_party(datum/party/party)
	if(istype(party))
		party_ref = WEAKREF(party)

/datum/dungeon_run/proc/get_party()
	var/datum/party/party = party_ref?.resolve()
	if(party && !QDELETED(party))
		return party
	return null

/datum/dungeon_run/proc/is_party_member(mob/living/user)
	if(!user?.ckey)
		return TRUE // partyless lone delver is always "in" its own run
	var/datum/party/party = get_party()
	if(!party)
		return TRUE
	return (ckey(user.ckey) in party.members)

/datum/dungeon_run/proc/mark_present(mob/living/user)
	if(!istype(user))
		return
	if(user.ckey)
		present_ckeys |= ckey(user.ckey)
	// Fall notification + wipe detection (override: re-entry re-marks freely).
	RegisterSignal(user, COMSIG_LIVING_DEFEATED, PROC_REF(on_member_defeated), override = TRUE)

/datum/dungeon_run/proc/mark_absent(mob/living/user)
	if(!istype(user))
		return
	if(user.ckey)
		present_ckeys -= ckey(user.ckey)
	UnregisterSignal(user, COMSIG_LIVING_DEFEATED)

/// Player-controlled or minded mobs currently inside a given room.
/datum/dungeon_run/proc/get_members_in_room(datum/pocket_dimension/dungeon/room)
	var/list/mob/found = list()
	if(QDELETED(room))
		return found
	for(var/mob/occupant as anything in room.get_occupants())
		if(QDELETED(occupant))
			continue
		if(occupant.mind || occupant.client)
			found += occupant
	return found

/// All minded/client members currently anywhere in the run.
/datum/dungeon_run/proc/get_present_members()
	var/list/mob/found = list()
	for(var/datum/pocket_dimension/dungeon/room as anything in get_all_rooms())
		found += get_members_in_room(room)
	return found

/// The run is joinable only while the present party rests in a break/descent room.
/datum/dungeon_run/proc/is_at_rest()
	if(ending)
		return FALSE
	if(length(stretch_rooms))
		return FALSE
	var/datum/map_template/pocket/dungeon/break_template = current_break_room?.get_dungeon_template()
	if(!break_template)
		return FALSE
	return break_template.room_kind == DUNGEON_ROOM_BREAK || break_template.room_kind == DUNGEON_ROOM_DESCENT

// -- Muster movement ---------------------------------------------------------

/// Attempts to advance the present party through a forward/descent gate.
/// Solo / partyless callers advance immediately. Otherwise all present,
/// conscious, connected members must be gathered in the gate's room.
/datum/dungeon_run/proc/muster_advance(obj/structure/dungeon_gate/gate, mob/living/initiator, force = FALSE)
	if(ending || QDELETED(gate))
		return FALSE
	var/datum/pocket_dimension/dungeon/source_room = gate.source_room
	if(QDELETED(source_room))
		return FALSE

	if(!force && !is_mustered(source_room))
		announce_muster_gap(source_room, initiator)
		return FALSE

	var/datum/pocket_dimension/dungeon/target = gate.resolve_destination()
	if(!target)
		to_chat(initiator, span_warning("The passage twists shut before me."))
		return FALSE

	// Cohort = every minded/client mob currently in the source room (carries downed bodies).
	var/list/mob/cohort = get_members_in_room(source_room)
	if(!length(cohort))
		cohort = list(initiator)
	cohort |= initiator

	for(var/mob/living/member as anything in cohort)
		if(QDELETED(member))
			continue
		move_member_through(member, target)

	// The path is chosen: sibling onward passages fuse shut for good. Only the
	// taken door stays open for backtracking.
	for(var/obj/structure/dungeon_gate/sibling as anything in source_room.gates)
		if(sibling == gate || QDELETED(sibling))
			continue
		if(sibling.gate_role == DUNGEON_GATE_FORWARD || sibling.gate_role == DUNGEON_GATE_DESCENT)
			sibling.forsaken = TRUE

	target.touch()
	source_room.touch()
	on_room_entered(target, initiator)
	return TRUE

/// TRUE when every present, conscious, connected member is in source_room.
/datum/dungeon_run/proc/is_mustered(datum/pocket_dimension/dungeon/source_room)
	return !length(get_muster_missing(source_room))

/// Moves a single member to a target room's entry turf, dragging pulled cargo.
/datum/dungeon_run/proc/move_member_through(mob/living/member, datum/pocket_dimension/dungeon/target)
	var/turf/entry_turf = target.get_entry_turf()
	if(!entry_turf)
		return FALSE
	var/list/atom/movable/dragged = list()
	if(member.pulling && !QDELETED(member.pulling))
		dragged += member.pulling
	for(var/obj/item/grabbing/grab_item in member.held_items)
		if(grab_item.grabbed && !QDELETED(grab_item.grabbed) && ismovable(grab_item.grabbed))
			dragged |= grab_item.grabbed
	member.forceMove(entry_turf)
	mark_present(member)
	apply_boons_to(member) // mustered members share the run's active boons
	if(target.current_trait?.announce && member.client)
		to_chat(member, span_warning(target.current_trait.announce))
	for(var/atom/movable/cargo as anything in dragged)
		var/turf/drop_turf = target.get_drop_turf(cargo) || entry_turf
		cargo.forceMove(drop_turf)
	return TRUE

/// Names of present members who still gate a muster from this room (conscious,
/// connected, not defeat-knocked-out, and standing somewhere else).
/datum/dungeon_run/proc/get_muster_missing(datum/pocket_dimension/dungeon/source_room)
	var/list/missing = list()
	if(QDELETED(source_room))
		return missing
	for(var/mob/living/member as anything in get_present_members())
		if(QDELETED(member) || !member.client || member.stat >= UNCONSCIOUS)
			continue
		if(member.has_status_effect(/datum/status_effect/defeat_knockout))
			continue // defeated members are carried, not waited on
		if(!source_room.contains_turf(get_turf(member)))
			missing += (member.real_name || member.name)
	return missing

/// Tells the initiator who still needs to gather before the party can advance.
/datum/dungeon_run/proc/announce_muster_gap(datum/pocket_dimension/dungeon/source_room, mob/living/initiator)
	var/list/missing = get_muster_missing(source_room)
	if(length(missing))
		to_chat(initiator, span_warning("The passage will not open until the party gathers. Still scattered: [english_list(missing)]."))
	else
		to_chat(initiator, span_warning("The passage resists. Try again."))

// -- Assembly UI -------------------------------------------------------------

/obj/structure/dungeon_entrance/proc/open_assembly_menu(mob/living/carbon/user)
	if(!istype(user) || !user.client)
		return
	var/datum/party/party = user.current_party
	if(!party)
		var/make = tgui_alert(user, "You need a party to mount an expedition. Form one now?", "Assemble Your Party", list("Create Party", "Cancel"))
		if(make != "Create Party")
			return
		party = create_party(user, "[user.real_name]'s Expedition")
		if(!party)
			return
	var/list/roster_lines = list()
	for(var/member_ckey in party.members)
		var/mob/living/member = get_mob_by_ckey(member_ckey)
		var/member_name = member ? (member.real_name || member.name) : member_ckey
		var/rank = get_player_rank(member_ckey)
		var/here = (member && member.Adjacent(src)) ? "present" : "away"
		roster_lines += "[member_name] — [rank] ([here])"
	var/list/actions = list("Descend (leader)", "Invite someone", "Refresh", "Close")
	var/header = "Party: [party.party_name]\nLeader: [get_mob_by_ckey(party.party_leader_ckey)]\n\n[roster_lines.Join("\n")]\n\n(Echo ledger appears here once unlocked.)"
	var/choice = tgui_alert(user, header, "Assemble Your Party", actions)
	switch(choice)
		if("Descend (leader)")
			if(!party.is_leader(user.ckey))
				to_chat(user, span_warning("Only the leader may give the order to descend."))
				return
			descend_with_party(user, party)
		if("Invite someone")
			user.invite_to_party()
			open_assembly_menu(user)
		if("Refresh")
			open_assembly_menu(user)

/// Starts the run (if needed) and moves every present, adjacent party member in.
/obj/structure/dungeon_entrance/proc/descend_with_party(mob/living/carbon/leader, datum/party/party)
	if(is_dormant())
		to_chat(leader, span_warning("The way down is buried under fresh rubble."))
		return
	if(!active_run)
		var/datum/dungeon_run/new_run = new(src, theme_filter)
		new_run.bind_party(party)
		new_run.seed_from_progress(get_dungeon_progress(leader.ckey))
		if(!new_run.start())
			qdel(new_run)
			to_chat(leader, span_warning("The depths refuse to take shape."))
			return
		active_run = new_run
	var/datum/pocket_dimension/dungeon/break_room = active_run.current_break_room
	if(!break_room)
		return
	var/descended = 0
	for(var/member_ckey in party.members)
		var/mob/living/member = get_mob_by_ckey(member_ckey)
		if(!member || !member.Adjacent(src))
			continue
		if(break_room.enter_mob(member, get_turf(src), src))
			active_run.mark_present(member)
			active_run.apply_boons_to(member)
			descended++
	if(!descended)
		to_chat(leader, span_warning("No one was close enough to descend."))

// -- Lockout, petition & approval -------------------------------------------

/obj/structure/dungeon_entrance/proc/petition_to_join(mob/living/carbon/user)
	if(!istype(user) || !user.client || !active_run)
		return
	if(active_run.is_party_member(user))
		descend_with_party(user, active_run.get_party())
		return
	if(!active_run.is_at_rest())
		to_chat(user, span_warning("The party is deep in the dungeon. The way is sealed until they reach a place of respite. You wait by the entrance."))
		active_run.waiting_petitioners |= WEAKREF(user)
		return
	active_run.request_join(user)

/// Asks present members to approve an outsider; non-unanimous per approval mode.
/datum/dungeon_run/proc/request_join(mob/living/carbon/petitioner)
	if(ending || !istype(petitioner))
		return
	var/list/mob/voters = list()
	for(var/mob/living/member as anything in get_present_members())
		if(member.client)
			voters += member
	if(!length(voters))
		// No one conscious to approve; admit by default while at rest.
		admit_petitioner(petitioner)
		return
	var/datum/party/party = get_party()
	var/approvals = 0
	var/needed = get_join_approvals_needed(length(voters), party)
	for(var/mob/living/voter as anything in voters)
		if(join_approval_mode == DUNGEON_JOIN_APPROVAL_LEADER && party && !party.is_leader(voter.ckey))
			continue
		var/yes = tgui_alert(voter, "[petitioner.real_name] petitions to join your expedition. Allow it?", "A Petitioner", list("Allow", "Deny"))
		if(yes == "Allow")
			approvals++
			if(approvals >= needed)
				break
	if(approvals >= needed)
		admit_petitioner(petitioner)
	else
		to_chat(petitioner, span_warning("The party turns you away."))

/datum/dungeon_run/proc/get_join_approvals_needed(voter_count, datum/party/party)
	switch(join_approval_mode)
		if(DUNGEON_JOIN_APPROVAL_MAJORITY)
			return FLOOR(voter_count / 2, 1) + 1
		if(DUNGEON_JOIN_APPROVAL_LEADER)
			return 1
	return 1 // ANY

/datum/dungeon_run/proc/admit_petitioner(mob/living/carbon/petitioner)
	if(ending || QDELETED(current_break_room))
		return
	var/datum/party/party = get_party()
	if(party && !(ckey(petitioner.ckey) in party.members))
		join_party(petitioner, party)
	waiting_petitioners -= WEAKREF(petitioner)
	var/turf/entry_turf = current_break_room.get_entry_turf()
	if(entry_turf)
		petitioner.forceMove(entry_turf)
		mark_present(petitioner)
		apply_boons_to(petitioner) // late joiners share the run's active boons
		to_chat(petitioner, span_nicegreen("The party admits you. You descend to join them."))
		for(var/mob/living/member as anything in get_present_members())
			if(member != petitioner)
				to_chat(member, span_notice("[petitioner.real_name] has joined the expedition."))

/datum/dungeon_run/proc/notify_waiting_petitioners()
	for(var/datum/weakref/petitioner_ref as anything in waiting_petitioners.Copy())
		var/mob/living/petitioner = petitioner_ref.resolve()
		if(!petitioner || QDELETED(petitioner) || !petitioner.client)
			waiting_petitioners -= petitioner_ref
			continue
		to_chat(petitioner, span_nicegreen("The expedition has reached a place of respite. Touch the entrance again to petition to join."))
