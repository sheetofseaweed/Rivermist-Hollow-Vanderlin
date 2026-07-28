/obj/structure/pocket_dimension_exit
	name = "return seam"
	desc = "A stable tear in space. Touch it to return to where you entered from."
	icon = 'icons/roguetown/misc/structure.dmi'
	icon_state = "ladder01"
	density = FALSE
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	var/datum/pocket_dimension/linked_pocket

/obj/structure/pocket_dimension_exit/Destroy(force)
	linked_pocket = null
	return ..()

/obj/structure/pocket_dimension_exit/examine(mob/user)
	. = ..()
	. += span_notice("Touch it to step back out of the pocket dimension.")

/obj/structure/pocket_dimension_exit/proc/use_exit(mob/user)
	if(!linked_pocket)
		to_chat(user, span_warning("The seam wavers, but nowhere answers."))
		return
	if(!linked_pocket.can_exit_mob(user, src))
		return
	linked_pocket.exit_mob(user)

/obj/structure/pocket_dimension_exit/attack_hand(mob/user, list/modifiers)
	. = ..()
	use_exit(user)

/obj/structure/pocket_dimension_exit/attack_animal(mob/user, list/modifiers)
	use_exit(user)

/obj/structure/pocket_dimension_exit/attack_paw(mob/user, list/modifiers)
	use_exit(user)

/obj/structure/pocket_dimension_exit/closet
	name = "return wardrobe"
	desc = "A wardrobe door humming with folded space. Touch it to return outside."
	icon = 'icons/roguetown/misc/structure.dmi'
	icon_state = "closet3"
	density = TRUE

/obj/structure/pocket_dimension_exit/hole
	name = "lair exit"
	desc = "Step out and join the hunt."
	icon = 'icons/turf/floors.dmi'
	icon_state = "hole1"
	anchored = TRUE
	pixel_y = 5
	density = TRUE

/obj/structure/pocket_dimension_exit/camp_shelter
	name = "tent flap"
	desc = "The canvas flap you came in through. Push it aside to step back out."
	icon = 'icons/turf/walls.dmi'
	icon_state = "tent_door1"
	density = FALSE
	var/exit_time = 1 SECONDS

// Mirrors the delay on entering a camp shelter. Every attack proc on the parent routes
// through use_exit, so overriding it alone covers hand, paw and animal.
/obj/structure/pocket_dimension_exit/camp_shelter/use_exit(mob/user)
	INVOKE_ASYNC(src, PROC_REF(try_exit), user)

/obj/structure/pocket_dimension_exit/camp_shelter/proc/try_exit(mob/user)
	if(!linked_pocket)
		to_chat(user, span_warning("The flap hangs slack, and nowhere answers."))
		return FALSE
	if(!linked_pocket.can_exit_mob(user, src))
		return FALSE

	user.visible_message(
		span_notice("[user] pushes aside [src]."),
		span_notice("I push aside [src]."),
	)
	if(!do_after(user, exit_time, src))
		return FALSE
	if(QDELETED(src) || QDELETED(user))
		return FALSE
	if(!Adjacent(user))
		to_chat(user, span_warning("I need to stay close to [src] to get out."))
		return FALSE
	if(!linked_pocket || !linked_pocket.can_exit_mob(user, src))
		return FALSE

	// Announce from the flap, not the user: once they are out they are no longer in view
	// of anyone left inside.
	visible_message(span_notice("[user] slips out through [src]."))
	if(!linked_pocket.exit_mob(user))
		return FALSE

	to_chat(user, span_notice("I step back outside."))
	return TRUE
