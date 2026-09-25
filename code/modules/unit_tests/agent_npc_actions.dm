// Sitting, custom emotes, handing things over, and sneakers staying hidden. Added 2026-09-24.

/// The first handle in the pawn's current observation that resolves to this atom, or null.
/proc/agent_test_handle_of(datum/agent_binding/binding, mob/living/pawn, atom/wanted)
	var/list/built = agent_build_observation(pawn, binding.observation_revision)
	binding.set_observation(built["observation"])
	for(var/handle in binding.last_observation.handles)
		if(binding.last_observation.resolve(handle) == wanted)
			return handle
	return null

/// A valid decision for dispatch_decision, as consume_pass would hand it over.
/proc/agent_test_decision(list/action)
	var/datum/agent_response/response = new()
	response.ok = TRUE
	response.action = action
	return response

// ------------------------------------------------------------------ sitting

/datum/unit_test/agent_npc_sit_and_stand

/datum/unit_test/agent_npc_sit_and_stand/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/obj/structure/chair/stool/bar/stool = allocate(/obj/structure/chair/stool/bar)
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")

	var/list/sat = agent_execute_sit(controller, pawn, stool)
	var/seated_on = pawn.buckled
	var/remembered = controller.blackboard[BB_AGENT_SEAT]
	var/list/stood = agent_execute_stand(pawn)
	var/still_on = pawn.buckled
	var/still_remembered = controller.blackboard[BB_AGENT_SEAT]
	agent_test_restore_subsystem(saved, controller.binding)

	TEST_ASSERT_EQUAL(sat["state"], AGENT_RESULT_SUCCEEDED, "Sitting on a free stool beside the NPC must succeed.")
	TEST_ASSERT_EQUAL(seated_on, stool, "The NPC must actually be on the stool.")
	TEST_ASSERT_EQUAL(remembered, stool, "The seat must be remembered as chosen, or the resist reflex pulls the NPC off it.")
	TEST_ASSERT_EQUAL(stood["state"], AGENT_RESULT_SUCCEEDED, "Standing must succeed.")
	TEST_ASSERT_NULL(still_on, "Standing must leave the seat.")
	TEST_ASSERT_NULL(still_remembered, "Leaving the seat must forget it.")

/datum/unit_test/agent_npc_resist_leaves_a_chosen_seat

/datum/unit_test/agent_npc_resist_leaves_a_chosen_seat/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/obj/structure/chair/stool/bar/stool = allocate(/obj/structure/chair/stool/bar)
	var/datum/ai_planning_subtree/generic_resist/agent/subtree = new()
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")

	agent_execute_sit(controller, pawn, stool)
	// A long tick makes the reflex's 75% roll a certainty, so only the seat rule can stop it.
	var/chosen = subtree.SelectBehaviors(controller, 20)
	controller.clear_blackboard_key(BB_AGENT_SEAT)
	var/imposed = subtree.SelectBehaviors(controller, 20)
	controller.CancelActions()
	if(pawn.buckled)
		stool.unbuckle_mob(pawn, force = TRUE)
	qdel(subtree)
	agent_test_restore_subsystem(saved, controller.binding)

	// SHOULD_RESIST counts any buckle. Without the exception the NPC would stand up as soon as it sat.
	TEST_ASSERT_NULL(chosen, "A seat the NPC chose must not be resisted.")
	TEST_ASSERT_EQUAL(imposed, SUBTREE_RETURN_FINISH_PLANNING, "Being put in a seat by someone else must still be resisted.")

/datum/unit_test/agent_npc_only_seats_are_sat_on

/datum/unit_test/agent_npc_only_seats_are_sat_on/Run()
	var/obj/structure/chair/stool/bar/stool = allocate(/obj/structure/chair/stool/bar)
	var/obj/structure/meathook/hook = allocate(/obj/structure/meathook)
	var/obj/structure/door/door = allocate(/obj/structure/door)
	TEST_ASSERT(agent_is_seat(stool), "A stool is a seat.")
	TEST_ASSERT(hook.can_buckle, "Setup failed: the hook must be something that buckles.")
	// Hooks, stocks and operating tables buckle too. Hanging yourself on a meathook is not sitting.
	TEST_ASSERT(!agent_is_seat(hook), "A meathook is not a seat, even though it buckles.")
	TEST_ASSERT(!agent_is_seat(door), "A door is not a seat.")

/datum/unit_test/agent_npc_seated_npc_gets_up

/datum/unit_test/agent_npc_seated_npc_gets_up/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/agent_binding/binding = controller?.binding
	var/obj/structure/chair/stool/bar/stool = allocate(/obj/structure/chair/stool/bar)
	var/obj/item/natural/cloth/cloth = allocate(/obj/item/natural/cloth)
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human/species/human/northern)
	TEST_ASSERT_NOTNULL(binding, "Setup failed: the pawn must be bound.")

	agent_execute_sit(controller, pawn, stool)
	var/cloth_handle = agent_test_handle_of(binding, pawn, cloth)
	SSagent_npc.dispatch_decision(binding, agent_test_decision(list("name" = "approach", "handle" = cloth_handle)))
	var/up_to_walk = isnull(pawn.buckled)

	agent_execute_sit(controller, pawn, stool)
	controller.on_pawn_attacked(pawn, attacker, 10)
	var/up_to_flee = isnull(pawn.buckled)
	controller.clear_threat()
	controller.cancel_agent_objective()
	agent_test_restore_subsystem(saved, binding)

	TEST_ASSERT(up_to_walk, "Walking anywhere must get the NPC up first.")
	// The chosen seat is not resisted, so nothing else would stand the NPC up to run.
	TEST_ASSERT(up_to_flee, "Being attacked must get a seated NPC up to flee.")

// ---------------------------------------------------------- custom emotes

/datum/unit_test/agent_npc_me_acts_in_its_own_words

/datum/unit_test/agent_npc_me_acts_in_its_own_words/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/pair = agent_test_agent_pair()
	var/mob/living/carbon/human/species/human/northern/agent_social/listener = pair[1]
	var/mob/living/carbon/human/species/human/northern/agent_social/actor = pair[2]
	var/datum/ai_controller/agent_social/controller = listener.ai_controller
	var/datum/ai_controller/agent_social/actor_controller = actor.ai_controller
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the listener must be bound.")
	controller.binding.take_events()
	var/list/actor_name = agent_name_tokens(actor.get_visible_name())
	TEST_ASSERT(length(actor_name), "Setup failed: the actor needs a usable name.")

	var/list/outcome = agent_execute_me(actor, "[actor_name[1]] wipes down the counter.")
	var/list/seen = agent_test_events_named(controller.binding.take_events(), "saw_emote")
	SSagent_npc.unregister_pawn(actor_controller.binding, "test teardown")
	agent_test_restore_subsystem(saved, controller.binding)

	TEST_ASSERT_EQUAL(outcome["state"], AGENT_RESULT_SUCCEEDED, "A small action in the NPC's own words must go through.")
	TEST_ASSERT_EQUAL(length(seen), 1, "Others must see the NPC's emote like anyone else's.")
	var/list/entry = seen[1]
	var/list/detail = entry["detail"]
	// The game already starts an emote with the name, so a model that writes it too would double it.
	TEST_ASSERT_EQUAL(detail["text"], "wipes down the counter.", "The NPC's own name must be stripped from the front.")

/datum/unit_test/agent_npc_me_refuses_speech_and_blanks

/datum/unit_test/agent_npc_me_refuses_speech_and_blanks/Run()
	var/mob/living/carbon/human/pawn = allocate(/mob/living/carbon/human/species/human/northern)
	var/list/speech = agent_execute_me(pawn, "says, \"hello there\"")
	var/list/blank = agent_execute_me(pawn, "<b></b>")
	// Words go through say, which applies language and the speech filters. An emote that talks skips both.
	TEST_ASSERT_EQUAL(speech["state"], AGENT_RESULT_REJECTED, "Speech dressed as an emote must be refused.")
	TEST_ASSERT_EQUAL(blank["state"], AGENT_RESULT_REJECTED, "An emote that is only markup is nothing.")

// ---------------------------------------------------------- handing over

/datum/unit_test/agent_npc_offer_is_noticed_and_taken

/datum/unit_test/agent_npc_offer_is_noticed_and_taken/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/pair = agent_test_pawn_and_person()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = pair[1]
	var/mob/living/carbon/human/person = pair[2]
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/obj/item/natural/cloth/cloth = allocate(/obj/item/natural/cloth)
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	TEST_ASSERT(person.put_in_active_hand(cloth), "Setup failed: the cloth must be held.")
	controller.binding.take_events()

	var/list/refused = agent_execute_take(pawn, person)
	TEST_ASSERT(person.offer_item(pawn, cloth), "Setup failed: the offer must be made.")
	var/list/events = agent_test_events_named(controller.binding.take_events(), "physical")
	var/list/taken = agent_execute_take(pawn, person)
	var/holder = cloth.loc
	agent_test_restore_subsystem(saved, controller.binding)

	TEST_ASSERT_EQUAL(refused["state"], AGENT_RESULT_REJECTED, "Nothing offered, nothing to take.")
	// The game tells the receiver by to_chat alone, which a clientless NPC never reads.
	TEST_ASSERT_EQUAL(length(events), 1, "An offer to the NPC must reach it.")
	var/list/entry = events[1]
	var/list/detail = entry["detail"]
	TEST_ASSERT_EQUAL(detail["what"], AGENT_STIMULUS_OFFERED, "It must say it is an offer.")
	TEST_ASSERT_EQUAL(taken["state"], AGENT_RESULT_SUCCEEDED, "Taking an offer made to the NPC must succeed.")
	TEST_ASSERT_EQUAL(holder, pawn, "The item must end up in the NPC's hands.")

/datum/unit_test/agent_npc_cannot_take_what_was_offered_to_another

/datum/unit_test/agent_npc_cannot_take_what_was_offered_to_another/Run()
	var/mob/living/carbon/human/pawn = allocate(/mob/living/carbon/human/species/human/northern)
	var/mob/living/carbon/human/person = allocate(/mob/living/carbon/human/species/human/northern)
	var/mob/living/carbon/human/friend = allocate(/mob/living/carbon/human/species/human/northern)
	var/obj/item/natural/cloth/cloth = allocate(/obj/item/natural/cloth)
	TEST_ASSERT(person.put_in_active_hand(cloth), "Setup failed: the cloth must be held.")
	TEST_ASSERT(person.offer_item(friend, cloth), "Setup failed: the offer must be made.")

	var/list/snatched = agent_execute_take(pawn, person)
	TEST_ASSERT_EQUAL(snatched["state"], AGENT_RESULT_REJECTED, "An offer to someone else must not be takeable.")
	TEST_ASSERT_EQUAL(cloth.loc, person, "The item must stay with the offerer.")

/datum/unit_test/agent_npc_give_holds_out_and_hears_back

/datum/unit_test/agent_npc_give_holds_out_and_hears_back/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/pair = agent_test_pawn_and_person()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = pair[1]
	var/mob/living/carbon/human/person = pair[2]
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/obj/item/natural/cloth/cloth = allocate(/obj/item/natural/cloth)
	var/obj/item/natural/feather/feather = allocate(/obj/item/natural/feather)
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	TEST_ASSERT(pawn.put_in_active_hand(feather), "Setup failed: the feather must be held.")
	TEST_ASSERT(pawn.put_in_inactive_hand(cloth), "Setup failed: the cloth must be held.")
	controller.binding.take_events()

	// The cloth is in the other hand: giving it must switch hands rather than hand over the feather.
	var/list/outcome = agent_execute_give(pawn, person, cloth)
	var/offering = pawn.offered_item_ref?.resolve()
	controller.watch_offer(cloth)
	var/accepted = person.try_accept_offered_item(pawn, cloth, FALSE)
	var/list/events = agent_test_events_named(controller.binding.take_events(), "offer_taken")
	var/holder = cloth.loc
	agent_test_restore_subsystem(saved, controller.binding)

	TEST_ASSERT_EQUAL(outcome["state"], AGENT_RESULT_SUCCEEDED, "Holding an item out to someone beside the NPC must succeed.")
	TEST_ASSERT_EQUAL(offering, cloth, "The item chosen must be the one held out.")
	TEST_ASSERT(accepted, "Setup failed: the person must take it.")
	TEST_ASSERT_EQUAL(holder, person, "The item must change hands.")
	TEST_ASSERT_EQUAL(length(events), 1, "The NPC must learn its offer was taken.")

/datum/unit_test/agent_npc_give_checks_the_item_before_walking

/datum/unit_test/agent_npc_give_checks_the_item_before_walking/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/pair = agent_test_pawn_and_person()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = pair[1]
	var/mob/living/carbon/human/person = pair[2]
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/agent_binding/binding = controller?.binding
	var/obj/item/natural/cloth/cloth = allocate(/obj/item/natural/cloth)
	var/obj/item/natural/feather/loose = allocate(/obj/item/natural/feather)
	TEST_ASSERT_NOTNULL(binding, "Setup failed: the pawn must be bound.")
	TEST_ASSERT(pawn.put_in_active_hand(cloth), "Setup failed: the cloth must be held.")

	var/person_handle = agent_test_handle_of(binding, pawn, person)
	var/cloth_handle = null
	var/loose_handle = null
	for(var/handle in binding.last_observation.handles)
		var/atom/resolved = binding.last_observation.resolve(handle)
		if(resolved == cloth)
			cloth_handle = handle
		if(resolved == loose)
			loose_handle = handle
	TEST_ASSERT_NOTNULL(cloth_handle, "Setup failed: the held cloth must have a handle.")

	SSagent_npc.dispatch_decision(binding, agent_test_decision(list("name" = "give", "handle" = person_handle, "key" = loose_handle)))
	var/intent_for_loose = binding.current_intent
	SSagent_npc.dispatch_decision(binding, agent_test_decision(list("name" = "approach", "handle" = cloth_handle)))
	var/intent_for_own_hand = binding.current_intent
	SSagent_npc.dispatch_decision(binding, agent_test_decision(list("name" = "give", "handle" = person_handle, "key" = cloth_handle)))
	var/list/intent_ok = binding.current_intent
	var/queued_item = controller.blackboard[BB_AGENT_GIVE_ITEM]
	controller.cancel_agent_objective()
	agent_test_restore_subsystem(saved, binding)

	TEST_ASSERT_NULL(intent_for_loose, "Giving something the NPC is not holding must be refused before walking.")
	TEST_ASSERT_NULL(intent_for_own_hand, "A held item is not somewhere to walk to.")
	TEST_ASSERT_NOTNULL(intent_ok, "Giving a held item to a person in view must become an objective.")
	// Resolved at dispatch: a new observation mid-walk would give the handle a different meaning.
	TEST_ASSERT_EQUAL(queued_item, cloth, "The item must be fixed at dispatch, not looked up on arrival.")

// ---------------------------------------------------------------- sneakers

/datum/unit_test/agent_npc_unspotted_sneaker_is_not_seen

/datum/unit_test/agent_npc_unspotted_sneaker_is_not_seen/Run()
	var/mob/living/carbon/human/pawn = allocate(/mob/living/carbon/human/species/human/northern)
	var/mob/living/carbon/human/sneaker = allocate(/mob/living/carbon/human/species/human/northern)
	// The spotting roll is on a cooldown, so this NPC cannot spot anyone right now. No randomness.
	COOLDOWN_START(pawn, npc_sneak_detect_cd, 1 MINUTES)

	sneaker.rogue_sneaking = TRUE
	sneaker.alpha = 0
	var/list/hidden = agent_build_observation(pawn, 1)
	var/datum/agent_observation/hidden_observation = hidden["observation"]
	var/list/hidden_payload = hidden["payload"]
	var/seen_hidden = agent_test_find_offered(hidden_observation, hidden_payload["entities"], sneaker)
	qdel(hidden_observation)

	sneaker.rogue_sneaking = FALSE
	sneaker.alpha = 255
	var/list/open = agent_build_observation(pawn, 2)
	var/datum/agent_observation/open_observation = open["observation"]
	var/list/open_payload = open["payload"]
	var/seen_open = agent_test_find_offered(open_observation, open_payload["entities"], sneaker)
	qdel(open_observation)

	// An NPC announcing a sneaker it never spotted breaks stealth play for everyone else.
	TEST_ASSERT_NULL(seen_hidden, "An unspotted sneaker must not be in the scene.")
	TEST_ASSERT_NOTNULL(seen_open, "The same person out of the shadows must be seen.")

/datum/unit_test/agent_npc_hidden_people_are_marked_unseen

/datum/unit_test/agent_npc_hidden_people_are_marked_unseen/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/pair = agent_test_pawn_and_person()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = pair[1]
	var/mob/living/carbon/human/sneaker = pair[2]
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	controller.binding.take_events()

	sneaker.rogue_sneaking = TRUE
	sneaker.alpha = 0
	controller.on_emote_perceived(sneaker, "waves.", TRUE, FALSE)
	controller.note_stimulus(AGENT_STIMULUS_TOUCHED, sneaker)
	controller.on_pawn_heard(pawn, list("composed", sneaker, null, "over here"))
	var/list/events = controller.binding.take_events()
	sneaker.rogue_sneaking = FALSE
	sneaker.alpha = 255
	agent_test_restore_subsystem(saved, controller.binding)

	TEST_ASSERT(length(events) >= 3, "Setup failed: the emote, the touch and the speech must all arrive.")
	// Heard and felt as players hear and feel them, but the model must not act as if it sees them.
	for(var/list/entry as anything in events)
		var/list/detail = entry["detail"]
		TEST_ASSERT(detail["unseen"], "[entry["event"]] from a hidden person must be marked unseen.")

/datum/unit_test/agent_npc_sneaking_emote_blurs_at_distance

/datum/unit_test/agent_npc_sneaking_emote_blurs_at_distance/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/mob/living/carbon/human/sneaker = allocate(/mob/living/carbon/human/species/human/northern, run_loc_floor_top_right)
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	TEST_ASSERT(get_dist(pawn, sneaker) > SNEAKY_EMOTE_VISIBLE_RANGE, "Setup failed: the sneaker must be beyond arm's length.")
	controller.binding.take_events()

	sneaker.m_intent = MOVE_INTENT_SNEAK
	controller.on_emote_perceived(sneaker, "signals quietly to the others waiting behind the wall", TRUE, FALSE)
	var/list/events = controller.binding.take_events()
	sneaker.m_intent = MOVE_INTENT_WALK
	agent_test_restore_subsystem(saved, controller.binding)

	TEST_ASSERT(length(events) >= 1, "Setup failed: the emote must arrive.")
	var/list/entry = events[1]
	var/list/detail = entry["detail"]
	// Players past arm's length get a starred copy. The NPC must not read more than they do.
	TEST_ASSERT(detail["text"] != "signals quietly to the others waiting behind the wall", "A sneaking emote past arm's length must arrive blurred.")

// ------------------------------------------------------------------ naming targets

/datum/unit_test/agent_npc_a_shown_name_stands_for_its_handle

/datum/unit_test/agent_npc_a_shown_name_stands_for_its_handle/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/agent_binding/binding = controller?.binding
	var/mob/living/carbon/human/lexus = allocate(/mob/living/carbon/human/species/human/northern)
	var/mob/living/carbon/human/namesake = allocate(/mob/living/carbon/human/species/human/northern)
	TEST_ASSERT_NOTNULL(binding, "Setup failed: the pawn must be bound.")
	lexus.real_name = "Lexus"
	lexus.name = "Lexus"
	TEST_ASSERT_EQUAL(lexus.get_visible_name(), "Lexus", "Setup failed: the face must show the name.")

	var/handle = agent_test_handle_of(binding, pawn, lexus)
	var/by_name = binding.resolve_handle("lexus ")
	var/as_shown = binding.resolve_handle("\[[handle]\] Lexus")
	var/nobody = binding.resolve_handle("Tarik")
	SSagent_npc.dispatch_decision(binding, agent_test_decision(list("name" = "approach", "handle" = "Lexus")))
	var/approached = controller.blackboard[BB_AGENT_OBJECTIVE_TARGET]
	controller.cancel_agent_objective()

	namesake.real_name = "Lexus"
	namesake.name = "Lexus"
	agent_test_handle_of(binding, pawn, lexus)
	var/shared = binding.resolve_handle("Lexus")
	agent_test_restore_subsystem(saved, binding)

	// Live models wrote "Lexus" for h1 and every approach and fight was rejected.
	TEST_ASSERT_EQUAL(by_name, lexus, "A shown person's name must stand for their handle, in any case.")
	TEST_ASSERT_EQUAL(as_shown, lexus, "A handle written the way the scene shows it must still resolve.")
	TEST_ASSERT_NULL(nobody, "A name nobody in the scene has must resolve to nobody.")
	TEST_ASSERT_EQUAL(approached, lexus, "Approaching by name must walk to them.")
	TEST_ASSERT_NULL(shared, "A name two shown people share must resolve to neither.")
