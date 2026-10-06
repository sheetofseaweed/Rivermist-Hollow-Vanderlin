// Initiative: the model picks the moment and how far; DM picks the act and always asks first.

/// The gentlest advances: nothing below the waist.
GLOBAL_LIST_INIT(agent_advance_tender_acts, list(
	/datum/sex_action/kissing,
	/datum/sex_action/rub_body,
	/datum/sex_action/masturbate/other/breasts,
	/datum/sex_action/suck_nipples,
))

/// The levels a model may name, as ranks.
GLOBAL_LIST_INIT(agent_advance_levels, list("tender" = AGENT_ADVANCE_TENDER, "intimate" = AGENT_ADVANCE_INTIMATE, "rough" = AGENT_ADVANCE_ROUGH))

/proc/agent_parse_advance_level(key)
	if(!istext(key))
		return null
	return GLOB.agent_advance_levels[lowertext(trim(key))]

/proc/agent_advance_level_name(rank)
	for(var/name in GLOB.agent_advance_levels)
		if(GLOB.agent_advance_levels[name] == rank)
			return name
	return null

/// The acts DM may pick from at one level: the performer's house lists, split by how far they go.
/proc/agent_advance_acts(rank)
	switch(rank)
		if(AGENT_ADVANCE_TENDER)
			return GLOB.agent_advance_tender_acts
		if(AGENT_ADVANCE_INTIMATE)
			return GLOB.agent_service_acts - GLOB.agent_advance_tender_acts
		if(AGENT_ADVANCE_ROUGH)
			return GLOB.agent_service_rough_acts
	return list()

/// An act's menu name, turned to the one it is offered to: "Ride them" becomes "ride you".
/proc/agent_advance_phrase(act_type)
	var/static/regex/them = regex(@"\bthem\b", "g")
	var/static/regex/their = regex(@"\btheir\b", "g")
	var/datum/sex_action/typed = act_type
	var/name = their.Replace(them.Replace("[initial(typed.name)]", "you"), "your")
	return lowertext(copytext(name, 1, 2)) + copytext(name, 2)

/// A player may always stop what an agent NPC does to them. Other NPCs keep the old rule.
/proc/agent_act_stoppable_by(datum/sex_action/action, mob/living/who)
	if(!action || !who || action.action_target != who || action.action_user == who)
		return FALSE
	return istype(action.action_user?.ai_controller, /datum/ai_controller/agent_social)

/// What one partner has said to this NPC's advances.
/datum/agent_advance_record
	/// world.time before which the NPC may not advance again, after a no.
	var/next_allowed = 0
	/// world.time until which they asked it to stop asking.
	var/blocked_until = 0
	/// Their standing yes: the furthest level it may lead without asking, and until when.
	var/standing_rank = 0
	var/standing_until = 0
	/// Rough is only offered after they welcomed something intimate.
	var/welcomed_intimate = FALSE
	/// Their popup is open until then. A time, not a flag, so a popup that errors cannot block advances forever.
	var/pending_until = 0

/datum/ai_controller/agent_social
	/// weakref -> /datum/agent_advance_record.
	var/list/advance_records
	/// The act the NPC led last, so the next advance picks something else when it can.
	var/last_advance_act

/datum/ai_controller/agent_social/proc/advance_record(mob/living/partner)
	RETURN_TYPE(/datum/agent_advance_record)
	var/datum/weakref/reference = WEAKREF(partner)
	var/datum/agent_advance_record/record = LAZYACCESS(advance_records, reference)
	if(!record)
		record = new()
		LAZYSET(advance_records, reference, record)
	return record

/// Only on someone the NPC said yes to, or a paying customer.
/datum/ai_controller/agent_social/proc/may_advance_on(mob/living/partner)
	return !!(consent_until(partner) || (partner && partner == paying_customer()))

/// Why the NPC may not advance on them now, or null.
/datum/ai_controller/agent_social/proc/advance_refusal(mob/living/partner, rank)
	if(!isliving(partner) || partner == pawn)
		return "advances are for a person, by their handle"
	if(!rank)
		return "key must be tender, intimate or rough"
	if(!may_advance_on(partner))
		return "they have not agreed to private time with you"
	if(in_combat())
		return "you are fighting"
	if(is_aggressor(partner))
		return "not after what they did to you"
	var/datum/agent_advance_record/record = advance_record(partner)
	if(record.pending_until > world.time)
		return "you are already waiting for their answer"
	if(record.blocked_until > world.time)
		return "they asked you not to try anything for now"
	if(record.next_allowed > world.time)
		return "wait a little before trying again"
	if(rank >= AGENT_ADVANCE_ROUGH && !record.welcomed_intimate)
		return "rough only after they have welcomed something intimate"
	if(!pawn.Adjacent(partner))
		return "they are not close enough; approach them first"
	return null

/// The model's advance. DM picks the act; a standing yes starts it, else the partner is asked. Returns the outcome.
/datum/ai_controller/agent_social/proc/make_advance(mob/living/partner, key)
	var/rank = agent_parse_advance_level(key)
	var/refusal = advance_refusal(partner, rank)
	if(refusal)
		return list("state" = AGENT_RESULT_REJECTED, "detail" = refusal)
	var/act_type = pick_advance_act(partner, rank)
	if(!act_type)
		return list("state" = AGENT_RESULT_REJECTED, "detail" = "nothing like that fits the two of you right now")
	var/level = agent_advance_level_name(rank)
	var/datum/agent_advance_record/record = advance_record(partner)
	if(record.standing_rank >= rank && record.standing_until > world.time)
		if(!start_advance_act(partner, act_type, rank))
			return list("state" = AGENT_RESULT_FAILED, "detail" = "it did not start")
		log_game("Agent NPC [key_name(pawn)] led [key_name(partner)] in [act_type] on their standing yes at [AREACOORD(pawn)].")
		return list("state" = AGENT_RESULT_SUCCEEDED, "detail" = "you took the lead ([level]); [partner.get_visible_name()] had already said yes for a while")
	if(!partner.client)
		return list("state" = AGENT_RESULT_REJECTED, "detail" = "they cannot be asked right now")
	record.pending_until = world.time + AGENT_ADVANCE_ANSWER_TIME + 5 SECONDS
	log_game("Agent NPC [key_name(pawn)] asked [key_name(partner)] for [act_type] ([level]) at [AREACOORD(pawn)].")
	INVOKE_ASYNC(src, PROC_REF(ask_advance), partner, act_type, rank)
	return list("state" = AGENT_RESULT_SUCCEEDED, "detail" = "you made a [level] advance to [partner.get_visible_name()]; they are deciding")

/// An act at this level that both bodies allow now, never the last one when there is a choice.
/datum/ai_controller/agent_social/proc/pick_advance_act(mob/living/partner, rank)
	var/mob/living/living_pawn = pawn
	var/datum/sex_scene_controller/controller = living_pawn.open_sex_scene(partner, FALSE)
	if(!controller)
		return null
	var/list/weighted = list()
	for(var/act_type in agent_advance_acts(rank))
		var/datum/sex_action_proposal/proposal = controller.create_action_proposal(act_type, "ai")
		if(proposal?.can_start())
			weighted[act_type] = max(1, proposal.get_pattern_desirability())
		qdel(proposal)
	if(length(weighted) > 1)
		weighted -= last_advance_act
	return length(weighted) ? pickweight(weighted) : null

/// The question, in the partner's own window. It sleeps until they answer.
/datum/ai_controller/agent_social/proc/ask_advance(mob/living/partner, act_type, rank)
	var/question = "[pawn.name] wants to [agent_advance_phrase(act_type)].\n\n\"[AGENT_ADVANCE_YES_FOR_A_WHILE]\" lets [pawn.name] lead like this without asking, for [round(AGENT_ADVANCE_STANDING_DURATION / (1 MINUTES))] minutes. \"[AGENT_ADVANCE_STOP_ASKING]\" stops these advances for as long."
	var/answer = tgui_alert(partner, question, "[pawn.name]", list(AGENT_ADVANCE_YES, AGENT_ADVANCE_YES_FOR_A_WHILE, AGENT_ADVANCE_NO, AGENT_ADVANCE_STOP_ASKING), AGENT_ADVANCE_ANSWER_TIME)
	if(QDELETED(src))
		return
	resolve_advance(partner, act_type, rank, answer)

/// The partner's answer. A yes starts the act at once; anything else holds the NPC back for a while.
/datum/ai_controller/agent_social/proc/resolve_advance(mob/living/partner, act_type, rank, answer)
	if(QDELETED(partner) || QDELETED(pawn))
		return
	var/datum/agent_advance_record/record = advance_record(partner)
	record.pending_until = 0
	var/heard
	switch(answer)
		if(AGENT_ADVANCE_YES, AGENT_ADVANCE_YES_FOR_A_WHILE)
			heard = (answer == AGENT_ADVANCE_YES) ? "yes" : "yes_for_a_while"
			if(answer == AGENT_ADVANCE_YES_FOR_A_WHILE)
				record.standing_rank = max(record.standing_rank, rank)
				record.standing_until = world.time + AGENT_ADVANCE_STANDING_DURATION
			if(rank >= AGENT_ADVANCE_INTIMATE)
				record.welcomed_intimate = TRUE
			// Things may have changed while they thought about it.
			if(!may_advance_on(partner) || !pawn.Adjacent(partner) || !start_advance_act(partner, act_type, rank))
				heard = "too_late"
		if(AGENT_ADVANCE_STOP_ASKING)
			heard = "stop_asking"
			record.blocked_until = world.time + AGENT_ADVANCE_STANDING_DURATION
			record.standing_until = 0
		if(AGENT_ADVANCE_NO)
			heard = "no"
			record.next_allowed = world.time + AGENT_ADVANCE_DECLINE_COOLDOWN
		else
			heard = "no_answer"
			record.next_allowed = world.time + AGENT_ADVANCE_DECLINE_COOLDOWN
	log_game("[key_name(partner)] answered agent NPC [key_name(pawn)]'s advance ([act_type]): [heard].")
	note_advance_event(partner, heard, rank)

/// The NPC leads the act it offered. It stops by itself after AGENT_ADVANCE_ACT_CAP if nothing ends it sooner.
/datum/ai_controller/agent_social/proc/start_advance_act(mob/living/partner, act_type, rank)
	var/mob/living/living_pawn = pawn
	var/datum/sex_scene_controller/controller = living_pawn.open_sex_scene(partner, FALSE)
	if(!controller)
		return null
	controller.stop_action()
	living_pawn.face_atom(partner)
	controller.set_current_force(rank >= AGENT_ADVANCE_ROUGH ? SEX_FORCE_HIGH : (rank >= AGENT_ADVANCE_INTIMATE ? SEX_FORCE_MID : SEX_FORCE_LOW))
	controller.set_current_speed(rank >= AGENT_ADVANCE_ROUGH ? SEX_SPEED_HIGH : SEX_SPEED_MID)
	var/datum/sex_action/started = controller.try_start_action(act_type, "ai")
	if(!started)
		return null
	last_advance_act = act_type
	addtimer(CALLBACK(src, PROC_REF(end_advance_act), WEAKREF(started)), AGENT_ADVANCE_ACT_CAP, TIMER_STOPPABLE)
	// Their own scene window, where one click stops what the NPC is doing.
	if(partner.client)
		partner.open_sex_scene(living_pawn)
	if(romance_enabled())
		start_romance_watch()
	return started

/// The cap on an act the NPC leads.
/datum/ai_controller/agent_social/proc/end_advance_act(datum/weakref/act_ref)
	var/datum/sex_action/act = act_ref?.resolve()
	if(QDELETED(act) || QDELETED(act.scene))
		return
	act.scene.stop_action(act)

/// The partner stopped an act the NPC led. It counts as a no, so the NPC waits before trying again.
/datum/ai_controller/agent_social/proc/on_act_stopped_by_partner(datum/source, mob/living/stopper)
	SIGNAL_HANDLER
	if(!isliving(stopper) || stopper == pawn)
		return
	advance_record(stopper).next_allowed = world.time + AGENT_ADVANCE_DECLINE_COOLDOWN
	note_advance_event(stopper, "stopped")

/datum/ai_controller/agent_social/proc/note_advance_event(mob/living/partner, answer, rank)
	if(!binding || QDELETED(binding) || QDELETED(partner))
		return
	var/list/detail = list("by" = partner.get_visible_name(), "answer" = answer)
	var/level = agent_advance_level_name(rank)
	if(level)
		detail["level"] = level
	binding.note_candidate(partner)
	binding.mark_dirty(AGENT_EVENT_ADVANCE, AGENT_EVENT_LOW, detail, replenish = !isnull(partner.client))

/// Standing yeses and "stop asking"s still in force, for the scene the model sees.
/datum/ai_controller/agent_social/proc/describe_advances()
	var/list/described = list()
	for(var/datum/weakref/reference as anything in advance_records)
		var/mob/living/partner = reference.resolve()
		var/datum/agent_advance_record/record = advance_records[reference]
		if(QDELETED(partner) || !record)
			continue
		var/list/entry = list()
		if(record.standing_until > world.time)
			entry["lead"] = agent_advance_level_name(record.standing_rank)
			entry["lead_minutes"] = max(1, CEILING((record.standing_until - world.time) / (1 MINUTES), 1))
		if(record.blocked_until > world.time)
			entry["not_now_minutes"] = max(1, CEILING((record.blocked_until - world.time) / (1 MINUTES), 1))
		if(length(entry))
			entry["name"] = partner.get_visible_name()
			described += list(entry)
	return described
