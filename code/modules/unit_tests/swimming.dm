/turf/open/water/swimming_unit_test
	mapped = TRUE
	fake_bottomless = TRUE
	skip_bottom_check = TRUE

/turf/open/water/swimming_unit_test/full
	water_height = WATER_HEIGHT_FULL

/turf/open/water/swimming_unit_test/deep
	water_height = WATER_HEIGHT_DEEP

/datum/unit_test/swimming_state_lifecycle
	var/turf/original_start
	var/turf/original_destination
	var/original_start_type
	var/original_destination_type
	var/list/original_start_baseturfs
	var/list/original_destination_baseturfs

/datum/unit_test/swimming_state_lifecycle/Destroy()
	if(original_start && original_start_type)
		original_start.ChangeTurf(original_start_type, original_start_baseturfs)
	if(original_destination && original_destination_type)
		original_destination.ChangeTurf(original_destination_type, original_destination_baseturfs)
	return ..()

/datum/unit_test/swimming_state_lifecycle/Run()
	original_start = get_step(run_loc_floor_bottom_left, EAST)
	original_destination = get_step(original_start, EAST)
	var/turf/dry_destination = get_step(original_destination, EAST)
	TEST_ASSERT_NOTNULL(original_start, "Test map should provide a start turf.")
	TEST_ASSERT_NOTNULL(original_destination, "Test map should provide a destination turf.")
	TEST_ASSERT_NOTNULL(dry_destination, "Test map should provide a dry exit turf.")

	original_start_type = original_start.type
	original_destination_type = original_destination.type
	original_start_baseturfs = original_start.baseturfs
	original_destination_baseturfs = original_destination.baseturfs

	var/turf/open/water/swimming_unit_test/full/start_water = original_start.ChangeTurf(/turf/open/water/swimming_unit_test/full)
	var/turf/open/water/swimming_unit_test/deep/destination_water = original_destination.ChangeTurf(/turf/open/water/swimming_unit_test/deep)
	start_water.water_elements_initialized = TRUE
	destination_water.water_elements_initialized = TRUE
	start_water.sync_water_elements()
	destination_water.sync_water_elements()

	var/mob/living/carbon/human/swimmer = allocate(/mob/living/carbon/human, dry_destination)
	swimmer.forceMove(start_water)
	TEST_ASSERT(HAS_TRAIT(swimmer, TRAIT_IMMERSED), "Entering active water did not apply immersion.")
	TEST_ASSERT(HAS_TRAIT(swimmer, TRAIT_MOVE_SWIMMING), "Deep water did not grant swimming movement.")
	var/datum/status_effect/swimming/swimming_status = swimmer.has_status_effect(/datum/status_effect/swimming)
	TEST_ASSERT_NOTNULL(swimming_status, "Entering swimmable water did not apply the swimming status.")
	TEST_ASSERT(swimming_status.block_breathing, "Full water did not configure the status as fully submerged.")

	swimmer.encumbrance = ENCUMBRANCE_MEDIUM
	swimming_status.update_sinking_state()
	TEST_ASSERT(HAS_TRAIT(swimmer, TRAIT_SINKING), "The local medium-encumbrance sinking threshold was not preserved.")
	swimmer.encumbrance = ENCUMBRANCE_NONE
	swimming_status.update_sinking_state()
	TEST_ASSERT(!HAS_TRAIT(swimmer, TRAIT_SINKING), "Sinking was not removed after encumbrance dropped.")

	TEST_ASSERT_EQUAL(swimmer.can_z_move(DOWN, start_water, destination_water, ZMOVE_SWIM_FLAGS), destination_water, "Connected water rejected swimming z-movement.")
	TEST_ASSERT(swimmer.zMove(DOWN, destination_water, ZMOVE_SWIM_FLAGS), "Swimming z-movement failed after validation.")
	TEST_ASSERT_EQUAL(get_turf(swimmer), destination_water, "Swimming movement did not reach its destination.")
	TEST_ASSERT_EQUAL(swimmer.has_status_effect(/datum/status_effect/swimming), swimming_status, "Crossing connected water recreated the swimming state.")
	TEST_ASSERT(!swimming_status.block_breathing, "Crossing into surface-level deep water did not refresh drowning configuration.")

	destination_water.water_volume = 0
	destination_water.handle_water()
	TEST_ASSERT(!HAS_TRAIT(swimmer, TRAIT_IMMERSED), "Drying water did not clear immersion.")
	TEST_ASSERT_NULL(swimmer.has_status_effect(/datum/status_effect/swimming), "Drying water did not remove the swimming status.")

	destination_water.water_volume = 100
	destination_water.handle_water()
	TEST_ASSERT(HAS_TRAIT(swimmer, TRAIT_IMMERSED), "Refilling water did not restore immersion to an occupant.")
	TEST_ASSERT_NOTNULL(swimmer.has_status_effect(/datum/status_effect/swimming), "Refilling water did not restore the swimming status to an occupant.")

	swimmer.forceMove(dry_destination)
	TEST_ASSERT(!HAS_TRAIT(swimmer, TRAIT_IMMERSED), "Leaving water did not clear immersion.")
	TEST_ASSERT(!HAS_TRAIT(swimmer, TRAIT_MOVE_SWIMMING), "Leaving water did not clear swimming movement.")
	TEST_ASSERT_NULL(swimmer.has_status_effect(/datum/status_effect/swimming), "Leaving water did not remove the swimming status.")
	TEST_ASSERT(!HAS_TRAIT(swimmer, TRAIT_SINKING), "Leaving water did not clear sinking.")
