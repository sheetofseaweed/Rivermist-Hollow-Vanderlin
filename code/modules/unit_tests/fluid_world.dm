/datum/unit_test/fluid_rain_and_water_rinse_coats/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/datum/reagents/source = new /datum/reagents(100)
	source.add_reagent(/datum/reagent/consumable/cum, 100)
	human.coat_with_fluid(FLUID_COAT_CHEST, source, 10)
	var/datum/component/fluid_coated/coated = human.GetComponent(/datum/component/fluid_coated)
	var/datum/fluid_coat/coat = coated.coats[FLUID_COAT_CHEST]
	var/before = coat.fluids.total_volume

	human.SoakMob(FULL_BODY, FALSE, TRUE)
	TEST_ASSERT(coat.fluids.total_volume < before, "Rain should rinse a bare coat.")
	var/after_rain = coat.fluids.total_volume
	human.SoakMob(FULL_BODY, FALSE, FALSE)
	TEST_ASSERT(after_rain - coat.fluids.total_volume > before - after_rain, "Wading should rinse faster than rain.")

	human.coat_with_fluid(FLUID_COAT_FEET, source, 5)
	var/datum/fluid_coat/feet = coated.coats[FLUID_COAT_FEET]
	var/feet_before = feet.fluids.total_volume
	human.SoakMob(CHEST, FALSE, TRUE)
	TEST_ASSERT_EQUAL(feet.fluids.total_volume, feet_before, "Rain on the chest should not rinse the feet.")
	feet.dry()
	for(var/i in 1 to 300)
		human.SoakMob(FEET, FALSE, TRUE)
		if(!coated.coats[FLUID_COAT_FEET])
			break
	TEST_ASSERT_NULL(coated.coats[FLUID_COAT_FEET], "Rain should slowly wash dried crust away.")

	var/obj/item/clothing/shirt/shortshirt/shirt = allocate(/obj/item/clothing/shirt/shortshirt)
	TEST_ASSERT(human.equip_to_slot_if_possible(shirt, ITEM_SLOT_SHIRT, disable_warning = TRUE, bypass_equip_delay_self = TRUE), "The test human should wear the shirt.")
	shirt.soak_fluid(source, 5)
	var/soaked = shirt.reagents.total_volume
	human.SoakMob(CHEST, FALSE, TRUE)
	TEST_ASSERT(shirt.reagents.total_volume < soaked, "Rain should rinse the shirt over the chest.")
	qdel(source)

/datum/unit_test/fluid_scent_marks_and_notes/Run()
	var/mob/living/carbon/human/leaker = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = new
	vagina.Insert(leaker, TRUE, FALSE)
	vagina.reagents.clear_reagents()
	vagina.reagents.add_reagent(/datum/reagent/consumable/cum, 20)
	var/marks_before = length(GLOB.fluid_scent_marks)
	vagina.leak_reagents()
	TEST_ASSERT_EQUAL(length(GLOB.fluid_scent_marks), marks_before + 1, "A bare leak should leave a scent mark.")
	var/datum/fluid_scent_mark/mark = GLOB.fluid_scent_marks[length(GLOB.fluid_scent_marks)]
	TEST_ASSERT_EQUAL(mark.kind, "seed", "The mark should smell of what leaked.")
	vagina.leak_reagents()
	TEST_ASSERT_EQUAL(length(GLOB.fluid_scent_marks), marks_before + 1, "Leaking on the same tile again should not stack marks.")

	mark.time = world.time - 11 MINUTES
	prune_fluid_scent_marks()
	TEST_ASSERT(!(mark in GLOB.fluid_scent_marks), "Old marks should fade.")

	TEST_ASSERT(findtext(get_fluid_scent_note(leaker), "fresh seed"), "Seed inside should be smelled.")
	leaker.add_fluid_modifier(/datum/fluid_modifier/in_heat, "test")
	TEST_ASSERT(findtext(get_fluid_scent_note(leaker), "in heat"), "Heat should be smelled.")
	leaker.remove_fluid_modifier(/datum/fluid_modifier/in_heat, "test")
	vagina.reagents.clear_reagents()
	// The leak also clung to the thighs; wash that off too.
	leaker.wash(CLEAN_WASH)
	TEST_ASSERT_EQUAL(get_fluid_scent_note(leaker), "", "Nothing to smell should add nothing.")

/datum/unit_test/fluid_full_heels_squelch/Run()
	var/mob/living/carbon/human/wearer = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/shoes/heels/heels = allocate(/obj/item/clothing/shoes/heels)
	TEST_ASSERT(wearer.equip_to_slot_if_possible(heels, ITEM_SLOT_SHOES, disable_warning = TRUE, bypass_equip_delay_self = TRUE), "The test human should wear the heels.")
	TEST_ASSERT(!heels.is_squelching(), "Empty heels should not squelch.")
	heels.reagents.add_reagent(/datum/reagent/consumable/cum, 10)
	TEST_ASSERT(heels.is_squelching(), "Full worn heels should squelch.")
	var/list/lines = wearer.get_fluid_stain_examine(list(THEIR = "their", THEYVE = "they've"))
	TEST_ASSERT(findtext(jointext(lines, " "), "heels squelch"), "Examine should mention the squelching heels.")
	for(var/i in 1 to 3)
		heels.squelch_step()
	TEST_ASSERT(heels.squelch_steps < 3, "Steps should reset after a squelch.")
