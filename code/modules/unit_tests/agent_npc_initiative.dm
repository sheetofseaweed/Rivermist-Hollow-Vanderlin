// Initiative: the model makes advances, DM picks the act, and the partner is always asked first.

/// Stands in for an open scene window: its handler only reads who is at it and whether it is live.
/datum/agent_test_window
	var/status = UI_INTERACTIVE
	var/mob/user

/// A bound barmaid who has said yes to a man beside her, both with the parts the acts need.
/datum/unit_test/proc/agent_test_couple()
	var/mob/living/carbon/human/species/human/northern/agent_social/barmaid = agent_test_romantic_pawn()
	barmaid.gender = FEMALE
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human/species/human/northern)
	partner.gender = MALE
	partner.give_genitals()
	var/datum/ai_controller/agent_social/agent = barmaid.ai_controller
	agent.grant_consent(partner)
	return list(barmaid, partner)

/// The act the NPC is leading on someone, if any.
/proc/agent_test_led_act(mob/living/leader)
	RETURN_TYPE(/datum/sex_action)
	for(var/datum/sex_action/act as anything in leader.sex_scene?.get_actions_involving(leader))
		if(act.action_user == leader)
			return act
	return null

/datum/unit_test/agent_initiative_needs_a_yes_and_a_moment

/datum/unit_test/agent_initiative_needs_a_yes_and_a_moment/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/barmaid = agent_test_romantic_pawn()
	var/datum/ai_controller/agent_social/agent = barmaid.ai_controller
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human/species/human/northern)
	partner.give_genitals()

	var/list/unchosen = agent.make_advance(partner, "tender")
	agent.grant_consent(partner)
	var/list/bad_level = agent.make_advance(partner, "wild")
	var/list/rough_first = agent.make_advance(partner, "rough")
	var/list/unaskable = agent.make_advance(partner, "tender")
	partner.forceMove(run_loc_floor_top_right)
	var/list/too_far = agent.make_advance(partner, "tender")
	agent_test_restore_subsystem(saved, agent.binding)

	TEST_ASSERT(findtext(unchosen["detail"], "have not agreed"), "Only someone the NPC said yes to: [unchosen["detail"]]")
	TEST_ASSERT(findtext(bad_level["detail"], "tender, intimate or rough"), "Only the three levels: [bad_level["detail"]]")
	TEST_ASSERT(findtext(rough_first["detail"], "after they have welcomed something intimate"), "Rough waits for an intimate yes: [rough_first["detail"]]")
	TEST_ASSERT(findtext(unaskable["detail"], "cannot be asked"), "Nobody is touched without being asked, and a body without a player cannot be: [unaskable["detail"]]")
	TEST_ASSERT(findtext(too_far["detail"], "approach them first"), "An advance needs the partner within reach: [too_far["detail"]]")

/datum/unit_test/agent_initiative_a_yes_starts_the_act

/datum/unit_test/agent_initiative_a_yes_starts_the_act/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/couple = agent_test_couple()
	var/mob/living/carbon/human/species/human/northern/agent_social/barmaid = couple[1]
	var/mob/living/carbon/human/partner = couple[2]
	var/datum/ai_controller/agent_social/agent = barmaid.ai_controller
	var/act_type = agent.pick_advance_act(partner, AGENT_ADVANCE_TENDER)
	TEST_ASSERT(act_type in GLOB.agent_advance_tender_acts, "Setup failed: a tender act must fit them: [act_type]")
	agent.binding.take_events()

	agent.resolve_advance(partner, act_type, AGENT_ADVANCE_TENDER, AGENT_ADVANCE_YES)
	var/datum/sex_action/led = agent_test_led_act(barmaid)
	var/running = led && DOING_INTERACTION(barmaid, "sex_action_[REF(led)]")
	var/list/answers = agent_test_events_named(agent.binding.take_events(), AGENT_EVENT_ADVANCE)
	var/list/answer = length(answers) ? answers[1]["detail"] : list()
	var/led_type = led?.type
	// Stopped first, so the next pick is not narrowed by what the running act holds.
	if(led)
		led.stop_runtime()
	var/next_type = agent.pick_advance_act(partner, AGENT_ADVANCE_TENDER)
	agent_test_restore_subsystem(saved, agent.binding)

	TEST_ASSERT(running, "A yes must start the act, with the NPC leading it.")
	TEST_ASSERT_EQUAL(led_type, act_type, "The act the partner said yes to, not another.")
	TEST_ASSERT_EQUAL(answer["answer"], "yes", "The model must hear the yes.")
	TEST_ASSERT_EQUAL(answer["level"], "tender", "And at what level.")
	TEST_ASSERT(next_type != act_type, "The next advance picks something else when it can.")

/datum/unit_test/agent_initiative_answers_hold_it_back

/datum/unit_test/agent_initiative_answers_hold_it_back/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/couple = agent_test_couple()
	var/mob/living/carbon/human/species/human/northern/agent_social/barmaid = couple[1]
	var/mob/living/carbon/human/partner = couple[2]
	var/datum/ai_controller/agent_social/agent = barmaid.ai_controller
	var/datum/agent_advance_record/record = agent.advance_record(partner)
	agent.binding.take_events()

	agent.resolve_advance(partner, /datum/sex_action/kissing, AGENT_ADVANCE_TENDER, AGENT_ADVANCE_NO)
	var/list/after_no = agent.make_advance(partner, "tender")
	record.next_allowed = 0
	agent.resolve_advance(partner, /datum/sex_action/kissing, AGENT_ADVANCE_TENDER, null)
	var/list/after_silence = agent.make_advance(partner, "tender")
	record.next_allowed = 0
	agent.resolve_advance(partner, /datum/sex_action/kissing, AGENT_ADVANCE_TENDER, AGENT_ADVANCE_STOP_ASKING)
	var/list/after_stop = agent.make_advance(partner, "tender")
	var/list/scene_line = agent.describe_advances()
	var/list/heard = list()
	for(var/list/entry as anything in agent_test_events_named(agent.binding.take_events(), AGENT_EVENT_ADVANCE))
		heard += entry["detail"]["answer"]
	var/started_anything = !isnull(agent_test_led_act(barmaid))
	agent_test_restore_subsystem(saved, agent.binding)

	TEST_ASSERT(findtext(after_no["detail"], "wait a little"), "A no holds the NPC back: [after_no["detail"]]")
	TEST_ASSERT(findtext(after_silence["detail"], "wait a little"), "So does no answer: [after_silence["detail"]]")
	TEST_ASSERT(findtext(after_stop["detail"], "not to try anything"), "Stop asking holds it back longer: [after_stop["detail"]]")
	TEST_ASSERT(length(scene_line) && scene_line[1]["not_now_minutes"], "And the model's scene says so.")
	TEST_ASSERT_EQUAL(jointext(heard, ","), "no,no_answer,stop_asking", "Each answer must reach the model as it was given.")
	TEST_ASSERT(!started_anything, "None of them may start anything.")

/datum/unit_test/agent_initiative_a_standing_yes_skips_the_question

/datum/unit_test/agent_initiative_a_standing_yes_skips_the_question/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/couple = agent_test_couple()
	var/mob/living/carbon/human/species/human/northern/agent_social/barmaid = couple[1]
	var/mob/living/carbon/human/partner = couple[2]
	var/datum/ai_controller/agent_social/agent = barmaid.ai_controller
	var/intimate_type = agent.pick_advance_act(partner, AGENT_ADVANCE_INTIMATE)
	TEST_ASSERT_NOTNULL(intimate_type, "Setup failed: an intimate act must fit them.")

	agent.resolve_advance(partner, intimate_type, AGENT_ADVANCE_INTIMATE, AGENT_ADVANCE_YES_FOR_A_WHILE)
	var/list/tender_again = agent.make_advance(partner, "tender")
	var/datum/sex_action/tender_act = agent_test_led_act(barmaid)
	var/tender_led = tender_act && (tender_act.type in GLOB.agent_advance_tender_acts)
	var/list/rough_now = agent.make_advance(partner, "rough")
	var/list/scene_line = agent.describe_advances()
	if(tender_act)
		tender_act.stop_runtime()
	agent_test_restore_subsystem(saved, agent.binding)

	TEST_ASSERT(findtext(tender_again["detail"], "already said yes for a while"), "A standing yes covers gentler advances without asking: [tender_again["detail"]]")
	TEST_ASSERT(tender_led, "And the act starts at once, replacing the last.")
	TEST_ASSERT(findtext(rough_now["detail"], "cannot be asked"), "Rough is beyond an intimate standing yes, so it must be asked: [rough_now["detail"]]")
	TEST_ASSERT(length(scene_line) && scene_line[1]["lead"] == "intimate", "The model's scene says how far it may lead.")

/datum/unit_test/agent_initiative_the_partner_can_always_stop_it

/datum/unit_test/agent_initiative_the_partner_can_always_stop_it/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/couple = agent_test_couple()
	var/mob/living/carbon/human/species/human/northern/agent_social/barmaid = couple[1]
	var/mob/living/carbon/human/partner = couple[2]
	var/mob/living/carbon/human/onlooker = allocate(/mob/living/carbon/human/species/human/northern)
	var/datum/ai_controller/agent_social/agent = barmaid.ai_controller
	agent.resolve_advance(partner, /datum/sex_action/kissing, AGENT_ADVANCE_TENDER, AGENT_ADVANCE_YES)
	var/datum/sex_action/led = agent_test_led_act(barmaid)
	TEST_ASSERT_NOTNULL(led, "Setup failed: the NPC must be leading an act.")
	agent.binding.take_events()

	var/partner_may = agent_act_stoppable_by(led, partner)
	var/onlooker_may = agent_act_stoppable_by(led, onlooker)
	var/datum/sex_scene_controller/window_side = partner.open_sex_scene(barmaid, FALSE)
	var/shown_stoppable = FALSE
	for(var/list/connection as anything in window_side.get_scene_connections_ui_data())
		if(connection["ref"] == REF(led))
			shown_stoppable = connection["can_stop"]
	var/datum/agent_test_window/window = new()
	window.user = partner
	window_side.ui_act("stop_scene_action", list("ref" = REF(led)), window)
	var/stopped = QDELETED(led) || !(led in barmaid.sex_scene?.active_actions)
	var/list/heard = agent_test_events_named(agent.binding.take_events(), AGENT_EVENT_ADVANCE)
	var/list/told = length(heard) ? heard[1]["detail"] : list()
	var/list/after_stop = agent.make_advance(partner, "tender")
	qdel(window)
	agent_test_restore_subsystem(saved, agent.binding)

	TEST_ASSERT(partner_may && !onlooker_may, "What an agent NPC does to someone, that person may stop, and only they.")
	TEST_ASSERT(shown_stoppable, "Their scene window must offer the stop button.")
	TEST_ASSERT(stopped, "And pressing it must stop the act.")
	TEST_ASSERT_EQUAL(told["answer"], "stopped", "The model must hear it was stopped.")
	TEST_ASSERT(findtext(after_stop["detail"], "wait a little"), "Stopping counts as a no: [after_stop["detail"]]")

/datum/unit_test/agent_initiative_acts_end_at_the_cap

/datum/unit_test/agent_initiative_acts_end_at_the_cap/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/couple = agent_test_couple()
	var/mob/living/carbon/human/species/human/northern/agent_social/barmaid = couple[1]
	var/mob/living/carbon/human/partner = couple[2]
	var/datum/ai_controller/agent_social/agent = barmaid.ai_controller
	agent.resolve_advance(partner, /datum/sex_action/rub_body, AGENT_ADVANCE_TENDER, AGENT_ADVANCE_YES)
	var/datum/sex_action/led = agent_test_led_act(barmaid)
	TEST_ASSERT_NOTNULL(led, "Setup failed: the NPC must be leading an act.")

	agent.end_advance_act(WEAKREF(led))
	var/stopped = QDELETED(led) || !(led in barmaid.sex_scene?.active_actions)
	agent_test_restore_subsystem(saved, agent.binding)

	TEST_ASSERT(stopped, "An act the NPC leads must stop at its time cap.")

/datum/unit_test/agent_initiative_is_granted_not_listed

/datum/unit_test/agent_initiative_is_granted_not_listed/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/barmaid = agent_test_romantic_pawn()
	var/mob/living/carbon/human/species/human/northern/agent_social/villager = agent_test_bound_pawn()
	var/mob/living/carbon/human/species/human/northern/agent_social/performer = agent_test_shopkeeper(/datum/agent_stock/service)
	var/datum/ai_controller/agent_social/barmaid_agent = barmaid.ai_controller
	var/datum/ai_controller/agent_social/villager_agent = villager.ai_controller
	var/datum/ai_controller/agent_social/performer_agent = performer.ai_controller

	var/barmaid_may = barmaid_agent.binding.profile_permits("initiate")
	var/villager_may = villager_agent.binding.profile_permits("initiate")
	var/performer_may = performer_agent.binding.profile_permits("initiate")
	var/performer_told = ("initiate" in performer_agent.binding.profile_payload()["permitted_actions"])
	var/stripped = !("initiate" in agent_clean_profile_actions(list("say", "initiate", "wait")))
	agent_test_restore_subsystem(saved, barmaid_agent.binding)
	agent_test_restore_subsystem(saved, villager_agent.binding)
	agent_test_restore_subsystem(saved, performer_agent.binding)

	TEST_ASSERT(barmaid_may, "Romance on grants advances.")
	TEST_ASSERT(!villager_may, "Without romance or a service there are none.")
	TEST_ASSERT(performer_may && performer_told, "Selling company grants them, whatever the profile says.")
	TEST_ASSERT(stripped, "And no saved action list can grant them.")

/datum/unit_test/agent_initiative_offers_read_to_the_partner

/datum/unit_test/agent_initiative_offers_read_to_the_partner/Run()
	TEST_ASSERT_EQUAL(agent_advance_phrase(/datum/sex_action/sex/other/vagina), "ride you", "Ride them, offered, is ride you.")
	TEST_ASSERT_EQUAL(agent_advance_phrase(/datum/sex_action/kissing), "make out with you", "Them becomes you.")
	TEST_ASSERT_EQUAL(agent_advance_phrase(/datum/sex_action/rub_body), "rub your body", "And their becomes your.")
