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
	// Stretch-end now caps with a boss room (Slice 3); this test exercises the
	// despawn-behind-party mechanic, so force the next room to a plain break room.
	next_gate.pre_rolled_template = SSpocket_dimensions.resolve_template("dungeon_test_break")

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

/datum/unit_test/dungeon_floor_descent/Run()
	var/obj/structure/dungeon_entrance/infinite/entrance = allocate(/obj/structure/dungeon_entrance/infinite, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/delver = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	delver.mind_initialize()

	TEST_ASSERT(entrance.try_enter(delver), "Infinite entrance should accept a delver.")
	var/datum/dungeon_run/run = entrance.active_run
	TEST_ASSERT_NOTNULL(run, "Run should be created.")
	TEST_ASSERT_EQUAL(run.floor, 1, "Run should start on floor 1.")

	var/datum/pocket_dimension/dungeon/first_break = run.current_break_room
	var/obj/structure/dungeon_gate/forward_gate
	for(var/obj/structure/dungeon_gate/gate as anything in first_break.gates)
		if(gate.gate_role == DUNGEON_GATE_FORWARD)
			forward_gate = gate
			break
	TEST_ASSERT_NOTNULL(forward_gate, "Break room should have a forward gate.")

	// Force the next room to be a descent room so we can test the floor advance.
	forward_gate.pre_rolled_template = SSpocket_dimensions.resolve_template("dungeon_test_descent")
	forward_gate.gate_role = DUNGEON_GATE_DESCENT
	forward_gate.sealed = FALSE

	TEST_ASSERT(forward_gate.use_gate(delver), "Descent gate should transfer the delver.")
	TEST_ASSERT_EQUAL(run.floor, 2, "Crossing a descent room should advance to floor 2.")
	TEST_ASSERT(QDELETED(first_break), "The previous floor's break room should despawn on descent.")

	qdel(run)

/datum/unit_test/dungeon_solo_still_works/Run()
	// Guards the foundation behavior: a lone, partyless delver can still run.
	var/obj/structure/dungeon_entrance/infinite/entrance = allocate(/obj/structure/dungeon_entrance/infinite, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/delver = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	delver.mind_initialize()
	TEST_ASSERT(entrance.try_enter(delver), "A partyless delver should still be able to enter.")
	var/datum/dungeon_run/run = entrance.active_run
	TEST_ASSERT_NOTNULL(run, "Solo entry should create a run.")
	TEST_ASSERT_NULL(run.get_party(), "Solo run should have no bound party.")

	var/datum/pocket_dimension/dungeon/break_room = run.current_break_room
	var/obj/structure/dungeon_gate/forward_gate
	for(var/obj/structure/dungeon_gate/gate as anything in break_room.gates)
		if(gate.gate_role == DUNGEON_GATE_FORWARD)
			forward_gate = gate
			break
	forward_gate.pre_rolled_template = SSpocket_dimensions.resolve_template("dungeon_test_combat")
	forward_gate.sealed = FALSE
	TEST_ASSERT(forward_gate.use_gate(delver), "A solo delver should muster trivially and advance.")
	TEST_ASSERT(forward_gate.destination_room.contains_turf(get_turf(delver)), "Solo delver should have moved through.")

	qdel(run)

/datum/unit_test/dungeon_at_rest_state/Run()
	var/obj/structure/dungeon_entrance/infinite/entrance = allocate(/obj/structure/dungeon_entrance/infinite, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/delver = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	delver.mind_initialize()
	TEST_ASSERT(entrance.try_enter(delver), "Delver should enter.")
	var/datum/dungeon_run/run = entrance.active_run
	TEST_ASSERT(run.is_at_rest(), "A run sitting in its starting break room should report at rest.")

	var/obj/structure/dungeon_gate/forward_gate
	for(var/obj/structure/dungeon_gate/gate as anything in run.current_break_room.gates)
		if(gate.gate_role == DUNGEON_GATE_FORWARD)
			forward_gate = gate
			break
	forward_gate.pre_rolled_template = SSpocket_dimensions.resolve_template("dungeon_test_combat")
	forward_gate.sealed = FALSE
	TEST_ASSERT(forward_gate.use_gate(delver), "Advance into the combat stretch.")
	TEST_ASSERT(!run.is_at_rest(), "With a live combat stretch room, the run should not be at rest.")

	qdel(run)

/datum/unit_test/dungeon_present_set/Run()
	var/obj/structure/dungeon_entrance/infinite/entrance = allocate(/obj/structure/dungeon_entrance/infinite, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/delver = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	delver.mind_initialize()
	TEST_ASSERT(entrance.try_enter(delver), "Delver should enter.")
	var/datum/dungeon_run/run = entrance.active_run
	// Clientless test mob has no ckey, so present_ckeys stays empty by design;
	// assert the occupant-based present-member query finds the delver instead.
	var/list/present = run.get_present_members()
	TEST_ASSERT(length(present) >= 1, "The delver should be counted among present members of the run.")

	qdel(run)

/datum/unit_test/dungeon_boss_room/Run()
	var/obj/structure/dungeon_entrance/infinite/entrance = allocate(/obj/structure/dungeon_entrance/infinite, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/delver = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	delver.mind_initialize()
	TEST_ASSERT(entrance.try_enter(delver), "Entrance should accept the delver.")
	var/datum/dungeon_run/run = entrance.active_run
	run.floor = 2 // so we can assert boss scaling
	run.floor_config = get_dungeon_floor_config(2)

	var/datum/pocket_dimension/dungeon/first_break = run.current_break_room
	var/obj/structure/dungeon_gate/forward_gate
	for(var/obj/structure/dungeon_gate/gate as anything in first_break.gates)
		if(gate.gate_role == DUNGEON_GATE_FORWARD)
			forward_gate = gate
			break
	TEST_ASSERT_NOTNULL(forward_gate, "Break room should have a forward gate.")

	forward_gate.pre_rolled_template = SSpocket_dimensions.resolve_template("dungeon_test_boss")
	forward_gate.sealed = FALSE
	TEST_ASSERT(forward_gate.use_gate(delver), "Gate should transfer into the boss room.")

	var/datum/pocket_dimension/dungeon/boss_room = forward_gate.destination_room
	TEST_ASSERT_NOTNULL(boss_room, "Boss room should instantiate.")
	TEST_ASSERT(!boss_room.cleared, "Boss room should not start cleared.")

	var/mob/living/simple_animal/hostile/boss/dungeon/boss
	for(var/boss_ref in boss_room.guardian_refs)
		var/datum/weakref/ref = boss_room.guardian_refs[boss_ref]
		boss = ref.resolve()
	TEST_ASSERT_NOTNULL(boss, "Boss should be spawned and tracked as a guardian.")
	TEST_ASSERT(boss.maxHealth > initial(boss.maxHealth), "Boss should be scaled up on floor 2.")

	var/obj/structure/dungeon_gate/onward
	for(var/obj/structure/dungeon_gate/gate as anything in boss_room.gates)
		if(gate.gate_role == DUNGEON_GATE_FORWARD)
			onward = gate
			break
	TEST_ASSERT_NOTNULL(onward, "Boss room should have a forward gate.")
	TEST_ASSERT(onward.sealed, "Boss room forward gate should be sealed while the boss lives.")

	boss.death()
	TEST_ASSERT(boss_room.cleared, "Killing the boss should clear the room.")
	TEST_ASSERT_EQUAL(onward.gate_role, DUNGEON_GATE_DESCENT, "Boss death should convert the forward gate to a descent gate.")
	TEST_ASSERT(!onward.sealed, "Descent gate should be open after the boss dies.")

	qdel(run)

/datum/unit_test/dungeon_elite_path/Run()
	var/obj/structure/dungeon_entrance/infinite/entrance = allocate(/obj/structure/dungeon_entrance/infinite, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/delver = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	delver.mind_initialize()
	TEST_ASSERT(entrance.try_enter(delver), "Entrance should accept the delver.")
	var/datum/dungeon_run/run = entrance.active_run

	var/datum/pocket_dimension/dungeon/first_break = run.current_break_room
	var/obj/structure/dungeon_gate/forward_gate
	for(var/obj/structure/dungeon_gate/gate as anything in first_break.gates)
		if(gate.gate_role == DUNGEON_GATE_FORWARD)
			forward_gate = gate
			break
	forward_gate.path_type = DUNGEON_PATH_ELITE
	forward_gate.pre_rolled_template = SSpocket_dimensions.resolve_template("dungeon_test_combat")
	forward_gate.sealed = FALSE
	TEST_ASSERT(forward_gate.use_gate(delver), "Elite gate should transfer the delver.")

	var/datum/pocket_dimension/dungeon/elite_room = forward_gate.destination_room
	TEST_ASSERT_EQUAL(elite_room.incoming_path_type, DUNGEON_PATH_ELITE, "Room should record the elite path type.")
	var/mob/living/guardian
	for(var/g_ref in elite_room.guardian_refs)
		var/datum/weakref/ref = elite_room.guardian_refs[g_ref]
		guardian = ref.resolve()
	TEST_ASSERT_NOTNULL(guardian, "Elite room should have a guardian.")
	TEST_ASSERT(findtext(guardian.name, "Champion"), "Elite guardian should be named a Champion.")

	qdel(run)

/datum/unit_test/dungeon_motes/Run()
	var/obj/structure/dungeon_entrance/infinite/entrance = allocate(/obj/structure/dungeon_entrance/infinite, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/delver = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	delver.mind_initialize()
	TEST_ASSERT(entrance.try_enter(delver), "Entrance should accept the delver.")
	var/datum/dungeon_run/run = entrance.active_run
	TEST_ASSERT_EQUAL(run.motes, 0, "Run should start with no motes.")

	var/datum/pocket_dimension/dungeon/first_break = run.current_break_room
	var/obj/structure/dungeon_gate/forward_gate
	for(var/obj/structure/dungeon_gate/gate as anything in first_break.gates)
		if(gate.gate_role == DUNGEON_GATE_FORWARD)
			forward_gate = gate
			break
	forward_gate.pre_rolled_template = SSpocket_dimensions.resolve_template("dungeon_test_combat")
	forward_gate.sealed = FALSE
	TEST_ASSERT(forward_gate.use_gate(delver), "Gate should transfer to combat room.")
	var/datum/pocket_dimension/dungeon/combat_room = forward_gate.destination_room

	var/mob/living/guardian
	for(var/g_ref in combat_room.guardian_refs)
		var/datum/weakref/ref = combat_room.guardian_refs[g_ref]
		guardian = ref.resolve()
	TEST_ASSERT_NOTNULL(guardian, "Combat room should have a guardian.")
	guardian.death()
	TEST_ASSERT(run.motes > 0, "Killing a guardian should award motes to the run pool.")

	TEST_ASSERT(run.spend_motes(run.motes), "Should be able to spend all motes.")
	TEST_ASSERT_EQUAL(run.motes, 0, "Spending should empty the pool.")
	TEST_ASSERT(!run.spend_motes(1), "Spending more than the pool should fail.")

	qdel(run)

/datum/unit_test/dungeon_boons/Run()
	var/obj/structure/dungeon_entrance/infinite/entrance = allocate(/obj/structure/dungeon_entrance/infinite, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/delver = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	delver.mind_initialize()
	TEST_ASSERT(entrance.try_enter(delver), "Entrance should accept the delver.")
	var/datum/dungeon_run/run = entrance.active_run

	var/starting_health = delver.maxHealth
	var/datum/dungeon_boon/vigor/vigor = new
	run.add_boon(vigor)
	TEST_ASSERT_EQUAL(delver.maxHealth, starting_health + 25, "Vigor boon should raise max health for roster members in the dungeon.")

	// Greed boon multiplies mote drops.
	var/datum/dungeon_boon/greed/greed = new
	run.add_boon(greed)
	TEST_ASSERT(run.mote_multiplier > 1, "Greed boon should set a mote multiplier.")

	qdel(run)
	TEST_ASSERT_EQUAL(delver.maxHealth, starting_health, "Run teardown should strip boons and restore max health (sandbox guarantee).")

/datum/unit_test/dungeon_shrine/Run()
	var/obj/structure/dungeon_entrance/infinite/entrance = allocate(/obj/structure/dungeon_entrance/infinite, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/delver = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	delver.mind_initialize()
	TEST_ASSERT(entrance.try_enter(delver), "Entrance should accept the delver.")
	var/datum/dungeon_run/run = entrance.active_run
	run.motes = 100

	var/datum/pocket_dimension/dungeon/break_room = run.current_break_room
	var/obj/structure/dungeon_shrine/shrine
	for(var/turf/room_turf as anything in break_room.affected_turfs)
		for(var/obj/structure/dungeon_shrine/found in room_turf)
			shrine = found
			break
		if(shrine)
			break
	TEST_ASSERT_NOTNULL(shrine, "Break room with a shrine landmark should build a shrine structure.")
	TEST_ASSERT_EQUAL(shrine.owning_run, run, "Shrine should know its run.")

	shrine.apply_shrine_offer("cache", delver)
	TEST_ASSERT(run.spend_motes(40), "Run should still have motes after a free apply (spend path tested separately).")

	qdel(run)

/datum/unit_test/dungeon_key_gate/Run()
	var/obj/structure/dungeon_entrance/infinite/entrance = allocate(/obj/structure/dungeon_entrance/infinite, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/delver = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	delver.mind_initialize()
	TEST_ASSERT(entrance.try_enter(delver), "Entrance should accept the delver.")
	var/datum/dungeon_run/run = entrance.active_run
	var/datum/pocket_dimension/dungeon/break_room = run.current_break_room

	var/obj/structure/dungeon_gate/forward_gate
	for(var/obj/structure/dungeon_gate/gate as anything in break_room.gates)
		if(gate.gate_role == DUNGEON_GATE_FORWARD)
			forward_gate = gate
			break
	TEST_ASSERT_NOTNULL(forward_gate, "Break room should have a forward gate.")
	forward_gate.requires_key = TRUE
	forward_gate.key_id = "vault"
	forward_gate.sealed = FALSE

	TEST_ASSERT(!forward_gate.use_gate(delver), "Locked gate should refuse passage without a key.")

	var/obj/item/dungeon_key/wrong = new(get_turf(delver))
	wrong.key_id = "other"
	forward_gate.attackby(wrong, delver)
	TEST_ASSERT(!forward_gate.key_unlocked, "Wrong key should not unlock the gate.")

	var/obj/item/dungeon_key/right = new(get_turf(delver))
	right.key_id = "vault"
	forward_gate.attackby(right, delver)
	TEST_ASSERT(forward_gate.key_unlocked, "Matching key should unlock the gate.")
	TEST_ASSERT(QDELETED(right), "Used key should be consumed.")

	qdel(run)

/datum/unit_test/dungeon_progress_persistence/Run()
	var/test_ckey = "dungeontestckey"
	var/datum/dungeon_progress/progress = get_dungeon_progress(test_ckey)
	TEST_ASSERT_NOTNULL(progress, "Should create a progress datum for a ckey.")
	var/before = progress.echoes
	progress.add_echoes(500)
	TEST_ASSERT_EQUAL(progress.echoes, before + 500, "add_echoes should raise the balance.")

	progress.grant_unlock("start_boon")
	TEST_ASSERT(progress.has_unlock("start_boon"), "Unlock should be recorded.")

	// Force a reload from disk via a fresh datum.
	GLOB.player_dungeon_progress -= ckey(test_ckey)
	var/datum/dungeon_progress/reloaded = get_dungeon_progress(test_ckey)
	TEST_ASSERT_EQUAL(reloaded.echoes, before + 500, "Echoes should persist across a reload.")
	TEST_ASSERT(reloaded.has_unlock("start_boon"), "Unlocks should persist across a reload.")

	// Cleanup the test save so reruns are deterministic.
	reloaded.echoes = before
	reloaded.purchased_unlocks = list()
	reloaded.save_progress()

/datum/unit_test/dungeon_start_unlocks/Run()
	var/obj/structure/dungeon_entrance/infinite/entrance = allocate(/obj/structure/dungeon_entrance/infinite, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/delver = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	delver.mind_initialize()

	var/datum/dungeon_progress/progress = get_dungeon_progress(delver.ckey || "fallbackckey")
	progress.purchased_unlocks = list("starting_motes" = TRUE, "deep_start" = TRUE)

	// Manually seed + start a run to read the unlocks.
	var/datum/dungeon_run/run = new(entrance, null)
	run.seed_from_progress(progress)
	TEST_ASSERT(run.start(), "Run should start.")
	TEST_ASSERT_EQUAL(run.floor, 2, "deep_start unlock should begin the run on floor 2.")
	TEST_ASSERT_EQUAL(run.motes, 50, "starting_motes unlock should grant 50 motes.")

	qdel(run)
	progress.purchased_unlocks = list()
	progress.save_progress()

/datum/unit_test/dungeon_cosmetic_title/Run()
	var/test_ckey = "cosmeticstestckey"
	var/datum/dungeon_progress/progress = get_dungeon_progress(test_ckey)
	progress.grant_cosmetic("title_delver")
	progress.selected_title = "title_delver"
	progress.save_progress()
	TEST_ASSERT(progress.has_cosmetic("title_delver"), "Cosmetic should be recorded.")

	var/datum/dungeon_cosmetic/cosmetic = get_dungeon_cosmetic_by_id("title_delver")
	TEST_ASSERT_NOTNULL(cosmetic, "Should resolve a cosmetic by id.")
	TEST_ASSERT_EQUAL(cosmetic.title_text, "Delver of the Deep", "Title text should match.")
	qdel(cosmetic)

	// Cleanup
	progress.purchased_cosmetics = list()
	progress.selected_title = null
	progress.save_progress()
