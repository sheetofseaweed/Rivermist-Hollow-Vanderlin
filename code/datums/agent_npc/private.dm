// Explicit scenes: the model's turns during an act. The game still picks and runs every act; this only tells and listens.

/datum/ai_controller/agent_social
	/// Acts involving the pawn at the last look, by ref: what to say if one has started or ended since.
	var/list/private_acts
	/// world.time an act involving the pawn was first seen running; 0 while none runs.
	var/private_since = 0
	/// The partner whose climax is listened for while an act with them runs.
	var/datum/weakref/climax_watch
	/// Set by the pawn's own climax; the next line out is shouted.
	var/climax_unvoiced = FALSE
	/// The roughest the partner agreed to for the act the NPC leads. Set where the act starts; pace never exceeds it.
	var/pace_force_ceiling = SEX_FORCE_MID

/// Is this person in an act with the pawn right now?
/datum/ai_controller/agent_social/proc/is_private_participant(mob/living/who)
	var/mob/living/living_pawn = pawn
	if(!who || who == living_pawn || !isliving(living_pawn) || QDELETED(living_pawn.sex_scene))
		return FALSE
	for(var/datum/sex_action/action as anything in living_pawn.sex_scene.get_actions_involving(living_pawn))
		if(action.action_user == who || action.action_target == who)
			return TRUE
	return FALSE

/// The acts involving the pawn now, by ref.
/datum/ai_controller/agent_social/proc/private_acts_now()
	var/list/now = list()
	var/mob/living/living_pawn = pawn
	if(!isliving(living_pawn) || QDELETED(living_pawn.sex_scene))
		return now
	for(var/datum/sex_action/action as anything in living_pawn.sex_scene.get_actions_involving(living_pawn))
		now[REF(action)] = action
	return now

/// Compare the acts running now with the last look and tell the model what started and ended. The watches call it.
/datum/ai_controller/agent_social/proc/note_private_acts()
	var/list/now = private_acts_now()
	watch_partner_climax(current_private_partner())
	var/list/before = private_acts || list()
	private_acts = list()
	// Told only while every gate is open; a hosted model never hears of an act. The look itself is always kept.
	var/tell = binding && !QDELETED(binding) && binding.explicit_effective()
	for(var/key in now)
		var/datum/sex_action/action = now[key]
		var/list/entry = before[key]
		if(!entry)
			var/mob/living/other = action.action_user == pawn ? action.action_target : action.action_user
			entry = list("name" = lowertext(action.name), "lead" = action.action_user == pawn ? "you" : "them", "by" = other?.get_visible_name() || "someone")
			if(tell)
				binding.mark_dirty(AGENT_EVENT_PRIVATE_ACT, AGENT_EVENT_HIGH, list("what" = "started", "act" = entry["name"], "lead" = entry["lead"], "by" = entry["by"]), replenish = FALSE)
		private_acts[key] = entry
	for(var/key in before)
		if(now[key])
			continue
		var/list/entry = before[key]
		if(tell)
			binding.mark_dirty(AGENT_EVENT_PRIVATE_ACT, AGENT_EVENT_HIGH, list("what" = "ended", "act" = entry["name"], "lead" = entry["lead"], "by" = entry["by"]), replenish = FALSE)

/// Listen for the partner's climax while an act with them runs; stop when it ends or the partner changes.
/datum/ai_controller/agent_social/proc/watch_partner_climax(mob/living/partner)
	var/mob/living/watched = climax_watch?.resolve()
	if(watched == partner)
		return
	if(watched)
		UnregisterSignal(watched, COMSIG_SEX_CLIMAX)
	climax_watch = null
	if(partner)
		RegisterSignal(partner, COMSIG_SEX_CLIMAX, PROC_REF(on_partner_climax), override = TRUE)
		climax_watch = WEAKREF(partner)

/// Forget everything about private time. Called when the controller lets the pawn go.
/datum/ai_controller/agent_social/proc/forget_private()
	watch_partner_climax(null)
	private_acts = null
	private_since = 0
	climax_unvoiced = FALSE
	pace_force_ceiling = SEX_FORCE_MID

/// The pawn's own peak: told to the model at once, and the next line out is shouted.
/datum/ai_controller/agent_social/proc/on_own_climax(datum/source, datum/sex_action/action, mob/living/receiver, mob/living/partner, mob/living/performer)
	SIGNAL_HANDLER
	if(!binding || QDELETED(binding) || !binding.explicit_effective())
		return
	climax_unvoiced = TRUE
	var/mob/living/other = current_private_partner()
	binding.mark_dirty(AGENT_EVENT_CLIMAX, AGENT_EVENT_HIGH, list("who" = "you", "by" = other?.get_visible_name() || "someone"), replenish = FALSE)

/// The partner's peak, while an act with them runs.
/datum/ai_controller/agent_social/proc/on_partner_climax(datum/source, datum/sex_action/action, mob/living/receiver, mob/living/partner, mob/living/performer)
	SIGNAL_HANDLER
	if(!binding || QDELETED(binding) || !binding.explicit_effective())
		return
	var/mob/living/who = source
	binding.mark_dirty(AGENT_EVENT_CLIMAX, AGENT_EVENT_HIGH, list("who" = "them", "by" = isliving(who) ? who.get_visible_name() : "someone"), replenish = FALSE)

/// The customer asked for it rough or gentle. Told to the model at once.
/datum/ai_controller/agent_social/proc/note_private_pace(mob/living/customer, rough)
	if(!binding || QDELETED(binding) || !binding.explicit_effective() || QDELETED(customer))
		return
	binding.mark_dirty(AGENT_EVENT_PRIVATE_PACE, AGENT_EVENT_HIGH, list("by" = customer.get_visible_name(), "pace" = rough ? "rough" : "gentle"), replenish = FALSE)

/// The act the model takes part in, for the scene it reads. Null when nothing runs.
/datum/ai_controller/agent_social/proc/describe_private()
	var/mob/living/living_pawn = pawn
	var/mob/living/partner = current_private_partner()
	if(!partner)
		return null
	var/list/acts = list()
	for(var/datum/sex_action/action as anything in living_pawn.sex_scene.get_actions_involving(living_pawn))
		acts += list(list(
			"name" = lowertext(action.name),
			"lead" = action.action_user == living_pawn ? "you" : "them",
			"force" = agent_force_word(action.force),
			"speed" = agent_speed_word(action.speed),
		))
	var/list/block = list(
		"with" = partner.get_visible_name(),
		"acts" = acts,
		"you" = agent_describe_arousal(living_pawn),
		"them" = agent_describe_arousal(partner),
	)
	var/datum/component/agent_shop/shop = living_pawn.GetComponent(/datum/component/agent_shop)
	var/datum/agent_stock/service/service = shop?.stock
	if(istype(service) && service.current_customer() == partner)
		block["paid_minutes_left"] = max(1, CEILING((service.paid_until - world.time) / (1 MINUTES), 1))
		block["rough"] = service.rough
	return block

/// Stop the acts the NPC leads. A partner's act is theirs to stop; consent no ends private time instead.
/datum/ai_controller/agent_social/proc/stop_led_acts()
	var/mob/living/living_pawn = pawn
	var/stopped = 0
	if(isliving(living_pawn) && !QDELETED(living_pawn.sex_scene))
		for(var/datum/sex_action/action as anything in living_pawn.sex_scene.get_actions_involving(living_pawn))
			if(action.action_user != living_pawn)
				continue
			action.scene?.stop_action(action)
			stopped++
	if(!stopped)
		return agent_result(AGENT_RESULT_REJECTED, "you lead nothing right now; to end private time, use consent with key no")
	return agent_result(AGENT_RESULT_SUCCEEDED, "you stopped what you were doing")

/// Does the NPC lead an act right now? Only then may it set the pace.
/datum/ai_controller/agent_social/proc/leads_private_act()
	var/mob/living/living_pawn = pawn
	var/datum/sex_scene_controller/controller = living_pawn?.sex_scene?.get_controller(living_pawn)
	return !!length(controller?.get_owned_actions())

/// The model sets the pace of an act it leads, one step at a time, never rougher than the partner agreed to.
/datum/ai_controller/agent_social/proc/pace_led_act(key)
	var/mob/living/living_pawn = pawn
	var/datum/sex_scene_controller/controller = living_pawn?.sex_scene?.get_controller(living_pawn)
	if(!controller || !length(controller.get_owned_actions()))
		return agent_result(AGENT_RESULT_REJECTED, "you lead nothing right now")
	var/want = istext(key) ? lowertext(trim(key)) : ""
	switch(want)
		if("faster", "slower")
			var/step = want == "faster" ? 1 : -1
			// Extreme is never the model's to pick.
			var/speed = clamp(controller.speed + step, SEX_SPEED_LOW, SEX_SPEED_HIGH)
			if(speed == controller.speed)
				return agent_result(AGENT_RESULT_REJECTED, step > 0 ? "as quick as you go already" : "as slow as you go already")
			controller.set_current_speed(speed)
		if("rougher", "gentler")
			var/step = want == "rougher" ? 1 : -1
			var/force = clamp(controller.force + step, SEX_FORCE_LOW, min(SEX_FORCE_HIGH, pace_force_ceiling))
			if(force == controller.force)
				return agent_result(AGENT_RESULT_REJECTED, step > 0 ? "they have not agreed to rougher than this" : "as gentle as you go already")
			controller.set_current_force(force)
		else
			return agent_result(AGENT_RESULT_REJECTED, "key must be faster, slower, gentler or rougher")
	return agent_result(AGENT_RESULT_SUCCEEDED, "you go [agent_force_word(controller.force)] and [agent_speed_word(controller.speed)] now")

/// Arousal as the model reads it: a band, whether they are close, whether they are spent.
/proc/agent_describe_arousal(mob/living/who)
	var/list/data = list()
	SEND_SIGNAL(who, COMSIG_SEX_GET_AROUSAL, data)
	var/arousal = data["arousal"] || 0
	var/progress = data["orgasm_progress"] || 0
	return list("arousal" = agent_arousal_band(arousal), "close" = progress >= AGENT_CLOSE_PROGRESS, "spent" = !!data["is_spent"])

/proc/agent_arousal_band(amount)
	if(amount >= AGENT_AROUSAL_BURNING)
		return "burning"
	if(amount >= AGENT_AROUSAL_AROUSED)
		return "aroused"
	if(amount >= AGENT_AROUSAL_WARMING)
		return "warming"
	return "cool"

/// The pace words the custom acts show players, so the model reads the same ones.
/proc/agent_force_word(force)
	switch(force)
		if(SEX_FORCE_LOW)
			return "gentle"
		if(SEX_FORCE_MID)
			return "firm"
		if(SEX_FORCE_HIGH)
			return "rough"
		if(SEX_FORCE_EXTREME)
			return "brutal"
	return "steady"

/proc/agent_speed_word(speed)
	switch(speed)
		if(SEX_SPEED_LOW)
			return "slow"
		if(SEX_SPEED_MID)
			return "steady"
		if(SEX_SPEED_HIGH)
			return "quick"
		if(SEX_SPEED_EXTREME)
			return "relentless"
	return "steady"

/// How a line is spoken, and why: whisper, say or shout, from the model's wish and the body's state.
/proc/agent_pick_voice(mob/living/pawn, wants_whisper)
	var/datum/ai_controller/agent_social/agent = pawn?.ai_controller
	if(!istype(agent))
		return list("voice" = "say", "note" = null)
	// At its own peak the first line out is not a choice.
	if(agent.climax_unvoiced)
		agent.climax_unvoiced = FALSE
		return list("voice" = "shout", "note" = "at your peak everyone nearby heard you")
	if(!wants_whisper)
		return list("voice" = "say", "note" = null)
	if(agent.in_private())
		var/list/state = agent_describe_arousal(pawn)
		if(state["close"] || state["arousal"] == "burning")
			return list("voice" = "say", "note" = "too far gone to keep your voice down")
	var/atom/movable/listener = agent.in_private() ? agent.current_private_partner() : agent.binding?.current_partner()
	if(!listener || !pawn.Adjacent(listener))
		return list("voice" = "say", "note" = "nobody beside you to whisper to")
	return list("voice" = "whisper", "note" = null)

/// The game shouts a line that ends in an exclamation mark.
/proc/agent_shouted(text)
	var/ending = copytext_char(text, -1)
	if(ending == "!")
		return text
	if(ending == "." || ending == "?")
		return copytext_char(text, 1, -1) + "!"
	return text + "!"

/// Did a say outcome put words in the air? The detail names the voice, and may carry a note after a colon.
/proc/agent_said_words(list/outcome)
	return islist(outcome) && outcome["state"] == AGENT_RESULT_SUCCEEDED && outcome["detail"] != "acted"
