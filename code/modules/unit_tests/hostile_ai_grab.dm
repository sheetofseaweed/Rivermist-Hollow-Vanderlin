/datum/unit_test/hostile_ai_retargets_to_grabber
	procs_tested = list(/mob/living/set_pulledby)

#ifdef FOCUS_HOSTILE_AI_GRAB_TEST
/datum/unit_test/hostile_ai_retargets_to_grabber
	focus = TRUE
#endif

/datum/unit_test/hostile_ai_horny_grab_turns_hostile_after_hold
	procs_tested = list(/mob/living/set_pulledby)

#ifdef FOCUS_HOSTILE_AI_GRAB_TEST
/datum/unit_test/hostile_ai_horny_grab_turns_hostile_after_hold
	focus = TRUE
#endif

/datum/unit_test/hostile_ai_horny_grab_knocks_out_after_two_grabber_climaxes
	procs_tested = list(/mob/living/set_pulledby)

#ifdef FOCUS_HOSTILE_AI_GRAB_TEST
/datum/unit_test/hostile_ai_horny_grab_knocks_out_after_two_grabber_climaxes
	focus = TRUE
#endif

/datum/targetting_datum/basic/unit_test_allow_clientless_horny/can_use_horny_ai_target(mob/living/living_mob, mob/living/carbon/human/human_target)
	return TRUE

/datum/unit_test/hostile_ai_retargets_to_grabber/Run()
	var/mob/living/simple_animal/hostile/simple_hostile = allocate(/mob/living/simple_animal/hostile)
	assert_grab_retarget(simple_hostile, "simple hostile")

	var/mob/living/carbon/human/species/goblin/npc/goblin_npc = allocate(/mob/living/carbon/human/species/goblin/npc)
	assert_grab_retarget(goblin_npc, "goblin NPC")

/datum/unit_test/hostile_ai_retargets_to_grabber/proc/assert_grab_retarget(mob/living/hostile_mob, context)
	var/mob/living/carbon/human/original_target = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/grabber = allocate(/mob/living/carbon/human)

	var/datum/ai_controller/controller = hostile_mob.ai_controller
	if(!controller)
		controller = allocate(/datum/ai_controller, hostile_mob)
	if(!hostile_mob.GetComponent(/datum/component/ai_aggro_system))
		hostile_mob.AddComponent(/datum/component/ai_aggro_system)

	var/datum/targetting_datum/basic/targetting_datum = allocate(/datum/targetting_datum/basic)
	controller.set_blackboard_key(BB_TARGETTING_DATUM, targetting_datum)
	controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, original_target)
	controller.set_blackboard_key(BB_HIGHEST_THREAT_MOB, original_target)

	hostile_mob.set_pulledby(grabber)

	TEST_ASSERT_EQUAL(controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET], grabber, "[context] should switch its current target to the mob grabbing it.")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_HIGHEST_THREAT_MOB], grabber, "[context] should treat its grabber as the highest immediate threat.")
	TEST_ASSERT(hostile_mob.hostile_grab_resist_timer, "[context] should schedule occasional grab resistance while held.")

/datum/unit_test/hostile_ai_horny_grab_turns_hostile_after_hold/Run()
	var/mob/living/carbon/human/species/goblin/npc/goblin_npc = allocate(/mob/living/carbon/human/species/goblin/npc)
	var/mob/living/carbon/human/grabber = allocate(/mob/living/carbon/human)

	prepare_horny_grab_test_pair(goblin_npc, grabber)
	goblin_npc.hostile_grab_horny_hostility_delay = 1

	var/datum/ai_controller/controller = goblin_npc.ai_controller
	var/datum/targetting_datum/basic/targetting_datum = controller.blackboard[BB_TARGETTING_DATUM]
	TEST_ASSERT(targetting_datum.is_selected_horny_target(goblin_npc, grabber), "Test setup should make the grabber a valid horny target.")

	controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_HORNY_TARGET, grabber)
	goblin_npc.set_pulledby(grabber)

	TEST_ASSERT_NULL(controller.blackboard[BB_HORNY_AGGRO_TARGET], "Horny-valid grabbers should not become horny-hostile immediately.")

	sleep(2)

	var/list/hostile_targets = controller.blackboard[BB_HORNY_HOSTILE_TARGETS]
	TEST_ASSERT(hostile_targets && !isnull(hostile_targets[grabber]), "Holding a hostile horny AI for long enough should mark the grabber horny-hostile.")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_HORNY_AGGRO_TARGET], grabber, "The long-held grabber should become the horny aggro target.")
	TEST_ASSERT_NULL(controller.blackboard[BB_BASIC_MOB_CURRENT_HORNY_TARGET], "Turning hostile should clear the current horny target so aggro planning can take over.")

/datum/unit_test/hostile_ai_horny_grab_knocks_out_after_two_grabber_climaxes/Run()
	var/mob/living/carbon/human/species/goblin/npc/goblin_npc = allocate(/mob/living/carbon/human/species/goblin/npc)
	var/mob/living/carbon/human/grabber = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/other_actor = allocate(/mob/living/carbon/human)

	prepare_horny_grab_test_pair(goblin_npc, grabber)
	goblin_npc.set_pulledby(grabber)

	SEND_SIGNAL(goblin_npc, COMSIG_SEX_CLIMAX, null, goblin_npc, grabber, other_actor)
	SEND_SIGNAL(goblin_npc, COMSIG_SEX_CLIMAX, null, goblin_npc, other_actor, grabber)
	TEST_ASSERT(!goblin_npc.IsUnconscious(), "Climaxes not initiated by the grabber against the grabbed mob should not count.")

	SEND_SIGNAL(goblin_npc, COMSIG_SEX_CLIMAX, null, goblin_npc, grabber, grabber)
	TEST_ASSERT(!goblin_npc.IsUnconscious(), "The first grabber-initiated climax should not knock out the grabbed mob.")

	SEND_SIGNAL(goblin_npc, COMSIG_SEX_CLIMAX, null, goblin_npc, grabber, grabber)
	TEST_ASSERT(goblin_npc.IsUnconscious(), "The second grabber-initiated climax during the horny grab window should knock out the grabbed mob.")
	TEST_ASSERT(goblin_npc.AmountUnconscious() >= 2 MINUTES - 1, "The grabbed mob should be knocked out for roughly two minutes.")
	TEST_ASSERT_NULL(goblin_npc.hostile_grab_horny_hostility_timer, "Sex-combat knockout should end the horny grab hostility window.")

/datum/unit_test/proc/prepare_horny_grab_test_pair(mob/living/hostile_mob, mob/living/carbon/human/grabber)
	hostile_mob.gender = MALE
	grabber.set_cached_erp_preferences(list(
		/datum/erp_preference/bitflag/horny_mobs = HORNY_MOBS_TAG_MALES,
		/datum/erp_preference/bitflag/horny_mob_types = HORNY_MOB_TYPE_HUMANOIDS,
	))
	var/datum/ai_controller/controller = hostile_mob.ai_controller
	if(controller)
		controller.set_blackboard_key(BB_TARGETTING_DATUM, allocate(/datum/targetting_datum/basic/unit_test_allow_clientless_horny))
