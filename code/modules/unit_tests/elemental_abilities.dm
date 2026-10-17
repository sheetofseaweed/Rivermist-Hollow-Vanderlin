/// Stops a thrown or stunned test mob, so teardown never deletes it mid-flight or floored.
/datum/unit_test/proc/settle_elemental_victim(mob/living/victim)
	QDEL_NULL(victim.throwing)
	victim.SetParalyzed(0)
	victim.SetImmobilized(0)
	victim.SetKnockdown(0)

/datum/unit_test/elemental_slam_respects_cooldown

/datum/unit_test/elemental_slam_respects_cooldown/Run()
	var/turf/center = locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y + 1, run_loc_floor_bottom_left.z)
	var/mob/living/simple_animal/hostile/retaliate/elemental/warden/warden = allocate(/mob/living/simple_animal/hostile/retaliate/elemental/warden, center)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(center, EAST))

	var/first_slam = warden.try_slam(victim)
	var/brute_after_slam = victim.getBruteLoss()
	var/second_slam = warden.try_slam(victim)
	var/brute_after_retry = victim.getBruteLoss()
	settle_elemental_victim(victim)

	TEST_ASSERT(first_slam, "A warden off cooldown should slam a living victim.")
	TEST_ASSERT(brute_after_slam > 0, "The slam should injure the victim.")
	TEST_ASSERT(!second_slam, "A second slam inside the cooldown must be refused.")
	TEST_ASSERT_EQUAL(brute_after_retry, brute_after_slam, "A refused slam must not injure the victim.")

/datum/unit_test/elemental_colossus_stomp_spares_self_and_allies

/datum/unit_test/elemental_colossus_stomp_spares_self_and_allies/Run()
	var/turf/center = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/mob/living/simple_animal/hostile/retaliate/elemental/collossus/colossus = allocate(/mob/living/simple_animal/hostile/retaliate/elemental/collossus, center)
	var/mob/living/simple_animal/hostile/retaliate/elemental/crawler/crawler = allocate(/mob/living/simple_animal/hostile/retaliate/elemental/crawler, get_step(center, EAST))
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(center, NORTH))
	TEST_ASSERT_NOTNULL(colossus.ai_controller, "The colossus should have an AI controller.")

	var/colossus_brute = colossus.getBruteLoss()
	var/crawler_brute = crawler.getBruteLoss()
	var/datum/ai_behavior/collossus_quake/stomp = GET_AI_BEHAVIOR(/datum/ai_behavior/collossus_quake)
	stomp.perform(0.1, colossus.ai_controller)
	var/victim_brute = victim.getBruteLoss()
	settle_elemental_victim(victim)
	settle_elemental_victim(crawler)

	TEST_ASSERT_EQUAL(colossus.getBruteLoss(), colossus_brute, "The stomp must not hit the colossus itself.")
	TEST_ASSERT_EQUAL(crawler.getBruteLoss(), crawler_brute, "The stomp must spare allied elementals.")
	TEST_ASSERT(victim_brute > 0, "The stomp should hit an adjacent non-allied mob.")

/datum/unit_test/elemental_behemoth_quake_keeps_target

/datum/unit_test/elemental_behemoth_quake_keeps_target/Run()
	var/turf/center = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/mob/living/simple_animal/hostile/retaliate/elemental/behemoth/behemoth = allocate(/mob/living/simple_animal/hostile/retaliate/elemental/behemoth, center)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(center, EAST))
	var/datum/ai_controller/controller = behemoth.ai_controller
	TEST_ASSERT_NOTNULL(controller, "The behemoth should have an AI controller.")

	var/datum/ai_planning_subtree/behemoth_special_abilities/sure_quake = allocate(/datum/ai_planning_subtree/behemoth_special_abilities)
	sure_quake.quake_chance = 100
	controller.planning_subtrees = list(sure_quake, GLOB.ai_subtrees[/datum/ai_planning_subtree/basic_melee_attack_subtree])
	controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, victim)
	controller.set_blackboard_key(BB_QUAKE_COOLDOWN, world.time + 1 MINUTES)

	var/datum/ai_behavior/melee = GET_AI_BEHAVIOR(/datum/ai_behavior/basic_melee_attack)
	var/datum/ai_behavior/quake = GET_AI_BEHAVIOR(/datum/ai_behavior/behemoth_quake)
	ai_test_plan(controller)
	TEST_ASSERT(LAZYACCESS(controller.current_behaviors, melee), "The behemoth should start its melee attack first.")

	controller.set_blackboard_key(BB_QUAKE_COOLDOWN, 0)
	ai_test_plan(controller)
	TEST_ASSERT(LAZYACCESS(controller.current_behaviors, quake), "A ready quake should be queued.")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET], victim, "Queuing the quake must not clear the target.")
	TEST_ASSERT(LAZYACCESS(controller.current_behaviors, melee), "The melee attack should stay queued beside the quake.")

	controller.ProcessBehavior(0.1, quake)
	// Freeze the AI so a melee swing cannot knock the victim out of the rupture area.
	controller.CancelActions()
	controller.PauseAi(10 SECONDS)
	sleep(1.6 SECONDS)

	var/victim_paralyzed = victim.IsParalyzed()
	var/rock_on_victim = locate(/obj/structure/flora/rock) in get_turf(victim)
	var/rock_on_behemoth = locate(/obj/structure/flora/rock) in get_turf(behemoth)
	settle_elemental_victim(victim)

	TEST_ASSERT(victim_paralyzed, "The rupture should paralyze the victim next to the behemoth.")
	TEST_ASSERT_NOTNULL(rock_on_victim, "The rupture should raise a rock under the victim.")
	TEST_ASSERT_NULL(rock_on_behemoth, "The rupture must not hit the behemoth that cast it.")

/datum/unit_test/overall_damage_respects_limb_multiplier

/datum/unit_test/overall_damage_respects_limb_multiplier/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	for(var/obj/item/bodypart/part as anything in victim.bodyparts)
		part.damage_multiplier = 0.5

	victim.take_overall_damage(20, 0, damage_type = BCLASS_BLUNT, no_crit = TRUE)
	var/brute = victim.getBruteLoss()

	TEST_ASSERT(brute > 0, "A blunt hit should injure the victim.")
	TEST_ASSERT(brute <= 10, "A 20 damage hit on half-damage limbs should land 10 at most, not spill onto other limbs; got [brute].")
