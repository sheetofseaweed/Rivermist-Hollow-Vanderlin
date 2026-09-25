// Controller, reflex and perception tests for the agent social NPC.
// The protocol itself is covered in agent_npc_protocol.dm.

/// Allocate the pilot pawn and force a registration, bypassing the retry cooldown.
/datum/unit_test/proc/agent_test_bound_pawn()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = allocate(/mob/living/carbon/human/species/human/northern/agent_social)
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	if(istype(controller))
		controller.register_cooldown = 0
		controller.ensure_registered()
	return pawn

// ------------------------------------------------------------- flee reflex

/datum/unit_test/agent_npc_attack_sets_flee_target

/datum/unit_test/agent_npc_attack_sets_flee_target/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller, "The pilot pawn must carry an agent_social controller.")

	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)

	TEST_ASSERT_NULL(controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET], "Setup failed: the pawn should start with no threat.")

	controller.on_pawn_attacked(pawn, attacker, 10)

	// flee_target needs BOTH keys. The base handler sets neither, which is why
	// the controller has to override it or the whole reflex tier is decorative.
	TEST_ASSERT_EQUAL(controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET], attacker, "Being attacked must set the flee target.")
	TEST_ASSERT(controller.blackboard[BB_AGENT_FLEE_UNTIL] > world.time, "Being attacked must open a flee window.")
	TEST_ASSERT(controller.blackboard[BB_BASIC_MOB_FLEEING], "The pilot controller must be permanently in fleeing mode; it cannot fight.")

	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_attack_by_self_is_ignored

/datum/unit_test/agent_npc_attack_by_self_is_ignored/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller

	controller.on_pawn_attacked(pawn, pawn, 10)

	TEST_ASSERT_NULL(controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET], "A pawn must not flee from itself.")

	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_flee_recovery_keeps_threat_inside_window

/datum/unit_test/agent_npc_flee_recovery_keeps_threat_inside_window/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)

	controller.on_pawn_attacked(pawn, attacker, 10)
	var/datum/ai_planning_subtree/agent_flee_recovery/recovery = new()
	recovery.SelectBehaviors(controller, 0.5)

	TEST_ASSERT_EQUAL(controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET], attacker, "A threat must not be dropped while the flee window is still open.")

	qdel(recovery)
	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_flee_recovery_clears_dead_threat

/datum/unit_test/agent_npc_flee_recovery_clears_dead_threat/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)

	controller.on_pawn_attacked(pawn, attacker, 10)
	// Without this, the assertion below passes vacuously whenever the threat was
	// never set in the first place.
	TEST_ASSERT_NOTNULL(controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET], "Setup failed: the attack should have set a threat to recover from.")
	attacker.stat = DEAD

	var/datum/ai_planning_subtree/agent_flee_recovery/recovery = new()
	recovery.SelectBehaviors(controller, 0.5)

	TEST_ASSERT_NULL(controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET], "A dead threat must be dropped. run_away_from_target finishes on escape but never clears the target, so a stale one would pin should_idle awake forever.")

	qdel(recovery)
	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_flee_recovery_clears_after_window_expires

/datum/unit_test/agent_npc_flee_recovery_clears_after_window_expires/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)

	controller.on_pawn_attacked(pawn, attacker, 10)
	TEST_ASSERT_NOTNULL(controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET], "Setup failed: the attack should have set a threat to recover from.")
	// Window closed, and the attacker is nowhere the pawn can see.
	controller.set_blackboard_key(BB_AGENT_FLEE_UNTIL, world.time - 1)
	attacker.forceMove(locate(1, 1, attacker.z))

	var/datum/ai_planning_subtree/agent_flee_recovery/recovery = new()
	recovery.SelectBehaviors(controller, 0.5)

	TEST_ASSERT_NULL(controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET], "Once the window closes and the threat is out of sight, the pawn must settle.")

	qdel(recovery)
	agent_test_restore_subsystem(saved, controller.binding)

// ---------------------------------------------------------------- ordering

/datum/unit_test/agent_npc_agent_subtree_sits_below_reflexes

/datum/unit_test/agent_npc_agent_subtree_sits_below_reflexes/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller

	var/agent_index = controller.get_subtree_index(/datum/ai_planning_subtree/agent_intent)
	var/flee_index = controller.get_subtree_index(/datum/ai_planning_subtree/flee_target)
	var/stand_index = controller.get_subtree_index(/datum/ai_planning_subtree/generic_stand)

	TEST_ASSERT(agent_index > 0, "The agent subtree must be present in the plan.")
	TEST_ASSERT(agent_index > flee_index, "The agent must not be able to outrank fleeing.")
	TEST_ASSERT(agent_index > stand_index, "The agent must not be able to outrank standing up.")

	agent_test_restore_subsystem(saved, controller.binding)

// ------------------------------------------------------------- wakefulness

/datum/unit_test/agent_npc_bound_pawn_stays_awake_on_quiet_zlevel

/datum/unit_test/agent_npc_bound_pawn_stays_awake_on_quiet_zlevel/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller.binding, "Setup failed: the pawn must be bound for the override to apply.")

	var/pawn_z = pawn.z
	var/list/saved_town_z = SSmobs.town_z.Copy()
	var/list/saved_clients = SSmobs.clients_by_zlevel[pawn_z]

	// Make this z-level exactly the case the engine would switch off: not town,
	// and nobody watching.
	SSmobs.town_z.Cut()
	SSmobs.clients_by_zlevel[pawn_z] = list()

	var/with_binding = controller.get_expected_ai_status()

	controller.binding = null
	var/without_binding = controller.get_expected_ai_status()

	SSmobs.town_z = saved_town_z
	SSmobs.clients_by_zlevel[pawn_z] = saved_clients

	TEST_ASSERT_EQUAL(without_binding, AI_STATUS_OFF, "Setup failed: an unbound controller on an empty z-level should be switched off.")
	TEST_ASSERT_EQUAL(with_binding, AI_STATUS_ON, "A bound agent must keep planning wherever it spawned, or it registers, receives events and silently never acts.")

	agent_test_restore_subsystem(saved, null)

/datum/unit_test/agent_npc_wakefulness_does_not_override_death

/datum/unit_test/agent_npc_wakefulness_does_not_override_death/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller.binding, "Setup failed: the pawn must be bound.")

	pawn.stat = DEAD

	TEST_ASSERT_EQUAL(controller.get_expected_ai_status(), AI_STATUS_OFF, "The wakefulness override must only cover the empty z-level case. Death still wins.")

	pawn.stat = CONSCIOUS
	agent_test_restore_subsystem(saved, controller.binding)

// ---------------------------------------------------------------- perception

/datum/unit_test/agent_npc_observation_offers_resolvable_handles

/datum/unit_test/agent_npc_observation_offers_resolvable_handles/Run()
	var/mob/living/carbon/human/pawn = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human)
	bystander.forceMove(get_turf(pawn))

	var/list/built = agent_build_observation(pawn, 1)
	var/datum/agent_observation/observation = built["observation"]
	var/list/payload = built["payload"]

	TEST_ASSERT_NOTNULL(observation, "The builder must return an observation.")
	TEST_ASSERT(length(payload["entities"]) > 0, "A bystander standing on the same turf should appear in the scene.")

	var/found = FALSE
	for(var/list/entity as anything in payload["entities"])
		if(observation.resolve(entity["handle"]) == bystander)
			found = TRUE
			break

	TEST_ASSERT(found, "Every offered handle must resolve back to the atom it was offered for.")
	qdel(observation)

/datum/unit_test/agent_npc_observation_rejects_unoffered_handle

/datum/unit_test/agent_npc_observation_rejects_unoffered_handle/Run()
	var/mob/living/carbon/human/pawn = allocate(/mob/living/carbon/human)
	var/list/built = agent_build_observation(pawn, 1)
	var/datum/agent_observation/observation = built["observation"]

	TEST_ASSERT_NULL(observation.resolve("h-never-offered"), "A handle that was never offered must not resolve. This is the authorisation boundary.")
	TEST_ASSERT_NULL(observation.resolve(null), "A null handle must not resolve.")
	TEST_ASSERT_NULL(observation.resolve(""), "An empty handle must not resolve.")
	qdel(observation)

/datum/unit_test/agent_npc_observation_hides_exact_health

/datum/unit_test/agent_npc_observation_hides_exact_health/Run()
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)

	TEST_ASSERT_EQUAL(agent_describe_condition(target), "unhurt", "A fresh mob should read as unhurt.")

	// Toxin pools like brute does, and unlike brute it can be set directly in a test.
	target.setToxLoss(target.get_effective_defeat_threshold() * 0.6)
	var/beaten_band = agent_describe_condition(target)
	target.setToxLoss(0)
	TEST_ASSERT_EQUAL(beaten_band, "badly hurt", "Condition must be a coarse band of the beating, never an exact figure.")

	target.stat = DEAD
	TEST_ASSERT_EQUAL(agent_describe_condition(target), "dead", "A dead mob should read as dead regardless of its health value.")

	target.stat = CONSCIOUS

// ----------------------------------------------- handle authorisation (#5)

/datum/unit_test/agent_npc_dispatch_rejects_unoffered_handle

/datum/unit_test/agent_npc_dispatch_rejects_unoffered_handle/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/agent_binding/binding = controller.binding
	TEST_ASSERT_NOTNULL(binding, "Setup failed: the pawn must be bound.")

	// Give the binding a real observation, then name a handle it never offered.
	var/list/built = agent_build_observation(pawn, 1)
	binding.set_observation(built["observation"])

	var/datum/agent_response/response = new()
	response.ok = TRUE
	response.action = list("name" = "approach", "handle" = "h-never-offered")

	SSagent_npc.dispatch_decision(binding, response)

	var/list/last_event = binding.events[length(binding.events)]
	TEST_ASSERT_EQUAL(last_event["detail"]["state"], AGENT_RESULT_REJECTED, "A structurally valid handle that was never offered must be rejected at execution, which is the whole reason handle checks are deferred past parsing.")

	qdel(response)
	agent_test_restore_subsystem(saved, binding)

// -------------------------------------------------------- hearing adapter

/datum/unit_test/agent_npc_hearing_adapter_records_speech

/datum/unit_test/agent_npc_hearing_adapter_records_speech/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/agent_binding/binding = controller.binding
	TEST_ASSERT_NOTNULL(binding, "Setup failed: the pawn must be bound.")

	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human)
	binding.take_events()

	// COMSIG_MOVABLE_HEAR delivers the emitting proc's whole args list as ONE
	// argument. A handler taking unpacked parameters binds the list to the wrong
	// slot and compiles clean, so the shape matters.
	var/list/hearing_args = list("composed", speaker, null, "hello there")
	controller.on_pawn_heard(pawn, hearing_args)

	TEST_ASSERT_EQUAL(length(binding.events), 1, "Overheard speech must reach the agent as an event.")
	var/list/entry = binding.events[1]
	TEST_ASSERT_EQUAL(entry["event"], "heard_speech", "The event should be recorded as heard speech.")
	TEST_ASSERT_NOTNULL(entry["detail"]["text"], "The event must carry the text this character actually understood.")

	agent_test_restore_subsystem(saved, binding)

// ------------------------------------------------- immediate actions (phase 4)

/datum/unit_test/agent_npc_speech_strips_mode_prefixes

/datum/unit_test/agent_npc_speech_strips_mode_prefixes/Run()
	// say() reads these as whisper, sing, radio, language and emote keys before
	// it treats anything as speech, so agent text must never carry them.
	TEST_ASSERT_EQUAL(agent_sanitise_speech(";hello"), "hello", "A radio prefix must be stripped.")
	TEST_ASSERT_EQUAL(agent_sanitise_speech("#quiet"), "quiet", "A whisper prefix must be stripped.")
	TEST_ASSERT_EQUAL(agent_sanitise_speech("*wave"), "wave", "An emote prefix must be stripped.")
	TEST_ASSERT_EQUAL(agent_sanitise_speech(":;#hi"), "hi", "Stacked prefixes must all be stripped.")
	TEST_ASSERT_EQUAL(agent_sanitise_speech("  spaced  "), "spaced", "Speech should be trimmed.")

	TEST_ASSERT_NULL(agent_sanitise_speech(";;;"), "Text that is nothing but prefixes must come back null.")
	TEST_ASSERT_NULL(agent_sanitise_speech(""), "Empty speech must come back null.")
	TEST_ASSERT_NULL(agent_sanitise_speech(null), "Null speech must come back null.")

/datum/unit_test/agent_npc_say_executes_and_reports

/datum/unit_test/agent_npc_say_executes_and_reports/Run()
	var/mob/living/carbon/human/pawn = allocate(/mob/living/carbon/human)

	var/list/outcome = agent_execute_say(pawn, "good morning")
	TEST_ASSERT_EQUAL(outcome["state"], AGENT_RESULT_SUCCEEDED, "Plain speech should succeed.")

	var/list/empty = agent_execute_say(pawn, ";;;")
	TEST_ASSERT_EQUAL(empty["state"], AGENT_RESULT_REJECTED, "Speech that sanitises to nothing must be rejected, not spoken.")

	pawn.stat = UNCONSCIOUS
	var/list/downed = agent_execute_say(pawn, "still talking")
	TEST_ASSERT_EQUAL(downed["state"], AGENT_RESULT_REJECTED, "An unconscious pawn must not speak.")
	pawn.stat = CONSCIOUS

/datum/unit_test/agent_npc_emote_allowlist_is_closed

/datum/unit_test/agent_npc_emote_allowlist_is_closed/Run()
	var/mob/living/carbon/human/pawn = allocate(/mob/living/carbon/human)

	var/list/good = agent_execute_emote(pawn, "wave")
	TEST_ASSERT_EQUAL(good["state"], AGENT_RESULT_UNVERIFIED, "An allowed emote should dispatch, and report unverified because emote() reports nothing back.")

	var/list/bad = agent_execute_emote(pawn, "deathgasp")
	TEST_ASSERT_EQUAL(bad["state"], AGENT_RESULT_REJECTED, "An emote outside the allowlist must be refused, even though it exists in the game.")

// ------------------------------------------------------------ profile gate

/datum/unit_test/agent_npc_profile_reaches_the_envelope

/datum/unit_test/agent_npc_profile_reaches_the_envelope/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/agent_binding/binding = controller.binding

	TEST_ASSERT_NOTNULL(controller.profile, "The pilot controller must carry a profile instance.")

	var/list/payload = binding.profile_payload()
	TEST_ASSERT_NOTNULL(payload, "The profile must reach the wire, or the model has no idea who it is.")
	TEST_ASSERT_NOTNULL(payload["persona"], "The brief must carry a persona.")
	TEST_ASSERT(length(payload["permitted_actions"]) > 0, "permitted_actions must survive to_payload. initial() on a list var returns null, which would silently empty it.")

	agent_test_restore_subsystem(saved, binding)

/datum/unit_test/agent_npc_profile_gates_permitted_actions

/datum/unit_test/agent_npc_profile_gates_permitted_actions/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/agent_binding/binding = controller.binding

	TEST_ASSERT(binding.profile_permits("say"), "The villager profile should permit speech.")
	TEST_ASSERT(binding.profile_permits("approach"), "The villager profile should permit approaching.")

	// Same character, narrower permissions.
	QDEL_NULL(controller.profile)
	controller.profile = new /datum/agent_profile/villager/sedentary()

	TEST_ASSERT(binding.profile_permits("say"), "A sedentary villager should still speak.")
	TEST_ASSERT(!binding.profile_permits("approach"), "A sedentary villager must not be able to walk anywhere. The vocabulary is global; the profile narrows it per character.")

	agent_test_restore_subsystem(saved, binding)

/datum/unit_test/agent_npc_dispatch_refuses_unpermitted_action

/datum/unit_test/agent_npc_dispatch_refuses_unpermitted_action/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/agent_binding/binding = controller.binding

	QDEL_NULL(controller.profile)
	controller.profile = new /datum/agent_profile/villager/sedentary()
	binding.take_events()

	var/datum/agent_response/response = new()
	response.ok = TRUE
	response.action = list("name" = "approach", "handle" = "h1")
	SSagent_npc.dispatch_decision(binding, response)

	TEST_ASSERT_NULL(binding.current_intent, "An action the profile forbids must never become an objective.")
	var/list/entry = binding.events[length(binding.events)]
	TEST_ASSERT_EQUAL(entry["detail"]["state"], AGENT_RESULT_REJECTED, "An action outside the character's permitted list must be rejected before anything executes.")

	qdel(response)
	agent_test_restore_subsystem(saved, binding)

/datum/unit_test/agent_npc_model_refusal_is_counted_and_reported

/datum/unit_test/agent_npc_model_refusal_is_counted_and_reported/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/agent_binding/binding = controller.binding
	binding.take_events()

	// A sidecar that reached the model but could not get a usable action back.
	// This returns HTTP 200, so from outside it looks like a working request.
	var/datum/agent_response/response = new()
	response.ok = TRUE
	response.model_refusal = "model output was not json"

	var/before = SSagent_npc.refusal_counts[AGENT_REFUSE_MODEL] || 0
	SSagent_npc.handle_response(binding, response)

	TEST_ASSERT_EQUAL(SSagent_npc.refusal_counts[AGENT_REFUSE_MODEL] || 0, before + 1, "A model refusal must be counted, or the likeliest failure mode is invisible in the status panel.")

	var/list/entry = binding.events[length(binding.events)]
	TEST_ASSERT_EQUAL(entry["detail"]["state"], AGENT_RESULT_REJECTED, "A model refusal must be reported as a rejection.")
	TEST_ASSERT_EQUAL(entry["detail"]["detail"], "model output was not json", "The reported detail must carry the sidecar's reason, not a generic string.")

	qdel(response)
	agent_test_restore_subsystem(saved, binding)

/datum/unit_test/agent_npc_missing_profile_permits_nothing

/datum/unit_test/agent_npc_missing_profile_permits_nothing/Run()
	// A binding with no agent controller behind it. Fail closed, not open.
	var/datum/agent_binding/binding = agent_test_binding()

	TEST_ASSERT_NULL(binding.profile_payload(), "No profile means nothing to send.")
	TEST_ASSERT(!binding.profile_permits("say"), "With no profile the answer must be no, not yes.")
	TEST_ASSERT(!binding.profile_permits("wait"), "Even harmless actions must fail closed without a profile.")

// ------------------------------------------------------ objectives (phase 4)

/datum/unit_test/agent_npc_dispatch_starts_an_objective

/datum/unit_test/agent_npc_dispatch_starts_an_objective/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/agent_binding/binding = controller.binding
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human)
	bystander.forceMove(get_turf(pawn))

	var/list/built = agent_build_observation(pawn, 1)
	var/datum/agent_observation/observation = built["observation"]
	binding.set_observation(observation)

	var/handle
	for(var/key in observation.handles)
		if(observation.resolve(key) == bystander)
			handle = key
			break
	TEST_ASSERT_NOTNULL(handle, "Setup failed: the bystander should have been offered a handle.")

	var/datum/agent_response/response = new()
	response.ok = TRUE
	response.action = list("name" = "approach", "handle" = handle)
	SSagent_npc.dispatch_decision(binding, response)

	TEST_ASSERT_NOTNULL(binding.current_intent, "An approach decision must become a live objective.")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AGENT_OBJECTIVE_TARGET], bystander, "The objective target must be the atom the handle resolved to.")

	qdel(response)
	agent_test_restore_subsystem(saved, binding)

/datum/unit_test/agent_npc_retarget_spares_reflex_behaviors

/datum/unit_test/agent_npc_retarget_spares_reflex_behaviors/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human)
	bystander.forceMove(get_turf(pawn))

	controller.set_blackboard_key(BB_AGENT_OBJECTIVE_TARGET, bystander)
	controller.binding.begin_intent(list("name" = "approach"))
	controller.queue_behavior(/datum/ai_behavior/agent_approach, BB_AGENT_OBJECTIVE_TARGET)

	// Stand a reflex behavior alongside it. Retargeting must not touch this.
	var/datum/ai_behavior/reflex = GET_AI_BEHAVIOR(/datum/ai_behavior/break_restraints)
	TEST_ASSERT_NOTNULL(reflex, "Setup failed: the reflex behavior singleton should exist.")
	LAZYADDASSOCLIST(controller.current_behaviors, reflex, TRUE)

	var/cancelled = controller.cancel_agent_objective()

	TEST_ASSERT(cancelled, "Retargeting should have cancelled the agent behavior.")
	TEST_ASSERT(LAZYACCESS(controller.current_behaviors, reflex), "Retargeting must spare reflex behaviors. CancelActions() finishes everything, which would cancel an active resist or restraint break.")

	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_objective_behaviors_allow_planning

/datum/unit_test/agent_npc_objective_behaviors_allow_planning/Run()
	// able_to_plan() refuses to plan at all while ANY running behavior lacks
	// this flag. Without it the agent's own objective would block the reflex
	// subtrees above it, suppressing the safety layer it is meant to yield to.
	for(var/behavior_type in list(/datum/ai_behavior/agent_approach, /datum/ai_behavior/agent_approach/use))
		var/datum/ai_behavior/behavior = GET_AI_BEHAVIOR(behavior_type)
		TEST_ASSERT_NOTNULL(behavior, "[behavior_type] should be registered as a behavior singleton.")
		TEST_ASSERT(behavior.behavior_flags & AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION, "[behavior_type] must allow planning during execution, or it starves the reflexes ranked above it.")

/datum/unit_test/agent_npc_reflex_guard_blocks_objectives

/datum/unit_test/agent_npc_reflex_guard_blocks_objectives/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)

	TEST_ASSERT(controller.reflex_guard_clear(), "A healthy standing pawn should be free to pursue an objective.")

	controller.on_pawn_attacked(pawn, attacker, 10)
	TEST_ASSERT(!controller.reflex_guard_clear(), "A pawn with a live threat is fleeing, and must not pursue agent objectives.")

	controller.clear_threat()
	TEST_ASSERT(controller.reflex_guard_clear(), "Once the threat clears, objectives may resume.")

	agent_test_restore_subsystem(saved, controller.binding)

/datum/unit_test/agent_npc_interruption_is_reported_once

/datum/unit_test/agent_npc_interruption_is_reported_once/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/agent_binding/binding = controller.binding
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	bystander.forceMove(get_turf(pawn))

	controller.set_blackboard_key(BB_AGENT_OBJECTIVE_TARGET, bystander)
	binding.begin_intent(list("name" = "approach"))
	controller.queue_behavior(/datum/ai_behavior/agent_approach, BB_AGENT_OBJECTIVE_TARGET)
	binding.take_events()

	// A reflex takes the wheel mid-objective.
	controller.on_pawn_attacked(pawn, attacker, 10)
	controller.cancel_agent_objective()

	TEST_ASSERT_NULL(binding.current_intent, "An interrupted objective must end, not linger.")

	// Count results only. Being attacked also pushes its own event, so a raw
	// length check would be measuring the wrong thing.
	var/results = 0
	var/reported_state
	for(var/list/entry as anything in binding.events)
		if(entry["event"] != "action_result")
			continue
		results++
		reported_state = entry["detail"]["state"]

	TEST_ASSERT_EQUAL(results, 1, "The interruption must be reported exactly once, not once per plan.")
	TEST_ASSERT_EQUAL(reported_state, AGENT_RESULT_INTERRUPTED, "A reflex taking over is an interruption, not a failure to reach. Got [reported_state].")

	// A second finish must not produce a second report.
	binding.finish_intent(AGENT_RESULT_FAILED, "should not appear")

	var/results_after = 0
	for(var/list/entry as anything in binding.events)
		if(entry["event"] == "action_result")
			results_after++
	TEST_ASSERT_EQUAL(results_after, 1, "Finishing an already finished objective must not report again.")

	agent_test_restore_subsystem(saved, binding)

/datum/unit_test/agent_npc_hearing_ignores_own_speech

/datum/unit_test/agent_npc_hearing_ignores_own_speech/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/agent_binding/binding = controller.binding
	binding.take_events()

	controller.on_pawn_heard(pawn, list("composed", pawn, null, "talking to myself"))

	TEST_ASSERT_EQUAL(length(binding.events), 0, "A pawn must not treat its own speech as an event, or two agents can talk each other into a loop.")

	agent_test_restore_subsystem(saved, binding)

// ------------------------------------------------- bounded continuation

/datum/unit_test/agent_npc_external_event_grants_continuation

/datum/unit_test/agent_npc_external_event_grants_continuation/Run()
	var/datum/agent_binding/binding = agent_test_binding()
	TEST_ASSERT_EQUAL(binding.continuation_budget, 0, "A fresh binding drives nothing on its own.")

	binding.mark_dirty("heard_speech")

	TEST_ASSERT_EQUAL(binding.continuation_budget, AGENT_CONTINUATION_BUDGET, "A real external event must start a bounded interaction.")
	TEST_ASSERT(binding.continuation_expires_at > world.time, "The interaction must carry a deadline as well as a count.")

/datum/unit_test/agent_npc_completed_action_continues_the_chain

/datum/unit_test/agent_npc_completed_action_continues_the_chain/Run()
	var/datum/agent_binding/binding = agent_test_binding()
	binding.mark_dirty("heard_speech")
	binding.take_events()
	TEST_ASSERT(!binding.dirty, "Setup failed: taking events should have cleared dirty.")

	// This is the defect the whole feature exists for: the NPC walked to the
	// salt, finished, and then sat there because results scheduled nothing.
	var/continued = binding.complete_action(AGENT_RESULT_SUCCEEDED, "arrived")

	TEST_ASSERT(continued, "A completed step must be able to ask for the next decision.")
	TEST_ASSERT(binding.dirty, "Continuing means the binding is due for another request.")
	TEST_ASSERT_EQUAL(binding.continuation_budget, AGENT_CONTINUATION_BUDGET - 1, "Each self-driven turn must consume budget.")

/datum/unit_test/agent_npc_continuation_stops_at_the_cap

/datum/unit_test/agent_npc_continuation_stops_at_the_cap/Run()
	var/datum/agent_binding/binding = agent_test_binding()
	binding.mark_dirty("heard_speech")

	for(var/i in 1 to AGENT_CONTINUATION_BUDGET)
		TEST_ASSERT(binding.complete_action(AGENT_RESULT_SUCCEEDED, "step [i]"), "Step [i] should still be inside the budget.")

	binding.take_events()
	// Without a cap this is where an NPC talks to itself until the round ends.
	TEST_ASSERT(!binding.complete_action(AGENT_RESULT_SUCCEEDED, "one too many"), "The chain must stop exactly at the cap.")
	TEST_ASSERT(!binding.dirty, "A chain that has run out must not schedule another request.")

/datum/unit_test/agent_npc_wait_ends_the_chain_but_keeps_events

/datum/unit_test/agent_npc_wait_ends_the_chain_but_keeps_events/Run()
	var/datum/agent_binding/binding = agent_test_binding()
	binding.mark_dirty("heard_speech")
	binding.take_events()
	binding.push_event("heard_speech", AGENT_EVENT_LOW, list("text" = "said while busy"))

	binding.complete_action(AGENT_RESULT_SUCCEEDED, "waiting", was_wait = TRUE)

	TEST_ASSERT_EQUAL(binding.continuation_budget, 0, "Choosing to wait must end the self-driven chain.")
	TEST_ASSERT(length(binding.events) >= 1, "Settling down must not erase what a player said while the NPC was busy.")

/datum/unit_test/agent_npc_expired_window_ends_the_chain

/datum/unit_test/agent_npc_expired_window_ends_the_chain/Run()
	var/datum/agent_binding/binding = agent_test_binding()
	binding.mark_dirty("heard_speech")
	binding.take_events()
	// Budget remains, but the interaction is long over.
	binding.continuation_expires_at = world.time - 1

	TEST_ASSERT(!binding.complete_action(AGENT_RESULT_SUCCEEDED, "late"), "A lapsed interaction must not continue on leftover budget.")
	TEST_ASSERT(!binding.dirty, "A lapsed interaction must not schedule another request.")

/datum/unit_test/agent_npc_agent_speech_does_not_replenish

/datum/unit_test/agent_npc_agent_speech_does_not_replenish/Run()
	var/datum/agent_binding/binding = agent_test_binding()
	binding.mark_dirty("heard_speech")
	binding.complete_action(AGENT_RESULT_SUCCEEDED, "spent one")
	var/after_spending = binding.continuation_budget

	// Another agent NPC speaking. Heard, but it must not buy more turns, or two
	// agents refresh each other forever and no per-turn cap can stop them.
	binding.mark_dirty("heard_speech", AGENT_EVENT_LOW, null, replenish = FALSE)

	TEST_ASSERT_EQUAL(binding.continuation_budget, after_spending, "Agent-to-agent speech must not refresh the continuation budget.")

	binding.mark_dirty("heard_speech")
	TEST_ASSERT_EQUAL(binding.continuation_budget, AGENT_CONTINUATION_BUDGET, "A player speaking must still refresh it.")

/datum/unit_test/agent_npc_revoke_ends_continuation

/datum/unit_test/agent_npc_revoke_ends_continuation/Run()
	var/datum/agent_binding/binding = agent_test_binding()
	binding.mark_dirty("heard_speech")
	TEST_ASSERT(binding.continuation_budget > 0, "Setup failed: the interaction should be live.")

	binding.revoke("kill switch")

	TEST_ASSERT_EQUAL(binding.continuation_budget, 0, "A revoked binding must not keep driving itself.")
