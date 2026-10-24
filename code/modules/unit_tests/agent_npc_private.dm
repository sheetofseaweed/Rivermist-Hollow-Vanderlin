// Explicit scenes during an act: the cadence gate, the cut vocabulary, the scene block, the events, the voice and the hold.

/// Every explicit gate open. Returns what to put back.
/datum/unit_test/proc/agent_test_open_explicit_gates()
	var/list/saved = list(
		"config" = CONFIG_GET(flag/agent_npc_explicit_scenes),
		"switch" = SSagent_npc.explicit_enabled,
		"capabilities" = SSagent_npc.sidecar_capabilities,
	)
	agent_test_set_explicit_config(TRUE)
	SSagent_npc.explicit_enabled = TRUE
	agent_test_sidecar_says(TRUE)
	return saved

/datum/unit_test/proc/agent_test_close_explicit_gates(list/saved)
	agent_test_set_explicit_config(saved["config"])
	SSagent_npc.explicit_enabled = saved["switch"]
	SSagent_npc.sidecar_capabilities = saved["capabilities"]

/// A barmaid leading an act on the man beside her. Returns list(barmaid, partner, act).
/datum/unit_test/proc/agent_test_private_scene()
	var/list/couple = agent_test_couple()
	var/mob/living/carbon/human/species/human/northern/agent_social/barmaid = couple[1]
	var/mob/living/carbon/human/partner = couple[2]
	var/datum/sex_scene_controller/scene = barmaid.open_sex_scene(partner, FALSE)
	var/datum/sex_action/act = scene?.try_start_action(/datum/sex_action/rub_body, "unit_test")
	return list(barmaid, partner, act)

/// Hears one line and keeps how it was said.
/datum/agent_test_ear
	var/list/mods
	var/heard

/datum/agent_test_ear/proc/on_hear(datum/source, list/hearing_args)
	SIGNAL_HANDLER
	heard = hearing_args[HEARING_RAW_MESSAGE]
	mods = (length(hearing_args) >= HEARING_MESSAGE_MODS) ? hearing_args[HEARING_MESSAGE_MODS] : null

/datum/unit_test/agent_private_turns_need_explicit_and_the_cadence

/datum/unit_test/agent_private_turns_need_explicit_and_the_cadence/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/gates = agent_test_open_explicit_gates()
	var/list/scene = agent_test_private_scene()
	var/mob/living/carbon/human/species/human/northern/agent_social/barmaid = scene[1]
	var/datum/sex_action/act = scene[3]
	var/datum/ai_controller/agent_social/agent = barmaid.ai_controller
	var/datum/agent_binding/binding = agent.binding
	TEST_ASSERT_NOTNULL(act, "Setup failed: the act must start.")
	TEST_ASSERT(agent.in_private(), "Setup failed: the act must count as private.")

	binding.set_dirty()
	binding.next_private_turn_at = 0
	var/allowed = binding.can_start_request()
	binding.next_private_turn_at = world.time + 10 SECONDS
	var/too_soon = binding.can_start_request()
	binding.pending_urgency = AGENT_EVENT_HIGH
	var/urgent = binding.can_start_request()
	binding.pending_urgency = AGENT_EVENT_LOW
	binding.next_private_turn_at = 0
	agent_test_sidecar_says(FALSE)
	var/without_explicit = binding.can_start_request()

	agent_test_close_explicit_gates(gates)
	agent_test_restore_subsystem(saved, binding)
	TEST_ASSERT(allowed, "With every gate open and the cadence due, a turn during the act is allowed.")
	TEST_ASSERT(!too_soon, "Before the cadence is due, nothing ordinary buys a turn.")
	TEST_ASSERT(urgent, "Something urgent buys one at once.")
	TEST_ASSERT(!without_explicit, "Without explicit, the act gives the model no turn at all.")

/datum/unit_test/agent_private_vocabulary_is_cut

/datum/unit_test/agent_private_vocabulary_is_cut/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/gates = agent_test_open_explicit_gates()
	var/list/scene = agent_test_private_scene()
	var/mob/living/carbon/human/species/human/northern/agent_social/barmaid = scene[1]
	var/datum/sex_action/act = scene[3]
	var/datum/ai_controller/agent_social/agent = barmaid.ai_controller
	var/datum/agent_binding/binding = agent.binding
	TEST_ASSERT_NOTNULL(act, "Setup failed: the act must start.")

	var/list/allowed = binding.profile_payload()["permitted_actions"]
	var/has_private = ("say" in allowed) && ("wait" in allowed) && ("stop" in allowed) && ("consent" in allowed) && ("me" in allowed)
	var/has_nothing_else = !("approach" in allowed) && !("initiate" in allowed) && !("touch" in allowed)
	var/permits = binding.profile_permits("stop") && binding.profile_permits("say") && !binding.profile_permits("approach")
	act.scene?.stop_action(act)
	var/after = binding.profile_permits("approach") && ("approach" in binding.profile_payload()["permitted_actions"])

	agent_test_close_explicit_gates(gates)
	agent_test_restore_subsystem(saved, binding)
	TEST_ASSERT(has_private, "In private the model may say, wait, stop, take back its yes and show its own body: [allowed.Join(", ")]")
	TEST_ASSERT(has_nothing_else, "And nothing else: [allowed.Join(", ")]")
	TEST_ASSERT(permits, "Dispatch agrees, and grants stop there whatever the combat limits say.")
	TEST_ASSERT(after, "Once the act ends the whole vocabulary is back.")

/datum/unit_test/agent_private_block_describes_the_act

/datum/unit_test/agent_private_block_describes_the_act/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/gates = agent_test_open_explicit_gates()
	var/list/scene = agent_test_private_scene()
	var/mob/living/carbon/human/species/human/northern/agent_social/barmaid = scene[1]
	var/mob/living/carbon/human/partner = scene[2]
	var/datum/sex_action/act = scene[3]
	var/datum/ai_controller/agent_social/agent = barmaid.ai_controller
	TEST_ASSERT_NOTNULL(act, "Setup failed: the act must start.")

	var/list/block = agent.describe_private()
	TEST_ASSERT_NOTNULL(block, "An act running gives the model a private block.")
	TEST_ASSERT_EQUAL(block["with"], partner.get_visible_name(), "It names the partner.")
	var/list/first = block["acts"][1]
	TEST_ASSERT_EQUAL(first["lead"], "you", "The NPC leads the act it started.")
	TEST_ASSERT_EQUAL(first["name"], lowertext(act.name), "By the act's own name.")
	TEST_ASSERT_EQUAL(block["you"]["arousal"], "cool", "Nothing has happened yet.")
	SEND_SIGNAL(partner, COMSIG_SEX_SET_AROUSAL, 450)
	SEND_SIGNAL(partner, COMSIG_SEX_SET_ORGASM_PROG, 100)
	block = agent.describe_private()
	TEST_ASSERT_EQUAL(block["them"]["arousal"], "burning", "The partner's arousal reads as a band.")
	TEST_ASSERT(block["them"]["close"], "And being close is said.")
	var/list/built = agent_build_observation(barmaid, 1)
	var/shown = !isnull(built["payload"]["self"]["private"])
	agent_test_sidecar_says(FALSE)
	built = agent_build_observation(barmaid, 2)
	var/hidden = isnull(built["payload"]["self"]["private"])

	agent_test_close_explicit_gates(gates)
	agent_test_restore_subsystem(saved, agent.binding)
	TEST_ASSERT(shown, "The scene the model reads carries the block while every gate is open.")
	TEST_ASSERT(hidden, "And not otherwise.")

/datum/unit_test/agent_private_acts_and_peaks_become_events

/datum/unit_test/agent_private_acts_and_peaks_become_events/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/gates = agent_test_open_explicit_gates()
	var/list/scene = agent_test_private_scene()
	var/mob/living/carbon/human/species/human/northern/agent_social/barmaid = scene[1]
	var/mob/living/carbon/human/partner = scene[2]
	var/datum/sex_action/act = scene[3]
	var/datum/ai_controller/agent_social/agent = barmaid.ai_controller
	var/datum/agent_binding/binding = agent.binding
	TEST_ASSERT_NOTNULL(act, "Setup failed: the act must start.")

	// Gates shut: the look is kept, nothing is said.
	agent_test_sidecar_says(FALSE)
	binding.take_events()
	agent.note_private_acts()
	SEND_SIGNAL(barmaid, COMSIG_SEX_CLIMAX, act, barmaid, partner, barmaid)
	var/silent = length(binding.events)
	var/unvoiced_while_shut = agent.climax_unvoiced

	// Gates open: the act counts as new again, and is told.
	agent_test_sidecar_says(TRUE)
	agent.private_acts = null
	agent.note_private_acts()
	var/list/started = agent_test_events_named(binding.events, AGENT_EVENT_PRIVATE_ACT)
	var/woke = binding.dirty && binding.pending_urgency >= AGENT_EVENT_HIGH
	binding.take_events()
	agent.note_private_acts()
	var/nothing_new = length(binding.events)
	SEND_SIGNAL(barmaid, COMSIG_SEX_CLIMAX, act, barmaid, partner, barmaid)
	var/list/own_peak = agent_test_events_named(binding.events, AGENT_EVENT_CLIMAX)
	var/unvoiced = agent.climax_unvoiced
	binding.take_events()
	SEND_SIGNAL(partner, COMSIG_SEX_CLIMAX, act, partner, barmaid, barmaid)
	var/list/their_peak = agent_test_events_named(binding.events, AGENT_EVENT_CLIMAX)
	binding.take_events()
	act.scene?.stop_action(act)
	agent.note_private_acts()
	var/list/ended = agent_test_events_named(binding.events, AGENT_EVENT_PRIVATE_ACT)

	agent_test_close_explicit_gates(gates)
	agent_test_restore_subsystem(saved, binding)
	TEST_ASSERT_EQUAL(silent, 0, "With a gate shut, no act and no peak reaches the model.")
	TEST_ASSERT(!unvoiced_while_shut, "And a peak behind a shut gate changes no voice.")
	TEST_ASSERT_EQUAL(length(started), 1, "An act running is told once.")
	TEST_ASSERT_EQUAL(started[1]["detail"]["what"], "started", "As a start.")
	TEST_ASSERT_EQUAL(started[1]["detail"]["lead"], "you", "With who leads it.")
	TEST_ASSERT(woke, "And it wakes the model at once.")
	TEST_ASSERT_EQUAL(nothing_new, 0, "A second look at the same act says nothing.")
	TEST_ASSERT_EQUAL(length(own_peak), 1, "Its own peak is told.")
	TEST_ASSERT_EQUAL(own_peak[1]["detail"]["who"], "you", "As its own.")
	TEST_ASSERT(unvoiced, "And the next line out will be shouted.")
	TEST_ASSERT_EQUAL(length(their_peak), 1, "The partner's peak is told.")
	TEST_ASSERT_EQUAL(their_peak[1]["detail"]["who"], "them", "As theirs.")
	TEST_ASSERT_EQUAL(length(ended), 1, "The act ending is told.")
	TEST_ASSERT_EQUAL(ended[1]["detail"]["what"], "ended", "As an end.")

/datum/unit_test/agent_private_partner_speech_wakes_and_bystanders_wait

/datum/unit_test/agent_private_partner_speech_wakes_and_bystanders_wait/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/gates = agent_test_open_explicit_gates()
	var/list/scene = agent_test_private_scene()
	var/mob/living/carbon/human/species/human/northern/agent_social/barmaid = scene[1]
	var/mob/living/carbon/human/partner = scene[2]
	var/datum/sex_action/act = scene[3]
	var/datum/ai_controller/agent_social/agent = barmaid.ai_controller
	var/datum/agent_binding/binding = agent.binding
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human/species/human/northern)
	TEST_ASSERT_NOTNULL(act, "Setup failed: the act must start.")

	binding.take_events()
	agent.on_pawn_heard(barmaid, list("composed", partner, null, "yes, like that"))
	var/list/heard = agent_test_events_named(binding.events, "heard_speech")
	var/urgent = binding.pending_urgency >= AGENT_EVENT_HIGH
	binding.take_events()
	agent.on_pawn_heard(barmaid, list("composed", bystander, null, "get a room, you two"))
	var/list/overheard = agent_test_events_named(binding.events, "overheard_speech")
	var/bystander_woke = binding.dirty
	binding.take_events()
	agent_test_sidecar_says(FALSE)
	agent.on_pawn_heard(barmaid, list("composed", partner, null, "still there?"))
	var/shut = length(binding.events)

	agent_test_close_explicit_gates(gates)
	agent_test_restore_subsystem(saved, binding)
	TEST_ASSERT_EQUAL(length(heard), 1, "The partner's words during the act reach the model.")
	TEST_ASSERT_EQUAL(heard[1]["detail"]["addressing"], AGENT_SPEECH_DIRECTED, "As words for it.")
	TEST_ASSERT(urgent, "And they buy a turn at once.")
	TEST_ASSERT_EQUAL(length(overheard), 1, "A bystander's line is kept.")
	TEST_ASSERT(!bystander_woke, "But waits for the next turn.")
	TEST_ASSERT_EQUAL(shut, 0, "Without explicit, nothing said during an act reaches the model.")

/datum/unit_test/agent_private_voice_follows_the_body_and_the_room

/datum/unit_test/agent_private_voice_follows_the_body_and_the_room/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/gates = agent_test_open_explicit_gates()
	var/list/scene = agent_test_private_scene()
	var/mob/living/carbon/human/species/human/northern/agent_social/barmaid = scene[1]
	var/mob/living/carbon/human/partner = scene[2]
	var/datum/sex_action/act = scene[3]
	var/datum/ai_controller/agent_social/agent = barmaid.ai_controller
	TEST_ASSERT_NOTNULL(act, "Setup failed: the act must start.")

	var/list/beside = agent_pick_voice(barmaid, TRUE)
	partner.forceMove(run_loc_floor_top_right)
	var/list/apart = agent_pick_voice(barmaid, TRUE)
	partner.forceMove(get_turf(barmaid))
	SEND_SIGNAL(barmaid, COMSIG_SEX_SET_AROUSAL, 450)
	var/list/burning = agent_pick_voice(barmaid, TRUE)
	SEND_SIGNAL(barmaid, COMSIG_SEX_SET_AROUSAL, 0)
	agent.climax_unvoiced = TRUE
	var/list/peak = agent_pick_voice(barmaid, FALSE)
	var/once = !agent.climax_unvoiced
	var/list/plain = agent_pick_voice(barmaid, FALSE)
	var/datum/agent_test_ear/ear = new()
	ear.RegisterSignal(partner, COMSIG_MOVABLE_HEAR, TYPE_PROC_REF(/datum/agent_test_ear, on_hear))
	var/list/said = agent_execute_say(barmaid, "Come closer", TRUE)
	var/whispered_mode = ear.mods?[WHISPER_MODE]
	ear.UnregisterSignal(partner, COMSIG_MOVABLE_HEAR)
	qdel(ear)

	agent_test_close_explicit_gates(gates)
	agent_test_restore_subsystem(saved, agent.binding)
	TEST_ASSERT_EQUAL(beside["voice"], "whisper", "Beside the partner, a whisper is a whisper.")
	TEST_ASSERT_EQUAL(apart["voice"], "say", "With nobody beside it, the line is spoken normally.")
	TEST_ASSERT(findtext(apart["note"], "nobody beside you"), "And the model is told why: [apart["note"]]")
	TEST_ASSERT_EQUAL(burning["voice"], "say", "Burning, it cannot keep its voice down.")
	TEST_ASSERT(findtext(burning["note"], "too far gone"), "And is told so: [burning["note"]]")
	TEST_ASSERT_EQUAL(peak["voice"], "shout", "The first line after its own peak is shouted.")
	TEST_ASSERT(once && plain["voice"] == "say", "Only that one line.")
	TEST_ASSERT_EQUAL(said["detail"], "whispered", "A whisper the body allows is reported as one: [said["detail"]]")
	TEST_ASSERT(agent_said_words(said), "And counts as words said.")
	TEST_ASSERT(whispered_mode, "The partner heard it as a whisper.")
	TEST_ASSERT_EQUAL(agent_shouted("come here"), "come here!", "A shout ends in an exclamation mark.")
	TEST_ASSERT_EQUAL(agent_shouted("now."), "now!", "Even a line that ended in a full stop.")
	TEST_ASSERT_EQUAL(agent_shouted("yes!"), "yes!", "One is enough.")

/datum/unit_test/agent_private_decisions_are_held

/datum/unit_test/agent_private_decisions_are_held/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/gates = agent_test_open_explicit_gates()
	var/list/scene = agent_test_private_scene()
	var/mob/living/carbon/human/species/human/northern/agent_social/barmaid = scene[1]
	var/datum/sex_action/act = scene[3]
	var/datum/ai_controller/agent_social/agent = barmaid.ai_controller
	var/datum/agent_binding/binding = agent.binding
	TEST_ASSERT_NOTNULL(act, "Setup failed: the act must start.")
	TEST_ASSERT(agent.in_private(), "Setup failed: the act must count as private.")
	var/before = SSagent_npc.refusal_counts[AGENT_REFUSE_PRIVATE] || 0
	var/list/line = list(list("event" = "heard_speech", "urgency" = AGENT_EVENT_LOW, "at" = world.time, "detail" = list("speaker" = "Bob", "text" = "hello")))

	// Without explicit, any decision landing during the act is held and its trigger kept.
	agent_test_sidecar_says(FALSE)
	binding.take_events()
	var/datum/agent_response/held = new()
	held.ok = TRUE
	held.action = list("name" = "say", "text" = "Well met.")
	SSagent_npc.handle_response(binding, held, line, "r1", world.time)
	var/held_count = (SSagent_npc.refusal_counts[AGENT_REFUSE_PRIVATE] || 0) - before
	var/kept = length(agent_test_events_named(binding.events, "heard_speech"))
	var/waiting = binding.dirty

	// With explicit, a decision built before the act began is held too.
	agent_test_sidecar_says(TRUE)
	binding.take_events()
	var/datum/agent_response/stale = new()
	stale.ok = TRUE
	stale.action = list("name" = "say", "text" = "Well met.")
	SSagent_npc.handle_response(binding, stale, line, "r2", agent.private_since - 10)
	var/stale_count = (SSagent_npc.refusal_counts[AGENT_REFUSE_PRIVATE] || 0) - before - held_count

	// One built during the act runs.
	binding.take_events()
	var/datum/agent_response/fresh = new()
	fresh.ok = TRUE
	fresh.action = list("name" = "say", "text" = "Well met.")
	SSagent_npc.handle_response(binding, fresh, line, "r3", world.time)
	var/ran = length(agent_test_events_named(binding.events, "action_result"))
	var/not_held = (SSagent_npc.refusal_counts[AGENT_REFUSE_PRIVATE] || 0) - before - held_count - stale_count
	qdel(held)
	qdel(stale)
	qdel(fresh)

	agent_test_close_explicit_gates(gates)
	agent_test_restore_subsystem(saved, binding)
	TEST_ASSERT_EQUAL(held_count, 1, "Without explicit, a decision landing during the act is held.")
	TEST_ASSERT_EQUAL(kept, 1, "And the line that bought it is put back.")
	TEST_ASSERT(waiting, "To be sent after the act.")
	TEST_ASSERT_EQUAL(stale_count, 1, "With explicit, a decision built before the act is held too.")
	TEST_ASSERT_EQUAL(not_held, 0, "One built during the act is not.")
	TEST_ASSERT_EQUAL(ran, 1, "It runs.")

/datum/unit_test/agent_private_stop_ends_only_what_the_npc_leads

/datum/unit_test/agent_private_stop_ends_only_what_the_npc_leads/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/gates = agent_test_open_explicit_gates()
	var/list/scene = agent_test_private_scene()
	var/mob/living/carbon/human/species/human/northern/agent_social/barmaid = scene[1]
	var/mob/living/carbon/human/partner = scene[2]
	var/datum/sex_action/act = scene[3]
	var/datum/ai_controller/agent_social/agent = barmaid.ai_controller
	TEST_ASSERT_NOTNULL(act, "Setup failed: the act must start.")

	var/list/stopped = agent.stop_led_acts()
	var/over = !agent.in_private()
	var/list/nothing = agent.stop_led_acts()
	// The partner's own act on the NPC is theirs to stop.
	var/datum/sex_scene_controller/theirs = partner.open_sex_scene(barmaid, FALSE)
	var/datum/sex_action/their_act = theirs?.try_start_action(/datum/sex_action/rub_body, "unit_test")
	var/list/not_mine = agent.stop_led_acts()
	var/theirs_goes_on = !isnull(their_act) && agent.in_private()

	agent_test_close_explicit_gates(gates)
	agent_test_restore_subsystem(saved, agent.binding)
	TEST_ASSERT_EQUAL(stopped["state"], AGENT_RESULT_SUCCEEDED, "The NPC stops what it leads: [stopped["detail"]]")
	TEST_ASSERT(over, "And the act is over.")
	TEST_ASSERT_EQUAL(nothing["state"], AGENT_RESULT_REJECTED, "With nothing to lead, stop is refused.")
	TEST_ASSERT(findtext(nothing["detail"], "consent"), "And the model is pointed at consent instead: [nothing["detail"]]")
	TEST_ASSERT_EQUAL(not_mine["state"], AGENT_RESULT_REJECTED, "An act the partner leads is not the NPC's to stop.")
	TEST_ASSERT(theirs_goes_on, "It goes on.")

/datum/unit_test/agent_private_pace_steps_within_what_was_agreed

/datum/unit_test/agent_private_pace_steps_within_what_was_agreed/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/gates = agent_test_open_explicit_gates()
	var/list/scene = agent_test_private_scene()
	var/mob/living/carbon/human/species/human/northern/agent_social/barmaid = scene[1]
	var/mob/living/carbon/human/partner = scene[2]
	var/datum/sex_action/act = scene[3]
	var/datum/ai_controller/agent_social/agent = barmaid.ai_controller
	var/datum/agent_binding/binding = agent.binding
	var/datum/sex_scene_controller/controller = barmaid.sex_scene?.get_controller(barmaid)
	TEST_ASSERT_NOTNULL(act, "Setup failed: the act must start.")
	TEST_ASSERT_NOTNULL(controller, "Setup failed: the NPC must have its own controller.")

	var/offered = ("pace" in binding.profile_payload()["permitted_actions"]) && binding.profile_permits("pace")
	var/list/faster = agent.pace_led_act("faster")
	var/quick = controller.speed == SEX_SPEED_HIGH && act.speed == SEX_SPEED_HIGH
	var/list/top = agent.pace_led_act("faster")
	var/list/slower = agent.pace_led_act("slower")
	var/steady = controller.speed == SEX_SPEED_MID
	var/list/rougher_unagreed = agent.pace_led_act("rougher")
	agent.pace_force_ceiling = SEX_FORCE_HIGH
	var/list/rougher = agent.pace_led_act("rougher")
	var/rough = controller.force == SEX_FORCE_HIGH && act.force == SEX_FORCE_HIGH
	var/list/gentler = agent.pace_led_act("gentler")
	var/list/gentler_again = agent.pace_led_act("gentler")
	var/gentle = controller.force == SEX_FORCE_LOW
	var/list/bottom = agent.pace_led_act("gentler")
	var/list/bad = agent.pace_led_act("wildly")
	act.scene?.stop_action(act)
	var/datum/sex_scene_controller/theirs = partner.open_sex_scene(barmaid, FALSE)
	var/datum/sex_action/their_act = theirs?.try_start_action(/datum/sex_action/rub_body, "unit_test")
	var/list/not_leading = agent.pace_led_act("faster")
	var/not_offered = !isnull(their_act) && !("pace" in binding.profile_payload()["permitted_actions"]) && !binding.profile_permits("pace")

	agent_test_close_explicit_gates(gates)
	agent_test_restore_subsystem(saved, binding)
	TEST_ASSERT(offered, "Leading an act in private, the model is offered pace.")
	TEST_ASSERT_EQUAL(faster["state"], AGENT_RESULT_SUCCEEDED, "Faster is one step up: [faster["detail"]]")
	TEST_ASSERT(quick, "And the act it leads goes quicker.")
	TEST_ASSERT_EQUAL(top["state"], AGENT_RESULT_REJECTED, "Quick is as fast as the model may go: [top["detail"]]")
	TEST_ASSERT(slower["state"] == AGENT_RESULT_SUCCEEDED && steady, "Slower is one step down.")
	TEST_ASSERT_EQUAL(rougher_unagreed["state"], AGENT_RESULT_REJECTED, "Rougher than agreed is refused: [rougher_unagreed["detail"]]")
	TEST_ASSERT(findtext(rougher_unagreed["detail"], "not agreed"), "And the model is told why: [rougher_unagreed["detail"]]")
	TEST_ASSERT(rougher["state"] == AGENT_RESULT_SUCCEEDED && rough, "With a rougher agreement, rougher is one step up.")
	TEST_ASSERT(gentler["state"] == AGENT_RESULT_SUCCEEDED && gentler_again["state"] == AGENT_RESULT_SUCCEEDED && gentle, "Gentler steps down to gentle.")
	TEST_ASSERT_EQUAL(bottom["state"], AGENT_RESULT_REJECTED, "And no further: [bottom["detail"]]")
	TEST_ASSERT(findtext(bad["detail"], "faster, slower, gentler or rougher"), "A bad step names the four: [bad["detail"]]")
	TEST_ASSERT(findtext(not_leading["detail"], "lead nothing"), "An act the partner leads is not the NPC's to pace: [not_leading["detail"]]")
	TEST_ASSERT(not_offered, "And pace is not offered then.")

/datum/unit_test/agent_private_pace_ceiling_comes_from_the_agreement

/datum/unit_test/agent_private_pace_ceiling_comes_from_the_agreement/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/gates = agent_test_open_explicit_gates()
	var/list/couple = agent_test_couple()
	var/mob/living/carbon/human/species/human/northern/agent_social/barmaid = couple[1]
	var/mob/living/carbon/human/partner = couple[2]
	var/datum/ai_controller/agent_social/agent = barmaid.ai_controller

	var/datum/sex_action/tender = agent.start_advance_act(partner, /datum/sex_action/kissing, AGENT_ADVANCE_TENDER)
	var/tender_ceiling = agent.pace_force_ceiling
	var/list/rougher_tender = agent.pace_led_act("rougher")
	tender?.scene?.stop_action(tender)
	var/datum/sex_action/intimate = agent.start_advance_act(partner, /datum/sex_action/rub_body, AGENT_ADVANCE_INTIMATE)
	var/intimate_ceiling = agent.pace_force_ceiling
	var/list/gentler_intimate = agent.pace_led_act("gentler")
	var/list/rougher_intimate = agent.pace_led_act("rougher")
	var/list/rougher_again = agent.pace_led_act("rougher")
	intimate?.scene?.stop_action(intimate)

	agent_test_close_explicit_gates(gates)
	agent_test_restore_subsystem(saved, agent.binding)
	TEST_ASSERT_NOTNULL(tender, "Setup failed: the tender act must start.")
	TEST_ASSERT_EQUAL(tender_ceiling, SEX_FORCE_LOW, "A tender yes allows nothing rougher than gentle.")
	TEST_ASSERT_EQUAL(rougher_tender["state"], AGENT_RESULT_REJECTED, "So rougher is refused: [rougher_tender["detail"]]")
	TEST_ASSERT_NOTNULL(intimate, "Setup failed: the intimate act must start.")
	TEST_ASSERT_EQUAL(intimate_ceiling, SEX_FORCE_MID, "An intimate yes allows firm.")
	TEST_ASSERT_EQUAL(gentler_intimate["state"], AGENT_RESULT_SUCCEEDED, "Gentler is always the model's: [gentler_intimate["detail"]]")
	TEST_ASSERT_EQUAL(rougher_intimate["state"], AGENT_RESULT_SUCCEEDED, "Back up to firm: [rougher_intimate["detail"]]")
	TEST_ASSERT_EQUAL(rougher_again["state"], AGENT_RESULT_REJECTED, "And no rougher than firm: [rougher_again["detail"]]")

/datum/unit_test/agent_private_has_no_follow_up_turns

/datum/unit_test/agent_private_has_no_follow_up_turns/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/gates = agent_test_open_explicit_gates()
	var/list/scene = agent_test_private_scene()
	var/mob/living/carbon/human/species/human/northern/agent_social/barmaid = scene[1]
	var/datum/sex_action/act = scene[3]
	var/datum/ai_controller/agent_social/agent = barmaid.ai_controller
	var/datum/agent_binding/binding = agent.binding
	TEST_ASSERT_NOTNULL(act, "Setup failed: the act must start.")

	binding.begin_interaction()
	var/more = binding.complete_action(AGENT_RESULT_SUCCEEDED, "spoke", spoke = TRUE)
	var/settled = !binding.dirty && binding.continuation_budget == 0

	agent_test_close_explicit_gates(gates)
	agent_test_restore_subsystem(saved, binding)
	TEST_ASSERT(!more, "In private an answer earns no follow-up turn.")
	TEST_ASSERT(settled, "The chain ends; the cadence brings the next turn.")
