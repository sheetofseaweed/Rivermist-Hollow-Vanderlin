/datum/ai_behavior/wave_attack_point
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_MOVE_AND_PERFORM
	required_distance = 2

/datum/ai_behavior/wave_attack_point/setup(datum/ai_controller/controller, target_key)
	. = ..()
	if(!.)
		return FALSE
	var/atom/target_point = controller.blackboard[target_key]
	if(QDELETED(target_point))
		return FALSE
	controller.set_movement_target(type, target_point)
	return TRUE

/datum/ai_behavior/wave_attack_point/perform(seconds_per_tick, datum/ai_controller/controller, target_key)
	. = ..()
	var/atom/target_point = controller.blackboard[target_key]
	var/datum/wave_defense_coordinator/coordinator = controller.blackboard[BB_WAVE_COORDINATOR]
	if(!coordinator || QDELETED(target_point))
		finish_action(controller, FALSE, target_key)
		return
	if(coordinator.wave_state != WAVE_ADVANCING)
		finish_action(controller, TRUE, target_key)
		return

	var/datum/ai_movement/hybrid_pathing/wave_defense/wave_movement = controller.ai_movement
	var/at_breaching_frontier = FALSE
	if(istype(wave_movement) && !length(controller.movement_path))
		at_breaching_frontier = (WEAKREF(controller) in wave_movement.using_closest_approach)
	var/atom/destructible = locate_wave_target_near(controller, controller.pawn, at_breaching_frontier)
	if(destructible)
		if(isliving(destructible))
			feed_threat(controller, destructible)
		else
			controller.set_blackboard_key(BB_WAVE_ATTACK_TARGET, destructible)
		finish_action(controller, TRUE, target_key)
		return

	if(coordinator.wave_state == WAVE_ADVANCING && get_dist(target_point, controller.pawn) <= required_distance)
		coordinator.begin_occupying()
		finish_action(controller, TRUE, target_key)

/datum/ai_behavior/wave_attack_point/proc/feed_threat(datum/ai_controller/controller, mob/living/target)
	var/mob/living/pawn = controller.pawn
	var/datum/component/ai_aggro_system/aggro_component = pawn.GetComponent(/datum/component/ai_aggro_system)
	if(aggro_component)
		aggro_component.add_threat_to_mob_capped(target, 15, 15)
		aggro_component.add_threat_to_mob(target, 3)
	else if(!controller.blackboard_key_exists(BB_BASIC_MOB_CURRENT_TARGET))
		controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, target)

/datum/ai_behavior/wave_attack_point/proc/locate_wave_target_near(datum/ai_controller/controller, atom/point, allow_structures, radius = WAVE_DEFENSE_POINT_RADIUS)
	var/mob/living/pawn = controller.pawn
	var/datum/targetting_datum/current_targetting = controller.blackboard[BB_TARGETTING_DATUM]
	var/static/datum/targetting_datum/basic/allow_structures/structure_targetting = new

	for(var/mob/living/enemy in oview(radius, point))
		if(current_targetting?.can_engage_target(pawn, enemy))
			return enemy
	if(!allow_structures)
		return null
	for(var/obj/thing in view(radius, point))
		if(structure_targetting.can_attack(pawn, thing))
			return thing
	return null

/datum/ai_behavior/wave_attack_point/finish_action(datum/ai_controller/controller, succeeded, target_key)
	. = ..()
	controller.clear_blackboard_key(target_key)

/datum/ai_behavior/wave_attack_target
	action_cooldown = 0.5 SECONDS
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_REQUIRE_REACH

/datum/ai_behavior/wave_attack_target/setup(datum/ai_controller/controller, target_key)
	. = ..()
	if(!.)
		return FALSE
	var/atom/target = controller.blackboard[target_key]
	if(QDELETED(target))
		return FALSE
	controller.set_movement_target(type, target)
	return TRUE

/datum/ai_behavior/wave_attack_target/perform(seconds_per_tick, datum/ai_controller/controller, target_key)
	. = ..()
	var/mob/living/pawn = controller.pawn
	var/atom/target = controller.blackboard[target_key]
	var/static/datum/targetting_datum/basic/allow_structures/structure_targetting = new
	if(!structure_targetting.can_attack(pawn, target))
		finish_action(controller, FALSE, target_key)
		return

	var/list/possible_intents = list()
	for(var/datum/intent/intent as anything in pawn.possible_a_intents)
		if(istype(intent, /datum/intent/unarmed/help) || istype(intent, /datum/intent/unarmed/shove) || istype(intent, /datum/intent/unarmed/grab))
			continue
		possible_intents |= intent
	if(length(possible_intents))
		pawn.a_intent = pick(possible_intents)
		pawn.used_intent = pawn.a_intent

	pawn.face_atom(target)
	controller.ai_interact(target, TRUE, TRUE)
	if(pawn.next_click < world.time)
		pawn.next_click = world.time + pawn.melee_attack_cooldown
		SEND_SIGNAL(pawn, COMSIG_MOB_BREAK_SNEAK)

/datum/ai_behavior/wave_attack_target/finish_action(datum/ai_controller/controller, succeeded, target_key)
	. = ..()
	controller.clear_blackboard_key(target_key)

/datum/ai_behavior/wave_occupy_point
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT
	required_distance = 3

/datum/ai_behavior/wave_occupy_point/setup(datum/ai_controller/controller, target_key)
	. = ..()
	if(!.)
		return FALSE
	var/atom/target_point = controller.blackboard[target_key]
	if(QDELETED(target_point))
		return FALSE
	controller.set_movement_target(type, target_point)
	return TRUE

/datum/ai_behavior/wave_occupy_point/perform(seconds_per_tick, datum/ai_controller/controller, target_key)
	. = ..()
	var/datum/wave_defense_coordinator/coordinator = controller.blackboard[BB_WAVE_COORDINATOR]
	if(!coordinator)
		finish_action(controller, FALSE, target_key)
		return
	coordinator.check_occupy_progress()
	if(QDELETED(coordinator) || controller.blackboard[BB_WAVE_COORDINATOR] != coordinator)
		return

	var/mob/living/pawn = controller.pawn
	var/datum/targetting_datum/current_targetting = controller.blackboard[BB_TARGETTING_DATUM]
	for(var/mob/living/enemy in oview(3, pawn))
		if(current_targetting?.can_engage_target(pawn, enemy))
			var/datum/component/ai_aggro_system/aggro_component = pawn.GetComponent(/datum/component/ai_aggro_system)
			if(aggro_component)
				aggro_component.add_threat_to_mob_capped(enemy, 15, 15)
				aggro_component.add_threat_to_mob(enemy, 3)
			else if(!controller.blackboard_key_exists(BB_BASIC_MOB_CURRENT_TARGET))
				controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, enemy)
			break

	finish_action(controller, TRUE, target_key)

/datum/ai_behavior/wave_occupy_point/finish_action(datum/ai_controller/controller, succeeded, target_key)
	. = ..()
	controller.clear_blackboard_key(target_key)
