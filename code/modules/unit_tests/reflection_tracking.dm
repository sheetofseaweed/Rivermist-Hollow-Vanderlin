/// The reflection component must hear about deletions of everything it tracks, or it holds refs to dead movables.
/datum/unit_test/reflection_hooks_qdel_on_tracked_movables
#ifdef FOCUS_REFLECTION_TRACKING
	focus = TRUE
#endif

/datum/unit_test/reflection_hooks_qdel_on_tracked_movables/Run()
	var/turf/floor = run_loc_floor_bottom_left
	TEST_ASSERT_NOTNULL(floor, "Test setup needs a run turf.")

	var/obj/structure/mirror/mirror = allocate(/obj/structure/mirror, floor)
	var/datum/component/reflection/reflection = mirror.GetComponent(/datum/component/reflection)
	TEST_ASSERT_NOTNULL(reflection, "Test setup needs a mirror carrying a reflection component.")

	var/obj/structure/flora/grass/bush/bush = allocate(/obj/structure/flora/grass/bush, floor)
	var/list/tracked = reflection.vars["reflected_movables"]
	TEST_ASSERT(tracked && (bush in tracked), "The mirror must track a movable spawned next to it.")

	var/list/hooked = reflection.signal_procs?[bush]
	TEST_ASSERT(hooked && hooked[COMSIG_PARENT_QDELETING], "The reflection component must hook COMSIG_PARENT_QDELETING on every movable it tracks, or deleting one leaves a dangling ref behind.")

/// A tracked movable that dies without an Exited must still leave the mirror's tracking list.
/datum/unit_test/reflection_drops_silently_deleted_movables
#ifdef FOCUS_REFLECTION_TRACKING
	focus = TRUE
#endif

/datum/unit_test/reflection_drops_silently_deleted_movables/Run()
	var/turf/floor = run_loc_floor_bottom_left
	TEST_ASSERT_NOTNULL(floor, "Test setup needs a run turf.")

	var/obj/structure/mirror/mirror = allocate(/obj/structure/mirror, floor)
	var/datum/component/reflection/reflection = mirror.GetComponent(/datum/component/reflection)
	TEST_ASSERT_NOTNULL(reflection, "Test setup needs a mirror carrying a reflection component.")

	var/obj/structure/flora/grass/bush/bush = allocate(/obj/structure/flora/grass/bush, floor)
	var/list/tracked = reflection.vars["reflected_movables"]
	TEST_ASSERT(tracked && (bush in tracked), "The mirror must track a movable spawned next to it.")

	// Nullspace first, so the turf's Exited fires while the mirror is not looking - this is how lighting objects vanish.
	bush.moveToNullspace()
	qdel(bush)

	tracked = reflection.vars["reflected_movables"]
	TEST_ASSERT(!tracked || !(bush in tracked), "The mirror kept a reference to a deleted movable, which turns into a hard delete.")
