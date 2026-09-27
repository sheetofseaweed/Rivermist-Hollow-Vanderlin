// Heels double as cups while nobody wears them; stepping into a full pair spills it.

/// Units drunk from a heel per sip.
#define HEEL_SIP_AMOUNT 5
/// Time to hold a heel to someone else's mouth.
#define HEEL_FEED_TIME (3 SECONDS)

/obj/item/clothing/shoes/heels
	/// Units of drink one pair of heels holds.
	var/drink_capacity = 20

/obj/item/clothing/shoes/heels/Initialize(mapload, ...)
	. = ..()
	create_reagents(drink_capacity, OPENCONTAINER)

/obj/item/clothing/shoes/heels/is_refillable()
	return !is_worn_as_shoes() && ..()

/obj/item/clothing/shoes/heels/is_drainable()
	return !is_worn_as_shoes() && ..()

/obj/item/clothing/shoes/heels/proc/is_worn_as_shoes()
	var/mob/wearer = loc
	return ismob(wearer) && wearer.get_item_by_slot(ITEM_SLOT_SHOES) == src

/obj/item/clothing/shoes/heels/equipped(mob/user, slot)
	. = ..()
	if((slot & ITEM_SLOT_SHOES) && reagents?.total_volume)
		spill_on_wearer(user)

/// Stepping into full heels squelches the drink out over the floor.
/obj/item/clothing/shoes/heels/proc/spill_on_wearer(mob/living/wearer)
	var/datum/reagent/drink = reagents.get_master_reagent()
	var/drink_name = LOWER_TEXT(drink.name)
	wearer.visible_message(span_warning("[wearer] steps into \the [src], and [drink_name] squelches out all over the floor!"), span_warning("I step into \the [src] and [drink_name] squelches out between my toes!"))
	playsound(wearer, pick('sound/foley/waterwash (1).ogg', 'sound/foley/waterwash (2).ogg'), 40, FALSE)
	spill_fluid_to_turf(get_turf(wearer), reagents, reagents.total_volume, FALSE)

/// A held heel is drunk from when aimed at a mouth, or poured out onto the floor.
/obj/item/clothing/shoes/heels/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!reagents?.total_volume)
		return ..()
	if(isliving(interacting_with) && user.zone_selected == BODY_ZONE_PRECISE_MOUTH)
		return drink_from_heel(interacting_with, user) ? ITEM_INTERACT_SUCCESS : ITEM_INTERACT_BLOCKING
	if(isopenturf(interacting_with))
		user.visible_message(span_notice("[user] pours out \the [src]."), span_notice("I pour out \the [src]."), vision_distance = 2)
		spill_fluid_to_turf(interacting_with, reagents, reagents.total_volume)
		return ITEM_INTERACT_SUCCESS
	return ..()

/obj/item/clothing/shoes/heels/proc/drink_from_heel(mob/living/drinker, mob/living/user)
	if(drinker.is_mouth_covered())
		to_chat(user, span_warning("[drinker == user ? "My" : "[drinker]'s"] mouth is covered."))
		return FALSE
	if(drinker != user && !do_after(user, HEEL_FEED_TIME, drinker))
		return FALSE
	if(!sip_reagents(reagents, drinker, HEEL_SIP_AMOUNT, user))
		return FALSE
	if(drinker == user)
		user.visible_message(span_notice("[user] drinks from \the [src]."), span_notice("I drink from \the [src]."), vision_distance = 2)
	else
		user.visible_message(span_notice("[user] tips \the [src] to [drinker]'s lips."), span_notice("I tip \the [src] to [drinker]'s lips."), vision_distance = 2)
	return TRUE

#undef HEEL_SIP_AMOUNT
#undef HEEL_FEED_TIME
