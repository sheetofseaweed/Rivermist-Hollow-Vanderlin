/// An "affix for rooms": modifies a combat room's encounter at spawn.
/// Traits are stateless shared singletons (see GLOB.dungeon_room_trait_singletons);
/// per-room state lives on the room, never on the trait.
/datum/dungeon_room_trait
	abstract_type = /datum/dungeon_room_trait
	var/name = "Trait"
	var/desc = ""
	/// Shown to occupants when they enter a room with this trait
	var/announce = ""
	var/weight = 10
	var/list/room_kinds = list(DUNGEON_ROOM_COMBAT)
	var/min_floor = 1

/datum/dungeon_room_trait/proc/can_apply(datum/pocket_dimension/dungeon/room)
	return TRUE

/// Pre-spawn: reshape scatter (style filter, extra count). Default no-op.
/datum/dungeon_room_trait/proc/modify_plan(datum/pocket_dimension/dungeon/room)
	return

/// Post-spawn: buff/alter the spawned guardians or the room. Default no-op.
/datum/dungeon_room_trait/proc/apply_to_room(datum/pocket_dimension/dungeon/room)
	return

/// Called when a living player-ish mob enters a room bearing this trait.
/// MUST be idempotent - entry fires from multiple paths (entrance walk-in,
/// gate transfer, re-entry).
/datum/dungeon_room_trait/proc/on_mob_entered(datum/pocket_dimension/dungeon/room, mob/living/target)
	return

/// Idempotent counterpart to on_mob_entered; also fired as a failsafe when the
/// room ejects or tears down.
/datum/dungeon_room_trait/proc/on_mob_exited(datum/pocket_dimension/dungeon/room, mob/living/target)
	return

/// Called when the run clears a combat room bearing this trait.
/datum/dungeon_room_trait/proc/on_room_cleared(datum/dungeon_run/run, datum/pocket_dimension/dungeon/room)
	return

/// Helper: every currently-tracked guardian mob in the room.
/datum/dungeon_room_trait/proc/get_room_guardians(datum/pocket_dimension/dungeon/room)
	var/list/mob/living/guardians = list()
	for(var/g_ref in room.guardian_refs)
		var/datum/weakref/ref = room.guardian_refs[g_ref]
		var/mob/living/guardian = ref?.resolve()
		if(guardian && !QDELETED(guardian))
			guardians += guardian
	return guardians

// -- Post-spawn buff traits (no extra data needed) --

/datum/dungeon_room_trait/emboldened
	name = "Emboldened"
	desc = "The guardians here are unnaturally strong."
	announce = "A cruel pressure fills the room - the guardians here are emboldened."

/datum/dungeon_room_trait/emboldened/apply_to_room(datum/pocket_dimension/dungeon/room)
	for(var/mob/living/guardian as anything in get_room_guardians(room))
		guardian.maxHealth = round(guardian.maxHealth * 1.4)
		guardian.health = guardian.maxHealth

/datum/dungeon_room_trait/enraged
	name = "Enraged"
	desc = "The guardians here move with frenzied speed."
	announce = "Snarls echo - the guardians here are enraged."

/datum/dungeon_room_trait/enraged/apply_to_room(datum/pocket_dimension/dungeon/room)
	for(var/mob/living/guardian as anything in get_room_guardians(room))
		if(istype(guardian, /mob/living/simple_animal/hostile))
			var/mob/living/simple_animal/hostile/animal = guardian
			animal.move_to_delay = max(1, animal.move_to_delay - 1)

/datum/dungeon_room_trait/treasure_laden
	name = "Treasure-laden"
	desc = "Something valuable is hidden here."
	announce = "A glint of hoarded wealth catches your eye."

/datum/dungeon_room_trait/treasure_laden/apply_to_room(datum/pocket_dimension/dungeon/room)
	room.spawn_bonus_loot_cache(sealed = FALSE)

// -- Pre-spawn selection traits (need style tags from Slice 1) --

/datum/dungeon_room_trait/archers_roost
	name = "Archers' Roost"
	desc = "Only ranged foes nest here."
	announce = "Arrows are already nocked in the dark ahead."

/datum/dungeon_room_trait/archers_roost/modify_plan(datum/pocket_dimension/dungeon/room)
	room.scatter_style_override = DUNGEON_STYLE_RANGED

/datum/dungeon_room_trait/brute_hall
	name = "Brute Hall"
	desc = "Only melee bruisers hold this room."
	announce = "Heavy footfalls thud somewhere close."

/datum/dungeon_room_trait/brute_hall/modify_plan(datum/pocket_dimension/dungeon/room)
	room.scatter_style_override = DUNGEON_STYLE_MELEE

/datum/dungeon_room_trait/swarm
	name = "Swarm"
	desc = "A teeming mass of weaker foes."
	announce = "The room churns with movement - a swarm."

/datum/dungeon_room_trait/swarm/modify_plan(datum/pocket_dimension/dungeon/room)
	room.scatter_count_bonus += 4

/datum/dungeon_room_trait/swarm/apply_to_room(datum/pocket_dimension/dungeon/room)
	for(var/mob/living/guardian as anything in get_room_guardians(room))
		guardian.maxHealth = round(max(1, guardian.maxHealth * 0.6))
		guardian.health = guardian.maxHealth

/datum/dungeon_room_trait/captives
	name = "Captives"
	desc = "Someone is chained up in here."
	announce = "A muffled voice pleads from somewhere in the room - captives!"
	weight = 6

/datum/dungeon_room_trait/captives/apply_to_room(datum/pocket_dimension/dungeon/room)
	var/list/turf/open = room.get_open_dungeon_turfs()
	var/count = rand(1, 2)
	for(var/i in 1 to count)
		if(!length(open))
			break
		var/turf/spot = pick(open)
		open -= spot
		var/mob/living/carbon/human/captive = new(spot)
		captive.name = "bound captive"
		captive.real_name = captive.name
		captive.AddComponent(/datum/component/npc_in_distress/dungeon)

/// Distress captive found inside a dungeon: the stock coin reward plus a mote
/// bonus paid to the run that freed them.
/datum/component/npc_in_distress/dungeon

/datum/component/npc_in_distress/dungeon/complete_rescue(mob/living/rescuer)
	. = ..()
	var/turf/here = get_turf(parent)
	if(!here)
		return
	for(var/datum/dungeon_run/run as anything in get_active_dungeon_runs())
		if(run.ending)
			continue
		for(var/datum/pocket_dimension/dungeon/room as anything in run.get_all_rooms())
			if(room.contains_turf(here))
				run.award_motes(15 + (run.floor - 1) * 5, parent)
				return

/datum/dungeon_room_trait/cursed
	name = "Cursed"
	desc = "A dark power's mark lies on this room."
	announce = "Cold dread crawls up your spine - this room is cursed."
	weight = 4
	min_floor = 3

/datum/dungeon_room_trait/cursed/proc/get_mod_id(datum/pocket_dimension/dungeon/room)
	return "dungeon_cursed_[REF(room)]"

/datum/dungeon_room_trait/cursed/on_mob_entered(datum/pocket_dimension/dungeon/room, mob/living/target)
	if(!target.client && !target.mind)
		return
	target.set_stat_modifier(get_mod_id(room), list(STAT_ENDURANCE = -2, STAT_FORTUNE = -10))

/datum/dungeon_room_trait/cursed/on_mob_exited(datum/pocket_dimension/dungeon/room, mob/living/target)
	target.remove_stat_modifier(get_mod_id(room))

/datum/dungeon_room_trait/cursed/on_room_cleared(datum/dungeon_run/run, datum/pocket_dimension/dungeon/room)
	// Compensation: a cursed room bleeds extra light when broken.
	run.award_motes(round((DUNGEON_MOTE_GUARDIAN_BASE + (run.floor - 1) * DUNGEON_MOTE_FLOOR_BONUS) * DUNGEON_CURSED_MOTE_BONUS), null)
	for(var/mob/occupant as anything in room.get_occupants())
		if(occupant.client)
			to_chat(occupant, span_nicegreen("The curse breaks, and its hoarded gilt scatters loose!"))

GLOBAL_LIST_EMPTY(dungeon_room_trait_singletons)

/proc/build_dungeon_room_trait_singletons()
	GLOB.dungeon_room_trait_singletons = list()
	for(var/datum/dungeon_room_trait/trait_type as anything in subtypesof(/datum/dungeon_room_trait))
		if(IS_ABSTRACT(trait_type))
			continue
		GLOB.dungeon_room_trait_singletons += new trait_type

/proc/get_dungeon_room_trait_singleton(trait_type)
	if(!length(GLOB.dungeon_room_trait_singletons))
		build_dungeon_room_trait_singletons()
	for(var/datum/dungeon_room_trait/trait as anything in GLOB.dungeon_room_trait_singletons)
		if(trait.type == trait_type)
			return trait
	return null

/// Builds a weighted pool of eligible trait singletons for a given room.
/// Instances are shared — rooms must never qdel them.
/proc/get_dungeon_room_traits(datum/pocket_dimension/dungeon/room, room_kind)
	if(!length(GLOB.dungeon_room_trait_singletons))
		build_dungeon_room_trait_singletons()
	var/list/pool = list()
	for(var/datum/dungeon_room_trait/trait as anything in GLOB.dungeon_room_trait_singletons)
		if(!(room_kind in trait.room_kinds))
			continue
		if((room.owning_run ? room.owning_run.floor : 1) < trait.min_floor)
			continue
		if(!trait.can_apply(room))
			continue
		pool[trait] = max(1, trait.weight)
	return pool
