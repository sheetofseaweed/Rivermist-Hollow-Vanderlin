/// Deluxe bedroll
/obj/item/sleepingbag
	item_weight = 0.63

/obj/item/sleepingbag/deluxe
	icon = 'icons/roguetown/topadd/johnie/amulets backpacks.dmi'
	icon_state = "bedroll"
	item_weight = 0.343

/obj/item/sleepingbag/deluxe/pre_attack_secondary(atom/target, mob/living/user, list/modifiers)
	if(istype(target, /obj/item/storage/backpack/backpack/longhike))
		var/obj/item/storage/backpack/backpack/longhike/deluxepack = target
		deluxepack.add_bedroll(src, user)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	return ..()

/obj/structure/bed/sleepingbag/deluxe
	icon = 'icons/roguetown/topadd/johnie/amulets backpacks.dmi'
	icon_state = "bedroll_turf"
	var/opened = FALSE
	var/initial_icon_state

/obj/structure/bed/sleepingbag/deluxe/Initialize()
	. = ..()
	initial_icon_state = "[initial(icon_state)]" // We need it because our icon_state is going to be overriden in some procs

/obj/structure/bed/sleepingbag/deluxe/MiddleClick(mob/user, list/modifiers)
	if(opened)
		to_chat(user, span_red("The [name] must be zipped shut!"))
		return
	..()

/obj/structure/bed/sleepingbag/deluxe/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	handle_opening()
	update_icon_state()

/obj/structure/bed/sleepingbag/deluxe/user_buckle_mob(mob/living/M, mob/user, check_loc)
	if(!opened)
		to_chat(user, span_red("The [name] is zipped shut!"))
		return
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(H.dna?.species.id in SPECIES_BIG_BODY)
			if(M == user)
				to_chat(user, span_red("I'm too big for the [name]!"))
			else
				to_chat(user, span_red("[M] is too big for the [name]!"))
			return
	. = ..()

/obj/structure/bed/sleepingbag/deluxe/post_buckle_mob(mob/living/M)
	..()
	handle_opening()
	update_appearance(UPDATE_ICON)

/obj/structure/bed/sleepingbag/deluxe/post_unbuckle_mob(mob/living/buckled_mob, force)
	..()
	handle_opening()
	update_appearance(UPDATE_ICON)

/obj/structure/bed/sleepingbag/deluxe/update_icon_state()
	. = ..()
	if(buckled_mobs && length(buckled_mobs))
		icon_state = "[initial_icon_state]_occupied"
	else if(opened)
		icon_state = "[initial_icon_state]_open"
	else
		icon_state = "[initial_icon_state]"

/obj/structure/bed/sleepingbag/deluxe/update_overlays()
	. = ..()
	if(buckled_mobs && length(buckled_mobs))
		var/mutable_appearance/occupied_overlay = mutable_appearance(icon, "[initial_icon_state]_occupied_overlay")
		occupied_overlay.layer = LYING_MOB_LAYER + 0.1 // So that standing mobs would walk over, lying ones crawl under
		occupied_overlay.plane = GAME_PLANE_UPPER
		. += occupied_overlay

/obj/structure/bed/sleepingbag/deluxe/proc/handle_opening(forced = FALSE)
	opened = !opened
	if(forced) // For admin atom proc calls. Just for case
		update_appearance(UPDATE_ICON_STATE)

///////////////////////////////////////////////////////////////
