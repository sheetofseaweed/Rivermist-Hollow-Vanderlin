// Combat: retaliation, the escalation ladder, fists-only brawls, and every way a fight must end. Added 2026-09-24.

/// A bound pawn whose profile fights back and starts fights as far as given.
/datum/unit_test/proc/agent_test_fighter(retaliate = AGENT_COMBAT_NONE, initiate = AGENT_COMBAT_NONE)
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	controller.profile.combat_retaliate = retaliate
	controller.profile.combat_initiate = initiate
	return pawn

/// Beat a mob this far towards defeat. Toxin pools like brute and, unlike brute, can be set directly.
/proc/agent_test_beat(mob/living/who, fraction)
	who.setToxLoss(who.get_effective_defeat_threshold() * fraction)

/// Put a mob back the way allocate() made it, after a test pokes its state.
/proc/agent_test_reset_mob(mob/living/who)
	who.stat = CONSCIOUS
	who.surrendering = FALSE
	who.setToxLoss(0)

// ------------------------------------------------------------------ the ladder

/datum/unit_test/agent_npc_combat_ladder

/datum/unit_test/agent_npc_combat_ladder/Run()
	TEST_ASSERT_EQUAL(agent_combat_rank(AGENT_COMBAT_NONE), 0, "None is the bottom of the ladder.")
	TEST_ASSERT_EQUAL(agent_combat_rank(AGENT_COMBAT_LETHAL), 3, "No quarter is the top.")
	TEST_ASSERT_EQUAL(agent_combat_rank("murder"), -1, "Anything off the ladder has no rank.")
	TEST_ASSERT_EQUAL(agent_combat_max(AGENT_COMBAT_BRAWL, AGENT_COMBAT_DOWNED), AGENT_COMBAT_DOWNED, "Max is the more violent.")
	TEST_ASSERT_EQUAL(agent_combat_min(AGENT_COMBAT_BRAWL, AGENT_COMBAT_DOWNED), AGENT_COMBAT_BRAWL, "Min is the less violent.")
	TEST_ASSERT_EQUAL(agent_clean_combat_level("murder"), AGENT_COMBAT_NONE, "An unknown level from a file must clean to none.")

/datum/unit_test/agent_npc_each_level_ends_its_own_way

/datum/unit_test/agent_npc_each_level_ends_its_own_way/Run()
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human/species/human/northern)

	var/brawl_fresh = agent_combat_over_reason(target, AGENT_COMBAT_BRAWL)
	agent_test_beat(target, 0.6)
	var/brawl_hurt = agent_combat_over_reason(target, AGENT_COMBAT_BRAWL)
	var/downed_hurt = agent_combat_over_reason(target, AGENT_COMBAT_DOWNED)
	agent_test_reset_mob(target)

	target.surrendering = TRUE
	var/brawl_yield = agent_combat_over_reason(target, AGENT_COMBAT_BRAWL)
	var/downed_yield = agent_combat_over_reason(target, AGENT_COMBAT_DOWNED)
	var/lethal_yield = agent_combat_over_reason(target, AGENT_COMBAT_LETHAL)
	agent_test_reset_mob(target)

	target.stat = SOFT_CRIT
	var/downed_crit = agent_combat_over_reason(target, AGENT_COMBAT_DOWNED)
	var/lethal_crit = agent_combat_over_reason(target, AGENT_COMBAT_LETHAL)
	target.stat = DEAD
	var/lethal_dead = agent_combat_over_reason(target, AGENT_COMBAT_LETHAL)
	agent_test_reset_mob(target)

	TEST_ASSERT_NULL(brawl_fresh, "A brawl with a fresh opponent goes on.")
	TEST_ASSERT_NOTNULL(brawl_hurt, "A brawl ends once they are half beaten.")
	TEST_ASSERT_NULL(downed_hurt, "Half beaten is not down; that fight goes on.")
	TEST_ASSERT_NOTNULL(brawl_yield, "A brawl ends when they yield.")
	TEST_ASSERT_NOTNULL(downed_yield, "Until-downed ends when they yield.")
	// That is what no quarter means. It is why a profile has to allow it explicitly.
	TEST_ASSERT_NULL(lethal_yield, "No quarter does not stop for a yield.")
	TEST_ASSERT_NOTNULL(downed_crit, "Until-downed ends in crit.")
	TEST_ASSERT_NULL(lethal_crit, "No quarter goes on past crit.")
	TEST_ASSERT_NOTNULL(lethal_dead, "Every fight ends at death.")

// --------------------------------------------------------------- retaliation

/datum/unit_test/agent_npc_pacifist_still_flees

/datum/unit_test/agent_npc_pacifist_still_flees/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_fighter()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human/species/human/northern)
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")

	controller.on_pawn_attacked(pawn, attacker, 10)
	var/fleeing_from = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	var/fighting = controller.in_combat()
	controller.clear_threat()
	agent_test_restore_subsystem(saved, controller.binding)

	TEST_ASSERT_EQUAL(fleeing_from, attacker, "A character that does not fight back must still run.")
	TEST_ASSERT(!fighting, "A character that does not fight back must not start a fight.")

/datum/unit_test/agent_npc_retaliation_matches_and_is_capped

/datum/unit_test/agent_npc_retaliation_matches_and_is_capped/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_fighter(retaliate = AGENT_COMBAT_DOWNED)
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human/species/human/northern)
	var/obj/item/weapon/knife/dagger/dagger = allocate(/obj/item/weapon/knife/dagger)
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")

	controller.on_pawn_attacked(pawn, attacker, 5)
	var/fist_level = controller.blackboard[BB_AGENT_COMBAT_LEVEL]
	var/fist_target = controller.blackboard[BB_AGENT_COMBAT_TARGET]
	var/fled = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	TEST_ASSERT(attacker.put_in_active_hand(dagger), "Setup failed: the attacker must hold the dagger.")
	controller.on_pawn_attacked(pawn, attacker, 15)
	var/blade_level = controller.blackboard[BB_AGENT_COMBAT_LEVEL]
	controller.end_combat("test", report = FALSE)

	controller.profile.combat_retaliate = AGENT_COMBAT_BRAWL
	controller.on_pawn_attacked(pawn, attacker, 15)
	var/capped_level = controller.blackboard[BB_AGENT_COMBAT_LEVEL]
	controller.end_combat("test", report = FALSE)
	agent_test_restore_subsystem(saved, controller.binding)

	TEST_ASSERT_EQUAL(fist_target, attacker, "Being struck must turn the NPC on the one who struck it.")
	TEST_ASSERT_NULL(fled, "Fighting back replaces running.")
	TEST_ASSERT_EQUAL(fist_level, AGENT_COMBAT_BRAWL, "Fists earn fists back.")
	TEST_ASSERT_EQUAL(blade_level, AGENT_COMBAT_DOWNED, "A blade earns weapons back.")
	TEST_ASSERT_EQUAL(capped_level, AGENT_COMBAT_BRAWL, "The profile's limit caps the answer, whatever the attacker used.")

/datum/unit_test/agent_npc_badly_hurt_npc_runs_instead

/datum/unit_test/agent_npc_badly_hurt_npc_runs_instead/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_fighter(retaliate = AGENT_COMBAT_LETHAL)
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human/species/human/northern)
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")

	agent_test_beat(pawn, 0.9)
	controller.on_pawn_attacked(pawn, attacker, 10)
	var/fighting = controller.in_combat()
	var/fleeing_from = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	controller.clear_threat()
	agent_test_reset_mob(pawn)
	agent_test_restore_subsystem(saved, controller.binding)

	TEST_ASSERT(!fighting, "A badly hurt NPC must not start trading blows, whatever its profile.")
	TEST_ASSERT_EQUAL(fleeing_from, attacker, "A badly hurt NPC must run.")

// ------------------------------------------------------------------ the ladder

/datum/unit_test/agent_npc_strangers_are_met_one_step_at_a_time

/datum/unit_test/agent_npc_strangers_are_met_one_step_at_a_time/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_fighter(initiate = AGENT_COMBAT_DOWNED)
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human/species/human/northern)
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")

	var/leap = controller.combat_refusal(stranger, AGENT_COMBAT_DOWNED)
	var/first_rung = controller.combat_refusal(stranger, AGENT_COMBAT_BRAWL)
	controller.start_combat(stranger, AGENT_COMBAT_BRAWL, "test")
	var/too_soon = controller.combat_refusal(stranger, AGENT_COMBAT_DOWNED)
	controller.set_blackboard_key(BB_AGENT_COMBAT_SINCE, world.time - AGENT_COMBAT_ESCALATION_DELAY - 1)
	var/in_time = controller.combat_refusal(stranger, AGENT_COMBAT_DOWNED)
	// From the top rung the limit allows, so the ladder would permit the next one and only the limit refuses.
	controller.start_combat(stranger, AGENT_COMBAT_DOWNED, "test")
	controller.set_blackboard_key(BB_AGENT_COMBAT_SINCE, world.time - AGENT_COMBAT_ESCALATION_DELAY - 1)
	var/over_limit = controller.combat_refusal(stranger, AGENT_COMBAT_LETHAL)
	controller.end_combat("test", report = FALSE)
	controller.profile.combat_initiate = AGENT_COMBAT_NONE
	var/pacifist = controller.combat_refusal(stranger, AGENT_COMBAT_BRAWL)
	agent_test_restore_subsystem(saved, controller.binding)

	TEST_ASSERT_NOTNULL(leap, "A fight with a stranger must start with a brawl.")
	TEST_ASSERT_NULL(first_rung, "A brawl is the first rung.")
	TEST_ASSERT_NOTNULL(too_soon, "Escalating the moment a brawl starts must wait.")
	TEST_ASSERT_NULL(in_time, "After the delay, the next rung is allowed.")
	TEST_ASSERT_NOTNULL(over_limit, "No rung above the profile's limit, ever.")
	TEST_ASSERT_NOTNULL(pacifist, "A character that does not start fights must be refused.")

/datum/unit_test/agent_npc_whoever_started_it_is_met_at_once

/datum/unit_test/agent_npc_whoever_started_it_is_met_at_once/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_fighter(retaliate = AGENT_COMBAT_DOWNED)
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/mob/living/carbon/human/brute = allocate(/mob/living/carbon/human/species/human/northern)
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human/species/human/northern)
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")

	controller.note_stimulus(AGENT_STIMULUS_SHOVED, brute)
	var/answer = controller.combat_refusal(brute, AGENT_COMBAT_DOWNED)
	var/unprovoked = controller.combat_refusal(stranger, AGENT_COMBAT_BRAWL)
	agent_test_restore_subsystem(saved, controller.binding)

	// Rough hands mean they started it. The answer may match their violence without climbing.
	TEST_ASSERT_NULL(answer, "Someone who laid hands on the NPC may be met at any rung of the retaliation limit.")
	TEST_ASSERT_NOTNULL(unprovoked, "The retaliation limit gives nothing against someone who did nothing.")

// ------------------------------------------------------------- the actions

/datum/unit_test/agent_npc_fight_and_stop_through_dispatch

/datum/unit_test/agent_npc_fight_and_stop_through_dispatch/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_fighter(initiate = AGENT_COMBAT_BRAWL)
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/agent_binding/binding = controller?.binding
	var/mob/living/carbon/human/person = allocate(/mob/living/carbon/human/species/human/northern)
	TEST_ASSERT_NOTNULL(binding, "Setup failed: the pawn must be bound.")

	var/person_handle = agent_test_handle_of(binding, pawn, person)
	SSagent_npc.dispatch_decision(binding, agent_test_decision(list("name" = "fight", "handle" = person_handle, "key" = AGENT_COMBAT_BRAWL)))
	var/fighting = controller.blackboard[BB_AGENT_COMBAT_TARGET]
	var/errands_blocked = !controller.reflex_guard_clear()
	binding.take_events()
	SSagent_npc.dispatch_decision(binding, agent_test_decision(list("name" = "stop")))
	var/still_fighting = controller.in_combat()
	var/list/ended = agent_test_events_named(binding.take_events(), "combat_ended")
	agent_test_restore_subsystem(saved, binding)

	TEST_ASSERT_EQUAL(fighting, person, "A permitted fight must begin.")
	TEST_ASSERT(errands_blocked, "A fight owns the NPC; errands must wait for it.")
	TEST_ASSERT(!still_fighting, "stop must end the fight.")
	TEST_ASSERT_EQUAL(length(ended), 0, "The model chose to stop; telling it so again wastes a decision.")

/datum/unit_test/agent_npc_fights_end_and_are_reported

/datum/unit_test/agent_npc_fights_end_and_are_reported/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_fighter(initiate = AGENT_COMBAT_BRAWL)
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/mob/living/carbon/human/person = allocate(/mob/living/carbon/human/species/human/northern)
	var/datum/ai_planning_subtree/agent_combat/subtree = new()
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")

	controller.start_combat(person, AGENT_COMBAT_BRAWL, "test")
	controller.binding.take_events()
	person.surrendering = TRUE
	subtree.SelectBehaviors(controller, 1)
	var/fighting_on = controller.in_combat()
	var/list/ended = agent_test_events_named(controller.binding.take_events(), "combat_ended")
	agent_test_reset_mob(person)

	controller.start_combat(person, AGENT_COMBAT_BRAWL, "test")
	agent_test_beat(pawn, 0.9)
	subtree.SelectBehaviors(controller, 1)
	var/fighting_hurt = controller.in_combat()
	var/fleeing_from = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	controller.clear_threat()
	agent_test_reset_mob(pawn)
	qdel(subtree)
	agent_test_restore_subsystem(saved, controller.binding)

	TEST_ASSERT(!fighting_on, "A brawl must end when they yield.")
	TEST_ASSERT_EQUAL(length(ended), 1, "The end of a fight the NPC did not stop must be reported, so it can react.")
	var/list/entry = ended[1]
	var/list/detail = entry["detail"]
	TEST_ASSERT_EQUAL(detail["reason"], "they yielded", "It must say why.")
	TEST_ASSERT(!fighting_hurt, "A badly hurt NPC must break off.")
	TEST_ASSERT_EQUAL(fleeing_from, person, "Breaking off means running from them.")

/datum/unit_test/agent_npc_kill_switch_ends_fights

/datum/unit_test/agent_npc_kill_switch_ends_fights/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_fighter(initiate = AGENT_COMBAT_BRAWL)
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/mob/living/carbon/human/person = allocate(/mob/living/carbon/human/species/human/northern)
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")

	controller.start_combat(person, AGENT_COMBAT_BRAWL, "test")
	SSagent_npc.disable_all("unit test")
	var/fighting = controller.in_combat()
	agent_test_restore_subsystem(saved, controller.binding)

	TEST_ASSERT(!fighting, "No agent-authorised fight may survive the kill switch.")

// ----------------------------------------------------------------- the melee

/datum/unit_test/agent_npc_brawl_keeps_to_fists

/datum/unit_test/agent_npc_brawl_keeps_to_fists/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_fighter(initiate = AGENT_COMBAT_BRAWL)
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/mob/living/carbon/human/person = allocate(/mob/living/carbon/human/species/human/northern)
	var/obj/item/natural/cloth/cloth = allocate(/obj/item/natural/cloth)
	var/obj/item/natural/feather/feather = allocate(/obj/item/natural/feather)
	var/obj/item/weapon/knife/dagger/dagger = allocate(/obj/item/weapon/knife/dagger)
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	TEST_ASSERT(pawn.put_in_active_hand(cloth), "Setup failed: the NPC must hold the cloth.")

	controller.start_combat(person, AGENT_COMBAT_BRAWL, "test")
	controller.set_blackboard_key(BB_AGENT_COMBAT_SWING, person)
	var/datum/ai_behavior/swing = GET_AI_BEHAVIOR(/datum/ai_behavior/basic_melee_attack/human_npc/agent)
	swing.setup(controller, BB_AGENT_COMBAT_SWING, BB_AGENT_COMBAT_TARGETTING, BB_AGENT_COMBAT_HIDING)
	var/list/held_at_setup = pawn.held_items.Copy()
	// Something picked up mid-fight must be put away again before the next swing.
	var/held_mid_fight = pawn.put_in_active_hand(feather)
	swing.perform(1, controller, BB_AGENT_COMBAT_SWING, BB_AGENT_COMBAT_TARGETTING, BB_AGENT_COMBAT_HIDING)
	var/list/held = pawn.held_items.Copy()
	var/dagger_loc = dagger.loc
	controller.end_combat("test", report = FALSE)
	agent_test_restore_subsystem(saved, controller.binding)

	TEST_ASSERT(!(cloth in held_at_setup), "A brawl must start with empty hands.")
	TEST_ASSERT(held_mid_fight, "Setup failed: the feather must be in hand before the swing.")
	// The humanoid melee arms itself from any weapon within a tile. A brawl must not.
	TEST_ASSERT(!(dagger in held), "A brawl must never pick up the weapon lying beside it.")
	TEST_ASSERT(!(feather in held), "Every swing of a brawl must be with empty hands.")
	TEST_ASSERT(isturf(dagger_loc), "The dagger must stay where it lay.")

/datum/unit_test/agent_npc_armed_fight_draws_a_worn_weapon

/datum/unit_test/agent_npc_armed_fight_draws_a_worn_weapon/Run()
	var/mob/living/carbon/human/pawn = allocate(/mob/living/carbon/human/species/human/northern)
	var/obj/item/weapon/knife/dagger/dagger = allocate(/obj/item/weapon/knife/dagger)
	var/obj/item/storage/belt/leather/belt = allocate(/obj/item/storage/belt/leather)
	TEST_ASSERT(pawn.equip_to_slot_if_possible(belt, ITEM_SLOT_BELT, disable_warning = TRUE, bypass_equip_delay_self = TRUE), "Setup failed: the belt must go on.")
	var/equipped = pawn.equip_to_slot_if_possible(dagger, ITEM_SLOT_BELT_L, disable_warning = TRUE, bypass_equip_delay_self = TRUE)
	if(!equipped)
		equipped = pawn.equip_to_slot_if_possible(dagger, ITEM_SLOT_BELT_R, disable_warning = TRUE, bypass_equip_delay_self = TRUE)
	TEST_ASSERT(equipped, "Setup failed: the dagger must be worn.")

	agent_draw_weapon(pawn)

	TEST_ASSERT_EQUAL(pawn.get_active_held_item(), dagger, "A fight with weapons must draw the weapon the NPC wears.")

// ----------------------------------------------------------------- profiles

/datum/unit_test/agent_npc_fighting_comes_from_the_combat_limits

/datum/unit_test/agent_npc_fighting_comes_from_the_combat_limits/Run()
	var/datum/agent_profile/villager = new /datum/agent_profile/villager()
	var/datum/agent_profile/guard = new /datum/agent_profile/guard()
	var/list/villager_actions = villager.to_payload()["permitted_actions"]
	var/list/guard_actions = guard.to_payload()["permitted_actions"]
	var/villager_fights = villager.permits("fight")
	var/guard_fights = guard.permits("fight")
	var/list/cleaned = agent_clean_profile_actions(list("say", "fight", "stop"))
	var/datum/agent_profile/rebuilt = agent_profile_from_payload(guard.to_payload())
	var/rebuilt_retaliate = rebuilt.combat_retaliate
	var/rebuilt_initiate = rebuilt.combat_initiate
	var/datum/agent_profile/copy = guard.clone()
	var/copy_initiate = copy.combat_initiate
	qdel(villager)
	qdel(guard)
	qdel(rebuilt)
	qdel(copy)

	TEST_ASSERT(!villager_fights, "A villager must not fight.")
	TEST_ASSERT(!("fight" in villager_actions), "The model must not be told a villager can fight.")
	TEST_ASSERT(guard_fights, "A guard's limits must grant fighting.")
	TEST_ASSERT(("fight" in guard_actions) && ("stop" in guard_actions), "The model must be told a guard can fight and stop.")
	// A hand-edited file must not arm a pacifist by listing the action.
	TEST_ASSERT(!("fight" in cleaned), "fight must never be stored as a ticked action.")
	TEST_ASSERT_EQUAL(rebuilt_retaliate, AGENT_COMBAT_DOWNED, "Combat limits must survive a save and load.")
	TEST_ASSERT_EQUAL(rebuilt_initiate, AGENT_COMBAT_DOWNED, "Combat limits must survive a save and load.")
	TEST_ASSERT_EQUAL(copy_initiate, AGENT_COMBAT_DOWNED, "A clone must carry the combat limits.")

/datum/unit_test/agent_npc_scene_shows_the_fight

/datum/unit_test/agent_npc_scene_shows_the_fight/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_fighter(retaliate = AGENT_COMBAT_BRAWL)
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/mob/living/carbon/human/brute = allocate(/mob/living/carbon/human/species/human/northern)
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")

	controller.on_pawn_attacked(pawn, brute, 5)
	var/list/built = agent_build_observation(pawn, 1)
	var/datum/agent_observation/observation = built["observation"]
	var/list/payload = built["payload"]
	var/list/entry = agent_test_find_offered(observation, payload["entities"], brute)
	var/list/myself = payload["self"]
	qdel(observation)
	controller.end_combat("test", report = FALSE)
	agent_test_restore_subsystem(saved, controller.binding)

	TEST_ASSERT_NOTNULL(entry, "Setup failed: the attacker must be in the scene.")
	TEST_ASSERT(entry["hostile"], "The model must know who started it, since that decides how hard it may answer.")
	var/list/fighting = myself["fighting"]
	TEST_ASSERT_NOTNULL(fighting, "The model must know it is fighting.")
	TEST_ASSERT_EQUAL(fighting["level"], AGENT_COMBAT_BRAWL, "And how hard.")

/datum/unit_test/agent_npc_real_blows_reach_the_npc

/datum/unit_test/agent_npc_real_blows_reach_the_npc/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_fighter(retaliate = AGENT_COMBAT_BRAWL)
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human/species/human/northern)
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")

	// The real signal a combat-mode hand sends, not a direct call to the handler.
	attacker.cmode = TRUE
	SEND_SIGNAL(pawn, COMSIG_ATOM_ATTACK_HAND, attacker, null)
	attacker.cmode = FALSE
	var/fighting = controller.blackboard[BB_AGENT_COMBAT_TARGET]
	controller.end_combat("test", report = FALSE)
	agent_test_restore_subsystem(saved, controller.binding)

	// Humans lack the element that turns hits into COMSIG_ATOM_WAS_ATTACKED, so this was dead in play.
	TEST_ASSERT_EQUAL(fighting, attacker, "A real blow must reach the NPC's attack handler.")
