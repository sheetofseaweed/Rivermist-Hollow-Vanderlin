/// stamina counts fatigue accumulated, so a positive adjustment is what tires a mob.
/datum/unit_test/stamina_sign_convention/Run()
	var/mob/living/carbon/human/subject = allocate(/mob/living/carbon/human)
	subject.stamina = 10

	subject.adjust_stamina(4)
	TEST_ASSERT_EQUAL(subject.stamina, 14, "a positive adjustment should add fatigue")

	subject.adjust_stamina(-4)
	TEST_ASSERT_EQUAL(subject.stamina, 10, "a negative adjustment should remove fatigue")

	TEST_ASSERT(subject.maximum_stamina > 0, "a mob should have a fatigue ceiling to exhaust against")

/// A sex action must charge its performer fatigue rather than refunding it.
/datum/unit_test/sex_action_stamina_cost_tires_the_performer/Run()
	var/mob/living/carbon/human/aggressor = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/datum/sex_scene_controller/controller = aggressor.open_sex_scene(victim, show_ui = FALSE)
	var/datum/sex_action/action = controller.instantiate_action(/datum/sex_action/rub_body)
	TEST_ASSERT(action.bind_runtime(controller), "the action should bind to the scene")
	TEST_ASSERT(action.stamina_cost > 0, "rub_body should carry a non-zero stamina cost to test against")

	aggressor.stamina = 10
	var/cycle_cost = action.stamina_cost * action.get_stamina_cost_multiplier()
	aggressor.adjust_stamina(cycle_cost)
	TEST_ASSERT(aggressor.stamina > 10, "one cycle of an action should leave its performer more tired, not less")

	qdel(controller)

/// Squirming in a captor's grip must tire the captor.
/datum/unit_test/held_squirm_tires_the_captor/Run()
	var/mob/living/carbon/human/captor = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/occupant = allocate(/mob/living/carbon/human)
	var/obj/item/mob_holder/holder = new(captor, occupant)
	TEST_ASSERT_NOTNULL(holder, "the holder should construct")
	TEST_ASSERT_EQUAL(holder.held_mob, occupant, "the holder should carry the occupant")
	TEST_ASSERT_EQUAL(occupant.loc, holder, "the occupant should sit inside the holder")

	var/datum/sex_action/held_mob_squirm/squirm = new
	captor.stamina = 10
	squirm.on_perform(occupant, captor)
	TEST_ASSERT(captor.stamina > 10, "squirming should tire the captor, not rest them")

	qdel(squirm)
	qdel(holder)

/// Clench power should weight constitution above strength.
/datum/unit_test/clench_power_weights_constitution/Run()
	var/con_heavy = get_clench_power_from_stats(20, 10, 1)
	var/str_heavy = get_clench_power_from_stats(10, 20, 1)
	TEST_ASSERT(con_heavy > str_heavy, "constitution should contribute more clench power than strength")

/// Weight leverage should scale power and stay inside its clamp.
/datum/unit_test/clench_power_applies_leverage/Run()
	var/even = get_clench_power_from_stats(10, 10, 1)
	var/heavier = get_clench_power_from_stats(10, 10, 1.5)
	var/lighter = get_clench_power_from_stats(10, 10, 0.5)
	TEST_ASSERT(heavier > even, "a heavier clencher should out-leverage an even match")
	TEST_ASSERT(lighter < even, "a lighter clencher should lose leverage against an even match")

/// Chance should rise with the clencher's advantage and stay clamped.
/datum/unit_test/clench_chance_scales_and_clamps/Run()
	var/even = get_clench_chance(10, 10)
	var/winning = get_clench_chance(30, 10)
	var/losing = get_clench_chance(1, 40)
	TEST_ASSERT_EQUAL(even, CLENCH_BASE_CHANCE, "an even contest should sit at the base chance")
	TEST_ASSERT(winning > even, "a stat advantage should raise the chance")
	TEST_ASSERT(winning <= CLENCH_CHANCE_CEIL, "the chance must not exceed its ceiling")
	TEST_ASSERT(losing >= CLENCH_CHANCE_FLOOR, "the chance must not drop below its floor")

/// The roll must map onto exactly three bands, crit nested inside success.
/datum/unit_test/clench_roll_bands/Run()
	TEST_ASSERT_EQUAL(resolve_clench_roll(1, 50), CLENCH_RESULT_STOP, "a roll inside the crit band should stop the action")
	TEST_ASSERT_EQUAL(resolve_clench_roll(10, 50), CLENCH_RESULT_STOP, "the crit band should reach 20% of the chance")
	TEST_ASSERT_EQUAL(resolve_clench_roll(11, 50), CLENCH_RESULT_INTERRUPT, "a roll above the crit band but inside the chance should interrupt")
	TEST_ASSERT_EQUAL(resolve_clench_roll(50, 50), CLENCH_RESULT_INTERRUPT, "the success band should include the chance itself")
	TEST_ASSERT_EQUAL(resolve_clench_roll(51, 50), CLENCH_RESULT_FAIL, "a roll above the chance should fail")

/// A zero chance must never produce a success.
/datum/unit_test/clench_roll_zero_chance_never_succeeds/Run()
	TEST_ASSERT_EQUAL(resolve_clench_roll(1, 0), CLENCH_RESULT_FAIL, "a zero chance should always fail")

/// An interrupted cycle must leave the action running; stop_requested must end it.
/datum/unit_test/clench_interrupt_flag_is_distinct_from_stop/Run()
	var/mob/living/carbon/human/aggressor = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/datum/sex_scene_controller/controller = aggressor.open_sex_scene(victim, show_ui = FALSE)
	TEST_ASSERT_NOTNULL(controller, "a controller should open for the aggressor")

	var/datum/sex_action/action = controller.instantiate_action(/datum/sex_action/rub_body)
	TEST_ASSERT_NOTNULL(action, "a runtime action should instantiate")
	TEST_ASSERT_EQUAL(action.cycle_interrupted, FALSE, "a fresh action should not start interrupted")

	action.cycle_interrupted = TRUE
	TEST_ASSERT_EQUAL(action.stop_requested, FALSE, "interrupting a cycle must not request a stop")

	qdel(action)
	qdel(controller)

/// A stop result should request a stop; an interrupt should only flag the cycle.
/datum/unit_test/clench_apply_result_sets_correct_flags/Run()
	var/mob/living/carbon/human/aggressor = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/datum/sex_scene_controller/controller = aggressor.open_sex_scene(victim, show_ui = FALSE)
	var/datum/sex_action/action = controller.instantiate_action(/datum/sex_action/rub_body)
	TEST_ASSERT(action.bind_runtime(controller), "the action should bind to the scene")

	action.apply_clench_result(victim, CLENCH_RESULT_INTERRUPT)
	TEST_ASSERT_EQUAL(action.cycle_interrupted, TRUE, "an interrupt result should flag the cycle")
	TEST_ASSERT_EQUAL(action.stop_requested, FALSE, "an interrupt result should not request a stop")

	action.cycle_interrupted = FALSE
	action.apply_clench_result(victim, CLENCH_RESULT_STOP)
	TEST_ASSERT_EQUAL(action.stop_requested, TRUE, "a stop result should request a stop")

	qdel(controller)

/// Clenching must tire the clencher, not the aggressor.
/datum/unit_test/clench_drains_the_clencher/Run()
	var/mob/living/carbon/human/aggressor = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/datum/sex_scene_controller/controller = aggressor.open_sex_scene(victim, show_ui = FALSE)
	var/datum/sex_action/action = controller.instantiate_action(/datum/sex_action/rub_body)
	TEST_ASSERT(action.bind_runtime(controller), "the action should bind to the scene")

	var/victim_stamina_before = victim.stamina
	var/aggressor_stamina_before = aggressor.stamina
	action.apply_clench_result(victim, CLENCH_RESULT_INTERRUPT)

	TEST_ASSERT(victim.stamina > victim_stamina_before, "the clencher should accumulate fatigue")
	TEST_ASSERT_EQUAL(aggressor.stamina, aggressor_stamina_before, "the aggressor should not be tired by being clenched")

	qdel(controller)

/// The cooldown must reject a second clench inside the window.
/datum/unit_test/clench_respects_cooldown/Run()
	var/mob/living/carbon/human/aggressor = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/datum/sex_scene_controller/controller = aggressor.open_sex_scene(victim, show_ui = FALSE)
	var/datum/sex_action/action = controller.instantiate_action(/datum/sex_action/rub_body)
	TEST_ASSERT(action.bind_runtime(controller), "the action should bind to the scene")

	TEST_ASSERT(action.can_clench(victim), "a fresh action should accept a clench")
	action.try_clench(victim)
	TEST_ASSERT(!action.can_clench(victim), "a second clench inside the cooldown should be rejected")

	qdel(controller)

/// An exhausted clencher cannot clench.
/datum/unit_test/clench_blocked_when_exhausted/Run()
	var/mob/living/carbon/human/aggressor = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/datum/sex_scene_controller/controller = aggressor.open_sex_scene(victim, show_ui = FALSE)
	var/datum/sex_action/action = controller.instantiate_action(/datum/sex_action/rub_body)
	TEST_ASSERT(action.bind_runtime(controller), "the action should bind to the scene")

	victim.stamina = victim.maximum_stamina
	TEST_ASSERT(!action.can_clench(victim), "an exhausted clencher should not be able to clench")

	qdel(controller)

/// Only the target of an action may clench it.
/datum/unit_test/clench_rejects_non_target/Run()
	var/mob/living/carbon/human/aggressor = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human)
	var/datum/sex_scene_controller/controller = aggressor.open_sex_scene(victim, show_ui = FALSE)
	var/datum/sex_action/action = controller.instantiate_action(/datum/sex_action/rub_body)
	TEST_ASSERT(action.bind_runtime(controller), "the action should bind to the scene")

	TEST_ASSERT(!action.can_clench(bystander), "a bystander must not be able to clench an unrelated action")
	TEST_ASSERT(!action.can_clench(aggressor), "the aggressor must not be able to clench their own action")

	qdel(controller)

/// The session override must win over the saved preference, and null must defer to it.
/datum/unit_test/clench_session_override_beats_preference/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)

	TEST_ASSERT_EQUAL(victim.auto_clench_override, null, "a fresh mob should defer to its preference")
	TEST_ASSERT_EQUAL(victim.wants_auto_clench(), FALSE, "a clientless mob should fall back to the default-off preference")

	victim.auto_clench_override = TRUE
	TEST_ASSERT_EQUAL(victim.wants_auto_clench(), TRUE, "an explicit session override should enable auto-clench")

	victim.auto_clench_override = FALSE
	TEST_ASSERT_EQUAL(victim.wants_auto_clench(), FALSE, "an explicit session override should disable auto-clench")

/// The preference must be a normal, discoverable ERP preference.
/datum/unit_test/clench_preference_is_registered/Run()
	var/datum/erp_preference/boolean/auto_clench/pref = new
	TEST_ASSERT_EQUAL(pref.default_value, FALSE, "auto-clench should be opt-in")
	TEST_ASSERT(pref.type in subtypesof(/datum/erp_preference), "the preference must be discoverable by the menu builders")
	qdel(pref)

/// Auto-clench must require both the toggle and combat mode.
/datum/unit_test/clench_auto_requires_toggle_and_cmode/Run()
	var/mob/living/carbon/human/aggressor = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/datum/sex_scene_controller/controller = aggressor.open_sex_scene(victim, show_ui = FALSE)
	var/datum/sex_action/action = controller.instantiate_action(/datum/sex_action/rub_body)
	TEST_ASSERT(action.bind_runtime(controller), "the action should bind to the scene")

	victim.auto_clench_override = FALSE
	victim.cmode = TRUE
	TEST_ASSERT(!action.should_auto_clench(), "combat mode alone should not fire auto-clench")

	victim.auto_clench_override = TRUE
	victim.cmode = FALSE
	TEST_ASSERT(!action.should_auto_clench(), "the toggle alone should not fire auto-clench")

	victim.cmode = TRUE
	TEST_ASSERT(action.should_auto_clench(), "toggle plus combat mode should fire auto-clench")

	qdel(controller)

/// Auto-clench must not fire on a self-directed action.
/datum/unit_test/clench_auto_ignores_solo_actions/Run()
	var/mob/living/carbon/human/solo = allocate(/mob/living/carbon/human)
	var/datum/sex_scene_controller/controller = solo.open_sex_scene(solo, show_ui = FALSE)
	var/datum/sex_action/action = controller.instantiate_action(/datum/sex_action/rub_body)
	TEST_ASSERT(action.prepare_proposal(controller), "the solo action should prepare against its controller")
	TEST_ASSERT_EQUAL(action.action_user, action.action_target, "a solo action should act on its own user")

	solo.auto_clench_override = TRUE
	solo.cmode = TRUE
	TEST_ASSERT(!action.should_auto_clench(), "a mob must not auto-clench against itself")

	qdel(action)
	qdel(controller)

/// The prompt must address the action by reference and offer both links.
/datum/unit_test/clench_prompt_builds_links/Run()
	var/mob/living/carbon/human/aggressor = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/datum/sex_scene_controller/controller = aggressor.open_sex_scene(victim, show_ui = FALSE)
	var/datum/sex_action/action = controller.instantiate_action(/datum/sex_action/rub_body)
	TEST_ASSERT(action.bind_runtime(controller), "the action should bind to the scene")

	var/prompt = action.build_clench_prompt()
	TEST_ASSERT(findtext(prompt, REF(action)), "the prompt should reference the action datum")
	TEST_ASSERT(findtext(prompt, "clench=1"), "the prompt should offer a clench link")
	TEST_ASSERT(findtext(prompt, "auto_clench=1"), "the prompt should offer an auto-clench toggle link")

	qdel(controller)

/// Topic must reject anyone who is not the target of the action.
/datum/unit_test/clench_topic_rejects_impostor/Run()
	var/mob/living/carbon/human/aggressor = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/impostor = allocate(/mob/living/carbon/human)
	var/datum/sex_scene_controller/controller = aggressor.open_sex_scene(victim, show_ui = FALSE)
	var/datum/sex_action/action = controller.instantiate_action(/datum/sex_action/rub_body)
	TEST_ASSERT(action.bind_runtime(controller), "the action should bind to the scene")

	TEST_ASSERT(!action.handle_clench_topic(impostor, list("clench" = "1")), "a bystander must not drive an unrelated clench")
	TEST_ASSERT(!action.handle_clench_topic(aggressor, list("clench" = "1")), "the aggressor must not drive the clench of their target")
	TEST_ASSERT_EQUAL(impostor.auto_clench_override, null, "a rejected topic must not mutate the caller")

	TEST_ASSERT(action.handle_clench_topic(victim, list("auto_clench" = "1")), "the target should be able to toggle auto-clench")
	TEST_ASSERT_EQUAL(victim.auto_clench_override, TRUE, "toggling from null should arm auto-clench")

	qdel(controller)
