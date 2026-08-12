// One-way deployment from the Succubus's lair into the mortal world.

/datum/antagonist/succubus
	/// Prevents stacked gateway prompts from racing the one-use deployment flag.
	var/tmp/deployment_prompt_pending = FALSE

/obj/structure/succubus_gateway
	name = "infernal gateway"
	desc = "A rose-purple wound in the air. Beyond it, two paths curl toward the mortal world."
	icon = 'icons/roguetown/topadd/death/vamp-lord.dmi'
	icon_state = "obelisk"
	color = "#D35AB9"
	alpha = 220
	density = FALSE
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	light_system = MOVABLE_LIGHT
	light_outer_range = 3
	light_color = "#C14CB7"

/obj/structure/succubus_gateway/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return
	begin_succubus_deployment(user)
	return TRUE

/obj/structure/succubus_gateway/proc/get_valid_deployment_landmarks(destination_kind)
	var/list/valid_landmarks = list()
	switch(destination_kind)
		if(SUCCUBUS_DEPLOYMENT_OUTSKIRTS)
			for(var/obj/effect/landmark/start/landmark as anything in GLOB.start_landmarks_list)
				if(!istype(landmark, /obj/effect/landmark/start/adventurerlate))
					continue
				var/turf/destination_turf = get_turf(landmark)
				if(!isturf(destination_turf) || destination_turf.density)
					continue
				valid_landmarks += landmark
		if(SUCCUBUS_DEPLOYMENT_SEWERS)
			for(var/obj/effect/landmark/succubus_insertion/sewers/landmark as anything in GLOB.succubus_sewer_insertions)
				var/turf/destination_turf = get_turf(landmark)
				if(QDELETED(landmark) || !isturf(destination_turf) || destination_turf.density)
					continue
				valid_landmarks += landmark
	return valid_landmarks

/obj/structure/succubus_gateway/proc/can_deploy_succubus(mob/living/carbon/human/user, datum/antagonist/succubus/succubus_antag, silent = FALSE)
	if(QDELETED(src) || !istype(user) || QDELETED(user))
		return FALSE
	if(user.stat != CONSCIOUS)
		if(!silent)
			to_chat(user, span_warning("I cannot hold the gateway's paths in my mind while senseless."))
		return FALSE
	if(!isturf(user.loc) || !user.Adjacent(src))
		if(!silent)
			to_chat(user, span_warning("I must stand beside the gateway to choose a path."))
		return FALSE
	if(QDELETED(succubus_antag) || !user.mind || user.mind.has_antag_datum(/datum/antagonist/succubus) != succubus_antag || succubus_antag.owner?.current != user)
		if(!silent)
			to_chat(user, span_warning("The infernal gateway does not answer me."))
		return FALSE
	if(succubus_antag.has_entered_mortal_world)
		if(!silent)
			to_chat(user, span_warning("This gateway has already spent its path into the mortal world. I cannot use it again."))
		return FALSE
	if(isnull(succubus_antag.current_form_key))
		if(!silent)
			to_chat(user, span_warning("I cannot cross in my true flesh. I must weave a mortal disguise first."))
		return FALSE
	if(!length(get_valid_deployment_landmarks(SUCCUBUS_DEPLOYMENT_OUTSKIRTS)))
		if(!silent)
			to_chat(user, span_warning("The path toward the outskirts has collapsed. I cannot enter the mortal world safely."))
		return FALSE
	if(!length(get_valid_deployment_landmarks(SUCCUBUS_DEPLOYMENT_SEWERS)))
		if(!silent)
			to_chat(user, span_warning("The path beneath the town has collapsed. I cannot enter the mortal world safely."))
		return FALSE
	return TRUE

/obj/structure/succubus_gateway/proc/begin_succubus_deployment(mob/living/carbon/human/user)
	var/datum/antagonist/succubus/succubus_antag = IS_SUCCUBUS(user)
	if(!can_deploy_succubus(user, succubus_antag))
		return FALSE
	if(succubus_antag.deployment_prompt_pending)
		to_chat(user, span_warning("The gateway is already waiting for me to choose a path."))
		return FALSE

	succubus_antag.deployment_prompt_pending = TRUE
	INVOKE_ASYNC(src, PROC_REF(prompt_succubus_deployment), WEAKREF(user), WEAKREF(succubus_antag))
	return TRUE

/obj/structure/succubus_gateway/proc/prompt_succubus_deployment(datum/weakref/user_ref, datum/weakref/antag_ref)
	var/mob/living/carbon/human/user = user_ref?.resolve()
	var/datum/antagonist/succubus/succubus_antag = antag_ref?.resolve()
	if(!istype(user) || QDELETED(succubus_antag))
		if(!QDELETED(succubus_antag))
			succubus_antag.deployment_prompt_pending = FALSE
		return FALSE

	var/choice = tgui_alert(
		user,
		"Where will I begin my hunt? This gateway is one-way until a defeated Rift returns me home.",
		"Enter the Mortal World",
		list(SUCCUBUS_DEPLOYMENT_OUTSKIRTS, SUCCUBUS_DEPLOYMENT_SEWERS),
	)
	if(!QDELETED(succubus_antag))
		succubus_antag.deployment_prompt_pending = FALSE
	if(QDELETED(src) || QDELETED(user) || QDELETED(succubus_antag))
		return FALSE
	if(!choice)
		return FALSE
	return complete_succubus_deployment(user, succubus_antag, choice)

/obj/structure/succubus_gateway/proc/complete_succubus_deployment(mob/living/carbon/human/user, datum/antagonist/succubus/succubus_antag, destination_kind)
	if(!can_deploy_succubus(user, succubus_antag))
		return FALSE

	var/list/valid_landmarks = get_valid_deployment_landmarks(destination_kind)
	if(!length(valid_landmarks))
		to_chat(user, span_warning("That path gutters out before I can step through it."))
		return FALSE
	var/obj/effect/landmark/destination_landmark = pick(valid_landmarks)
	var/turf/destination_turf = get_turf(destination_landmark)
	if(!isturf(destination_turf) || destination_turf.density)
		to_chat(user, span_warning("That path twists shut before I can commit to it."))
		return FALSE

	succubus_antag.has_entered_mortal_world = TRUE
	if(!user.forceMove(destination_turf))
		succubus_antag.has_entered_mortal_world = FALSE
		to_chat(user, span_warning("The gateway rejects the crossing. Its paths remain open to me."))
		return FALSE

	src.visible_message(span_boldwarning("Rose-purple fire folds around [user] and draws [user.p_them()] through [src]!"))
	user.visible_message(
		span_warning("Rose-purple fire parts as [user] steps into the mortal world."),
		span_love("The gateway seals behind me. My hunt begins."),
	)
	playsound(user, 'sound/magic/demon_attack1.ogg', 60, TRUE)
	log_game("[key_name(user)] deployed through the Succubus gateway to [destination_kind] at [AREACOORD(user)].")
	return TRUE
