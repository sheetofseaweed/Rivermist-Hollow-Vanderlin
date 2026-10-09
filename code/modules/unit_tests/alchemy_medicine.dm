/datum/unit_test/health_potion_heals_moderate_toxin_damage
#ifdef FOCUS_ALCHEMY_MEDICINE_TEST
	focus = TRUE
#endif

/datum/unit_test/health_potion_heals_moderate_toxin_damage/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	patient.adjustToxLoss(20, updating_health = FALSE, forced = TRUE)
	var/starting_tox = patient.getToxLoss()
	TEST_ASSERT(starting_tox > 0, "Test setup should give the patient toxin damage.")

	var/datum/reagent/medicine/healthpot/potion = allocate(/datum/reagent/medicine/healthpot)
	potion.volume = 5
	potion.on_mob_life(patient, 1)

	var/healed_tox = starting_tox - patient.getToxLoss()
	TEST_ASSERT(healed_tox >= 4, "Health potions should heal a moderate amount of toxin damage.")

/datum/unit_test/antidote_has_single_recipe_and_merchant_pack
#ifdef FOCUS_ALCHEMY_MEDICINE_TEST
	focus = TRUE
#endif

/datum/unit_test/antidote_has_single_recipe_and_merchant_pack/Run()
	var/antidote_recipe_count = 0
	for(var/recipe_type in subtypesof(/datum/alch_cauldron_recipe))
		var/datum/alch_cauldron_recipe/recipe = new recipe_type()
		if(recipe.output_reagents && recipe.output_reagents[/datum/reagent/medicine/antidote])
			antidote_recipe_count++
		qdel(recipe)

	TEST_ASSERT_EQUAL(antidote_recipe_count, 1, "Exactly one alchemy cauldron recipe should produce antidote.")

	var/antidote_pack_count = 0
	var/antidote_pack_type = text2path("/datum/supply_pack/tools/medical/antidote")
	for(var/datum/supply_pack/pack_type as anything in subtypesof(/datum/supply_pack))
		var/contains = initial(pack_type.contains)
		if(islist(contains))
			if(/obj/item/reagent_containers/glass/bottle/antidote in contains)
				antidote_pack_count++
		else if(contains == /obj/item/reagent_containers/glass/bottle/antidote)
			antidote_pack_count++

	TEST_ASSERT_EQUAL(antidote_pack_count, 1, "Exactly one merchant supply pack should sell bottled antidote.")
	TEST_ASSERT_NOTNULL(antidote_pack_type, "The antidote supply pack type should exist.")

	var/antidote_pack_listed = FALSE
	for(var/faction_type in subtypesof(/datum/world_faction))
		var/datum/world_faction/faction = new faction_type()
		if((antidote_pack_type in faction.essential_packs) || (antidote_pack_type in faction.common_pool) || (antidote_pack_type in faction.uncommon_pool) || (antidote_pack_type in faction.rare_pool) || (antidote_pack_type in faction.exotic_pool))
			antidote_pack_listed = TRUE
		qdel(faction)
		if(antidote_pack_listed)
			break

	TEST_ASSERT(antidote_pack_listed, "The antidote supply pack should be reachable from a world faction merchant pool.")

/datum/unit_test/herbal_decoction_dried_batches
#ifdef FOCUS_ALCHEMY_MEDICINE_TEST
	focus = TRUE
#endif

/datum/unit_test/herbal_decoction_dried_batches/Run()
	var/mob/living/carbon/human/brewer = allocate(/mob/living/carbon/human)
	brewer.mind_initialize()
	for(var/datum/container_craft/cooking/herbal_decoction/recipe_type as anything in subtypesof(/datum/container_craft/cooking/herbal_decoction))
		if(IS_ABSTRACT(recipe_type))
			continue
		var/datum/container_craft/cooking/herbal_decoction/recipe = allocate(recipe_type)
		var/obj/item/reagent_containers/glass/bucket/pot/pot = allocate(/obj/item/reagent_containers/glass/bucket/pot)
		pot.reagents.add_reagent(/datum/reagent/water, 50)
		for(var/herb_type in recipe.requirements)
			for(var/i in 1 to recipe.requirements[herb_type] * 2)
				var/obj/item/alch/herb/herb = allocate(herb_type, pot)
				herb.finish_drying()
		recipe.execute_craft_completion(pot, brewer, 2)
		var/datum/reagent/medicine/herbal/decoction/product = pot.reagents.get_reagent(recipe.created_reagent)
		TEST_ASSERT(istype(product), "[recipe.name] should produce a strength-aware decoction.")
		TEST_ASSERT_EQUAL(product.volume, 20, "[recipe.name] should yield ten measures per batch.")
		TEST_ASSERT_EQUAL(product.herbal_strength, 1, "Repeated dry batches of [recipe.name] should stay full strength.")
		TEST_ASSERT_EQUAL(pot.reagents.total_volume, 20, "[recipe.name] should consume all fifty measures of water.")

/datum/unit_test/herbal_decoction_strength_survives_pouring
#ifdef FOCUS_ALCHEMY_MEDICINE_TEST
	focus = TRUE
#endif

/datum/unit_test/herbal_decoction_strength_survives_pouring/Run()
	var/mob/living/carbon/human/brewer = allocate(/mob/living/carbon/human)
	brewer.mind_initialize()
	var/datum/container_craft/cooking/herbal_decoction/recipe = allocate(/datum/container_craft/cooking/herbal_tea/artemisia_luck)
	var/obj/item/reagent_containers/glass/bucket/pot/pot = allocate(/obj/item/reagent_containers/glass/bucket/pot)
	var/obj/item/reagent_containers/glass/bottle/first_bottle = allocate(/obj/item/reagent_containers/glass/bottle)
	var/obj/item/reagent_containers/glass/bottle/second_bottle = allocate(/obj/item/reagent_containers/glass/bottle)
	for(var/batch in 1 to 2)
		pot.reagents.add_reagent(/datum/reagent/water, 25)
		for(var/i in 1 to 2)
			var/obj/item/alch/herb/herb = allocate(/obj/item/alch/herb/artemisia, pot)
			herb.finish_drying()
		recipe.execute_craft_completion(pot, brewer, 1)
		pot.reagents.trans_to(first_bottle, 10)
	var/datum/reagent/medicine/herbal/decoction/product = first_bottle.reagents.get_reagent(recipe.created_reagent)
	TEST_ASSERT_EQUAL(product.herbal_strength, 1, "Pouring dry batches together should preserve full strength.")
	first_bottle.reagents.trans_to(second_bottle, 10)

	pot.reagents.add_reagent(/datum/reagent/water, 25)
	var/obj/item/alch/herb/dried_herb = allocate(/obj/item/alch/herb/artemisia, pot)
	dried_herb.finish_drying()
	allocate(/obj/item/alch/herb/artemisia, pot)
	recipe.execute_craft_completion(pot, brewer, 1)
	product = pot.reagents.get_reagent(recipe.created_reagent)
	TEST_ASSERT_EQUAL(product.herbal_strength, 0.5, "One fresh herb should make a mixed preparation half strength.")
	pot.reagents.trans_to(first_bottle, 10)
	product = first_bottle.reagents.get_reagent(recipe.created_reagent)
	TEST_ASSERT_EQUAL(product.herbal_strength, 0.5, "Fresh medicine poured into dry medicine should keep the weaker strength.")
	second_bottle.reagents.trans_to(first_bottle, 10)
	TEST_ASSERT_EQUAL(product.herbal_strength, 0.5, "Dry medicine must not upgrade an existing weak mixture.")
	pot.reagents.add_reagent(recipe.created_reagent, 5)
	pot.reagents.add_reagent(recipe.created_reagent, 5)
	product = pot.reagents.get_reagent(recipe.created_reagent)
	TEST_ASSERT_EQUAL(product.herbal_strength, 0.5, "Medicine without preparation data should default to half strength.")
	TEST_ASSERT_EQUAL(product.data["herbal_strength"], 0.5, "Merging medicine without preparation data should create transferable strength data.")

/datum/unit_test/herbal_anodyne_delivery_and_cleanup
#ifdef FOCUS_ALCHEMY_MEDICINE_TEST
	focus = TRUE
#endif

/datum/unit_test/herbal_anodyne_delivery_and_cleanup/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	var/obj/item/bodypart/arm = patient.get_bodypart(BODY_ZONE_L_ARM)
	var/obj/item/natural/cloth/bandage = allocate(/obj/item/natural/cloth)
	arm.bandage = bandage
	bandage.reagents.add_reagent(/datum/reagent/medicine/herbal/anodyne/atropa, 5, list("herbal_strength" = 1))
	for(var/i in 1 to 30)
		arm.apply_bandage_reagents()
	TEST_ASSERT_EQUAL(bandage.reagents.total_volume, 0, "The bandage should consume its anodyne.")
	TEST_ASSERT_EQUAL(patient.get_chem_effect(CE_PAINKILLER), 0, "Oral anodyne on a bandage must not leave a permanent painkiller effect.")
	arm.bandage = null

	patient.reagents.add_reagent(/datum/reagent/medicine/herbal/anodyne/atropa, 5, list("herbal_strength" = 1))
	var/datum/reagent/medicine/herbal/decoction/anodyne = patient.reagents.get_reagent(/datum/reagent/medicine/herbal/anodyne/atropa)
	anodyne.metabolizing = TRUE
	anodyne.on_mob_metabolize(patient)
	anodyne.on_mob_life(patient, 1)
	TEST_ASSERT_EQUAL(patient.get_chem_effect(CE_PAINKILLER), 8, "Dry oral anodyne should relieve pain.")
	patient.reagents.add_reagent(anodyne.type, 5, list("herbal_strength" = 0.5))
	anodyne.on_mob_life(patient, 1)
	TEST_ASSERT_EQUAL(patient.get_chem_effect(CE_PAINKILLER), 4, "Mixing in weak anodyne should refresh the active effect.")
	patient.reagents.clear_reagents()
	TEST_ASSERT_EQUAL(patient.get_chem_effect(CE_PAINKILLER), 0, "Removing oral anodyne should remove its painkiller effect.")

/datum/unit_test/herbal_decoction_healing_strength
#ifdef FOCUS_ALCHEMY_MEDICINE_TEST
	focus = TRUE
#endif

/datum/unit_test/herbal_decoction_healing_strength/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	patient.adjustToxLoss(20, updating_health = FALSE, forced = TRUE)
	patient.reagents.add_reagent(/datum/reagent/medicine/herbal/decoction/artemisia, 5, list("herbal_strength" = 1))
	var/datum/reagent/medicine/herbal/decoction/remedy = patient.reagents.get_reagent(/datum/reagent/medicine/herbal/decoction/artemisia)
	var/starting_tox = patient.getToxLoss()
	remedy.on_bodypart_absorb(patient.get_bodypart(BODY_ZONE_L_ARM), patient, 1)
	TEST_ASSERT_EQUAL(patient.getToxLoss(), starting_tox, "A bandaged decoction must not heal internal toxin damage.")
	remedy.on_mob_life(patient, 1)
	var/dry_healing = starting_tox - patient.getToxLoss()
	TEST_ASSERT(dry_healing > 0, "The dry decoction should heal toxin damage orally.")
	patient.reagents.add_reagent(remedy.type, 5, list("herbal_strength" = 0.5))
	starting_tox = patient.getToxLoss()
	remedy.on_mob_life(patient, 1)
	TEST_ASSERT_EQUAL(starting_tox - patient.getToxLoss(), dry_healing / 2, "The fresh mixture should heal at half strength.")

/datum/unit_test/herbal_atropa_precursor_chains
#ifdef FOCUS_ALCHEMY_MEDICINE_TEST
	focus = TRUE
#endif

/datum/unit_test/herbal_atropa_precursor_chains/Run()
	var/mob/living/carbon/human/brewer = allocate(/mob/living/carbon/human)
	brewer.mind_initialize()
	var/datum/herbal_mortar_recipe/extraction = allocate(/datum/herbal_mortar_recipe/atropa_extract)
	var/list/recipes = list(
		/datum/container_craft/cooking/alchemical_refinement/fools_blush = 10,
		/datum/container_craft/cooking/alchemical_refinement/grave_dream = 10,
		/datum/container_craft/cooking/alchemical_refinement/nightshade_mercy = 10,
		/datum/container_craft/cooking/herbal_tea/atropa_concentrate = 20,
		/datum/container_craft/cooking/herbal_tea/swamp_miasma = 30,
	)
	for(var/recipe_type in recipes)
		var/datum/container_craft/cooking/recipe = allocate(recipe_type)
		var/obj/item/reagent_containers/glass/mortar/mortar = allocate(/obj/item/reagent_containers/glass/mortar)
		var/obj/item/reagent_containers/glass/bucket/pot/pot = allocate(/obj/item/reagent_containers/glass/bucket/pot)
		var/required_atropa = recipe.reagent_requirements[/datum/reagent/poison/herbal/weak_atropa]
		while(pot.reagents.get_reagent_amount(/datum/reagent/poison/herbal/weak_atropa) < required_atropa)
			var/obj/item/alch/herb/atropa/herb = allocate(/obj/item/alch/herb/atropa, mortar)
			mortar.to_grind += herb
			mortar.reagents.add_reagent(/datum/reagent/water, 10)
			TEST_ASSERT(extraction.prepare(mortar), "A fresh atropa bundle should produce crude extract.")
			TEST_ASSERT_EQUAL(mortar.reagents.get_reagent_amount(/datum/reagent/poison/herbal/weak_atropa), 10, "Extraction should produce ten measures.")
			var/remaining = required_atropa - pot.reagents.get_reagent_amount(/datum/reagent/poison/herbal/weak_atropa)
			mortar.reagents.trans_to(pot, min(10, remaining))
		for(var/reagent_type in recipe.reagent_requirements)
			if(reagent_type != /datum/reagent/poison/herbal/weak_atropa)
				pot.reagents.add_reagent(reagent_type, recipe.reagent_requirements[reagent_type])
		for(var/item_type in recipe.requirements)
			for(var/i in 1 to recipe.requirements[item_type])
				allocate(item_type, pot)
		recipe.execute_craft_completion(pot, brewer, 1)
		TEST_ASSERT_EQUAL(pot.reagents.get_reagent_amount(recipe.created_reagent), recipes[recipe_type], "[recipe.name] should produce one measured batch.")
		TEST_ASSERT_EQUAL(pot.reagents.total_volume, recipes[recipe_type], "[recipe.name] should consume its reagent inputs.")

/datum/unit_test/herbal_mortar_requires_exact_preparation
#ifdef FOCUS_ALCHEMY_MEDICINE_TEST
	focus = TRUE
#endif

/datum/unit_test/herbal_mortar_requires_exact_preparation/Run()
	var/datum/herbal_mortar_recipe/recipe = allocate(/datum/herbal_mortar_recipe/calendula)
	var/obj/item/reagent_containers/glass/mortar/mortar = allocate(/obj/item/reagent_containers/glass/mortar)
	for(var/i in 1 to 2)
		mortar.to_grind += allocate(/obj/item/alch/herb/calendula, mortar)
	mortar.reagents.add_reagent(/datum/reagent/water, 10)
	TEST_ASSERT(!recipe.prepare(mortar), "Fresh herbs must not make wound paste.")
	TEST_ASSERT_EQUAL(length(mortar.to_grind), 2, "A failed preparation must retain the herbs.")
	for(var/obj/item/alch/herb/herb as anything in mortar.to_grind)
		herb.finish_drying()
	mortar.reagents.add_reagent(/datum/reagent/water, 1)
	TEST_ASSERT(!recipe.prepare(mortar), "Excess water must not make paste.")
	mortar.reagents.remove_reagent(/datum/reagent/water, 1)
	mortar.reagents.add_reagent(/datum/reagent/consumable/ethanol, 1)
	TEST_ASSERT(!recipe.prepare(mortar), "Additional reagents must not make paste.")
	mortar.reagents.remove_reagent(/datum/reagent/consumable/ethanol, 1)
	TEST_ASSERT(recipe.prepare(mortar), "The exact dried mixture should make paste.")
	TEST_ASSERT_EQUAL(length(mortar.to_grind), 0, "Successful preparation should consume the herbs.")
	TEST_ASSERT_EQUAL(mortar.reagents.get_reagent_amount(recipe.result_reagent), 10, "A paste recipe should produce ten measures.")

/datum/unit_test/herbal_handbook_lists_preparation_chains
#ifdef FOCUS_ALCHEMY_MEDICINE_TEST
	focus = TRUE
#endif

/datum/unit_test/herbal_handbook_lists_preparation_chains/Run()
	var/obj/item/recipe_book/apothecarys_handbook/book = allocate(/obj/item/recipe_book/apothecarys_handbook)
	var/list/entries = book.get_cached_book_recipes(book.type, FALSE)
	var/list/entry_counts = list()
	for(var/list/entry as anything in entries)
		entry_counts[entry["name"]]++
	var/list/required_entries = list(
		"Preparing Herbal Medicines",
		"crude atropa extract",
		"Blush",
		"Grave Dream",
		"Nightshade Mercy",
		"Atropa Death Draught",
		"Distill Mentha Cooling Oil",
		"Distill Rosa Perfume Oil",
	)
	for(var/datum/container_craft/cooking/herbal_decoction/recipe_type as anything in subtypesof(/datum/container_craft/cooking/herbal_decoction))
		if(!IS_ABSTRACT(recipe_type))
			required_entries += initial(recipe_type.name)
	for(var/datum/herbal_mortar_recipe/mortar_recipe as anything in GLOB.herbal_mortar_recipes)
		required_entries |= mortar_recipe.name
	for(var/entry_name in required_entries)
		TEST_ASSERT_EQUAL(entry_counts[entry_name], 1, "The handbook should list [entry_name] exactly once.")

/datum/unit_test/herbal_handbook_static_data_lists_pottery_timings
#ifdef FOCUS_ALCHEMY_MEDICINE_TEST
	focus = TRUE
#endif

/datum/unit_test/herbal_handbook_static_data_lists_pottery_timings/Run()
	var/list/pottery_recipes = list()
	for(var/datum/pottery_recipe/recipe_type as anything in subtypesof(/datum/pottery_recipe))
		if(IS_ABSTRACT(recipe_type))
			continue
		var/datum/pottery_recipe/recipe = allocate(recipe_type)
		TEST_ASSERT_EQUAL(length(recipe.step_to_time), length(recipe.recipe_steps), "[recipe_type] should define one spin time per step.")
		pottery_recipes["[recipe.name]|[recipe.created_item]"] = recipe

	var/mob/living/carbon/human/reader = allocate(/mob/living/carbon/human)
	var/obj/item/recipe_book/apothecarys_handbook/book = allocate(/obj/item/recipe_book/apothecarys_handbook)
	var/list/data = book.ui_static_data(reader)
	TEST_ASSERT(length(data["recipes"]), "The handbook should send its own recipes.")
	TEST_ASSERT(length(data["linked_recipes"]), "The handbook should send linked recipes from other books.")

	var/pottery_entries = 0
	for(var/list/entry as anything in data["recipes"] + data["linked_recipes"])
		if(entry["type"] != "pottery")
			continue
		pottery_entries++
		var/datum/pottery_recipe/recipe = pottery_recipes["[entry["name"]]|[entry["_output_path"]]"]
		TEST_ASSERT_NOTNULL(recipe, "Pottery entry [entry["name"]] should come from a pottery recipe.")
		var/list/steps = entry["steps"]
		TEST_ASSERT_EQUAL(length(steps), length(recipe.recipe_steps), "[recipe.name] should list every step.")
		for(var/i in 1 to length(steps))
			var/list/step_data = steps[i]
			TEST_ASSERT_EQUAL(step_data["time_s"], recipe.get_step_time(i) / 10, "[recipe.name] step [i] should show the time the wheel uses.")
	TEST_ASSERT(pottery_entries, "The handbook's linked recipes should include pottery.")

/datum/unit_test/mortar_pours_and_fills_liquid_containers
#ifdef FOCUS_ALCHEMY_MEDICINE_TEST
	focus = TRUE
#endif

/datum/unit_test/mortar_pours_and_fills_liquid_containers/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	user.mind_initialize()
	var/obj/item/reagent_containers/glass/mortar/mortar = allocate(/obj/item/reagent_containers/glass/mortar)
	var/obj/item/reagent_containers/glass/bucket/bucket = allocate(/obj/item/reagent_containers/glass/bucket)
	bucket.reagents.add_reagent(/datum/reagent/water, 50)
	TEST_ASSERT(user.put_in_active_hand(bucket, forced = TRUE), "The user should hold the bucket.")
	TEST_ASSERT_EQUAL(user.used_intent?.type, INTENT_POUR, "A held bucket should default to pouring.")
	TEST_ASSERT_EQUAL(bucket.amount_per_transfer_from_this, 10, "Test setup expects the bucket's ten-measure pour.")

	bucket.melee_attack_chain(user, mortar)
	TEST_ASSERT_EQUAL(user.get_active_held_item(), bucket, "Pouring should leave the bucket in hand.")
	TEST_ASSERT(!(bucket in mortar.to_grind), "The bucket must not be added to the grinding load.")
	TEST_ASSERT_EQUAL(mortar.reagents.get_reagent_amount(/datum/reagent/water), 10, "One click should pour exactly one selected measure into the mortar.")
	TEST_ASSERT_EQUAL(bucket.reagents.get_reagent_amount(/datum/reagent/water), 40, "The rest of the water should stay in the bucket.")

	bucket.amount_per_transfer_from_this = 5
	bucket.melee_attack_chain(user, mortar)
	TEST_ASSERT_EQUAL(mortar.reagents.get_reagent_amount(/datum/reagent/water), 15, "A click should pour the newly selected measure.")
	TEST_ASSERT_EQUAL(bucket.reagents.get_reagent_amount(/datum/reagent/water), 35, "Only the selected measure should leave the bucket.")

	user.dropItemToGround(bucket, force = TRUE)
	var/obj/item/reagent_containers/glass/bottle/corked = allocate(/obj/item/reagent_containers/glass/bottle)
	corked.reagents.add_reagent(/datum/reagent/water, 10)
	TEST_ASSERT(user.put_in_active_hand(corked, forced = TRUE), "The user should hold the corked bottle.")
	corked.melee_attack_chain(user, mortar)
	TEST_ASSERT_EQUAL(user.get_active_held_item(), corked, "A corked bottle should stay in hand.")
	TEST_ASSERT(!(corked in mortar.to_grind), "A corked bottle must not be added to the grinding load.")
	TEST_ASSERT_EQUAL(corked.reagents.total_volume, 10, "A corked bottle must not pour.")
	TEST_ASSERT_EQUAL(mortar.reagents.total_volume, 15, "A corked bottle must not change the mortar.")
	user.dropItemToGround(corked, force = TRUE)
	var/obj/item/reagent_containers/glass/bottle/bottle = allocate(/obj/item/reagent_containers/glass/bottle)
	bottle.toggle_cork(user, FALSE)
	TEST_ASSERT(user.put_in_active_hand(bottle, forced = TRUE), "The user should hold the bottle.")
	var/fill_index = 0
	for(var/i in 1 to length(user.possible_a_intents))
		var/datum/intent/intent = user.possible_a_intents[i]
		if(intent.type == INTENT_FILL)
			fill_index = i
			break
	TEST_ASSERT(fill_index, "A held bottle should offer the fill intent.")
	user.rog_intent_change(fill_index)

	bottle.melee_attack_chain(user, mortar)
	TEST_ASSERT_EQUAL(user.get_active_held_item(), bottle, "Filling should leave the bottle in hand.")
	TEST_ASSERT(!length(mortar.to_grind), "Filling must not add anything to the grinding load.")
	TEST_ASSERT_EQUAL(bottle.reagents.get_reagent_amount(/datum/reagent/water), 15, "The bottle should fill from the mortar.")
	TEST_ASSERT_EQUAL(mortar.reagents.total_volume, 0, "The mortar should be drained into the bottle.")

	user.dropItemToGround(bottle, force = TRUE)
	var/obj/item/alch/herb/calendula/herb = allocate(/obj/item/alch/herb/calendula)
	TEST_ASSERT(user.put_in_active_hand(herb, forced = TRUE), "The user should hold the herb.")
	herb.melee_attack_chain(user, mortar)
	TEST_ASSERT_EQUAL(herb.loc, mortar, "Herbs should still go into the mortar.")
	TEST_ASSERT((herb in mortar.to_grind), "Herbs should join the grinding load.")

/datum/unit_test/herbal_mortar_pastes_are_exact_and_distinct
#ifdef FOCUS_ALCHEMY_MEDICINE_TEST
	focus = TRUE
#endif

/datum/unit_test/herbal_mortar_pastes_are_exact_and_distinct/Run()
	for(var/datum/herbal_mortar_recipe/recipe as anything in GLOB.herbal_mortar_recipes)
		// Enhancements start from a finished remedy; herbal_enhancement_is_exact_and_one_time covers them.
		if(istype(recipe, /datum/herbal_mortar_recipe/enhancement))
			continue
		var/obj/item/reagent_containers/glass/mortar/mortar = allocate(/obj/item/reagent_containers/glass/mortar)
		for(var/herb_type in recipe.herbs)
			for(var/i in 1 to recipe.herbs[herb_type])
				var/obj/item/alch/herb/herb = allocate(herb_type, mortar)
				herb.finish_drying()
				mortar.to_grind += herb
		mortar.reagents.add_reagent(/datum/reagent/water, recipe.water_amount)
		for(var/datum/herbal_mortar_recipe/other as anything in GLOB.herbal_mortar_recipes)
			if(other != recipe)
				TEST_ASSERT(!other.can_prepare(mortar), "[other.name] must not accept the exact mixture for [recipe.name].")
		TEST_ASSERT(recipe.prepare(mortar), "The exact dried mixture should make [recipe.name].")
		TEST_ASSERT_EQUAL(length(mortar.to_grind), 0, "[recipe.name] should consume its herbs.")
		TEST_ASSERT_EQUAL(mortar.reagents.get_reagent_amount(/datum/reagent/water), 0, "[recipe.name] should consume its water.")
		TEST_ASSERT_EQUAL(mortar.reagents.get_reagent_amount(recipe.result_reagent), recipe.result_amount, "[recipe.name] should yield its measured amount.")

/datum/unit_test/herbal_blend_decoctions_do_not_conflict
#ifdef FOCUS_ALCHEMY_MEDICINE_TEST
	focus = TRUE
#endif

/datum/unit_test/herbal_blend_decoctions_do_not_conflict/Run()
	var/list/blend_types = list(
		/datum/container_craft/cooking/herbal_tea/calendula_decoction,
		/datum/container_craft/cooking/herbal_tea/calendula_matricaria,
		/datum/container_craft/cooking/herbal_tea/rosa_valeriana,
	)
	for(var/blend_type in blend_types)
		var/datum/container_craft/blend = GLOB.container_craft_to_singleton[blend_type]
		TEST_ASSERT_NOTNULL(blend, "[blend_type] should be a pot recipe.")
		for(var/datum/container_craft/cooking/other_type as anything in subtypesof(/datum/container_craft/cooking))
			if(other_type == blend_type || IS_ABSTRACT(other_type))
				continue
			var/datum/container_craft/other = GLOB.container_craft_to_singleton[other_type]
			TEST_ASSERT(!accepts_exact_inputs(other, blend), "[other.name] would also start from the exact inputs of [blend.name].")
			TEST_ASSERT(!accepts_exact_inputs(blend, other), "[blend.name] would also start from the exact inputs of [other.name].")

/// Whether recipe could start in a pot holding exactly source's required items and reagents.
/datum/unit_test/herbal_blend_decoctions_do_not_conflict/proc/accepts_exact_inputs(datum/container_craft/recipe, datum/container_craft/source)
	for(var/reagent_type in recipe.reagent_requirements)
		var/available = 0
		for(var/source_reagent in source.reagent_requirements)
			if(source_reagent == reagent_type || (recipe.subtype_reagents_allowed && ispath(source_reagent, reagent_type)))
				available += source.reagent_requirements[source_reagent]
		if(available < recipe.reagent_requirements[reagent_type])
			return FALSE
	var/list/items = source.requirements ? source.requirements.Copy() : list()
	for(var/item_type in recipe.requirements)
		if(items[item_type] < recipe.requirements[item_type])
			return FALSE
		items[item_type] -= recipe.requirements[item_type]
		if(!items[item_type])
			items -= item_type
	for(var/wildcard in recipe.wildcard_requirements)
		var/needed = recipe.wildcard_requirements[wildcard]
		for(var/item_type in items.Copy())
			if(needed <= 0)
				break
			if(!ispath(item_type, wildcard))
				continue
			var/used = min(needed, items[item_type])
			needed -= used
			items[item_type] -= used
			if(!items[item_type])
				items -= item_type
		if(needed > 0)
			return FALSE
	if(recipe.isolation_craft && length(items))
		return FALSE
	return TRUE

/// Approximate equality for fractional bleeding values.
#define HERBAL_TEST_CLOSE(a, b) (abs((a) - (b)) < 0.001)

/datum/unit_test/herbal_bloodroot_assists_natural_clotting
#ifdef FOCUS_ALCHEMY_MEDICINE_TEST
	focus = TRUE
#endif

/datum/unit_test/herbal_bloodroot_assists_natural_clotting/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	var/obj/item/bodypart/left_arm = patient.get_bodypart(BODY_ZONE_L_ARM)
	var/obj/item/bodypart/right_arm = patient.get_bodypart(BODY_ZONE_R_ARM)
	var/obj/item/bodypart/chest = patient.get_bodypart(BODY_ZONE_CHEST)
	var/obj/item/bodypart/left_leg = patient.get_bodypart(BODY_ZONE_L_LEG)

	var/datum/wound/near_floor = left_arm.add_wound(/datum/wound/slash, silent = TRUE)
	var/datum/wound/bleeding = right_arm.add_wound(/datum/wound/slash, silent = TRUE)
	var/datum/wound/arterial = chest.add_wound(/datum/wound/slash, silent = TRUE)
	var/datum/wound/no_floor = left_leg.add_wound(/datum/wound/slash, silent = TRUE)
	TEST_ASSERT(near_floor && bleeding && arterial && no_floor, "Test setup should apply slash wounds.")
	// Together these can clot less than one dose's budget, so both must stop at their floors.
	near_floor.bleed_rate = near_floor.clotting_threshold + 0.05
	bleeding.bleed_rate = bleeding.clotting_threshold + 0.03
	// Maxed arterial wounds stop clotting entirely; herbs must not take over that role.
	arterial.bleed_rate = 1
	arterial.clotting_rate = 0
	no_floor.bleed_rate = 1
	no_floor.clotting_threshold = null

	var/datum/injury/ordinary = right_arm.create_injury(WOUND_SLASH, 20)
	var/datum/injury/surgical = chest.create_injury(WOUND_SLASH, 20, surgical = TRUE)
	var/datum/injury/divine = left_leg.create_injury(WOUND_DIVINE, 20)
	var/obj/item/bodypart/original_leg = patient.get_bodypart(BODY_ZONE_R_LEG)
	original_leg.drop_limb()
	qdel(original_leg)
	var/obj/item/bodypart/r_leg/prosthetic/wood/prosthetic_leg = allocate(/obj/item/bodypart/r_leg/prosthetic/wood)
	prosthetic_leg.attach_limb(patient, special = TRUE)
	var/datum/injury/mechanical = prosthetic_leg.create_injury(WOUND_SLASH, 20)
	TEST_ASSERT(ordinary && surgical && divine && mechanical, "Test setup should create each kind of injury.")
	var/ordinary_timer = ordinary.bleed_timer
	var/surgical_timer = surgical.bleed_timer
	var/divine_timer = divine.bleed_timer
	var/mechanical_timer = mechanical.bleed_timer

	patient.blood_volume = BLOOD_VOLUME_NORMAL - 50
	patient.reagents.add_reagent(/datum/reagent/medicine/herbal/compound/bloodroot, 5, list("herbal_strength" = 1))
	var/datum/reagent/medicine/herbal/compound/bloodroot/bloodroot = patient.reagents.get_reagent(/datum/reagent/medicine/herbal/compound/bloodroot)
	bloodroot.on_mob_life(patient, 1)

	TEST_ASSERT_EQUAL(patient.blood_volume, BLOOD_VOLUME_NORMAL - 45, "Dry bloodroot should still restore blood.")
	TEST_ASSERT(HERBAL_TEST_CLOSE(near_floor.bleed_rate, near_floor.clotting_threshold), "Clotting assistance must stop at a wound's natural floor.")
	TEST_ASSERT(HERBAL_TEST_CLOSE(bleeding.bleed_rate, bleeding.clotting_threshold), "Remaining budget should reach other clotting wounds.")
	TEST_ASSERT_EQUAL(arterial.bleed_rate, 1, "Wounds that no longer clot naturally must keep bleeding.")
	TEST_ASSERT_EQUAL(no_floor.bleed_rate, 1, "Wounds without a natural clotting floor must keep bleeding.")
	TEST_ASSERT_EQUAL(ordinary.bleed_timer, ordinary_timer - 5, "A full oral dose should shorten ordinary injury bleeding.")
	TEST_ASSERT_EQUAL(surgical.bleed_timer, surgical_timer, "Surgical openings must not be clotted by herbs.")
	TEST_ASSERT_EQUAL(divine.bleed_timer, divine_timer, "Divine wounds must not be clotted by herbs.")
	TEST_ASSERT_EQUAL(mechanical.bleed_timer, mechanical_timer, "Prosthetic limbs must not be clotted by herbs.")

	bleeding.bleed_rate = 1
	bloodroot.on_mob_life(patient, 1)
	TEST_ASSERT(HERBAL_TEST_CLOSE(bleeding.bleed_rate, 0.9), "A full oral dose should clot only a small amount of heavier bleeding.")
	TEST_ASSERT(HERBAL_TEST_CLOSE(near_floor.bleed_rate, near_floor.clotting_threshold), "Wounds already at their floor must stay there.")

/datum/unit_test/herbal_rosa_valeriana_paste_clots_locally
#ifdef FOCUS_ALCHEMY_MEDICINE_TEST
	focus = TRUE
#endif

/datum/unit_test/herbal_rosa_valeriana_paste_clots_locally/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	var/obj/item/bodypart/treated_arm = patient.get_bodypart(BODY_ZONE_L_ARM)
	var/obj/item/bodypart/other_arm = patient.get_bodypart(BODY_ZONE_R_ARM)
	var/datum/wound/first_wound = treated_arm.add_wound(/datum/wound/slash, silent = TRUE)
	var/datum/wound/second_wound = treated_arm.add_wound(/datum/wound/slash, silent = TRUE)
	var/datum/wound/other_wound = other_arm.add_wound(/datum/wound/slash, silent = TRUE)
	TEST_ASSERT(first_wound && second_wound && other_wound, "Test setup should apply slash wounds.")
	first_wound.bleed_rate = 1
	second_wound.bleed_rate = 1
	other_wound.bleed_rate = 1
	var/datum/injury/cut = treated_arm.create_injury(WOUND_SLASH, 10)
	var/datum/injury/puncture = treated_arm.create_injury(WOUND_PIERCE, 10)
	var/datum/injury/other_cut = other_arm.create_injury(WOUND_SLASH, 10)
	TEST_ASSERT(cut && puncture && other_cut, "Test setup should create injuries.")
	var/treated_timers = cut.bleed_timer + puncture.bleed_timer
	var/other_timer = other_cut.bleed_timer
	patient.blood_volume = BLOOD_VOLUME_NORMAL - 50

	var/obj/item/natural/cloth/bandage = allocate(/obj/item/natural/cloth)
	bandage.reagents.add_reagent(/datum/reagent/medicine/herbal/wound_paste/rosa_valeriana, 5)
	var/datum/reagent/medicine/herbal/wound_paste/dressing_paste = bandage.reagents.get_reagent(/datum/reagent/medicine/herbal/wound_paste/rosa_valeriana)
	var/dose = dressing_paste.metabolization_rate
	treated_arm.bandage = bandage
	treated_arm.apply_bandage_reagents()
	treated_arm.bandage = null

	var/wound_clotting = 2 - (first_wound.bleed_rate + second_wound.bleed_rate)
	TEST_ASSERT(HERBAL_TEST_CLOSE(wound_clotting, 0.1 * dose), "One dressing application should share a dose-scaled clotting budget across the limb's wounds.")
	TEST_ASSERT(HERBAL_TEST_CLOSE(treated_timers - (cut.bleed_timer + puncture.bleed_timer), 5 * dose), "One dressing application should share a dose-scaled bleeding-time budget across the limb's injuries.")
	TEST_ASSERT_EQUAL(other_wound.bleed_rate, 1, "The paste must not clot wounds on other limbs.")
	TEST_ASSERT_EQUAL(other_cut.bleed_timer, other_timer, "The paste must not clot injuries on other limbs.")
	TEST_ASSERT_EQUAL(patient.blood_volume, BLOOD_VOLUME_NORMAL - 50, "The paste must not restore blood through a dressing.")

	patient.reagents.add_reagent(/datum/reagent/medicine/herbal/wound_paste/rosa_valeriana, 5)
	var/datum/reagent/medicine/herbal/wound_paste/swallowed = patient.reagents.get_reagent(/datum/reagent/medicine/herbal/wound_paste/rosa_valeriana)
	swallowed.on_mob_life(patient, 1)
	TEST_ASSERT_EQUAL(patient.blood_volume, BLOOD_VOLUME_NORMAL - 50, "Drinking the paste must not restore blood.")
	TEST_ASSERT_EQUAL(other_wound.bleed_rate, 1, "Drinking the paste must not clot wounds.")

/datum/unit_test/mortar_paste_soaks_into_cloth
#ifdef FOCUS_ALCHEMY_MEDICINE_TEST
	focus = TRUE
#endif

/datum/unit_test/mortar_paste_soaks_into_cloth/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	user.mind_initialize()
	var/obj/item/reagent_containers/glass/mortar/mortar = allocate(/obj/item/reagent_containers/glass/mortar)
	var/datum/herbal_mortar_recipe/paste_recipe = locate(/datum/herbal_mortar_recipe/calendula) in GLOB.herbal_mortar_recipes
	for(var/i in 1 to 2)
		var/obj/item/alch/herb/herb = allocate(/obj/item/alch/herb/calendula, mortar)
		herb.finish_drying()
		mortar.to_grind += herb
	mortar.reagents.add_reagent(/datum/reagent/water, 10)
	TEST_ASSERT(paste_recipe.prepare(mortar), "Test setup should prepare calendula paste.")
	var/datum/herbal_mortar_recipe/urtica = locate(/datum/herbal_mortar_recipe/enhancement/urtica) in GLOB.herbal_mortar_recipes
	var/obj/item/alch/herb/urtica/nettle = allocate(/obj/item/alch/herb/urtica, mortar)
	nettle.finish_drying()
	mortar.to_grind += nettle
	TEST_ASSERT(urtica.prepare(mortar), "Test setup should enhance the paste.")

	var/paste_type = paste_recipe.result_reagent
	var/obj/item/natural/cloth/cloth = allocate(/obj/item/natural/cloth)
	TEST_ASSERT(user.put_in_active_hand(cloth, forced = TRUE), "The user should hold the cloth.")
	var/soak_index = 0
	var/wring_index = 0
	for(var/i in 1 to length(user.possible_a_intents))
		var/datum/intent/intent = user.possible_a_intents[i]
		if(intent.type == INTENT_SOAK)
			soak_index = i
		else if(intent.type == INTENT_WRING)
			wring_index = i
	TEST_ASSERT(soak_index && wring_index, "A held cloth should offer soak and wring intents.")

	user.rog_intent_change(soak_index)
	cloth.melee_attack_chain(user, mortar)
	TEST_ASSERT_EQUAL(user.get_active_held_item(), cloth, "Soaking should leave the cloth in hand.")
	TEST_ASSERT(!(cloth in mortar.to_grind), "Soaking must not add the cloth to the grinding load.")
	var/datum/reagent/medicine/herbal/preparation/soaked = cloth.reagents.get_reagent(paste_type)
	TEST_ASSERT_NOTNULL(soaked, "The cloth should soak up the paste.")
	TEST_ASSERT_EQUAL(soaked.volume, cloth.reagents.maximum_volume, "The cloth should soak up as much paste as it holds.")
	TEST_ASSERT_EQUAL(soaked.volume + mortar.reagents.get_reagent_amount(paste_type), 10, "Soaking should not lose any paste.")
	TEST_ASSERT_EQUAL(soaked.get_herbal_potency(), 1.25, "Soaked paste should stay enhanced.")
	TEST_ASSERT(soaked.herbal_enhanced, "Soaked paste should keep its used flag.")

	user.rog_intent_change(wring_index)
	cloth.melee_attack_chain(user, mortar)
	TEST_ASSERT_EQUAL(user.get_active_held_item(), cloth, "Wringing should leave the cloth in hand.")
	TEST_ASSERT(!(cloth in mortar.to_grind), "Wringing must not add the cloth to the grinding load.")
	TEST_ASSERT_EQUAL(cloth.reagents.total_volume, 0, "Wringing should empty the cloth.")
	var/datum/reagent/medicine/herbal/preparation/returned = mortar.reagents.get_reagent(paste_type)
	TEST_ASSERT_EQUAL(returned.volume, 10, "Wringing should return all of the paste.")
	TEST_ASSERT_EQUAL(returned.get_herbal_potency(), 1.25, "Wrung-out paste should stay enhanced.")

/datum/unit_test/herbal_clotting_skips_nonbleeding_injuries
#ifdef FOCUS_ALCHEMY_MEDICINE_TEST
	focus = TRUE
#endif

/datum/unit_test/herbal_clotting_skips_nonbleeding_injuries/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	var/obj/item/bodypart/arm = patient.get_bodypart(BODY_ZONE_L_ARM)
	// Created first so they come first in the injury list.
	var/datum/injury/bruise = arm.create_injury(WOUND_BLUNT, 10)
	var/datum/injury/burn = arm.create_injury(WOUND_BURN, 10)
	var/datum/injury/cut = arm.create_injury(WOUND_SLASH, 10)
	TEST_ASSERT(bruise && burn && cut, "Test setup should create a bruise, a burn, and a cut.")
	TEST_ASSERT(bruise.current_stage > bruise.max_bleeding_stage, "Test setup expects a bruise past its bleeding stages.")
	TEST_ASSERT(burn.current_stage > burn.max_bleeding_stage, "Test setup expects a burn that never bleeds.")
	var/bruise_timer = bruise.bleed_timer
	var/burn_timer = burn.bleed_timer
	var/cut_timer = cut.bleed_timer

	var/datum/reagent/medicine/herbal/compound/bloodroot/bloodroot = allocate(/datum/reagent/medicine/herbal/compound/bloodroot)
	bloodroot.assist_natural_clotting(list(arm), 1)

	TEST_ASSERT_EQUAL(bruise.bleed_timer, bruise_timer, "Bruises that cannot bleed must not use the clotting budget.")
	TEST_ASSERT_EQUAL(burn.bleed_timer, burn_timer, "Burns must not use the clotting budget.")
	TEST_ASSERT_EQUAL(cut.bleed_timer, cut_timer - 5, "The whole budget should reach the bleeding cut.")

/datum/unit_test/herbal_enhancement_is_exact_and_one_time
#ifdef FOCUS_ALCHEMY_MEDICINE_TEST
	focus = TRUE
#endif

/datum/unit_test/herbal_enhancement_is_exact_and_one_time/Run()
	var/remedy_type = /datum/reagent/medicine/herbal/decoction/calendula
	for(var/datum/herbal_mortar_recipe/enhancement/recipe as anything in GLOB.herbal_mortar_recipes)
		if(!istype(recipe))
			continue
		var/obj/item/reagent_containers/glass/mortar/mortar = allocate(/obj/item/reagent_containers/glass/mortar)
		mortar.reagents.add_reagent(remedy_type, 10, list("herbal_strength" = 1, "quality" = 3))
		var/datum/reagent/medicine/herbal/preparation/remedy = mortar.reagents.get_reagent(remedy_type)
		var/obj/item/alch/herb/additive_herb
		if(recipe.additive_herb)
			additive_herb = allocate(recipe.additive_herb, mortar)
			mortar.to_grind += additive_herb
			TEST_ASSERT(!recipe.can_prepare(mortar), "[recipe.name] must require a fully dried bundle.")
			additive_herb.finish_drying()
		else
			mortar.reagents.add_reagent(recipe.additive_reagent, 4)
			TEST_ASSERT(!recipe.can_prepare(mortar), "[recipe.name] must require exactly [recipe.additive_amount] measures of oil.")
			mortar.reagents.add_reagent(recipe.additive_reagent, 1)
		for(var/datum/herbal_mortar_recipe/other as anything in GLOB.herbal_mortar_recipes)
			if(other != recipe)
				TEST_ASSERT(!other.can_prepare(mortar), "[other.name] must not accept the exact inputs for [recipe.name].")
		var/quality = remedy.recipe_quality
		var/overdose = remedy.overdose_threshold
		TEST_ASSERT(recipe.prepare(mortar), "The exact inputs should make [recipe.name].")
		TEST_ASSERT_EQUAL(mortar.reagents.total_volume, 10, "[recipe.name] should consume its enhancer and keep the remedy's volume.")
		TEST_ASSERT_EQUAL(length(mortar.to_grind), 0, "[recipe.name] should consume its herb.")
		TEST_ASSERT_EQUAL(mortar.reagents.get_reagent(remedy_type), remedy, "Enhancement should change the held remedy in place.")
		TEST_ASSERT_EQUAL(remedy.get_herbal_potency(), 1.25, "A dried remedy should become 1.25 strength.")
		TEST_ASSERT_EQUAL(remedy.data["herbal_enhanced"], TRUE, "The used flag should travel in reagent data.")
		TEST_ASSERT_EQUAL(remedy.recipe_quality, quality, "Enhancement must not change quality.")
		TEST_ASSERT_EQUAL(remedy.data["quality"], quality, "Enhancement must keep unrelated reagent data.")
		TEST_ASSERT_EQUAL(remedy.overdose_threshold, overdose, "Enhancement must not change the overdose threshold.")

		// A second enhancement is refused without consuming anything.
		if(recipe.additive_herb)
			additive_herb = allocate(recipe.additive_herb, mortar)
			additive_herb.finish_drying()
			mortar.to_grind += additive_herb
		else
			mortar.reagents.add_reagent(recipe.additive_reagent, recipe.additive_amount)
		for(var/datum/herbal_mortar_recipe/other as anything in GLOB.herbal_mortar_recipes)
			TEST_ASSERT(!other.can_prepare(mortar), "[other.name] must refuse a batch that was already enhanced.")
		TEST_ASSERT(!recipe.prepare(mortar), "[recipe.name] must not enhance a batch twice.")
		TEST_ASSERT_EQUAL(mortar.reagents.total_volume, recipe.additive_herb ? 10 : 15, "A refused enhancement must not consume the oil.")
		TEST_ASSERT_EQUAL(length(mortar.to_grind), recipe.additive_herb ? 1 : 0, "A refused enhancement must not consume the herb.")
		TEST_ASSERT_EQUAL(remedy.get_herbal_potency(), 1.25, "A refused enhancement must not change the remedy.")

	// Traditional remedies, water, and wrong amounts are not enhancement inputs.
	var/datum/herbal_mortar_recipe/enhancement/lavender = locate(/datum/herbal_mortar_recipe/enhancement/lavender) in GLOB.herbal_mortar_recipes
	var/obj/item/reagent_containers/glass/mortar/mortar = allocate(/obj/item/reagent_containers/glass/mortar)
	mortar.reagents.add_reagent(/datum/reagent/medicine/herbal/calendula_salve, 10)
	mortar.reagents.add_reagent(/datum/reagent/herbal_enhancer_oil/lavender, 5)
	TEST_ASSERT(!lavender.can_prepare(mortar), "Traditional alchemical remedies must not be enhanced.")
	mortar.reagents.clear_reagents()
	mortar.reagents.add_reagent(remedy_type, 9)
	mortar.reagents.add_reagent(/datum/reagent/herbal_enhancer_oil/lavender, 5)
	TEST_ASSERT(!lavender.can_prepare(mortar), "Enhancement needs exactly ten measures of remedy.")
	mortar.reagents.add_reagent(remedy_type, 1)
	mortar.reagents.add_reagent(/datum/reagent/water, 1)
	TEST_ASSERT(!lavender.can_prepare(mortar), "Enhancement must refuse water or other reagents.")

/datum/unit_test/herbal_enhancement_survives_only_unmixed
#ifdef FOCUS_ALCHEMY_MEDICINE_TEST
	focus = TRUE
#endif

/datum/unit_test/herbal_enhancement_survives_only_unmixed/Run()
	var/remedy_type = /datum/reagent/medicine/herbal/decoction/calendula
	var/datum/herbal_mortar_recipe/enhancement/lavender = locate(/datum/herbal_mortar_recipe/enhancement/lavender) in GLOB.herbal_mortar_recipes

	// Splitting and recombining one enhanced batch keeps the bonus, but it still cannot be enhanced again.
	var/obj/item/reagent_containers/glass/mortar/mortar = allocate(/obj/item/reagent_containers/glass/mortar)
	var/obj/item/reagent_containers/glass/bottle/first_half = allocate(/obj/item/reagent_containers/glass/bottle)
	var/obj/item/reagent_containers/glass/bottle/second_half = allocate(/obj/item/reagent_containers/glass/bottle)
	mortar.reagents.add_reagent(remedy_type, 10, list("herbal_strength" = 1))
	var/datum/reagent/medicine/herbal/preparation/remedy = mortar.reagents.get_reagent(remedy_type)
	TEST_ASSERT(remedy.enhance(), "A plain batch should accept enhancement.")
	mortar.reagents.trans_to(first_half, 5)
	mortar.reagents.trans_to(second_half, 5)
	var/datum/reagent/medicine/herbal/preparation/split = first_half.reagents.get_reagent(remedy_type)
	TEST_ASSERT_EQUAL(split.get_herbal_potency(), 1.25, "Pouring an enhanced batch should keep its potency.")
	TEST_ASSERT(split.herbal_enhanced, "Pouring an enhanced batch should keep its used flag.")
	first_half.reagents.trans_to(mortar, 5)
	second_half.reagents.trans_to(mortar, 5)
	remedy = mortar.reagents.get_reagent(remedy_type)
	TEST_ASSERT_EQUAL(remedy.get_herbal_potency(), 1.25, "Recombining one enhanced batch should keep its potency.")
	mortar.reagents.add_reagent(/datum/reagent/herbal_enhancer_oil/lavender, 5)
	TEST_ASSERT(!lavender.can_prepare(mortar), "A recombined enhanced batch must not be enhanced again.")

	// Mixing with plain medicine loses the bonus in either order, and the mixture stays used.
	for(var/enhanced_first in list(TRUE, FALSE))
		var/obj/item/reagent_containers/glass/bottle/enhanced = allocate(/obj/item/reagent_containers/glass/bottle)
		var/obj/item/reagent_containers/glass/bottle/plain = allocate(/obj/item/reagent_containers/glass/bottle)
		enhanced.reagents.add_reagent(remedy_type, 5, list("herbal_strength" = 1))
		var/datum/reagent/medicine/herbal/preparation/enhanced_remedy = enhanced.reagents.get_reagent(remedy_type)
		enhanced_remedy.enhance()
		plain.reagents.add_reagent(remedy_type, 5, list("herbal_strength" = 1))
		var/obj/item/reagent_containers/glass/bottle/target = enhanced_first ? plain : enhanced
		var/obj/item/reagent_containers/glass/bottle/source = enhanced_first ? enhanced : plain
		source.reagents.trans_to(target, 5)
		var/datum/reagent/medicine/herbal/preparation/mixed = target.reagents.get_reagent(remedy_type)
		TEST_ASSERT_EQUAL(mixed.get_herbal_potency(), 1, "Mixing enhanced with plain medicine should lose the bonus.")
		TEST_ASSERT(mixed.herbal_enhanced, "Mixing must not clear the used flag.")
		TEST_ASSERT_EQUAL(mixed.data["herbal_enhanced"], TRUE, "The mixed used flag should be written to reagent data.")

	// Medicine without any preparation data counts as plain and fresh, and cannot launder the flag either.
	var/obj/item/reagent_containers/glass/bottle/bottle = allocate(/obj/item/reagent_containers/glass/bottle)
	bottle.reagents.add_reagent(remedy_type, 5, list("herbal_strength" = 1))
	var/datum/reagent/medicine/herbal/preparation/marked = bottle.reagents.get_reagent(remedy_type)
	marked.enhance()
	bottle.reagents.add_reagent(remedy_type, 5)
	TEST_ASSERT_EQUAL(marked.herbal_boost, 1, "Medicine without data should count as unenhanced.")
	TEST_ASSERT_EQUAL(marked.herbal_strength, 0.5, "Decoction without data should count as fresh.")
	TEST_ASSERT(marked.herbal_enhanced, "Medicine without data must not clear the used flag.")

/datum/unit_test/herbal_enhancement_strengthens_effects
#ifdef FOCUS_ALCHEMY_MEDICINE_TEST
	focus = TRUE
#endif

/datum/unit_test/herbal_enhancement_strengthens_effects/Run()
	// Oral healing, fresh and dried.
	for(var/strength in list(0.5, 1))
		var/list/healed = list()
		for(var/enhanced in list(FALSE, TRUE))
			var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
			patient.adjustToxLoss(20, updating_health = FALSE, forced = TRUE)
			patient.reagents.add_reagent(/datum/reagent/medicine/herbal/decoction/artemisia, 5, list("herbal_strength" = strength))
			var/datum/reagent/medicine/herbal/decoction/remedy = patient.reagents.get_reagent(/datum/reagent/medicine/herbal/decoction/artemisia)
			if(enhanced)
				remedy.enhance()
			TEST_ASSERT_EQUAL(remedy.get_herbal_potency(), strength * (enhanced ? 1.25 : 1), "Enhancement should add a quarter of the batch's strength.")
			var/starting_tox = patient.getToxLoss()
			remedy.on_mob_life(patient, 1)
			healed += starting_tox - patient.getToxLoss()
		TEST_ASSERT(healed[1] > 0, "The plain decoction should heal toxin damage.")
		TEST_ASSERT(HERBAL_TEST_CLOSE(healed[2], healed[1] * 1.25), "An enhanced [strength] strength decoction should heal 25% more.")

	// Persistent chemical effects.
	var/mob/living/carbon/human/numbed = allocate(/mob/living/carbon/human)
	numbed.reagents.add_reagent(/datum/reagent/medicine/herbal/anodyne/atropa, 5, list("herbal_strength" = 1))
	var/datum/reagent/medicine/herbal/decoction/anodyne = numbed.reagents.get_reagent(/datum/reagent/medicine/herbal/anodyne/atropa)
	anodyne.enhance()
	anodyne.metabolizing = TRUE
	anodyne.on_mob_metabolize(numbed)
	anodyne.on_mob_life(numbed, 1)
	TEST_ASSERT_EQUAL(numbed.get_chem_effect(CE_PAINKILLER), 10, "Enhanced dry anodyne should relieve 25% more pain.")
	numbed.reagents.clear_reagents()

	// Topical paste healing through a dressing.
	var/list/paste_healed = list()
	for(var/enhanced in list(FALSE, TRUE))
		var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
		var/obj/item/bodypart/arm = patient.get_bodypart(BODY_ZONE_L_ARM)
		var/datum/injury/cut = arm.create_injury(WOUND_SLASH, 20)
		TEST_ASSERT_NOTNULL(cut, "Test setup should create a cut.")
		var/obj/item/natural/cloth/bandage = allocate(/obj/item/natural/cloth)
		bandage.reagents.add_reagent(/datum/reagent/medicine/herbal/wound_paste/calendula, 5)
		var/datum/reagent/medicine/herbal/wound_paste/paste = bandage.reagents.get_reagent(/datum/reagent/medicine/herbal/wound_paste/calendula)
		TEST_ASSERT_EQUAL(paste.get_herbal_potency(), 1, "Fresh paste should start at full strength.")
		if(enhanced)
			paste.enhance()
		var/starting_damage = cut.damage
		arm.bandage = bandage
		arm.apply_bandage_reagents()
		arm.bandage = null
		paste_healed += starting_damage - cut.damage
	TEST_ASSERT(paste_healed[1] > 0, "Plain paste should heal the dressed cut.")
	TEST_ASSERT(HERBAL_TEST_CLOSE(paste_healed[2], paste_healed[1] * 1.25), "Enhanced paste should heal 25% more per measure.")

/datum/unit_test/herbal_enhancer_oils_brew_and_distill
#ifdef FOCUS_ALCHEMY_MEDICINE_TEST
	focus = TRUE
#endif

/datum/unit_test/herbal_enhancer_oils_brew_and_distill/Run()
	var/mob/living/carbon/human/brewer = allocate(/mob/living/carbon/human)
	brewer.mind_initialize()
	var/list/chains = list(
		/datum/container_craft/cooking/herbal_oil/lavender_oil = /datum/reagent/herbal_enhancer_oil/lavender,
		/datum/container_craft/cooking/herbal_oil/salvia_oil = /datum/reagent/herbal_enhancer_oil/salvia,
	)
	for(var/recipe_type in chains)
		var/datum/container_craft/cooking/recipe = GLOB.container_craft_to_singleton[recipe_type]
		var/obj/item/reagent_containers/glass/bucket/pot/pot = allocate(/obj/item/reagent_containers/glass/bucket/pot)
		pot.reagents.add_reagent(/datum/reagent/consumable/ethanol, 30)
		for(var/herb_type in recipe.requirements)
			for(var/i in 1 to recipe.requirements[herb_type])
				allocate(herb_type, pot)
		recipe.execute_craft_completion(pot, brewer, 1)
		TEST_ASSERT_EQUAL(pot.reagents.get_reagent_amount(recipe.created_reagent), 30, "[recipe.name] should brew 30 measures of infusion.")
		TEST_ASSERT_EQUAL(pot.reagents.get_reagent_amount(/datum/reagent/consumable/ethanol), 0, "[recipe.name] should use all 30 measures of spirits.")

		var/datum/reagent/infusion = pot.reagents.get_reagent(recipe.created_reagent)
		var/infusion_quality = infusion.recipe_quality

		var/obj/structure/chem_separator/alembic = allocate(/obj/structure/chem_separator)
		var/obj/item/reagent_containers/glass/bucket/receiver = allocate(/obj/item/reagent_containers/glass/bucket)
		pot.reagents.trans_to(alembic, 30)
		alembic.replace_beaker(receiver)
		TEST_ASSERT(alembic.start(), "The alembic should start distilling [recipe.name].")
		// Drive processing by hand so the subsystem cannot double-process it.
		STOP_PROCESSING(SSobj, alembic)
		TEST_ASSERT_EQUAL(alembic.separating_reagent_type, recipe.created_reagent, "The alembic should choose the infusion to distill.")
		alembic.reagents.chem_temp = alembic.required_temp
		for(var/i in 1 to 10)
			if(!alembic.burning)
				break
			alembic.process(1)
		alembic.stop()

		var/oil_type = chains[recipe_type]
		var/datum/reagent/oil = receiver.reagents.get_reagent(oil_type)
		TEST_ASSERT_NOTNULL(oil, "The alembic should produce finished oil from [recipe.name].")
		TEST_ASSERT(HERBAL_TEST_CLOSE(oil.volume, 10), "Thirty measures of [recipe.name] should distill into ten measures of finished oil.")
		TEST_ASSERT(HERBAL_TEST_CLOSE(receiver.reagents.total_volume, 10), "Only finished oil should reach the receiving vessel.")
		TEST_ASSERT_EQUAL(alembic.reagents.get_reagent_amount(recipe.created_reagent), 0, "All of the infusion should be distilled.")
		TEST_ASSERT_EQUAL(alembic.reagents.total_volume, 0, "Nothing should remain in the alembic.")
		TEST_ASSERT_EQUAL(oil.name, initial(oil.name), "The oil should keep its own name, not the infusion's.")
		// The alembic adds the oil in several fractions, and ordinary reagent merging floors the weighted quality each time.
		TEST_ASSERT_EQUAL(oil.recipe_quality, floor(infusion_quality), "The oil should keep the infusion's brewing quality, rounded down by ordinary merging.")

/datum/unit_test/lavender_grows_from_wild_herbs
#ifdef FOCUS_ALCHEMY_MEDICINE_TEST
	focus = TRUE
#endif

/datum/unit_test/lavender_grows_from_wild_herbs/Run()
	var/obj/structure/flora/grass/herb/lavender/bush = allocate(/obj/structure/flora/grass/herb/lavender)
	TEST_ASSERT((/obj/item/alch/herb/lavender in bush.looty), "A wild lavender bush should yield lavender.")
	var/obj/item/reagent_containers/glass/mortar/mortar = allocate(/obj/item/reagent_containers/glass/mortar)
	var/obj/item/alch/herb/lavender/herb = allocate(/obj/item/alch/herb/lavender)
	var/datum/alch_grind_recipe/grinding = mortar.find_recipe(herb)
	TEST_ASSERT_NOTNULL(grinding, "Lavender should grind in a mortar.")
	var/obj/item/neuFarm/seed/seed_type
	for(var/output in grinding.valid_outputs)
		if(ispath(output, /obj/item/neuFarm/seed))
			seed_type = output
	TEST_ASSERT_NOTNULL(seed_type, "Ground lavender should give seeds.")
	var/datum/plant_def/plant = initial(seed_type.plant_def_type)
	TEST_ASSERT_EQUAL(initial(plant.produce_type), /obj/item/alch/herb/lavender, "Lavender seeds should grow lavender.")

/// Tests that drive SSmachines by hand through fire_machine().
/datum/unit_test/machine_processing
	abstract_type = /datum/unit_test/machine_processing

/datum/unit_test/machine_processing/drying_rack_dries_herbs_after_idle_stop
#ifdef FOCUS_ALCHEMY_MEDICINE_TEST
	focus = TRUE
#endif

/datum/unit_test/machine_processing/drying_rack_dries_herbs_after_idle_stop/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	user.mind_initialize()
	var/obj/machinery/tanningrack/rack = allocate(/obj/machinery/tanningrack)
	// Every rack is empty on its first SSmachines fire at roundstart.
	fire_machine(rack)
	TEST_ASSERT(!(rack in SSmachines.processing), "An empty drying rack should stop processing.")

	var/obj/item/alch/herb/calendula/first_herb = allocate(/obj/item/alch/herb/calendula)
	TEST_ASSERT(user.put_in_active_hand(first_herb, forced = TRUE), "The user should hold the first herb.")
	first_herb.melee_attack_chain(user, rack)
	TEST_ASSERT_EQUAL(first_herb.loc, rack, "Herbs should spread onto the rack.")
	TEST_ASSERT((first_herb in rack.drying_herbs), "The rack should track the herb it dries.")
	TEST_ASSERT((rack in SSmachines.processing), "A herb added after an idle stop should restart drying.")

	// Pin still indoor air so the result does not depend on the test map's weather.
	rack.drying_modifier = 1
	rack.next_drying_environment_check = INFINITY
	var/half_time = first_herb.drying_time / 2
	rack.last_drying_process = world.time - half_time
	fire_machine(rack)
	TEST_ASSERT(!first_herb.dried, "A herb should not dry before its full drying time.")
	TEST_ASSERT((rack in SSmachines.processing), "A rack with a fresh herb should keep processing.")
	var/expected_minutes = CEILING(half_time / (1 MINUTES), 1)
	TEST_ASSERT(findtext(rack.drying_status_text(), "about [expected_minutes] more minute"), "The rack should report the remaining drying time.")

	rack.last_drying_process = world.time - half_time
	fire_machine(rack)
	TEST_ASSERT(first_herb.dried, "A herb should dry after its full drying time on the rack.")
	TEST_ASSERT(!(rack in SSmachines.processing), "A rack with only dry herbs should stop processing.")

	first_herb.forceMove(get_turf(rack))
	TEST_ASSERT(!length(rack.drying_herbs), "A herb leaving the rack should leave the drying list.")

	var/obj/item/alch/herb/calendula/second_herb = allocate(/obj/item/alch/herb/calendula)
	TEST_ASSERT(user.put_in_active_hand(second_herb, forced = TRUE), "The user should hold the second herb.")
	second_herb.melee_attack_chain(user, rack)
	TEST_ASSERT((rack in SSmachines.processing), "A herb added after a finished batch should restart drying.")
	qdel(second_herb)
	TEST_ASSERT(!length(rack.drying_herbs), "A deleted herb must not stay in the drying list.")

/datum/unit_test/machine_processing/essence_infuser_polls_only_while_waiting
#ifdef FOCUS_ALCHEMY_MEDICINE_TEST
	focus = TRUE
#endif

/datum/unit_test/machine_processing/essence_infuser_polls_only_while_waiting/Run()
	var/obj/machinery/essence/infuser/infuser = allocate(/obj/machinery/essence/infuser)
	fire_machine(infuser)
	TEST_ASSERT(!(infuser in SSmachines.processing), "An idle infuser should stop polling.")

	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	user.mind_initialize()
	infuser.current_recipe = new /datum/infusion_recipe/glass
	var/obj/item/natural/stone/stone = allocate(/obj/item/natural/stone)
	TEST_ASSERT(user.put_in_active_hand(stone, forced = TRUE), "The user should hold the stone.")
	stone.melee_attack_chain(user, infuser)
	TEST_ASSERT_EQUAL(infuser.infusion_target, stone, "The stone should rest on the infuser.")
	TEST_ASSERT((infuser in SSmachines.processing), "An infuser waiting for essence should poll.")
	fire_machine(infuser)
	TEST_ASSERT((infuser in SSmachines.processing), "An infuser still short of essence should keep polling.")

	infuser.storage.add(/datum/thaumaturgical_essence/crystal, 5)
	TEST_ASSERT(!(infuser in SSmachines.processing), "An infuser with every essence should stop polling.")
	infuser.storage.remove(/datum/thaumaturgical_essence/crystal, 1)
	TEST_ASSERT((infuser in SSmachines.processing), "An infuser that loses essence should poll again.")

	qdel(stone)
	TEST_ASSERT(!(infuser in SSmachines.processing), "An infuser with no item should stop polling.")

/// Runs the real SSmachines fire over this machine alone, then restores the subsystem's own lists.
/datum/unit_test/machine_processing/proc/fire_machine(obj/machinery/machine)
	var/list/real_processing = SSmachines.processing
	var/list/real_currentrun = SSmachines.currentrun
	var/was_processing = (machine in real_processing)
	SSmachines.processing = was_processing ? list(machine) : list()
	SSmachines.currentrun = list()
	try
		SSmachines.fire()
	catch(var/exception/error)
		TEST_FAIL("SSmachines fire runtimed: [error]")
	var/still_processing = (machine in SSmachines.processing)
	SSmachines.processing = real_processing
	SSmachines.currentrun = real_currentrun
	if(was_processing && !still_processing)
		real_processing -= machine

#undef HERBAL_TEST_CLOSE
