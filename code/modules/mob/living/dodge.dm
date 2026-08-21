
/mob/living/proc/get_dodge_recharge_time()
	var/speed = GET_MOB_ATTRIBUTE_VALUE(src, STAT_SPEED)
	var/recharge_time = DODGE_RECHARGE_BASE - ((speed - 10) * 0.5 SECONDS)
	if(HAS_TRAIT(src, TRAIT_DODGEEXPERT))
		recharge_time *= 0.75
	return clamp(round(recharge_time), DODGE_RECHARGE_MIN, DODGE_RECHARGE_MAX)

/mob/living/proc/get_manual_dodge_distance()
	var/athletics = GET_MOB_SKILL_VALUE_OLD(src, /datum/attribute/skill/misc/athletics)
	var/mobility_score = GET_MOB_ATTRIBUTE_VALUE(src, STAT_SPEED) + athletics
	if(HAS_TRAIT(src, TRAIT_DODGEEXPERT))
		mobility_score += 2

	var/dodge_distance = 1
	if(mobility_score >= DODGE_DISTANCE_TWO_THRESHOLD)
		dodge_distance = 2
	if(mobility_score >= DODGE_DISTANCE_THREE_THRESHOLD)
		dodge_distance = 3

	if(ishuman(src))
		var/mob/living/carbon/human/human = src
		switch(human.worn_armor_class)
			if(AC_MEDIUM)
				dodge_distance = min(dodge_distance, 2)
			if(AC_HEAVY)
				dodge_distance = 1
	return dodge_distance

/mob/living/proc/get_manual_dodge_stamina_cost()
	var/speed = GET_MOB_ATTRIBUTE_VALUE(src, STAT_SPEED)
	var/stamina_cost = clamp(DODGE_STAMINA_BASE - (speed - 10), DODGE_STAMINA_MIN, DODGE_STAMINA_MAX)
	if(HAS_TRAIT(src, TRAIT_DODGEEXPERT))
		stamina_cost -= 2

	if(ishuman(src))
		var/mob/living/carbon/human/human = src
		stamina_cost += CEILING(human.getPainLoss() / 50, 1)
		switch(human.worn_armor_class)
			if(AC_LIGHT)
				stamina_cost += 3
			if(AC_MEDIUM)
				stamina_cost += 7
			if(AC_HEAVY)
				stamina_cost += 12

	stamina_cost -= get_tempo_bonus(TEMPO_TAG_STAMLOSS_DODGE)
	return clamp(stamina_cost, DODGE_STAMINA_MIN, DODGE_STAMINA_MAX)

/mob/living/proc/get_manual_dodge_grace_time()
	var/athletics = GET_MOB_SKILL_VALUE_OLD(src, /datum/attribute/skill/misc/athletics)
	var/grace_time = DODGE_GRACE_MIN
	grace_time += floor((GET_MOB_ATTRIBUTE_VALUE(src, STAT_SPEED) - 8) / 2)
	grace_time += floor(athletics / 2)
	if(HAS_TRAIT(src, TRAIT_DODGEEXPERT))
		grace_time += 1
	return clamp(grace_time, DODGE_GRACE_MIN, DODGE_GRACE_MAX)

/mob/living/proc/get_manual_dodge_success_chance()
	if(HAS_TRAIT(src, TRAIT_EVASIVE))
		return 100

	var/athletics = GET_MOB_SKILL_VALUE_OLD(src, /datum/attribute/skill/misc/athletics)
	var/success_chance = 55 + (GET_MOB_ATTRIBUTE_VALUE(src, STAT_SPEED) * 2) + (athletics * 8)
	if(HAS_TRAIT(src, TRAIT_DODGEEXPERT))
		success_chance += 15
	return clamp(round(success_chance), 20, 100)

/mob/living/proc/get_manual_dodge_destination(travel_direction, dodge_distance)
	var/turf/current_turf = get_turf(src)
	var/turf/last_safe_turf
	for(var/step_number in 1 to dodge_distance)
		var/turf/next_turf = get_step(current_turf, travel_direction)
		if(!is_valid_dodge_turf(next_turf))
			break
		last_safe_turf = next_turf
		current_turf = next_turf
	return last_safe_turf

/mob/living/proc/can_manual_dodge()
	if(!client || !cmode)
		return FALSE
	if(!candodge || HAS_TRAIT(src, TRAIT_UNDODGING) || HAS_TRAIT(src, TRAIT_IMMOBILIZED))
		return FALSE
	if(stat || incapacitated() || body_position == LYING_DOWN || !(mobility_flags & MOBILITY_STAND) || throwing)
		return FALSE
	if(pulling || pulledby || buckled)
		return FALSE
	if(get_num_legs() < 2 || IsOffBalanced())
		return FALSE
	if(has_status_effect(/datum/status_effect/debuff/exposed) || has_status_effect(/datum/status_effect/debuff/vulnerable))
		return FALSE
	var/turf/current_turf = get_turf(src)
	if(!current_turf || istype(current_turf, /turf/open/water))
		return FALSE
	if(ishuman(src))
		var/mob/living/carbon/human/human = src
		if(human.legcuffed || human.encumbrance >= ENCUMBRANCE_HEAVY)
			return FALSE
	return TRUE

/mob/living/proc/update_dodge_charge_hud()
	var/atom/movable/screen/cmode/combat_mode_button = hud_used?.cmode_button
	combat_mode_button?.update_dodge_charges()

/mob/living/proc/start_dodge_charge_recharge()
	if(dodge_charge_timer || dodge_charges >= DODGE_CHARGE_MAX)
		return
	dodge_charge_timer = addtimer(CALLBACK(src, PROC_REF(restore_dodge_charge)), get_dodge_recharge_time(), TIMER_STOPPABLE)

/mob/living/proc/restore_dodge_charge()
	dodge_charge_timer = null
	if(dodge_charges >= DODGE_CHARGE_MAX)
		return
	dodge_charges += 1
	update_dodge_charge_hud()
	start_dodge_charge_recharge()

/mob/living/proc/use_dodge_charge()
	if(dodge_charges <= 0)
		return FALSE
	dodge_charges -= 1
	update_dodge_charge_hud()
	start_dodge_charge_recharge()
	return TRUE

/mob/living/proc/clear_dodge_grace()
	dodge_grace_available = FALSE
	dodge_grace_until = 0

/mob/living/proc/has_dodge_grace()
	if(!dodge_grace_available || !cmode)
		return FALSE
	if(world.time > dodge_grace_until)
		clear_dodge_grace()
		return FALSE
	return TRUE

/mob/living/proc/consume_dodge_grace(datum/intent/intenty, mob/living/user)
	if(!has_dodge_grace())
		return FALSE
	if(!candodge || HAS_TRAIT(src, TRAIT_UNDODGING))
		return FALSE
	if(intenty && !intenty.candodge)
		return FALSE

	clear_dodge_grace()
	flash_fullscreen("blackflash2")
	visible_message(span_warning("<b>[src]</b> slips clear of [user]'s attack!"), span_notice("I evade [user]'s attack!"))
	if(user.used_intent)
		user.aftermiss()
	if(mind && user.mind)
		var/attacking_item = user.get_active_held_item()
		var/intent_name = intenty?.name ? intenty.name : "unknown"
		log_defense(src, user, "dodged", attacking_atom = attacking_item, addition = "(INTENT:[uppertext(intent_name)])")
	if(client)
		record_round_statistic(STATS_DODGES)
	return TRUE

/mob/living/proc/dodge_projectile(obj/projectile/projectile)
	if(!has_dodge_grace() || !projectile.dodgeable || !candodge || HAS_TRAIT(src, TRAIT_UNDODGING))
		return FALSE
	if(projectile.original == src && projectile.firer == src)
		return FALSE

	clear_dodge_grace()
	flash_fullscreen("blackflash2")
	visible_message(span_warning("<b>[src]</b> slips clear of [projectile]!"), span_notice("I evade [projectile]!"))
	if(client)
		record_round_statistic(STATS_DODGES)
	return TRUE

/mob/living/proc/try_manual_dodge(travel_direction)
	if(!cmode)
		balloon_alert(src, "combat mode required")
		return FALSE
	if(!can_manual_dodge())
		balloon_alert(src, "cannot dodge")
		return FALSE
	if(dodge_charges <= 0)
		balloon_alert(src, "no dodge charges")
		return FALSE

	if(!travel_direction)
		var/facing = angle2dir_cardinal(dir2angle(dir))
		travel_direction = REVERSE_DIR(facing)

	var/dodge_distance = get_manual_dodge_distance()
	var/turf/target_turf = get_manual_dodge_destination(travel_direction, dodge_distance)
	if(!target_turf)
		balloon_alert(src, "nowhere to dodge")
		return FALSE

	var/stamina_cost = get_manual_dodge_stamina_cost()
	if(stamina + stamina_cost >= maximum_stamina)
		balloon_alert(src, "too tired to dodge")
		return FALSE
	if(!adjust_stamina(stamina_cost))
		balloon_alert(src, "too tired to dodge")
		return FALSE
	if(!use_dodge_charge())
		return FALSE

	var/success_chance = get_manual_dodge_success_chance()
	if(!prob(success_chance))
		visible_message(span_warning("<b>[src]</b> stumbles while trying to dodge!"), span_warning("I fumble my dodge!"))
		return TRUE

	stop_attack()
	changeNext_move(CLICK_CD_FAST)
	last_dodge = world.time
	dodge_grace_available = TRUE
	dodge_grace_until = world.time + get_manual_dodge_grace_time()
	playsound(src, dodge_sound, 100, FALSE)
	visible_message(span_warning("<b>[src]</b> dodges away!"), span_notice("I dodge away!"))
	throw_at(target_turf, get_dist(src, target_turf), 1, src, spin = FALSE)
	return TRUE

/mob/living/proc/get_dodging_score(modifier = 0)
	var/basic_speed = GET_MOB_ATTRIBUTE_VALUE(src, STAT_SPEED)
	var/current_encumbrance = encumbrance
	if(!HAS_TRAIT(src, TRAIT_DODGEEXPERT) && current_encumbrance > ENCUMBRANCE_NONE)
		current_encumbrance = min(ENCUMBRANCE_EXTREME, CEILING(current_encumbrance * 1.5, 1))
	var/encumbrance_penalty = 0
	switch(current_encumbrance)
		if(ENCUMBRANCE_LIGHT)
			encumbrance_penalty = 1
		if(ENCUMBRANCE_MEDIUM)
			encumbrance_penalty = 2
		if(ENCUMBRANCE_HEAVY)
			encumbrance_penalty = 3
		if(ENCUMBRANCE_EXTREME)
			encumbrance_penalty = 4

	var/stun_penalty = 0
	if(incapacitated())
		stun_penalty = 4
	if(cmode && (d_intent == INTENT_DODGE))
		modifier += 2
	return floor(max(0, 3 + basic_speed + modifier - encumbrance_penalty - stun_penalty - dodging_penalty))

/mob/living/proc/update_dodging_penalty(incoming = 0, duration = DODGING_PENALTY_COOLDOWN_DURATION)
	//use remove_dodging_penalty() you idiot
	if(HAS_TRAIT(src, TRAIT_DODGEEXPERT))
		duration *= 0.5

	if(!incoming || !duration)
		return
	if(dodging_penalty_timer)
		deltimer(dodging_penalty_timer)
		dodging_penalty_timer = null
	//add incoming modification
	dodging_penalty += incoming
	dodging_penalty_timer = addtimer(CALLBACK(src, PROC_REF(remove_dodging_penalty)), duration, TIMER_STOPPABLE)

/mob/living/proc/remove_dodging_penalty()
	dodging_penalty = 0
	if(dodging_penalty_timer)
		deltimer(dodging_penalty_timer)
	dodging_penalty_timer = null

/**
 * Attempt to dodge an attack
 * @param datum/intent/intenty The intent used for the attack
 * @param mob/living/user The attacker
 * @return TRUE if dodge successful, FALSE otherwise
 */
/mob/living/proc/attempt_dodge(datum/intent/intenty, mob/living/user, can_dodge_see = TRUE)
	if(!candodge)
		return FALSE
	if(intenty && !intenty.candodge)
		return FALSE
	if(loc == user.loc)
		return FALSE
	if(incapacitated())
		return FALSE

	if(pulling)
		return FALSE

	if(has_status_effect(/datum/status_effect/debuff/exposed))
		return FALSE
	if(has_status_effect(/datum/status_effect/debuff/vulnerable))
		return FALSE
	if(world.time < last_dodge + dodgetime && !istype(rmb_intent, /datum/rmb_intent/riposte))
		return FALSE

	var/list/dirry = calculate_dodge_directions(user)
	var/turf/turfy = find_dodge_turf(dirry)

	//do_dodge applies the blind modifier internally
	if(!do_dodge(user, turfy, can_dodge_see))
		return FALSE

	flash_fullscreen("blackflash2")
	user.aftermiss()
	var/attacking_item = user.get_active_held_item()
	if(!(!src.mind || !user.mind))
		log_defense(src, user, "dodged", attacking_atom = attacking_item,
					addition = "(INTENT:[uppertext(user.used_intent.name)])")
	if(client)
		record_round_statistic(STATS_DODGES)
	return TRUE

/**
 * Handles dodge attempts by the mob
 * @param mob/living/user The attacker
 * @param turf/target_turf The turf to dodge to
 * @return TRUE if dodge successful, FALSE otherwise
 */
/mob/living/proc/do_dodge(mob/living/user, turf/target_turf, can_dodge_see)
	if(dodgecd || stamina >= maximum_stamina || body_position == LYING_DOWN)
		return FALSE

	if(!is_valid_dodge_turf(target_turf))
		to_chat(src, span_boldwarning("There's nowhere to dodge to!"))
		return FALSE

	var/drained = 7
	var/dodge_speed = floor(GET_MOB_ATTRIBUTE_VALUE(src, STAT_SPEED) / 2)

	// fast attackers raise the threshold (mirror of parry system)
	// STAT_SPEED on 0-~30 range; divide by 5 for ~0-6 opposition impact
	var/attacker_opposition = floor(GET_MOB_ATTRIBUTE_VALUE(user, STAT_SPEED) / 5)

	if(istype(src, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = src
		switch(H.worn_armor_class)
			if(AC_LIGHT)
				dodge_speed -= 10
				drained += 3
			if(AC_MEDIUM)
				dodge_speed = floor(dodge_speed * 0.5)
				drained += 7
				attacker_opposition += 2  // armor makes you easier to hit
			if(AC_HEAVY)
				dodge_speed = floor(dodge_speed * 0.25)
				drained += 12
				attacker_opposition += 4  // heavy armor tanks dodge chance

		var/time_since_last = world.time - last_dodge
		if(time_since_last < 2 SECONDS)
			drained += 5

		if((H.encumbrance >= ENCUMBRANCE_HEAVY) || H.legcuffed)
			H.Knockdown(1)
			return FALSE

		drained = max(drained, 5)
		drained = max(drained - get_tempo_bonus(TEMPO_TAG_STAMLOSS_DODGE), 1)

		if(stamina + drained >= maximum_stamina)
			to_chat(src, span_warning("I'm too tired to dodge!"))
			return FALSE
		if(!H.adjust_stamina(drained))
			to_chat(src, span_warning("I'm too tired to dodge!"))
			return FALSE

	var/dodge_modifier = calculate_dodge_score(user)

	if(!can_dodge_see)
		dodge_modifier -= 3

	var/dodge_score = get_dodging_score(dodge_modifier - attacker_opposition)

	var/attacker_dualwielding = user.dual_wielding_check()
	var/defender_dualwielding = dual_wielding_check()

	//mirror parry system here cause lazy
	var/effective_score = dodge_score
	if(attacker_dualwielding && !defender_dualwielding)
		effective_score = max(0, dodge_score - 2)

	if(client?.prefs.showrolls)
		var/text = "Roll to dodge... (score: [effective_score])"
		if(attacker_dualwielding)
			if(defender_dualwielding)
				text += " Dual wield cancels out."
			else
				text += " Disadvantage! (score: [effective_score])"
		to_chat(src, span_info("[text]"))

	if(user.client?.prefs.showrolls && attacker_dualwielding)
		var/attacker_feedback = "Attacking with advantage."
		if(defender_dualwielding)
			attacker_feedback += " Cancelled out!"
		to_chat(user, span_info("[attacker_feedback]"))

	var/roll_result = diceroll(effective_score, context = DICE_CONTEXT_PHYSICAL)

	if(roll_result == DICE_FAILURE || roll_result == DICE_CRIT_FAILURE)
		if(roll_result == DICE_CRIT_FAILURE)
			to_chat(src, span_warning("I completely fumbled my dodge!"))
		return FALSE

	update_dodging_penalty(DODGING_PENALTY, DODGING_PENALTY_COOLDOWN_DURATION)
	try_dodge_to(user, target_turf, dodge_speed)

	if(roll_result == DICE_CRIT_SUCCESS)
		to_chat(src, span_notice("A perfectly timed dodge!"))

	last_dodge = world.time
	changeNext_def(dodgetime + DEFENSE_CD_BUILDUP) // consecutive dodges get slower (TA buildup)
	return TRUE

/**
 * Check if a turf is valid for dodging into
 * @param turf/target_turf The turf to check
 * @return TRUE if valid, FALSE otherwise
 */
/mob/living/proc/is_valid_dodge_turf(turf/target_turf)
	if(!target_turf || !target_turf.can_traverse_safely(src))
		return FALSE
	if(target_turf.is_blocked_turf(exclude_mobs = FALSE, source_atom = src))
		return FALSE
	return TRUE

/**
 * Calculate the dodge score based on attacker and defender stats
 * @param mob/living/user The attacker
 * @return The calculated dodge score
 */
/mob/living/proc/calculate_dodge_score(mob/living/user)
	if(HAS_TRAIT(src, TRAIT_EVASIVE))
		return 99  // Effectively uncappable score, handled as special case
	if(HAS_TRAIT(src, TRAIT_UNDODGING))
		return -99 // Effectively impossible score

	var/dodge_modifier = 0

	var/mob/living/defending_mob = src
	var/mob/living/carbon/human/attacking_human
	var/obj/item/attacking_item

	if(ishuman(user))
		attacking_human = user
		attacking_item = attacking_human?.used_intent?.get_master_item()

	//longer weapons are harder to dodge
	var/obj/item/defending_item = get_active_held_item()
	if(istype(defending_item, /obj/item/weapon))
		switch(defending_item.wlength)
			if(WLENGTH_NORMAL)
				dodge_modifier -= 1
			if(WLENGTH_LONG)
				dodge_modifier -= 2
			if(WLENGTH_GREAT)
				dodge_modifier -= 3
		dodge_modifier += floor(defending_item.wdodgebonus / 10)

	// Intent bonuses
	dodge_modifier += floor(used_intent?.idodgebonus / 10)
	dodge_modifier += floor(rmb_intent?.def_bonus / 10)

	if(user.attributes?.has_diceroll_modifier(/datum/diceroll_modifier/guidance))
		dodge_modifier -= 2
	if(user.attributes?.has_diceroll_modifier(/datum/diceroll_modifier/fervor))
		dodge_modifier -= 1

	//knowing how an attack works helps dodge it
	if(attacking_item)
		if(!attacking_item.associated_skill)
			dodge_modifier += 1  //slightly easier to read
		else
			// 0-60 skill / 10 = 0-6 modifier range
			dodge_modifier += floor(GET_MOB_SKILL_VALUE_RAW(defending_mob, attacking_item.associated_skill) / 7)

	// Unarmed vs unarmed, skill matchup
	if(user.used_intent.unarmed)
		dodge_modifier += floor(GET_MOB_SKILL_VALUE_RAW(defending_mob, /datum/attribute/skill/combat/unarmed) / 7)
		dodge_modifier -= floor(GET_MOB_SKILL_VALUE_RAW(user, /datum/attribute/skill/combat/unarmed) / 7)

	return dodge_modifier

/**
 * Execute the dodge movement
 * @param mob/living/user The attacker
 * @param turf/target_turf The destination turf
 * @param dodge_speed The speed of the dodge
 */
/mob/living/proc/try_dodge_to(mob/living/user, turf/target_turf, dodge_speed)
	dodgecd = TRUE
	dodge_speed = (11 - dodge_speed)

	playsound(src, 'sound/combat/dodge.ogg', 100, FALSE)
	throw_at(target_turf, 1, dodge_speed, src, FALSE)

	var/drained = GET_MOB_ATTRIBUTE_VALUE(src, STAT_SPEED) > 15 ? 0 : 5  // Just a proxy to determine if it was an "easy" dodge
	if(drained > 0)
		src.visible_message("<span class='warning'><b>[src]</b> dodges [user]'s attack!</span>")
	else
		src.visible_message("<span class='warning'><b>[src]</b> easily dodges [user]'s attack!</span>")

	dodgecd = FALSE

/**
 * Find a valid turf to dodge to
 * @param list/dirry List of directions to try
 * @return Valid turf or null
 */
/mob/living/proc/find_dodge_turf(list/dirry)
	var/turf/turfy
	for(var/x in shuffle(dirry.Copy())) {
		turfy = get_step(src, x)
		if(is_valid_dodge_turf(turfy))
			return turfy
	}
	return null

/**
 * Calculate possible dodge directions based on relative positions
 * @param mob/living/user The attacker
 * @return List of directions to try dodging
 */
/mob/living/proc/calculate_dodge_directions(mob/living/user)
	var/list/dirry = GLOB.cardinals.Copy()
	var/dx = x - user.x
	var/dy = y - user.y

	if(abs(dx) < abs(dy))
		if(dy > 0)
			dirry -= SOUTH
		else
			dirry -= NORTH

	else
		if(dx > 0)
			dirry -= WEST
		else
			dirry -= EAST

	return dirry
