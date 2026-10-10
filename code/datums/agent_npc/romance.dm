// Romance: an NPC chooses its own company. The model says yes or takes it back, and DM enforces it.

/// Granted by a profile's romance setting, the way a shop grants haggle.
GLOBAL_LIST_INIT(agent_romance_actions, list("consent", "initiate"))

/// TRUE for a yes, FALSE for a no, null for anything else. Models write "yes", "No" or "agree".
/proc/agent_parse_consent(answer)
	if(!istext(answer))
		return null
	switch(lowertext(trim(answer)))
		if("yes", "y", "agree", "true", "1")
			return TRUE
		if("no", "n", "withdraw", "false", "0")
			return FALSE
	return null

/// Says the answer, or the player never learns it: the model's words, else a nod or shake. TRUE if spoken.
/proc/agent_voice_answer(mob/living/pawn, words, answer)
	if(istext(words) && length(words))
		var/list/said = agent_execute_say(pawn, words)
		if(said["state"] == AGENT_RESULT_SUCCEEDED)
			return said["detail"] == "spoke"
	// Forced, or the throttle left by any recent emote swallows the answer.
	if(!QDELETED(pawn) && pawn.stat < UNCONSCIOUS)
		pawn.emote(answer ? "nod" : "shakehead", forced = TRUE)
	return FALSE

/datum/ai_controller/agent_social
	/// Who the NPC agreed to private time with: weakref -> world.time the agreement lapses.
	var/list/consents
	/// The other side of the act running at the last look, so its end reaches the model once.
	var/datum/weakref/private_partner
	var/romance_timer

/datum/ai_controller/agent_social/proc/romance_enabled()
	return !!profile?.romance

/// When the NPC's yes to them lapses, or 0 if there is none.
/datum/ai_controller/agent_social/proc/consent_until(mob/living/who)
	if(!who)
		return 0
	var/until = LAZYACCESS(consents, WEAKREF(who))
	return (until && until > world.time) ? until : 0

/// Whether any yes is still live.
/datum/ai_controller/agent_social/proc/has_live_consent()
	for(var/datum/weakref/reference as anything in consents)
		if(consents[reference] > world.time)
			return TRUE
	return FALSE

/// The model said yes. The body gets what private time needs, and the watch for its end starts.
/datum/ai_controller/agent_social/proc/grant_consent(mob/living/who)
	LAZYSET(consents, WEAKREF(who), world.time + AGENT_ROMANCE_CONSENT_DURATION)
	var/mob/living/living_pawn = pawn
	living_pawn?.give_genitals()
	start_romance_watch()

/// Taking it back ends any act between them on its next step, since every step asks again.
/datum/ai_controller/agent_social/proc/withdraw_consent(mob/living/who)
	LAZYREMOVE(consents, WEAKREF(who))

/// Why the NPC will not share a scene with them, as words after its name, or null.
/datum/ai_controller/agent_social/proc/romance_refusal(mob/living/other)
	var/mob/living/living_pawn = pawn
	if(!isliving(living_pawn) || living_pawn.stat != CONSCIOUS)
		return "is in no state for that"
	if(in_combat())
		return "is busy fighting"
	if(is_aggressor(other))
		return "will have nothing to do with you after what you did"
	if(!consent_until(other))
		return "has not agreed to that"
	return null

/// Names and minutes left, for the scene the model sees.
/datum/ai_controller/agent_social/proc/describe_consents()
	var/list/agreed = list()
	for(var/datum/weakref/reference as anything in consents)
		var/mob/living/who = reference.resolve()
		var/until = consents[reference]
		if(QDELETED(who) || until <= world.time)
			continue
		agreed += list(list("name" = who.get_visible_name(), "minutes_left" = max(1, CEILING((until - world.time) / (1 MINUTES), 1))))
	return agreed

/// Someone tried to start a scene and was refused. An NPC that may choose hears the ask.
/datum/ai_controller/agent_social/proc/on_scene_refused(datum/source, mob/living/asker)
	SIGNAL_HANDLER
	if(!romance_enabled() || !isliving(asker) || asker == pawn || consent_until(asker))
		return
	if(!binding || QDELETED(binding))
		return
	var/list/detail = list("by" = asker.get_visible_name())
	if(binding.coalesce_event(AGENT_EVENT_PRIVATE_REQUEST, detail))
		return
	binding.note_candidate(asker)
	binding.mark_dirty(AGENT_EVENT_PRIVATE_REQUEST, AGENT_EVENT_LOW, detail, replenish = !isnull(asker.client))

/// The other side of an act involving the NPC, if one is running.
/datum/ai_controller/agent_social/proc/current_private_partner()
	RETURN_TYPE(/mob/living)
	var/mob/living/living_pawn = pawn
	if(!isliving(living_pawn) || QDELETED(living_pawn.sex_scene))
		return null
	for(var/datum/sex_action/action as anything in living_pawn.sex_scene.get_actions_involving(living_pawn))
		var/mob/living/other = action.action_user == living_pawn ? action.action_target : action.action_user
		if(other && other != living_pawn)
			return other
	return null

/datum/ai_controller/agent_social/proc/start_romance_watch()
	if(!romance_timer)
		romance_timer = addtimer(CALLBACK(src, PROC_REF(romance_watch)), AGENT_SERVICE_WATCH_INTERVAL, TIMER_STOPPABLE)

/// While any yes is live or an act runs: tell the model once an act with someone ends.
/datum/ai_controller/agent_social/proc/romance_watch()
	// Called early, a pending look would otherwise run alongside the next one.
	deltimer(romance_timer)
	romance_timer = null
	if(QDELETED(pawn))
		return
	for(var/datum/weakref/reference as anything in consents?.Copy())
		if(consents[reference] <= world.time)
			LAZYREMOVE(consents, reference)
	var/mob/living/partner = current_private_partner()
	var/mob/living/last = private_partner?.resolve()
	if(last && last != partner && binding && !QDELETED(binding))
		binding.note_candidate(last)
		binding.mark_dirty(AGENT_EVENT_PRIVATE_TIME, AGENT_EVENT_LOW, list("by" = last.get_visible_name(), "what" = "spent"), replenish = !isnull(last.client))
	private_partner = partner ? WEAKREF(partner) : null
	if(partner || LAZYLEN(consents))
		start_romance_watch()
