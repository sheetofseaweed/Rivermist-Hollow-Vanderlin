// Romance: an agent NPC with the setting on chooses its own company, through the consent action.

/obj/effect/agent_npc_spawner/barmaid/test
	npc_name = "Testy Barmaid"

/// A bound pawn playing the built-in barmaid, who has romance on.
/datum/unit_test/proc/agent_test_romantic_pawn()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/agent_profile/barmaid/template = new()
	agent_swap_profile(pawn, template)
	qdel(template)
	return pawn

/datum/unit_test/agent_romance_refuses_without_a_yes

/datum/unit_test/agent_romance_refuses_without_a_yes/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/barmaid = agent_test_romantic_pawn()
	var/mob/living/carbon/human/species/human/northern/agent_social/villager = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/barmaid_agent = barmaid.ai_controller
	var/datum/ai_controller/agent_social/villager_agent = villager.ai_controller
	var/mob/living/carbon/human/suitor = allocate(/mob/living/carbon/human/species/human/northern)

	var/datum/sex_scene_controller/unasked = suitor.open_sex_scene(barmaid, FALSE)
	var/unasked_reason = suitor.get_sex_scene_refusal(barmaid)
	var/villager_reason = suitor.get_sex_scene_refusal(villager)
	barmaid_agent.grant_consent(suitor)
	var/datum/sex_scene_controller/chosen = suitor.open_sex_scene(barmaid, FALSE)
	var/allowed_after_yes = !isnull(chosen)
	qdel(chosen)
	barmaid_agent.note_aggressor(suitor)
	var/hit_reason = suitor.get_sex_scene_refusal(barmaid)
	barmaid_agent.aggressors = null
	barmaid_agent.consents[WEAKREF(suitor)] = world.time - 1
	var/lapsed_reason = suitor.get_sex_scene_refusal(barmaid)
	agent_test_restore_subsystem(saved, barmaid_agent.binding)
	agent_test_restore_subsystem(saved, villager_agent.binding)

	TEST_ASSERT_NULL(unasked, "Romance on is not consent: nobody gets a scene before a yes.")
	TEST_ASSERT(findtext(unasked_reason, "has not agreed"), "And the suitor is told so: [unasked_reason]")
	TEST_ASSERT(findtext(villager_reason, "refuses"), "With romance off the NPC refuses outright: [villager_reason]")
	TEST_ASSERT(allowed_after_yes, "After the NPC's own yes, the scene opens.")
	TEST_ASSERT(findtext(hit_reason, "after what you did"), "A yes does not survive a blow: [hit_reason]")
	TEST_ASSERT(findtext(lapsed_reason, "has not agreed"), "Nor its time running out: [lapsed_reason]")

/datum/unit_test/agent_romance_asking_reaches_the_model

/datum/unit_test/agent_romance_asking_reaches_the_model/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/barmaid = agent_test_romantic_pawn()
	var/mob/living/carbon/human/species/human/northern/agent_social/villager = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/barmaid_agent = barmaid.ai_controller
	var/datum/ai_controller/agent_social/villager_agent = villager.ai_controller
	var/mob/living/carbon/human/suitor = allocate(/mob/living/carbon/human/species/human/northern)
	barmaid_agent.binding.take_events()
	villager_agent.binding.take_events()

	// The drag a player makes to start a scene: themselves onto the other.
	barmaid.MiddleMouseDrop_T(suitor, suitor)
	barmaid.MiddleMouseDrop_T(suitor, suitor)
	villager.MiddleMouseDrop_T(suitor, suitor)
	var/list/asks = agent_test_events_named(barmaid_agent.binding.take_events(), AGENT_EVENT_PRIVATE_REQUEST)
	var/list/villager_asks = agent_test_events_named(villager_agent.binding.take_events(), AGENT_EVENT_PRIVATE_REQUEST)
	var/list/first_ask = length(asks) ? asks[1]["detail"] : list()
	agent_test_restore_subsystem(saved, barmaid_agent.binding)
	agent_test_restore_subsystem(saved, villager_agent.binding)

	TEST_ASSERT_EQUAL(length(asks), 1, "A refused ask must reach the model, and asking twice is one event, not two.")
	TEST_ASSERT_EQUAL(first_ask["by"], suitor.get_visible_name(), "The model must know who asked.")
	TEST_ASSERT_EQUAL(first_ask["count"], 2, "And how often.")
	TEST_ASSERT_EQUAL(length(villager_asks), 0, "An NPC with romance off is never asked: it simply refuses.")

/datum/unit_test/agent_romance_consent_through_dispatch

/datum/unit_test/agent_romance_consent_through_dispatch/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/barmaid = agent_test_romantic_pawn()
	var/datum/ai_controller/agent_social/agent = barmaid.ai_controller
	var/datum/agent_binding/binding = agent.binding
	var/mob/living/carbon/human/suitor = allocate(/mob/living/carbon/human/species/human/northern)
	TEST_ASSERT_NOTNULL(binding, "Setup failed: the pawn must be bound.")
	var/suitor_handle = agent_test_handle_of(binding, barmaid, suitor)
	TEST_ASSERT_NOTNULL(suitor_handle, "Setup failed: the suitor must have a handle in the scene.")
	binding.take_events()

	SSagent_npc.dispatch_decision(binding, agent_test_decision(list("name" = "consent", "handle" = suitor_handle, "key" = "maybe")))
	var/after_maybe = agent.consent_until(suitor)
	SSagent_npc.dispatch_decision(binding, agent_test_decision(list("name" = "consent", "handle" = suitor_handle, "key" = "Yes")))
	var/after_yes = agent.consent_until(suitor)
	var/list/myself = agent_describe_self(barmaid)
	var/list/agreed = myself["agreed_with"]
	var/datum/sex_scene_controller/chosen = suitor.open_sex_scene(barmaid, FALSE)
	var/allowed_after_yes = !isnull(chosen)
	qdel(chosen)
	SSagent_npc.dispatch_decision(binding, agent_test_decision(list("name" = "consent", "handle" = suitor_handle, "key" = "no")))
	var/after_no = agent.consent_until(suitor)
	var/list/results = list()
	for(var/list/entry as anything in agent_test_events_named(binding.take_events(), "action_result"))
		results += "[entry["detail"]["state"]]: [entry["detail"]["detail"]]"
	var/datum/agent_profile/villager/plain = new()
	agent_swap_profile(barmaid, plain)
	qdel(plain)
	SSagent_npc.dispatch_decision(binding, agent_test_decision(list("name" = "consent", "handle" = suitor_handle, "key" = "yes")))
	var/plain_consent = agent.consent_until(suitor)
	agent_test_restore_subsystem(saved, binding)

	TEST_ASSERT(!after_maybe, "Only yes or no is an answer.")
	TEST_ASSERT(after_yes > world.time, "Yes must grant consent.")
	TEST_ASSERT(length(agreed) && agreed[1]["name"] == suitor.get_visible_name(), "The model's scene must show who it said yes to.")
	TEST_ASSERT(allowed_after_yes, "And the suitor's scene must open.")
	TEST_ASSERT(!after_no, "No must take it back.")
	TEST_ASSERT(findtext(jointext(results, " | "), "yes or no"), "A bad answer must be refused with the reason: [jointext(results, " | ")]")
	TEST_ASSERT(!plain_consent, "A character with romance off can never consent, whatever the model asks for.")

/datum/unit_test/agent_romance_taking_it_back_ends_the_act

/datum/unit_test/agent_romance_taking_it_back_ends_the_act/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/barmaid = agent_test_romantic_pawn()
	var/datum/ai_controller/agent_social/agent = barmaid.ai_controller
	var/mob/living/carbon/human/suitor = allocate(/mob/living/carbon/human/species/human/northern)
	agent.grant_consent(suitor)
	var/datum/sex_scene_controller/scene = suitor.open_sex_scene(barmaid, FALSE)
	TEST_ASSERT_NOTNULL(scene, "Setup failed: the scene must open after a yes.")
	var/datum/sex_action/act = scene.try_start_action(/datum/sex_action/rub_body, "unit_test")
	TEST_ASSERT_NOTNULL(act, "Setup failed: the suitor's act must start.")
	var/interaction_key = "sex_action_[REF(act)]"
	var/running = DOING_INTERACTION(suitor, interaction_key)
	agent.romance_watch()
	agent.binding.take_events()

	agent.withdraw_consent(suitor)
	sleep(3 SECONDS)
	var/stopped = QDELETED(act) || !DOING_INTERACTION(suitor, interaction_key)
	agent.romance_watch()
	var/list/private_time = agent_test_events_named(agent.binding.take_events(), AGENT_EVENT_PRIVATE_TIME)
	var/list/told = length(private_time) ? private_time[1]["detail"] : list()
	if(!QDELETED(act))
		act.stop_runtime()
	agent_test_restore_subsystem(saved, agent.binding)

	TEST_ASSERT(running, "The act must run while the yes holds.")
	TEST_ASSERT(stopped, "Taking it back must end the act on its next step.")
	TEST_ASSERT_EQUAL(told["what"], "spent", "The model must hear that its private time ended.")
	TEST_ASSERT_EQUAL(told["by"], suitor.get_visible_name(), "And with whom.")

/datum/unit_test/agent_romance_partner_may_take_a_hand

/datum/unit_test/agent_romance_partner_may_take_a_hand/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/barmaid = agent_test_romantic_pawn()
	var/datum/ai_controller/agent_social/agent = barmaid.ai_controller
	var/mob/living/carbon/human/suitor = allocate(/mob/living/carbon/human/species/human/northern)
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human/species/human/northern)
	TEST_ASSERT_NOTNULL(agent?.binding, "Setup failed: the pawn must be bound.")

	var/busy_unchosen = agent.busy_away_from_post()
	agent.grant_consent(suitor)
	var/busy_chosen = agent.busy_away_from_post()
	agent.note_stimulus(AGENT_STIMULUS_GRABBED, suitor)
	var/suitor_grab_is_attack = agent.is_aggressor(suitor)
	agent.note_stimulus(AGENT_STIMULUS_GRABBED, stranger)
	var/stranger_grab_is_attack = agent.is_aggressor(stranger)
	agent.note_stimulus(AGENT_STIMULUS_STRUCK, suitor)
	var/suitor_blow_is_attack = agent.is_aggressor(suitor)
	agent_test_restore_subsystem(saved, agent.binding)

	TEST_ASSERT(!busy_unchosen, "Setup failed: an idle NPC is free to walk back to its post.")
	TEST_ASSERT(busy_chosen, "Someone it said yes to may take it elsewhere: it must not walk back to its post.")
	TEST_ASSERT(!suitor_grab_is_attack, "Leading a willing partner off by the hand is not an attack.")
	TEST_ASSERT(stranger_grab_is_attack, "Anyone else's grab still is.")
	TEST_ASSERT(suitor_blow_is_attack, "And a blow from the partner is still a blow.")

/datum/unit_test/agent_romance_setting_is_a_profile_toggle

/datum/unit_test/agent_romance_setting_is_a_profile_toggle/Run()
	var/datum/agent_profile/barmaid/barmaid = new()
	var/datum/agent_profile/villager/villager = new()
	var/list/payload = barmaid.to_payload()
	var/datum/agent_profile/reloaded = agent_profile_from_payload(payload)
	var/datum/agent_profile/copied = barmaid.clone()
	var/list/hand_edited = villager.to_payload()
	hand_edited["romance"] = "yes"
	hand_edited["permitted_actions"] += "consent"
	var/datum/agent_profile/smuggled = agent_profile_from_payload(hand_edited)
	var/barmaid_permits = barmaid.permits("consent")
	var/villager_permits = villager.permits("consent")
	var/smuggled_permits = smuggled.permits("consent")
	var/smuggled_list = ("consent" in smuggled.permitted_actions)
	qdel(barmaid)
	qdel(villager)
	qdel(reloaded)
	qdel(copied)
	qdel(smuggled)

	TEST_ASSERT(("consent" in payload["permitted_actions"]), "Romance on must offer the model consent.")
	TEST_ASSERT(payload["romance"], "And the setting must travel with the profile.")
	TEST_ASSERT(reloaded.romance && copied.romance, "Saving, loading and copying must keep it.")
	TEST_ASSERT(barmaid_permits && !villager_permits, "Consent comes from the setting alone.")
	TEST_ASSERT(!smuggled.romance && !smuggled_permits && !smuggled_list, "A hand-edited file cannot switch it on with text or sneak the action in.")

/datum/unit_test/agent_romance_spawner_places_a_barmaid

/datum/unit_test/agent_romance_spawner_places_a_barmaid/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/turf/here = run_loc_floor_top_right
	new /obj/effect/agent_npc_spawner/barmaid/test(here)
	var/mob/living/carbon/human/barmaid = agent_test_spawned_named(here, "Testy Barmaid")
	TEST_ASSERT_NOTNULL(barmaid, "The barmaid spawner must leave its NPC where it stood.")
	var/datum/ai_controller/agent_social/agent = barmaid.ai_controller
	var/label = agent?.profile?.label
	var/chooses = agent?.romance_enabled()
	var/gender = barmaid.gender
	var/dressed = FALSE
	for(var/obj/item/worn in barmaid.get_equipped_items())
		if(istype(worn, /obj/item/clothing/shirt/dress))
			dressed = TRUE
	agent_test_restore_subsystem(saved, agent?.binding)
	qdel(barmaid)

	TEST_ASSERT_EQUAL(label, "barmaid", "The NPC must play the barmaid.")
	TEST_ASSERT(chooses, "With romance on.")
	TEST_ASSERT_EQUAL(gender, FEMALE, "As a woman.")
	TEST_ASSERT(dressed, "In a dress.")

/// What a player leaves on a body they possessed: a mind with their key, and no ERP while away.
/proc/agent_test_leave_player_mark(mob/living/body, key)
	body.mind_initialize()
	body.mind.key = key
	body.set_cached_erp_preferences(list(/datum/erp_preference/boolean/allow_player_erp_when_disconnected = FALSE))

/datum/unit_test/agent_romance_possessed_npc_answers_for_itself

/datum/unit_test/agent_romance_possessed_npc_answers_for_itself/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/list/couple = agent_test_couple()
	var/mob/living/carbon/human/species/human/northern/agent_social/barmaid = couple[1]
	var/mob/living/carbon/human/partner = couple[2]
	var/datum/ai_controller/agent_social/agent = barmaid.ai_controller
	// Live, an admin possessed the NPC to rename it, and every scene with it was refused afterwards (2026-10-06).
	agent_test_leave_player_mark(barmaid, "unit_test_admin")

	var/datum/sex_scene_controller/scene = partner.open_sex_scene(barmaid, FALSE)
	var/opened = !isnull(scene)
	var/refusal = opened ? "" : partner.get_sex_scene_refusal(barmaid)
	qdel(scene)
	var/advance_act = agent.pick_advance_act(partner, AGENT_ADVANCE_TENDER)
	agent_test_restore_subsystem(saved, agent.binding)

	TEST_ASSERT(opened, "An agent NPC someone possessed and left must still answer for itself: [refusal]")
	TEST_ASSERT_NOTNULL(advance_act, "And its own advances must still find an act; live, all seventeen were refused.")

/datum/unit_test/agent_attach_refuses_someone_elses_character

/datum/unit_test/agent_attach_refuses_someone_elses_character/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human/species/human/northern)
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human/species/human/northern)
	agent_test_leave_player_mark(body, "unit_test_player")
	var/datum/agent_profile/barmaid/template = new()
	// Review 2026-10-16: an agent on a logged-off player's character outlived their absence.
	var/attach_refusal = agent_attach_controller(body, template)
	var/attached = istype(body.ai_controller, /datum/ai_controller/agent_social)
	var/their_own = agent_borrows_character(body, ckey("unit_test_player"))
	var/never_played_refusal = agent_attach_controller(stranger, template)
	var/datum/ai_controller/agent_social/stranger_agent = stranger.ai_controller
	qdel(template)
	agent_test_restore_subsystem(saved, istype(stranger_agent) ? stranger_agent.binding : null)

	TEST_ASSERT(findtext(attach_refusal, "unit_test_player's character"), "Attaching to someone else's character must be refused, and say whose: [attach_refusal]")
	TEST_ASSERT(!attached, "And nothing may be attached.")
	TEST_ASSERT(!their_own, "A body the attaching admin played themselves is still theirs to attach to.")
	TEST_ASSERT_NULL(never_played_refusal, "So is one nobody ever played.")

/datum/unit_test/agent_login_releases_the_body

/datum/unit_test/agent_login_releases_the_body/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/barmaid = agent_test_romantic_pawn()
	var/datum/ai_controller/agent_social/agent = barmaid.ai_controller
	var/datum/agent_binding/binding = agent.binding
	TEST_ASSERT_NOTNULL(binding, "Setup failed: the pawn must be bound.")
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human/species/human/northern)
	var/refused_before = !barmaid.allows_sex_with(stranger)
	binding.mark_dirty("heard_speech", AGENT_EVENT_LOW, list("speaker" = "Bob", "text" = "a whisper"))

	// What Login() sends when a client arrives. Unit tests cannot make a client, but the signal is the seam.
	SEND_SIGNAL(barmaid, COMSIG_MOB_LOGIN)
	var/allowed_after = barmaid.allows_sex_with(stranger)
	var/still_bound = !QDELETED(binding) || !isnull(agent.binding)
	var/list/registered = agent.signal_procs?[barmaid]
	var/still_hearing = !isnull(registered?[COMSIG_MOVABLE_HEAR])
	var/still_answering = !isnull(registered?[COMSIG_LIVING_SEX_CONSENT])
	agent.register_cooldown = 0
	var/rebound = agent.ensure_registered()
	SEND_SIGNAL(barmaid, COMSIG_MOB_LOGOUT)
	var/status_after_logout = agent.ai_status
	// An admin brings it back by attaching again, which replaces the released controller.
	var/reattach_refusal = agent_attach_controller(barmaid, null)
	var/datum/ai_controller/agent_social/fresh = barmaid.ai_controller
	var/fresh_bound = istype(fresh) && fresh != agent && !isnull(fresh.binding) && !QDELETED(fresh.binding)
	agent_test_restore_subsystem(saved, istype(fresh) ? fresh.binding : null)

	TEST_ASSERT(refused_before, "Setup failed: the agent must refuse a stranger it never chose.")
	TEST_ASSERT(allowed_after, "Once a player has the body, the agent must not answer for its consent.")
	TEST_ASSERT(!still_answering, "The consent signal must be unregistered.")
	TEST_ASSERT(!still_hearing, "Nor may it keep hearing what the player hears.")
	TEST_ASSERT(!still_bound, "The binding goes, and with it every line buffered to send.")
	TEST_ASSERT(!rebound, "It must not bind again, or the next logout ships the player's own conversation.")
	TEST_ASSERT_EQUAL(status_after_logout, AI_STATUS_OFF, "No reflexes or fights on a player's body while they are away.")
	TEST_ASSERT_NULL(reattach_refusal, "Attaching again must replace a released controller, not call it agent controlled.")
	TEST_ASSERT(fresh_bound, "And the new one binds.")

/datum/unit_test/agent_romance_answer_is_said_out_loud

/datum/unit_test/agent_romance_answer_is_said_out_loud/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/barmaid = agent_test_romantic_pawn()
	var/datum/ai_controller/agent_social/agent = barmaid.ai_controller
	var/datum/agent_binding/binding = agent.binding
	var/mob/living/carbon/human/suitor = allocate(/mob/living/carbon/human/species/human/northern)
	TEST_ASSERT_NOTNULL(binding, "Setup failed: the pawn must be bound.")
	var/suitor_handle = agent_test_handle_of(binding, barmaid, suitor)
	TEST_ASSERT_NOTNULL(suitor_handle, "Setup failed: the suitor must have a handle in the scene.")
	binding.mark_dirty("heard_speech")
	binding.take_events()

	// Live, a silent yes left the player guessing whether anything had happened (2026-10-06). Validated, as live replies are.
	SSagent_npc.dispatch_decision(binding, agent_test_decision(agent_validate_action(list("name" = "consent", "handle" = suitor_handle, "key" = "yes", "text" = "Aye, come along then."))))
	var/streak_after_words = binding.speech_streak
	SSagent_npc.dispatch_decision(binding, agent_test_decision(agent_validate_action(list("name" = "consent", "handle" = suitor_handle, "key" = "no"))))
	var/streak_after_shake = binding.speech_streak
	SSagent_npc.dispatch_decision(binding, agent_test_decision(agent_validate_action(list("name" = "consent", "handle" = suitor_handle, "key" = "yes"))))
	var/agreed = agent.consent_until(suitor)
	var/said = agent_test_mob_log(barmaid, LOG_SAY)
	var/acted = agent_test_mob_log(barmaid, LOG_EMOTE)
	agent_test_restore_subsystem(saved, binding)

	TEST_ASSERT(findtext(said, "come along then"), "The yes must be said out loud, in the model's words: [said]")
	TEST_ASSERT_EQUAL(streak_after_words, 1, "Words with an answer count as speech for the chain.")
	TEST_ASSERT(findtext(acted, "shakes"), "A no without words still shows, as a shake of the head: [acted]")
	TEST_ASSERT_EQUAL(streak_after_shake, 0, "A head shake is not speech.")
	TEST_ASSERT(findtext(acted, "nods"), "And a yes without words as a nod: [acted]")
	TEST_ASSERT(agreed, "A yes without words still counts.")

/datum/unit_test/agent_romance_lapse_is_announced

/datum/unit_test/agent_romance_lapse_is_announced/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/barmaid = agent_test_romantic_pawn()
	var/datum/ai_controller/agent_social/agent = barmaid.ai_controller
	var/mob/living/carbon/human/suitor = allocate(/mob/living/carbon/human/species/human/northern)
	TEST_ASSERT_NOTNULL(agent?.binding, "Setup failed: the pawn must be bound.")
	agent.grant_consent(suitor)
	agent.binding.take_events()

	agent.romance_watch()
	var/list/while_live = agent_test_events_named(agent.binding.take_events(), AGENT_EVENT_PRIVATE_TIME)
	agent.consents[WEAKREF(suitor)] = world.time - 1
	agent.romance_watch()
	var/list/lapsed = agent_test_events_named(agent.binding.take_events(), AGENT_EVENT_PRIVATE_TIME)
	var/list/told = length(lapsed) ? lapsed[1]["detail"] : list()
	agent.romance_watch()
	var/list/again = agent_test_events_named(agent.binding.take_events(), AGENT_EVENT_PRIVATE_TIME)
	var/list/advance = agent.make_advance(suitor, "tender")
	agent_test_restore_subsystem(saved, agent.binding)

	TEST_ASSERT_EQUAL(length(while_live), 0, "Setup failed: a live yes is not announced.")
	// Live, her yes ran out unannounced and she kept trying advances the game refused (2026-10-15).
	TEST_ASSERT_EQUAL(told["what"], "lapsed", "The model must hear that its yes ran out.")
	TEST_ASSERT_EQUAL(told["by"], suitor.get_visible_name(), "And with whom.")
	TEST_ASSERT_EQUAL(length(again), 0, "Once, not at every look.")
	TEST_ASSERT(findtext(advance["detail"], "your yes has run out"), "A refused advance must say whose yes is missing: [advance["detail"]]")
