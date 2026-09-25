/// Turf lists must hold turf paths: place() matches them to the turf type and ChangeTurf()s spawnableTurfs.
/datum/unit_test/map_generator_turf_lists

/datum/unit_test/map_generator_turf_lists/Run()
	for(var/module_type in subtypesof(/datum/mapGeneratorModule))
		var/datum/mapGeneratorModule/module = allocate(module_type)
		for(var/list/turf_list in list(module.allowed_turfs, module.excluded_turfs, module.spawnableTurfs))
			for(var/path in turf_list)
				TEST_ASSERT(ispath(path, /turf), "[module_type] lists [path] as a turf.")

/// The bog grass layers add no turfs, skip the parent's flora table, and seat kneestingers in plain grass.
/datum/unit_test/rmh_bog_grass_layers

/datum/unit_test/rmh_bog_grass_layers/Run()
	var/datum/mapGeneratorModule/rmh_bog/boggrassturf/grass_layer = allocate(/datum/mapGeneratorModule/rmh_bog/boggrassturf)
	var/datum/mapGeneratorModule/rmh_bog/boggrass/stinger_layer = allocate(/datum/mapGeneratorModule/rmh_bog/boggrass)
	TEST_ASSERT_EQUAL(length(grass_layer.spawnableTurfs), 0, "boggrassturf inherited turf spawns.")
	TEST_ASSERT_EQUAL(length(stinger_layer.spawnableTurfs), 0, "boggrass inherited turf spawns.")
	TEST_ASSERT(!(/obj/structure/flora/grass/maneater/real in grass_layer.spawnableAtoms), "boggrassturf re-rolls the parent's flora table.")

	var/turf/bare = run_loc_floor_bottom_left
	var/turf/tufted = get_step(bare, EAST)
	var/turf/weedy = get_step(tufted, EAST)
	var/turf/hungry = get_step(weedy, EAST)
	allocate(/obj/structure/flora/grass, tufted)
	allocate(/obj/structure/flora/grass/swampweed, weedy)
	allocate(/obj/structure/flora/grass, hungry)
	allocate(/obj/structure/flora/grass/maneater/real, hungry)

	TEST_ASSERT(!stinger_layer.checkPlaceAtom(bare), "Kneestingers took a tile without grass.")
	TEST_ASSERT(stinger_layer.checkPlaceAtom(tufted), "Kneestingers refused a plain grass tuft.")
	TEST_ASSERT(!stinger_layer.checkPlaceAtom(weedy), "A grass subtype counted as a plain tuft.")
	TEST_ASSERT(!stinger_layer.checkPlaceAtom(hungry), "Kneestingers took a tile hiding a maneater.")
