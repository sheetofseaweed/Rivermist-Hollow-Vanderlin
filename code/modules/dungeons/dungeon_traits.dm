/// An "affix for rooms": modifies a combat room's encounter at spawn.
/datum/dungeon_room_trait
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
	var/turf/spot = room.get_drop_turf(null)
	if(!spot)
		return
	var/obj/structure/dungeon_loot_cache/cache = new(spot)
	var/datum/map_template/pocket/dungeon/dungeon_template = room.get_dungeon_template()
	if(dungeon_template?.loot_table_type)
		cache.loot = new dungeon_template.loot_table_type
	cache.delve_level = max(1, room.depth)
	cache.unseal() // bonus cache is already open
	room.loot_caches += cache
	room.native_movables[cache] = TRUE

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

/// Builds a weighted pool of trait instances eligible for a given room.
/proc/get_dungeon_room_traits(datum/pocket_dimension/dungeon/room, room_kind)
	var/list/pool = list()
	for(var/trait_type in subtypesof(/datum/dungeon_room_trait))
		var/datum/dungeon_room_trait/trait = new trait_type
		if(!trait.name || trait.name == "Trait")
			qdel(trait)
			continue
		if(!(room_kind in trait.room_kinds))
			qdel(trait)
			continue
		if((room.owning_run ? room.owning_run.floor : 1) < trait.min_floor)
			qdel(trait)
			continue
		if(!trait.can_apply(room))
			qdel(trait)
			continue
		pool[trait] = max(1, trait.weight)
	return pool
