/// Minotaur enrage subtree — handles rage buildup, phase transitions, berserk targeting, and stat scaling.
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

	// --- Berserk mode activation at 50% HP ---
	if(health_percent <= 0.5 && !controller.blackboard[BB_MINOTAUR_BERSERK])
		controller.set_blackboard_key(BB_MINOTAUR_BERSERK, TRUE)
		boss.visible_message("<span class='danger'>[boss] enters a berserk frenzy, its eyes locked on [target]!</span>")
		playsound(boss, 'sound/misc/explode/explosionfar (1).ogg', 40, TRUE)

	// --- Berserk targeting scan ---
	if(controller.blackboard[BB_MINOTAUR_BERSERK] && ishuman(target))
		var/plan_target_ref = controller.blackboard[BB_MINOTAUR_PLAN_TARGET]
		var/current_plan = controller.blackboard[BB_MINOTAUR_COMBAT_PLAN]

		// Re-evaluate if target changed, no plan, or wound goal reached
		if(plan_target_ref != target || !current_plan)
			_berserk_scan_target(controller, boss, target)
		else if(current_plan == "wounds")
			// After 2-3 wounds inflicted, switch to artery
			var/wounds_done = controller.blackboard[BB_MINOTAUR_WOUNDS_INFLICTED]
			if(wounds_done >= 2)
				controller.set_blackboard_key(BB_MINOTAUR_COMBAT_PLAN, "artery")
				controller.set_blackboard_key(BB_MINOTAUR_WOUNDS_INFLICTED, 0)
				// Find best artery zone
				_pick_artery_zone(controller, boss, target)

	// --- Queue enrage tick behavior (runs alongside other behaviors) ---
	controller.queue_behavior(/datum/ai_behavior/minotaur_enrage_tick)

/// Berserk scan — evaluates target and decides combat plan.
/// Priority: skull fracture > artery > wounds
/datum/ai_planning_subtree/minotaur_enrage/proc/_berserk_scan_target(datum/ai_controller/controller, mob/living/simple_animal/hostile/retaliate/minotaur/boss, mob/living/carbon/human/target)
	if(!istype(target))
		return

	controller.set_blackboard_key(BB_MINOTAUR_PLAN_TARGET, target)
	controller.set_blackboard_key(BB_MINOTAUR_WOUNDS_INFLICTED, 0)

	// Determine what crits our bclass can do
	var/datum/intent/current_intent = boss.a_intent
	var/bclass = current_intent?.blade_class
	var/can_fracture = bclass ? (bclass in GLOB.fracture_bclasses) : FALSE
	var/can_artery = bclass ? (bclass in GLOB.artery_bclasses) : FALSE

	// Evaluate head armor for skull fracture
	var/head_armor_rating = _get_zone_armor(target, BODY_ZONE_HEAD, bclass)
	var/head_exposed = (head_armor_rating < 15)

	// Evaluate all zones for artery/wound potential
	var/best_artery_zone = null
	var/best_artery_rating = INFINITY
	var/best_wound_zone = null
	var/best_wound_rating = INFINITY

	for(var/obj/item/bodypart/part in target.bodyparts)
		if(!part)
			continue
		var/zone = part.body_zone
		var/armor_val = _get_zone_armor(target, zone, bclass)

		// Track best zone for artery (lowest armor)
		if(can_artery && armor_val < best_artery_rating)
			best_artery_rating = armor_val
			best_artery_zone = zone

		// Track best zone for wound stacking (lowest armor)
		if(armor_val < best_wound_rating)
			best_wound_rating = armor_val
			best_wound_zone = zone

	// --- Decision tree ---
	// Priority 1: Skull fracture — if we can fracture and head is exposed/weak
	if(can_fracture && head_exposed)
		controller.set_blackboard_key(BB_MINOTAUR_COMBAT_PLAN, "fracture")
		controller.set_blackboard_key(BB_MINOTAUR_PLAN_ZONE, BODY_ZONE_HEAD)
		return

	// Priority 2: Artery — if we can artery and there's a weak zone
	if(can_artery && best_artery_zone && best_artery_rating < 30)
		controller.set_blackboard_key(BB_MINOTAUR_COMBAT_PLAN, "artery")
		controller.set_blackboard_key(BB_MINOTAUR_PLAN_ZONE, best_artery_zone)
		return

	// Priority 3: Compare fracture vs artery vs wounds based on what's faster
	if(can_fracture)
		// Check if head armor is beatable (even if not fully exposed)
		if(head_armor_rating < 30)
			controller.set_blackboard_key(BB_MINOTAUR_COMBAT_PLAN, "fracture")
			controller.set_blackboard_key(BB_MINOTAUR_PLAN_ZONE, BODY_ZONE_HEAD)
			return

	// Fallback: stack wounds on weakest zone, then switch to artery
	if(best_wound_zone)
		controller.set_blackboard_key(BB_MINOTAUR_COMBAT_PLAN, "wounds")
		controller.set_blackboard_key(BB_MINOTAUR_PLAN_ZONE, best_wound_zone)
		return

	// No plan possible — just hit chest
	controller.set_blackboard_key(BB_MINOTAUR_COMBAT_PLAN, null)
	controller.set_blackboard_key(BB_MINOTAUR_PLAN_ZONE, null)

/// Pick the best zone for artery based on existing damage and armor.
/datum/ai_planning_subtree/minotaur_enrage/proc/_pick_artery_zone(datum/ai_controller/controller, mob/living/simple_animal/hostile/retaliate/minotaur/boss, mob/living/carbon/human/target)
	if(!istype(target))
		return

	var/datum/intent/current_intent = boss.a_intent
	var/bclass = current_intent?.blade_class

	var/best_zone = null
	var/best_score = -INFINITY

	for(var/obj/item/bodypart/part in target.bodyparts)
		if(!part)
			continue
		var/zone = part.body_zone
		var/armor_val = _get_zone_armor(target, zone, bclass)

		// Score = existing damage (higher = closer to artery threshold) minus armor
		var/score = (part.brute_dam + part.burn_dam) - armor_val
		if(score > best_score)
			best_score = score
			best_zone = zone

	if(best_zone)
		controller.set_blackboard_key(BB_MINOTAUR_PLAN_ZONE, best_zone)

/// Get armor rating for a specific zone against our blade class.
/datum/ai_planning_subtree/minotaur_enrage/proc/_get_zone_armor(mob/living/carbon/human/target, zone, bclass)
	if(!istype(target))
		return 0

	var/armor_type = bclass ? bclass_to_armor_rating(bclass) : "blunt"

	// Check worn items that cover this zone
	var/best_rating = 0
	var/list/slots_to_check = list()

	switch(zone)
		if(BODY_ZONE_HEAD)
			slots_to_check = list(ITEM_SLOT_HEAD)
		if(BODY_ZONE_CHEST)
			slots_to_check = list(ITEM_SLOT_ARMOR, ITEM_SLOT_SHIRT)
		if(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
			slots_to_check = list(ITEM_SLOT_ARMOR, ITEM_SLOT_GLOVES)
		if(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
			slots_to_check = list(ITEM_SLOT_PANTS, ITEM_SLOT_SHOES)

	for(var/slot in slots_to_check)
		var/obj/item/worn = target.get_item_by_slot(slot)
		if(worn?.armor)
			var/rating = worn.armor.getRating(armor_type)
			if(rating > best_rating)
				best_rating = rating

	return best_rating

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
