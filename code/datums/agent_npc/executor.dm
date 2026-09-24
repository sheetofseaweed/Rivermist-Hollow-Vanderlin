/**
 * Immediate actions.
 *
 * Speech and emotes are instantaneous and take no movement, so they never enter
 * planning. That is deliberate: routing every utterance through a queued
 * behavior would make the agent take exclusive ownership of the pawn just to
 * say a sentence.
 */

/**
 * Strip anything say() would read as a mode key.
 *
 * say() parses leading characters into whisper, sing, radio, language and
 * emote before it ever treats the text as speech. Agent output is plain speech
 * or nothing.
 */
/proc/agent_sanitise_speech(text)
	var/static/list/mode_prefixes = list("#", "%", ";", ",", "*", ":", ".")
	if(!istext(text))
		return null

	var/cleaned = trim(text)
	while(length(cleaned) && (copytext_char(cleaned, 1, 2) in mode_prefixes))
		cleaned = trim(copytext_char(cleaned, 2))

	cleaned = copytext_char(cleaned, 1, MAX_MESSAGE_LEN)
	return length(cleaned) ? cleaned : null

/proc/agent_result(state, detail)
	return list("state" = state, "detail" = detail)

/proc/agent_execute_say(mob/living/pawn, text)
	if(QDELETED(pawn) || !isliving(pawn))
		return agent_result(AGENT_RESULT_REJECTED, "no pawn to speak with")
	if(pawn.stat >= UNCONSCIOUS)
		return agent_result(AGENT_RESULT_REJECTED, "cannot speak right now")

	var/cleaned = agent_sanitise_speech(text)
	if(!cleaned)
		return agent_result(AGENT_RESULT_REJECTED, "nothing left after sanitising")

	// say() only runs the IC filter when a client is present, so a clientless
	// agent pawn bypasses it entirely. Run it here or it never runs.
	if(CHAT_FILTER_CHECK(cleaned))
		return agent_result(AGENT_RESULT_REJECTED, "blocked by the IC filter")

	pawn.say(cleaned, forced = TRUE)
	return agent_result(AGENT_RESULT_SUCCEEDED, "spoke")

/proc/agent_execute_emote(mob/living/pawn, key)
	// Closed allowlist of verified keys. An agent cannot reach arbitrary emotes.
	var/static/list/allowed = list("wave", "nod", "shrug", "smile", "laugh", "sigh", "frown", "bow")

	if(QDELETED(pawn) || !isliving(pawn))
		return agent_result(AGENT_RESULT_REJECTED, "no pawn to emote with")
	if(pawn.stat >= UNCONSCIOUS)
		return agent_result(AGENT_RESULT_REJECTED, "cannot emote right now")
	if(!(key in allowed))
		return agent_result(AGENT_RESULT_REJECTED, "emote is not on the allowlist")

	pawn.emote(key, intentional = TRUE)
	// emote() reports nothing useful back, so this is dispatched, not verified.
	return agent_result(AGENT_RESULT_UNVERIFIED, "emote dispatched")

/// Every way the touch action may lay a hand on someone. Kisses and worse are not the model's to start.
/proc/agent_touch_ways()
	return list(AGENT_TOUCH_TAP, AGENT_TOUCH_HUG, AGENT_TOUCH_HEADPAT, AGENT_TOUCH_HELP)

/// Lay a hand on someone without clicking them, so a held knife can never turn a pat into a stab.
/proc/agent_execute_touch(mob/living/pawn, mob/living/target, way)
	if(QDELETED(pawn) || QDELETED(target))
		return agent_result(AGENT_RESULT_FAILED, "they are gone")
	if(pawn.stat >= UNCONSCIOUS || HAS_TRAIT(pawn, TRAIT_HANDS_BLOCKED))
		return agent_result(AGENT_RESULT_REJECTED, "cannot reach out right now")
	if(!pawn.Adjacent(target))
		return agent_result(AGENT_RESULT_FAILED, "not close enough to touch")

	var/target_name = target.get_visible_name()
	switch(way)
		if(AGENT_TOUCH_HELP)
			if(target.body_position != LYING_DOWN || !iscarbon(target) || !iscarbon(pawn))
				return agent_result(AGENT_RESULT_REJECTED, "they are not lying down")
			// Async: rescuing someone from defeat runs a do_after, and a behavior must not sleep.
			INVOKE_ASYNC(target, TYPE_PROC_REF(/mob/living/carbon, help_shake_act), pawn)
			return agent_result(AGENT_RESULT_UNVERIFIED, "reached down to help them")
		if(AGENT_TOUCH_HUG, AGENT_TOUCH_HEADPAT)
			var/datum/emote/gesture = agent_emote_datum(way)
			if(!gesture)
				return agent_result(AGENT_RESULT_REJECTED, "that gesture does not exist here")
			// Emote first, the effect only if it happened: a refused hug must not play its sound.
			if(!gesture.run_emote(pawn, target_name, null, TRUE))
				return agent_result(AGENT_RESULT_FAILED, "could not [way] them")
			gesture.adjacentaction(pawn, target)
			return agent_result(AGENT_RESULT_SUCCEEDED, "[way] given")
		if(AGENT_TOUCH_TAP)
			var/datum/emote/custom = agent_emote_datum("me")
			if(!custom || !custom.run_emote(pawn, "taps [target_name] on the shoulder.", null, TRUE))
				return agent_result(AGENT_RESULT_FAILED, "could not tap them")
			return agent_result(AGENT_RESULT_SUCCEEDED, "tapped them")
	return agent_result(AGENT_RESULT_REJECTED, "not a way to touch someone")

/// The emote datum behind a key, or null.
/proc/agent_emote_datum(key)
	for(var/datum/emote/candidate in GLOB.emote_list[key])
		return candidate
	return null

/// Chairs, stools, benches, beds and thrones. Never stocks, pillories or hooks, which also buckle.
/proc/agent_is_seat(atom/thing)
	var/static/list/seats = typecacheof(list(/obj/structure/chair, /obj/structure/bed, /obj/structure/throne))
	if(!is_type_in_typecache(thing, seats))
		return FALSE
	var/atom/movable/seat = thing
	return seat.can_buckle

/// Drop leading words that are the NPC's own name. The game already starts the emote with it.
/proc/agent_strip_own_name(mob/living/pawn, text)
	var/list/parts = list()
	for(var/part in agent_name_tokens(pawn.get_visible_name()))
		parts[lowertext(part)] = TRUE
	var/list/words = splittext(text, " ")
	while(length(words) > 1 && parts[lowertext(agent_trim_punctuation(words[1]))])
		words.Cut(1, 2)
	return jointext(words, " ")

/// The NPC's own custom emote: a small action in its own words, never speech.
/proc/agent_execute_me(mob/living/pawn, text)
	if(QDELETED(pawn) || !isliving(pawn))
		return agent_result(AGENT_RESULT_REJECTED, "no pawn to act with")
	if(pawn.stat >= UNCONSCIOUS)
		return agent_result(AGENT_RESULT_REJECTED, "cannot act right now")
	var/cleaned = agent_clean_emote_text(text)
	if(cleaned)
		cleaned = trim(copytext_char(agent_strip_own_name(pawn, cleaned), 1, AGENT_ME_TEXT_MAX + 1))
	if(!length(cleaned))
		return agent_result(AGENT_RESULT_REJECTED, "nothing left after cleaning")
	// Words belong in say, which runs language and the speech filters. An emote that talks skips both.
	var/static/list/speech_verbs = list("says", "exclaims", "yells", "asks", "shouts", "whispers")
	if(lowertext(agent_trim_punctuation(splittext(cleaned, " ")[1])) in speech_verbs)
		return agent_result(AGENT_RESULT_REJECTED, "speech goes through say, not me")
	// say() only filters for clients, and a clientless emote is never filtered at all.
	if(CHAT_FILTER_CHECK(cleaned))
		return agent_result(AGENT_RESULT_REJECTED, "blocked by the IC filter")
	var/datum/emote/custom = agent_emote_datum("me")
	// Encoded as the me verb does, because the text lands in chat as HTML.
	if(!custom?.run_emote(pawn, html_encode(cleaned), EMOTE_VISIBLE, TRUE))
		return agent_result(AGENT_RESULT_FAILED, "could not act")
	return agent_result(AGENT_RESULT_SUCCEEDED, "acted")

/// Get off a seat. Restraints are not a seat, and resisting them is the reflexes' job.
/proc/agent_execute_stand(mob/living/pawn)
	var/atom/movable/seat = pawn?.buckled
	if(!seat)
		return agent_result(AGENT_RESULT_REJECTED, "you are not sitting")
	if(!agent_is_seat(seat))
		return agent_result(AGENT_RESULT_REJECTED, "you are held there, not sitting")
	if(!seat.user_unbuckle_mob(pawn, pawn))
		return agent_result(AGENT_RESULT_FAILED, "could not get up")
	return agent_result(AGENT_RESULT_SUCCEEDED, "got up")

/// Sit on a seat the NPC is beside. Records it, so the resist reflex leaves a chosen seat alone.
/proc/agent_execute_sit(datum/ai_controller/controller, mob/living/pawn, atom/movable/seat)
	if(QDELETED(seat) || !agent_is_seat(seat))
		return agent_result(AGENT_RESULT_REJECTED, "that is not something to sit on")
	if(pawn.buckled == seat)
		controller.set_blackboard_key(BB_AGENT_SEAT, seat)
		return agent_result(AGENT_RESULT_SUCCEEDED, "already there")
	if(pawn.buckled)
		agent_execute_stand(pawn)
	if(LAZYLEN(seat.buckled_mobs) >= seat.max_buckled_mobs)
		return agent_result(AGENT_RESULT_FAILED, "someone is already there")
	if(!seat.user_buckle_mob(pawn, pawn, check_loc = FALSE))
		return agent_result(AGENT_RESULT_FAILED, "could not get onto it")
	controller.set_blackboard_key(BB_AGENT_SEAT, seat)
	return agent_result(AGENT_RESULT_SUCCEEDED, seat.buckleverb == "lay" ? "lying on it" : "sitting on it")

/// Hold a carried item out to someone, the way the give key does. They take it or it lapses.
/proc/agent_execute_give(mob/living/pawn, mob/living/target, obj/item/item)
	if(QDELETED(target) || !isliving(target) || target == pawn)
		return agent_result(AGENT_RESULT_FAILED, "they are gone")
	if(QDELETED(item) || !(item in pawn.held_items))
		return agent_result(AGENT_RESULT_FAILED, "you are no longer holding it")
	if(!pawn.Adjacent(target))
		return agent_result(AGENT_RESULT_FAILED, "not close enough to hand it over")
	if(pawn.get_active_held_item() != item)
		pawn.swap_hand()
	if(pawn.get_active_held_item() != item)
		return agent_result(AGENT_RESULT_FAILED, "could not get it into your hand")
	pawn.give(target)
	if(pawn.offered_item_ref?.resolve() != item)
		return agent_result(AGENT_RESULT_FAILED, "could not hold it out")
	return agent_result(AGENT_RESULT_SUCCEEDED, "holding it out; they have to take it")

/// The offer someone is making to the NPC now, or null. Checked on the offer itself, so none is misdirected.
/proc/agent_offer_to(mob/living/pawn, mob/living/offerer)
	RETURN_TYPE(/obj/effect/temp_visual/offered_item_effect)
	for(var/obj/effect/temp_visual/offered_item_effect/offer in range(1, pawn))
		if(offer.fading_out || offer.offerer_weak_ref?.resolve() != offerer)
			continue
		if(offer.offered_to_weak_ref?.resolve() != pawn)
			continue
		return offer
	return null

/// Accept what someone holds out, into a free hand. The offerer stays put, so no walking.
/proc/agent_execute_take(mob/living/pawn, mob/living/offerer)
	if(QDELETED(pawn) || QDELETED(offerer))
		return agent_result(AGENT_RESULT_FAILED, "they are gone")
	var/obj/effect/temp_visual/offered_item_effect/offer = agent_offer_to(pawn, offerer)
	var/obj/item/offered = offer?.offered_thing_weak_ref?.resolve()
	if(QDELETED(offered))
		return agent_result(AGENT_RESULT_REJECTED, "they are not offering you anything")
	if(pawn.get_active_held_item() && !pawn.get_inactive_held_item())
		pawn.swap_hand()
	if(pawn.get_active_held_item())
		return agent_result(AGENT_RESULT_FAILED, "your hands are full")
	if(!pawn.try_accept_offered_item(offerer, offered, offer.stealthy) || offered.loc != pawn)
		return agent_result(AGENT_RESULT_FAILED, "could not take it")
	return agent_result(AGENT_RESULT_SUCCEEDED, "took the [offered.name]")
