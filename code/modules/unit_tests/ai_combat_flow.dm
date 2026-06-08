/datum/targetting_datum/ai_combat_flow_hot_pursuit
	var/atom/allowed_target

/datum/targetting_datum/ai_combat_flow_hot_pursuit/can_attack(mob/living/living_mob, atom/target)
	return target == allowed_target

/datum/targetting_datum/ai_combat_flow_hot_pursuit/can_engage_target(mob/living/living_mob, atom/target)
	return target == allowed_target

/datum/targetting_datum/ai_combat_flow_hot_pursuit/can_quickly_engage_target(mob/living/living_mob, atom/target)
	return FALSE

/datum/intent/ai_combat_flow_reach
	reach = 2

/datum/ai_behavior/ai_combat_flow_non_reach_probe
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT
	required_distance = 1

/datum/ai_behavior/ai_combat_flow_non_reach_probe/perform(delta_time, datum/ai_controller/controller)
	. = ..()
	controller.set_blackboard_key("ai_combat_flow_non_reach_probe_fired", TRUE)

/datum/unit_test/ai_combat_alert_prevents_idle

/datum/unit_test/ai_combat_alert_prevents_idle/Run()
	var/mob/living/simple_animal/hostile/hostile_mob = allocate(/mob/living/simple_animal/hostile)
	var/datum/ai_controller/controller = hostile_mob.ai_controller
	if(!controller)
		controller = allocate(/datum/ai_controller, hostile_mob)

	controller.set_ai_status(AI_STATUS_IDLE)
	controller.set_blackboard_key(BB_AI_ALERT_MODE_UNTIL, world.time + 30 SECONDS)
	controller.recalculate_idle()

	TEST_ASSERT_EQUAL(controller.ai_status, AI_STATUS_ON, "AI with a live combat-alert timer should not remain idle just because no client is in its watched cells.")

/datum/unit_test/ai_combat_aggro_prevents_idle_and_preserves_horny_target

/datum/unit_test/ai_combat_aggro_prevents_idle_and_preserves_horny_target/Run()
	var/mob/living/simple_animal/hostile/hostile_mob = allocate(/mob/living/simple_animal/hostile)
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/horny_target = allocate(/mob/living/carbon/human)
	var/datum/ai_controller/controller = hostile_mob.ai_controller
	if(!controller)
		controller = allocate(/datum/ai_controller, hostile_mob)

	var/list/aggro_table = list()
	aggro_table[attacker] = 15
	controller.set_blackboard_key(BB_MOB_AGGRO_TABLE, aggro_table)
	controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_HORNY_TARGET, horny_target)
	controller.set_ai_status(AI_STATUS_IDLE)
	controller.recalculate_idle()

	TEST_ASSERT_EQUAL(controller.ai_status, AI_STATUS_ON, "AI with active aggro should wake instead of idling off-screen.")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_BASIC_MOB_CURRENT_HORNY_TARGET], horny_target, "Combat wake checks must not clear the horny target pipeline.")

/datum/unit_test/ai_combat_attack_signal_wakes_idle_ai_and_preserves_horny_target

/datum/unit_test/ai_combat_attack_signal_wakes_idle_ai_and_preserves_horny_target/Run()
	var/mob/living/simple_animal/hostile/hostile_mob = allocate(/mob/living/simple_animal/hostile)
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/horny_target = allocate(/mob/living/carbon/human)
	var/datum/ai_controller/controller = hostile_mob.ai_controller
	if(!controller)
		controller = allocate(/datum/ai_controller, hostile_mob)

	controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_HORNY_TARGET, horny_target)
	controller.set_ai_status(AI_STATUS_IDLE)
	SEND_SIGNAL(hostile_mob, COMSIG_ATOM_WAS_ATTACKED, attacker, 10)

	TEST_ASSERT_EQUAL(controller.ai_status, AI_STATUS_ON, "Idle AI should wake when its pawn receives COMSIG_ATOM_WAS_ATTACKED.")
	TEST_ASSERT(controller.blackboard[BB_AI_ALERT_MODE_UNTIL] > world.time, "Attack wake should stamp a short combat-alert grace period.")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_BASIC_MOB_CURRENT_HORNY_TARGET], horny_target, "Attack wake must not clear the horny target pipeline.")

/datum/unit_test/ai_combat_projectile_hit_records_ranged_attacker

/datum/unit_test/ai_combat_projectile_hit_records_ranged_attacker/Run()
	var/mob/living/simple_animal/hostile/hostile_mob = allocate(/mob/living/simple_animal/hostile)
	var/mob/living/carbon/human/shooter = allocate(/mob/living/carbon/human)
	var/obj/projectile/projectile = allocate(/obj/projectile)
	var/datum/ai_controller/controller = hostile_mob.ai_controller
	if(!controller)
		controller = allocate(/datum/ai_controller, hostile_mob)

	projectile.firer = shooter
	projectile.damage = 25
	hostile_mob.AddElement(/datum/element/relay_attackers)
	SEND_SIGNAL(hostile_mob, COMSIG_ATOM_BULLET_ACT, projectile)

	TEST_ASSERT_EQUAL(controller.blackboard[BB_LAST_RANGED_ATTACKER], shooter, "Projectile hits should record the ranged attacker on the victim AI controller.")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_LAST_RANGED_HIT_TIME], world.time, "Projectile hits should record the ranged hit time on the victim AI controller.")

/datum/unit_test/ai_combat_hot_pursuit_keeps_recent_ranged_threat

/datum/unit_test/ai_combat_hot_pursuit_keeps_recent_ranged_threat/Run()
	var/mob/living/simple_animal/hostile/hostile_mob = allocate(/mob/living/simple_animal/hostile)
	var/mob/living/carbon/human/shooter = allocate(/mob/living/carbon/human)
	var/datum/ai_controller/controller = hostile_mob.ai_controller
	if(!controller)
		controller = allocate(/datum/ai_controller, hostile_mob)

	var/datum/targetting_datum/ai_combat_flow_hot_pursuit/targetting_datum = allocate(/datum/targetting_datum/ai_combat_flow_hot_pursuit)
	targetting_datum.allowed_target = shooter
	controller.set_blackboard_key(BB_TARGETTING_DATUM, targetting_datum)
	controller.set_blackboard_key(BB_HIGHEST_THREAT_MOB, shooter)
	controller.set_blackboard_key(BB_AGGRO_MAINTAIN_RANGE, -1)
	controller.set_blackboard_key(BB_LAST_RANGED_ATTACKER, shooter)
	controller.set_blackboard_key(BB_LAST_RANGED_HIT_TIME, world.time)

	var/datum/ai_behavior/find_aggro_targets/find_targets = allocate(/datum/ai_behavior/find_aggro_targets)
	find_targets.perform(1, controller, BB_BASIC_MOB_CURRENT_TARGET, BB_TARGETTING_DATUM, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)

	TEST_ASSERT_EQUAL(controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET], shooter, "A recent ranged attacker should be preserved as the active target during hot-pursuit grace, even beyond maintain range.")

/datum/unit_test/ai_combat_call_for_help_wakes_idle_ally

/datum/unit_test/ai_combat_call_for_help_wakes_idle_ally/Run()
	var/mob/living/carbon/human/calling_mob = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/ally = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	var/datum/ai_controller/caller_controller = allocate(/datum/ai_controller, calling_mob)
	var/datum/ai_controller/ally_controller = allocate(/datum/ai_controller, ally)

	var/turf/caller_turf = get_turf(calling_mob)
	var/turf/ally_turf = get_step(caller_turf, EAST)
	TEST_ASSERT_NOTNULL(ally_turf, "Test setup needs an adjacent turf for the called ally.")
	ally.forceMove(ally_turf)

	var/list/test_faction = list("ai_combat_flow_allies")
	calling_mob.faction = test_faction.Copy()
	ally.faction = test_faction.Copy()
	caller_controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, target)
	ally_controller.set_ai_status(AI_STATUS_IDLE)

	var/datum/ai_behavior/call_for_help/call_help = allocate(/datum/ai_behavior/call_for_help)
	call_help.perform(1, caller_controller, BB_BASIC_MOB_CURRENT_TARGET)

	TEST_ASSERT_EQUAL(ally_controller.ai_status, AI_STATUS_ON, "Call-for-help target injection should wake an idle allied AI immediately.")
	TEST_ASSERT_EQUAL(ally_controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET], target, "Call-for-help should still assign the caller's combat target to the ally.")

/datum/unit_test/ai_combat_added_threat_wakes_idle_ai

/datum/unit_test/ai_combat_added_threat_wakes_idle_ai/Run()
	var/mob/living/simple_animal/hostile/hostile_mob = allocate(/mob/living/simple_animal/hostile)
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	var/datum/ai_controller/controller = hostile_mob.ai_controller
	if(!controller)
		controller = allocate(/datum/ai_controller, hostile_mob)

	var/datum/component/ai_aggro_system/aggro_system = hostile_mob.GetComponent(/datum/component/ai_aggro_system)
	if(!aggro_system)
		hostile_mob.AddComponent(/datum/component/ai_aggro_system)
		aggro_system = hostile_mob.GetComponent(/datum/component/ai_aggro_system)
	TEST_ASSERT_NOTNULL(aggro_system, "Test setup should attach an AI aggro system.")

	controller.set_ai_status(AI_STATUS_IDLE)
	aggro_system.add_threat_to_mob(attacker, 15)

	TEST_ASSERT_EQUAL(controller.ai_status, AI_STATUS_ON, "Adding threat through the aggro system should wake an idle AI without requiring a later idle recalculation.")

/datum/unit_test/ai_combat_non_reach_movement_ignores_intent_reach_distance

/datum/unit_test/ai_combat_non_reach_movement_ignores_intent_reach_distance/Run()
	var/mob/living/carbon/human/pawn = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	var/datum/ai_controller/controller = allocate(/datum/ai_controller, pawn)

	var/turf/start_turf = get_turf(pawn)
	var/turf/one_step = get_step(start_turf, EAST)
	TEST_ASSERT_NOTNULL(one_step, "Test setup needs a turf one tile away.")
	var/turf/two_steps = get_step(one_step, EAST)
	TEST_ASSERT_NOTNULL(two_steps, "Test setup needs a turf two tiles away.")
	target.forceMove(two_steps)

	pawn.used_intent = allocate(/datum/intent/ai_combat_flow_reach)
	var/datum/ai_behavior/ai_combat_flow_non_reach_probe/probe = allocate(/datum/ai_behavior/ai_combat_flow_non_reach_probe)
	controller.current_behaviors = list()
	controller.current_behaviors[probe] = TRUE
	controller.set_movement_target(probe.type, target)

	controller.process(1)

	TEST_ASSERT(!controller.blackboard["ai_combat_flow_non_reach_probe_fired"], "Movement behaviors without AI_BEHAVIOR_REQUIRE_REACH should not use combat intent reach to satisfy required_distance.")
