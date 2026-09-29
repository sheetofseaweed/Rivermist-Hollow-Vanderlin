/// Caches ERP prefs on the human with the fluid potion pref set; uncached mobs refuse every potion.
/proc/set_fluid_potion_pref(mob/living/carbon/human/human, datum/preferences/prefs, allowed)
	prefs.setup_default_erp_preferences()
	var/datum/erp_preference/boolean/allow_fluid_potions/potion_pref = new
	potion_pref.set_value(prefs, allowed)
	human.cache_erp_preferences_from_prefs(prefs)

/datum/unit_test/fluid_potion_dose_applies_modifier/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	set_fluid_potion_pref(human, allocate(/datum/preferences), TRUE)

	human.reagents.add_reagent(/datum/reagent/fluid_potion/surge, FLUID_POTION_DOSE - 1)
	human.reagents.metabolize(human)
	TEST_ASSERT(!human.has_status_effect(/datum/status_effect/buff/fluid_potion/surge), "Less than a dose should not take effect.")

	human.reagents.add_reagent(/datum/reagent/fluid_potion/surge, FLUID_POTION_DOSE)
	human.reagents.metabolize(human)
	TEST_ASSERT(human.has_status_effect(/datum/status_effect/buff/fluid_potion/surge), "A full dose should apply the effect.")
	TEST_ASSERT(human.has_fluid_modifier(/datum/fluid_modifier/fluid_surge), "The effect should add its fluid modifier.")
	TEST_ASSERT_EQUAL(human.reagents.get_reagent_amount(/datum/reagent/fluid_potion/surge), 0, "The rest of the dose should be used up.")

	human.remove_status_effect(/datum/status_effect/buff/fluid_potion/surge)
	TEST_ASSERT(!human.has_fluid_modifier(/datum/fluid_modifier/fluid_surge), "The modifier should end with the effect.")

/datum/unit_test/fluid_potion_respects_pref/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	set_fluid_potion_pref(human, allocate(/datum/preferences), FALSE)

	human.reagents.add_reagent(/datum/reagent/fluid_potion/drought, FLUID_POTION_DOSE + 1)
	human.reagents.metabolize(human)
	TEST_ASSERT(!human.has_status_effect(/datum/status_effect/buff/fluid_potion/drought), "A body that refuses fluid potions should not be affected.")
	TEST_ASSERT_EQUAL(human.reagents.get_reagent_amount(/datum/reagent/fluid_potion/drought), 0, "A refused dose should still be used up.")

/datum/unit_test/fluid_potion_drought_stops_production/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.nutrition = NUTRITION_LEVEL_WELL_FED + 500
	var/obj/item/organ/genitals/filling_organ/testicles/testicles = allocate(/obj/item/organ/genitals/filling_organ/testicles)
	testicles.Insert(human, TRUE, FALSE)
	TEST_ASSERT_NOTNULL(testicles.reagents, "Inserted testicles should have a reagent holder.")
	testicles.reagents.clear_reagents()

	human.apply_status_effect(/datum/status_effect/buff/fluid_potion/drought)
	tick_organ_life(human, 3)
	TEST_ASSERT_EQUAL(testicles.reagents.total_volume, 0, "The drying draught should stop production.")

/datum/unit_test/fluid_potion_surge_and_ebb_scale_climax/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/testicles/testicles = allocate(/obj/item/organ/genitals/filling_organ/testicles)
	testicles.Insert(human, TRUE, FALSE)

	human.apply_status_effect(/datum/status_effect/buff/fluid_potion/surge)
	TEST_ASSERT_EQUAL(testicles.get_climax_multiplier(), 1.5, "The brimming draught should raise climax output.")
	TEST_ASSERT_EQUAL(testicles.get_production_multiplier(), 2, "The brimming draught should double production.")
	human.remove_status_effect(/datum/status_effect/buff/fluid_potion/surge)

	human.apply_status_effect(/datum/status_effect/buff/fluid_potion/ebb)
	TEST_ASSERT_EQUAL(testicles.get_climax_multiplier(), 0.5, "The ebbing draught should lower climax output.")
	TEST_ASSERT_EQUAL(testicles.get_production_multiplier(), 0.5, "The ebbing draught should halve production.")

/datum/unit_test/fluid_potion_lactation_inducer_boosts_milk/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/breasts/breasts = allocate(/obj/item/organ/genitals/filling_organ/breasts)
	breasts.produces_fluid = FALSE
	breasts.Insert(human, TRUE, FALSE)

	human.add_fluid_modifier(/datum/fluid_modifier/induced_lactation, FLUID_SOURCE_LACTATION_INDUCER)
	TEST_ASSERT(breasts.is_producing(), "Induced lactation should start milk.")
	TEST_ASSERT_EQUAL(breasts.get_production_multiplier(), 1.5, "Induced lactation should boost milk output.")

/datum/unit_test/fluid_swap_picks_largest_eligible_pair/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.reagents.add_reagent(/datum/reagent/medicine/healthpot, 40)
	human.reagents.add_reagent(/datum/reagent/consumable/aphrodisiac, 40)
	human.reagents.add_reagent(/datum/reagent/consumable/honey, 20)
	human.reagents.add_reagent(/datum/reagent/water, 10)

	TEST_ASSERT_EQUAL(find_fluid_swap_pair(human), /datum/reagent/consumable/honey, "The largest eligible reagent should be the pair.")
	TEST_ASSERT(is_fluid_swap_target(/datum/reagent/consumable/ethanol/beer), "Alcohol should be a valid swap target.")
	TEST_ASSERT(!is_fluid_swap_target(/datum/reagent/medicine/healthpot), "Medicine should not be a swap target.")
	TEST_ASSERT(!is_fluid_swap_target(/datum/reagent/consumable/cum), "Sexual fluids should not be swap targets.")

	human.reagents.clear_reagents()
	human.reagents.add_reagent(/datum/reagent/water, FLUID_SWAP_MIN_PAIR_VOLUME - 1)
	TEST_ASSERT_NULL(find_fluid_swap_pair(human), "A trace of a reagent should not count as a pair.")

/datum/unit_test/fluid_swap_potion_waits_then_binds/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	set_fluid_potion_pref(human, allocate(/datum/preferences), TRUE)
	human.nutrition = NUTRITION_LEVEL_WELL_FED + 500
	var/obj/item/organ/genitals/filling_organ/breasts/breasts = allocate(/obj/item/organ/genitals/filling_organ/breasts)
	breasts.produces_fluid = TRUE
	breasts.Insert(human, TRUE, FALSE)
	TEST_ASSERT_NOTNULL(breasts.reagents, "Inserted breasts should have a reagent holder.")
	breasts.reagents.clear_reagents()

	human.reagents.add_reagent(/datum/reagent/fluid_potion/swap/milk, FLUID_POTION_DOSE * 2)
	human.reagents.metabolize(human)
	TEST_ASSERT(!human.has_status_effect(/datum/status_effect/buff/fluid_swap/breasts), "A swap draught with nothing to pair should wait.")
	TEST_ASSERT(human.reagents.get_reagent_amount(/datum/reagent/fluid_potion/swap/milk) > 0, "A waiting swap draught should stay in the blood.")

	human.reagents.add_reagent(/datum/reagent/consumable/honey, 20)
	human.reagents.metabolize(human)
	TEST_ASSERT(human.has_status_effect(/datum/status_effect/buff/fluid_swap/breasts), "The swap draught should bind once a pair arrives.")
	TEST_ASSERT_EQUAL(breasts.get_produced_reagent(), /datum/reagent/consumable/honey, "Breasts should make the paired reagent.")
	TEST_ASSERT_EQUAL(breasts.get_nutrition_cost_per_unit(), 15 * FLUID_SWAP_NUTRITION_MARGIN, "Swapped honey should cost more nutrition than it gives.")

	tick_organ_life(human, 1)
	TEST_ASSERT(breasts.reagents.get_reagent_amount(/datum/reagent/consumable/honey) > 0, "Swapped breasts should fill with honey.")
	TEST_ASSERT_EQUAL(breasts.reagents.get_reagent_amount(breasts.reagent_to_make), 0, "Swapped breasts should not make milk.")

	human.remove_status_effect(/datum/status_effect/buff/fluid_swap/breasts)
	TEST_ASSERT_EQUAL(breasts.get_produced_reagent(), breasts.reagent_to_make, "Breasts should make milk again when the swap ends.")

/datum/unit_test/fluid_swap_replacement_keeps_new_swap/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)

	human.apply_status_effect(/datum/status_effect/buff/fluid_swap/testicles, null, /datum/reagent/consumable/honey)
	human.apply_status_effect(/datum/status_effect/buff/fluid_swap/testicles, null, /datum/reagent/water)
	TEST_ASSERT_EQUAL(LAZYACCESS(human.fluid_reagent_overrides, ORGAN_SLOT_TESTICLES), /datum/reagent/water, "A second swap should replace the first.")

	human.clear_fluid_reagent_override(ORGAN_SLOT_TESTICLES, /datum/reagent/consumable/honey)
	TEST_ASSERT_EQUAL(LAZYACCESS(human.fluid_reagent_overrides, ORGAN_SLOT_TESTICLES), /datum/reagent/water, "Ending an old swap must not end the newer one.")

	human.remove_status_effect(/datum/status_effect/buff/fluid_swap/testicles)
	TEST_ASSERT_NULL(human.fluid_reagent_overrides, "Removing the swap should clear the override.")

/datum/unit_test/fluid_swap_output_counts_as_own/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = allocate(/obj/item/organ/genitals/filling_organ/vagina)
	vagina.Insert(human, TRUE, FALSE)
	TEST_ASSERT_NOTNULL(vagina.reagents, "Inserted vagina should have a reagent holder.")
	ADD_TRAIT(vagina, TRAIT_PASSIVE_LEAK_BLOCKED, "unit_test")
	SEND_SIGNAL(human, COMSIG_SEX_SET_AROUSAL, 0)
	vagina.reagents.clear_reagents()
	vagina.reagents.add_reagent(/datum/reagent/water, 5)
	vagina.reagents.add_reagent(/datum/reagent/consumable/cum, 5)

	human.set_fluid_reagent_override(ORGAN_SLOT_VAGINA, /datum/reagent/water)
	TEST_ASSERT(vagina.is_own_fluid(/datum/reagent/water), "Swapped output should count as the organ's own fluid.")
	TEST_ASSERT(vagina.is_own_fluid(vagina.reagent_to_make), "The natural fluid should still count as own.")

	tick_organ_life(human, 1)
	TEST_ASSERT_EQUAL(vagina.reagents.get_reagent_amount(/datum/reagent/water), 5, "Swapped output should not be absorbed.")
	TEST_ASSERT(vagina.reagents.get_reagent_amount(/datum/reagent/consumable/cum) < 5, "Foreign fluid should still be absorbed.")

	human.clear_fluid_reagent_override(ORGAN_SLOT_VAGINA, /datum/reagent/water)
	TEST_ASSERT(!vagina.is_own_fluid(/datum/reagent/water), "Leftover swapped fluid should be foreign once the swap ends.")

/datum/unit_test/fluid_quirk_extra_productive_adds_modifier/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)

	human.add_quirk(/datum/quirk/peculiarity/extra_productive)
	TEST_ASSERT(human.has_fluid_modifier(/datum/fluid_modifier/extra_productive), "The quirk should add its modifier.")
	human.remove_quirk(/datum/quirk/peculiarity/extra_productive)
	TEST_ASSERT(!human.has_fluid_modifier(/datum/fluid_modifier/extra_productive), "Removing the quirk should remove its modifier.")

/datum/unit_test/fluid_quirk_relief_needed_aches_until_relieved/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/testicles/testicles = allocate(/obj/item/organ/genitals/filling_organ/testicles)
	testicles.Insert(human, TRUE, FALSE)
	TEST_ASSERT_NOTNULL(testicles.reagents, "Inserted testicles should have a reagent holder.")
	human.add_quirk(/datum/quirk/peculiarity/relief_needed)
	var/datum/quirk/peculiarity/relief_needed/quirk = locate() in human.quirks
	TEST_ASSERT_NOTNULL(quirk, "The quirk should be added.")
	SEND_SIGNAL(human, COMSIG_SEX_SET_AROUSAL, 0)

	testicles.reagents.clear_reagents()
	testicles.reagents.add_reagent(testicles.reagent_to_make, testicles.reagents.maximum_volume)
	quirk.on_life(human)
	TEST_ASSERT_NOTNULL(human.has_stress_type(/datum/stress_event/overfilled), "Full testicles should cause the overfilled mood.")
	var/list/arousal_data = list()
	SEND_SIGNAL(human, COMSIG_SEX_GET_AROUSAL, arousal_data)
	TEST_ASSERT(arousal_data["arousal"] > 0, "Full testicles should raise arousal.")
	var/datum/stress_event/overfilled/first_ache = human.has_stress_type(/datum/stress_event/overfilled)
	TEST_ASSERT_EQUAL(first_ache?.get_stress(), 2, "The first ache should cost 2 stress.")
	TEST_ASSERT(quirk.next_ache_message > world.time, "The first ache should send a reminder.")
	var/first_reminder = quirk.next_ache_message

	quirk.next_ache = 0
	quirk.on_life(human)
	TEST_ASSERT_EQUAL(quirk.next_ache_message, first_reminder, "A second ache should stay silent until the reminder timer ends.")
	var/datum/stress_event/overfilled/overfilled = human.has_stress_type(/datum/stress_event/overfilled)
	TEST_ASSERT_EQUAL(overfilled?.get_stress(), 3, "An ignored ache should grow worse.")

	testicles.reagents.remove_all(testicles.reagents.maximum_volume * 0.1)
	quirk.on_life(human)
	TEST_ASSERT_NOTNULL(human.has_stress_type(/datum/stress_event/overfilled), "A slight drop should not bring relief yet.")

	testicles.reagents.clear_reagents()
	quirk.on_life(human)
	TEST_ASSERT_NULL(human.has_stress_type(/datum/stress_event/overfilled), "Emptying the organ should bring relief.")

	testicles.reagents.add_reagent(testicles.reagent_to_make, testicles.reagents.maximum_volume)
	quirk.on_life(human)
	TEST_ASSERT_NOTNULL(human.has_stress_type(/datum/stress_event/overfilled), "Refilling should bring the ache back at once.")
	TEST_ASSERT_EQUAL(quirk.next_ache_message, first_reminder, "A quick refill should not repeat the reminder.")

/datum/unit_test/fluid_potions_are_brewable_and_sold/Run()
	var/list/potion_vials = list(
		/datum/reagent/fluid_potion/surge = /obj/item/reagent_containers/glass/bottle/vial/fluid_surge,
		/datum/reagent/fluid_potion/ebb = /obj/item/reagent_containers/glass/bottle/vial/fluid_ebb,
		/datum/reagent/fluid_potion/drought = /obj/item/reagent_containers/glass/bottle/vial/fluid_drought,
		/datum/reagent/consumable/lactation_inducer = /obj/item/reagent_containers/glass/bottle/vial/lactation_inducer,
		/datum/reagent/fluid_potion/swap/milk = /obj/item/reagent_containers/glass/bottle/vial/milk_swap,
		/datum/reagent/fluid_potion/swap/seed = /obj/item/reagent_containers/glass/bottle/vial/seed_swap,
		/datum/reagent/fluid_potion/swap/nectar = /obj/item/reagent_containers/glass/bottle/vial/nectar_swap,
		/datum/reagent/fluid_potion/contraceptive/moon_tea = /obj/item/reagent_containers/glass/bottle/vial/moon_tea,
		/datum/reagent/fluid_potion/contraceptive/cold_seed = /obj/item/reagent_containers/glass/bottle/vial/cold_seed,
	)
	var/list/brewed = list()
	for(var/recipe_type in subtypesof(/datum/alch_cauldron_recipe))
		var/datum/alch_cauldron_recipe/recipe = new recipe_type()
		for(var/reagent_type in recipe.output_reagents)
			brewed[reagent_type] = TRUE
		qdel(recipe)
	var/list/sold = list()
	for(var/datum/supply_pack/pack_type as anything in subtypesof(/datum/supply_pack))
		var/contains = initial(pack_type.contains)
		if(ispath(contains))
			sold[contains] = TRUE
	for(var/reagent_type in potion_vials)
		TEST_ASSERT(brewed[reagent_type], "[reagent_type] should have a cauldron recipe.")
		TEST_ASSERT(sold[potion_vials[reagent_type]], "[potion_vials[reagent_type]] should be sold in a supply pack.")

/datum/unit_test/fluid_potions_have_herbal_brews/Run()
	var/mob/living/carbon/human/brewer = allocate(/mob/living/carbon/human)
	brewer.mind_initialize()
	var/list/brewed = list()
	for(var/datum/container_craft/cooking/herbal_tea/fluid_brew/recipe_type as anything in subtypesof(/datum/container_craft/cooking/herbal_tea/fluid_brew))
		var/datum/container_craft/cooking/herbal_tea/fluid_brew/recipe = allocate(recipe_type)
		var/obj/item/reagent_containers/glass/bucket/pot/pot = allocate(/obj/item/reagent_containers/glass/bucket/pot)
		pot.reagents.add_reagent(/datum/reagent/water, 20)
		for(var/herb_type in recipe.requirements)
			for(var/i in 1 to recipe.requirements[herb_type])
				allocate(herb_type, pot)
		recipe.execute_craft_completion(pot, brewer, 1)
		TEST_ASSERT_EQUAL(pot.reagents.get_reagent_amount(recipe.created_reagent), 10, "[recipe.name] should brew ten measures from twenty of water.")
		brewed[recipe.created_reagent] = TRUE
	for(var/reagent_type in list(
		/datum/reagent/fluid_potion/surge,
		/datum/reagent/fluid_potion/ebb,
		/datum/reagent/fluid_potion/drought,
		/datum/reagent/consumable/lactation_inducer,
		/datum/reagent/fluid_potion/contraceptive/moon_tea,
		/datum/reagent/fluid_potion/contraceptive/cold_seed,
	))
		TEST_ASSERT(brewed[reagent_type], "[reagent_type] should have a herbal brew.")
	for(var/swap_type in subtypesof(/datum/reagent/fluid_potion/swap))
		TEST_ASSERT(!brewed[swap_type], "[swap_type] should stay cauldron-only.")

/datum/unit_test/fluid_potion_activation_purges_stomach/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	set_fluid_potion_pref(human, allocate(/datum/preferences), TRUE)
	var/obj/item/organ/stomach/stomach = human.getorganslot(ORGAN_SLOT_STOMACH)
	TEST_ASSERT_NOTNULL(stomach?.reagents, "The test human should have a stomach with reagents.")

	stomach.reagents.add_reagent(/datum/reagent/fluid_potion/surge, 10)
	human.reagents.add_reagent(/datum/reagent/fluid_potion/surge, FLUID_POTION_DOSE)
	human.reagents.metabolize(human)
	TEST_ASSERT(human.has_status_effect(/datum/status_effect/buff/fluid_potion/surge), "A full dose in the blood should apply the effect.")
	TEST_ASSERT_EQUAL(stomach.reagents.get_reagent_amount(/datum/reagent/fluid_potion/surge), 0, "Leftover potion in the stomach should be used up too.")

/datum/unit_test/fluid_swap_unbound_is_admin_only/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	set_fluid_potion_pref(human, allocate(/datum/preferences), TRUE)
	var/obj/item/organ/genitals/filling_organ/breasts/breasts = allocate(/obj/item/organ/genitals/filling_organ/breasts)
	breasts.produces_fluid = TRUE
	breasts.Insert(human, TRUE, FALSE)

	human.reagents.add_reagent(/datum/reagent/fluid_potion/swap/milk/unbound, 20)
	human.reagents.add_reagent(/datum/reagent/medicine/healthpot, 10)
	TEST_ASSERT_NULL(find_fluid_swap_pair(human), "A normal swap must refuse medicine.")
	TEST_ASSERT_EQUAL(find_fluid_swap_pair(human, TRUE), /datum/reagent/medicine/healthpot, "An unbound swap should pair with medicine, never with a fluid potion.")

	human.reagents.metabolize(human)
	TEST_ASSERT_EQUAL(breasts.get_produced_reagent(), /datum/reagent/medicine/healthpot, "Unbound swapped breasts should make the medicine.")

	var/list/unbound_reagents = list(
		/datum/reagent/fluid_potion/swap/milk/unbound,
		/datum/reagent/fluid_potion/swap/seed/unbound,
		/datum/reagent/fluid_potion/swap/nectar/unbound,
	)
	for(var/datum/reagent/reagent_type as anything in unbound_reagents)
		TEST_ASSERT(!initial(reagent_type.can_synth), "[reagent_type] must stay out of random reagent pools.")
	for(var/recipe_type in subtypesof(/datum/alch_cauldron_recipe))
		var/datum/alch_cauldron_recipe/recipe = new recipe_type()
		for(var/reagent_type in recipe.output_reagents)
			TEST_ASSERT(!(reagent_type in unbound_reagents), "[recipe_type] must not brew an unbound swap.")
		qdel(recipe)
	for(var/datum/supply_pack/pack_type as anything in subtypesof(/datum/supply_pack))
		var/contains = initial(pack_type.contains)
		TEST_ASSERT(!ispath(contains, /obj/item/reagent_containers/glass/bottle/vial/milk_swap/unbound), "[pack_type] must not sell an unbound swap.")
		TEST_ASSERT(!ispath(contains, /obj/item/reagent_containers/glass/bottle/vial/seed_swap/unbound), "[pack_type] must not sell an unbound swap.")
		TEST_ASSERT(!ispath(contains, /obj/item/reagent_containers/glass/bottle/vial/nectar_swap/unbound), "[pack_type] must not sell an unbound swap.")

/datum/unit_test/expel_fluids_clears_own_and_foreign/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = allocate(/obj/item/organ/genitals/filling_organ/vagina)
	vagina.Insert(human, TRUE, FALSE)
	TEST_ASSERT_NOTNULL(vagina.reagents, "Inserted vagina should have a reagent holder.")
	var/datum/sex_action/hole_storage/expel_foreign_fluids/vaginal/action = allocate(/datum/sex_action/hole_storage/expel_foreign_fluids/vaginal)
	var/obj/item/reagent_containers/glass/bucket/bucket = allocate(/obj/item/reagent_containers/glass/bucket)
	TEST_ASSERT(action.can_collect_into(bucket), "The test bucket should accept fluid.")

	vagina.reagents.clear_reagents()
	vagina.reagents.add_reagent(vagina.reagent_to_make, 5)
	TEST_ASSERT_EQUAL(action.get_held_fluid_volume(vagina), 5, "Own fluid alone should be expellable.")

	vagina.reagents.add_reagent(/datum/reagent/consumable/cum, 5)
	action.transfer_fluids_to_container(vagina, bucket, human)
	TEST_ASSERT_EQUAL(vagina.reagents.total_volume, 0, "Expelling into a container should clear every fluid.")
	TEST_ASSERT_EQUAL(bucket.reagents.get_reagent_amount(vagina.reagent_to_make), 5, "Own fluid should be collected too.")

	vagina.reagents.add_reagent(vagina.reagent_to_make, 5)
	vagina.reagents.add_reagent(/datum/reagent/consumable/cum, 5)
	action.spill_fluids_to_floor(vagina, get_turf(human))
	TEST_ASSERT_EQUAL(vagina.reagents.total_volume, 0, "Expelling onto the floor should clear every fluid.")
