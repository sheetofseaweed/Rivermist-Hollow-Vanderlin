/// The hidden entrances retain outsider discovery by watching and an unrestricted exit.
/// Map gnollhub outside and exit_gnollhub inside, with matching travel tile IDs.
/obj/structure/fluff/traveltile/rmh_cc/gnollhub
	name = "hidden hunting trail"
	desc = "A narrow, well-hidden trail into the pack's wilderness shelter."

/obj/structure/fluff/traveltile/rmh_cc/exit_gnollhub
	name = "trail to the wilderness"
	desc = "An outward trail from the pack's shelter. Follow it to return to the wilderness."

/// Abduction with companions leaves the donor's one-use pursuit opportunity.
/obj/structure/fluff/traveltile/gnoll_hunt_rift
	name = "fading hunting path"
	desc = "A wavering shortcut through the wilderness. There is time for one traveller to follow."
	icon = 'icons/roguetown/misc/structure.dmi'
	icon_state = "shitportal"
	color = "#b58b50"
	aportalid = null
	aportalgoesto = null
	var/datum/weakref/destination_ref
	var/used = FALSE

/obj/structure/fluff/traveltile/gnoll_hunt_rift/Initialize(mapload, turf/destination)
	. = ..()
	destination_ref = WEAKREF(destination)
	QDEL_IN(src, 45 SECONDS)

/obj/structure/fluff/traveltile/gnoll_hunt_rift/Destroy()
	destination_ref = null
	return ..()

/obj/structure/fluff/traveltile/gnoll_hunt_rift/get_other_end_turf(return_travel = FALSE)
	return used ? null : destination_ref?.resolve()

/obj/structure/fluff/traveltile/gnoll_hunt_rift/user_try_travel(mob/living/user)
	var/turf/destination = destination_ref?.resolve()
	if(used || !destination || !user.Adjacent(src) || !can_go(user) || user.incapacitated() || leashed_by_other(user))
		return
	if(!do_after(user, 2 SECONDS, target = src))
		return
	if(QDELETED(src) || QDELETED(user) || used || destination_ref?.resolve() != destination || !user.Adjacent(src) || !can_go(user) || user.incapacitated() || leashed_by_other(user))
		return
	if(do_teleport(user, destination, no_effects = TRUE))
		used = TRUE
		user.recent_travel = world.time
		qdel(src)
