// Agent NPC combat: answering attacks, a fight action on an escalation ladder, and DM-driven melee.

GLOBAL_LIST_INIT(agent_combat_ladder, list(AGENT_COMBAT_NONE, AGENT_COMBAT_BRAWL, AGENT_COMBAT_DOWNED, AGENT_COMBAT_LETHAL))
/// Granted by a profile's combat limits rather than ticked by hand.
GLOBAL_LIST_INIT(agent_combat_actions, list("fight", "stop"))

/// 0 for none up to 3 for no quarter, -1 for anything not on the ladder.
/proc/agent_combat_rank(level)
	return GLOB.agent_combat_ladder.Find(level) - 1

/proc/agent_combat_max(first, second)
	return agent_combat_rank(first) >= agent_combat_rank(second) ? first : second

/proc/agent_combat_min(first, second)
	return agent_combat_rank(first) <= agent_combat_rank(second) ? first : second

/// A level from untrusted data, or none.
/proc/agent_clean_combat_level(value)
	return (istext(value) && (value in GLOB.agent_combat_ladder)) ? value : AGENT_COMBAT_NONE

/// How badly beaten, 0 to 1. Carbon health ignores brute here, so damage is pooled as defeat pools it.
/proc/agent_combat_beaten(mob/living/who)
	if(!iscarbon(who))
		return who.maxHealth > 0 ? clamp(1 - (who.health / who.maxHealth), 0, 1) : 0
	var/pooled = who.getBruteLoss() + (who.getFireLoss() * DEFEAT_BURN_DAMAGE_WEIGHT) + who.getToxLoss() + who.getCloneLoss()
	return clamp(pooled / who.get_effective_defeat_threshold(), 0, 1)

/// Hurt enough that any fight is abandoned for running. Bleeding out counts as much as bruises.
/proc/agent_combat_too_hurt(mob/living/who)
	if(agent_combat_beaten(who) >= AGENT_COMBAT_FLEE_BEATEN)
		return TRUE
	var/mob/living/carbon/body = who
	if(!iscarbon(body) || (NOBLOOD in body.dna?.species?.species_traits))
		return FALSE
	return body.blood_volume < BLOOD_VOLUME_OKAY

/// What an attacker's violence earns back: fists for fists, the weapon ladder for weapons.
/proc/agent_combat_matching_level(mob/living/attacker)
	return isweapon(attacker.get_active_held_item()) ? AGENT_COMBAT_DOWNED : AGENT_COMBAT_BRAWL

/// Why a fight at this level against this target is over, or null while it goes on.
/proc/agent_combat_over_reason(mob/living/target, level)
	if(QDELETED(target) || !isliving(target))
		return "they are gone"
	if(target.stat == DEAD)
		return "they are dead"
	var/defeated = target.has_status_effect(/datum/status_effect/defeat_knockout)
	switch(level)
		if(AGENT_COMBAT_LETHAL)
			// The game will not let a defeated player die, so beating them further is only cruelty.
			return defeated ? "they are beaten and cannot be finished" : null
		if(AGENT_COMBAT_DOWNED)
			if(target.surrendering)
				return "they yielded"
			if(defeated || target.stat >= SOFT_CRIT)
				return "they are down"
			if(target.body_position == LYING_DOWN && target.incapacitated(IGNORE_GRAB))
				return "they are down"
			return null
		if(AGENT_COMBAT_BRAWL)
			if(target.surrendering)
				return "they yielded"
			if(defeated || target.stat >= SOFT_CRIT || target.body_position == LYING_DOWN)
				return "they went down"
			if(agent_combat_beaten(target) >= AGENT_BRAWL_STOP_BEATEN)
				return "they are beaten"
			return null
	return "there is no fight"

/// Put away whatever is held so a brawl stays a brawl: stowed where it fits, dropped where not.
/proc/agent_empty_hands(mob/living/carbon/human/pawn)
	var/static/list/stow_slots = list(ITEM_SLOT_BELT_L, ITEM_SLOT_BELT_R, ITEM_SLOT_BACK_L, ITEM_SLOT_BACK_R, ITEM_SLOT_BELT)
	for(var/obj/item/held in pawn.held_items)
		var/stowed = FALSE
		for(var/slot in stow_slots)
			if(!pawn.get_item_by_slot(slot) && pawn.equip_to_slot_if_possible(held, slot, disable_warning = TRUE))
				stowed = TRUE
				break
		if(!stowed)
			pawn.dropItemToGround(held)

/// Draw a weapon the NPC wears, unless it already holds one. Sheathed weapons stay out of reach.
/proc/agent_draw_weapon(mob/living/carbon/human/pawn)
	if(isweapon(pawn.get_active_held_item()))
		return TRUE
	if(pawn.get_active_held_item())
		pawn.swap_hand()
		if(isweapon(pawn.get_active_held_item()))
			return TRUE
		if(pawn.get_active_held_item())
			return FALSE
	for(var/obj/item/weapon/worn_weapon in pawn.get_equipped_items())
		if(pawn.temporarilyRemoveItemFromInventory(worn_weapon) && pawn.put_in_active_hand(worn_weapon))
			return TRUE
	return FALSE

/// Anyone living, visible and within chase range. The agent chose them, so no faction rules apply.
/datum/targetting_datum/agent_combat

/datum/targetting_datum/agent_combat/can_attack(mob/living/living_mob, atom/target)
	var/mob/living/victim = target
	if(!isliving(victim) || victim == living_mob || victim.stat == DEAD)
		return FALSE
	if(victim.status_flags & GODMODE)
		return FALSE
	if(get_dist(living_mob, victim) > AGENT_COMBAT_CHASE_RANGE)
		return FALSE
	return can_see(living_mob, victim, AGENT_COMBAT_CHASE_RANGE)

/// Never the ERP subdue path. How a fight goes is the ladder's business.
/datum/targetting_datum/agent_combat/should_disarm(mob/living/living_mob, atom/target)
	return FALSE

/// The humanoid melee, aimed at the agent's chosen target. A brawl swings fists and never picks up a weapon.
/datum/ai_behavior/basic_melee_attack/human_npc/agent

/datum/ai_behavior/basic_melee_attack/human_npc/agent/setup(datum/ai_controller/controller, target_key, targetting_datum_key, hiding_location_key)
	var/mob/living/carbon/human/pawn = controller.pawn
	if(!ishuman(pawn))
		return FALSE
	var/brawl = controller.blackboard[BB_AGENT_COMBAT_LEVEL] == AGENT_COMBAT_BRAWL
	if(!brawl)
		agent_draw_weapon(pawn)
	. = ..()
	if(. && brawl)
		agent_empty_hands(pawn)

/datum/ai_behavior/basic_melee_attack/human_npc/agent/perform(delta_time, datum/ai_controller/controller, target_key, targetting_datum_key, hiding_location_key)
	if(controller.blackboard[BB_AGENT_COMBAT_LEVEL] != AGENT_COMBAT_BRAWL)
		return ..()
	// Not the parent: it arms itself from any weapon lying within a tile.
	controller.behavior_cooldowns[src] = world.time + get_cooldown(controller)
	var/mob/living/carbon/human/pawn = controller.pawn
	var/mob/living/target = controller.blackboard[target_key]
	var/datum/targetting_datum/targetting = controller.blackboard[targetting_datum_key]
	if(!targetting?.can_engage_target(pawn, target))
		finish_action(controller, FALSE, target_key)
		return
	agent_empty_hands(pawn)
	if(!pawn.CanReach(target))
		finish_action(controller, FALSE, target_key)
		return
	if(pawn.next_move > world.time || pawn.incapacitated(IGNORE_GRAB))
		return
	pawn.face_atom(target)
	_choose_standard_attack_zone(pawn, target)
	_choose_reach_capable_intent(pawn, target)
	controller.ai_interact(target, TRUE, TRUE)
	if(pawn.next_click < world.time)
		pawn.next_click = world.time + (pawn.used_intent?.clickcd || CLICK_CD_MELEE)
		SEND_SIGNAL(pawn, COMSIG_MOB_BREAK_SNEAK)

/// Fight whoever the agent chose or answered. Below the reflexes that keep it alive, above its errands.
/datum/ai_planning_subtree/agent_combat

/datum/ai_planning_subtree/agent_combat/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	var/datum/ai_controller/agent_social/agent = controller
	if(!istype(agent) || !agent.in_combat())
		return
	var/reason = agent.combat_status_check()
	if(reason)
		agent.end_combat(reason)
		return
	agent.set_blackboard_key(BB_AGENT_COMBAT_SWING, agent.blackboard[BB_AGENT_COMBAT_TARGET])
	agent.queue_behavior(/datum/ai_behavior/basic_melee_attack/human_npc/agent, BB_AGENT_COMBAT_SWING, BB_AGENT_COMBAT_TARGETTING, BB_AGENT_COMBAT_HIDING)
	return SUBTREE_RETURN_FINISH_PLANNING

/datum/ai_controller/agent_social/proc/in_combat()
	return !isnull(blackboard[BB_AGENT_COMBAT_TARGET])

/datum/ai_controller/agent_social/proc/note_aggressor(mob/living/who)
	LAZYSET(aggressors, WEAKREF(who), world.time)

/// Did they lay hands on us lately? Then they started it, and the NPC's answer is theirs to have earned.
/datum/ai_controller/agent_social/proc/is_aggressor(mob/living/who)
	if(!who)
		return FALSE
	var/when = LAZYACCESS(aggressors, WEAKREF(who))
	return when && world.time <= when + AGENT_AGGRESSOR_MEMORY

/// How far this NPC may go against them: what it would start, or answer with if they started it.
/datum/ai_controller/agent_social/proc/combat_limit(mob/living/target)
	var/limit = profile ? agent_clean_combat_level(profile.combat_initiate) : AGENT_COMBAT_NONE
	if(is_aggressor(target))
		limit = agent_combat_max(limit, profile ? agent_clean_combat_level(profile.combat_retaliate) : AGENT_COMBAT_NONE)
	return limit

/// Why the model may not fight them at this level now, or null if it may.
/datum/ai_controller/agent_social/proc/combat_refusal(mob/living/target, level)
	var/rank = agent_combat_rank(level)
	if(rank <= 0)
		return "choose how hard to fight: brawl, until_downed or no_quarter"
	var/mob/living/living_pawn = pawn
	if(agent_combat_too_hurt(living_pawn))
		return "you are too badly hurt to fight"
	var/limit = combat_limit(target)
	if(agent_combat_rank(limit) <= 0)
		return is_aggressor(target) ? "you do not fight back" : "you do not start fights"
	if(rank > agent_combat_rank(limit))
		return "you would not go further than [limit] with them"
	var/current = (blackboard[BB_AGENT_COMBAT_TARGET] == target) ? blackboard[BB_AGENT_COMBAT_LEVEL] : AGENT_COMBAT_NONE
	var/current_rank = max(agent_combat_rank(current), 0)
	// Whoever started it may be met at any rung the limit allows. A stranger climbs the ladder.
	if(!is_aggressor(target) && rank > current_rank + 1)
		return current_rank ? "escalate one step at a time, from [current]" : "start with a brawl"
	if(rank > current_rank && current_rank && world.time < blackboard[BB_AGENT_COMBAT_SINCE] + AGENT_COMBAT_ESCALATION_DELAY)
		return "too soon to escalate further"
	return null

/// Begin or change a fight. The melee is DM's; the model only chooses who and how hard.
/datum/ai_controller/agent_social/proc/start_combat(mob/living/target, level, reason)
	var/changing = blackboard[BB_AGENT_COMBAT_TARGET] == target
	set_blackboard_key(BB_AGENT_COMBAT_TARGET, target)
	set_blackboard_key(BB_AGENT_COMBAT_LEVEL, level)
	set_blackboard_key(BB_AGENT_COMBAT_SINCE, world.time)
	clear_blackboard_key(BB_AGENT_COMBAT_LOST_AT)
	// A fight replaces running away and any errand; set first, so the errand reports a reflex took over.
	clear_threat()
	cancel_agent_objective()
	var/mob/living/living_pawn = pawn
	if(living_pawn.buckled && living_pawn.buckled == blackboard[BB_AGENT_SEAT])
		agent_execute_stand(living_pawn)
	log_combat(living_pawn, target, "agent NPC [changing ? "changed its fight to" : "started a fight:"] [level] ([reason])")
	SSagent_npc?.log_agent("[living_pawn] fights [target] at [level]: [reason]")
	return TRUE

/// End the fight. Reported to the model unless the model itself chose to stop.
/datum/ai_controller/agent_social/proc/end_combat(reason, report = TRUE)
	if(!in_combat() && !blackboard[BB_AGENT_COMBAT_LEVEL])
		return FALSE
	var/mob/living/target = blackboard[BB_AGENT_COMBAT_TARGET]
	var/level = blackboard[BB_AGENT_COMBAT_LEVEL]
	for(var/key in list(BB_AGENT_COMBAT_TARGET, BB_AGENT_COMBAT_LEVEL, BB_AGENT_COMBAT_SINCE, BB_AGENT_COMBAT_LOST_AT, BB_AGENT_COMBAT_SWING, BB_AGENT_COMBAT_HIDING))
		clear_blackboard_key(key)
	cancel_combat_behavior()
	SSagent_npc?.log_agent("[pawn] stops fighting [target || "someone"]: [reason]")
	if(report && binding && !QDELETED(binding))
		var/with = isliving(target) ? target.get_visible_name() : "someone"
		binding.mark_dirty("combat_ended", AGENT_EVENT_LOW, list("with" = with, "level" = level, "reason" = reason), replenish = FALSE)
	return TRUE

/// Finish a running swing now, so ending a fight never leaves the NPC mid-attack.
/datum/ai_controller/agent_social/proc/cancel_combat_behavior()
	for(var/datum/ai_behavior/current_behavior as anything in current_behaviors)
		if(!istype(current_behavior, /datum/ai_behavior/basic_melee_attack/human_npc/agent))
			continue
		var/list/arguments = list(src, FALSE)
		var/list/stored_arguments = behavior_args[current_behavior.type]
		if(stored_arguments)
			arguments += stored_arguments
		current_behavior.finish_action(arglist(arguments))

/// Why the current fight should stop now, or null. Checked every plan, so no fight outlives its reason.
/datum/ai_controller/agent_social/proc/combat_status_check()
	if(!binding || QDELETED(binding) || binding.state == AGENT_BINDING_DISABLED)
		return "you stood down"
	var/mob/living/target = blackboard[BB_AGENT_COMBAT_TARGET]
	var/reason = agent_combat_over_reason(target, blackboard[BB_AGENT_COMBAT_LEVEL])
	if(reason)
		return reason
	var/mob/living/living_pawn = pawn
	if(agent_combat_too_hurt(living_pawn))
		// Breaking off means running, so the flee reflex gets the attacker.
		set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, target)
		set_blackboard_key(BB_AGENT_FLEE_UNTIL, world.time + AGENT_FLEE_DURATION)
		return "you are badly hurt and break off"
	var/datum/targetting_datum/targetting = blackboard[BB_AGENT_COMBAT_TARGETTING]
	if(targetting?.can_attack(living_pawn, target))
		clear_blackboard_key(BB_AGENT_COMBAT_LOST_AT)
		return null
	if(!blackboard[BB_AGENT_COMBAT_LOST_AT])
		set_blackboard_key(BB_AGENT_COMBAT_LOST_AT, world.time)
		return null
	if(world.time > blackboard[BB_AGENT_COMBAT_LOST_AT] + AGENT_COMBAT_LOST_TIMEOUT)
		return "they got away"
	return null

/// Fight back instead of running, if the profile allows and the NPC is fit to. Returns the level, or null.
/datum/ai_controller/agent_social/proc/retaliate(mob/living/attacker)
	if(!binding || QDELETED(binding) || binding.state == AGENT_BINDING_DISABLED)
		return null
	var/limit = profile ? agent_clean_combat_level(profile.combat_retaliate) : AGENT_COMBAT_NONE
	if(agent_combat_rank(limit) <= 0)
		return null
	var/mob/living/living_pawn = pawn
	if(agent_combat_too_hurt(living_pawn))
		return null
	var/level = agent_combat_min(limit, agent_combat_matching_level(attacker))
	// Never softer than the fight already running with them.
	if(blackboard[BB_AGENT_COMBAT_TARGET] == attacker)
		level = agent_combat_max(level, blackboard[BB_AGENT_COMBAT_LEVEL])
	start_combat(attacker, level, "fighting back")
	return level
