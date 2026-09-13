/// Basic targeting which also permits dense, destructible structures.
/datum/targetting_datum/basic/allow_structures/can_attack(mob/living/living_mob, atom/the_target)
	if(!isobj(the_target))
		return ..()

	var/obj/structure_target = the_target
	if(!living_mob || living_mob.see_invisible < structure_target.invisibility)
		return FALSE
	if(HAS_TRAIT(structure_target, TRAIT_IMPERCEPTIBLE))
		return FALSE
	if(!isturf(structure_target.loc) || !structure_target.density)
		return FALSE
	if(structure_target.resistance_flags & INDESTRUCTIBLE)
		return FALSE
	return TRUE
