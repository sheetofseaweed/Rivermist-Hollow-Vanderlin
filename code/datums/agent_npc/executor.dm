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
