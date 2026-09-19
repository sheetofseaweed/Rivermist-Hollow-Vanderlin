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
