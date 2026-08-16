/**
 * A physical restraint point made by colony defenders.
 *
 * Mappers may place these directly in a lair. Defenders also create them on growth tiles near their
 * core, so a successful haul remains visible and reachable instead of disappearing into a pocket.
 */
/obj/structure/tentacle_growth/nest
	name = "tentacle resin nest"
	desc = "A low cradle of warm, fibrous resin, shaped to hold a struggling captive."
	icon = 'modular_rmh/icons/obj/tentacle_nest.dmi'
	icon_state = "tentacle_nest"
	anchored = TRUE
	density = FALSE
	max_integrity = 120
	resistance_flags = CAN_BE_HIT
	can_buckle = TRUE
	buckle_lying = 0
	buckle_requires_restraints = TRUE
	max_buckled_mobs = 1
	var/static/mutable_appearance/nest_overlay = mutable_appearance('modular_rmh/icons/obj/tentacle_nest.dmi', "nest_overlay", LYING_MOB_LAYER)

/obj/structure/tentacle_growth/nest/Initialize(mapload)
	. = ..()
	icon_state = pick("tentacle_nest", "tentacle_nest2")

/obj/structure/tentacle_growth/nest/user_unbuckle_mob(mob/living/buckled_mob, mob/living/user)
	if(!buckled_mob || buckled_mob.buckled != src || !user || !user.Adjacent(src))
		return FALSE

	var/is_self_rescue = buckled_mob == user
	var/rescue_time = is_self_rescue ? 45 SECONDS : 5 SECONDS
	if(is_self_rescue)
		buckled_mob.visible_message(
			span_warning("[buckled_mob] strains against [src], slowly peeling resin apart!"),
			span_notice("I begin the long struggle out of [src]. I must hold still."),
			span_hear("I hear sticky fibers stretching."),
		)
	else
		buckled_mob.visible_message(
			span_notice("[user] starts tearing [buckled_mob] free from [src]!"),
			span_notice("[user] starts tearing me free from [src]!"),
			span_hear("I hear sticky fibers being pulled apart."),
		)

	if(!do_after(user, rescue_time, src, interaction_key = "tentacle_nest_escape"))
		return FALSE
	if(QDELETED(src) || QDELETED(buckled_mob) || buckled_mob.buckled != src || !user.Adjacent(src))
		return FALSE

	unbuckle_mob(buckled_mob, force = TRUE)
	buckled_mob.visible_message(
		span_notice("[buckled_mob] is pulled free from [src]!"),
		span_notice("I tear free from [src]!"),
		span_hear("I hear resin split with a wet snap."),
	)
	return TRUE

/obj/structure/tentacle_growth/nest/post_buckle_mob(mob/living/buckled_mob)
	. = ..()
	buckled_mob.pixel_x = buckled_mob.base_pixel_x + 2
	buckled_mob.pixel_y = buckled_mob.base_pixel_y
	buckled_mob.layer = BELOW_MOB_LAYER
	add_overlay(nest_overlay)

/obj/structure/tentacle_growth/nest/post_unbuckle_mob(mob/living/buckled_mob)
	. = ..()
	buckled_mob.pixel_x = buckled_mob.get_standard_pixel_x_offset()
	buckled_mob.pixel_y = buckled_mob.get_standard_pixel_y_offset()
	buckled_mob.layer = initial(buckled_mob.layer)
	var/datum/component/kidnap_captivity/captivity = buckled_mob.GetComponent(/datum/component/kidnap_captivity)
	if(captivity?.is_physical_anchor(src))
		captivity.end_captivity()
	buckled_mob.grant_kidnap_release_grace()
	cut_overlay(nest_overlay)
