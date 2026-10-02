/datum/unit_test/species_fluid_flavours_cover_playable_species/Run()
	for(var/species_id in GLOB.roundstart_species)
		var/datum/species/species_type = GLOB.species_list[species_id]
		// Plain humans are the baseline everyone else is compared to.
		if(species_type == /datum/species/human/northern)
			continue
		var/list/fluids = list(
			/datum/reagent/consumable/cum = initial(species_type.cum),
			/datum/reagent/consumable/femcum = initial(species_type.femcum),
			/datum/reagent/consumable/milk = initial(species_type.breast_milk),
		)
		for(var/datum/reagent/base_type as anything in fluids)
			var/datum/reagent/species_fluid = fluids[base_type]
			TEST_ASSERT(ispath(species_fluid, base_type) && species_fluid != base_type, "[species_type] should have its own [initial(base_type.name)].")
			TEST_ASSERT_NOTEQUAL(initial(species_fluid.taste_description), initial(base_type.taste_description), "[species_fluid] should taste different from plain [initial(base_type.name)].")

/datum/unit_test/species_fluid_modifiers_follow_species/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.set_species(/datum/species/goblin/player)
	TEST_ASSERT(human.has_fluid_modifier(/datum/fluid_modifier/small_frame, FLUID_SOURCE_SPECIES), "Goblins should have a small frame.")
	TEST_ASSERT(human.has_fluid_modifier(/datum/fluid_modifier/prolific_seed, FLUID_SOURCE_SPECIES), "Goblins should make seed faster.")
	TEST_ASSERT_EQUAL(human.cum, /datum/reagent/consumable/cum/goblinp/player, "Player goblins should make their own seed.")
	TEST_ASSERT_EQUAL(human.breast_milk, /datum/reagent/consumable/milk/goblin, "Goblins should make their own milk.")

	var/obj/item/organ/genitals/filling_organ/breasts/breasts = allocate(/obj/item/organ/genitals/filling_organ/breasts)
	breasts.Insert(human, TRUE, FALSE)
	TEST_ASSERT(abs(breasts.get_reagent_capacity() - breasts.get_base_capacity() * 0.75) < 0.01, "A small frame should hold three quarters as much.")

	human.set_species(/datum/species/ogre)
	TEST_ASSERT(!human.has_fluid_modifier(/datum/fluid_modifier/small_frame), "Leaving a species should remove its frame.")
	TEST_ASSERT(!human.has_fluid_modifier(/datum/fluid_modifier/prolific_seed), "Leaving a species should remove its seed boost.")
	TEST_ASSERT(human.has_fluid_modifier(/datum/fluid_modifier/large_frame, FLUID_SOURCE_SPECIES), "Ogres should have a large frame.")
	TEST_ASSERT_EQUAL(human.breast_milk, /datum/reagent/consumable/milk/ogre, "Ogres should make their own milk.")

/datum/unit_test/species_milk_salts_into_cheese/Run()
	var/obj/item/reagent_containers/glass/bucket/bucket = allocate(/obj/item/reagent_containers/glass/bucket)
	bucket.reagents.add_reagent(/datum/reagent/consumable/milk/halfling, 20)
	bucket.reagents.add_reagent(/datum/reagent/consumable/milk/gote, 15)
	bucket.reagents.add_reagent(/datum/reagent/consumable/milk/salted, 30)

	TEST_ASSERT_EQUAL(bucket.salt_milks(), 2, "Species milk and gote milk should both salt.")
	TEST_ASSERT_EQUAL(bucket.reagents.get_reagent_amount(/datum/reagent/consumable/milk/halfling), 5, "Salting should use 15 units of species milk.")
	TEST_ASSERT_EQUAL(bucket.reagents.get_reagent_amount(/datum/reagent/consumable/milk/salted), 45, "Species milk should salt like cow milk.")
	TEST_ASSERT_EQUAL(bucket.reagents.get_reagent_amount(/datum/reagent/consumable/milk/salted_gote), 15, "Gote milk should still salt into its own kind.")
	TEST_ASSERT_EQUAL(bucket.salt_milks(), 0, "Salted milk and small leftovers should not salt again.")
