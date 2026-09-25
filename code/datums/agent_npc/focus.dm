// Explicit focus: the player names the NPC they mean. The one addressing rule that guesses nothing.

/// Agent NPCs this player could turn to right now, nearest first.
/proc/agent_focus_candidates(mob/living/speaker)
	var/list/found = list()
	if(!isliving(speaker) || QDELETED(speaker))
		return found
	for(var/mob/living/nearby in view(AGENT_FOCUS_RANGE, speaker))
		if(nearby == speaker)
			continue
		var/datum/ai_controller/agent_social/agent = nearby.ai_controller
		if(!istype(agent) || QDELETED(agent.binding))
			continue
		found[nearby] = get_dist(speaker, nearby)
	sortTim(found, GLOBAL_PROC_REF(cmp_numeric_asc), associative = TRUE)
	return found

/// Which NPC, if any, this player is speaking with now.
/proc/agent_focus_target_of(mob/living/speaker)
	RETURN_TYPE(/mob/living)
	if(!speaker || !SSagent_npc?.bindings)
		return null
	for(var/pawn_id in SSagent_npc.bindings)
		var/datum/agent_binding/binding = SSagent_npc.bindings[pawn_id]
		if(!QDELETED(binding) && binding.has_focus_from(speaker))
			return binding.resolve_pawn()
	return null

/// Did this speaker turn to another NPC and stay near it? Otherwise every NPC in earshot answers.
/proc/agent_focus_held_elsewhere(atom/movable/speaker, datum/agent_binding/ours)
	if(!speaker || !SSagent_npc?.bindings)
		return FALSE
	for(var/pawn_id in SSagent_npc.bindings)
		var/datum/agent_binding/binding = SSagent_npc.bindings[pawn_id]
		if(binding == ours || QDELETED(binding) || !binding.has_focus_from(speaker))
			continue
		var/mob/living/other = binding.resolve_pawn()
		if(other && get_dist(speaker, other) <= AGENT_FOCUS_RANGE)
			return TRUE
	return FALSE

/// Drop this player's focus everywhere, or two NPCs both believe they are being addressed.
/proc/agent_focus_off(mob/living/speaker)
	if(!speaker || !SSagent_npc?.bindings)
		return
	for(var/pawn_id in SSagent_npc.bindings)
		var/datum/agent_binding/binding = SSagent_npc.bindings[pawn_id]
		if(!QDELETED(binding))
			binding.clear_focus(speaker)

/// Turn a player toward an agent NPC. Null on success, else a refusal; nothing from the verb is trusted.
/proc/agent_focus_on(mob/living/speaker, mob/living/target)
	if(!isliving(speaker) || QDELETED(speaker) || speaker.stat >= UNCONSCIOUS)
		return "You are in no state to talk."
	if(!isliving(target) || QDELETED(target) || target == speaker)
		return "There is nobody there to talk to."
	var/datum/ai_controller/agent_social/agent = target.ai_controller
	if(!istype(agent) || QDELETED(agent.binding))
		return "[target] is not someone you can talk to like that."
	if(target.stat >= UNCONSCIOUS)
		return "[target] is in no state to talk."
	if(get_dist(speaker, target) > AGENT_FOCUS_RANGE || !(target in view(AGENT_FOCUS_RANGE, speaker)))
		return "[target] is too far away."

	agent_focus_off(speaker)
	agent.binding.set_focus(speaker)
	return null

/// A client verb, because verbs on nearby mobs never reach the stat panel. Added in add_verbs_from_config().
/client/proc/agent_talk_to()
	set name = "Talk To"
	set category = "IC"
	set desc = "Turn to speak with someone, so they know it is them you mean."

	var/mob/living/speaker = mob
	if(!isliving(speaker))
		return
	if(!SSagent_npc?.enabled || SSagent_npc.globally_disabled)
		to_chat(speaker, span_warning("There is nobody here to talk to like that."))
		return

	var/mob/living/current = agent_focus_target_of(speaker)
	var/list/candidates = agent_focus_candidates(speaker)

	// One candidate needs no menu: you are either starting to talk to them or finishing.
	if(length(candidates) == 1)
		var/mob/living/only = candidates[1]
		if(only == current)
			agent_focus_off(speaker)
			to_chat(speaker, span_notice("You stop speaking with [only.get_visible_name()]."))
			return
		if(!current)
			agent_talk_to_confirm(speaker, only)
			return

	if(!length(candidates) && !current)
		to_chat(speaker, span_warning("There is nobody close enough to talk to."))
		return

	var/list/choices = list()
	var/static/stop_label = "--- stop speaking ---"
	if(current)
		choices[stop_label] = stop_label
	for(var/mob/living/nearby as anything in candidates)
		var/label = "[nearby.get_visible_name()] ([candidates[nearby]] tiles [dir2text(get_dir(speaker, nearby))])"
		choices[label] = nearby

	var/picked = input(speaker, "Who do you want to speak with?", "Talk To") as null|anything in choices
	if(!picked || QDELETED(speaker))
		return
	if(choices[picked] == stop_label)
		agent_focus_off(speaker)
		to_chat(speaker, span_notice("You stop speaking with [current?.get_visible_name() || "them"]."))
		return
	// input() slept. agent_focus_on checks everything again on what is true now.
	agent_talk_to_confirm(speaker, choices[picked])

/client/proc/agent_talk_to_confirm(mob/living/speaker, mob/living/target)
	var/refusal = agent_focus_on(speaker, target)
	if(refusal)
		to_chat(speaker, span_warning(refusal))
		return
	to_chat(speaker, span_notice("You turn to speak with [target.get_visible_name()]. What you say now is meant for them."))
