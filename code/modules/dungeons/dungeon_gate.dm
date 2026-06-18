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

/obj/structure/dungeon_gate/Destroy()
	owning_run = null
	source_room = null
	destination_room = null
	pre_rolled_template = null
	return ..()

/obj/structure/dungeon_gate/examine(mob/user)
	. = ..()
	if(sealed)
		. += span_warning("It is sealed shut. The hostile presence in this room holds it closed.")
	else if(gate_role == DUNGEON_GATE_BACK)
		. += span_notice("It leads back the way I came.")
	else if(gate_role == DUNGEON_GATE_DESCENT)
		. += span_notice("A stairway plunges deeper. The air below is colder, hungrier.")
	else if(pre_rolled_template)
		. += span_notice(pre_rolled_template.gate_hint)

/obj/structure/dungeon_gate/attack_hand(mob/user, list/modifiers)
	. = ..()
	use_gate(user)

/obj/structure/dungeon_gate/attack_animal(mob/user, list/modifiers)
	use_gate(user)

/obj/structure/dungeon_gate/attack_paw(mob/user, list/modifiers)
	use_gate(user)

/obj/structure/dungeon_gate/proc/use_gate(mob/living/user)
	if(!istype(user))
		return FALSE
	// Dungeon natives don't get to wander the run.
	if(!user.mind && !user.client)
		return FALSE
	if(sealed)
		to_chat(user, span_warning("The passage is sealed. Whatever guards this room holds it shut."))
		return FALSE
	if(!owning_run || QDELETED(owning_run))
		to_chat(user, span_warning("The passage leads nowhere. The dungeon has lost interest."))
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
