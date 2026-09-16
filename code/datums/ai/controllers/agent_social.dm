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

	binding.mark_dirty("heard_speech", AGENT_EVENT_LOW, list(
		"speaker" = speaker_name,
		"text" = understood,
	), replenish = !from_another_agent)

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
