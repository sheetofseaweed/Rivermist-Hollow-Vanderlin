/// A human with lactating breasts, fed and stamped once, for taste tests.
/proc/make_taste_test_mother(datum/unit_test/test)
	var/mob/living/carbon/human/mother = test.allocate(/mob/living/carbon/human)
	mother.nutrition = NUTRITION_LEVEL_WELL_FED
	var/obj/item/organ/genitals/filling_organ/breasts/breasts = test.allocate(/obj/item/organ/genitals/filling_organ/breasts)
	breasts.produces_fluid = TRUE
	breasts.Insert(mother, TRUE, FALSE)
	breasts.reagents.clear_reagents()
	breasts.reagents.add_reagent(/datum/reagent/consumable/milk, 30)
	tick_organ_life(mother, 1)
	return mother

/datum/unit_test/fluid_taste_breast_milk_knows_its_maker/Run()
	var/mob/living/carbon/human/mother = make_taste_test_mother(src)
	var/obj/item/organ/genitals/filling_organ/breasts/breasts = mother.getorganslot(ORGAN_SLOT_BREASTS)
	var/datum/reagent/consumable/milk/milk = breasts.reagents.get_reagent(/datum/reagent/consumable/milk)
	TEST_ASSERT_EQUAL(milk?.get_fluid_donor(), mother, "Breast milk should know its maker.")

	var/obj/item/reagent_containers/glass/bucket/bucket = allocate(/obj/item/reagent_containers/glass/bucket)
	bucket.reagents.add_reagent(/datum/reagent/consumable/milk, 10)
	var/datum/reagent/consumable/milk/cow_milk = bucket.reagents.get_reagent(/datum/reagent/consumable/milk)
	TEST_ASSERT_NULL(cow_milk.get_fluid_donor(), "Cow milk should have no maker.")
	var/runtimed = FALSE
	try
		breasts.reagents.trans_to(bucket, 5)
	catch
		runtimed = TRUE
	TEST_ASSERT(!runtimed, "Pouring stamped milk into plain milk should not runtime.")
	TEST_ASSERT_EQUAL(cow_milk.get_fluid_donor(), mother, "Anonymous milk should take on the only maker in it.")

	var/mob/living/carbon/human/other_mother = make_taste_test_mother(src)
	var/obj/item/organ/genitals/filling_organ/breasts/other_breasts = other_mother.getorganslot(ORGAN_SLOT_BREASTS)
	other_breasts.reagents.trans_to(bucket, 5)
	TEST_ASSERT_NULL(cow_milk.get_fluid_donor(), "Milk from two mothers should belong to neither.")
	breasts.reagents.trans_to(bucket, 5)
	TEST_ASSERT_NULL(cow_milk.get_fluid_donor(), "Once mixed, more milk from one mother should not make it hers.")

/datum/unit_test/fluid_taste_grows_familiar_after_an_hour/Run()
	var/mob/living/carbon/human/mother = make_taste_test_mother(src)
	var/obj/item/organ/genitals/filling_organ/breasts/breasts = mother.getorganslot(ORGAN_SLOT_BREASTS)
	var/mob/living/carbon/human/drinker = allocate(/mob/living/carbon/human)
	drinker.mind = allocate(/datum/mind, "taste-test-drinker")
	drinker.mind.current = drinker

	breasts.reagents.trans_to(drinker, 2, method = INGEST)
	var/list/memory = LAZYACCESS(drinker.mind.fluid_taste_memory, WEAKREF(mother))
	TEST_ASSERT_EQUAL(memory?["visits"], 1, "A first taste should be remembered.")
	TEST_ASSERT_NULL(drinker.has_stress_type(/datum/stress_event/familiar_taste), "A first taste should not feel familiar yet.")

	breasts.reagents.trans_to(drinker, 2, method = INGEST)
	TEST_ASSERT_EQUAL(memory["visits"], 1, "Tasting again within the hour should not count as a visit.")

	memory["visit"] -= FAMILIAR_TASTE_GAP
	breasts.reagents.trans_to(drinker, 2, method = INGEST)
	TEST_ASSERT_EQUAL(memory["visits"], 2, "Tasting again after an hour should be a new visit.")
	TEST_ASSERT_NOTNULL(drinker.has_stress_type(/datum/stress_event/familiar_taste), "A familiar taste should lift the mood.")

	memory["visit"] -= FAMILIAR_TASTE_GAP
	breasts.reagents.trans_to(drinker, 2, method = INGEST)
	TEST_ASSERT_NOTNULL(drinker.has_stress_type(/datum/stress_event/cherished_taste), "A third visit should make the taste cherished.")

	var/obj/item/organ/genitals/filling_organ/vagina/womb = allocate(/obj/item/organ/genitals/filling_organ/vagina)
	womb.Insert(drinker, TRUE, FALSE)
	memory["visit"] -= FAMILIAR_TASTE_GAP
	breasts.reagents.trans_to(drinker, 2, method = TOUCH)
	breasts.reagents.trans_to(womb, 2, method = INGEST)
	TEST_ASSERT_EQUAL(memory["visits"], FAMILIAR_TASTE_CHERISHED_VISITS, "Splashes and fluid put into a womb should not count as tastes.")

	mother.mind = allocate(/datum/mind, "taste-test-mother")
	mother.mind.current = mother
	breasts.reagents.trans_to(mother, 2, method = INGEST)
	TEST_ASSERT_NULL(mother.mind.fluid_taste_memory, "Nobody should learn their own taste.")

	var/mob/living/carbon/human/numb = allocate(/mob/living/carbon/human)
	numb.mind = allocate(/datum/mind, "taste-test-numb")
	numb.mind.current = numb
	ADD_TRAIT(numb, TRAIT_AGEUSIA, "unit_test")
	breasts.reagents.trans_to(numb, 2, method = INGEST)
	TEST_ASSERT_NULL(numb.mind.fluid_taste_memory, "Someone who cannot taste should learn nothing.")

	for(var/mob/living/carbon/human/person as anything in list(drinker, mother, numb))
		person.mind.current = null
		person.mind = null

/datum/unit_test/fluid_taste_carries_a_hint_of_the_diet/Run()
	var/mob/living/carbon/human/mother = make_taste_test_mother(src)
	var/obj/item/organ/genitals/filling_organ/breasts/breasts = mother.getorganslot(ORGAN_SLOT_BREASTS)
	var/datum/reagent/consumable/milk/milk = breasts.reagents.get_reagent(/datum/reagent/consumable/milk)
	TEST_ASSERT_EQUAL(milk.get_taste_description(), milk.taste_description, "Milk should taste plain without a diet.")

	var/obj/item/reagent_containers/food/snacks/fruit = allocate(/obj/item/reagent_containers/food/snacks)
	fruit.foodtype = FRUIT
	SEND_SIGNAL(mother, COMSIG_MOB_FOOD_EAT, fruit)
	SEND_SIGNAL(mother, COMSIG_MOB_FOOD_EAT, fruit)
	breasts.stamp_own_fluids()
	TEST_ASSERT(findtext(milk.get_taste_description(), "hint of something fruity"), "Eating fruit should flavour the milk, got [milk.get_taste_description()].")

	var/obj/item/reagent_containers/glass/bucket/bucket = allocate(/obj/item/reagent_containers/glass/bucket)
	breasts.reagents.trans_to(bucket, 5)
	TEST_ASSERT(findtext(bucket.reagents.generate_taste_message(0), "fruity"), "The hint should travel with the milk into the taste message.")

	mother.reagents.add_reagent(/datum/reagent/consumable/ethanol, 20)
	breasts.stamp_own_fluids()
	TEST_ASSERT(findtext(milk.get_taste_description(), "boozy"), "Strong drink should make the milk taste boozy.")

	mother.reagents.clear_reagents()
	breasts.diet_faded_at -= 1 HOURS
	breasts.stamp_own_fluids()
	TEST_ASSERT_EQUAL(milk.get_taste_description(), milk.taste_description, "The hint should fade after an hour.")

/datum/unit_test/fluid_taste_seed_and_nectar_know_their_maker/Run()
	var/obj/item/reagent_containers/glass/bucket/seed_bucket = allocate(/obj/item/reagent_containers/glass/bucket)
	var/obj/item/reagent_containers/glass/bucket/nectar_bucket = allocate(/obj/item/reagent_containers/glass/bucket)
	var/list/makers = list()
	for(var/i in 1 to 2)
		var/mob/living/carbon/human/maker = allocate(/mob/living/carbon/human)
		var/obj/item/organ/genitals/penis/penis = allocate(/obj/item/organ/genitals/penis)
		penis.Insert(maker, TRUE, FALSE)
		var/obj/item/organ/genitals/filling_organ/testicles/testicles = allocate(/obj/item/organ/genitals/filling_organ/testicles)
		testicles.Insert(maker, TRUE, FALSE)
		var/obj/item/organ/genitals/filling_organ/vagina/vagina = allocate(/obj/item/organ/genitals/filling_organ/vagina)
		vagina.Insert(maker, TRUE, FALSE)
		vagina.reagents.add_reagent(vagina.reagent_to_make, 10)
		// Stamped directly: a life tick would let the bare vagina leak before the pour.
		testicles.sync_cum_source_data()
		vagina.tag_femcum_donor()
		makers += maker
		testicles.reagents.trans_to(seed_bucket, 5)
		vagina.reagents.trans_to(nectar_bucket, 5)
		var/datum/reagent/seed = seed_bucket.reagents.get_reagent(/datum/reagent/consumable/cum)
		var/datum/reagent/nectar = nectar_bucket.reagents.get_reagent(/datum/reagent/consumable/femcum)
		if(i == 1)
			TEST_ASSERT_EQUAL(seed?.get_fluid_donor(), maker, "Seed should know its maker.")
			TEST_ASSERT_EQUAL(nectar?.get_fluid_donor(), maker, "Nectar should know its maker.")
		else
			TEST_ASSERT_NULL(seed?.get_fluid_donor(), "Seed from two makers should belong to neither.")
			TEST_ASSERT_NULL(nectar?.get_fluid_donor(), "Nectar from two makers should belong to neither.")
	var/mob/living/carbon/human/first_maker = makers[1]
	var/obj/item/organ/genitals/filling_organ/testicles/first_balls = first_maker.getorganslot(ORGAN_SLOT_TESTICLES)
	var/obj/item/organ/genitals/filling_organ/vagina/first_vagina = first_maker.getorganslot(ORGAN_SLOT_VAGINA)
	first_balls.reagents.trans_to(seed_bucket, 5)
	first_vagina.reagents.trans_to(nectar_bucket, 3)
	var/datum/reagent/mixed_seed = seed_bucket.reagents.get_reagent(/datum/reagent/consumable/cum)
	var/datum/reagent/mixed_nectar = nectar_bucket.reagents.get_reagent(/datum/reagent/consumable/femcum)
	TEST_ASSERT_NULL(mixed_seed.get_fluid_donor(), "Once mixed, more seed from one maker should not make it theirs.")
	TEST_ASSERT_NULL(mixed_nectar.get_fluid_donor(), "Once mixed, more nectar from one maker should not make it theirs.")
