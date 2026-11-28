/// Floor and water tiles are valid landing surfaces; openspace and hazardous open turfs are not.
/proc/is_valid_anti_magic_field_landing_turf(turf/candidate)
	return isfloorturf(candidate) || istype(candidate, /turf/open/water)

/// Find the nearest adjacent valid turf not occupied by a living mob or dense anchored object.
/proc/find_anti_magic_field_landing_turf(turf/origin, atom/impact_atom)
	if(!origin)
		return null
	var/list/directions = list(NORTH, EAST, SOUTH, WEST, NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST)
	for(var/direction in directions)
		var/turf/candidate = get_step(origin, direction)
		if(!is_valid_anti_magic_field_landing_turf(candidate))
			continue
		if(locate(/mob/living) in candidate)
			continue
		var/occupied = FALSE
		for(var/atom/movable/movable_atom in candidate)
			if(movable_atom == impact_atom)
				continue
			if(movable_atom.anchored && movable_atom.density)
				occupied = TRUE
				break
		if(occupied)
			continue
		return candidate
	return null

/obj/item/rope/net/bola/mantrap/anti_magic_field
	name = "throwable anti-magic field"
	icon = 'modular_rmh/icons/obj/structures/antimagicfield.dmi'
	icon_state = "antimagicthrowable"
	desc = "A compact deployable anti-magic field generator attached to a weighted throwing frame."
	throw_range = 4
	throw_speed = 1.5
	throwforce = 3

/obj/item/rope/net/bola/mantrap/anti_magic_field/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(QDELETED(src) || !hit_atom || QDELETED(hit_atom))
		return

	var/turf/impact_turf = get_turf(hit_atom)
	if(!impact_turf)
		visible_message(span_warning("[src] fails to find a valid landing location and remains intact."))
		return

	var/turf/landing_turf
	if(isclosedturf(hit_atom) || ismovable(hit_atom))
		landing_turf = find_anti_magic_field_landing_turf(impact_turf, hit_atom)
	else if(is_valid_anti_magic_field_landing_turf(impact_turf))
		landing_turf = impact_turf
	else
		landing_turf = find_anti_magic_field_landing_turf(impact_turf, hit_atom)

	if(!landing_turf)
		visible_message(span_warning("[src] strikes an invalid surface; no clear tile is nearby, so it is not deployed."))
		var/mob/thrower = throwingdatum?.get_thrower()
		var/turf/return_turf = get_turf(thrower)
		if(!return_turf)
			return_turf = impact_turf
		forceMove(return_turf)
		return

	if(deploy_anti_magic_field(landing_turf))
		qdel(src)
		return

	visible_message(span_warning("[src] fails to deploy and remains intact."))
	var/mob/thrower = throwingdatum?.get_thrower()
	var/turf/return_turf = get_turf(thrower)
	if(!return_turf)
		return_turf = impact_turf
	forceMove(return_turf)

/// Deploys the generator using the same explicit pattern as mantrap.deploy_beartrap().
/obj/item/rope/net/bola/mantrap/anti_magic_field/proc/deploy_anti_magic_field(turf/landing_turf)
	if(!landing_turf)
		return FALSE
	new /obj/structure/anti_magic_field/throwable(landing_turf)
	visible_message(span_notice("[src] lands and unfolds into an anti-magic field generator!"))
	return TRUE
