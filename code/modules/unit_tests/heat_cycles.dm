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

	var/turf/open/human_turf = get_turf(human)
	// Earlier tests leave smells here, and a turf at its cap takes no more.
	human_turf.pollution?.scrub_amount(human_turf.pollution.total_amount)
	SEND_SIGNAL(human, COMSIG_SEX_SET_AROUSAL, 0)
	heat.tick()
	TEST_ASSERT(get_heat_test_arousal(human) > 0, "Heat should raise arousal.")
	TEST_ASSERT(human_turf?.pollution?.pollutants[/datum/pollutant/heat_musk] > 0, "Heat should give off musk.")
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
