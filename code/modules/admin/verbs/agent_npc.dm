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
	// Every gate but the profile's, so an admin can see which one holds explicit scenes shut.
	var/list/capabilities = SSagent_npc.sidecar_capabilities
	lines += "explicit scenes: config [CONFIG_GET(flag/agent_npc_explicit_scenes) ? "on" : "off"] | \
		admin [SSagent_npc.explicit_enabled ? "on" : "off"] | \
		sidecar [SSagent_npc.sidecar_explicit() ? "<b>yes</b>" : "no"]\
		[capabilities ? " ([capabilities["adapter"]], [capabilities["model"] || "model unknown"], screening [capabilities["screening"]])" : " (no reply yet)"]"
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
		// The ratio is what the ambiguous limits should be tuned from. A lot of
		// deferrals means the NPC is in a busy room and being rationed.
		lines += "&nbsp;&nbsp;unclear speech: [measured.ambiguous_requests] answered / [AGENT_AMBIGUOUS_ROUND_LIMIT] allowed, [measured.ambiguous_deferred] deferred"
		// Non-zero means two NPCs were left talking to each other.
		lines += "&nbsp;&nbsp;agent-to-agent lines held back: [measured.agent_exchanges_capped]"
		lines += "&nbsp;&nbsp;lines held back past a speaker's [AGENT_SPEAKER_DECISIONS] per [AGENT_SPEAKER_WINDOW / (1 MINUTES)] min: [measured.speaker_deferred]"
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
		var/datum/ai_controller/agent_social/agent = binding.resolve_controller()
		var/fight = ""
		if(istype(agent) && agent.in_combat())
			var/mob/living/foe = agent.blackboard[BB_AGENT_COMBAT_TARGET]
			fight = " | <b>FIGHTING</b> [foe] ([agent.blackboard[BB_AGENT_COMBAT_LEVEL]])"
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
			| unclear [binding.ambiguous_spent]/[AGENT_AMBIGUOUS_PAWN_LIMIT] \
			| failures [binding.consecutive_failures][breaker][fight]"

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

/client/proc/agent_npc_explicit_toggle()
	set category = "Debug.Agent NPC"
	set name = "Agent NPC - Explicit scenes (toggle)"
	if(!check_rights(R_DEBUG))
		return

	var/turning_on = !SSagent_npc.explicit_enabled
	var/refusal = SSagent_npc.set_explicit_enabled(turning_on, "admin [key_name(src)]")
	if(refusal)
		to_chat(src, span_warning(refusal))
		return
	message_admins("[key_name_admin(src)] turned explicit scenes for agent NPCs [turning_on ? "<b>on</b>" : "off"].")
	log_admin("[key_name(src)] turned explicit scenes for agent NPCs [turning_on ? "on" : "off"].")
	to_chat(src, span_notice("Explicit scenes are [turning_on ? "on, for profiles that allow them and a sidecar that does" : "off"]."))

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

/// The admin picks a bound NPC, or null.
/proc/agent_npc_pick_binding(client/admin, prompt)
	var/list/options = list()
	for(var/pawn_id in SSagent_npc.bindings)
		var/datum/agent_binding/binding = SSagent_npc.bindings[pawn_id]
		var/mob/living/pawn = binding?.resolve_pawn()
		if(pawn)
			options["[pawn.name] ([pawn_id])"] = binding
	if(!length(options))
		to_chat(admin, span_warning("No agent NPCs are registered."))
		return null
	var/choice = input(admin, prompt, "Agent NPC") as null|anything in options
	return choice ? options[choice] : null

/// The partner for a staged state: the admin's own character first, then anyone with a client in view.
/proc/agent_npc_pick_partner(client/admin, mob/living/pawn)
	var/list/options = list()
	if(isliving(admin.mob))
		options["[admin.mob.name] (you)"] = admin.mob
	for(var/mob/living/carbon/human/candidate in view(AGENT_ATTACH_RANGE, admin.mob))
		if(candidate.client && candidate != admin.mob && candidate != pawn)
			options["[candidate.name] ([candidate.key])"] = candidate
	if(!length(options))
		to_chat(admin, span_warning("Nobody to stage with: be in a living body, or have a player in view."))
		return null
	var/choice = input(admin, "With whom?", "Agent NPC") as null|anything in options
	return choice ? options[choice] : null

/client/proc/agent_npc_stage()
	set category = "Debug.Agent NPC"
	set name = "Agent NPC - Stage (debug)"
	if(!check_rights(R_DEBUG))
		return

	var/datum/agent_binding/binding = agent_npc_pick_binding(src, "Stage which NPC?")
	if(!binding)
		return
	var/datum/ai_controller/agent_social/agent = binding.resolve_controller()
	var/mob/living/pawn = binding.resolve_pawn()
	var/mob/living/partner = agent_npc_pick_partner(src, pawn)
	if(!partner)
		return
	var/list/options = list()
	for(var/datum/agent_stage_preset/preset as anything in agent_stage_presets())
		if(!agent_stage_refusal(preset, agent, partner))
			options[preset.name] = preset
	if(!length(options))
		to_chat(src, span_warning("No preset fits [pawn] with [partner]."))
		return
	var/choice = input(src, "Which state?", "Agent NPC") as null|anything in options
	if(!choice)
		return

	var/datum/agent_stage_preset/preset = options[choice]
	var/list/staged = agent_stage(preset, agent, partner)
	if(staged["refusal"])
		to_chat(src, span_warning("Not staged: [staged["refusal"]]"))
		return
	var/memory = staged["summary"] ? " Memory sent: \"[staged["summary"]]\"" : " No memory for this one."
	var/took = (staged["summary"] && !staged["seeded"]) ? " The sidecar could not be reached, so the memory was not sent." : ""
	to_chat(src, span_notice("Staged '[preset.name]' on [pawn] with [partner].[memory][took]"))
	message_admins("[key_name_admin(src)] staged '[preset.id]' on agent NPC [key_name_admin(pawn)] with [key_name_admin(partner)].")
	log_admin("[key_name(src)] staged '[preset.id]' on agent NPC [key_name(pawn)] with [key_name(partner)].")

/client/proc/agent_npc_seed_memory()
	set category = "Debug.Agent NPC"
	set name = "Agent NPC - Seed memory (debug)"
	if(!check_rights(R_DEBUG))
		return

	var/datum/agent_binding/binding = agent_npc_pick_binding(src, "Whose memory?")
	if(!binding)
		return
	var/text = input(src, "What the character remembers, in its own voice. Up to [AGENT_SEED_TEXT_MAX] characters.", "Agent NPC", "") as null|message
	text = agent_clean_profile_text(text, AGENT_SEED_TEXT_MAX)
	if(!length(text))
		return
	if(!SSagent_npc.seed_memory(binding, text))
		to_chat(src, span_warning("The sidecar could not be reached."))
		return
	to_chat(src, span_notice("Sent. Check the sidecar log for what it kept."))
	log_admin("[key_name(src)] seeded agent NPC [binding.pawn_id]'s memory: [text]")

/client/proc/agent_npc_clear_memory()
	set category = "Debug.Agent NPC"
	set name = "Agent NPC - Clear memory (debug)"
	if(!check_rights(R_DEBUG))
		return

	var/datum/agent_binding/binding = agent_npc_pick_binding(src, "Whose memory?")
	if(!binding)
		return
	if(!SSagent_npc.seed_memory(binding, null))
		to_chat(src, span_warning("The sidecar could not be reached."))
		return
	to_chat(src, span_notice("Cleared: history, waiting answers and the summary."))
	log_admin("[key_name(src)] cleared agent NPC [binding.pawn_id]'s memory.")

/client/proc/agent_npc_poke()
	set category = "Debug.Agent NPC"
	set name = "Agent NPC - Poke (force a decision)"
	if(!check_rights(R_DEBUG))
		return

	var/datum/agent_binding/binding = agent_npc_pick_binding(src, "Poke which one?")
	if(!binding)
		return
	// Clear the pacing floor too, or the poke silently waits for it.
	binding.next_request_at = 0
	binding.consecutive_failures = 0
	binding.mark_dirty("admin_poke", AGENT_EVENT_HIGH)
	to_chat(src, span_notice("Poked. It should ask for a decision within a second."))
	log_admin("[key_name(src)] poked agent NPC [binding.pawn_id].")
