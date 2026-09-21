/**
 * # Agent social controller
 *
 * The pilot pawn for agent-driven NPCs. Purpose built rather than reskinned
 * from a hostile, because every existing humanoid controller carries branches
 * that are unsafe as an unsupervised fallback: human_bum has mug and loot, and
 * every human_npc user in the tree is a hostile.
 *
 * It cannot fight. Attacked, it stands, resists, breaks restraints and runs.
 * That is the whole autonomous repertoire, which is what makes the sidecar
 * outage fallback safe by construction rather than by hope.
 */
/datum/ai_controller/agent_social
	movement_delay = 0.5 SECONDS
	max_target_distance = 9
	ai_movement = /datum/ai_movement/hybrid_pathing
	idle_behavior = /datum/idle_behavior/nothing
	// Idling would add up to 5s to every reaction on top of the model round
	// trip. Affordable for a pilot; revisit before the registry grows.
	can_idle = FALSE

	blackboard = list(
		// It never fights, so any target it holds is something to run from.
		BB_BASIC_MOB_FLEEING = TRUE,
		BB_AGENT_FLEE_UNTIL = 0,
	)

	planning_subtrees = list(
		// REFLEX, indices 1..5. Never agent owned.
		/datum/ai_planning_subtree/generic_stand,
		/datum/ai_planning_subtree/generic_break_restraints,
		/datum/ai_planning_subtree/generic_resist,
		/datum/ai_planning_subtree/agent_flee_recovery,
		/datum/ai_planning_subtree/flee_target,
		// OBJECTIVE, index 6. The only agent owned slot.
		/datum/ai_planning_subtree/agent_intent,
	)

	/// A bound pawn keeps planning on z-levels the engine would otherwise idle.
	var/require_wakefulness = TRUE
	/// Our registration with SSagent_npc. Always guard with QDELETED.
	var/datum/agent_binding/binding
	/// Who this character is. Set the typepath; New() instantiates it.
	var/profile_type = /datum/agent_profile/villager
	var/datum/agent_profile/profile
	/// Throttles registration retries for pawns that spawn before the subsystem.
	COOLDOWN_DECLARE(register_cooldown)

/datum/ai_controller/agent_social/New(atom/new_pawn)
	// An instance, not initial() on the typepath: initial() returns null for
	// list vars, which would silently empty permitted_actions.
	profile = new profile_type()
	return ..()

/datum/ai_controller/agent_social/PossessPawn(atom/new_pawn)
	. = ..()
	RegisterSignal(pawn, COMSIG_MOVABLE_HEAR, PROC_REF(on_pawn_heard))
	ensure_registered()

/datum/ai_controller/agent_social/UnpossessPawn(destroy)
	if(pawn)
		UnregisterSignal(pawn, COMSIG_MOVABLE_HEAR)
	release_binding("pawn unpossessed")
	return ..()

/**
 * Turn overheard speech into an event the agent can answer.
 *
 * The signal carries the emitting proc's whole args list as ONE payload, so the
 * handler must take a list. A handler declaring unpacked parameters compiles
 * clean and silently binds the list to the wrong argument.
 *
 * The raw payload is not forwarded. It is composed here through lang_treat on
 * our own pawn, because /mob/living/Hear() returns early for clientless mobs,
 * before language incomprehension is ever applied. Forwarding the raw message
 * would hand the agent text this character cannot actually understand.
 */
/datum/ai_controller/agent_social/proc/on_pawn_heard(datum/source, list/hearing_args)
	SIGNAL_HANDLER
	if(!islist(hearing_args) || !binding || QDELETED(binding))
		return

	var/atom/movable/speaker = hearing_args[HEARING_SPEAKER]
	if(QDELETED(speaker) || speaker == pawn)
		return

	var/mob/living/living_pawn = pawn
	if(!isliving(living_pawn) || living_pawn.stat >= UNCONSCIOUS || !living_pawn.can_hear())
		return

	var/understood = living_pawn.lang_treat(
		speaker,
		hearing_args[HEARING_LANGUAGE],
		hearing_args[HEARING_RAW_MESSAGE],
		null,
		null,
		no_quote = TRUE,
	)

	// get_visible_name is on /mob/living, and it honours disguise. Anything else
	// is named plainly rather than guessed at.
	var/speaker_name = "[speaker.name]"
	if(isliving(speaker))
		var/mob/living/living_speaker = speaker
		speaker_name = living_speaker.get_visible_name()

	// Speech from another agent NPC must not refresh the continuation budget.
	// Two agents replenishing each other is a conversation with no end that no
	// per-turn cap can stop. It is still heard; it just does not buy more turns.
	var/from_another_agent = !isnull(SSagent_npc?.bindings?["[REF(speaker)]"])

	// Bounds checked: Hear() passes its whole args list, but callers that build
	// one by hand stop at the four named HEARING_* fields. Indexing past the end
	// runtimes, and a runtime in a signal handler loses the speech silently.
	var/list/mods = (length(hearing_args) >= HEARING_MESSAGE_MODS) ? hearing_args[HEARING_MESSAGE_MODS] : null
	var/list/context = build_speech_context(speaker, understood, hearing_args[HEARING_RAW_MESSAGE], mods)

	var/list/detail = list(
		"speaker" = speaker_name,
		"text" = understood,
		"distance" = context["distance"],
		"whispered" = context["whispered"],
		"shouted" = agent_speech_is_shouted(context["volume"]),
		// Named for what it is: a cheap local estimate of the social scene, not
		// the set of mobs the speech engine actually delivered to.
		"nearby_people" = context["nearby_people"],
	)

	var/classification = classify_speech(speaker, understood, context)
	detail["addressing"] = classification

	route_speech(classification, speaker_name, understood, detail, from_another_agent)

/**
 * What does one classified line actually do?
 *
 * Returns the route taken, so the decision can be tested without staging a
 * hearing event. Nothing here is ever discarded: the worst outcome for a line
 * is that it waits and rides along with the next real decision.
 */
/datum/ai_controller/agent_social/proc/route_speech(classification, speaker_name, text, list/detail, from_another_agent = FALSE)
	if(QDELETED(binding))
		return "unbound"

	// The same line, still waiting to be sent. Repeats should not push a
	// player's actual question out of a ring that only holds twelve.
	if(binding.speech_already_buffered(speaker_name, text))
		return "duplicate"

	// Overheard. It still reaches the agent, folded into the next real decision,
	// but it neither buys one nor extends the interaction. Two players chatting
	// nearby used to do both.
	if(!agent_speech_wakes_us(classification))
		binding.push_event("overheard_speech", AGENT_EVENT_LOW, detail)
		return "buffered"

	// Rationed, not silenced, and only ever for speech we could not classify.
	// Directed lines and attacks never reach this branch.
	if(classification == AGENT_SPEECH_AMBIGUOUS)
		if(!binding.may_spend_on_ambiguous())
			SSagent_npc?.note_ambiguous_deferred()
			binding.push_event("overheard_speech", AGENT_EVENT_LOW, detail)
			return "rationed"
		binding.note_ambiguous_spend()

	binding.mark_dirty("heard_speech", AGENT_EVENT_LOW, detail, replenish = !from_another_agent)
	return "sent"

/**
 * Everything cheap and local we can say about one heard line.
 *
 * Built once, because the classifier, the event payload and the telemetry all
 * want the same facts and view() is not free. Signal handlers must not sleep,
 * and nothing here does.
 */
/datum/ai_controller/agent_social/proc/build_speech_context(atom/movable/speaker, text, raw_text, list/mods)
	var/list/context = list(
		"distance" = get_dist(pawn, speaker),
		"whispered" = islist(mods) && mods[WHISPER_MODE],
		// Read from the raw line, because volume is physical: you can hear that
		// someone is shouting in a language you do not speak.
		"volume" = say_test(raw_text),
		// Which script the NPC is being spoken to in, so a failed name match in
		// a script we cannot read is not mistaken for an absent name.
		"script" = agent_text_script(text),
		"nearby_people" = 0,
		"named_someone_else" = FALSE,
	)

	for(var/mob/living/nearby in view(AGENT_VIEW_RANGE, pawn))
		if(nearby == pawn || nearby == speaker)
			continue
		// Someone who cannot hear is not an alternative audience.
		if(nearby.stat >= UNCONSCIOUS || !nearby.can_hear())
			continue
		context["nearby_people"]++
		if(!context["named_someone_else"] && agent_name_in_vocative(nearby.get_visible_name(), text))
			context["named_someone_else"] = TRUE
	return context

/// The name this NPC can legitimately be addressed by. get_visible_name honours
/// disguise, so a hidden identity is not what wakes it.
/datum/ai_controller/agent_social/proc/addressable_name()
	var/mob/living/living_pawn = pawn
	return isliving(living_pawn) ? living_pawn.get_visible_name() : "[pawn?.name]"

/**
 * Was that said to us?
 *
 * Three answers, not two. Only the first four rules claim to know; everything
 * else is honestly ambiguous. The classifier stays lopsided — a wasted decision
 * is a fraction of a penny, an NPC that ignores someone looks broken — so only
 * positive evidence that a line belonged elsewhere produces `overheard`.
 */
/datum/ai_controller/agent_social/proc/classify_speech(atom/movable/speaker, text, list/context)
	// Mid-conversation. A reply does not carry your name.
	if(binding?.in_interaction())
		return AGENT_SPEECH_DIRECTED

	// A whisper carries one tile. Past that is the eavesdrop band, where what
	// arrives is a starred copy, so hearing one proves proximity rather than
	// intent. An eavesdropped whisper falls through to the ordinary rules.
	if(context["whispered"] && context["distance"] <= AGENT_WHISPER_INTENDED_RANGE)
		return AGENT_SPEECH_DIRECTED

	if(agent_name_matches_loosely(addressable_name(), text))
		return AGENT_SPEECH_DIRECTED

	// The one confident suppression: they addressed someone else standing here.
	if(context["named_someone_else"])
		return AGENT_SPEECH_OVERHEARD

	// Nobody else could have been the audience.
	if(context["nearby_people"] <= 0)
		return AGENT_SPEECH_DIRECTED

	// A shout is a deliberate attempt to be heard at distance, and the engine
	// extends its range to match. Loud and public is not the same as ours, so
	// this is worth attention rather than a claim of certainty.
	if(agent_speech_is_shouted(context["volume"]))
		return AGENT_SPEECH_AMBIGUOUS

	// Ordinary distant chatter in a room with other people in it.
	//
	// Skipped when the line is in a script we cannot match a Latin name against.
	// The name rule above is the escape hatch that lets a distant call through,
	// so applying this without it silences exactly one language group.
	if(context["distance"] > AGENT_DIRECT_SPEECH_RANGE && agent_script_is_matchable(context["script"]))
		return AGENT_SPEECH_OVERHEARD

	return AGENT_SPEECH_AMBIGUOUS

/// Does this classification schedule a decision? Ambiguous still does: without
/// an attention budget to bound it, silence is the worse failure.
/proc/agent_speech_wakes_us(classification)
	return classification != AGENT_SPEECH_OVERHEARD

/datum/ai_controller/agent_social/Destroy(force, ...)
	release_binding("controller destroyed")
	QDEL_NULL(profile)
	return ..()

/// Register with SSagent_npc, retrying for pawns that spawned before it existed.
/datum/ai_controller/agent_social/proc/ensure_registered()
	if(binding && !QDELETED(binding))
		return TRUE
	binding = null
	if(QDELETED(pawn) || !isliving(pawn))
		return FALSE
	if(!COOLDOWN_FINISHED(src, register_cooldown))
		return FALSE
	COOLDOWN_START(src, register_cooldown, AGENT_REGISTER_RETRY)
	binding = SSagent_npc?.register_pawn(pawn, src)
	return !isnull(binding)

/datum/ai_controller/agent_social/proc/release_binding(reason)
	if(binding && !QDELETED(binding))
		SSagent_npc?.unregister_pawn(binding, reason)
	binding = null

/**
 * Keep a bound pawn awake wherever it spawned.
 *
 * The parent puts a controller to AI_STATUS_OFF when its z-level is outside
 * SSmobs.town_z and holds no clients. An agent NPC there would register,
 * receive events, and silently never plan. Only that one reason is overridden:
 * death, incapacitation and player takeover are rechecked and still win.
 */
/datum/ai_controller/agent_social/get_expected_ai_status()
	. = ..()
	if(. != AI_STATUS_OFF || !require_wakefulness)
		return .
	if(!binding || QDELETED(binding) || QDELETED(pawn) || !able_to_run)
		return .
	var/mob/living/mob_pawn = pawn
	if(!isliving(mob_pawn) || mob_pawn.client || mob_pawn.stat >= UNCONSCIOUS)
		return .
	return AI_STATUS_ON

/**
 * Turn being hit into an actual flee.
 *
 * flee_target needs both BB_BASIC_MOB_FLEEING and a live target, and the base
 * attacked handler sets neither: it only touches alert and status. Without this
 * the controller's reflex tier would look complete and never run.
 *
 * This is a reflex, so it must work with the sidecar down. Notifying the agent
 * is the last thing it does, and is optional.
 */
/datum/ai_controller/agent_social/on_pawn_attacked(atom/source, atom/attacker, damage)
	. = ..()
	if(attacker == pawn || QDELETED(attacker) || !isliving(attacker))
		return

	set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, attacker)
	set_blackboard_key(BB_AGENT_FLEE_UNTIL, world.time + AGENT_FLEE_DURATION)

	if(binding && !QDELETED(binding))
		binding.mark_dirty("attacked", AGENT_EVENT_HIGH, list("by" = "[attacker.name]"))

/**
 * Is the pawn free to pursue an agent objective?
 *
 * Re-evaluated every plan. Any reflex condition suspends the objective rather
 * than cancelling it, so the agent is told what happened and can decide again.
 */
/datum/ai_controller/agent_social/proc/reflex_guard_clear()
	var/mob/living/living_pawn = pawn
	if(!isliving(living_pawn) || QDELETED(living_pawn))
		return FALSE
	if(living_pawn.stat >= UNCONSCIOUS)
		return FALSE
	if(living_pawn.body_position == LYING_DOWN)
		return FALSE
	if(blackboard[BB_BASIC_MOB_CURRENT_TARGET])
		return FALSE
	var/mob/living/carbon/carbon_pawn = living_pawn
	if(iscarbon(carbon_pawn) && (carbon_pawn.handcuffed || carbon_pawn.legcuffed))
		return FALSE
	return TRUE

/**
 * Cancel only the agent's own objective.
 *
 * CancelActions() finishes every running behavior, so using it to retarget
 * would also cancel an active resist or restraint break. Retargeting must not
 * be able to interrupt a reflex.
 */
/// Returns TRUE if something was actually cancelled.
/datum/ai_controller/agent_social/proc/cancel_agent_objective()
	. = FALSE
	if(!LAZYLEN(current_behaviors))
		return
	for(var/datum/ai_behavior/current_behavior as anything in current_behaviors)
		if(!istype(current_behavior, /datum/ai_behavior/agent_approach))
			continue
		var/list/arguments = list(src, FALSE)
		var/list/stored_arguments = behavior_args[current_behavior.type]
		if(stored_arguments)
			arguments += stored_arguments
		current_behavior.finish_action(arglist(arguments))
		. = TRUE

/// Drop a threat we have finished running from, so the pawn can settle.
/datum/ai_controller/agent_social/proc/clear_threat()
	clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)
	clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)
	set_blackboard_key(BB_AGENT_FLEE_UNTIL, 0)
