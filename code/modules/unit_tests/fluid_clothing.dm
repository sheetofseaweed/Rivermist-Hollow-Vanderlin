/datum/unit_test/fluid_leak_soaks_clothes_inside_out/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = allocate(/obj/item/organ/genitals/filling_organ/vagina)
	vagina.Insert(human, TRUE, FALSE)
	TEST_ASSERT_NOTNULL(vagina.reagents, "Inserted vagina should have a reagent holder.")
	var/obj/item/clothing/undies/panties/panties = allocate(/obj/item/clothing/undies/panties)
	var/obj/item/clothing/pants/trou/trousers = allocate(/obj/item/clothing/pants/trou)
	TEST_ASSERT(human.equip_to_slot_if_possible(panties, ITEM_SLOT_UNDER_BOTTOM, disable_warning = TRUE, bypass_equip_delay_self = TRUE), "The test human should wear panties.")
	TEST_ASSERT(human.equip_to_slot_if_possible(trousers, ITEM_SLOT_PANTS, disable_warning = TRUE, bypass_equip_delay_self = TRUE), "The test human should wear trousers.")

	var/list/covers = vagina.get_opening_covers()
	TEST_ASSERT_EQUAL(length(covers), 2, "Panties and trousers should both cover the vagina.")
	TEST_ASSERT_EQUAL(covers[1], panties, "Panties should be the innermost cover.")

	vagina.reagents.clear_reagents()
	vagina.reagents.add_reagent(/datum/reagent/consumable/cum, 40)
	TEST_ASSERT_EQUAL(vagina.soak_into_covers(covers, 15), 0, "Nothing should drip while the clothes can still soak.")
	TEST_ASSERT_EQUAL(panties.reagents?.total_volume, panties.fluid_capacity, "Panties should fill first.")
	TEST_ASSERT_EQUAL(trousers.reagents?.total_volume, 15 - panties.fluid_capacity, "Trousers should take the rest.")
	TEST_ASSERT_NULL(human.has_stress_type(/datum/stress_event/wet_cloth), "Clothes that still hold the fluid should not upset the wearer.")

	var/dripped = vagina.soak_into_covers(covers, 20)
	TEST_ASSERT(dripped > 0, "Fluid should drip through once every layer is soaked.")
	TEST_ASSERT_NOTNULL(human.has_stress_type(/datum/stress_event/wet_cloth), "Soaking through every layer should upset the wearer.")

	panties.reagents.clear_reagents()
	vagina.leak_reagents()
	TEST_ASSERT(panties.reagents.total_volume > 0, "A real leak should go into the clothes.")

/datum/unit_test/fluid_leak_sealed_by_non_absorbent_cover/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = allocate(/obj/item/organ/genitals/filling_organ/vagina)
	vagina.Insert(human, TRUE, FALSE)
	var/obj/item/clothing/pants/trou/trousers = allocate(/obj/item/clothing/pants/trou)
	trousers.material_category = ARMOR_MAT_CHAINMAIL
	TEST_ASSERT(human.equip_to_slot_if_possible(trousers, ITEM_SLOT_PANTS, disable_warning = TRUE, bypass_equip_delay_self = TRUE), "The test human should wear the trousers.")
	vagina.reagents.clear_reagents()
	vagina.reagents.add_reagent(/datum/reagent/consumable/cum, 30)

	TEST_ASSERT_EQUAL(vagina.soak_into_covers(vagina.get_opening_covers(), 10), 0, "A cover that does not soak should hold the fluid in.")
	TEST_ASSERT_NULL(trousers.reagents, "A cover that does not soak should take no fluid.")

/datum/unit_test/fluid_full_breasts_let_down_into_bra/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/breasts/breasts = allocate(/obj/item/organ/genitals/filling_organ/breasts)
	breasts.Insert(human, TRUE, FALSE)
	TEST_ASSERT_NOTNULL(breasts.reagents, "Inserted breasts should have a reagent holder.")
	var/obj/item/clothing/bra/bra = allocate(/obj/item/clothing/bra)
	TEST_ASSERT(human.equip_to_slot_if_possible(bra, ITEM_SLOT_UNDER_TOP, disable_warning = TRUE, bypass_equip_delay_self = TRUE), "The test human should wear a bra.")
	var/capacity = breasts.reagents.maximum_volume

	breasts.reagents.clear_reagents()
	breasts.reagents.add_reagent(breasts.reagent_to_make, capacity * 0.95)
	breasts.leak_reagents()
	TEST_ASSERT_NULL(bra.reagents, "Breasts that are not completely full should not leak.")

	breasts.reagents.add_reagent(breasts.reagent_to_make, capacity)
	breasts.leak_reagents()
	var/first_letdown = bra.reagents?.total_volume
	TEST_ASSERT(first_letdown > 0, "Completely full breasts should let down into the bra.")
	breasts.leak_reagents()
	TEST_ASSERT_EQUAL(bra.reagents.total_volume, first_letdown, "Let-downs should come only now and then.")
	var/datum/component/fluid_soaked/soak = bra.GetComponent(/datum/component/fluid_soaked)
	TEST_ASSERT_NOTNULL(soak, "A wet bra should track its fluid.")
	TEST_ASSERT(FLUID_STAIN_CHEST in soak.stain_zones, "Breast fluid should stain the chest.")

/datum/unit_test/fluid_soaked_garment_shows_stain/Run()
	var/mob/living/carbon/human/examiner = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/undies/panties/panties = allocate(/obj/item/clothing/undies/panties)
	var/datum/reagents/source = new /datum/reagents(50)
	source.add_reagent(/datum/reagent/consumable/cum, 50)
	var/mutable_appearance/standing = mutable_appearance(panties.mob_overlay_icon, "panties")
	var/dry_overlays = length(panties.worn_overlays(standing))

	panties.soak_fluid(source, panties.fluid_capacity * 0.3)
	var/datum/component/fluid_soaked/soak = panties.GetComponent(/datum/component/fluid_soaked)
	TEST_ASSERT_NOTNULL(soak, "Soaking should attach the fluid tracker.")
	TEST_ASSERT_EQUAL(soak.stain_level, 1, "Some fluid should leave a damp spot.")
	panties.soak_fluid(source, panties.fluid_capacity)
	TEST_ASSERT_EQUAL(soak.stain_level, 2, "A full garment should look soaked.")

	var/list/wet_overlays = panties.worn_overlays(standing)
	TEST_ASSERT_EQUAL(length(wet_overlays), dry_overlays + 2, "A garment full of semen should draw a wet spot and a coat.")
	var/stain_count = 0
	for(var/mutable_appearance/overlay as anything in wet_overlays)
		if(overlay.alpha == 100)
			stain_count++
	TEST_ASSERT_EQUAL(stain_count, 1, "The wet spot should be drawn once at alpha 100.")
	TEST_ASSERT(findtext(jointext(panties.examine(examiner), " "), "soaked through with semen"), "Examine should name the fluid.")
	qdel(source)

/datum/unit_test/fluid_stain_shows_on_wearer_examine/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/undies/panties/panties = allocate(/obj/item/clothing/undies/panties)
	TEST_ASSERT(human.equip_to_slot_if_possible(panties, ITEM_SLOT_UNDER_BOTTOM, disable_warning = TRUE, bypass_equip_delay_self = TRUE), "The test human should wear panties.")
	var/list/pronouns = list(THEIR = "their", THEYVE = "they have")
	TEST_ASSERT_EQUAL(length(human.get_fluid_stain_examine(pronouns)), 0, "Dry panties should not be mentioned.")

	var/datum/reagents/source = new /datum/reagents(50)
	source.add_reagent(/datum/reagent/consumable/femcum, 50)
	panties.soak_fluid(source, panties.fluid_capacity * 0.3)
	TEST_ASSERT(findtext(jointext(human.get_fluid_stain_examine(pronouns), " "), "damp spot on their panties"), "A damp spot should show on examine.")
	qdel(source)

/datum/unit_test/fluid_wring_dip_and_wash/Run()
	var/obj/item/clothing/undies/panties/panties = allocate(/obj/item/clothing/undies/panties)
	var/obj/item/reagent_containers/glass/bucket/bucket = allocate(/obj/item/reagent_containers/glass/bucket)
	bucket.reagents.add_reagent(/datum/reagent/consumable/milk, 30)

	TEST_ASSERT(panties.soak_fluid(bucket.reagents, panties.fluid_capacity) > 0, "Dipping should soak the garment.")
	TEST_ASSERT_EQUAL(panties.reagents.get_reagent_amount(/datum/reagent/consumable/milk), panties.fluid_capacity, "The garment should hold its capacity.")

	var/obj/item/reagent_containers/glass/bucket/empty_bucket = allocate(/obj/item/reagent_containers/glass/bucket)
	TEST_ASSERT_EQUAL(panties.pour_soaked_fluid_into(empty_bucket, null), panties.fluid_capacity, "Wringing into a container should move all the fluid.")
	TEST_ASSERT_EQUAL(panties.reagents.total_volume, 0, "A wrung garment should be empty.")

	panties.soak_fluid(bucket.reagents, panties.fluid_capacity)
	TEST_ASSERT_EQUAL(panties.spill_soaked_fluid_onto(get_turf(panties)), panties.fluid_capacity, "Wringing onto the floor should spill all the fluid.")

	panties.soak_fluid(bucket.reagents, 5)
	panties.wash(CLEAN_WASH)
	TEST_ASSERT_NULL(panties.GetComponent(/datum/component/fluid_soaked), "Washing should remove the fluid tracker.")
	TEST_ASSERT_NULL(panties.reagents, "Washing should remove the soaked fluid.")

/datum/unit_test/fluid_dried_stain_smells_until_washed/Run()
	var/mob/living/carbon/human/examiner = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/undies/panties/panties = allocate(/obj/item/clothing/undies/panties)
	var/datum/reagents/source = new /datum/reagents(50)
	source.add_reagent(/datum/reagent/consumable/cum, 50)
	panties.soak_fluid(source, 5)
	var/datum/component/fluid_soaked/soak = panties.GetComponent(/datum/component/fluid_soaked)
	TEST_ASSERT_NOTNULL(soak, "Soaking should attach the fluid tracker.")

	soak.process(60)
	TEST_ASSERT(panties.reagents.total_volume < 5, "Soaked fluid should evaporate over time.")
	var/turf/open/panties_turf = get_turf(panties)
	TEST_ASSERT(panties_turf?.pollution?.pollutants[/datum/pollutant/body_fluid/seed] > 0, "A dirty garment should give off a smell.")

	soak.evaporate(100)
	soak.process(1)
	TEST_ASSERT_EQUAL(panties.reagents.total_volume, 0, "The fluid should dry out completely.")
	TEST_ASSERT(findtext(jointext(panties.examine(examiner), " "), "dried stains of semen"), "A dried garment should keep its stain.")
	TEST_ASSERT_NOTNULL(panties.GetComponent(/datum/component/fluid_soaked), "A dried stain should keep smelling until washed.")

	panties.wash(CLEAN_WASH)
	TEST_ASSERT_NULL(panties.GetComponent(/datum/component/fluid_soaked), "Washing should remove the stain and its smell.")
	qdel(source)

/datum/unit_test/fluid_held_garment_lick_feeds_drinker/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/stomach/stomach = human.getorganslot(ORGAN_SLOT_STOMACH)
	TEST_ASSERT_NOTNULL(stomach?.reagents, "The test human should have a stomach with reagents.")
	var/obj/item/clothing/undies/panties/panties = allocate(/obj/item/clothing/undies/panties)
	var/datum/reagents/source = new /datum/reagents(50)
	source.add_reagent(/datum/reagent/consumable/femcum, 50)
	panties.soak_fluid(source, 5)

	TEST_ASSERT_EQUAL(panties.drink_soaked_fluid(human, human), FLUID_LICK_AMOUNT, "A lick should swallow one mouthful.")
	TEST_ASSERT_EQUAL(panties.reagents.total_volume, 5 - FLUID_LICK_AMOUNT, "The garment should lose what was licked.")
	TEST_ASSERT_EQUAL(stomach.reagents.get_reagent_amount(/datum/reagent/consumable/femcum), FLUID_LICK_AMOUNT, "The licked fluid should reach the stomach.")
	qdel(source)

/datum/unit_test/fluid_lick_action_needs_visible_wet_clothes/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/undies/panties/panties = allocate(/obj/item/clothing/undies/panties)
	TEST_ASSERT(target.equip_to_slot_if_possible(panties, ITEM_SLOT_UNDER_BOTTOM, disable_warning = TRUE, bypass_equip_delay_self = TRUE), "The target should wear panties.")
	var/datum/sex_action/lick_soaked_clothes/crotch/action = allocate(/datum/sex_action/lick_soaked_clothes/crotch)

	TEST_ASSERT(!action.shows_on_menu(user, target), "Dry panties should not offer licking.")
	var/datum/reagents/source = new /datum/reagents(50)
	source.add_reagent(/datum/reagent/consumable/femcum, 50)
	panties.soak_fluid(source, 6)
	TEST_ASSERT(action.shows_on_menu(user, target), "Wet panties should offer licking.")
	TEST_ASSERT(action.can_perform(user, target), "Wet panties should be lickable.")

	var/runtimed = FALSE
	try
		action.on_perform(user, target)
	catch
		runtimed = TRUE
	TEST_ASSERT(!runtimed, "Licking should not runtime.")
	TEST_ASSERT_EQUAL(panties.reagents.total_volume, 6 - FLUID_LICK_AMOUNT, "Licking should drain the panties.")

	var/obj/item/clothing/pants/trou/trousers = allocate(/obj/item/clothing/pants/trou)
	trousers.flags_inv |= HIDECROTCH
	TEST_ASSERT(target.equip_to_slot_if_possible(trousers, ITEM_SLOT_PANTS, disable_warning = TRUE, bypass_equip_delay_self = TRUE), "The target should wear trousers.")
	TEST_ASSERT(!action.can_perform(user, target), "Wet panties under dry trousers should be out of reach.")
	qdel(source)

/datum/unit_test/fluid_heels_hold_a_drink_until_worn/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/stomach/stomach = human.getorganslot(ORGAN_SLOT_STOMACH)
	TEST_ASSERT_NOTNULL(stomach?.reagents, "The test human should have a stomach with reagents.")
	var/obj/item/clothing/shoes/heels/heels = allocate(/obj/item/clothing/shoes/heels)
	TEST_ASSERT(heels.is_refillable(), "Heels off the feet should accept a drink.")
	heels.reagents.add_reagent(/datum/reagent/consumable/milk, 10)

	TEST_ASSERT(heels.drink_from_heel(human, human), "Drinking from a heel should work.")
	TEST_ASSERT_EQUAL(heels.reagents.total_volume, 5, "A sip should take five units.")
	TEST_ASSERT_EQUAL(stomach.reagents.get_reagent_amount(/datum/reagent/consumable/milk), 5, "The sip should reach the stomach.")

	TEST_ASSERT(human.equip_to_slot_if_possible(heels, ITEM_SLOT_SHOES, disable_warning = TRUE, bypass_equip_delay_self = TRUE), "The test human should wear the heels.")
	TEST_ASSERT_EQUAL(heels.reagents.total_volume, 0, "Putting on full heels should spill the drink.")
	TEST_ASSERT(!heels.is_refillable(), "Worn heels should not accept a drink.")

/// Switches the user's intent to the held item's intent of this type; TRUE when it was offered.
/proc/select_test_intent(mob/living/user, intent_type)
	for(var/i in 1 to length(user.possible_a_intents))
		var/datum/intent/intent = user.possible_a_intents[i]
		if(intent.type == intent_type)
			user.rog_intent_change(i)
			return TRUE
	return FALSE

/datum/unit_test/fluid_heels_work_like_a_cup/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	user.mind_initialize()
	var/obj/item/organ/stomach/stomach = user.getorganslot(ORGAN_SLOT_STOMACH)
	var/obj/item/clothing/shoes/heels/color/courtesan/heels = allocate(/obj/item/clothing/shoes/heels/color/courtesan)
	heels.reagents.add_reagent(/datum/reagent/consumable/milk, 15)
	TEST_ASSERT(user.put_in_active_hand(heels, forced = TRUE), "The user should hold the heels.")
	TEST_ASSERT_EQUAL(user.used_intent?.type, INTENT_POUR, "Held heels should default to the feed intent.")

	user.zone_selected = BODY_ZONE_CHEST
	heels.melee_attack_chain(user, user)
	TEST_ASSERT_EQUAL(stomach.reagents.get_reagent_amount(/datum/reagent/consumable/milk), 5, "Feeding yourself from a heel should drink from it, whatever zone is aimed at.")

	var/obj/item/reagent_containers/glass/bucket/bucket = allocate(/obj/item/reagent_containers/glass/bucket)
	heels.melee_attack_chain(user, bucket)
	TEST_ASSERT(bucket.reagents.get_reagent_amount(/datum/reagent/consumable/milk) > 0, "The feed intent should pour a heel into a container.")
	var/in_bucket = bucket.reagents.total_volume

	heels.reagents.add_reagent(/datum/reagent/consumable/milk, 5)
	heels.melee_attack_chain(user, bucket)
	TEST_ASSERT_EQUAL(bucket.reagents.total_volume, in_bucket + 5, "Heels should pour into a container that already holds liquid, not get dunked in it.")
	in_bucket = bucket.reagents.total_volume

	TEST_ASSERT(select_test_intent(user, INTENT_FILL), "Held heels should offer the fill intent.")
	var/in_heels_before = heels.reagents.total_volume
	heels.melee_attack_chain(user, bucket)
	TEST_ASSERT(heels.reagents.total_volume > in_heels_before, "The fill intent should scoop a container back into the heel.")
	TEST_ASSERT(bucket.reagents.total_volume < in_bucket, "Scooping should take from the container.")

	user.dropItemToGround(heels, force = TRUE)
	var/obj/item/reagent_containers/glass/bottle/bottle = allocate(/obj/item/reagent_containers/glass/bottle)
	bottle.toggle_cork(user, FALSE)
	TEST_ASSERT(user.put_in_active_hand(bottle, forced = TRUE), "The user should hold the bottle.")
	TEST_ASSERT(select_test_intent(user, INTENT_FILL), "A held bottle should offer the fill intent.")
	var/in_heels = heels.reagents.total_volume
	TEST_ASSERT(in_heels > 0, "The heels should still hold some milk.")
	bottle.melee_attack_chain(user, heels)
	TEST_ASSERT(bottle.reagents.get_reagent_amount(/datum/reagent/consumable/milk) > 0, "A bottle should be able to drain the heels.")

	user.dropItemToGround(bottle, force = TRUE)
	heels.reagents.add_reagent(/datum/reagent/water, 5)
	TEST_ASSERT(user.put_in_active_hand(heels, forced = TRUE), "The user should hold the heels again.")
	TEST_ASSERT(select_test_intent(user, INTENT_SPLASH), "Held heels should offer the splash intent.")
	heels.melee_attack_chain(user, get_turf(user))
	TEST_ASSERT_EQUAL(heels.reagents.total_volume, 0, "Splashing should empty the heels.")

/datum/unit_test/fluid_semen_coat_stays_until_washed/Run()
	var/obj/item/clothing/undies/panties/panties = allocate(/obj/item/clothing/undies/panties)
	var/mutable_appearance/standing = mutable_appearance(panties.mob_overlay_icon, "panties")
	var/dry_worn = length(panties.worn_overlays(standing))
	var/dry_item = length(panties.update_overlays())
	var/datum/reagents/source = new /datum/reagents(50)
	source.add_reagent(/datum/reagent/consumable/cum/sterile, 50)

	panties.soak_fluid(source, 2)
	var/datum/component/fluid_soaked/soak = panties.GetComponent(/datum/component/fluid_soaked)
	TEST_ASSERT_NOTNULL(soak, "Soaking should attach the fluid tracker.")
	TEST_ASSERT_EQUAL(soak.coat_level, 1, "A little semen, sterile too, should leave a light coat.")
	panties.soak_fluid(source, panties.fluid_capacity)
	TEST_ASSERT_EQUAL(soak.coat_level, 2, "A garment full of semen should get a heavy coat.")
	TEST_ASSERT_EQUAL(length(panties.update_overlays()), dry_item + 1, "The coat should show on the garment's own icon.")

	soak.evaporate(100)
	TEST_ASSERT_EQUAL(soak.coat_level, 1, "Dried semen should leave a crust.")
	TEST_ASSERT_EQUAL(length(panties.worn_overlays(standing)), dry_worn + 1, "A dry but dirty garment should draw only the crust.")

	panties.wash(CLEAN_WASH)
	TEST_ASSERT_EQUAL(length(panties.update_overlays()), dry_item, "Washing should remove the coat.")
	qdel(source)

/datum/unit_test/fluid_femcum_leaves_no_coat/Run()
	var/obj/item/clothing/undies/panties/panties = allocate(/obj/item/clothing/undies/panties)
	var/datum/reagents/source = new /datum/reagents(50)
	source.add_reagent(/datum/reagent/consumable/femcum, 50)
	panties.soak_fluid(source, panties.fluid_capacity)
	var/datum/component/fluid_soaked/soak = panties.GetComponent(/datum/component/fluid_soaked)
	TEST_ASSERT_EQUAL(soak.stain_level, 2, "Femcum should still soak the garment.")
	TEST_ASSERT_EQUAL(soak.coat_level, 0, "Only semen should draw the coat.")
	qdel(source)

/datum/unit_test/fluid_garment_pleasure_climax_coats_garment/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/penis/penis = allocate(/obj/item/organ/genitals/penis)
	penis.Insert(partner, TRUE, FALSE)
	var/obj/item/organ/genitals/filling_organ/testicles/testicles = allocate(/obj/item/organ/genitals/filling_organ/testicles)
	testicles.Insert(partner, TRUE, FALSE)
	TEST_ASSERT_NOTNULL(testicles.reagents, "Inserted testicles should have a reagent holder.")
	testicles.reagents.clear_reagents()
	testicles.reagents.add_reagent(/datum/reagent/consumable/cum, testicles.reagents.maximum_volume)
	var/datum/sex_action/garment_pleasure/self/self_action = allocate(/datum/sex_action/garment_pleasure/self)
	var/datum/sex_action/garment_pleasure/other/other_action = allocate(/datum/sex_action/garment_pleasure/other)

	TEST_ASSERT(!other_action.shows_on_menu(user, partner), "Empty hands should not offer the garment action.")
	var/obj/item/clothing/undies/panties/panties = allocate(/obj/item/clothing/undies/panties)
	TEST_ASSERT(user.put_in_active_hand(panties, forced = TRUE), "The user should hold the panties.")
	TEST_ASSERT(other_action.shows_on_menu(user, partner), "Held panties should offer pleasuring a partner.")
	TEST_ASSERT(other_action.can_perform(user, partner), "Held panties should work on a partner with a penis.")
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = allocate(/obj/item/organ/genitals/filling_organ/vagina)
	vagina.Insert(user, TRUE, FALSE)
	TEST_ASSERT(self_action.shows_on_menu(user, user), "A user with genitals should get the self action.")
	TEST_ASSERT(!self_action.shows_on_menu(user, partner), "The self action should not show on a partner.")
	TEST_ASSERT(!other_action.shows_on_menu(user, user), "The partner action should not show on the user.")

	// The climaxing partner is passed first; the garment is found in the performer's hand.
	TEST_ASSERT_EQUAL(other_action.get_climax_container(partner, user, user, partner, user), panties, "The climax should go into the held panties.")
	TEST_ASSERT_NOTNULL(panties.reagents, "The panties should be ready to take the climax.")

	var/datum/component/arousal/arousal = partner.LoadComponent(/datum/component/arousal)
	var/runtimed = FALSE
	try
		arousal.handle_climax(other_action, ORGASM_LOCATION_CONTAINER, partner, user, FALSE, user, partner, user)
	catch
		runtimed = TRUE
	TEST_ASSERT(!runtimed, "Climaxing into a garment should not runtime.")
	TEST_ASSERT(panties.reagents.get_reagent_amount(/datum/reagent/consumable/cum) > 0, "The climax should soak into the panties.")
	var/datum/component/fluid_soaked/soak = panties.GetComponent(/datum/component/fluid_soaked)
	soak.process(0)
	TEST_ASSERT(soak.coat_level > 0, "The climax should coat the panties.")

	var/obj/item/reagent_containers/glass/bottle/bottle = allocate(/obj/item/reagent_containers/glass/bottle)
	user.dropItemToGround(panties, force = TRUE)
	TEST_ASSERT(user.put_in_active_hand(bottle, forced = TRUE), "The user should hold the bottle.")
	TEST_ASSERT(!other_action.shows_on_menu(user, partner), "A held bottle is not a garment.")

/datum/unit_test/fluid_garment_pleasure_self_soaks_wetness/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = allocate(/obj/item/organ/genitals/filling_organ/vagina)
	vagina.Insert(user, TRUE, FALSE)
	vagina.reagents.clear_reagents()
	vagina.reagents.add_reagent(/datum/reagent/consumable/femcum, 10)
	var/datum/sex_action/garment_pleasure/self/action = allocate(/datum/sex_action/garment_pleasure/self)
	TEST_ASSERT(!action.shows_on_menu(user, user), "Empty hands should not offer the garment action.")

	var/obj/item/clothing/undies/panties/panties = allocate(/obj/item/clothing/undies/panties)
	TEST_ASSERT(user.put_in_active_hand(panties, forced = TRUE), "The user should hold the panties.")
	TEST_ASSERT(action.shows_on_menu(user, user), "Held panties should offer pleasuring yourself.")
	TEST_ASSERT(action.can_perform(user, user), "A user with a vagina should be able to use the panties.")

	var/runtimed = FALSE
	try
		action.on_perform(user, user)
	catch
		runtimed = TRUE
	TEST_ASSERT(!runtimed, "Rubbing with the panties should not runtime.")
	TEST_ASSERT(panties.reagents?.get_reagent_amount(/datum/reagent/consumable/femcum) > 0, "Rubbing a wet vagina should soak the panties.")
