/obj/structure/throne
	name = "throne"
	desc = "A big throne, to hold the Lord's giant personality. Say 'help' with the crown on your head if you are confused."
	icon = 'icons/roguetown/misc/96x96.dmi'
	icon_state = "throne"
	density = FALSE
	can_buckle = 1
	SET_BASE_PIXEL(-32, 0)
	max_integrity = 999999
	buckle_lying = FALSE
	obj_flags = NONE
	uses_lord_coloring = LORD_PRIMARY | LORD_SECONDARY
	var/throat_mode = "None"

/obj/structure/throne/post_buckle_mob(mob/living/M)
	..()
	density = TRUE
	M.set_mob_offsets("bed_buckle", _x = 0, _y = 8)

/obj/structure/throne/post_unbuckle_mob(mob/living/M)
	. = ..()
	density = FALSE
	M.reset_offsets("bed_buckle")

/obj/structure/throne/statues	// alt version with more statue but covers side tables less.
	icon = 'icons/roguetown/misc/throne_alt.dmi'

/obj/structure/throne/vthrone
	name = "The Blood Throne"
	desc = "A big ominous throne."
	icon = 'icons/roguetown/misc/vthrone.dmi'

/obj/structure/throne/examine(mob/user)
	. = ..()
	. += span_notice("The current mode is [throat_mode].")

//RMH EDITED START
// Clicking the throne opens the co-located TITAN's command interface. Sitting
// is done by dragging a mob onto the throne (MouseDrop), so attack_hand is free
// and this does not interfere with buckling.
/obj/structure/throne/attack_hand(mob/living/user)
	if(ishuman(user))
		var/obj/structure/fake_machine/titan/titan = locate(/obj/structure/fake_machine/titan) in loc
		if(titan)
			titan.ui_interact(user)
			return TRUE
	return ..()
//RMH EDITED END

/obj/structure/throne/proc/do_filters_glow()
	filters = filter(type = "rays", size = 80, color = "#a38c2e")

/obj/structure/throne/proc/remove_filters_glow()
	filters = null

