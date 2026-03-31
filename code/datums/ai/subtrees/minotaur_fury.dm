/// Minotaur enrage subtree — handles rage buildup, phase transitions, and stat scaling.
/// Queues an enrage_tick behavior for actual stat mutation (subtree only plans).
/datum/ai_planning_subtree/minotaur_enrage

/datum/ai_planning_subtree/minotaur_enrage/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/simple_animal/hostile/retaliate/minotaur/boss = controller.pawn
	if(!istype(boss))
		return

	// Only build rage and transition phases while we have a target
	var/atom/target = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	if(QDELETED(target))
		return

	// --- Rage buildup ---
	var/current_rage = controller.blackboard[BB_MINOTAUR_RAGE_METER]
	var/rage_increase = delta_time * 2

	var/health_percent = boss.health / boss.maxHealth
	if(health_percent < 0.3)
		rage_increase *= 3
	else if(health_percent < 0.6)
		rage_increase *= 2

	controller.set_blackboard_key(BB_MINOTAUR_RAGE_METER, min(100, current_rage + rage_increase))

	// --- Phase transitions ---
	var/current_phase = controller.blackboard[BB_MINOTAUR_PHASE]
	if(health_percent < 0.3 && current_phase < 3)
		controller.set_blackboard_key(BB_MINOTAUR_PHASE, 3)
		boss.visible_message("<span class='danger'>[boss] lets out an earthshaking roar as blood seeps from its wounds!</span>")
		boss.playsound_local(get_turf(boss), 'sound/misc/explode/explosionfar (1).ogg', 50, TRUE)
		new /obj/effect/temp_visual/minotaur_rage(get_turf(boss))
		controller.set_blackboard_key(BB_MINOTAUR_ENRAGE_BONUS, 15)
	else if(health_percent < 0.6 && current_phase < 2)
		controller.set_blackboard_key(BB_MINOTAUR_PHASE, 2)
		boss.visible_message("<span class='warning'>[boss] stomps the ground in anger, its eyes burning with hatred!</span>")
		new /obj/effect/temp_visual/minotaur_rage(get_turf(boss))
		controller.set_blackboard_key(BB_MINOTAUR_ENRAGE_BONUS, 5)

	// --- Queue enrage tick behavior (runs alongside other behaviors) ---
	controller.queue_behavior(/datum/ai_behavior/minotaur_enrage_tick)

/// Behavior that applies enrage stat bonuses. Runs alongside other behaviors.
/datum/ai_behavior/minotaur_enrage_tick
	action_cooldown = 1 SECONDS
	behavior_flags = AI_BEHAVIOR_EXECUTE_ALONGSIDE | AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION

/datum/ai_behavior/minotaur_enrage_tick/perform(delta_time, datum/ai_controller/controller)
	. = ..()
	var/mob/living/simple_animal/hostile/retaliate/minotaur/boss = controller.pawn
	if(!istype(boss))
		finish_action(controller, FALSE)
		return

	var/enrage_bonus = controller.blackboard[BB_MINOTAUR_ENRAGE_BONUS]
	var/current_rage = controller.blackboard[BB_MINOTAUR_RAGE_METER]
	var/current_phase = controller.blackboard[BB_MINOTAUR_PHASE]

	// Calculate total bonus
	var/rage_factor = current_rage / 100
	var/phase_bonus = (current_phase - 1) * 5
	var/total_bonus = enrage_bonus + phase_bonus + (rage_factor * 10)

	// Apply damage scaling
	boss.melee_damage_lower = initial(boss.melee_damage_lower) + total_bonus
	boss.melee_damage_upper = initial(boss.melee_damage_upper) + total_bonus

	// Apply speed scaling (lower = faster)
	controller.movement_delay = max(4, initial(controller.movement_delay) - (total_bonus * 0.02))

	// Visual rage effects
	if(current_rage > 80)
		if(prob(15) && current_phase >= 2)
			new /obj/effect/temp_visual/minotaur_rage(get_turf(boss))
			playsound(boss, 'sound/misc/explode/explosionfar (1).ogg', 25, TRUE)
	else if(current_rage > 50)
		if(prob(8) && current_phase >= 2)
			new /obj/effect/temp_visual/minotaur_rage(get_turf(boss))

	// Phase 3: passive heal and fury zones
	if(current_phase == 3 && prob(5))
		boss.adjustHealth(-boss.maxHealth * 0.01)
		new /obj/effect/temp_visual/heal(get_turf(boss), "#FF0000")

		if(current_rage > 90 && prob(15))
			boss.visible_message("<span class='danger'>The air around [boss] ripples with heat!</span>")
			for(var/turf/T in range(1, boss))
				if(prob(70))
					new /obj/effect/temp_visual/minotaur_fury_zone(T)

	finish_action(controller, TRUE)
