// Touch: the gentle action, and the NPC noticing hands laid on it. Asked for on 2026-09-23.

/// A bound pawn and a person beside it, with the subsystem armed. Restore with agent_test_restore_subsystem.
/datum/unit_test/proc/agent_test_pawn_and_person()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/mob/living/carbon/human/person = allocate(/mob/living/carbon/human/species/human/northern)
	return list(pawn, person)

// ------------------------------------------------------------ the touch action

/datum/unit_test/agent_npc_touch_validates

/datum/unit_test/agent_npc_touch_validates/Run()
	var/list/plain = agent_validate_action(list("name" = "touch", "handle" = "h1"))
	TEST_ASSERT_NOTNULL(plain, "touch with a handle is valid.")
	TEST_ASSERT_EQUAL(plain["key"], AGENT_TOUCH_TAP, "A touch with no way given is a tap.")
	var/list/hug = agent_validate_action(list("name" = "touch", "handle" = "h1", "key" = "hug"))
	TEST_ASSERT_EQUAL(hug["key"], "hug", "The way asked for must survive validation.")
	TEST_ASSERT_NULL(agent_validate_action(list("name" = "touch")), "touch without a handle must be rejected.")

/datum/unit_test/agent_npc_touch_never_harms_with_a_weapon

/datum/unit_test/agent_npc_touch_never_harms_with_a_weapon/Run()
	var/mob/living/carbon/human/pawn = allocate(/mob/living/carbon/human/species/human/northern)
	var/mob/living/carbon/human/person = allocate(/mob/living/carbon/human/species/human/northern)
	var/obj/item/weapon/knife/dagger/dagger = allocate(/obj/item/weapon/knife/dagger)
	TEST_ASSERT(pawn.put_in_active_hand(dagger), "Setup failed: the dagger must be held.")
	var/health_before = person.health

	var/list/outcome = agent_execute_touch(pawn, person, AGENT_TOUCH_TAP)

	// The reason touch exists apart from use: use clicks, and a click with a dagger is a stab.
	TEST_ASSERT_EQUAL(person.health, health_before, "A touch must never hurt, whatever the NPC is holding.")
	TEST_ASSERT_EQUAL(outcome["state"], AGENT_RESULT_SUCCEEDED, "A tap beside someone must succeed.")

/datum/unit_test/agent_npc_touch_ways_behave

/datum/unit_test/agent_npc_touch_ways_behave/Run()
	var/mob/living/carbon/human/pawn = allocate(/mob/living/carbon/human/species/human/northern)
	var/mob/living/carbon/human/person = allocate(/mob/living/carbon/human/species/human/northern)

	var/list/hug = agent_execute_touch(pawn, person, AGENT_TOUCH_HUG)
	TEST_ASSERT_EQUAL(hug["state"], AGENT_RESULT_SUCCEEDED, "A hug beside someone must succeed.")
	var/list/help_standing = agent_execute_touch(pawn, person, AGENT_TOUCH_HELP)
	TEST_ASSERT_EQUAL(help_standing["state"], AGENT_RESULT_REJECTED, "Helping up someone already standing makes no sense.")
	var/list/unknown = agent_execute_touch(pawn, person, "kiss")
	TEST_ASSERT_EQUAL(unknown["state"], AGENT_RESULT_REJECTED, "A way that is not offered must be refused.")
	TEST_ASSERT(!("kiss" in agent_touch_ways()), "Kisses are not the model's to start.")

/datum/unit_test/agent_npc_touch_dispatch_checks_target_and_way

/datum/unit_test/agent_npc_touch_dispatch_checks_target_and_way/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/pair = agent_test_pawn_and_person()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = pair[1]
	var/mob/living/carbon/human/person = pair[2]
	var/obj/item/natural/cloth/cloth = allocate(/obj/item/natural/cloth)
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/agent_binding/binding = controller?.binding
	TEST_ASSERT_NOTNULL(binding, "Setup failed: the pawn must be bound.")

	var/list/built = agent_build_observation(pawn, binding.observation_revision)
	binding.set_observation(built["observation"])
	var/datum/agent_observation/observation = binding.last_observation
	var/cloth_handle
	var/person_handle
	for(var/handle in observation.handles)
		var/atom/resolved = observation.resolve(handle)
		if(resolved == cloth)
			cloth_handle = handle
		if(resolved == person)
			person_handle = handle
	TEST_ASSERT_NOTNULL(cloth_handle, "Setup failed: the cloth must be offered.")
	TEST_ASSERT_NOTNULL(person_handle, "Setup failed: the person must be offered.")

	var/datum/agent_response/response = new()
	response.ok = TRUE
	response.action = list("name" = "touch", "handle" = cloth_handle, "key" = AGENT_TOUCH_TAP)
	SSagent_npc.dispatch_decision(binding, response)
	var/intent_on_thing = binding.current_intent

	response.action = list("name" = "touch", "handle" = person_handle, "key" = "kiss")
	SSagent_npc.dispatch_decision(binding, response)
	var/intent_on_bad_way = binding.current_intent

	response.action = list("name" = "touch", "handle" = person_handle, "key" = AGENT_TOUCH_HUG)
	SSagent_npc.dispatch_decision(binding, response)
	var/list/intent_ok = binding.current_intent
	agent_test_restore_subsystem(saved, binding)

	TEST_ASSERT_NULL(intent_on_thing, "Touching a thing must be refused before any walking starts.")
	TEST_ASSERT_NULL(intent_on_bad_way, "An unknown way must be refused before any walking starts.")
	TEST_ASSERT_NOTNULL(intent_ok, "A hug on a person in view must become an objective.")
	TEST_ASSERT_EQUAL(intent_ok["key"], AGENT_TOUCH_HUG, "The objective must remember how to touch.")

/datum/unit_test/agent_npc_use_on_a_person_is_refused

/datum/unit_test/agent_npc_use_on_a_person_is_refused/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/pair = agent_test_pawn_and_person()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = pair[1]
	var/mob/living/carbon/human/person = pair[2]
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/agent_binding/binding = controller?.binding
	TEST_ASSERT_NOTNULL(binding, "Setup failed: the pawn must be bound.")

	var/list/built = agent_build_observation(pawn, binding.observation_revision)
	binding.set_observation(built["observation"])
	var/person_handle
	for(var/handle in binding.last_observation.handles)
		if(binding.last_observation.resolve(handle) == person)
			person_handle = handle
	TEST_ASSERT_NOTNULL(person_handle, "Setup failed: the person must be offered.")

	var/datum/agent_response/response = new()
	response.ok = TRUE
	response.action = list("name" = "use", "handle" = person_handle)
	SSagent_npc.dispatch_decision(binding, response)
	var/intent = binding.current_intent
	agent_test_restore_subsystem(saved, binding)

	// A click with a dagger in hand is a stab. This NPC cannot fight, so people get touch, never use.
	TEST_ASSERT_NULL(intent, "use on a person must be refused before any walking starts.")

// ------------------------------------------------------------- being touched

/datum/unit_test/agent_npc_hand_on_the_npc_is_noticed

/datum/unit_test/agent_npc_hand_on_the_npc_is_noticed/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/pair = agent_test_pawn_and_person()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = pair[1]
	var/mob/living/carbon/human/person = pair[2]
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	controller.binding.take_events()

	person.cmode = FALSE
	person.used_intent = new /datum/intent/unarmed/help(person)
	// The real signal, so the registration in PossessPawn is what is tested.
	SEND_SIGNAL(pawn, COMSIG_ATOM_ATTACK_HAND, person, null)
	var/was_dirty = controller.binding.dirty
	var/list/events = agent_test_events_named(controller.binding.take_events(), "physical")

	person.cmode = TRUE
	SEND_SIGNAL(pawn, COMSIG_ATOM_ATTACK_HAND, person, null)
	var/list/combat_events = agent_test_events_named(controller.binding.take_events(), "physical")
	person.cmode = FALSE
	agent_test_restore_subsystem(saved, controller.binding)

	// A help-click on someone standing does nothing in game, so this is the only way the NPC learns of it.
	TEST_ASSERT_EQUAL(length(events), 1, "A hand laid on the NPC must reach it.")
	var/list/entry = events[1]
	var/list/detail = entry["detail"]
	TEST_ASSERT_EQUAL(detail["what"], AGENT_STIMULUS_TOUCHED, "A help-intent hand is a touch.")
	TEST_ASSERT(was_dirty, "Being touched must buy a decision, like being spoken to.")
	TEST_ASSERT_EQUAL(length(combat_events), 0, "A combat-mode hand is reported as an attack, not twice.")

/datum/unit_test/agent_npc_touch_kinds_follow_intent

/datum/unit_test/agent_npc_touch_kinds_follow_intent/Run()
	var/mob/living/carbon/human/person = allocate(/mob/living/carbon/human/species/human/northern)
	person.used_intent = new /datum/intent/unarmed/help(person)
	TEST_ASSERT_EQUAL(agent_touch_kind(person), AGENT_STIMULUS_TOUCHED, "Help intent is a touch.")
	person.used_intent = new /datum/intent/unarmed/grab(person)
	TEST_ASSERT_EQUAL(agent_touch_kind(person), AGENT_STIMULUS_GRABBED, "Grab intent is a grab.")
	person.used_intent = new /datum/intent/unarmed/shove(person)
	TEST_ASSERT_EQUAL(agent_touch_kind(person), AGENT_STIMULUS_SHOVED, "Disarm intent is a shove.")
	person.used_intent = null
	TEST_ASSERT_EQUAL(agent_touch_kind(person), AGENT_STIMULUS_TOUCHED, "No intent is no evidence of harm.")

/datum/unit_test/agent_npc_being_fed_is_noticed

/datum/unit_test/agent_npc_being_fed_is_noticed/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/pair = agent_test_pawn_and_person()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = pair[1]
	var/mob/living/carbon/human/person = pair[2]
	var/obj/item/natural/cloth/bread_stand_in = allocate(/obj/item/natural/cloth)
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	controller.binding.take_events()

	SEND_SIGNAL(pawn, COMSIG_MOB_FED, person, bread_stand_in)
	var/list/events = agent_test_events_named(controller.binding.take_events(), "physical")
	agent_test_restore_subsystem(saved, controller.binding)

	TEST_ASSERT_EQUAL(length(events), 1, "Being fed must reach the NPC.")
	var/list/entry = events[1]
	var/list/detail = entry["detail"]
	TEST_ASSERT_EQUAL(detail["what"], AGENT_STIMULUS_FED, "It must say what happened.")
	TEST_ASSERT_EQUAL(detail["item"], "[bread_stand_in.name]", "It must say what was fed.")

/datum/unit_test/agent_npc_repeated_touches_are_counted

/datum/unit_test/agent_npc_repeated_touches_are_counted/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/pair = agent_test_pawn_and_person()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = pair[1]
	var/mob/living/carbon/human/person = pair[2]
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	controller.binding.take_events()

	var/first = controller.note_stimulus(AGENT_STIMULUS_TOUCHED, person)
	var/second = controller.note_stimulus(AGENT_STIMULUS_TOUCHED, person)
	var/third = controller.note_stimulus(AGENT_STIMULUS_TOUCHED, person)
	var/list/events = agent_test_events_named(controller.binding.take_events(), "physical")
	agent_test_restore_subsystem(saved, controller.binding)

	TEST_ASSERT_EQUAL(first, "sent", "The first touch is news.")
	TEST_ASSERT_EQUAL(second, "coalesced", "A repeat must be counted, not queued again.")
	TEST_ASSERT_EQUAL(third, "coalesced", "Every repeat must be counted.")
	// Twelve slots. A player clicking the NPC repeatedly must not push out what others said.
	TEST_ASSERT_EQUAL(length(events), 1, "Repeated touches must fill one slot.")
	var/list/entry = events[1]
	var/list/detail = entry["detail"]
	TEST_ASSERT_EQUAL(detail["count"], 3, "The count must say how many times.")

/datum/unit_test/agent_npc_agent_touches_are_capped

/datum/unit_test/agent_npc_agent_touches_are_capped/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/pair = agent_test_agent_pair()
	var/mob/living/carbon/human/species/human/northern/agent_social/listener = pair[1]
	var/mob/living/carbon/human/species/human/northern/agent_social/toucher = pair[2]
	var/datum/ai_controller/agent_social/controller = listener.ai_controller
	var/datum/ai_controller/agent_social/toucher_controller = toucher.ai_controller
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the listener must be bound.")

	for(var/i in 1 to AGENT_MAX_AGENT_EXCHANGES)
		controller.binding.note_agent_exchange(toucher)
	var/route = controller.note_stimulus(AGENT_STIMULUS_TOUCHED, toucher)
	SSagent_npc.unregister_pawn(toucher_controller.binding, "test teardown")
	agent_test_restore_subsystem(saved, controller.binding)

	// Agent A uses agent B, B answers by using A: the speech loop again, in hands.
	TEST_ASSERT_EQUAL(route, "capped", "Another agent's touch past the cap must not buy a decision.")

// --------------------------------------------------------- urgency and cost

/datum/unit_test/agent_npc_rough_handling_is_urgent

/datum/unit_test/agent_npc_rough_handling_is_urgent/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/pair = agent_test_pawn_and_person()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = pair[1]
	var/mob/living/carbon/human/person = pair[2]
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/agent_binding/binding = controller?.binding
	TEST_ASSERT_NOTNULL(binding, "Setup failed: the pawn must be bound.")

	binding.pending = agent_test_request_for(binding)
	binding.state = AGENT_BINDING_PENDING
	controller.note_stimulus(AGENT_STIMULUS_GRABBED, person)
	var/abandoned_for_grab = isnull(binding.pending)

	binding.pending = agent_test_request_for(binding)
	binding.state = AGENT_BINDING_PENDING
	controller.note_stimulus(AGENT_STIMULUS_TOUCHED, person)
	var/kept_for_touch = !isnull(binding.pending)
	binding.abandon_pending("test teardown")
	agent_test_restore_subsystem(saved, binding)

	TEST_ASSERT(abandoned_for_grab, "Being grabbed cannot wait for a reply to something older.")
	TEST_ASSERT(kept_for_touch, "A touch can wait for the reply in flight.")

/datum/unit_test/agent_npc_urgent_events_abandon_once_per_request

/datum/unit_test/agent_npc_urgent_events_abandon_once_per_request/Run()
	var/datum/agent_binding/binding = agent_test_binding("abandon-once")
	var/datum/agent_request/request = agent_test_request_for(binding)
	request.sent_events = list(list("event" = "attacked", "urgency" = AGENT_EVENT_HIGH, "detail" = list("by" = "Bob")))
	binding.pending = request
	binding.state = AGENT_BINDING_PENDING

	binding.mark_dirty("attacked", AGENT_EVENT_HIGH, list("by" = "Bob"))

	// Every blow used to abandon the request and pay for another. The reply to the first is worth waiting for.
	TEST_ASSERT_NOTNULL(binding.pending, "A request already carrying an emergency must not be abandoned for another.")
	TEST_ASSERT(binding.dirty, "The later blow must still wait for the next request.")
	binding.abandon_pending("test teardown")
	qdel(binding)

/datum/unit_test/agent_npc_repeated_attacks_are_counted

/datum/unit_test/agent_npc_repeated_attacks_are_counted/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/pair = agent_test_pawn_and_person()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = pair[1]
	var/mob/living/carbon/human/person = pair[2]
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	controller.binding.take_events()

	for(var/i in 1 to 4)
		controller.on_pawn_attacked(pawn, person, 10)
	var/list/attacks = agent_test_events_named(controller.binding.take_events(), "attacked")
	controller.clear_threat()
	agent_test_restore_subsystem(saved, controller.binding)

	TEST_ASSERT_EQUAL(length(attacks), 1, "A flurry of blows must be one event, or it pushes out everything else.")
	var/list/entry = attacks[1]
	var/list/detail = entry["detail"]
	TEST_ASSERT_EQUAL(detail["count"], 4, "The count must say how many blows.")
