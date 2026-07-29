/// Deploying must carry identity and every colour var onto the structure.
/datum/unit_test/camp_shelter_deploy_preserves_state

/datum/unit_test/camp_shelter_deploy_preserves_state/Run()
	var/obj/item/camp_shelter/pavilion/folded = allocate(/obj/item/camp_shelter/pavilion, run_loc_floor_bottom_left)
	folded.color_base_primary = "#112233"
	folded.color_base_secondary = "#445566"
	folded.color_flag_primary = "#778899"
	folded.color_flag_secondary = "#aabbcc"
	var/expected_id = folded.shelter_id
	TEST_ASSERT_NOTNULL(expected_id, "A folded shelter should generate a shelter_id on Initialize.")

	var/obj/structure/camp_shelter/deployed = allocate(/obj/structure/camp_shelter/pavilion, run_loc_floor_bottom_left, folded)
	TEST_ASSERT_EQUAL(deployed.shelter_id, expected_id, "Deploying should carry the shelter_id onto the structure.")
	TEST_ASSERT_EQUAL(deployed.color_base_primary, "#112233", "Deploying should carry the primary structure colour.")
	TEST_ASSERT_EQUAL(deployed.color_base_secondary, "#445566", "Deploying should carry the secondary structure colour.")
	TEST_ASSERT_EQUAL(deployed.color_flag_primary, "#778899", "Deploying should carry the primary flag colour.")
	TEST_ASSERT_EQUAL(deployed.color_flag_secondary, "#aabbcc", "Deploying should carry the secondary flag colour.")

/// Folding must carry identity and colours back, and keep the same pocket instance key.
/datum/unit_test/camp_shelter_fold_preserves_state

/datum/unit_test/camp_shelter_fold_preserves_state/Run()
	var/obj/item/camp_shelter/yurt/folded = allocate(/obj/item/camp_shelter/yurt, run_loc_floor_bottom_left)
	folded.color_base_primary = "#ff0000"
	folded.color_base_secondary = "#00ff00"
	var/expected_id = folded.shelter_id
	var/expected_key = folded.get_pocket_instance_key()

	var/obj/structure/camp_shelter/deployed = allocate(/obj/structure/camp_shelter/yurt, run_loc_floor_bottom_left, folded)
	TEST_ASSERT_EQUAL(deployed.get_pocket_instance_key(), expected_key, "A deployed shelter should resolve the same pocket key as its folded form.")

	var/obj/item/camp_shelter/refolded = allocate(/obj/item/camp_shelter/yurt, run_loc_floor_bottom_left, deployed)
	TEST_ASSERT_EQUAL(refolded.shelter_id, expected_id, "Folding should carry the shelter_id back onto the item.")
	TEST_ASSERT_EQUAL(refolded.color_base_primary, "#ff0000", "Folding should carry the primary structure colour back.")
	TEST_ASSERT_EQUAL(refolded.color_base_secondary, "#00ff00", "Folding should carry the secondary structure colour back.")
	TEST_ASSERT_EQUAL(refolded.get_pocket_instance_key(), expected_key, "A refolded shelter should resolve the same pocket key.")

/// Deploy must refuse a footprint containing a dense object.
/datum/unit_test/camp_shelter_deploy_rejects_blocked_footprint

/datum/unit_test/camp_shelter_deploy_rejects_blocked_footprint/Run()
	var/obj/item/camp_shelter/tent/folded = allocate(/obj/item/camp_shelter/tent, run_loc_floor_bottom_left)
	var/turf/anchor = run_loc_floor_bottom_left

	TEST_ASSERT(folded.footprint_is_clear(anchor), "A clear 2x2 should pass the footprint check.")

	var/turf/blocked = locate(anchor.x + 1, anchor.y, anchor.z)
	TEST_ASSERT_NOTNULL(blocked, "The test zone should have a turf east of the bottom-left corner.")
	allocate(/obj/structure/table/wood, blocked)

	TEST_ASSERT(!folded.footprint_is_clear(anchor), "A dense object anywhere in the 2x2 should fail the footprint check.")
	TEST_ASSERT_NOTNULL(folded.get_footprint_blocker(anchor), "A failed footprint check should name the blocking turf.")

/// Folding is refused while anyone is inside, and the shelter survives the refusal.
/datum/unit_test/camp_shelter_fold_blocked_by_occupant

/datum/unit_test/camp_shelter_fold_blocked_by_occupant/Run()
	var/obj/structure/camp_shelter/tent/pitched = allocate(/obj/structure/camp_shelter/tent, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/camper = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)

	var/datum/component/pocket_access/access = pitched.GetComponent(/datum/component/pocket_access)
	TEST_ASSERT_NOTNULL(access, "A pitched shelter should carry a pocket_access component.")
	TEST_ASSERT(access.enter_user(camper), "The shelter should let a mob inside.")

	var/datum/pocket_dimension/instance = pitched.get_pocket_instance()
	TEST_ASSERT_NOTNULL(instance, "Entering should have created the pocket instance.")
	TEST_ASSERT(instance.contains_turf(get_turf(camper)), "The camper should be inside the pocket.")

	TEST_ASSERT(!pitched.can_fold(), "Folding should be refused while a mob is inside.")

	TEST_ASSERT(access.leave_user(camper), "The shelter should let the mob back out.")
	TEST_ASSERT(pitched.can_fold(), "Folding should be allowed once the pocket is empty.")

/// A foreign item left inside survives a fold and comes back on the next pitch.
/datum/unit_test/camp_shelter_foreign_item_survives_round_trip

/datum/unit_test/camp_shelter_foreign_item_survives_round_trip/Run()
	var/obj/structure/camp_shelter/tent/pitched = allocate(/obj/structure/camp_shelter/tent, run_loc_floor_bottom_left)
	var/datum/component/pocket_access/access = pitched.GetComponent(/datum/component/pocket_access)
	var/obj/item/natural/cloth/stashed = allocate(/obj/item/natural/cloth, run_loc_floor_bottom_left)

	TEST_ASSERT(access.store_movable_for_user(null, stashed, run_loc_floor_bottom_left), "The shelter should accept a foreign item.")
	var/datum/pocket_dimension/instance = pitched.get_pocket_instance()
	TEST_ASSERT_NOTNULL(instance, "Storing an item should have created the pocket instance.")
	TEST_ASSERT(instance.contains_turf(get_turf(stashed)), "The stashed item should be inside the pocket.")

	var/obj/item/camp_shelter/folded = pitched.fold_into_item()
	TEST_ASSERT_NOTNULL(folded, "Folding an empty shelter should produce a folded kit.")
	TEST_ASSERT(instance.is_hibernating(), "Folding should hibernate the pocket rather than delete it.")
	TEST_ASSERT(!QDELETED(stashed), "A hibernating pocket should keep the foreign item alive.")

	var/obj/structure/camp_shelter/repitched = new folded.deployed_type(run_loc_floor_bottom_left, folded)
	folded.transferring = TRUE
	qdel(folded)
	var/datum/component/pocket_access/reaccess = repitched.GetComponent(/datum/component/pocket_access)
	var/mob/living/carbon/human/camper = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	TEST_ASSERT(reaccess.enter_user(camper), "The repitched shelter should reopen its pocket.")
	TEST_ASSERT(instance.contains_turf(get_turf(stashed)), "The stashed item should return when the pocket wakes.")
	TEST_ASSERT(reaccess.leave_user(camper), "The camper should be able to leave again.")

	qdel(repitched)

/// Native furniture from the map template survives a fold and deploy.
/datum/unit_test/camp_shelter_native_furniture_survives_round_trip

/// affected_turfs is an assoc list keyed by turf, so scan each turf's contents rather
/// than relying on how the list itself is keyed.
/datum/unit_test/camp_shelter_native_furniture_survives_round_trip/proc/pocket_has_chest(datum/pocket_dimension/instance)
	for(var/turf/interior_turf as anything in instance.affected_turfs)
		if(locate(/obj/structure/closet/crate/chest) in interior_turf)
			return TRUE
	return FALSE

/datum/unit_test/camp_shelter_native_furniture_survives_round_trip/Run()
	var/obj/structure/camp_shelter/yurt/pitched = allocate(/obj/structure/camp_shelter/yurt, run_loc_floor_bottom_left)
	var/datum/component/pocket_access/access = pitched.GetComponent(/datum/component/pocket_access)
	var/mob/living/carbon/human/camper = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)

	TEST_ASSERT(access.enter_user(camper), "The yurt should let a mob inside.")
	var/datum/pocket_dimension/instance = pitched.get_pocket_instance()
	TEST_ASSERT_NOTNULL(instance, "Entering should have created the pocket instance.")
	TEST_ASSERT(pocket_has_chest(instance), "The yurt template should place a chest inside.")
	TEST_ASSERT(access.leave_user(camper), "The camper should be able to leave.")

	var/obj/item/camp_shelter/folded = pitched.fold_into_item()
	TEST_ASSERT_NOTNULL(folded, "Folding an empty yurt should produce a folded kit.")

	var/obj/structure/camp_shelter/repitched = new folded.deployed_type(run_loc_floor_bottom_left, folded)
	folded.transferring = TRUE
	qdel(folded)
	var/datum/component/pocket_access/reaccess = repitched.GetComponent(/datum/component/pocket_access)
	TEST_ASSERT(reaccess.enter_user(camper), "The repitched yurt should reopen its pocket.")
	TEST_ASSERT(pocket_has_chest(instance), "Native furniture should survive the round trip.")
	TEST_ASSERT(reaccess.leave_user(camper), "The camper should be able to leave the repitched yurt.")

	qdel(repitched)

/// Destroying a pitched shelter dumps its occupants onto the wreck's turf.
/datum/unit_test/camp_shelter_destroy_ejects_occupants

/datum/unit_test/camp_shelter_destroy_ejects_occupants/Run()
	var/turf/anchor = run_loc_floor_bottom_left
	var/obj/structure/camp_shelter/tent/pitched = allocate(/obj/structure/camp_shelter/tent, anchor)
	var/mob/living/carbon/human/camper = allocate(/mob/living/carbon/human, anchor)
	var/datum/component/pocket_access/access = pitched.GetComponent(/datum/component/pocket_access)

	TEST_ASSERT(access.enter_user(camper), "The shelter should let a mob inside.")
	var/datum/pocket_dimension/instance = pitched.get_pocket_instance()
	TEST_ASSERT(instance.contains_turf(get_turf(camper)), "The camper should be inside the pocket.")
	var/instance_key = pitched.get_pocket_instance_key()

	qdel(pitched)

	TEST_ASSERT_EQUAL(get_turf(camper), anchor, "Destroying the shelter should dump the camper onto its turf.")
	TEST_ASSERT_NULL(SSpocket_dimensions.get_instance(instance_key), "Destroying the shelter should collapse its pocket.")

/// Destroying a folded kit dumps the foreign items hibernating inside it.
/datum/unit_test/camp_shelter_destroy_folded_ejects_foreign_items

/datum/unit_test/camp_shelter_destroy_folded_ejects_foreign_items/Run()
	var/turf/anchor = run_loc_floor_bottom_left
	var/obj/structure/camp_shelter/tent/pitched = allocate(/obj/structure/camp_shelter/tent, anchor)
	var/datum/component/pocket_access/access = pitched.GetComponent(/datum/component/pocket_access)
	var/obj/item/natural/cloth/stashed = allocate(/obj/item/natural/cloth, anchor)

	TEST_ASSERT(access.store_movable_for_user(null, stashed, anchor), "The shelter should accept a foreign item.")
	var/instance_key = pitched.get_pocket_instance_key()

	var/obj/item/camp_shelter/folded = pitched.fold_into_item()
	TEST_ASSERT_NOTNULL(folded, "Folding should produce a kit.")
	TEST_ASSERT_NOTNULL(SSpocket_dimensions.get_instance(instance_key), "Folding should keep the pocket registered.")

	var/turf/wreck_turf = run_loc_floor_top_right
	folded.forceMove(wreck_turf)
	qdel(folded)

	TEST_ASSERT_EQUAL(get_turf(stashed), wreck_turf, "Destroying the kit should dump its foreign items where the kit was.")
	TEST_ASSERT_NULL(SSpocket_dimensions.get_instance(instance_key), "Destroying the kit should collapse its pocket.")

/// A shelter anchored outside the footprint still overlaps it, so deploy must refuse.
/datum/unit_test/camp_shelter_deploy_rejects_overlapping_shelter

/datum/unit_test/camp_shelter_deploy_rejects_overlapping_shelter/Run()
	var/turf/anchor = run_loc_floor_bottom_left
	var/obj/item/camp_shelter/tent/folded = allocate(/obj/item/camp_shelter/tent, anchor)

	// Anchor a shelter one tile diagonally away. Its own turf is outside the kit's
	// footprint, but their 2x2 areas share a corner turf.
	var/turf/neighbour_anchor = locate(anchor.x + 1, anchor.y + 1, anchor.z)
	TEST_ASSERT_NOTNULL(neighbour_anchor, "The test zone should have a turf north-east of the bottom-left corner.")
	var/obj/structure/camp_shelter/tent/neighbour = allocate(/obj/structure/camp_shelter/tent, neighbour_anchor)
	TEST_ASSERT_EQUAL(get_turf(neighbour), neighbour_anchor, "The neighbouring shelter should sit on its own anchor turf.")

	TEST_ASSERT(!folded.footprint_is_clear(anchor), "A shelter overlapping the footprint from outside it should block deployment.")

/// Entering must take enter_time rather than teleporting the user on contact.
/datum/unit_test/camp_shelter_entry_is_delayed

/datum/unit_test/camp_shelter_entry_is_delayed/Run()
	var/turf/anchor = run_loc_floor_bottom_left
	var/obj/structure/camp_shelter/tent/pitched = allocate(/obj/structure/camp_shelter/tent, anchor)
	var/mob/living/carbon/human/camper = allocate(/mob/living/carbon/human, anchor)

	pitched.attack_hand(camper)
	TEST_ASSERT_EQUAL(get_turf(camper), anchor, "Touching the shelter should not move the camper straight away.")

	sleep(pitched.enter_time * 3)

	var/datum/pocket_dimension/instance = pitched.get_pocket_instance()
	TEST_ASSERT_NOTNULL(instance, "The delayed entry should have opened the pocket.")
	TEST_ASSERT(instance.contains_turf(get_turf(camper)), "The camper should be inside once the delay elapses.")

	var/datum/component/pocket_access/access = pitched.GetComponent(/datum/component/pocket_access)
	TEST_ASSERT(access.leave_user(camper), "The camper should be able to leave afterwards.")

/// Leaving must take exit_time rather than teleporting the user out on contact.
/datum/unit_test/camp_shelter_exit_is_delayed

/datum/unit_test/camp_shelter_exit_is_delayed/Run()
	var/turf/anchor = run_loc_floor_bottom_left
	var/obj/structure/camp_shelter/tent/pitched = allocate(/obj/structure/camp_shelter/tent, anchor)
	var/mob/living/carbon/human/camper = allocate(/mob/living/carbon/human, anchor)
	var/datum/component/pocket_access/access = pitched.GetComponent(/datum/component/pocket_access)

	TEST_ASSERT(access.enter_user(camper), "The shelter should let a mob inside.")
	var/datum/pocket_dimension/instance = pitched.get_pocket_instance()
	TEST_ASSERT_NOTNULL(instance, "Entering should have created the pocket instance.")
	TEST_ASSERT(instance.contains_turf(get_turf(camper)), "The camper should start inside.")

	var/obj/structure/pocket_dimension_exit/camp_shelter/flap = locate(/obj/structure/pocket_dimension_exit/camp_shelter) in instance.exit_objects
	TEST_ASSERT_NOTNULL(flap, "The tent template should place a camp shelter flap inside.")

	// Stand on the flap so the adjacency recheck cannot depend on the interior layout.
	camper.forceMove(get_turf(flap))
	flap.use_exit(camper)
	TEST_ASSERT(instance.contains_turf(get_turf(camper)), "Touching the flap should not move the camper straight away.")

	sleep(flap.exit_time * 3)

	TEST_ASSERT(!instance.contains_turf(get_turf(camper)), "The camper should be outside once the delay elapses.")
	TEST_ASSERT_EQUAL(get_turf(camper), anchor, "Leaving should put the camper back at the shelter.")
