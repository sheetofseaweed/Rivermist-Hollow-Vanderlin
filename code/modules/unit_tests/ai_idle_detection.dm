/datum/unit_test/ai_idle_recalculate_wakes_when_tracked_cell_has_client
#ifdef FOCUS_AI_IDLE_DETECTION_TEST
	focus = TRUE
#endif

/datum/unit_test/ai_idle_recalculate_wakes_when_tracked_cell_has_client/Run()
	var/mob/living/simple_animal/hostile/hostile_mob = allocate(/mob/living/simple_animal/hostile)
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human)
	var/datum/ai_controller/controller = hostile_mob.ai_controller
	if(!controller)
		controller = allocate(/datum/ai_controller, hostile_mob)

	controller.set_ai_status(AI_STATUS_IDLE)

	var/datum/spatial_grid_cell/watched_cell = controller.our_cells.member_cells[1]
	TEST_ASSERT_NOTNULL(watched_cell, "AI controller did not register any watched spatial cells.")

	var/list/old_client_contents = watched_cell.client_contents
	watched_cell.client_contents = list(viewer)
	controller.recalculate_idle()
	watched_cell.client_contents = old_client_contents

	TEST_ASSERT_EQUAL(controller.ai_status, AI_STATUS_ON, "Idle AI should wake when a recalculated watched cell already contains a client mob.")

/datum/unit_test/ai_idle_client_enter_signal_wakes_idle_ai
#ifdef FOCUS_AI_IDLE_DETECTION_TEST
	focus = TRUE
#endif

/datum/unit_test/ai_idle_client_enter_signal_wakes_idle_ai/Run()
	var/mob/living/simple_animal/hostile/hostile_mob = allocate(/mob/living/simple_animal/hostile)
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human)
	var/datum/ai_controller/controller = hostile_mob.ai_controller
	if(!controller)
		controller = allocate(/datum/ai_controller, hostile_mob)

	viewer.forceMove(get_turf(hostile_mob))
	controller.set_ai_status(AI_STATUS_IDLE)

	// The spatial grid delivers a LIST of client mobs, not a single atom. A nearby client must arm
	// the alert and wake the AI; the handler must not runtime on the list payload.
	controller.on_client_enter(null, list(viewer))

	TEST_ASSERT_EQUAL(controller.ai_status, AI_STATUS_ON, "A client entering a watched cell must wake an idle AI via the list-payload signal handler.")

/datum/unit_test/ai_idle_active_target_prevents_idle
#ifdef FOCUS_AI_IDLE_DETECTION_TEST
	focus = TRUE
#endif

/datum/unit_test/ai_idle_active_target_prevents_idle/Run()
	var/mob/living/simple_animal/hostile/hostile_mob = allocate(/mob/living/simple_animal/hostile)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human)
	var/datum/ai_controller/controller = hostile_mob.ai_controller
	if(!controller)
		controller = allocate(/datum/ai_controller, hostile_mob)

	controller.set_ai_status(AI_STATUS_IDLE)
	// Detection field firing on FOV entry sets a target while idle; the mob must wake to engage it,
	// not doze through a 5s idle plan with prey standing in front of it.
	controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, prey)
	controller.recalculate_idle()

	TEST_ASSERT_EQUAL(controller.ai_status, AI_STATUS_ON, "An AI holding a live combat target must wake instead of idling.")
