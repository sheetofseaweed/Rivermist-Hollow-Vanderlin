/// A test human with a fertile vagina; returns the vagina.
/proc/give_fertility_test_vagina(mob/living/carbon/human/human)
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = new
	vagina.Insert(human, TRUE, FALSE)
	vagina.reagents.clear_reagents()
	return vagina

/datum/unit_test/pregnancy_starts_hidden/Run()
	var/mob/living/carbon/human/mother = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = give_fertility_test_vagina(mother)
	TEST_ASSERT(vagina.be_impregnated(), "The test setup should start a pregnancy.")
	TEST_ASSERT(vagina.pregnant, "The pregnancy should be real.")
	TEST_ASSERT_NULL(mother.has_status_effect(/datum/status_effect/debuff/impregnation), "Conception should not show an alert.")
	TEST_ASSERT_NULL(mother.has_status_effect(/datum/status_effect/morning_sickness), "Morning sickness should wait a while.")
	TEST_ASSERT_NOTNULL(vagina.morning_sickness_timer, "Morning sickness should be on its way.")

	vagina.start_morning_sickness()
	var/datum/status_effect/morning_sickness/sickness = mother.has_status_effect(/datum/status_effect/morning_sickness)
	TEST_ASSERT_NOTNULL(sickness, "Morning sickness should start later.")
	mother.nausea = 0
	sickness.sickness_bout()
	TEST_ASSERT(mother.nausea >= 40, "A bout should make the carrier queasy.")

	vagina.advance_pregnancy_stage()
	TEST_ASSERT_NULL(mother.has_status_effect(/datum/status_effect/morning_sickness), "A growing belly should end morning sickness.")
	vagina.clear_conventional_pregnancy()
	TEST_ASSERT(!vagina.pregnant, "Clearing should end the pregnancy.")
	// The first pregnancy reached the milk stage; its lingering milk is not what the next part checks.
	mother.remove_fluid_modifier(/datum/fluid_modifier/pregnancy_lactation, FLUID_SOURCE_POST_PREGNANCY)

	vagina.be_impregnated()
	var/timer = vagina.morning_sickness_timer
	vagina.clear_conventional_pregnancy()
	TEST_ASSERT_NULL(vagina.morning_sickness_timer, "An early end should stop the coming sickness.")
	TEST_ASSERT(!timeleft(timer), "The sickness timer should be gone.")
	TEST_ASSERT(!mother.has_fluid_modifier(/datum/fluid_modifier/pregnancy_lactation), "An early end should leave no milk behind.")

/datum/unit_test/seed_sachet_tells_after_ten_minutes/Run()
	var/mob/living/carbon/human/mother = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = give_fertility_test_vagina(mother)
	for(var/state in list("sachet", "sachet_wet", "sachet_sprouted", "sachet_spent"))
		TEST_ASSERT(icon_exists('modular_rmh/icons/obj/pregnancy_test.dmi', state), "The sachet needs the [state] sprite.")

	var/obj/item/pregnancy_test/early = allocate(/obj/item/pregnancy_test)
	vagina.be_impregnated()
	early.take_sample(mother)
	TEST_ASSERT_EQUAL(early.icon_state, "sachet_wet", "A wetted sachet should look damp.")
	early.show_result()
	TEST_ASSERT_EQUAL(early.icon_state, "sachet_spent", "A pregnancy under ten minutes old should not show yet.")

	vagina.conception_time = world.time - PREGNANCY_TEST_MIN_AGE
	var/obj/item/pregnancy_test/later = allocate(/obj/item/pregnancy_test)
	later.take_sample(mother)
	later.show_result()
	TEST_ASSERT_EQUAL(later.icon_state, "sachet_sprouted", "A pregnancy ten minutes along should sprout the seeds.")

	var/mob/living/carbon/human/other = allocate(/mob/living/carbon/human)
	var/obj/item/pregnancy_test/negative = allocate(/obj/item/pregnancy_test)
	negative.take_sample(other)
	negative.show_result()
	TEST_ASSERT_EQUAL(negative.icon_state, "sachet_spent", "Nobody pregnant, no sprouts.")

/datum/unit_test/contraceptives_cut_conception/Run()
	var/mob/living/carbon/human/mother = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/father = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = give_fertility_test_vagina(mother)
	var/obj/item/organ/genitals/filling_organ/testicles/testicles = new
	testicles.Insert(father, TRUE, FALSE)

	var/datum/reagent/fluid_potion/contraceptive/moon_tea/tea = new
	tea.try_take_effect(mother)
	TEST_ASSERT(mother.has_fluid_modifier(/datum/fluid_modifier/barren_womb), "Moon Tea should work even without the fluid potion preference.")
	qdel(tea)
	TEST_ASSERT_EQUAL(vagina.get_conception_chance(CONCEPTION_FULL_SEED, 1), CONCEPTION_BASE_CHANCE * CONTRACEPTIVE_MULTIPLIER, "Moon Tea should cut the chance.")
	mother.reagents.add_reagent(/datum/reagent/medicine/pregplus, 5)
	TEST_ASSERT(!vagina.is_conception_certain(TRUE), "The contraceptive should win over quickening.")
	mother.remove_status_effect(/datum/status_effect/buff/fluid_potion/moon_tea)
	TEST_ASSERT(vagina.is_conception_certain(FALSE), "Without it, a quickened carrier should conceive for sure.")
	mother.reagents.del_reagent(/datum/reagent/medicine/pregplus)

	father.apply_status_effect(/datum/status_effect/buff/fluid_potion/cold_seed)
	TEST_ASSERT_EQUAL(father.get_seed_virility_multiplier(), CONTRACEPTIVE_MULTIPLIER, "Cold Seed should weaken the seed.")
	father.reagents.add_reagent(/datum/reagent/medicine/vertplus, 5)
	testicles.reagents.clear_reagents()
	testicles.reagents.add_reagent(/datum/reagent/consumable/cum, 20)
	testicles.sync_cum_source_data()
	testicles.reagents.trans_to(vagina, 10, transfered_by = father, method = INGEST)
	var/datum/seed_deposit/deposit = vagina.seed_ledger[vagina.seed_ledger[1]]
	TEST_ASSERT(abs(deposit.virility - CONTRACEPTIVE_MULTIPLIER) < 0.001, "Seed given under Cold Seed should be recorded as weak.")
	TEST_ASSERT(!deposit.quickened, "Cold Seed should win over a quickened father.")

/datum/unit_test/seed_waits_out_a_blocked_womb/Run()
	var/mob/living/carbon/human/mother = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/father = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = give_fertility_test_vagina(mother)
	var/obj/item/organ/genitals/filling_organ/testicles/testicles = new
	testicles.Insert(father, TRUE, FALSE)
	testicles.reagents.clear_reagents()
	testicles.reagents.add_reagent(/datum/reagent/consumable/cum, 10)
	testicles.sync_cum_source_data()

	TEST_ASSERT(vagina.be_impregnated(), "The test setup should start a pregnancy.")
	testicles.reagents.trans_to(vagina, 10, transfered_by = father, method = INGEST)
	TEST_ASSERT_EQUAL(LAZYLEN(vagina.seed_ledger), 1, "Seed should be recorded even while the womb cannot conceive.")
	mother.reagents.add_reagent(/datum/reagent/medicine/pregplus, 5)
	TEST_ASSERT(!vagina.roll_conception(), "A pregnant womb should not conceive again.")
	TEST_ASSERT(LAZYLEN(vagina.seed_ledger), "A blocked roll should keep the record.")

	vagina.clear_conventional_pregnancy()
	TEST_ASSERT(vagina.roll_conception(), "The waiting seed should take once the block ends.")
	TEST_ASSERT(vagina.pregnant, "The new conception should be a real pregnancy.")

/datum/unit_test/pregnancy_belly_grows_hourly/Run()
	var/mob/living/carbon/human/mother = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = give_fertility_test_vagina(mother)
	TEST_ASSERT(vagina.be_impregnated(), "The test setup should start a pregnancy.")
	TEST_ASSERT(abs(timeleft(vagina.conventional_pregnancy_timer) - PREGNANCY_STAGE_TIME) <= 1 SECONDS, "The first stage should come after one stage time.")
	for(var/stage in 1 to PREGNANCY_MAX_STAGE)
		deltimer(vagina.conventional_pregnancy_timer)
		vagina.advance_conventional_pregnancy()
		TEST_ASSERT_EQUAL(vagina.conventional_pregnancy_stage, stage, "Every check should grow the belly one stage.")
	TEST_ASSERT_NULL(vagina.conventional_pregnancy_timer, "Growth should stop at full term.")
	vagina.clear_conventional_pregnancy()
