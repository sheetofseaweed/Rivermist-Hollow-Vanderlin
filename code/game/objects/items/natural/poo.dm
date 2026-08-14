/// How long the fade-out runs once a dropping's time is up.
#define POO_FADE_TIME (5 SECONDS)

/obj/item/natural/poo
	item_weight = 16 GRAMS
	name = "nitesoil"
	desc = "This smells bad. Excrement from some disgusting individual."
	icon_state = "humpoo"
	dropshrink = 0.75
	throwforce = 0
	resistance_flags = FLAMMABLE
	w_class = WEIGHT_CLASS_TINY
	/// Time lying on open ground before it dissolves, zero keeps it around forever.
	var/dissolve_time = 8 MINUTES
	/// Random spread added on top, so a herd's droppings don't vanish in one wave.
	var/dissolve_variance = 4 MINUTES
	/// Stoppable timer id, only ticking while we sit on a turf.
	var/dissolve_timer

/obj/item/natural/poo/Initialize(mapload)
	. = ..()
	// Hand-placed filth is set dressing, so it stays wherever the mapper put it.
	if(mapload)
		dissolve_time = 0
		return
	start_dissolving()

/obj/item/natural/poo/Destroy()
	stop_dissolving()
	return ..()

/obj/item/natural/poo/Moved(atom/OldLoc, Dir, Forced = FALSE)
	. = ..()
	if(isturf(loc))
		start_dissolving()
	else
		stop_dissolving()

/// Starts the countdown, unless one is already running or we aren't on the ground.
/obj/item/natural/poo/proc/start_dissolving()
	if(dissolve_timer || !dissolve_time || !isturf(loc))
		return
	dissolve_timer = addtimer(CALLBACK(src, PROC_REF(fade_away)), dissolve_time + rand(0, dissolve_variance), TIMER_STOPPABLE)

/// Cancels the countdown and undoes any fade, for when we get picked up or stored.
/obj/item/natural/poo/proc/stop_dissolving()
	if(dissolve_timer)
		deltimer(dissolve_timer)
		dissolve_timer = null
	if(alpha != initial(alpha))
		animate(src, alpha = initial(alpha), time = 0)

/// Sinks out of sight over a few seconds instead of popping away in front of people.
/obj/item/natural/poo/proc/fade_away()
	dissolve_timer = null
	// Fertilizer kept up on a table is spared, and rechecked in case the table goes away.
	if(locate(/obj/structure/table) in loc)
		start_dissolving()
		return
	animate(src, alpha = 0, time = POO_FADE_TIME)
	dissolve_timer = addtimer(CALLBACK(src, PROC_REF(dissolve)), POO_FADE_TIME, TIMER_STOPPABLE)

/obj/item/natural/poo/proc/dissolve()
	dissolve_timer = null
	qdel(src)

/obj/item/natural/poo/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	if(ishuman(hit_atom))
		var/mob/living/carbon/human/H = hit_atom
		playsound(H, 'sound/foley/meatslap.ogg', 100, TRUE)
		if(HAS_TRAIT(H, TRAIT_STINKY))
			H.add_stress(/datum/stress_event/poohit_nice)
		else
			H.add_stress(/datum/stress_event/poohit)
		H.adjust_hygiene(-200)
		qdel(src)

/obj/item/natural/poo/examine(mob/user)
	. = ..()
	if(GET_MOB_SKILL_VALUE_OLD(user, /datum/attribute/skill/labor/farming) >= 3)
		. += span_info("Restores 60 Nitrogen")
		. += span_info("Restores 40 Phosphorus")
		. += span_info("Restores 50 Potassium")

/obj/item/natural/poo/cow
	name = "cow pie"
	desc = "A pie that could not be described as delicious."
	icon_state = "cowpoo"

/obj/item/natural/poo/horse
	name = "droppings"
	desc = "Fecal matter from some animal."
	icon_state = "horsepoo"

// Map these instead of the plain types when hand-placed filth is meant to stay put.
/obj/item/natural/poo/permanent
	dissolve_time = 0

/obj/item/natural/poo/cow/permanent
	dissolve_time = 0

/obj/item/natural/poo/horse/permanent
	dissolve_time = 0

#undef POO_FADE_TIME
