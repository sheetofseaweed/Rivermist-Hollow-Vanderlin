/area/pocket_dimension
	name = "Pocket Dimension"
	area_flags = NO_TELEPORT | HIDDEN_AREA
	var/datum/pocket_dimension/linked_pocket

/area/pocket_dimension/Destroy(force)
	linked_pocket = null
	return ..()

/// Returns the exact loaded pocket instance containing target, including its sealed reservation border.
/// BYOND shares area datums between loaded copies, so area.linked_pocket cannot identify an instance.
/proc/get_pocket_dimension_at(atom/target)
	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		return null

	var/datum/turf_reservation/pocket_dimension/pocket_reservation = SSmapping.used_turfs[target_turf]
	if(!istype(pocket_reservation) || !pocket_reservation.pocket_instance_ref)
		return null

	var/datum/pocket_dimension/pocket = pocket_reservation.pocket_instance_ref.resolve()
	if(!pocket || QDELETED(pocket))
		return null

	return pocket

/// Removes listeners outside the source's pocket instance from a positional sound audience.
/// The caller resolves the source pocket first so ordinary world sounds pay no per-listener cost.
/proc/filter_pocket_sound_listeners(datum/pocket_dimension/source_pocket, list/listeners)
	if(!source_pocket || !length(listeners))
		return listeners

	for(var/mob/listener in listeners)
		if(get_pocket_dimension_at(listener) != source_pocket)
			listeners -= listener

	return listeners

/area/pocket_dimension/test_chamber
	name = "Pocket Test Chamber"

/area/pocket_dimension/bag_of_holding
	name = "Bag of Holding Cache"

/area/pocket_dimension/magic_closet
	name = "Magic Closet Interior"

/area/pocket_dimension/lighting_test
	name = "Pocket Lighting Test"

/area/pocket_dimension/camp_tent
	name = "Tent Interior"

/area/pocket_dimension/camp_yurt
	name = "Yurt Interior"

/area/pocket_dimension/camp_pavilion
	name = "Pavilion Interior"

/turf/closed/indestructible/pocket_border
	name = "folded-space boundary"
	desc = "Looking at this is making your head hurt."
	icon_state = "shroud1"
