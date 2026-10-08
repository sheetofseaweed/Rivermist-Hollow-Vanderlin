/// Caches ERP prefs on the human with the heat cycle pref set; uncached mobs refuse species heat.
/proc/set_heat_cycle_pref(mob/living/carbon/human/human, datum/preferences/prefs, allowed)
	prefs.setup_default_erp_preferences()
	var/datum/erp_preference/boolean/allow_heat_cycles/heat_pref = new
	heat_pref.set_value(prefs, allowed)
	human.cache_erp_preferences_from_prefs(prefs)

/proc/get_heat_test_arousal(mob/living/living_mob)
	var/list/arousal_data = list()
	SEND_SIGNAL(living_mob, COMSIG_SEX_GET_AROUSAL, arousal_data)
	return arousal_data["arousal"]

/datum/unit_test/heat_cycle_species_needs_pref/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	set_heat_cycle_pref(human, allocate(/datum/preferences), FALSE)
	human.set_species(/datum/species/gnoll)
	var/datum/component/heat_cycle/cycle = human.GetComponent(/datum/component/heat_cycle)
	TEST_ASSERT_NOTNULL(cycle, "Gnolls should have a heat cycle.")
	TEST_ASSERT_NOTNULL(cycle.next_heat_timer, "Species heat should run on a timer.")
	TEST_ASSERT(!cycle.start_heat(), "Species heat should respect the preference.")

	set_heat_cycle_pref(human, allocate(/datum/preferences), TRUE)
	TEST_ASSERT(cycle.start_heat(), "Species heat should start once the preference allows it.")
	TEST_ASSERT_NOTNULL(human.has_status_effect(/datum/status_effect/in_heat), "Heat should apply its status effect.")
	TEST_ASSERT(human.has_fluid_modifier(/datum/fluid_modifier/in_heat), "Heat should boost the fluids.")
	TEST_ASSERT(!cycle.start_heat(), "A second heat should not stack.")

	human.set_species(/datum/species/human/northern)
	TEST_ASSERT_NULL(human.GetComponent(/datum/component/heat_cycle), "Leaving the species should end the cycle.")
	TEST_ASSERT_NULL(human.has_status_effect(/datum/status_effect/in_heat), "Leaving the species should end the heat.")
	TEST_ASSERT(!human.has_fluid_modifier(/datum/fluid_modifier/in_heat), "The heat boost should end with the heat.")

/datum/unit_test/heat_cycle_quirk_runs_on_timer/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	set_heat_cycle_pref(human, allocate(/datum/preferences), FALSE)
	human.grant_heat_cycle(HEAT_SOURCE_QUIRK)
	var/datum/component/heat_cycle/cycle = human.GetComponent(/datum/component/heat_cycle)
	TEST_ASSERT_NOTNULL(cycle?.next_heat_timer, "The quirk should schedule a heat.")

	var/first_timer = cycle.next_heat_timer
	cycle.on_heat_timer()
	TEST_ASSERT_NOTNULL(human.has_status_effect(/datum/status_effect/in_heat), "The quirk should bring heat even with the preference off.")
	TEST_ASSERT(cycle.next_heat_timer && cycle.next_heat_timer != first_timer, "A heat should schedule the next one.")

	human.revoke_heat_cycle(HEAT_SOURCE_QUIRK)
	TEST_ASSERT_NULL(human.GetComponent(/datum/component/heat_cycle), "Removing the last source should end the cycle.")
	TEST_ASSERT_NULL(human.has_status_effect(/datum/status_effect/in_heat), "Removing the last source should end the heat.")

/datum/unit_test/heat_pulls_arousal_until_sated/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/penis/penis = allocate(/obj/item/organ/genitals/penis)
	penis.Insert(human, TRUE, FALSE)
	human.grant_heat_cycle(HEAT_SOURCE_QUIRK)
	var/datum/component/heat_cycle/cycle = human.GetComponent(/datum/component/heat_cycle)
	TEST_ASSERT(cycle.start_heat(), "The quirk should start a heat.")
	var/datum/status_effect/in_heat/heat = human.has_status_effect(/datum/status_effect/in_heat)
	TEST_ASSERT(heat.is_rut, "A penis without a vagina should make it a rut.")
	TEST_ASSERT_EQUAL(heat.linked_alert?.name, "In Rut", "The alert should say rut.")

	SEND_SIGNAL(human, COMSIG_SEX_SET_AROUSAL, 0)
	heat.tick()
	TEST_ASSERT(get_heat_test_arousal(human) > 0, "Heat should raise arousal.")
	for(var/i in 1 to 30)
		heat.tick()
	TEST_ASSERT_EQUAL(get_heat_test_arousal(human), HEAT_AROUSAL_FLOOR, "Heat should stop raising arousal at its floor.")
	SEND_SIGNAL(human, COMSIG_SEX_SET_AROUSAL, HEAT_AROUSAL_FLOOR + 40)
	heat.tick()
	TEST_ASSERT_EQUAL(get_heat_test_arousal(human), HEAT_AROUSAL_FLOOR + 40, "Heat should never lower arousal that is already high.")

	SEND_SIGNAL(human, COMSIG_SEX_CLIMAX)
	TEST_ASSERT_NOTNULL(human.has_status_effect(/datum/status_effect/heat_sated), "A climax should sate the heat.")
	SEND_SIGNAL(human, COMSIG_SEX_SET_AROUSAL, 0)
	heat.tick()
	TEST_ASSERT_EQUAL(get_heat_test_arousal(human), 0, "A sated heat should not raise arousal.")

	human.revoke_heat_cycle(HEAT_SOURCE_QUIRK)
	TEST_ASSERT_NULL(human.has_status_effect(/datum/status_effect/heat_sated), "Ending the heat should end the sated state.")

	penis.strapon = TRUE
	human.grant_heat_cycle(HEAT_SOURCE_QUIRK)
	cycle = human.GetComponent(/datum/component/heat_cycle)
	TEST_ASSERT(cycle.start_heat(), "The quirk should start a second heat.")
	heat = human.has_status_effect(/datum/status_effect/in_heat)
	TEST_ASSERT(!heat.is_rut, "A strapon should not make it a rut.")
	human.revoke_heat_cycle(HEAT_SOURCE_QUIRK)

/// Lets the arousal component cool as if nothing aroused the mob for a while.
/proc/cool_heat_test_arousal(mob/living/living_mob)
	var/datum/component/arousal/arousal = living_mob.GetComponent(/datum/component/arousal)
	arousal.last_arousal_increase_time = world.time - 1 MINUTES
	arousal.last_ejaculation_time = world.time - 1 MINUTES
	arousal.handle_aroousal_cooling()

/datum/unit_test/heat_holds_arousal_at_its_floor/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	TEST_ASSERT_NOTNULL(human.GetComponent(/datum/component/arousal), "The test human should have arousal.")
	SEND_SIGNAL(human, COMSIG_SEX_SET_AROUSAL, HEAT_AROUSAL_FLOOR + 1)
	cool_heat_test_arousal(human)
	TEST_ASSERT(get_heat_test_arousal(human) < HEAT_AROUSAL_FLOOR, "Without heat, arousal should cool below the heat floor.")

	human.grant_heat_cycle(HEAT_SOURCE_QUIRK)
	var/datum/component/heat_cycle/cycle = human.GetComponent(/datum/component/heat_cycle)
	TEST_ASSERT(cycle.start_heat(), "The quirk should start a heat.")
	SEND_SIGNAL(human, COMSIG_SEX_SET_AROUSAL, HEAT_AROUSAL_FLOOR + 1)
	cool_heat_test_arousal(human)
	TEST_ASSERT_EQUAL(get_heat_test_arousal(human), HEAT_AROUSAL_FLOOR, "Cooling should stop at the heat floor.")
	cool_heat_test_arousal(human)
	TEST_ASSERT_EQUAL(get_heat_test_arousal(human), HEAT_AROUSAL_FLOOR, "Arousal should stay at the heat floor.")

	human.apply_status_effect(/datum/status_effect/heat_sated)
	cool_heat_test_arousal(human)
	TEST_ASSERT(get_heat_test_arousal(human) < HEAT_AROUSAL_FLOOR, "A sated heat should let arousal cool.")

	human.death()
	TEST_ASSERT_NULL(human.has_status_effect(/datum/status_effect/in_heat), "Death should end the heat.")
	human.revoke_heat_cycle(HEAT_SOURCE_QUIRK)

/proc/set_pheromone_test_pref(mob/living/carbon/human/human, datum/preferences/prefs, flags)
	prefs.setup_default_erp_preferences()
	var/datum/erp_preference/bitflag/pheromones/pheromone_pref = new
	pheromone_pref.set_value(prefs, flags)
	human.cache_erp_preferences_from_prefs(prefs)

/datum/unit_test/heat_pheromones_reach_matching_noses/Run()
	// No genitals reads as heat, so this owner gives off heat scent.
	var/mob/living/carbon/human/owner = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/heat_lover = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/rut_lover = allocate(/mob/living/carbon/human)
	set_pheromone_test_pref(owner, allocate(/datum/preferences), PHEROMONE_SCENT_HEAT)
	set_pheromone_test_pref(heat_lover, allocate(/datum/preferences), PHEROMONE_SCENT_HEAT)
	set_pheromone_test_pref(rut_lover, allocate(/datum/preferences), PHEROMONE_SCENT_RUT)
	owner.grant_heat_cycle(HEAT_SOURCE_QUIRK)
	var/datum/component/heat_cycle/cycle = owner.GetComponent(/datum/component/heat_cycle)
	TEST_ASSERT(cycle.start_heat(), "The quirk should start a heat.")
	var/datum/status_effect/in_heat/heat = owner.has_status_effect(/datum/status_effect/in_heat)
	TEST_ASSERT(!heat.is_rut, "No genitals should read as heat.")

	heat.emit_pheromones()
	TEST_ASSERT_NOTNULL(heat_lover.has_status_effect(/datum/status_effect/pheromone_haze), "Heat scent should reach a nose that likes it.")
	TEST_ASSERT_NULL(rut_lover.has_status_effect(/datum/status_effect/pheromone_haze), "Heat scent should not arouse a nose that likes only rut.")
	TEST_ASSERT_NULL(owner.has_status_effect(/datum/status_effect/pheromone_haze), "Nobody should be aroused by their own scent.")

	SEND_SIGNAL(heat_lover, COMSIG_SEX_SET_AROUSAL, PHEROMONE_AROUSAL_FLOOR + 1)
	cool_heat_test_arousal(heat_lover)
	TEST_ASSERT_EQUAL(get_heat_test_arousal(heat_lover), PHEROMONE_AROUSAL_FLOOR, "The scent should hold arousal at its floor.")

	heat_lover.remove_status_effect(/datum/status_effect/pheromone_haze)
	owner.forceMove(run_loc_floor_top_right)
	TEST_ASSERT(get_dist(owner, heat_lover) >= 4, "The test room should put the owner out of direct reach.")
	heat.emit_pheromones()
	TEST_ASSERT_NOTNULL(heat_lover.has_status_effect(/datum/status_effect/pheromone_haze), "The scent should linger where the owner stood.")

	heat_lover.remove_status_effect(/datum/status_effect/pheromone_haze)
	for(var/turf/trail_turf as anything in heat.scent_trail)
		heat.scent_trail[trail_turf] = world.time - 10 MINUTES
	heat.emit_pheromones()
	TEST_ASSERT_NULL(heat_lover.has_status_effect(/datum/status_effect/pheromone_haze), "An old trail should fade.")
	owner.revoke_heat_cycle(HEAT_SOURCE_QUIRK)

/datum/unit_test/heat_cycle_werewolf_starts_at_nightfall/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	set_heat_cycle_pref(human, allocate(/datum/preferences), TRUE)
	var/datum/antagonist/werewolf/curse = allocate(/datum/antagonist/werewolf)
	curse.apply_innate_effects(human)
	var/datum/component/heat_cycle/cycle = human.GetComponent(/datum/component/heat_cycle)
	TEST_ASSERT_NOTNULL(cycle, "The werewolf curse should give a heat cycle.")
	TEST_ASSERT_NULL(cycle.next_heat_timer, "Werewolf heat should wait for nightfall, not a timer.")

	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_TIME_OF_DAY_CHANGED, "day", "dawn")
	TEST_ASSERT_NULL(human.has_status_effect(/datum/status_effect/in_heat), "Daybreak should not start werewolf heat.")
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_TIME_OF_DAY_CHANGED, "night", "dusk")
	TEST_ASSERT_NOTNULL(human.has_status_effect(/datum/status_effect/in_heat), "Nightfall should start werewolf heat.")

	curse.remove_innate_effects(human)
	TEST_ASSERT_NULL(human.GetComponent(/datum/component/heat_cycle), "Losing the curse should end the cycle.")

/datum/unit_test/heat_examine_verbs_agree_with_pronouns/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.gender = FEMALE
	human.pronouns = SHE_HER
	// A hidden face and body read as PLURAL, but chosen pronouns still say "she".
	TEST_ASSERT_EQUAL("[human.p_they(TRUE, PLURAL)] [human.p_are(PLURAL)]", "She is", "A hidden she should still be 'She is', never 'She are'.")
	human.apply_status_effect(/datum/status_effect/in_heat)
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human)
	TEST_ASSERT(findtext(human.status_effect_examines(viewer), "She is flushed"), "The heat examine line should read 'She is flushed'.")

	human.pronouns = THEY_THEM
	TEST_ASSERT_EQUAL("[human.p_they()] [human.p_are()]", "they are", "They should take 'are'.")
	TEST_ASSERT_EQUAL("run[human.p_s()]", "run", "They should run, not runs.")

	human.pronouns = null
	TEST_ASSERT_EQUAL("[human.p_they(FALSE, PLURAL)] [human.p_are(PLURAL)]", "they are", "Without chosen pronouns a hidden body is 'they are'.")
	TEST_ASSERT_EQUAL("[human.p_they(FALSE, FEMALE)] [human.p_are(FEMALE)] run[human.p_s(FEMALE)]", "she is runs", "Without chosen pronouns a woman takes singular verbs.")
