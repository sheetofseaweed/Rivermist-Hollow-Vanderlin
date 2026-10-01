/// Pronouns for coat examine lines.
/proc/get_coat_test_pronouns()
	return list(THEYRE = "they're", THEIR = "their")

/datum/unit_test/fluid_coat_lands_on_bare_skin_dries_and_washes/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	// A playable species, so the body parts have sprites to clip the coat to.
	human.set_species(/datum/species/human/northern)
	var/datum/reagents/source = new /datum/reagents(60)
	source.add_reagent(/datum/reagent/consumable/cum, 60)

	TEST_ASSERT_EQUAL(human.coat_with_fluid(FLUID_COAT_CHEST, source, 10), 0, "Bare skin should take all of it.")
	var/datum/component/fluid_coated/coated = human.GetComponent(/datum/component/fluid_coated)
	TEST_ASSERT_NOTNULL(coated, "Coating skin should attach the coat tracker.")
	var/datum/fluid_coat/coat = coated.coats[FLUID_COAT_CHEST]
	TEST_ASSERT_EQUAL(coat.get_level(), 2, "Ten units should coat heavily.")
	TEST_ASSERT_EQUAL(length(coated.applied_overlays), 1, "The coat should draw on the body.")
	TEST_ASSERT(findtext(jointext(coated.get_examine_lines(human, get_coat_test_pronouns()), " "), "chest is glazed with cum"), "One coated zone should be named.")
	TEST_ASSERT(human.coat_with_fluid(FLUID_COAT_CHEST, source, 20) > 0, "A full zone should let the rest run off.")

	coat.dry_at = world.time - 1
	coated.process(1)
	TEST_ASSERT(!coat.is_wet(), "A coat should dry after a while.")
	TEST_ASSERT(findtext(jointext(coated.get_examine_lines(human, get_coat_test_pronouns()), " "), "crusted with dried cum"), "A dried coat should read as crust.")
	TEST_ASSERT_EQUAL(length(coated.applied_overlays), 1, "The crust should still draw.")

	human.wash(CLEAN_WASH)
	TEST_ASSERT_NULL(human.GetComponent(/datum/component/fluid_coated), "Washing should clear every coat.")
	qdel(source)

/datum/unit_test/fluid_coat_covered_zone_soaks_the_clothes/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/shirt/shortshirt/shirt = allocate(/obj/item/clothing/shirt/shortshirt)
	TEST_ASSERT(shirt.can_soak_fluid(), "The test shirt should be cloth.")
	TEST_ASSERT(human.equip_to_slot_if_possible(shirt, ITEM_SLOT_SHIRT, disable_warning = TRUE, bypass_equip_delay_self = TRUE), "The test human should wear the shirt.")
	var/datum/reagents/source = new /datum/reagents(20)
	source.add_reagent(/datum/reagent/consumable/cum, 20)

	TEST_ASSERT_EQUAL(human.get_coat_zone_cover(FLUID_COAT_BELLY), shirt, "The shirt should cover the belly.")
	human.coat_with_fluid(FLUID_COAT_BELLY, source, 5)
	TEST_ASSERT_EQUAL(shirt.reagents?.get_reagent_amount(/datum/reagent/consumable/cum), 5, "The shirt should soak what lands on it.")
	TEST_ASSERT_NULL(human.GetComponent(/datum/component/fluid_coated), "Skin under the shirt should stay clean.")
	qdel(source)

/datum/unit_test/fluid_coat_several_zones_read_as_covered/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/datum/reagents/source = new /datum/reagents(20)
	source.add_reagent(/datum/reagent/consumable/femcum, 20)
	human.coat_with_fluid(FLUID_COAT_FACE, source, 4)
	var/datum/component/fluid_coated/coated = human.GetComponent(/datum/component/fluid_coated)
	TEST_ASSERT(findtext(jointext(coated.get_examine_lines(human, get_coat_test_pronouns()), " "), "face is glazed with juices"), "A lone facial should be named.")
	human.coat_with_fluid(FLUID_COAT_FEET, source, 4)
	TEST_ASSERT(findtext(jointext(coated.get_examine_lines(human, get_coat_test_pronouns()), " "), "covered in juices"), "Several zones should read as covered in juices.")
	qdel(source)

/datum/unit_test/fluid_coat_onto_climax_lands_where_aimed/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/penis/penis = allocate(/obj/item/organ/genitals/penis)
	penis.Insert(user, TRUE, FALSE)
	var/obj/item/organ/genitals/filling_organ/testicles/testicles = allocate(/obj/item/organ/genitals/filling_organ/testicles)
	testicles.Insert(user, TRUE, FALSE)
	var/datum/sex_action/sex/vaginal/pull_out = allocate(/datum/sex_action/sex/vaginal)
	var/datum/sex_action/masturbate/penis_over/over = allocate(/datum/sex_action/masturbate/penis_over)
	user.zone_selected = BODY_ZONE_PRECISE_L_FOOT
	TEST_ASSERT_EQUAL(pull_out.get_climax_coat_zone(user), FLUID_COAT_BELLY, "Pulling out should land on the belly.")
	TEST_ASSERT_EQUAL(over.get_climax_coat_zone(user), FLUID_COAT_FEET, "Jerking off over someone should follow the aim.")

	var/datum/component/arousal/arousal = user.GetComponent(/datum/component/arousal)
	var/runtimed = FALSE
	try
		arousal.handle_climax(pull_out, ORGASM_LOCATION_ONTO, user, target, FALSE, user, target, user)
	catch
		runtimed = TRUE
	TEST_ASSERT(!runtimed, "Climaxing onto a partner should not runtime.")
	var/datum/component/fluid_coated/coated = target.GetComponent(/datum/component/fluid_coated)
	var/datum/fluid_coat/belly = coated?.coats[FLUID_COAT_BELLY]
	TEST_ASSERT(belly?.fluids?.get_reagent_amount(/datum/reagent/consumable/cum) > 0, "The load should coat the partner's belly.")
	TEST_ASSERT_NULL(target.has_status_effect(/datum/status_effect/facial), "The old facial status should not be used any more.")

	runtimed = FALSE
	try
		arousal.spill_climax_on_face(target, testicles, null)
	catch
		runtimed = TRUE
	TEST_ASSERT(!runtimed, "An oral spill should not runtime.")
	var/datum/fluid_coat/face = coated.coats[FLUID_COAT_FACE]
	TEST_ASSERT_EQUAL(face?.fluids?.total_volume, FLUID_COAT_ORAL_SPILL, "An oral climax should leave a little on the face.")

/datum/unit_test/fluid_coat_bare_leak_clings_and_licks_off/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = allocate(/obj/item/organ/genitals/filling_organ/vagina)
	vagina.Insert(human, TRUE, FALSE)
	vagina.reagents.clear_reagents()
	vagina.reagents.add_reagent(vagina.reagent_to_make, 10)
	TEST_ASSERT_EQUAL(vagina.cling_to_skin(4), 2, "Half of a bare leak should cling to the skin.")
	var/datum/component/fluid_coated/coated = human.GetComponent(/datum/component/fluid_coated)
	TEST_ASSERT(findtext(jointext(coated?.get_examine_lines(human, get_coat_test_pronouns()), " "), "Juices run down their thighs"), "Nectar should run down the thighs.")

	var/mob/living/carbon/human/licker = allocate(/mob/living/carbon/human)
	var/datum/sex_action/lick_coat/lick = allocate(/datum/sex_action/lick_coat)
	TEST_ASSERT(lick.shows_on_menu(licker, human), "Wet bare skin should offer licking it clean.")
	var/obj/item/organ/stomach/stomach = licker.getorganslot(ORGAN_SLOT_STOMACH)
	coated.lick_zone(FLUID_COAT_THIGHS, licker)
	TEST_ASSERT(stomach.reagents.get_reagent_amount(/datum/reagent/consumable/femcum) > 0, "Licking should swallow the coat.")
	TEST_ASSERT_NULL(human.GetComponent(/datum/component/fluid_coated), "A zone licked clean should leave no crust.")

	vagina.reagents.add_reagent(vagina.reagent_to_make, 10)
	vagina.reagents.maximum_volume = vagina.reagents.total_volume / 2
	vagina.leak_reagents()
	coated = human.GetComponent(/datum/component/fluid_coated)
	TEST_ASSERT_NOTNULL(coated?.coats[FLUID_COAT_THIGHS], "A real bare leak should run down the thighs.")

/datum/unit_test/fluid_coat_draws_clipped_to_the_body/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.set_species(/datum/species/human/northern)
	var/list/part_sprites = human.get_coat_part_sprites()
	var/list/head_sprite = part_sprites[BODY_ZONE_HEAD]
	TEST_ASSERT_NOTNULL(head_sprite, "The test human should have a drawn head.")
	var/icon/head = icon(head_sprite[1], head_sprite[2], SOUTH)
	var/face_pixels = 0
	for(var/variant in 1 to 3)
		var/icon/coat = icon(get_fluid_coat_icon(part_sprites, FLUID_COAT_FACE, 2, variant))
		var/icon/south = icon(coat, "", SOUTH)
		var/icon/north = icon(coat, "", NORTH)
		for(var/x in 1 to south.Width())
			for(var/y in 1 to south.Height())
				TEST_ASSERT_NULL(north.GetPixel(x, y), "A facial should not show from behind.")
				if(!south.GetPixel(x, y))
					continue
				face_pixels++
				TEST_ASSERT_NOTNULL(head.GetPixel(x, y), "A facial should stay on the head sprite, stray pixel at [x],[y].")
	TEST_ASSERT(face_pixels > 0, "A facial should draw something on the face.")
