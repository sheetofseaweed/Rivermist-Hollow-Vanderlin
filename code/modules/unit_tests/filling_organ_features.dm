/datum/unit_test/climax_release_uses_location_shares/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/testicles/testicles = allocate(/obj/item/organ/genitals/filling_organ/testicles)
	testicles.organ_size = 2
	testicles.Insert(human, TRUE, FALSE)
	TEST_ASSERT_NOTNULL(testicles.reagents, "Inserted testicles should have a reagent holder.")
	var/capacity = testicles.reagents.maximum_volume
	testicles.reagents.clear_reagents()
	testicles.reagents.add_reagent(testicles.reagent_to_make, capacity / 2)

	TEST_ASSERT(abs(testicles.get_climax_release(ORGASM_LOCATION_INTO) - capacity / 4) < 0.01, "Half-full testicles should release a quarter of capacity inside.")
	TEST_ASSERT_EQUAL(testicles.get_climax_release(ORGASM_LOCATION_ONTO), 20, "Release onto a partner should cap at ten per size step.")
	TEST_ASSERT(abs(testicles.get_climax_release(ORGASM_LOCATION_SELF) - capacity / 5) < 0.01, "Self release should be a fifth of capacity.")
	TEST_ASSERT(abs(testicles.get_climax_release(ORGASM_LOCATION_CONTAINER) - capacity / 3) < 0.01, "Container release should be a third of capacity.")
	TEST_ASSERT_EQUAL(testicles.get_climax_release(), 3, "A quick climax should release three units.")
	TEST_ASSERT_EQUAL(testicles.get_climax_release(ORGASM_LOCATION_INTO, 10), 10, "Release should not exceed the space given.")

	testicles.reagents.clear_reagents()
	TEST_ASSERT_EQUAL(testicles.get_climax_release(ORGASM_LOCATION_INTO), 0, "Empty testicles should release nothing.")

/datum/unit_test/climax_release_scales_when_pent_up/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/testicles/testicles = allocate(/obj/item/organ/genitals/filling_organ/testicles)
	testicles.Insert(human, TRUE, FALSE)
	TEST_ASSERT_NOTNULL(testicles.reagents, "Inserted testicles should have a reagent holder.")
	var/capacity = testicles.reagents.maximum_volume

	testicles.reagents.clear_reagents()
	testicles.reagents.add_reagent(testicles.reagent_to_make, capacity / 2)
	TEST_ASSERT(!testicles.is_pent_up(), "Half-full testicles should not be pent up.")
	var/half_release = testicles.get_climax_release(ORGASM_LOCATION_INTO)

	testicles.reagents.add_reagent(testicles.reagent_to_make, capacity / 2)
	TEST_ASSERT(testicles.is_pent_up(), "Full testicles should be pent up.")
	TEST_ASSERT(abs(testicles.get_climax_release(ORGASM_LOCATION_INTO) - half_release * FLUID_PENT_UP_MAX_MULT) < 0.01, "Full testicles should release half again as much.")

	human.add_fluid_modifier(/datum/fluid_modifier/fluid_surge, "unit_test")
	TEST_ASSERT(abs(testicles.get_climax_release(ORGASM_LOCATION_INTO) - half_release * FLUID_PENT_UP_MAX_MULT * 1.5) < 0.01, "Climax modifiers should stack with the pent-up scale.")

/datum/unit_test/climax_pent_up_release_lifts_mood/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/penis/penis = allocate(/obj/item/organ/genitals/penis)
	penis.Insert(human, TRUE, FALSE)
	var/obj/item/organ/genitals/filling_organ/testicles/testicles = allocate(/obj/item/organ/genitals/filling_organ/testicles)
	testicles.Insert(human, TRUE, FALSE)
	TEST_ASSERT_NOTNULL(testicles.reagents, "Inserted testicles should have a reagent holder.")
	testicles.reagents.clear_reagents()
	testicles.reagents.add_reagent(testicles.reagent_to_make, testicles.reagents.maximum_volume)
	var/datum/component/arousal/arousal = human.GetComponent(/datum/component/arousal)
	TEST_ASSERT_NOTNULL(arousal, "Humans should have an arousal component.")
	var/start_volume = testicles.reagents.total_volume

	var/runtimed = FALSE
	try
		arousal.manual_orgasm()
	catch
		runtimed = TRUE
	TEST_ASSERT(!runtimed, "A quick climax should not runtime.")
	TEST_ASSERT_NOTNULL(human.has_stress_type(/datum/stress_event/pent_up_release), "A pent-up climax should lift the mood.")
	TEST_ASSERT(abs((start_volume - testicles.reagents.total_volume) - 3 * FLUID_PENT_UP_MAX_MULT) < 0.01, "A pent-up quick climax should release half again the base amount.")

/datum/unit_test/vagina_climax_release_uses_held_fluid/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = allocate(/obj/item/organ/genitals/filling_organ/vagina)
	vagina.Insert(human, TRUE, FALSE)
	TEST_ASSERT_NOTNULL(vagina.reagents, "Inserted vagina should have a reagent holder.")
	vagina.reagents.clear_reagents()
	vagina.reagents.add_reagent(vagina.reagent_to_make, 20)
	TEST_ASSERT(abs(vagina.get_climax_release(ORGASM_LOCATION_ONTO) - 6) < 0.01, "The vagina should release thirty percent of what it holds.")

/datum/unit_test/fullness_description_tracks_fill/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/breasts/breasts = allocate(/obj/item/organ/genitals/filling_organ/breasts)
	breasts.Insert(human, TRUE, FALSE)
	TEST_ASSERT_NOTNULL(breasts.reagents, "Inserted breasts should have a reagent holder.")
	var/capacity = breasts.reagents.maximum_volume

	breasts.reagents.clear_reagents()
	breasts.reagents.add_reagent(breasts.reagent_to_make, capacity * 0.5)
	TEST_ASSERT_NULL(breasts.get_fullness_description(), "Half-full breasts should not look full.")

	breasts.reagents.add_reagent(breasts.reagent_to_make, capacity * 0.35)
	TEST_ASSERT(findtext(breasts.get_fullness_description(), "heavy with milk"), "Mostly full breasts should look heavy with milk.")

	breasts.reagents.add_reagent(breasts.reagent_to_make, capacity * 0.15)
	TEST_ASSERT(findtext(breasts.get_fullness_description(), "bursting"), "Full breasts should look close to bursting.")

	var/datum/mob_descriptor/breasts/descriptor = allocate(/datum/mob_descriptor/breasts)
	TEST_ASSERT(findtext(descriptor.get_description(human), "bursting with milk"), "The breast descriptor should include the fullness.")

/datum/unit_test/engorgement_swells_until_sprites_run_out/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.nutrition = NUTRITION_LEVEL_WELL_FED + 500
	var/obj/item/organ/genitals/filling_organ/breasts/breasts = allocate(/obj/item/organ/genitals/filling_organ/breasts)
	breasts.accessory_type = /datum/sprite_accessory/genitals/breasts/pair
	breasts.organ_size = 3
	breasts.produces_fluid = FALSE
	breasts.Insert(human, TRUE, FALSE)
	TEST_ASSERT_NOTNULL(breasts.reagents, "Inserted breasts should have a reagent holder.")
	var/capacity = breasts.reagents.maximum_volume
	breasts.reagents.clear_reagents()
	breasts.reagents.add_reagent(breasts.reagent_to_make, capacity)

	tick_organ_life(human, 1)
	TEST_ASSERT_EQUAL(breasts.engorgement_steps, 0, "Breasts should not swell without the trait.")
	var/resting_key = human.generate_icon_render_key()

	ADD_TRAIT(human, TRAIT_FLUID_ENGORGEMENT, "unit_test")
	tick_organ_life(human, 1)
	TEST_ASSERT_EQUAL(breasts.engorgement_steps, 3, "Full breasts should swell three steps.")
	TEST_ASSERT_EQUAL(breasts.get_visible_size(), 6, "Swelling should add to the visible size.")
	TEST_ASSERT_EQUAL(breasts.organ_size, 3, "Swelling must not change the real size.")
	TEST_ASSERT_NOTEQUAL(human.generate_icon_render_key(), resting_key, "A swollen look needs its own render key.")

	breasts.reagents.remove_all(capacity * 0.07)
	tick_organ_life(human, 1)
	TEST_ASSERT_EQUAL(breasts.engorgement_steps, 3, "A small dip below a threshold should not shrink the swelling.")

	breasts.reagents.remove_all(capacity * 0.8)
	tick_organ_life(human, 1)
	TEST_ASSERT_EQUAL(breasts.engorgement_steps, 0, "Emptied breasts should shrink back.")
	TEST_ASSERT_EQUAL(human.generate_icon_render_key(), resting_key, "The render key should drop the swelling.")

	var/obj/item/organ/genitals/filling_organ/testicles/testicles = allocate(/obj/item/organ/genitals/filling_organ/testicles)
	testicles.organ_size = 3
	testicles.Insert(human, TRUE, FALSE)
	testicles.reagents.clear_reagents()
	testicles.reagents.add_reagent(testicles.reagent_to_make, testicles.reagents.maximum_volume)
	testicles.produces_fluid = FALSE
	tick_organ_life(human, 1)
	TEST_ASSERT_EQUAL(testicles.engorgement_steps, 3, "Full balls should swell three steps.")
	TEST_ASSERT_EQUAL(testicles.get_visible_size(), 3, "Balls should stop at the largest sprite that exists.")
	REMOVE_TRAIT(human, TRAIT_FLUID_ENGORGEMENT, "unit_test")

/datum/unit_test/swelling_glands_quirk_grants_trait/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)

	human.add_quirk(/datum/quirk/peculiarity/swelling_glands)
	TEST_ASSERT(HAS_TRAIT(human, TRAIT_FLUID_ENGORGEMENT), "The quirk should grant engorgement.")
	human.remove_quirk(/datum/quirk/peculiarity/swelling_glands)
	TEST_ASSERT(!HAS_TRAIT(human, TRAIT_FLUID_ENGORGEMENT), "Removing the quirk should end engorgement.")
