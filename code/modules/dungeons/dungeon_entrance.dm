/obj/structure/dungeon_entrance
	name = "yawning cave mouth"
	desc = "A dark opening exhaling cold, stale air. Something about its depths refuses to be mapped."
	icon = 'icons/turf/floors.dmi'
	icon_state = "hole1"
	anchored = TRUE
	density = FALSE
	pixel_y = 5
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	/// DUNGEON_ENTRANCE_* kind
	var/entrance_kind = DUNGEON_ENTRANCE_ONESHOT
	/// Restrict rolled templates to one DUNGEON_THEME_*; null = any
	var/theme_filter
	/// Tier band for one-bite template rolls
	var/tier_min = 1
	var/tier_max = 2
	/// Dormancy duration after the dungeon collapses
	var/respawn_cooldown = DUNGEON_ENTRANCE_COOLDOWN
	/// world.time before which the entrance refuses to open
	var/dormant_until = 0
	/// Live infinite run, if entrance_kind is infinite
	var/datum/dungeon_run/active_run

/obj/structure/dungeon_entrance/Destroy()
	if(active_run)
		var/datum/dungeon_run/run = active_run
		active_run = null
		qdel(run)
	else if(SSpocket_dimensions)
		SSpocket_dimensions.delete_instance(get_instance_key(), "The dungeon collapses and throws everything back outside!")
	return ..()

/obj/structure/dungeon_entrance/examine(mob/user)
	. = ..()
	if(is_dormant())
		. += span_warning("The passage is choked with fresh rubble. Given time, the depths will open again.")
	else
		. += span_notice("Touch it to descend.")

/obj/structure/dungeon_entrance/proc/get_instance_key()
	return "dungeon::[REF(src)]"

/obj/structure/dungeon_entrance/proc/is_dormant()
	return world.time < dormant_until

/obj/structure/dungeon_entrance/attack_hand(mob/user, list/modifiers)
	. = ..()
	try_enter(user)

/obj/structure/dungeon_entrance/attack_animal(mob/user, list/modifiers)
	try_enter(user)

/obj/structure/dungeon_entrance/attack_paw(mob/user, list/modifiers)
	try_enter(user)

/obj/structure/dungeon_entrance/AltClick(mob/user, list/modifiers)
	. = ..()
	if(!iscarbon(user) || !user.Adjacent(src))
		return
	var/mob/living/carbon/carbon_user = user
	if(entrance_kind != DUNGEON_ENTRANCE_INFINITE)
		try_enter(carbon_user)
		return
	if(active_run && !active_run.is_party_member(carbon_user))
		petition_to_join(carbon_user)
		return
	open_assembly_menu(carbon_user)

/obj/structure/dungeon_entrance/attackby(obj/item/attacking_item, mob/living/user, list/modifiers)
	if(istype(attacking_item, /obj/item/grabbing))
		var/obj/item/grabbing/grab_item = attacking_item
		if(handle_grabbed_entry(user, grab_item))
			return TRUE
	return ..()

/// Resolves (creating if needed) the room a user entering this entrance lands in.
/obj/structure/dungeon_entrance/proc/get_entry_room(mob/living/user)
	if(is_dormant())
		to_chat(user, span_warning("The way down is buried under fresh rubble. It has not reopened yet."))
		return null

	if(entrance_kind == DUNGEON_ENTRANCE_INFINITE)
		if(active_run && !active_run.is_party_member(user))
			if(iscarbon(user))
				var/mob/living/carbon/carbon_petitioner = user
				petition_to_join(carbon_petitioner)
			return null
		if(!active_run)
			var/datum/dungeon_run/new_run = new(src, theme_filter)
			var/datum/party/user_party
			if(iscarbon(user))
				var/mob/living/carbon/carbon_user = user
				user_party = carbon_user.current_party
			new_run.bind_party(user_party) // null is fine (solo)
			if(!new_run.start())
				qdel(new_run)
				to_chat(user, span_warning("The depths refuse to take shape. Nothing answers."))
				return null
			active_run = new_run
		return active_run.current_break_room

	var/datum/pocket_dimension/dungeon/instance = SSpocket_dimensions.get_instance(get_instance_key())
	if(!instance)
		var/datum/map_template/pocket/dungeon/rolled = pick_dungeon_template(DUNGEON_ROOM_ONESHOT, theme_filter, tier_min, tier_max)
		if(!rolled)
			to_chat(user, span_warning("The depths refuse to take shape. Nothing answers."))
			return null
		instance = SSpocket_dimensions.get_or_create_instance(get_instance_key(), rolled, POCKET_LIFECYCLE_COLLAPSE, DUNGEON_DEFAULT_IDLE_TIMEOUT, src)
	return instance

/obj/structure/dungeon_entrance/proc/try_enter(mob/living/user)
	if(!istype(user))
		return FALSE
	var/datum/pocket_dimension/dungeon/room = get_entry_room(user)
	if(!room)
		return FALSE
	to_chat(user, span_notice("I slip down into the dark."))
	. = room.enter_mob(user, get_turf(src), src)
	if(. && active_run)
		active_run.mark_present(user)
	return .

/obj/structure/dungeon_entrance/proc/handle_grabbed_entry(mob/living/user, obj/item/grabbing/grab_item)
	if(!istype(user) || !istype(grab_item))
		return FALSE
	var/mob/living/victim = grab_item.grabbed
	if(!istype(victim))
		return FALSE
	var/datum/pocket_dimension/dungeon/room = get_entry_room(user)
	if(!room)
		return TRUE
	if(!room.send_movable_inside(victim, get_turf(src), null, src))
		to_chat(user, span_warning("[victim] won't fit through the opening."))
		return TRUE
	user.stop_pulling()
	qdel(grab_item)
	room.enter_mob(user, get_turf(src), src)
	user.visible_message(
		span_warning("[user] drags [victim] down into [src]!"),
		span_notice("I drag [victim] down into [src]."),
	)
	return TRUE

/// Called by the dungeon instance when it collapses. Run-owned rooms despawn
/// constantly mid-run, so the cooldown only applies to standalone dungeons;
/// run teardown applies it through on_run_ended() instead.
/obj/structure/dungeon_entrance/proc/on_dungeon_collapsed(datum/pocket_dimension/dungeon/instance)
	if(instance?.owning_run || active_run)
		return
	dormant_until = world.time + respawn_cooldown
	visible_message(span_warning("[src] shudders as the passage below collapses in on itself!"))

/obj/structure/dungeon_entrance/proc/on_run_ended(datum/dungeon_run/run)
	if(active_run == run)
		active_run = null
	dormant_until = world.time + respawn_cooldown
	visible_message(span_warning("[src] shudders as the passage below collapses in on itself!"))

/obj/structure/dungeon_entrance/infinite
	name = "abyssal delve mouth"
	desc = "A stairway descending into dark that swallows torchlight. The steps are never quite where they were yesterday."
	entrance_kind = DUNGEON_ENTRANCE_INFINITE
