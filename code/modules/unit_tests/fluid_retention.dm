/// A test human with a vagina holding a load of seed; returns the vagina.
/proc/give_retention_test_vagina(mob/living/carbon/human/human, seed_units = 30)
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = new
	vagina.Insert(human, TRUE, FALSE)
	vagina.reagents.clear_reagents()
	if(seed_units)
		vagina.reagents.add_reagent(/datum/reagent/consumable/cum, seed_units)
	return vagina

/datum/unit_test/fluid_retention_hold_it_in_slows_leaks/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = give_retention_test_vagina(human)
	var/standing = vagina.get_leak_amount()
	TEST_ASSERT(standing > 0, "A vagina holding seed should leak.")

	TEST_ASSERT(human.toggle_holding_fluids_in(), "Anyone with a vagina should be able to hold it in.")
	TEST_ASSERT(abs(vagina.get_leak_amount() - standing * FLUID_HELD_LEAK_MULT) < 0.001, "Holding it in should cut the leak.")
	human.set_body_position(LYING_DOWN)
	TEST_ASSERT(abs(vagina.get_leak_amount() - standing * FLUID_HELD_LEAK_MULT * FLUID_LYING_LEAK_MULT) < 0.001, "Lying down should slow the leak further.")
	human.set_body_position(STANDING_UP)
	human.set_lying_angle(0)

	var/datum/status_effect/holding_fluids_in/hold = human.has_status_effect(/datum/status_effect/holding_fluids_in)
	human.stamina = 0
	hold.tick()
	TEST_ASSERT_EQUAL(human.stamina, FLUID_HOLD_STAMINA_COST, "Holding something in should cost a little stamina.")
	TEST_ASSERT(FLUID_HOLD_STAMINA_COST * 2 SECONDS / FLUID_HOLD_TICK < 10, "The cost should stay far below natural recovery.")
	var/datum/sex_scene_controller/controller = human.open_sex_scene(human, FALSE)
	var/list/controls = controller.ui_data(human)["controls"]
	TEST_ASSERT(controls["can_hold_it_in"] && controls["hold_it_in"], "The panel should show the hold as on.")
	qdel(controller)

	TEST_ASSERT(!human.toggle_holding_fluids_in(), "Toggling again should relax.")
	TEST_ASSERT_EQUAL(vagina.reagents.total_volume, 30, "Relaxing on purpose should not gush.")

	human.toggle_holding_fluids_in()
	hold = human.has_status_effect(/datum/status_effect/holding_fluids_in)
	human.stamina = human.maximum_stamina
	hold.tick()
	TEST_ASSERT_NULL(human.has_status_effect(/datum/status_effect/holding_fluids_in), "Running out of stamina should end the hold.")
	TEST_ASSERT(abs(vagina.reagents.total_volume - 30 * (1 - FLUID_HOLD_GUSH_SHARE)) < 0.01, "A hold that gives out should gush a quarter of it.")

/datum/unit_test/conception_rolls_over_time_not_on_deposit/Run()
	var/mob/living/carbon/human/mother = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/father = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = give_retention_test_vagina(mother, 0)
	var/obj/item/organ/genitals/filling_organ/testicles/testicles = new
	testicles.Insert(father, TRUE, FALSE)
	testicles.reagents.clear_reagents()
	testicles.reagents.add_reagent(/datum/reagent/consumable/cum, 30)
	testicles.sync_cum_source_data()

	testicles.reagents.trans_to(vagina, 20, transfered_by = father, method = INGEST)
	TEST_ASSERT(!vagina.pregnant, "A deposit alone should not make anyone pregnant.")
	TEST_ASSERT_EQUAL(LAZYLEN(vagina.seed_ledger), 1, "The deposit should be recorded.")
	var/datum/seed_deposit/deposit = vagina.seed_ledger[vagina.seed_ledger[1]]
	TEST_ASSERT(abs(deposit.units - 20) < 0.01, "The record should hold the deposited seed.")
	TEST_ASSERT_EQUAL(deposit.father_ref?.resolve(), father, "The record should know the father.")
	TEST_ASSERT(!COOLDOWN_FINISHED(vagina, conception_cooldown), "The first check should wait a full interval.")
	vagina.check_conception()
	TEST_ASSERT(!vagina.pregnant && LAZYLEN(vagina.seed_ledger), "Nothing should roll before the interval passes.")

	TEST_ASSERT_EQUAL(vagina.get_conception_chance(CONCEPTION_FULL_SEED, 1), CONCEPTION_BASE_CHANCE, "A full dose of average seed should give the base chance.")
	TEST_ASSERT_EQUAL(vagina.get_conception_chance(CONCEPTION_FULL_SEED / 2, 1), CONCEPTION_BASE_CHANCE / 2, "Half a dose should halve the chance.")
	TEST_ASSERT_EQUAL(vagina.get_conception_chance((CONCEPTION_FULL_SEED + CONCEPTION_DOUBLE_SEED) / 2, 1), CONCEPTION_BASE_CHANCE * 1.5, "More seed than a full dose should keep raising the chance.")
	TEST_ASSERT_EQUAL(vagina.get_conception_chance(CONCEPTION_DOUBLE_SEED * 2, 1), CONCEPTION_BASE_CHANCE * 2, "The chance should stop rising at twice a full dose.")
	TEST_ASSERT_EQUAL(vagina.get_conception_chance(CONCEPTION_FULL_SEED, 5), CONCEPTION_BASE_CHANCE * 5, "Virile seed should raise the chance.")
	mother.add_fluid_modifier(/datum/fluid_modifier/in_heat, "test")
	TEST_ASSERT_EQUAL(vagina.get_conception_chance(CONCEPTION_FULL_SEED, 1), CONCEPTION_BASE_CHANCE * CONCEPTION_HEAT_MULT, "Heat should raise the chance.")
	mother.remove_fluid_modifier(/datum/fluid_modifier/in_heat, "test")

	vagina.reagents.remove_reagent(/datum/reagent/consumable/cum, 10)
	vagina.sync_seed_ledger()
	TEST_ASSERT(abs(deposit.units - 10) < 0.01, "The record should shrink as seed leaves.")

	var/datum/seed_deposit/weak = new
	weak.units = 10
	weak.virility = 1
	var/datum/seed_deposit/strong = new
	strong.units = 10
	strong.virility = 5
	var/list/weights = list()
	weights[weak] = 10
	weights[strong] = 50
	var/strong_picks = 0
	for(var/i in 1 to 600)
		if(vagina.pick_seed_deposit(weights) == strong)
			strong_picks++
	TEST_ASSERT(strong_picks > 420, "More virile seed should father more often, got [strong_picks] of 600.")

	father.reagents.add_reagent(/datum/reagent/medicine/vertplus, 5)
	testicles.reagents.trans_to(vagina, 5, transfered_by = father, method = INGEST)
	TEST_ASSERT(deposit.quickened, "Seed from a quickened father should be marked.")
	COOLDOWN_RESET(vagina, conception_cooldown)
	vagina.check_conception()
	TEST_ASSERT(vagina.pregnant, "Quickened seed should conceive at the first check.")
	TEST_ASSERT_NULL(vagina.seed_ledger, "Conception should clear the record.")

/datum/unit_test/conception_record_keeps_every_father/Run()
	var/mob/living/carbon/human/mother = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = give_retention_test_vagina(mother, 0)
	for(var/i in 1 to 2)
		var/mob/living/carbon/human/father = allocate(/mob/living/carbon/human)
		var/obj/item/organ/genitals/filling_organ/testicles/testicles = new
		testicles.Insert(father, TRUE, FALSE)
		testicles.reagents.clear_reagents()
		testicles.reagents.add_reagent(/datum/reagent/consumable/cum, 10)
		testicles.sync_cum_source_data()
		testicles.reagents.trans_to(vagina, 10, transfered_by = father, method = INGEST)
	TEST_ASSERT_EQUAL(LAZYLEN(vagina.seed_ledger), 2, "Seed from two fathers should keep two records, even once mixed.")
	var/datum/reagent/consumable/cum/mixed = vagina.reagents.get_reagent(/datum/reagent/consumable/cum)
	TEST_ASSERT_NULL(mixed?.get_fluid_donor(), "The mixed seed itself should no longer name a father.")

	var/datum/seed_deposit/first = vagina.seed_ledger[vagina.seed_ledger[1]]
	first.virility = 3
	var/list/weights = vagina.get_seed_weights()
	TEST_ASSERT(abs(weights[first] - first.units * 3) < 0.01, "A father's claim should be his seed left inside times its virility.")

	mother.reagents.add_reagent(/datum/reagent/medicine/pregplus, 5)
	TEST_ASSERT(vagina.roll_conception(), "A mother quickened after the deposit should conceive at the next check.")
	TEST_ASSERT(vagina.pregnant, "The conception should be a real pregnancy.")
