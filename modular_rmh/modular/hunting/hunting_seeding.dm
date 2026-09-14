// Hunting & Tracking pack - seeding trail heads into the world.
//
// Nothing spawns the first trail head of a chain on its own: hunting_spawner only appears once a
// hunter has already worked a trail, so without seeding the whole hunting half is unreachable.
// Trail heads are therefore scattered by the mapgen flora tables, alongside trees and bushes.
// RMH's mapgen modules are themselves modular, so rather than editing those files this appends to
// their spawn tables at construction. Weights are relative to the surrounding flora entries, which
// run 10-80, so these are deliberately rare.

/// Trail head weight in open, well-travelled country.
#define HUNT_SEED_FIELD 3
/// Denser cover - more game, more sign.
#define HUNT_SEED_WOODS 4
/// The bog and the high snow, where a hunt is the point of going there.
#define HUNT_SEED_WILDS 5

/datum/mapGeneratorModule/rmh_field/New()
	. = ..()
	spawnableAtoms[/obj/effect/hunting_track] = HUNT_SEED_FIELD

/datum/mapGeneratorModule/rmh_fieldgrass/New()
	. = ..()
	spawnableAtoms[/obj/effect/hunting_track] = HUNT_SEED_WOODS

/datum/mapGeneratorModule/rmh_bog/New()
	. = ..()
	spawnableAtoms[/obj/effect/hunting_track] = HUNT_SEED_WILDS

/datum/mapGeneratorModule/rmh_bog/boggrass/New()
	. = ..()
	spawnableAtoms[/obj/effect/hunting_track] = HUNT_SEED_WILDS

/datum/mapGeneratorModule/rmh_mountainssnow/New()
	. = ..()
	spawnableAtoms[/obj/effect/hunting_track] = HUNT_SEED_WILDS

/datum/mapGeneratorModule/rmh_mountainsgrass/New()
	. = ..()
	spawnableAtoms[/obj/effect/hunting_track] = HUNT_SEED_WOODS

// A verb only reaches the admin menus by being in one of the GLOB.admin_verbs_* lists - those are
// what add_admin_verbs() hands out on login, and "set category" alone does nothing. The lists are
// built in core from world.AVerbsDebug() and friends, so the pack appends to the debug one at init,
// the same include-order trick hunting_trait_registry.dm uses. GLOBAL_PROTECT only blocks VV, not
// code.
GLOBAL_LIST_INIT(hunting_debug_verb_registration, register_hunting_debug_verbs())

/proc/register_hunting_debug_verbs()
	GLOB.admin_verbs_debug += /client/proc/spawn_hunting_trail
	return list()

/// Admin/testing helper: drops a fresh trail head under the caller. The hunting chain picks its
/// quarry from whatever area it is standing in, so run this somewhere the categories cover -
/// woods, bog or mountains - or it falls back to small game.
/client/proc/spawn_hunting_trail()
	set name = "Spawn Hunting Trail"
	set category = "Debug"
	set desc = "Places a hunting trail head at your location."
	if(!check_rights(R_DEBUG))
		return
	var/turf/target = get_turf(mob)
	if(!target)
		return
	new /obj/effect/hunting_track(target)
	to_chat(mob, span_notice("Trail head placed at [AREACOORD(target)]. Click it from a tile away to start reading it."))
	log_admin("[key_name(src)] spawned a hunting trail head at [AREACOORD(target)].")

#undef HUNT_SEED_FIELD
#undef HUNT_SEED_WOODS
#undef HUNT_SEED_WILDS
