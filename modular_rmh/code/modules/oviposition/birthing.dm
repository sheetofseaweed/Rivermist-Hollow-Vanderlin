// Pushing eggs out and giving birth: a staged, taxing event instead of an instant drop.

#define LABOUR_PHASE_CONTRACTING 1
#define LABOUR_PHASE_PUSHING 2
/// Contractions before the push; each recent birth and each size step past comfort add one.
#define LABOUR_BASE_CONTRACTIONS 3
/// Births inside this window make the next labour longer and harder.
#define LABOUR_FATIGUE_WINDOW (1 HOURS)
#define LABOUR_CONTRACTION_GAP (20 SECONDS)
#define LABOUR_CONTRACTION_GAP_MIN (10 SECONDS)
/// Time between dropping down to push and the passage itself.
#define LABOUR_PUSH_DELAY (6 SECONDS)
/// Stamina each contraction costs, plus this much more per recent birth.
#define LABOUR_CONTRACTION_STAMINA 15
#define LABOUR_FATIGUE_STAMINA 10
/// Soreness every birth leaves on the opening, on top of the passage itself.
#define LABOUR_SORENESS 10
/// Share of the fluid inside that gushes out with a birth.
#define LABOUR_GUSH_SHARE 0.5
/// How long the worn debuff lasts per birth in the window.
#define BIRTH_WORN_TIME (5 MINUTES)
/// One push when pushing an egg out by hand, what it costs, and how many a tight fit may take.
#define EGG_PUSH_TIME (6 SECONDS)
#define EGG_PUSH_STAMINA 20
#define EGG_PUSH_MAX_PUSHES 4
/// Chance per push that an egg past comfort slips back, per unit of strain over one.
#define EGG_PUSH_SLIP_CHANCE 25

/mob/living/carbon
	/// world.time of each recent birth; the count inside the window makes the next one harder.
	var/list/recent_labours

/mob/living/carbon/proc/get_birth_fatigue()
	var/cutoff = world.time - LABOUR_FATIGUE_WINDOW
	while(length(recent_labours) && recent_labours[1] <= cutoff)
		recent_labours.Cut(1, 2)
	return length(recent_labours)

/mob/living/carbon/proc/record_labour()
	LAZYADD(recent_labours, world.time)

/// TRUE while the egg or hatchling holder still sits in this organ's storage.
/proc/is_passenger_inside(obj/item/passenger, obj/item/organ/container)
	if(!passenger || QDELETED(passenger) || !container || QDELETED(container))
		return FALSE
	if(istype(passenger, /obj/item/oviposition_egg))
		return container.is_oviposition_egg(passenger)
	return !!SEND_SIGNAL(container, COMSIG_BODYSTORAGE_FIND_ITEM_LAYER, passenger)

/// The organ that holds this egg for its owner, or null.
/mob/living/carbon/proc/get_passenger_container(obj/item/passenger)
	var/obj/item/organ/container = passenger?.loc
	if(!istype(container) || container.owner != src || !is_passenger_inside(passenger, container))
		return null
	return container

/// Starts labour for a ripe egg or a hatchling; TRUE while labour runs for it.
/mob/living/carbon/proc/start_labour(obj/item/passenger, obj/item/organ/container, voluntary = FALSE)
	if(stat == DEAD || !passenger || !container)
		return FALSE
	var/datum/status_effect/labour/labour = has_status_effect(/datum/status_effect/labour)
	if(labour)
		return labour.passenger_ref?.resolve() == passenger
	labour = apply_status_effect(/datum/status_effect/labour)
	if(!labour)
		return FALSE
	labour.begin(passenger, container, voluntary)
	return TRUE

/// The egg leaves right now, through the opening in front of its host.
/mob/living/carbon/proc/expel_egg_now(obj/item/oviposition_egg/egg, obj/item/organ/container)
	if(!SEND_SIGNAL(container, COMSIG_BODYSTORAGE_TRY_REMOVE, egg, null, BODYSTORAGE_REMOVE_MANUAL))
		return FALSE
	var/obj/item/organ/genitals/filling_organ/canal = container.get_birth_canal()
	if(istype(canal) && canal.orifice_type)
		canal.get_orifice().pass_through(egg.get_insert_girth(), SEX_FORCE_MID, src)
	egg.forceMove(get_turf(src))
	visible_message(span_notice("[src] [container.get_oviposition_lay_verb()] [egg] with a last hard push."), span_love("With a last push, the [egg.name] slides out of my [container.get_oviposition_location_name()]."))
	playsound(src, 'sound/effects/wounds/splatter.ogg', 40, TRUE)
	return TRUE

// ---- Pushing an egg out by hand ----

/// Why an egg cannot be pushed out right now, or null when it can.
/mob/living/carbon/human/proc/get_push_out_block_reason(obj/item/oviposition_egg/egg, obj/item/organ/container)
	if(stat != CONSCIOUS)
		return "I am in no state to push."
	if(incapacitated())
		return "I can't brace myself like this."
	if(has_status_effect(/datum/status_effect/labour))
		return "My body is already pushing."
	if(!egg.can_remove_from_body_storage(BODYSTORAGE_REMOVE_MANUAL))
		return "That one is too deep, or too much a part of me, to push out."
	var/obj/item/organ/genitals/filling_organ/canal = container.get_birth_canal()
	if(!istype(canal) || !canal.orifice_type)
		return null
	// The panel's rules: only armor above light keeps hands off, and a worn device seals its slot.
	if(get_sex_covering_garment(BODY_ZONE_PRECISE_GROIN))
		return "My clothes are in the way."
	if(is_organ_slot_blocked(canal.slot))
		return "Something worn seals the way out."
	var/datum/component/body_storage/passage = canal.GetComponent(/datum/component/body_storage)
	if(passage?.has_layer_insertion_blocker(egg, STORAGE_LAYER_DEEP))
		return "Something plugs the way out."
	var/datum/orifice/opening = canal.get_orifice()
	if(length(opening.get_live_penetrations()))
		return "Not with that inside me."
	if(egg.get_insert_girth() > opening.get_max_girth())
		return "It is too big to pass. I would need more stretching, or something slick."
	return null

/// Pushes one egg out by hand over a few timed pushes; a ripe egg starts a labour instead.
/mob/living/carbon/human/proc/try_push_out_egg(obj/item/oviposition_egg/egg)
	var/obj/item/organ/container = get_passenger_container(egg)
	if(!container)
		return FALSE
	var/reason = get_push_out_block_reason(egg, container)
	if(reason)
		to_chat(src, span_warning(reason))
		return FALSE
	var/datum/component/pregnancy/pregnancy = egg.get_pregnancy_component()
	if(pregnancy && pregnancy.stage >= pregnancy.max_stage)
		return start_labour(egg, container, TRUE)
	INVOKE_ASYNC(src, PROC_REF(push_out_egg), egg, container)
	return TRUE

/// One egg after another; stops at the first that will not come.
/mob/living/carbon/human/proc/push_out_all_eggs(obj/item/organ/organ)
	for(var/obj/item/oviposition_egg/egg as anything in organ.get_oviposition_eggs())
		if(QDELETED(egg) || !is_passenger_inside(egg, organ))
			continue
		var/reason = get_push_out_block_reason(egg, organ)
		if(reason)
			to_chat(src, span_warning(reason))
			return
		var/datum/component/pregnancy/pregnancy = egg.get_pregnancy_component()
		if(pregnancy && pregnancy.stage >= pregnancy.max_stage)
			start_labour(egg, organ, TRUE)
			return
		if(!push_out_egg(egg, organ))
			return

/// Timed pushes with pain and stamina; an egg wider than comfort takes more and may slip back.
/mob/living/carbon/human/proc/push_out_egg(obj/item/oviposition_egg/egg, obj/item/organ/container)
	var/obj/item/organ/genitals/filling_organ/canal = container.get_birth_canal()
	var/datum/orifice/opening = (istype(canal) && canal.orifice_type) ? canal.get_orifice() : null
	var/girth = egg.get_insert_girth()
	var/strain_over = opening ? max(0, opening.get_strain(girth) - 1) : 0
	var/pushes = clamp(1 + round(strain_over * 2), 1, EGG_PUSH_MAX_PUSHES)
	visible_message(span_warning("[src] squats down and strains, bearing down."), span_warning("I squat down and bear down on the [egg.name] inside me..."))
	var/done = 0
	var/attempts = 0
	while(done < pushes)
		if(attempts++ >= EGG_PUSH_MAX_PUSHES * 2)
			to_chat(src, span_warning("I can't get the [egg.name] past the opening. Not like this."))
			return FALSE
		if(!do_after(src, EGG_PUSH_TIME, src, extra_checks = CALLBACK(src, PROC_REF(can_keep_pushing), egg, container)))
			to_chat(src, span_warning("I lose the rhythm, and the [egg.name] settles back inside."))
			return FALSE
		adjust_stamina(EGG_PUSH_STAMINA)
		done++
		opening?.apply_passage_pain(girth * done / pushes, src)
		if(done >= pushes)
			break
		if(strain_over && prob(EGG_PUSH_SLIP_CHANCE * strain_over))
			done = max(0, done - 1)
			to_chat(src, span_warning("It slips back deeper. I have to start that push over."))
			continue
		to_chat(src, span_warning(pick("It moves, barely. I push again.", "I feel it shift lower, pressing against the opening.", "Almost... I bear down harder.")))
	return expel_egg_now(egg, container)

/mob/living/carbon/human/proc/can_keep_pushing(obj/item/oviposition_egg/egg, obj/item/organ/container)
	return stat == CONSCIOUS && !incapacitated() && is_passenger_inside(egg, container)

// ---- Labour ----

/// Contractions, then a push, then the aftermath; another ripe passenger in the same organ follows on.
/datum/status_effect/labour
	id = "labour"
	duration = -1
	tick_interval = 1 SECONDS
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/labour
	var/datum/weakref/passenger_ref
	var/datum/weakref/container_ref
	var/phase = LABOUR_PHASE_CONTRACTING
	var/contractions_done = 0
	var/contractions_needed = LABOUR_BASE_CONTRACTIONS
	var/next_event = 0
	var/births = 0

/datum/status_effect/labour/on_remove()
	passenger_ref = null
	container_ref = null
	return ..()

/datum/status_effect/labour/proc/is_pushing()
	return phase == LABOUR_PHASE_PUSHING

/datum/status_effect/labour/proc/begin(obj/item/passenger, obj/item/organ/container, voluntary = FALSE)
	passenger_ref = WEAKREF(passenger)
	container_ref = WEAKREF(container)
	var/mob/living/carbon/carrier = owner
	var/fatigue = carrier.get_birth_fatigue()
	contractions_needed = LABOUR_BASE_CONTRACTIONS + fatigue + get_size_contractions(passenger, container)
	// Bearing down on purpose skips the long wait but not the work.
	if(voluntary)
		contractions_needed = max(1, round(contractions_needed / 2))
	contractions_done = 0
	phase = LABOUR_PHASE_CONTRACTING
	next_event = world.time + (voluntary ? 2 SECONDS : LABOUR_CONTRACTION_GAP / 2)
	var/location = container.get_oviposition_location_name()
	carrier.visible_message(span_warning("[carrier] goes still and presses a hand to [carrier.p_their()] belly."), span_userdanger("My [location] clenches hard around the [passenger.name]. It is coming."))
	if(fatigue)
		to_chat(carrier, span_warning("My body remembers the last birth too well. This will be harder."))

/// A passenger wider than the opening is comfortable with adds contractions.
/datum/status_effect/labour/proc/get_size_contractions(obj/item/passenger, obj/item/organ/container)
	var/obj/item/organ/genitals/filling_organ/canal = container.get_birth_canal()
	if(!istype(canal) || !canal.orifice_type)
		return 0
	return round(max(0, canal.get_orifice().get_strain(passenger.get_insert_girth()) - 1) * 2)

/datum/status_effect/labour/tick()
	var/mob/living/carbon/carrier = owner
	if(!istype(carrier) || carrier.stat == DEAD)
		qdel(src)
		return
	var/obj/item/passenger = passenger_ref?.resolve()
	var/obj/item/organ/container = container_ref?.resolve()
	if(!container || QDELETED(container) || container.owner != carrier)
		qdel(src)
		return
	if(!is_passenger_inside(passenger, container))
		// It left some other way; carry on with the next one, or rest.
		if(!queue_next(container))
			finish()
		return
	if(world.time < next_event)
		return
	switch(phase)
		if(LABOUR_PHASE_CONTRACTING)
			contract(passenger, container)
		if(LABOUR_PHASE_PUSHING)
			deliver(passenger, container)

/datum/status_effect/labour/proc/contract(obj/item/passenger, obj/item/organ/container)
	var/mob/living/carbon/carrier = owner
	contractions_done++
	var/location = container.get_oviposition_location_name()
	var/self_text
	switch(contractions_done)
		if(1)
			self_text = "A deep cramp rolls through my belly and my [location] tightens. It has begun."
		if(2)
			self_text = "Another contraction, stronger, squeezing the [passenger.name] lower."
		else
			self_text = pick("The contractions come hard and close now. I can hardly breathe between them.", "My whole body bears down on its own. There is no stopping this.")
	carrier.visible_message(span_warning("[carrier] doubles over with a groan, clutching [carrier.p_their()] belly."), span_warning(self_text))
	apply_pain(passenger, container, 0.5)
	carrier.adjust_stamina(LABOUR_CONTRACTION_STAMINA + LABOUR_FATIGUE_STAMINA * carrier.get_birth_fatigue())
	if(contractions_done >= contractions_needed)
		phase = LABOUR_PHASE_PUSHING
		next_event = world.time + LABOUR_PUSH_DELAY
		carrier.visible_message(span_warning("[carrier] drops down, straining, bearing down hard!"), span_userdanger("I can't hold it back any longer. I have to push!"))
		carrier.Knockdown(LABOUR_PUSH_DELAY + 2 SECONDS, TRUE, TRUE)
		return
	next_event = world.time + max(LABOUR_CONTRACTION_GAP_MIN, LABOUR_CONTRACTION_GAP - contractions_done * (3 SECONDS))

/// Pain through the opening in front of the host, scaled by how much of the passenger presses on it.
/datum/status_effect/labour/proc/apply_pain(obj/item/passenger, obj/item/organ/container, share)
	var/obj/item/organ/genitals/filling_organ/canal = container.get_birth_canal()
	if(!istype(canal) || !canal.orifice_type)
		return
	canal.get_orifice().apply_passage_pain(passenger.get_insert_girth() * share, owner)

/datum/status_effect/labour/proc/deliver(obj/item/passenger, obj/item/organ/container)
	var/mob/living/carbon/carrier = owner
	var/delivered = FALSE
	if(istype(passenger, /obj/item/mob_holder/internal_womb))
		var/datum/component/internal_womb_hatchling/hatchling = passenger.GetComponent(/datum/component/internal_womb_hatchling)
		delivered = hatchling?.birth_hatchling()
	else if(istype(passenger, /obj/item/oviposition_egg))
		var/obj/item/oviposition_egg/egg = passenger
		var/datum/component/pregnancy/pregnancy = egg.get_pregnancy_component()
		if(pregnancy && pregnancy.stage >= pregnancy.max_stage)
			delivered = pregnancy.lay_egg(get_turf(carrier), TRUE)
		else
			delivered = carrier.expel_egg_now(egg, container)
	if(!delivered)
		to_chat(carrier, span_warning("I push, but it will not come. My body slackens for a moment."))
		phase = LABOUR_PHASE_CONTRACTING
		contractions_done = max(0, contractions_needed - 1)
		next_event = world.time + LABOUR_CONTRACTION_GAP
		return
	births++
	aftermath(container)
	if(!queue_next(container))
		finish()

/// Every birth leaves the carrier spent, sore and wet, and the next one within the hour harder.
/datum/status_effect/labour/proc/aftermath(obj/item/organ/container)
	var/mob/living/carbon/carrier = owner
	carrier.record_labour()
	var/obj/item/organ/genitals/filling_organ/canal = container.get_birth_canal()
	if(istype(canal) && canal.orifice_type)
		canal.get_orifice().add_soreness(LABOUR_SORENESS)
	var/turf/floor = get_turf(carrier)
	var/list/sources = list(container)
	if(canal != container)
		sources += canal
	for(var/obj/item/organ/genitals/filling_organ/organ in sources)
		if(floor && organ.reagents?.total_volume)
			spill_fluid_to_turf(floor, organ.reagents, organ.reagents.total_volume * LABOUR_GUSH_SHARE, FALSE)
	carrier.adjust_stamina(LABOUR_CONTRACTION_STAMINA * 2)
	carrier.apply_status_effect(/datum/status_effect/birth_worn, BIRTH_WORN_TIME * carrier.get_birth_fatigue())
	to_chat(carrier, span_love(pick("It is out. Warm wetness runs down my thighs and the ache ebbs, slowly.", "The pressure is gone all at once. I lie there, spent and trembling.")))

/// Another ripe egg or a waiting hatchling in the same organ follows on with less work.
/datum/status_effect/labour/proc/queue_next(obj/item/organ/container)
	if(!container || QDELETED(container))
		return FALSE
	var/obj/item/next
	for(var/obj/item/oviposition_egg/egg as anything in container.get_oviposition_eggs(TRUE))
		var/datum/component/pregnancy/pregnancy = egg.get_pregnancy_component()
		if(pregnancy && !egg.hatch_inside_host && pregnancy.stage >= pregnancy.max_stage)
			next = egg
			break
	if(!next)
		var/list/layers = SEND_SIGNAL(container, COMSIG_BODYSTORAGE_GET_LISTS)
		for(var/layer in layers)
			for(var/obj/item/mob_holder/internal_womb/holder in layers[layer])
				var/datum/component/internal_womb_hatchling/hatchling = holder.GetComponent(/datum/component/internal_womb_hatchling)
				if(hatchling?.auto_birth)
					next = holder
					break
			if(next)
				break
	if(!next)
		return FALSE
	passenger_ref = WEAKREF(next)
	phase = LABOUR_PHASE_CONTRACTING
	contractions_done = 0
	contractions_needed = max(1, LABOUR_BASE_CONTRACTIONS - 1)
	next_event = world.time + LABOUR_CONTRACTION_GAP_MIN
	to_chat(owner, span_warning("There is another. My [container.get_oviposition_location_name()] tightens again."))
	return TRUE

/datum/status_effect/labour/proc/finish()
	if(births)
		owner.visible_message(span_notice("[owner] goes limp, breathing hard."), span_love("It is over. I am empty, and so tired."))
	qdel(src)

/atom/movable/screen/alert/status_effect/labour
	name = "In labour"
	desc = "My body is pushing something out. Every contraction costs me."
	icon = 'modular_rmh/icons/mob/screen_alert.dmi'
	icon_state = "impregnation"

/// Slow and sore after a birth; each birth inside the hour adds to it.
/datum/status_effect/birth_worn
	id = "birth_worn"
	duration = BIRTH_WORN_TIME
	tick_interval = STATUS_EFFECT_NO_TICK
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /atom/movable/screen/alert/status_effect/birth_worn
	effectedstats = list("speed" = -1)

/atom/movable/screen/alert/status_effect/birth_worn
	name = "Worn from birth"
	desc = "My body is spent from giving birth. I move slowly, and another so soon would be hard."
	icon = 'modular_rmh/icons/mob/screen_alert.dmi'
	icon_state = "spent_loins"

#undef LABOUR_PHASE_CONTRACTING
#undef LABOUR_PHASE_PUSHING
#undef LABOUR_BASE_CONTRACTIONS
#undef LABOUR_FATIGUE_WINDOW
#undef LABOUR_CONTRACTION_GAP
#undef LABOUR_CONTRACTION_GAP_MIN
#undef LABOUR_PUSH_DELAY
#undef LABOUR_CONTRACTION_STAMINA
#undef LABOUR_FATIGUE_STAMINA
#undef LABOUR_SORENESS
#undef LABOUR_GUSH_SHARE
#undef BIRTH_WORN_TIME
#undef EGG_PUSH_TIME
#undef EGG_PUSH_STAMINA
#undef EGG_PUSH_MAX_PUSHES
#undef EGG_PUSH_SLIP_CHANCE
