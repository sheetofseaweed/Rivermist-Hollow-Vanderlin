/datum/unit_test/dungeon_onebite/Run()
	var/mob/living/carbon/human/raider = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/turf/origin = run_loc_floor_bottom_left

	var/datum/pocket_dimension/dungeon/instance = SSpocket_dimensions.get_or_create_instance("[REF(src)]::onebite", /datum/map_template/pocket/dungeon/test_onebite, POCKET_LIFECYCLE_COLLAPSE, 0)
	TEST_ASSERT_NOTNULL(instance, "One-bite dungeon instance should be created.")
	TEST_ASSERT(istype(instance, /datum/pocket_dimension/dungeon), "Instance should use the dungeon subtype via instance_type.")
	TEST_ASSERT(!instance.cleared, "Dungeon with a guardian should not start cleared.")
	TEST_ASSERT_EQUAL(length(instance.guardian_refs), 1, "Guardian landmark should have produced exactly one tracked guardian.")
	TEST_ASSERT_EQUAL(length(instance.loot_caches), 1, "Loot landmark should have produced exactly one cache.")

	var/obj/structure/dungeon_loot_cache/cache = instance.loot_caches[1]
	TEST_ASSERT(cache.locked, "Reward cache should start sealed.")

	TEST_ASSERT(instance.enter_mob(raider, origin), "Dungeon should accept a mob entry.")
	TEST_ASSERT(instance.contains_turf(get_turf(raider)), "Raider should be inside the dungeon.")

	var/mob/living/guardian
	for(var/guardian_ref in instance.guardian_refs)
		var/datum/weakref/ref = instance.guardian_refs[guardian_ref]
		guardian = ref.resolve()
	TEST_ASSERT_NOTNULL(guardian, "Tracked guardian weakref should resolve.")

	guardian.death()
	TEST_ASSERT(instance.cleared, "Dungeon should clear when its last guardian dies.")
	TEST_ASSERT(!cache.locked, "Reward cache should unlock on clear.")

	TEST_ASSERT(SSpocket_dimensions.delete_instance(instance, null, origin), "Dungeon should collapse on demand.")
	TEST_ASSERT_EQUAL(get_turf(raider), origin, "Raider should be ejected to the entrance on collapse.")
	TEST_ASSERT(QDELETED(guardian), "Dead native guardian must be deleted on collapse, not ejected.")

/datum/unit_test/dungeon_native_mobs_die_on_collapse/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/pocket_dimension/dungeon/instance = SSpocket_dimensions.get_or_create_instance("[REF(src)]::collapse", /datum/map_template/pocket/dungeon/test_onebite, POCKET_LIFECYCLE_COLLAPSE, 0)
	TEST_ASSERT_NOTNULL(instance, "Collapse-test dungeon instance should be created.")

	var/mob/living/guardian
	for(var/guardian_ref in instance.guardian_refs)
		var/datum/weakref/ref = instance.guardian_refs[guardian_ref]
		guardian = ref.resolve()
	TEST_ASSERT_NOTNULL(guardian, "Guardian should exist before collapse.")

	// Collapse with the guardian still alive - it must be deleted, never ejected.
	TEST_ASSERT(SSpocket_dimensions.delete_instance(instance, null, origin), "Dungeon should collapse with a live guardian inside.")
	TEST_ASSERT(QDELETED(guardian), "Live native guardian must be deleted on collapse, not ejected.")

/datum/unit_test/dungeon_infinite_run/Run()
	var/obj/structure/dungeon_entrance/infinite/entrance = allocate(/obj/structure/dungeon_entrance/infinite, run_loc_floor_bottom_left)
	entrance.theme_filter = DUNGEON_THEME_TEST
	var/mob/living/carbon/human/delver = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	delver.mind_initialize() // gates refuse mindless mobs (dungeon natives), so the test delver needs a mind

	TEST_ASSERT(entrance.try_enter(delver), "Infinite entrance should accept a delver.")
	var/datum/dungeon_run/run = entrance.active_run
	TEST_ASSERT_NOTNULL(run, "Entering an infinite entrance should create a run.")
	run.stretch_length = 1 // shorten the stretch so the test reaches a second break room fast

	var/datum/pocket_dimension/dungeon/first_break = run.current_break_room
	TEST_ASSERT_NOTNULL(first_break, "Run should have a starting break room.")
	TEST_ASSERT(first_break.cleared, "A guardian-less break room should be auto-cleared.")
	TEST_ASSERT(first_break.contains_turf(get_turf(delver)), "Delver should be inside the break room.")

	var/obj/structure/dungeon_gate/forward_gate
	for(var/obj/structure/dungeon_gate/gate as anything in first_break.gates)
		if(gate.gate_role == DUNGEON_GATE_FORWARD)
			forward_gate = gate
			break
	TEST_ASSERT_NOTNULL(forward_gate, "Break room should have a forward gate.")
	TEST_ASSERT(!forward_gate.sealed, "Forward gates in a cleared room should be open.")

	// stretch_length was shortened after the break room's gates pre-rolled their
	// templates against the default length, so re-roll them for the test.
	forward_gate.pre_rolled_template = run.roll_next_room_template(first_break)
	TEST_ASSERT_NOTNULL(forward_gate.pre_rolled_template, "Forward gate should have a pre-rolled template.")

	// Drag-through: bring a foreign object along.
	var/obj/item/storage/backpack/cargo = allocate(/obj/item/storage/backpack, get_turf(delver))
	delver.start_pulling(cargo)
	TEST_ASSERT_EQUAL(delver.pulling, cargo, "Delver should be pulling the cargo before the gate.")
	TEST_ASSERT(forward_gate.use_gate(delver), "Open forward gate should transfer the delver.")

	var/datum/pocket_dimension/dungeon/combat_room = forward_gate.destination_room
	TEST_ASSERT_NOTNULL(combat_room, "Forward gate should have instantiated its room.")
	TEST_ASSERT(combat_room.contains_turf(get_turf(delver)), "Delver should be in the combat room.")
	TEST_ASSERT(combat_room.contains_turf(get_turf(cargo)), "Dragged cargo should cross the gate with the delver.")
	TEST_ASSERT_EQUAL(combat_room.depth, 1, "First combat room should be depth 1.")
	TEST_ASSERT(!combat_room.cleared, "Combat room with a guardian should not start cleared.")

	var/mob/living/guardian
	for(var/guardian_ref in combat_room.guardian_refs)
		var/datum/weakref/ref = combat_room.guardian_refs[guardian_ref]
		guardian = ref.resolve()
	TEST_ASSERT_NOTNULL(guardian, "Combat room guardian should resolve.")
	// enhance_mob feeds the affix system depth-1 (matching SSdungeon_generator),
	// so assert on its observable effects rather than the stored delve_level.
	TEST_ASSERT(length(guardian.affixes) >= 1, "Guardian should receive at least one affix from depth enhancement.")
	TEST_ASSERT(guardian.maxHealth > initial(guardian.maxHealth), "Guardian max health should be scaled up by depth enhancement.")

	var/obj/structure/dungeon_gate/next_gate
	for(var/obj/structure/dungeon_gate/gate as anything in combat_room.gates)
		if(gate.gate_role == DUNGEON_GATE_FORWARD)
			next_gate = gate
			break
	TEST_ASSERT_NOTNULL(next_gate, "Combat room should have a forward gate.")
	TEST_ASSERT(next_gate.sealed, "Forward gates should be sealed while guardians live.")
	TEST_ASSERT(!next_gate.use_gate(delver), "Sealed gate should refuse passage.")

	guardian.death()
	TEST_ASSERT(combat_room.cleared, "Combat room should clear when its guardian dies.")
	TEST_ASSERT(!next_gate.sealed, "Forward gates should unseal on clear.")
	TEST_ASSERT_EQUAL(run.depth, 1, "Run depth should increment per cleared combat room.")
	TEST_ASSERT_NOTNULL(next_gate.pre_rolled_template, "Cleared combat room's forward gate should have a template.")
	TEST_ASSERT_EQUAL(next_gate.pre_rolled_template.room_kind, DUNGEON_ROOM_BREAK, "With stretch_length 1, the next room should be a break room.")

	TEST_ASSERT(next_gate.use_gate(delver), "Cleared forward gate should transfer the delver onward.")
	var/datum/pocket_dimension/dungeon/second_break = run.current_break_room
	TEST_ASSERT(second_break != first_break, "Reaching a new break room should advance the run.")
	TEST_ASSERT(second_break.contains_turf(get_turf(delver)), "Delver should be in the new break room.")
	TEST_ASSERT(QDELETED(first_break), "The old break room should despawn behind the party.")
	TEST_ASSERT(QDELETED(combat_room), "Cleared stretch rooms should despawn behind the party.")

	// The test mob has no client, so exercise run teardown directly.
	qdel(run)
	TEST_ASSERT_NULL(entrance.active_run, "Ending the run should clear the entrance's active run.")
	TEST_ASSERT(entrance.is_dormant(), "Entrance should go dormant after its run ends.")
	TEST_ASSERT(QDELETED(second_break), "Run teardown should delete remaining rooms.")
	TEST_ASSERT_EQUAL(get_turf(delver), get_turf(entrance), "Run teardown should eject the delver to the entrance.")
