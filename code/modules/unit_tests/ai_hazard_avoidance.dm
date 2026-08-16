/datum/unit_test/ai_hazard_avoidance_detects_object_hazards
#ifdef FOCUS_AI_IDLE_DETECTION_TEST
	focus = TRUE
#endif

/datum/unit_test/ai_hazard_avoidance_detects_object_hazards/Run()
	var/turf/clear_turf = run_loc_floor_bottom_left
	TEST_ASSERT_NOTNULL(clear_turf, "Test setup needs a run turf.")
	TEST_ASSERT(!ai_turf_is_hazardous(clear_turf), "An empty floor turf should not read as hazardous.")

	// Bushes are objects sitting on a turf, so the old turf-type-only check never saw them and
	// wandering AI walked in and scratched itself to death.
	var/obj/structure/flora/grass/bush/bush = allocate(/obj/structure/flora/grass/bush, clear_turf)
	TEST_ASSERT_NOTNULL(bush, "Test setup needs a bush.")
	TEST_ASSERT(ai_turf_is_hazardous(clear_turf), "A turf holding a bush must read as hazardous to AI movement.")

/datum/unit_test/ai_hazard_avoidance_allows_destination_object_hazard
#ifdef FOCUS_AI_IDLE_DETECTION_TEST
	focus = TRUE
#endif

/datum/unit_test/ai_hazard_avoidance_allows_destination_object_hazard/Run()
	var/turf/destination = run_loc_floor_bottom_left
	TEST_ASSERT_NOTNULL(destination, "Test setup needs a run turf.")

	var/obj/structure/flora/grass/bush/bush = allocate(/obj/structure/flora/grass/bush, destination)
	TEST_ASSERT_NOTNULL(bush, "Test setup needs a bush.")

	// Prey hides inside bushes, so a mob closing on a target standing there must still be allowed in.
	TEST_ASSERT(!ai_turf_is_hazardous(destination, destination), "An object hazard on the mob's actual destination must not block movement, or mobs can never reach prey hiding in bushes.")
