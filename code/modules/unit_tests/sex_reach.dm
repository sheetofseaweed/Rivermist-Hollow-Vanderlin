/// Hiding under a table puts you inside it rather than on a turf; sex reach has to survive that.
/datum/unit_test/sex_reach_under_table/Run()
	var/turf/next_tile = get_step(run_loc_floor_bottom_left, EAST)
	var/turf/far_tile = get_step(next_tile, EAST)
	TEST_ASSERT_NOTNULL(next_tile, "Test map should have a tile east of the run loc.")
	TEST_ASSERT_NOTNULL(far_tile, "Test map should have a second tile east of the run loc.")

	var/mob/living/carbon/human/hider = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human, next_tile)
	var/obj/structure/table/table = allocate(/obj/structure/table)

	TEST_ASSERT(hider.adjacent_or_closet(partner), "Mobs on adjacent tiles should reach each other.")

	hider.forceMove(table)
	TEST_ASSERT_EQUAL(hider.loc, table, "Setup should have put the hider inside the table.")

	TEST_ASSERT(hider.adjacent_or_closet(partner), "A mob under a table could not reach a partner on the next tile.")
	TEST_ASSERT(partner.adjacent_or_closet(hider), "A partner could not reach a mob hiding under the adjacent table.")

	partner.forceMove(far_tile)
	TEST_ASSERT(!hider.adjacent_or_closet(partner), "Hiding under a table should not extend reach past one tile.")
	TEST_ASSERT(!partner.adjacent_or_closet(hider), "A mob under a table should not be reachable from two tiles away.")

/// Two mobs inside the same thing count as sharing a tile; two on the same turf do not.
/datum/unit_test/sex_reach_shared_container/Run()
	var/mob/living/carbon/human/first = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/second = allocate(/mob/living/carbon/human)
	var/obj/structure/closet/closet = allocate(/obj/structure/closet)

	TEST_ASSERT(!first.check_closet(second), "Mobs standing on a turf are not inside a shared container.")

	first.forceMove(closet)
	TEST_ASSERT(!first.check_closet(second), "Only one of the pair is inside the closet.")

	second.forceMove(closet)
	TEST_ASSERT(first.check_closet(second), "Both mobs are inside the same closet.")
	TEST_ASSERT(first.adjacent_or_closet(second), "Mobs inside the same closet should reach each other.")

/// The only thing on screen to drag while you are inside something is the container itself.
/datum/unit_test/sex_reach_drag_container_counts_as_self/Run()
	var/turf/next_tile = get_step(run_loc_floor_bottom_left, EAST)
	TEST_ASSERT_NOTNULL(next_tile, "Test map should have a tile east of the run loc.")

	var/mob/living/carbon/human/hider = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human, next_tile)
	var/obj/structure/table/table = allocate(/obj/structure/table)

	hider.forceMove(table)
	partner.MiddleMouseDrop_T(table, hider)

	var/datum/sex_scene/scene = hider.sex_scene
	TEST_ASSERT_NOTNULL(scene, "Dragging the table you are hiding under should open a session.")
	TEST_ASSERT_EQUAL(scene, partner.sex_scene, "The session should bind both participants to one scene.")

	qdel(scene)
