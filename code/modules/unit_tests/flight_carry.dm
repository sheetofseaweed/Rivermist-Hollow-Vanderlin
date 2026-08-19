/// A mob carried by an airborne mob must not drop out of their arms.
/datum/unit_test/flight_carried_rider_does_not_zfall/Run()
	var/mob/living/carbon/human/carrier = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/rider = allocate(/mob/living/carbon/human)
	var/turf/landing = get_step(run_loc_floor_bottom_left, EAST)
	TEST_ASSERT_NOTNULL(landing, "Test map should have an adjacent turf to fall onto.")

	TEST_ASSERT(carrier.buckle_mob(rider, TRUE, TRUE, 90, 0, 0), "Carrier could not fireman-carry the rider.")
	TEST_ASSERT(rider.can_zFall(get_turf(rider), 1, landing, DOWN), "A rider carried by a grounded mob should still be able to fall.")

	ADD_TRAIT(carrier, TRAIT_MOVE_FLYING, ORGAN_TRAIT)
	TEST_ASSERT(!rider.can_zFall(get_turf(rider), 1, landing, DOWN), "A rider carried by a flying mob fell out of their arms.")

/// Grouped z-movement must carry a buckled passenger while keeping the pull and grab intact.
/datum/unit_test/flight_takeoff_carries_passenger/Run()
	var/mob/living/carbon/human/carrier = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/rider = allocate(/mob/living/carbon/human)
	var/obj/item/organ/wings/flight/wings = allocate(/obj/item/organ/wings/flight)
	var/turf/destination = get_step(run_loc_floor_bottom_left, EAST)
	TEST_ASSERT_NOTNULL(destination, "Test map should have an adjacent destination turf.")

	var/datum/action/item_action/organ_action/use/flight/fly = new(wings)
	wings.fly = fly
	fly.Grant(carrier)

	TEST_ASSERT(carrier.start_pulling(rider, suppress_message = TRUE), "Carrier could not pull the rider.")
	TEST_ASSERT(carrier.buckle_mob(rider, TRUE, TRUE, 90, 0, 0), "Carrier could not fireman-carry the rider.")

	fly.release_dragged()
	TEST_ASSERT_EQUAL(carrier.pulling, rider, "Taking off let go of a rider that was being carried, not just dragged.")

	carrier.zMove(UP, destination, ZMOVE_FLIGHT_FLAGS)

	TEST_ASSERT_EQUAL(get_turf(rider), destination, "The carried rider was left behind when the carrier changed loc.")
	TEST_ASSERT_EQUAL(rider.buckled, carrier, "The carried rider was unbuckled by the move.")
	TEST_ASSERT_EQUAL(carrier.pulling, rider, "The carrier lost its pull on the rider during the move.")
	TEST_ASSERT_EQUAL(rider.pulledby, carrier, "The rider's pulledby was not restored after the move.")

/// Someone who is only being dragged has to be let go of on takeoff, not towed a z-level below.
/datum/unit_test/flight_takeoff_releases_dragged/Run()
	var/mob/living/carbon/human/carrier = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/dragged = allocate(/mob/living/carbon/human)
	var/obj/item/organ/wings/flight/wings = allocate(/obj/item/organ/wings/flight)

	var/datum/action/item_action/organ_action/use/flight/fly = new(wings)
	wings.fly = fly
	fly.Grant(carrier)

	TEST_ASSERT(carrier.start_pulling(dragged, suppress_message = TRUE), "Carrier could not pull the dragged mob.")

	fly.release_dragged()
	TEST_ASSERT_NULL(carrier.pulling, "Taking off did not release a mob that was only being dragged.")
	TEST_ASSERT_NULL(dragged.pulledby, "The dragged mob still thinks it is being pulled after takeoff.")
