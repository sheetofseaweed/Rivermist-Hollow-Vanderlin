/// Minotaur special attacks subtree — selects and queues special attacks based on cooldowns, phase, and rage.
/datum/ai_planning_subtree/minotaur_special_attacks
/datum/ai_planning_subtree/minotaur_special_attacks/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/atom/target = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	if(QDELETED(target))
		return

	var/current_phase = controller.blackboard[BB_MINOTAUR_PHASE]
	var/current_rage = controller.blackboard[BB_MINOTAUR_RAGE_METER]
	var/world_time = world.time

	var/can_charge = world_time > controller.blackboard[BB_MINOTAUR_CHARGE_COOLDOWN]
	var/can_fury = world_time > controller.blackboard[BB_MINOTAUR_FURY_COOLDOWN] && current_phase >= 2
	var/can_slam = world_time > controller.blackboard[BB_MINOTAUR_SLAM_COOLDOWN] && current_phase >= 3

	var/list/possible_attacks = list()

	if(can_charge && get_dist(controller.pawn, target) >= 4 && get_dist(controller.pawn, target) <= 10)
		possible_attacks += "charge"

	if(can_fury)
		possible_attacks += "fury"

	if(can_slam && current_rage >= 50)
		possible_attacks += "slam"

	if(!length(possible_attacks))
		return

	var/chosen_attack = pick(possible_attacks)

	// Avoid repeating the same special attack
	if(length(possible_attacks) > 1 && chosen_attack == controller.blackboard[BB_MINOTAUR_LAST_SPECIAL_ATTACK])
		possible_attacks -= chosen_attack
		chosen_attack = pick(possible_attacks)

	controller.set_blackboard_key(BB_MINOTAUR_LAST_SPECIAL_ATTACK, chosen_attack)

	switch(chosen_attack)
		if("charge")
			controller.queue_behavior(/datum/ai_behavior/minotaur_charge_attack, BB_BASIC_MOB_CURRENT_TARGET)
			return SUBTREE_RETURN_FINISH_PLANNING
		if("fury")
			controller.queue_behavior(/datum/ai_behavior/minotaur_fury_slam, BB_BASIC_MOB_CURRENT_TARGET)
			return SUBTREE_RETURN_FINISH_PLANNING
		if("slam")
			controller.queue_behavior(/datum/ai_behavior/minotaur_ground_slam)
			controller.set_blackboard_key(BB_MINOTAUR_RAGE_METER, max(0, current_rage - 50))
			return SUBTREE_RETURN_FINISH_PLANNING

// ============================================================
// CHARGE ATTACK — stage-driven, no sleep(), state in blackboard
// ============================================================
// Stages: 0 = telegraphing, 1 = charging (tick-by-tick movement), 2 = done

/datum/ai_behavior/minotaur_charge_attack
	behavior_flags = AI_BEHAVIOR_MOVE_AND_PERFORM
	action_cooldown = 1 // Fast tick for smooth charge movement

/datum/ai_behavior/minotaur_charge_attack/setup(datum/ai_controller/controller, target_key)
	. = ..()
	var/atom/target = controller.blackboard[target_key]
	if(QDELETED(target))
		return FALSE

	controller.set_blackboard_key(BB_MINOTAUR_CHARGE_COOLDOWN, world.time + 15 SECONDS)
	controller.set_blackboard_key(BB_MINOTAUR_CHARGE_STAGE, 0)
	controller.set_blackboard_key(BB_MINOTAUR_CHARGE_DIRECTION, 0)
	controller.set_blackboard_key(BB_MINOTAUR_CHARGE_STEPS_LEFT, 0)
	return TRUE

/datum/ai_behavior/minotaur_charge_attack/perform(delta_time, datum/ai_controller/controller, target_key)
	. = ..()
	var/mob/living/simple_animal/hostile/retaliate/minotaur/boss = controller.pawn
	if(!istype(boss) || boss.stat != CONSCIOUS)
		finish_action(controller, FALSE)
		return

	var/atom/target = controller.blackboard[target_key]
	if(QDELETED(target))
		finish_action(controller, FALSE)
		return

	var/stage = controller.blackboard[BB_MINOTAUR_CHARGE_STAGE]

	switch(stage)
		if(0) // Telegraph
			boss.visible_message("<span class='danger'>[boss] lowers its head and prepares to charge!</span>")
			playsound(boss, 'sound/misc/meteorimpact.ogg', 50, TRUE)
			show_charge_path(boss, target)

			// Calculate charge direction and distance
			var/turf/start_turf = get_turf(boss)
			var/turf/target_turf = get_turf(target)
			var/direction = get_dir(start_turf, target_turf)
			var/distance = get_dist(start_turf, target_turf)
			var/charge_distance = min(distance + 2, 15)

			controller.set_blackboard_key(BB_MINOTAUR_CHARGE_DIRECTION, direction)
			controller.set_blackboard_key(BB_MINOTAUR_CHARGE_STEPS_LEFT, charge_distance)
			controller.set_blackboard_key(BB_MINOTAUR_CHARGE_STAGE, 1)

			// Pause before charging
			action_cooldown = 2 SECONDS
			controller.PauseAi(2 SECONDS)

		if(1) // Charging — move one tile per perform tick
			action_cooldown = 1 // Fast ticks for smooth movement
			var/direction = controller.blackboard[BB_MINOTAUR_CHARGE_DIRECTION]
			var/steps_left = controller.blackboard[BB_MINOTAUR_CHARGE_STEPS_LEFT]

			if(steps_left <= 0 || !direction)
				finish_charge(controller, boss)
				return

			var/turf/next_turf = get_step(boss, direction)

			// Blocked by closed turf
			if(isclosedturf(next_turf) && next_turf.density)
				finish_charge(controller, boss)
				return

			// Blocked by dense structure
			for(var/obj/structure/A in next_turf)
				if(A.density)
					A.take_damage(30)
					finish_charge(controller, boss)
					return

			// Leave afterimage
			new /obj/effect/temp_visual/decoy/fading(get_turf(boss), boss)

			// Hit living mobs in path
			for(var/atom/A in next_turf)
				if(isliving(A) && A != boss)
					var/mob/living/M = A
					M.Knockdown(2 SECONDS)
					M.adjustBruteLoss(20)
					M.throw_at(get_edge_target_turf(boss, direction), 4, 1)
					playsound(M, pick('sound/combat/hits/punch/punch_hard (1).ogg','sound/combat/hits/punch/punch_hard (2).ogg','sound/combat/hits/punch/punch_hard (3).ogg'), 50, TRUE)
				else if(isstructure(A) && !A.density)
					var/obj/structure/S = A
					S.take_damage(30)

			boss.forceMove(next_turf)
			boss.setDir(direction)

			// First step: announce and add afterimage component
			if(steps_left == controller.blackboard[BB_MINOTAUR_CHARGE_STEPS_LEFT])
				boss.visible_message("<span class='danger'>[boss] charges forward!</span>")
				playsound(boss, 'sound/combat/hits/kick/stomp.ogg', 50, TRUE)

			controller.set_blackboard_key(BB_MINOTAUR_CHARGE_STEPS_LEFT, steps_left - 1)

			if(steps_left - 1 <= 0)
				finish_charge(controller, boss)

/datum/ai_behavior/minotaur_charge_attack/proc/finish_charge(datum/ai_controller/controller, mob/living/simple_animal/hostile/retaliate/minotaur/boss)
	if(!istype(boss))
		finish_action(controller, FALSE)
		return

	playsound(boss, 'sound/misc/meteorimpact.ogg', 50, TRUE)
	// Impact damage to adjacent mobs
	for(var/mob/living/L in orange(1, boss))
		if(L != boss)
			L.Knockdown(1 SECONDS)
			L.adjustBruteLoss(10)

	new /obj/effect/temp_visual/minotaur_impact(get_turf(boss))

	// Reset charge state
	controller.set_blackboard_key(BB_MINOTAUR_CHARGE_STAGE, 0)
	controller.set_blackboard_key(BB_MINOTAUR_CHARGE_STEPS_LEFT, 0)
	action_cooldown = 3 SECONDS // Reset to normal
	finish_action(controller, TRUE)

/datum/ai_behavior/minotaur_charge_attack/proc/show_charge_path(mob/living/boss, atom/target)
	var/turf/start_turf = get_turf(boss)
	var/turf/target_turf = get_turf(target)

	if(!start_turf || !target_turf)
		return

	var/direction = get_dir(start_turf, target_turf)
	var/distance = get_dist(start_turf, target_turf)
	var/charge_distance = min(distance + 2, 15)

	var/turf/current_turf = start_turf

	for(var/i in 1 to charge_distance)
		var/turf/next_turf = get_step(current_turf, direction)
		if(!next_turf || isclosedturf(next_turf))
			break

		var/blocked = FALSE
		for(var/obj/structure/A in next_turf)
			if(A.density)
				blocked = TRUE
				break

		new /obj/effect/temp_visual/target/minotaur(next_turf)

		current_turf = next_turf

		if(blocked)
			break

// ============================================================
// FURY SLAM — timer-based, no sleep()
// ============================================================

/datum/ai_behavior/minotaur_fury_slam
	action_cooldown = 5 SECONDS
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_MOVE_AND_PERFORM
	required_distance = 1

/datum/ai_behavior/minotaur_fury_slam/setup(datum/ai_controller/controller, target_key)
	. = ..()
	var/atom/target = controller.blackboard[target_key]
	if(QDELETED(target))
		return FALSE

	set_movement_target(controller, target)
	return TRUE

/datum/ai_behavior/minotaur_fury_slam/perform(delta_time, datum/ai_controller/controller, target_key)
	. = ..()
	var/mob/living/simple_animal/hostile/retaliate/minotaur/boss = controller.pawn
	if(!istype(boss) || boss.stat != CONSCIOUS)
		finish_action(controller, FALSE)
		return

	var/atom/target = controller.blackboard[target_key]
	if(QDELETED(target))
		finish_action(controller, FALSE)
		return

	controller.set_blackboard_key(BB_MINOTAUR_FURY_COOLDOWN, world.time + 25 SECONDS)
	boss.visible_message("<span class='danger'>[boss] raises its weapon high, the air around it shimmering with heat!</span>")
	playsound(boss, 'sound/magic/fireball.ogg', 50, TRUE)

	new /obj/effect/temp_visual/minotaur_magic(get_turf(boss))

	addtimer(CALLBACK(src, PROC_REF(do_fury_slam), controller, target), 1.5 SECONDS)

/datum/ai_behavior/minotaur_fury_slam/proc/do_fury_slam(datum/ai_controller/controller, atom/target)
	var/mob/living/simple_animal/hostile/retaliate/minotaur/boss = controller.pawn
	if(!istype(boss) || QDELETED(target))
		finish_action(controller, FALSE)
		return

	var/turf/target_turf = get_turf(target)

	boss.visible_message("<span class='danger'>[boss] slams the ground, creating a rain of fiery debris!</span>")
	playsound(boss, 'sound/misc/bamf.ogg', 50, TRUE)

	var/current_phase = controller.blackboard[BB_MINOTAUR_PHASE]
	var/zone_count = 3 + (current_phase * 2)

	if(target_turf)
		new /obj/effect/temp_visual/minotaur_fury_zone/strong(target_turf)

		var/list/possible_turfs = list()
		for(var/turf/T in range(3, target_turf))
			if(T != target_turf && !T.density)
				possible_turfs += T

		for(var/i in 1 to min(zone_count, length(possible_turfs)))
			if(!length(possible_turfs))
				break

			var/turf/zone_turf = pick_n_take(possible_turfs)

			addtimer(CALLBACK(src, PROC_REF(create_fury_zone), zone_turf, i, current_phase), i * 3)

	new /obj/effect/temp_visual/minotaur_fury_zone(get_turf(boss))

	if(current_phase >= 3)
		var/turf/front_turf = get_step(boss, boss.dir)
		if(front_turf)
			boss.visible_message("<span class='danger'>[boss] smashes the ground in front of it!</span>")
			new /obj/effect/temp_visual/minotaur_impact(front_turf)
			for(var/mob/living/L in front_turf)
				if(L != boss)
					L.Knockdown(2 SECONDS)
					L.adjustBruteLoss(15)

	finish_action(controller, TRUE)

/datum/ai_behavior/minotaur_fury_slam/proc/create_fury_zone(turf/zone_turf, index, phase)
	if(!zone_turf)
		return

	if(phase >= 3 && prob(40))
		new /obj/effect/temp_visual/minotaur_fury_zone/strong(zone_turf)
	else
		new /obj/effect/temp_visual/minotaur_fury_zone(zone_turf)

// ============================================================
// GROUND SLAM — timer-based, no sleep()
// ============================================================

/datum/ai_behavior/minotaur_ground_slam
	action_cooldown = 4 SECONDS

/datum/ai_behavior/minotaur_ground_slam/perform(delta_time, datum/ai_controller/controller)
	. = ..()
	var/mob/living/simple_animal/hostile/retaliate/minotaur/boss = controller.pawn
	if(!istype(boss) || boss.stat != CONSCIOUS)
		finish_action(controller, FALSE)
		return

	controller.set_blackboard_key(BB_MINOTAUR_SLAM_COOLDOWN, world.time + 20 SECONDS)
	boss.visible_message("<span class='danger'>[boss] raises its fists high into the air!</span>")
	playsound(boss, 'sound/combat/hits/kick/stomp.ogg', 50, TRUE)

	addtimer(CALLBACK(src, PROC_REF(do_slam), controller), 1.5 SECONDS)

/datum/ai_behavior/minotaur_ground_slam/proc/do_slam(datum/ai_controller/controller)
	var/mob/living/simple_animal/hostile/retaliate/minotaur/boss = controller.pawn
	if(!istype(boss))
		finish_action(controller, FALSE)
		return

	boss.visible_message("<span class='danger'>[boss] slams the ground with tremendous force!</span>")
	playsound(boss, 'sound/misc/explode/explosionfar (1).ogg', 50, TRUE)

	new /obj/effect/temp_visual/minotaur_slam(get_turf(boss))

	// Shockwave rings via timers
	for(var/i in 1 to 5)
		addtimer(CALLBACK(src, PROC_REF(shockwave_effect), controller, i), i * 3)

	finish_action(controller, TRUE)

/datum/ai_behavior/minotaur_ground_slam/proc/shockwave_effect(datum/ai_controller/controller, radius)
	var/mob/living/simple_animal/hostile/retaliate/minotaur/boss = controller.pawn
	if(!istype(boss))
		return

	for(var/turf/T in orange(radius, boss))
		if(prob(20))
			new /obj/effect/temp_visual/minotaur_impact(T)

	for(var/mob/living/L in range(radius, boss))
		if(L != boss && !L.faction_check_mob(boss))
			var/distance = get_dist(boss, L)
			var/damage = 30 - (distance * 5)
			if(damage > 0)
				L.adjustBruteLoss(damage)

			if(distance <= 3)
				L.Knockdown(3 SECONDS - (distance * 0.5 SECONDS))

			var/throw_dir = get_dir(boss, L)
			var/throw_strength = 1
			if(radius == 3)
				throw_strength = 3
			L.throw_at(get_edge_target_turf(L, throw_dir), throw_strength, 1)
