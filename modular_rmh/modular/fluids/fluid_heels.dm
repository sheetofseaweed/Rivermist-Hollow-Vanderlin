// Heels double as cups while nobody wears them; stepping into a full pair spills it.

/// Units drunk from a heel per sip.
#define HEEL_SIP_AMOUNT 5
/// Time to hold a heel to someone else's mouth.
#define HEEL_FEED_TIME (3 SECONDS)
/// Units moved per pouring or filling step, and the time one step takes.
#define HEEL_POUR_AMOUNT 5
#define HEEL_POUR_STEP_TIME (8 DECISECONDS)

/obj/item/clothing/shoes/heels
	// Cup intents: feed drinks or pours, fill scoops from a container, splash throws it.
	possible_item_intents = list(INTENT_POUR, INTENT_FILL, INTENT_SPLASH, /datum/intent/use)
	default_item_intent = INTENT_POUR
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

/// Held heels work like a cup with the feed, fill and splash intents; worn ones do nothing.
/obj/item/clothing/shoes/heels/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(is_worn_as_shoes() || !reagents)
		return ..()
	switch(user.used_intent?.type)
		if(INTENT_POUR)
			if(isliving(interacting_with))
				return drink_from_heel(interacting_with, user) ? ITEM_INTERACT_SUCCESS : ITEM_INTERACT_BLOCKING
			if(isopenturf(interacting_with))
				return pour_out_heel(interacting_with, user) ? ITEM_INTERACT_SUCCESS : ITEM_INTERACT_BLOCKING
			if(interacting_with.reagents && interacting_with.is_refillable())
				return pour_heel_into(interacting_with, user) ? ITEM_INTERACT_SUCCESS : ITEM_INTERACT_BLOCKING
		if(INTENT_FILL)
			if(interacting_with.reagents && interacting_with.is_drainable())
				return fill_heel_from(interacting_with, user) ? ITEM_INTERACT_SUCCESS : ITEM_INTERACT_BLOCKING
		if(INTENT_SPLASH)
			return splash_heel(interacting_with, user) ? ITEM_INTERACT_SUCCESS : ITEM_INTERACT_BLOCKING
	return ..()

/obj/item/clothing/shoes/heels/proc/pour_out_heel(turf/open/target_turf, mob/living/user)
	if(!reagents.total_volume)
		to_chat(user, span_warning("\The [src] is empty."))
		return FALSE
	user.visible_message(span_notice("[user] pours out \the [src]."), span_notice("I pour out \the [src]."), vision_distance = 2)
	spill_fluid_to_turf(target_turf, reagents, reagents.total_volume)
	return TRUE

/// Pours the heel into a container a measure at a time, like pouring from a cup.
/obj/item/clothing/shoes/heels/proc/pour_heel_into(atom/target, mob/living/user)
	if(!reagents.total_volume)
		to_chat(user, span_warning("\The [src] is empty."))
		return FALSE
	if(target.reagents.holder_full())
		to_chat(user, span_warning("\The [target] is full."))
		return FALSE
	user.visible_message(span_notice("[user] pours \the [src] into \the [target]."), span_notice("I pour \the [src] into \the [target]."), vision_distance = 2)
	return move_heel_measures(reagents, target, user, target)

/// Scoops from a drainable container into the heel a measure at a time.
/obj/item/clothing/shoes/heels/proc/fill_heel_from(atom/source, mob/living/user)
	if(!source.reagents.total_volume)
		to_chat(user, span_warning("\The [source] is empty."))
		return FALSE
	if(reagents.holder_full())
		to_chat(user, span_warning("\The [src] is full."))
		return FALSE
	user.visible_message(span_notice("[user] fills \the [src] from \the [source]."), span_notice("I fill \the [src] from \the [source]."), vision_distance = 2)
	return move_heel_measures(source.reagents, src, user, source)

/// Moves measures until the source is empty, the target is full, or the user stops.
/obj/item/clothing/shoes/heels/proc/move_heel_measures(datum/reagents/from, atom/to_atom, mob/living/user, atom/do_after_target)
	var/moved = 0
	while(from.total_volume && !to_atom.reagents.holder_full())
		if(!do_after(user, HEEL_POUR_STEP_TIME, do_after_target))
			break
		if(!from.total_volume || to_atom.reagents.holder_full())
			break
		var/step = from.trans_to(to_atom, HEEL_POUR_AMOUNT, transfered_by = user)
		if(!step)
			break
		moved += step
	return moved > 0

/obj/item/clothing/shoes/heels/proc/splash_heel(atom/target, mob/living/user)
	if(!reagents.total_volume)
		to_chat(user, span_warning("\The [src] is empty."))
		return FALSE
	user.changeNext_move(CLICK_CD_MELEE)
	user.visible_message(span_danger("[user] splashes the contents of \the [src] onto [target]!"), span_danger("I splash the contents of \the [src] onto [target]!"))
	playsound(target, pick('sound/foley/water_land1.ogg', 'sound/foley/water_land2.ogg', 'sound/foley/water_land3.ogg'), 25, TRUE)
	log_combat(user, target, "splashed from heels", reagents.get_reagent_log_string())
	reagents.reaction(target, TOUCH)
	chem_splash(get_turf(target), 2, list(reagents))
	return TRUE

/obj/item/clothing/shoes/heels/proc/drink_from_heel(mob/living/drinker, mob/living/user)
	if(!reagents.total_volume)
		to_chat(user, span_warning("\The [src] is empty."))
		return FALSE
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
#undef HEEL_POUR_AMOUNT
#undef HEEL_POUR_STEP_TIME
