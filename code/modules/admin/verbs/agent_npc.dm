/**
 * Operator controls for agent NPCs.
 *
 * The kill switch is the important one. Without a verb, disable_all() is only
 * reachable by restarting the server, which is not an acceptable answer when an
 * agent misbehaves in front of players.
 */

/client/proc/agent_npc_status()
	set category = "Debug.Agent NPC"
	set name = "Agent NPC - Status"
	if(!check_rights(R_DEBUG))
		return

	var/list/lines = list("<b>Agent NPC</b>")
	lines += "enabled: [SSagent_npc.enabled ? "yes" : "no"] | \
		operator disable: [SSagent_npc.globally_disabled ? "<b>ON</b>" : "off"]"
	lines += "endpoint: [SSagent_npc.endpoint || "unset"]"
	lines += "session: [SSagent_npc.session_id]"
	lines += "registered: [length(SSagent_npc.bindings)] | in flight: [length(SSagent_npc.in_flight)] | draining: [length(SSagent_npc.draining)]"
	lines += "tokens spent: [SSagent_npc.tokens_spent] | reserved: [SSagent_npc.tokens_reserved_total]"
	lines += "unsettled: [SSagent_npc.tokens_unsettled] | budget: [SSagent_npc.round_token_budget || "unlimited"]"
	lines += "outstanding: [length(SSagent_npc.in_flight) + length(SSagent_npc.draining)] / [AGENT_MAX_OUTSTANDING]"
	lines += "drains abandoned: [SSagent_npc.drain_abandoned]"

	if(length(SSagent_npc.refusal_counts))
		var/list/refusals = list()
		for(var/reason in SSagent_npc.refusal_counts)
			refusals += "[reason]=[SSagent_npc.refusal_counts[reason]]"
		lines += "refusals: [refusals.Join(", ")]"

	var/datum/agent_telemetry/measured = SSagent_npc.telemetry
	if(measured)
		lines += "<b>measured</b> (decisions: [measured.decisions][measured.breaker_probes ? ", breaker probes: [measured.breaker_probes]" : ""])"
		// Queue wait and round trip are split because the fixes differ: pacing
		// and concurrency are ours, the round trip belongs to the provider.
		lines += "&nbsp;&nbsp;queue wait: [measured.queue_wait.summary_ds()]"
		lines += "&nbsp;&nbsp;round trip: [measured.round_trip.summary_ds()]"
		lines += "&nbsp;&nbsp;observation age at objective end: [measured.observation_age.summary_ds()]"
		lines += "&nbsp;&nbsp;tokens/decision: [measured.tokens.summary_plain()]"
		if(measured.tokens.count < measured.decisions)
			lines += "&nbsp;&nbsp;<i>[measured.decisions - measured.tokens.count] decision(s) reported no usage.</i>"
		lines += "&nbsp;&nbsp;chain depth: [measured.chain_depth.summary_plain()]"
		lines += "&nbsp;&nbsp;actions chosen: [measured.format_counts(measured.action_counts)]"
		lines += "&nbsp;&nbsp;outcomes: [measured.format_counts(measured.result_counts)]"

	for(var/pawn_id in SSagent_npc.bindings)
		var/datum/agent_binding/binding = SSagent_npc.bindings[pawn_id]
		if(QDELETED(binding))
			continue
		var/mob/living/pawn = binding.resolve_pawn()
		var/list/intent = binding.current_intent
		// A pawn past the failure limit is sending one probe per cooldown and is
		// otherwise silent. Saying so plainly beats leaving it to be inferred.
		var/breaker = ""
		if(binding.is_probe())
			var/wait_ds = max(0, binding.next_request_at - world.time)
			breaker = " | <b>BREAKER OPEN</b>, probe in [round(wait_ds / 10, 1)]s"

		lines += "&nbsp;&nbsp;[pawn ? pawn.name : "(gone)"] \
			epoch [binding.epoch] gen [binding.generation] \
			| state [binding.state] \
			| intent [intent ? intent["name"] : "none"] \
			| events [length(binding.events)] \
			| requests [binding.requests_made] refused [binding.requests_refused] expired [binding.requests_expired] \
			| failures [binding.consecutive_failures][breaker]"

	to_chat(src, "<span class='notice'>[lines.Join("<br>")]</span>")

/client/proc/agent_npc_toggle()
	set category = "Debug.Agent NPC"
	set name = "Agent NPC - Toggle All (kill switch)"
	if(!check_rights(R_DEBUG))
		return

	if(SSagent_npc.globally_disabled)
		SSagent_npc.enable_all("admin [key_name(src)]")
		message_admins("[key_name_admin(src)] re-enabled agent NPCs.")
		log_admin("[key_name(src)] re-enabled agent NPCs.")
		return

	SSagent_npc.disable_all("admin [key_name(src)]")
	message_admins("[key_name_admin(src)] <b>disabled all agent NPCs</b>.")
	log_admin("[key_name(src)] disabled all agent NPCs.")

/client/proc/agent_npc_spawn()
	set category = "Debug.Agent NPC"
	set name = "Agent NPC - Spawn"
	if(!check_rights(R_DEBUG))
		return

	var/turf/here = get_turf(mob)
	if(!here)
		to_chat(src, span_warning("You are not standing anywhere."))
		return

	var/static/list/profiles = list(
		"villager (can walk and use things)" = /datum/agent_profile/villager,
		"villager, talk only (safer first test)" = /datum/agent_profile/villager/sedentary,
	)
	var/choice = input(src, "Which profile?", "Agent NPC") as null|anything in profiles
	if(!choice)
		return

	var/mob/living/carbon/human/species/human/northern/agent_social/spawned = new(here)
	var/datum/ai_controller/agent_social/controller = spawned.ai_controller
	if(istype(controller))
		QDEL_NULL(controller.profile)
		// DM will not parse `new profiles[choice]()`; the type needs its own var.
		var/chosen_type = profiles[choice]
		controller.profile = new chosen_type()
		// The controller already tried to register at possession. Retry now in
		// case the subsystem was off then, or the profile decided admission.
		controller.register_cooldown = 0
		controller.ensure_registered()

	var/bound = istype(controller) && controller.binding && !QDELETED(controller.binding)
	if(!bound)
		to_chat(src, span_warning("Spawned, but it did NOT bind to SSagent_npc. \
			It will behave as an ordinary passive NPC. Check that AGENT_NPC_ENABLED \
			is set and the subsystem is not disabled."))
	else
		to_chat(src, span_notice("Spawned [spawned.name], bound as epoch [controller.binding.epoch]."))

	message_admins("[key_name_admin(src)] spawned an agent NPC ([choice]) at [AREACOORD(here)].")
	log_admin("[key_name(src)] spawned an agent NPC ([choice]) at [AREACOORD(here)].")

/client/proc/agent_npc_poke()
	set category = "Debug.Agent NPC"
	set name = "Agent NPC - Poke (force a decision)"
	if(!check_rights(R_DEBUG))
		return

	var/list/options = list()
	for(var/pawn_id in SSagent_npc.bindings)
		var/datum/agent_binding/binding = SSagent_npc.bindings[pawn_id]
		var/mob/living/pawn = binding?.resolve_pawn()
		if(pawn)
			options["[pawn.name] ([pawn_id])"] = binding

	if(!length(options))
		to_chat(src, span_warning("No agent NPCs are registered."))
		return

	var/choice = input(src, "Poke which one?", "Agent NPC") as null|anything in options
	if(!choice)
		return

	var/datum/agent_binding/binding = options[choice]
	// Clear the pacing floor too, or the poke silently waits for it.
	binding.next_request_at = 0
	binding.consecutive_failures = 0
	binding.mark_dirty("admin_poke", AGENT_EVENT_HIGH)
	to_chat(src, span_notice("Poked. It should ask for a decision within a second."))
	log_admin("[key_name(src)] poked agent NPC [binding.pawn_id].")
