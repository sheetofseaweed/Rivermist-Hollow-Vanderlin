/obj/structure/dungeon_gate
	name = "shifting passage"
	desc = "An archway of stone that was not there a moment ago. The space beyond refuses to settle."
	icon = 'icons/roguetown/misc/structure.dmi'
	icon_state = "ladder01"
	density = FALSE
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	/// DUNGEON_GATE_* role
	var/gate_role = DUNGEON_GATE_FORWARD
	/// Run that owns this gate
	var/datum/dungeon_run/owning_run
	/// Room this gate stands in
	var/datum/pocket_dimension/dungeon/source_room
	/// Destination room; lazily created for forward gates
	var/datum/pocket_dimension/dungeon/destination_room
	/// Template a forward gate will instantiate on first use
	var/datum/map_template/pocket/dungeon/pre_rolled_template
	/// Forward gates stay sealed until the room is cleared
	var/sealed = FALSE
	/// DUNGEON_PATH_* — risk/reward flavor of the room beyond
	var/path_type = DUNGEON_PATH_COMBAT
	/// DUNGEON_REWARD_* this door promises for clearing the room beyond
	var/reward_type = DUNGEON_REWARD_MOTES
	/// When set, this gate stays locked until a matching key is applied
	var/requires_key = FALSE
	/// Key id this gate accepts
	var/key_id = "default"
	/// Whether the key lock has been opened
	var/key_unlocked = FALSE
	/// TRUE once a sibling door was chosen instead - the path is committed,
	/// this passage never opens again
	var/forsaken = FALSE

/obj/structure/dungeon_gate/Destroy()
	owning_run = null
	source_room = null
	destination_room = null
	pre_rolled_template = null
	return ..()

/obj/structure/dungeon_gate/examine(mob/user)
	. = ..()
	if(forsaken)
		. += span_warning("It has fused into dead stone. The party chose another path - this one is gone forever.")
		return
	if(requires_key && !key_unlocked)
		. += span_warning("It is locked. A key lies somewhere in this room.")
	if(sealed)
		. += span_warning("It is sealed shut. The hostile presence in this room holds it closed.")
	else if(gate_role == DUNGEON_GATE_BACK)
		. += span_notice("It leads back the way I came.")
	else if(gate_role == DUNGEON_GATE_DESCENT)
		. += span_notice("A stairway plunges deeper. The air below is colder, hungrier.")
	else if(pre_rolled_template)
		. += span_notice(pre_rolled_template.gate_hint)
		. += span_notice(get_reward_promise_text())
		. += span_notice("Danger: [get_path_danger_text()].")

/obj/structure/dungeon_gate/proc/get_reward_promise_text()
	switch(reward_type)
		if(DUNGEON_REWARD_BOON)
			return "Beyond this passage, a blessing awaits."
		if(DUNGEON_REWARD_LOOT)
			return "The smell of old gold seeps through."
		if(DUNGEON_REWARD_VAULT)
			return "Something locked and heavy with treasure waits beyond."
		if(DUNGEON_REWARD_HEAL)
			return "Warm, clean air drifts from beyond."
	return "You hear the faint chime of motes beyond."

/obj/structure/dungeon_gate/proc/get_path_danger_text()
	switch(path_type)
		if(DUNGEON_PATH_TREASURE)
			return "low"
		if(DUNGEON_PATH_SHORTCUT)
			return "low"
		if(DUNGEON_PATH_HAZARD)
			return "high"
		if(DUNGEON_PATH_ELITE)
			return "very high"
	return "moderate"


/obj/structure/dungeon_gate/attack_hand(mob/user, list/modifiers)
	. = ..()
	// Players get the full gate panel; anything mindless falls through to nothing.
	if(user.client)
		ui_interact(user)
		return
	use_gate(user)

/obj/structure/dungeon_gate/ui_state(mob/user)
	return GLOB.physical_state

/obj/structure/dungeon_gate/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "DungeonGate")
		ui.open()

/obj/structure/dungeon_gate/ui_data(mob/user)
	var/list/data = list()
	data["role"] = gate_role
	data["sealed"] = sealed
	data["forsaken"] = forsaken
	data["locked"] = (requires_key && !key_unlocked)
	data["reward_text"] = (gate_role == DUNGEON_GATE_BACK) ? null : get_reward_promise_text()
	data["danger_text"] = (gate_role == DUNGEON_GATE_BACK) ? null : get_path_danger_text()
	data["hint"] = pre_rolled_template?.gate_hint
	data["back_available"] = (gate_role == DUNGEON_GATE_BACK) ? (destination_room && !QDELETED(destination_room)) : TRUE

	var/list/missing = list()
	var/is_leader = FALSE
	if(owning_run && !QDELETED(owning_run))
		if(gate_role != DUNGEON_GATE_BACK && !QDELETED(source_room))
			missing = owning_run.get_muster_missing(source_room)
		var/datum/party/party = owning_run.get_party()
		is_leader = !party || party.is_leader(user?.ckey)
	data["muster_missing"] = missing
	data["is_leader"] = is_leader
	return data

/obj/structure/dungeon_gate/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/living/user = usr
	if(!isliving(user))
		return
	switch(action)
		if("traverse")
			ui.close()
			use_gate(user)
			return TRUE
		if("force")
			if(!owning_run || QDELETED(owning_run) || sealed || forsaken || gate_role == DUNGEON_GATE_BACK)
				return
			var/datum/party/party = owning_run.get_party()
			if(party && !party.is_leader(user.ckey))
				to_chat(user, span_warning("Only the party leader can force the way open."))
				return
			ui.close()
			if(user.client)
				user.visible_message(span_notice("[user] begins working the passage open..."), span_notice("I begin working the passage open..."))
				if(!do_after(user, DUNGEON_GATE_TRAVERSE_TIME, src))
					return TRUE
			owning_run.muster_advance(src, user, force = TRUE)
			return TRUE

/obj/structure/dungeon_gate/attack_animal(mob/user, list/modifiers)
	use_gate(user)

/obj/structure/dungeon_gate/attack_paw(mob/user, list/modifiers)
	use_gate(user)

/obj/structure/dungeon_gate/attackby(obj/item/attacking_item, mob/living/user, list/modifiers)
	if(requires_key && !key_unlocked && istype(attacking_item, /obj/item/dungeon_key))
		var/obj/item/dungeon_key/key = attacking_item
		if(key.key_id != key_id)
			to_chat(user, span_warning("This key does not fit this passage."))
			return TRUE
		key_unlocked = TRUE
		qdel(key)
		visible_message(span_nicegreen("[src] grinds open as the key dissolves into light!"))
		return TRUE
	return ..()

/obj/structure/dungeon_gate/proc/use_gate(mob/living/user)
	if(!istype(user))
		return FALSE
	// Dungeon natives don't get to wander the run.
	if(!user.mind && !user.client)
		return FALSE
	if(forsaken)
		to_chat(user, span_warning("The passage is dead stone. The path was chosen, and it was not this one."))
		return FALSE
	if(sealed)
		to_chat(user, span_warning("The passage is sealed. Whatever guards this room holds it shut."))
		return FALSE
	if(!owning_run || QDELETED(owning_run))
		to_chat(user, span_warning("The passage leads nowhere. The dungeon has lost interest."))
		return FALSE
	if(requires_key && !key_unlocked)
		to_chat(user, span_warning("This passage is locked. It needs a key found within this room."))
		return FALSE
	// Working a passage open takes a moment (players only; the harness and any
	// odd mob paths stay instant).
	if(user.client)
		user.visible_message(span_notice("[user] begins working the passage open..."), span_notice("I begin working the passage open..."))
		if(!do_after(user, DUNGEON_GATE_TRAVERSE_TIME, src))
			return FALSE
	if(gate_role == DUNGEON_GATE_BACK)
		// Backtracking is free: any present member may step back alone.
		var/datum/pocket_dimension/dungeon/back_room = resolve_destination()
		if(!back_room)
			to_chat(user, span_warning("The way back has crumbled."))
			return FALSE
		return transfer_through(user, back_room)
	// Forward / descent gates move the whole present party together (muster).
	return owning_run.muster_advance(src, user)

/obj/structure/dungeon_gate/attack_hand_secondary(mob/user, list/modifiers)
	if(gate_role == DUNGEON_GATE_BACK || sealed || !owning_run || QDELETED(owning_run))
		return ..()
	var/datum/party/party = owning_run.get_party()
	if(party && !party.is_leader(user?.ckey))
		to_chat(user, span_warning("Only the party leader can force the way open."))
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	owning_run.muster_advance(src, user, force = TRUE)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/structure/dungeon_gate/proc/resolve_destination()
	if(destination_room && !QDELETED(destination_room))
		return destination_room
	destination_room = null
	if((gate_role != DUNGEON_GATE_FORWARD && gate_role != DUNGEON_GATE_DESCENT) || !pre_rolled_template)
		return null
	destination_room = owning_run.instantiate_room_for_gate(src)
	return destination_room

/obj/structure/dungeon_gate/proc/transfer_through(mob/living/user, datum/pocket_dimension/dungeon/target_room)
	var/turf/entry_turf = target_room.get_entry_turf()
	if(!entry_turf)
		return FALSE

	// Bring along whatever the user is dragging - mobs, crates, corpses, anything.
	var/list/atom/movable/dragged = list()
	if(user.pulling && !QDELETED(user.pulling))
		dragged += user.pulling
	for(var/obj/item/grabbing/grab_item in user.held_items)
		if(grab_item.grabbed && !QDELETED(grab_item.grabbed) && ismovable(grab_item.grabbed))
			dragged |= grab_item.grabbed

	user.forceMove(entry_turf)
	for(var/atom/movable/cargo as anything in dragged)
		var/turf/drop_turf = target_room.get_drop_turf(cargo) || entry_turf
		cargo.forceMove(drop_turf)
	target_room.touch()
	source_room?.touch()
	owning_run.on_room_entered(target_room, user)
	to_chat(user, span_notice("I step through, and the passage seals behind my heels."))
	return TRUE
