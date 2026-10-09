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
	TEST_ASSERT(!breasts.is_producing(), "A hidden pregnancy should not bring the milk in at once.")
	TEST_ASSERT_EQUAL(vagina.get_reagent_capacity(), base_capacity, "Capacity should not shrink before the belly grows.")
	vagina.advance_pregnancy_stage()
	TEST_ASSERT(breasts.is_producing(), "The first belly stage should start lactation.")
	for(var/stage in 2 to PREGNANCY_MAX_STAGE)
		vagina.advance_pregnancy_stage()
	TEST_ASSERT_EQUAL(vagina.reagents.maximum_volume, base_capacity * 0.5, "A full-term belly should halve capacity.")

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

	// Between half and two thirds full is still only a light bloat.
	vagina.reagents.add_reagent(/datum/reagent/water, vagina.reagents.maximum_volume * 0.1)
	tick_organ_life(human, 1)
	TEST_ASSERT(!human.has_status_effect(/datum/status_effect/debuff/bloattwo), "Three fifths full should only be a light bloat.")

	vagina.reagents.add_reagent(/datum/reagent/water, vagina.reagents.maximum_volume * 0.2)
	tick_organ_life(human, 1)
	TEST_ASSERT(human.has_status_effect(/datum/status_effect/debuff/bloattwo), "Over two thirds full should be a heavy bloat.")

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

	// A tenth of the way to well fed; drops under the 0.05 unit reagent floor must add up, not vanish.
	human.nutrition = NUTRITION_LEVEL_HUNGRY + (NUTRITION_LEVEL_WELL_FED - NUTRITION_LEVEL_HUNGRY) / 10
	testicles.reagents.clear_reagents()
	tick_organ_life(human, 10)
	var/peckish_amount = testicles.reagents.total_volume
	TEST_ASSERT(peckish_amount > 0, "A slightly peckish owner should still make a little.")
	human.nutrition = NUTRITION_LEVEL_WELL_FED
	testicles.reagents.clear_reagents()
	tick_organ_life(human, 10)
	TEST_ASSERT(testicles.reagents.total_volume > peckish_amount * 5, "A well fed owner should make far more than a peckish one.")

/datum/unit_test/filling_organ_fluids_cost_more_than_they_feed/Run()
	for(var/organ_type in list(/obj/item/organ/genitals/filling_organ/breasts, /obj/item/organ/genitals/filling_organ/testicles))
		var/mob/living/carbon/human/maker = allocate(/mob/living/carbon/human)
		var/obj/item/organ/genitals/filling_organ/organ = allocate(organ_type)
		organ.Insert(maker, TRUE, FALSE)
		var/datum/reagent/fluid_type = organ.get_produced_reagent()

		// Measured, not read from vars, so a flat bonus in the reagent's own tick is counted too.
		var/mob/living/carbon/human/drinker = allocate(/mob/living/carbon/human)
		drinker.nutrition = NUTRITION_LEVEL_HUNGRY
		drinker.reagents.add_reagent(fluid_type, 10)
		drinker.reagents.metabolize(drinker)
		var/used = 10 - drinker.reagents.get_reagent_amount(fluid_type)
		TEST_ASSERT(used > 0, "[initial(fluid_type.name)] should be metabolized.")
		var/value_per_unit = (drinker.nutrition - NUTRITION_LEVEL_HUNGRY) / used
		TEST_ASSERT(organ.get_nutrition_cost_per_unit() >= value_per_unit * 2, "Making [initial(fluid_type.name)] should cost at least twice what drinking it gives back, got [organ.get_nutrition_cost_per_unit()] for [value_per_unit].")

/datum/unit_test/filling_organ_breasts_make_milk_at_a_cows_pace/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.nutrition = NUTRITION_LEVEL_WELL_FED
	var/obj/item/organ/genitals/filling_organ/breasts/breasts = allocate(/obj/item/organ/genitals/filling_organ/breasts)
	breasts.produces_fluid = TRUE
	breasts.Insert(human, TRUE, FALSE)
	breasts.reagents.clear_reagents()
	tick_organ_life(human, 1)
	// A cow's udder makes 0.5 units per second.
	TEST_ASSERT(abs(breasts.reagents.total_volume - 0.5) < 0.01, "Well fed breasts should make half a unit a second, got [breasts.reagents.total_volume].")

/datum/unit_test/arousal_wetness_drips_only_when_high/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = allocate(/obj/item/organ/genitals/filling_organ/vagina)
	vagina.Insert(human, TRUE, FALSE)
	var/turf/floor = get_turf(human)
	for(var/obj/effect/decal/cleanable/liquid_drip/old_drop in floor)
		qdel(old_drop)
	vagina.reagents.clear_reagents()
	vagina.reagents.add_reagent(vagina.reagent_to_make, 5)

	SEND_SIGNAL(human, COMSIG_SEX_SET_AROUSAL, HEAT_AROUSAL_FLOOR)
	vagina.leak_reagents()
	TEST_ASSERT_NULL(locate(/obj/effect/decal/cleanable/liquid_drip) in floor, "Heat-level wetness should not drip on the floor.")

	SEND_SIGNAL(human, COMSIG_SEX_SET_AROUSAL, VAGINA_DRIP_AROUSAL)
	vagina.leak_reagents()
	var/obj/effect/decal/cleanable/liquid_drip/drop = locate() in floor
	TEST_ASSERT_NOTNULL(drop, "High arousal should drip on the floor.")
	TEST_ASSERT_NOTNULL(drop.dry_timer, "A drop should dry away in time.")
	qdel(drop)

	SEND_SIGNAL(human, COMSIG_SEX_SET_AROUSAL, 0)
	TEST_ASSERT(vagina.produce_climax_fluid() > 0, "A climax should add a burst.")
	var/burst = vagina.burst_to_drip
	vagina.leak_reagents()
	TEST_ASSERT_NOTNULL(locate(/obj/effect/decal/cleanable/liquid_drip) in floor, "A climax burst should drip at any arousal.")
	TEST_ASSERT(vagina.burst_to_drip < burst, "Leaking should spend the burst.")
	for(var/obj/effect/decal/cleanable/liquid_drip/burst_drop in floor)
		qdel(burst_drop)

	vagina.burst_to_drip = 0
	vagina.reagents.clear_reagents()
	vagina.reagents.add_reagent(vagina.reagent_to_make, 5)
	vagina.leak_reagents(1)
	TEST_ASSERT_NOTNULL(locate(/obj/effect/decal/cleanable/liquid_drip) in floor, "A forced gush should reach the floor at any arousal.")
	for(var/obj/effect/decal/cleanable/liquid_drip/gush_drop in floor)
		qdel(gush_drop)

	vagina.burst_to_drip = 0
	vagina.reagents.clear_reagents()
	vagina.reagents.add_reagent(/datum/reagent/consumable/cum, 5)
	vagina.leak_reagents()
	TEST_ASSERT_NOTNULL(locate(/obj/effect/decal/cleanable/liquid_drip) in floor, "Seed should drip at any arousal.")
	for(var/obj/effect/decal/cleanable/liquid_drip/seed_drop in floor)
		qdel(seed_drop)
	human.wash(CLEAN_WASH)
