/// Minotaur melee subtree — uses standard basic_melee_attack_subtree pattern.
/datum/ai_planning_subtree/basic_melee_attack_subtree/minotaur
	melee_attack_behavior = /datum/ai_behavior/basic_melee_attack/minotaur

/// Minotaur melee behavior — inherits from basic_melee_attack and adds phase-based bonuses.
/datum/ai_behavior/basic_melee_attack/minotaur
	action_cooldown = 0.2 SECONDS

/datum/ai_behavior/basic_melee_attack/minotaur/perform(delta_time, datum/ai_controller/controller, target_key, targetting_datum_key, hiding_location_key)
	. = ..()
	var/mob/living/simple_animal/hostile/retaliate/minotaur/boss = controller.pawn
	if(!istype(boss) || boss.stat != CONSCIOUS)
		return

	var/atom/target = controller.blackboard[target_key]
	if(QDELETED(target))
		return

	// Set defensive intent — axe variant parries, unarmed dodges
	if(locate(/datum/intent/simple/minotaur_axe) in boss.possible_a_intents)
		if(boss.d_intent != INTENT_PARRY)
			boss.d_intent = INTENT_PARRY
	else
		if(boss.d_intent != INTENT_DODGE)
			boss.d_intent = INTENT_DODGE

	var/current_phase = controller.blackboard[BB_MINOTAUR_PHASE]

	// Phase 2+: chance for knockback
	if(current_phase >= 2 && prob(30))
		if(ismob(target) && isturf(target.loc))
			var/mob/living/L = target
			var/throw_dir = get_dir(boss, L)
			L.throw_at(get_edge_target_turf(L, throw_dir), 1, 1)
			L.Knockdown(0.5 SECONDS)

	// Phase 3: chance for cleave hitting adjacent targets
	if(current_phase >= 3 && prob(20))
		for(var/mob/living/L in range(1, boss))
			if(L != boss && L != target && !L.faction_check_mob(boss))
				L.adjustBruteLoss(boss.melee_damage_lower / 2)
				to_chat(L, "<span class='danger'>[boss] cleaves you with its attack!</span>")
				new /obj/effect/temp_visual/minotaur_impact(get_turf(L))

	// Sidestep after attack, chance scales with phase
	if(prob(15 * current_phase) && isturf(boss.loc) && isturf(target.loc) && boss.stat != DEAD)
		var/target_dir = get_dir(boss, target)
		var/static/list/cardinal_sidestep_directions = list(-90, -45, 0, 45, 90)
		var/static/list/diagonal_sidestep_directions = list(-45, 0, 45)
		var/chosen_dir = 0

		if(target_dir & (target_dir - 1))
			chosen_dir = pick(diagonal_sidestep_directions)
		else
			chosen_dir = pick(cardinal_sidestep_directions)

		if(chosen_dir)
			chosen_dir = turn(target_dir, chosen_dir)
			boss.Move(get_step(boss, chosen_dir))
			boss.face_atom(target)
