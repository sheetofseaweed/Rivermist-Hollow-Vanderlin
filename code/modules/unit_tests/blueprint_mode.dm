/datum/unit_test/stale_blueprint_vision_trait_is_not_active_blueprint_mode
#ifdef FOCUS_BLUEPRINT_MODE_TEST
	focus = TRUE
#endif

/datum/unit_test/stale_blueprint_vision_trait_is_not_active_blueprint_mode/Run()
	var/mob/user = allocate(/mob)

	ADD_TRAIT(user, TRAIT_BLUEPRINT_VISION, TRAIT_GENERIC)

	TEST_ASSERT(!user.has_active_blueprint_mode(), "A stale blueprint vision trait should not count as active blueprint mode.")

	user.exit_blueprint()

	TEST_ASSERT(!HAS_TRAIT(user, TRAIT_BLUEPRINT_VISION), "Exiting blueprint mode should remove stale blueprint vision.")
	TEST_ASSERT_NULL(user.blueprints, "Exiting blueprint mode should clear stale blueprint datum references.")

/// setup_blueprint() is the only place recipe is guaranteed to exist, so it owns both the final
/// appearance and the viewer handout.
/datum/unit_test/blueprint_setup_builds_appearance
#ifdef FOCUS_BLUEPRINT_MODE_TEST
	focus = TRUE
#endif

/datum/unit_test/blueprint_setup_builds_appearance/Run()
	var/obj/structure/blueprint/print = allocate(/obj/structure/blueprint, run_loc_floor_bottom_left)
	var/datum/blueprint_recipe/recipe = allocate(/datum/blueprint_recipe/floor/woodfloor)

	TEST_ASSERT(print in GLOB.active_blueprints, "A placed blueprint should register in active_blueprints.")

	print.recipe = recipe
	print.setup_blueprint()

	TEST_ASSERT_EQUAL(print.name, "[recipe.name] blueprint", "setup_blueprint should name the blueprint after its recipe.")
	var/atom/result = recipe.result_type
	TEST_ASSERT_EQUAL(print.icon, initial(result.icon), "setup_blueprint should adopt the result type's icon.")

/// after_load() was defined twice on this type. DM compiles that silently and keeps only one body,
/// so restored blueprints lost either their registration or their appearance.
/datum/unit_test/blueprint_after_load_restores_blueprint
#ifdef FOCUS_BLUEPRINT_MODE_TEST
	focus = TRUE
#endif

/datum/unit_test/blueprint_after_load_restores_blueprint/Run()
	var/obj/structure/blueprint/print = allocate(/obj/structure/blueprint, run_loc_floor_bottom_left)
	var/datum/blueprint_recipe/recipe = allocate(/datum/blueprint_recipe/floor/woodfloor)

	print.recipe = recipe
	GLOB.active_blueprints -= print

	print.after_load()

	TEST_ASSERT(print in GLOB.active_blueprints, "after_load should re-register the blueprint in active_blueprints.")

	sleep(1.2 SECONDS) // after_load defers setup_blueprint so neighbouring turfs exist first

	TEST_ASSERT_EQUAL(print.name, "[recipe.name] blueprint", "after_load should run setup_blueprint.")

/datum/unit_test/blueprint_placement_checks
#ifdef FOCUS_BLUEPRINT_MODE_TEST
	focus = TRUE
#endif

/datum/unit_test/blueprint_placement_checks/Run()
	var/turf/location = run_loc_floor_bottom_left
	var/datum/blueprint_recipe/floor_recipe = allocate(/datum/blueprint_recipe/floor/woodfloor)
	var/datum/blueprint_recipe/structure_recipe = allocate(/datum/blueprint_recipe/structure/anvil)

	TEST_ASSERT(can_place_blueprint_at(location, floor_recipe), "An empty floor should accept a floor blueprint.")

	// A blueprint whose recipe never got assigned used to runtime the check and wall off the turf.
	var/obj/structure/blueprint/recipeless = allocate(/obj/structure/blueprint, location)

	TEST_ASSERT(can_place_blueprint_at(location, floor_recipe), "A recipe-less blueprint should not block placement.")
	TEST_ASSERT(can_place_blueprint_at(location, structure_recipe), "A recipe-less blueprint should not block a structure blueprint.")

	recipeless.recipe = floor_recipe

	TEST_ASSERT(!can_place_blueprint_at(location, floor_recipe), "Two floor blueprints should not stack on one turf.")
	TEST_ASSERT(can_place_blueprint_at(location, structure_recipe), "A floor blueprint should not block a structure blueprint.")
