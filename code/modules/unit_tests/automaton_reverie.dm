/datum/unit_test/construct_awake_rest_restores_energy

/datum/unit_test/construct_awake_rest_restores_energy/Run()
	var/mob/living/carbon/human/construct = allocate(/mob/living/carbon/human/species/construct)
	TEST_ASSERT(HAS_TRAIT(construct, TRAIT_NOSLEEP), "Warforged should not be able to sleep.")
	construct.energy = 0
	construct.set_body_position(LYING_DOWN)
	construct.handle_sleep()
	TEST_ASSERT(construct.energy > 0, "A sleepless Warforged lying down should regain energy at rest.")

/datum/unit_test/construct_reverie_deep_rest

/datum/unit_test/construct_reverie_deep_rest/Run()
	var/mob/living/carbon/human/construct = allocate(/mob/living/carbon/human/species/construct)
	var/datum/component/reverie/reverie = construct.GetComponent(/datum/component/reverie)
	TEST_ASSERT_NOTNULL(reverie, "Warforged should get Reverie from their species.")
	TEST_ASSERT_EQUAL(reverie.rest_name, "Dormancy", "Warforged Reverie should use their own name.")

	construct.mind = allocate(/datum/mind, "reverie-test-mind")
	construct.mind.current = construct
	construct.update_tod("night")
	var/offered_dream = construct.has_status_effect(/datum/status_effect/debuff/dreamytime)

	var/obj/item/bodypart/arm = construct.get_bodypart(BODY_ZONE_R_ARM)
	var/datum/injury/dent = arm.create_injury(WOUND_BLUNT, 10, TRUE)
	arm.post_damage_change()
	var/dent_damage = dent?.damage
	construct.energy = 0
	construct.set_body_position(LYING_DOWN)
	reverie.enter(construct)
	var/datum/status_effect/reverie/effect = construct.has_status_effect(/datum/status_effect/reverie)
	var/entered = !isnull(effect)
	var/eyes_closed = construct.eyesclosed
	for(var/i in 1 to 26)
		if(QDELETED(effect))
			break
		effect.tick()
	var/still_resting = !QDELETED(effect)
	var/dream_spent = !construct.has_status_effect(/datum/status_effect/debuff/dreamytime)
	var/cycles = construct.mind.sleep_adv.sleep_adv_cycle
	var/energy = construct.energy
	var/dent_after = QDELETED(dent) ? 0 : dent.damage

	construct.remove_status_effect(/datum/status_effect/reverie)
	var/eyes_reopened = !construct.eyesclosed
	construct.mind.current = null
	construct.mind = null

	TEST_ASSERT(offered_dream, "Nightfall should offer a Reverie holder tonight's dream.")
	TEST_ASSERT(entered, "A lying Warforged should enter Reverie.")
	TEST_ASSERT(eyes_closed, "Reverie should close the eyes.")
	TEST_ASSERT(still_resting, "An undisturbed Reverie should not end by itself.")
	TEST_ASSERT(dream_spent, "Deep Reverie should spend tonight's dream.")
	TEST_ASSERT_EQUAL(cycles, 1, "Deep Reverie should run one dream cycle.")
	TEST_ASSERT(energy > 0, "Deep Reverie should restore energy.")
	TEST_ASSERT_NOTNULL(dent_damage, "The test dent should exist.")
	TEST_ASSERT(dent_after < dent_damage, "Deep Reverie should mend a small dent.")
	TEST_ASSERT(eyes_reopened, "Leaving Reverie should open the eyes.")

/datum/unit_test/construct_reverie_breaks_on_harm

/datum/unit_test/construct_reverie_breaks_on_harm/Run()
	var/mob/living/carbon/human/construct = allocate(/mob/living/carbon/human/species/construct)
	var/datum/component/reverie/reverie = construct.GetComponent(/datum/component/reverie)
	TEST_ASSERT_NOTNULL(reverie, "Warforged should get Reverie from their species.")
	construct.set_body_position(LYING_DOWN)
	reverie.enter(construct)
	var/datum/status_effect/reverie/effect = construct.has_status_effect(/datum/status_effect/reverie)
	TEST_ASSERT_NOTNULL(effect, "A lying Warforged should enter Reverie.")
	var/obj/item/bodypart/chest = construct.get_bodypart(BODY_ZONE_CHEST)
	chest.create_injury(WOUND_BLUNT, 20, TRUE)
	chest.post_damage_change()
	effect.tick()
	TEST_ASSERT(QDELETED(effect), "Fresh harm should end Reverie.")
	TEST_ASSERT(!construct.eyesclosed, "Being jolted out of Reverie should open the eyes.")

/datum/unit_test/reverie_needs_an_explicit_grant

/datum/unit_test/reverie_needs_an_explicit_grant/Run()
	var/mob/living/carbon/human/sleepless = allocate(/mob/living/carbon/human/species/human/northern)
	ADD_TRAIT(sleepless, TRAIT_NOSLEEP, "unit_test")
	sleepless.update_tod("night")
	TEST_ASSERT(!sleepless.has_status_effect(/datum/status_effect/debuff/dreamytime), "Sleeplessness alone should not offer a dream.")

	sleepless.grant_reverie("first", "Grave Vigil")
	sleepless.grant_reverie("second")
	sleepless.revoke_reverie("first")
	TEST_ASSERT(HAS_TRAIT(sleepless, TRAIT_REVERIE), "Reverie should stay while any source still grants it.")
	sleepless.revoke_reverie("second")
	TEST_ASSERT(!HAS_TRAIT(sleepless, TRAIT_REVERIE), "Reverie should go when the last source is revoked.")
	TEST_ASSERT_NULL(sleepless.GetComponent(/datum/component/reverie), "The Reverie component should delete itself with no sources.")

/datum/unit_test/construct_material_repair

/datum/unit_test/construct_material_repair/Run()
	var/mob/living/carbon/human/construct = allocate(/mob/living/carbon/human/species/construct)
	var/datum/component/easy_repair/repair = construct.GetComponent(/datum/component/easy_repair)
	TEST_ASSERT_NOTNULL(repair, "Warforged should be repairable.")
	var/obj/item/bodypart/arm = construct.get_bodypart(BODY_ZONE_R_ARM)
	arm.create_injury(WOUND_BLUNT, 30, TRUE)
	arm.post_damage_change()
	var/damage_before = arm.get_damage()
	TEST_ASSERT(damage_before > 0, "The test dent should damage the arm.")

	var/list/fiber_stats = repair.get_material_stats(allocate(/obj/item/natural/fibers))
	TEST_ASSERT_NOTNULL(fiber_stats, "Fibers should be a repair material.")
	TEST_ASSERT_EQUAL(repair.mend_part(arm, fiber_stats[1], fiber_stats[2]), 0, "Fibers should be too flimsy for a deep dent.")

	var/list/cloth_stats = repair.get_material_stats(allocate(/obj/item/natural/cloth))
	var/list/bundle_stats = repair.get_material_stats(allocate(/obj/item/natural/bundle/cloth))
	TEST_ASSERT_EQUAL(bundle_stats, cloth_stats, "A cloth bundle should repair like cloth.")

	var/list/iron_stats = repair.get_material_stats(allocate(/obj/item/ingot/iron))
	var/list/steel_stats = repair.get_material_stats(allocate(/obj/item/ingot/steel))
	TEST_ASSERT(steel_stats[1] > cloth_stats[1], "Steel should mend more than cloth.")
	TEST_ASSERT(repair.mend_part(arm, iron_stats[1], iron_stats[2]) > 0, "Iron should mend a deep dent.")
	TEST_ASSERT(arm.get_damage() < damage_before, "Mending should lower the limb's damage.")

/datum/unit_test/automaton_regrown_limb_is_robotic

/datum/unit_test/automaton_regrown_limb_is_robotic/Run()
	var/mob/living/carbon/human/construct = allocate(/mob/living/carbon/human/species/construct)
	var/obj/item/bodypart/old_arm = construct.get_bodypart(BODY_ZONE_L_ARM)
	old_arm.drop_limb()
	qdel(old_arm)
	var/obj/item/bodypart/new_arm = construct.regenerate_limb(BODY_ZONE_L_ARM)
	TEST_ASSERT_NOTNULL(new_arm, "The arm should regrow.")
	TEST_ASSERT_EQUAL(new_arm.status, BODYPART_ROBOTIC, "A regrown construct limb should be robotic.")

/datum/unit_test/automaton_sheds_reagents

/datum/unit_test/automaton_sheds_reagents/Run()
	var/mob/living/carbon/human/construct = allocate(/mob/living/carbon/human/species/construct)
	construct.reagents.add_reagent(/datum/reagent/water, 10)
	construct.dna.species.spec_life(construct)
	TEST_ASSERT(construct.reagents.total_volume < 10, "Constructs should shed reagents they cannot metabolize.")

/datum/unit_test/bloodless_bodies_lose_no_blood

/datum/unit_test/bloodless_bodies_lose_no_blood/Run()
	var/mob/living/carbon/human/doll = allocate(/mob/living/carbon/human/species/doll)
	TEST_ASSERT(doll.is_bloodless(), "Dolls should count as bloodless.")
	var/start_volume = doll.blood_volume
	doll.adjust_bloodvolume(-300)
	var/obj/item/bodypart/arm = doll.get_bodypart(BODY_ZONE_R_ARM)
	arm.create_injury(WOUND_BURN, 30)
	TEST_ASSERT_EQUAL(doll.blood_volume, start_volume, "A bloodless body should not lose blood to drains or burns.")

	doll.blood_volume = 0
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human/species/human/northern)
	var/list/examine_text = doll.examine(viewer)
	var/shows_paleness = FALSE
	for(var/line in examine_text)
		if(findtext("[line]", "pale and sickly"))
			shows_paleness = TRUE
	TEST_ASSERT(!shows_paleness, "A bloodless body should never be described as pale from blood loss.")

	var/mob/living/carbon/human/bleeder = allocate(/mob/living/carbon/human/species/human/northern)
	var/bleeder_volume = bleeder.blood_volume
	bleeder.adjust_bloodvolume(-300)
	TEST_ASSERT_EQUAL(bleeder.blood_volume, bleeder_volume - 300, "A body with blood should still lose it.")

/datum/unit_test/defeat_warning_repeats_only_on_fresh_harm

/datum/unit_test/defeat_warning_repeats_only_on_fresh_harm/Run()
	var/mob/living/carbon/human/doll = allocate(/mob/living/carbon/human/species/doll)
	var/datum/component/defeat_monitor/monitor = doll.AddComponent(/datum/component/defeat_monitor)
	TEST_ASSERT_NOTNULL(monitor, "The defeat monitor should attach.")
	TEST_ASSERT(monitor.maybe_warn_damage_defeat(doll, 150, 200), "Entering the near-defeat band should warn.")
	monitor.damage_warning_last_at = 0
	TEST_ASSERT(!monitor.maybe_warn_damage_defeat(doll, 150, 200), "Unchanged damage should not warn again.")
	TEST_ASSERT(monitor.maybe_warn_damage_defeat(doll, 160, 200), "Fresh harm should warn again.")
	monitor.damage_warning_last_at = 0
	TEST_ASSERT(!monitor.maybe_warn_damage_defeat(doll, 155, 200), "Healing should not warn.")
	TEST_ASSERT(!monitor.maybe_warn_damage_defeat(doll, 50, 200), "Leaving the band should not warn.")
	TEST_ASSERT(monitor.maybe_warn_damage_defeat(doll, 150, 200), "Coming back into the band should warn again.")

/datum/unit_test/doll_has_no_critical_weakness

/datum/unit_test/doll_has_no_critical_weakness/Run()
	var/mob/living/carbon/human/doll = allocate(/mob/living/carbon/human/species/doll)
	TEST_ASSERT(!HAS_TRAIT(doll, TRAIT_CRITICAL_WEAKNESS), "Dolls should not die outright from mortal wounds.")
	TEST_ASSERT(HAS_TRAIT(doll, TRAIT_REVERIE), "Dolls should rest in Reverie.")
