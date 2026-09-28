/datum/fluid_modifier/unit_test_boost
	rate_multiplier = 3
	capacity_multiplier = 2
	climax_multiplier = 2

/datum/fluid_modifier/unit_test_block
	blocks_production = TRUE

/// Runs the organ life loop the given number of one-second ticks.
/proc/tick_organ_life(mob/living/carbon/human/human, ticks)
	for(var/i in 1 to ticks)
		human.handle_organs(1, i)

/datum/unit_test/filling_organ_keeps_regenerating_across_ticks/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.nutrition = NUTRITION_LEVEL_WELL_FED + 500
	var/obj/item/organ/genitals/filling_organ/testicles/testicles = allocate(/obj/item/organ/genitals/filling_organ/testicles)
	testicles.Insert(human, TRUE, FALSE)
	TEST_ASSERT_NOTNULL(testicles.reagents, "Inserted testicles should have a reagent holder.")
	testicles.reagents.clear_reagents()

	tick_organ_life(human, 1)
	var/after_first_tick = testicles.reagents.total_volume
	TEST_ASSERT(after_first_tick > 0, "Testicles should produce on the first life tick.")
	tick_organ_life(human, 4)

	TEST_ASSERT(testicles.needs_processing, "A healthy filling organ must stay in the organ life loop.")
	TEST_ASSERT(testicles.reagents.total_volume > after_first_tick, "Testicles stopped producing after the first life tick.")

/datum/unit_test/filling_organ_dormant_breasts_do_not_produce/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.nutrition = NUTRITION_LEVEL_WELL_FED + 500
	var/obj/item/organ/genitals/filling_organ/breasts/breasts = allocate(/obj/item/organ/genitals/filling_organ/breasts)
	breasts.produces_fluid = FALSE
	breasts.Insert(human, TRUE, FALSE)
	TEST_ASSERT_NOTNULL(breasts.reagents, "Inserted breasts should have a reagent holder.")

	TEST_ASSERT_EQUAL(breasts.reagents.total_volume, 0, "Non-lactating breasts should not start full.")
	tick_organ_life(human, 3)
	TEST_ASSERT_EQUAL(breasts.reagents.total_volume, 0, "Non-lactating breasts should not produce milk.")

/datum/unit_test/filling_organ_rate_modifier_scales_production/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.nutrition = NUTRITION_LEVEL_WELL_FED + 500
	var/obj/item/organ/genitals/filling_organ/testicles/testicles = allocate(/obj/item/organ/genitals/filling_organ/testicles)
	testicles.Insert(human, TRUE, FALSE)
	TEST_ASSERT_NOTNULL(testicles.reagents, "Inserted testicles should have a reagent holder.")

	testicles.reagents.clear_reagents()
	tick_organ_life(human, 1)
	var/base_amount = testicles.reagents.total_volume
	TEST_ASSERT(base_amount > 0, "Testicles should produce without modifiers.")

	testicles.reagents.clear_reagents()
	human.add_fluid_modifier(/datum/fluid_modifier/unit_test_boost, "unit_test")
	tick_organ_life(human, 1)
	TEST_ASSERT(abs(testicles.reagents.total_volume - base_amount * 3) < 0.01, "A x3 rate modifier should triple production, got [testicles.reagents.total_volume] from [base_amount].")

/datum/unit_test/filling_organ_capacity_modifier_applies_and_restores/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/testicles/testicles = allocate(/obj/item/organ/genitals/filling_organ/testicles)
	testicles.Insert(human, TRUE, FALSE)
	TEST_ASSERT_NOTNULL(testicles.reagents, "Inserted testicles should have a reagent holder.")
	var/base_capacity = testicles.reagents.maximum_volume
	TEST_ASSERT(base_capacity > 0, "Testicles should have a capacity.")

	human.add_fluid_modifier(/datum/fluid_modifier/unit_test_boost, "unit_test")
	tick_organ_life(human, 1)
	TEST_ASSERT_EQUAL(testicles.reagents.maximum_volume, base_capacity * 2, "A x2 capacity modifier should double capacity.")

	human.remove_fluid_modifier(/datum/fluid_modifier/unit_test_boost, "unit_test")
	tick_organ_life(human, 1)
	TEST_ASSERT_EQUAL(testicles.reagents.maximum_volume, base_capacity, "Removing the modifier should restore capacity.")
	TEST_ASSERT(testicles.reagents.total_volume <= testicles.reagents.maximum_volume, "Fluid above the restored capacity should spill.")

/datum/unit_test/filling_organ_modifier_sources_are_independent/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)

	human.add_fluid_modifier(/datum/fluid_modifier/unit_test_boost, "first")
	human.add_fluid_modifier(/datum/fluid_modifier/unit_test_boost, "second")
	human.remove_fluid_modifier(/datum/fluid_modifier/unit_test_boost, "first")
	TEST_ASSERT(human.has_fluid_modifier(/datum/fluid_modifier/unit_test_boost), "A modifier should stay while another source remains.")
	TEST_ASSERT(!human.has_fluid_modifier(/datum/fluid_modifier/unit_test_boost, "first"), "The removed source should be gone.")

	human.remove_fluid_modifier(/datum/fluid_modifier/unit_test_boost, "second")
	TEST_ASSERT(!human.has_fluid_modifier(/datum/fluid_modifier/unit_test_boost), "A modifier should end with its last source.")
	TEST_ASSERT_NULL(human.fluid_modifier_sources, "The lazy source list should be released when empty.")

/datum/unit_test/filling_organ_block_modifier_stops_production/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.nutrition = NUTRITION_LEVEL_WELL_FED + 500
	var/obj/item/organ/genitals/filling_organ/testicles/testicles = allocate(/obj/item/organ/genitals/filling_organ/testicles)
	testicles.Insert(human, TRUE, FALSE)
	TEST_ASSERT_NOTNULL(testicles.reagents, "Inserted testicles should have a reagent holder.")
	testicles.reagents.clear_reagents()

	human.add_fluid_modifier(/datum/fluid_modifier/induced_lactation, "unit_test")
	human.add_fluid_modifier(/datum/fluid_modifier/unit_test_block, "unit_test")
	tick_organ_life(human, 2)
	TEST_ASSERT_EQUAL(testicles.reagents.total_volume, 0, "A blocking modifier should stop production.")

/datum/unit_test/filling_organ_nohunger_owner_produces_for_free/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	ADD_TRAIT(human, TRAIT_NOHUNGER, "unit_test")
	human.nutrition = NUTRITION_LEVEL_STARVING
	var/obj/item/organ/genitals/filling_organ/testicles/testicles = allocate(/obj/item/organ/genitals/filling_organ/testicles)
	testicles.Insert(human, TRUE, FALSE)
	TEST_ASSERT_NOTNULL(testicles.reagents, "Inserted testicles should have a reagent holder.")
	testicles.reagents.clear_reagents()

	tick_organ_life(human, 2)
	TEST_ASSERT(testicles.reagents.total_volume > 0, "An owner without hunger should produce regardless of nutrition.")
	TEST_ASSERT_EQUAL(human.nutrition, NUTRITION_LEVEL_STARVING, "An owner without hunger should not pay nutrition.")

/datum/unit_test/filling_organ_species_fluid_swap_keeps_capacity/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/breasts/breasts = allocate(/obj/item/organ/genitals/filling_organ/breasts)
	breasts.produces_fluid = TRUE
	breasts.Insert(human, TRUE, FALSE)
	TEST_ASSERT_NOTNULL(breasts.reagents, "Inserted breasts should have a reagent holder.")
	var/capacity = breasts.reagents.maximum_volume
	var/stored = breasts.reagents.total_volume
	TEST_ASSERT(stored > 0, "Lactating breasts should start full.")

	human.set_milk(/datum/reagent/consumable/milk/elf)
	TEST_ASSERT_EQUAL(breasts.reagents.maximum_volume, capacity, "Changing milk type should keep capacity.")
	TEST_ASSERT_EQUAL(breasts.reagents.get_reagent_amount(/datum/reagent/consumable/milk/elf), stored, "Stored milk should convert to the new type.")
	TEST_ASSERT_EQUAL(breasts.reagents.get_reagent_amount(/datum/reagent/consumable/milk), 0, "No old milk should remain.")

/datum/unit_test/filling_organ_vagina_wetness_follows_arousal/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = allocate(/obj/item/organ/genitals/filling_organ/vagina)
	vagina.Insert(human, TRUE, FALSE)
	TEST_ASSERT_NOTNULL(vagina.reagents, "Inserted vagina should have a reagent holder.")
	vagina.reagents.clear_reagents()

	SEND_SIGNAL(human, COMSIG_SEX_SET_AROUSAL, 0)
	tick_organ_life(human, 3)
	TEST_ASSERT_EQUAL(vagina.reagents.get_reagent_amount(vagina.reagent_to_make), 0, "An unaroused vagina should not get wet.")

	vagina.reagents.add_reagent(/datum/reagent/consumable/cum, 20)
	SEND_SIGNAL(human, COMSIG_SEX_SET_AROUSAL, ACTIVE_EJAC_THRESHOLD)
	tick_organ_life(human, 40)
	var/wetness = vagina.reagents.get_reagent_amount(vagina.reagent_to_make)
	TEST_ASSERT(abs(wetness - vagina.max_wetness) < 0.01, "Full arousal should reach max wetness despite foreign fluid, got [wetness].")

/datum/unit_test/filling_organ_absorbs_only_foreign_fluid/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = allocate(/obj/item/organ/genitals/filling_organ/vagina)
	vagina.Insert(human, TRUE, FALSE)
	TEST_ASSERT_NOTNULL(vagina.reagents, "Inserted vagina should have a reagent holder.")
	ADD_TRAIT(vagina, TRAIT_PASSIVE_LEAK_BLOCKED, "unit_test")
	SEND_SIGNAL(human, COMSIG_SEX_SET_AROUSAL, 0)
	vagina.reagents.clear_reagents()
	vagina.reagents.add_reagent(vagina.reagent_to_make, 5)
	vagina.reagents.add_reagent(/datum/reagent/water, 5)

	tick_organ_life(human, 1)
	TEST_ASSERT_EQUAL(vagina.reagents.get_reagent_amount(vagina.reagent_to_make), 5, "The organ should keep its own fluid.")
	TEST_ASSERT(vagina.reagents.get_reagent_amount(/datum/reagent/water) < 5, "Foreign fluid should be absorbed.")

/datum/unit_test/filling_organ_climax_burst_uses_modifiers/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = allocate(/obj/item/organ/genitals/filling_organ/vagina)
	vagina.Insert(human, TRUE, FALSE)
	TEST_ASSERT_NOTNULL(vagina.reagents, "Inserted vagina should have a reagent holder.")
	vagina.reagents.clear_reagents()

	TEST_ASSERT_EQUAL(vagina.produce_climax_fluid(), FEMCUM_ORGASM_VOLUME, "A climax should add the base burst.")
	vagina.reagents.clear_reagents()
	human.add_fluid_modifier(/datum/fluid_modifier/unit_test_boost, "unit_test")
	TEST_ASSERT_EQUAL(vagina.produce_climax_fluid(), FEMCUM_ORGASM_VOLUME * 2, "A x2 climax modifier should double the burst.")

/datum/unit_test/filling_organ_pregnancy_lactation_outlives_pregnancy/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/breasts/breasts = allocate(/obj/item/organ/genitals/filling_organ/breasts)
	breasts.produces_fluid = FALSE
	breasts.Insert(human, TRUE, FALSE)
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = allocate(/obj/item/organ/genitals/filling_organ/vagina)
	vagina.Insert(human, TRUE, FALSE)
	TEST_ASSERT_NOTNULL(vagina.reagents, "Inserted vagina should have a reagent holder.")
	var/base_capacity = vagina.reagents.maximum_volume

	TEST_ASSERT(vagina.be_impregnated(), "The test setup should start a conventional pregnancy.")
	TEST_ASSERT(breasts.is_producing(), "Pregnancy should start lactation.")
	TEST_ASSERT_EQUAL(vagina.reagents.maximum_volume, base_capacity * 0.5, "Pregnancy should halve capacity exactly once.")

	vagina.clear_conventional_pregnancy()
	TEST_ASSERT(breasts.is_producing(), "Lactation should continue for a while after pregnancy.")
	TEST_ASSERT(!human.has_fluid_modifier(/datum/fluid_modifier/pregnancy_lactation, FLUID_SOURCE_PREGNANCY), "The pregnancy source should end with the pregnancy.")
	TEST_ASSERT(human.has_fluid_modifier(/datum/fluid_modifier/pregnancy_lactation, FLUID_SOURCE_POST_PREGNANCY), "A timed post-pregnancy source should take over.")

/datum/unit_test/filling_organ_snapshot_ignores_temporary_lactation/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/breasts/breasts = allocate(/obj/item/organ/genitals/filling_organ/breasts)
	breasts.produces_fluid = FALSE
	breasts.Insert(human, TRUE, FALSE)
	human.add_fluid_modifier(/datum/fluid_modifier/induced_lactation, "unit_test")

	var/datum/organ_dna/breasts/breasts_dna = allocate(/datum/organ_dna/breasts)
	breasts.imprint_organ_dna(breasts_dna)
	TEST_ASSERT(!breasts_dna.lactating, "Temporary lactation must not be saved as permanent lactation.")

/datum/unit_test/filling_organ_own_fluid_does_not_bloat/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = allocate(/obj/item/organ/genitals/filling_organ/vagina)
	vagina.Insert(human, TRUE, FALSE)
	TEST_ASSERT_NOTNULL(vagina.reagents, "Inserted vagina should have a reagent holder.")
	vagina.reagents.clear_reagents()

	vagina.reagents.add_reagent(vagina.reagent_to_make, vagina.reagents.maximum_volume * 0.5)
	tick_organ_life(human, 1)
	TEST_ASSERT(!human.has_status_effect(/datum/status_effect/debuff/bloatone), "Own fluid should not bloat.")

	vagina.reagents.clear_reagents()
	vagina.reagents.add_reagent(/datum/reagent/water, vagina.reagents.maximum_volume * 0.5)
	tick_organ_life(human, 1)
	TEST_ASSERT(human.has_status_effect(/datum/status_effect/debuff/bloatone), "Foreign fluid should bloat.")

/datum/unit_test/filling_organ_production_scales_with_nourishment/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/testicles/testicles = allocate(/obj/item/organ/genitals/filling_organ/testicles)
	testicles.Insert(human, TRUE, FALSE)
	TEST_ASSERT_NOTNULL(testicles.reagents, "Inserted testicles should have a reagent holder.")

	human.nutrition = NUTRITION_LEVEL_HUNGRY
	TEST_ASSERT_EQUAL(testicles.get_nourishment_multiplier(), 0, "A hungry owner should make nothing.")
	human.nutrition = (NUTRITION_LEVEL_HUNGRY + NUTRITION_LEVEL_WELL_FED) / 2
	TEST_ASSERT(abs(testicles.get_nourishment_multiplier() - 0.5) < 0.01, "Half way to well fed should make half as much.")
	human.nutrition = NUTRITION_LEVEL_WELL_FED
	TEST_ASSERT_EQUAL(testicles.get_nourishment_multiplier(), 1, "A well fed owner should make the normal amount.")
	human.nutrition = NUTRITION_LEVEL_FULL
	TEST_ASSERT(testicles.get_nourishment_multiplier() > 1, "A stuffed owner should make more.")

	// A tenth of the way to well fed; smaller first drops fall under the 0.05 unit reagent floor.
	human.nutrition = NUTRITION_LEVEL_HUNGRY + (NUTRITION_LEVEL_WELL_FED - NUTRITION_LEVEL_HUNGRY) / 10
	testicles.reagents.clear_reagents()
	tick_organ_life(human, 1)
	var/peckish_amount = testicles.reagents.total_volume
	TEST_ASSERT(peckish_amount > 0, "A slightly peckish owner should still make a little.")
	human.nutrition = NUTRITION_LEVEL_WELL_FED
	testicles.reagents.clear_reagents()
	tick_organ_life(human, 1)
	TEST_ASSERT(testicles.reagents.total_volume > peckish_amount * 5, "A well fed owner should make far more than a peckish one.")

/datum/unit_test/filling_organ_milk_costs_more_than_it_feeds/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/breasts/breasts = allocate(/obj/item/organ/genitals/filling_organ/breasts)
	breasts.Insert(human, TRUE, FALSE)
	var/datum/reagent/consumable/milk/milk = GLOB.chemical_reagents_list[/datum/reagent/consumable/milk]
	// Drinking a unit gives its nutriment times the quality rate, since poor quality burns faster.
	var/milk_value = milk.nutriment_factor * milk.get_quality_metabolization_modifier()
	TEST_ASSERT(breasts.get_nutrition_cost_per_unit() >= milk_value * 2, "Making milk should cost at least twice what drinking it gives back.")
