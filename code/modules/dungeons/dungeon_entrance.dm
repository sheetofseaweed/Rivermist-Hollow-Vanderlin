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
	/// Heat dial ranks staged at assembly (assoc dial id -> rank); copied onto
	/// the next run created here, then cleared. Requires the leader to own the
	/// Grim Covenant unlock.
	var/list/pending_heat_ranks = list()

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
	// Infinite entrances lead with the assembly screen; only mid-run members
	// drop straight back down. One-shot holes stay touch-to-descend.
	if(entrance_kind != DUNGEON_ENTRANCE_INFINITE || !iscarbon(user) || !user.client)
		try_enter(user)
		return
	var/mob/living/carbon/carbon_user = user
	if(active_run)
		if(active_run.is_party_member(carbon_user))
			try_enter(carbon_user)
		else
			petition_to_join(carbon_user)
		return
	open_assembly_menu(carbon_user)

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

/obj/structure/dungeon_entrance/attack_hand_secondary(mob/user, list/modifiers)
	if(entrance_kind == DUNGEON_ENTRANCE_INFINITE && isliving(user) && user.client)
		ui_interact(user)
	else
		user.examinate(src)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

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
			new_run.bind_party(user_party, user) // null is fine (solo)
			new_run.seed_from_progress(get_dungeon_progress(user.ckey))
			new_run.heat_ranks = consume_pending_heat(user)
			// Publish before start(): map activation yields, and a second entrant
			// must observe this construction instead of creating a duplicate run.
			active_run = new_run
			if(!new_run.start())
				if(active_run == new_run)
					active_run = null
				qdel(new_run)
				to_chat(user, span_warning("The depths refuse to take shape. Nothing answers."))
				return null
			var/datum/party/current_user_party
			if(iscarbon(user))
				var/mob/living/carbon/current_carbon_user = user
				current_user_party = current_carbon_user.current_party
			if(active_run != new_run || QDELETED(user) || !user.Adjacent(src) || current_user_party != user_party)
				if(!QDELETED(new_run))
					qdel(new_run)
				return null
		if(!active_run.current_break_room)
			to_chat(user, span_warning("The depths are still taking shape. Try again in a moment."))
			return null
		return active_run.current_break_room

	var/datum/pocket_dimension/dungeon/instance = SSpocket_dimensions.get_instance(get_instance_key())
	if(!instance)
		var/datum/map_template/pocket/dungeon/rolled = pick_dungeon_template(DUNGEON_ROOM_ONESHOT, theme_filter, tier_min, tier_max)
		if(!rolled)
			to_chat(user, span_warning("The depths refuse to take shape. Nothing answers."))
			return null
		instance = SSpocket_dimensions.get_or_create_instance(get_instance_key(), rolled, POCKET_LIFECYCLE_COLLAPSE, DUNGEON_DEFAULT_IDLE_TIMEOUT, src)
	return instance

/// Hands the staged heat ranks to a new run - only if the initiating player
/// still owns the covenant (the dials are also gated, this is the backstop).
/obj/structure/dungeon_entrance/proc/consume_pending_heat(mob/living/initiator)
	var/list/staged = pending_heat_ranks
	pending_heat_ranks = list()
	if(!length(staged))
		return list()
	var/datum/dungeon_progress/progress = initiator?.ckey ? get_dungeon_progress(initiator.ckey) : null
	if(!progress?.has_unlock("grim_covenant"))
		return list()
	return staged

/obj/structure/dungeon_entrance/proc/try_enter(mob/living/user)
	if(!istype(user))
		return FALSE
	var/datum/pocket_dimension/dungeon/room = get_entry_room(user)
	if(!room)
		return FALSE
	to_chat(user, span_notice("I slip down into the dark."))
	. = room.enter_mob(user, get_turf(src), src)
	if(. && active_run)
		active_run.on_member_entered_room(room, user, TRUE)
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
	if(active_run)
		active_run.add_forced_entrant(victim)
		active_run.on_member_entered_room(room, victim)
	user.stop_pulling()
	qdel(grab_item)
	if(room.enter_mob(user, get_turf(src), src) && active_run)
		active_run.on_member_entered_room(room, user, TRUE)
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
	if(active_run != run)
		return
	active_run = null
	dormant_until = world.time + respawn_cooldown
	visible_message(span_warning("[src] shudders as the passage below collapses in on itself!"))

/obj/structure/dungeon_entrance/infinite
	name = "abyssal delve gate"
	desc = "A gate sealing a stairway descending into dark that swallows torchlight. The steps are never quite where they were yesterday."
	icon = 'icons/roguetown/misc/gate.dmi'
	icon_state = "gate1"
	entrance_kind = DUNGEON_ENTRANCE_INFINITE
	bound_width = 96

/obj/structure/dungeon_entrance/infinite/swampgob
	name = "sunken warren gate"
	desc = "A gate sealing a root-torn pit breathing marsh-rot and faint goblin chatter. The dark below is wet and it is listening."
	theme_filter = DUNGEON_THEME_SWAMPGOB

// -- Standalone singlet entrances -----------------------------------------

/obj/structure/dungeon_entrance/bandit_hideout
	name = "smoke-stained hideout mouth"
	desc = "A cramped cut in the earth, reinforced with stolen timber. Boot-mud, cookfire smoke, and fresh whetstone dust mark the way below."
	icon = 'icons/roguetown/misc/dungeon_entrances_64.dmi'
	icon_state = "bandit_hideout"
	pixel_x = -16
	pixel_y = 0
	theme_filter = DUNGEON_THEME_BANDIT
	tier_min = 2
	tier_max = 2

/obj/structure/dungeon_entrance/bear_den
	name = "claw-riven den mouth"
	desc = "A broad cave mouth scored by claws wider than a man's hand. The stones are slick with moss, old blood, and the heat of a great sleeping beast."
	icon = 'icons/roguetown/misc/dungeon_entrances_64.dmi'
	icon_state = "bear_den"
	pixel_x = -16
	pixel_y = 0
	theme_filter = DUNGEON_THEME_BEAR
	tier_min = 3
	tier_max = 3

/obj/structure/dungeon_entrance/ratfolk_camp
	name = "gnawed warrens"
	desc = "A low burrow propped open with splintered planks and filthy tentcloth. Grease smoke curls out beside the sound of quick, clawed feet."
	icon = 'icons/roguetown/misc/dungeon_entrances_64.dmi'
	icon_state = "ratfolk_camp"
	pixel_x = -16
	pixel_y = 0
	theme_filter = DUNGEON_THEME_RATFOLK
	tier_min = 2
	tier_max = 2

/obj/structure/dungeon_entrance/spider_nursery
	name = "silk-choked fissure"
	desc = "A narrow fissure curtained in old web. Cocoon silk tugs softly at the stones, though the air is perfectly still."
	icon = 'icons/roguetown/misc/dungeon_entrances_64.dmi'
	icon_state = "spider_nursery"
	pixel_x = -16
	pixel_y = 0
	theme_filter = DUNGEON_THEME_SPIDER
	tier_min = 1
	tier_max = 1

/obj/structure/dungeon_entrance/werewolf_shrine
	name = "moon-scarred stair"
	desc = "Broken shrine steps descend beneath a crescent gouged into the stone. Cold crystal-light pulses below like a heartbeat."
	icon = 'icons/roguetown/misc/dungeon_entrances_64.dmi'
	icon_state = "werewolf_shrine"
	pixel_x = -16
	pixel_y = 0
	theme_filter = DUNGEON_THEME_WEREWOLF
	tier_min = 3
	tier_max = 3

/obj/structure/dungeon_entrance/wolf_den
	name = "bone-strewn den mouth"
	desc = "A cramped animal trail disappears between damp stones. Tufts of grey fur cling to the rock above a scatter of gnawed bones."
	icon = 'icons/roguetown/misc/dungeon_entrances_64.dmi'
	icon_state = "wolf_den"
	pixel_x = -16
	pixel_y = 0
	theme_filter = DUNGEON_THEME_WOLF
	tier_min = 1
	tier_max = 1
