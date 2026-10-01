/// A test human with a cock and full balls; returns the penis.
/proc/give_spurt_test_genitals(mob/living/carbon/human/human, seed = 200)
	var/obj/item/organ/genitals/penis/penis = new
	penis.Insert(human, TRUE, FALSE)
	var/obj/item/organ/genitals/filling_organ/testicles/testicles = new
	testicles.Insert(human, TRUE, FALSE)
	testicles.reagents.maximum_volume = max(testicles.reagents.maximum_volume, seed)
	testicles.reagents.clear_reagents()
	testicles.reagents.add_reagent(/datum/reagent/consumable/cum, seed)
	return penis

/proc/get_spurt_test_coat(mob/living/carbon/human/human, zone)
	var/datum/component/fluid_coated/coated = human.GetComponent(/datum/component/fluid_coated)
	var/datum/fluid_coat/coat = coated?.coats[zone]
	return coat?.fluids?.total_volume || 0

/datum/unit_test/climax_spurt_amounts_follow_the_load/Run()
	TEST_ASSERT_EQUAL(length(get_climax_spurt_amounts(CLIMAX_SPURT_TWO_UNITS - 1)), 1, "A small load should come in one spurt.")
	TEST_ASSERT_EQUAL(length(get_climax_spurt_amounts(CLIMAX_SPURT_THREE_UNITS)), 2, "A middling load should come in two spurts.")
	var/list/big = get_climax_spurt_amounts(CLIMAX_SPURT_THREE_UNITS + 15)
	TEST_ASSERT_EQUAL(length(big), 3, "A big load should come in three spurts.")
	TEST_ASSERT(abs(big[1] + big[2] + big[3] - (CLIMAX_SPURT_THREE_UNITS + 15)) < 0.01, "The spurts should add up to the load.")
	TEST_ASSERT(big[1] > big[2] && big[2] > big[3], "Each spurt should be weaker than the last.")

/datum/unit_test/climax_spurts_drift_or_follow_the_aim/Run()
	var/mob/living/carbon/human/climaxer = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human)
	give_spurt_test_genitals(climaxer)
	var/datum/component/arousal/arousal = climaxer.LoadComponent(/datum/component/arousal)

	TEST_ASSERT(arousal.spurt_onto(partner, FLUID_COAT_FACE, 40), "An unaimed climax onto someone should spurt.")
	TEST_ASSERT(get_spurt_test_coat(partner, FLUID_COAT_FACE) > 0, "The first spurt should land where it starts.")
	TEST_ASSERT_NOTNULL(arousal.active_spurts, "More spurts should be on the way.")
	arousal.active_spurts.pulse()
	TEST_ASSERT(get_spurt_test_coat(partner, FLUID_COAT_CHEST) > 0, "Without a new aim, the next spurt should drift down to the chest.")
	arousal.active_spurts.pulse()
	TEST_ASSERT(get_spurt_test_coat(partner, FLUID_COAT_BELLY) > 0, "The last spurt should drift on to the belly.")
	TEST_ASSERT_NULL(arousal.active_spurts, "The climax should end after its last spurt.")

	climaxer.zone_selected = BODY_ZONE_PRECISE_GROIN
	climaxer.try_grip_penis(climaxer)
	var/obj/item/organ/genitals/penis/penis = climaxer.getorganslot(ORGAN_SLOT_PENIS)
	var/obj/item/penis_grip/grip = penis.grip
	climaxer.zone_selected = BODY_ZONE_PRECISE_L_FOOT
	grip.aim_at(partner, climaxer)
	var/obj/item/organ/genitals/filling_organ/testicles/testicles = climaxer.getorganslot(ORGAN_SLOT_TESTICLES)
	testicles.reagents.add_reagent(/datum/reagent/consumable/cum, 100)
	var/runtimed = FALSE
	try
		arousal.ejaculate()
	catch
		runtimed = TRUE
	TEST_ASSERT(!runtimed, "An aimed spurting climax should not runtime.")
	TEST_ASSERT(get_spurt_test_coat(partner, FLUID_COAT_FEET) > 0, "The first spurt should hit the feet.")
	var/obj/item/reagent_containers/glass/bucket/bucket = allocate(/obj/item/reagent_containers/glass/bucket)
	grip.aim_at(bucket, climaxer)
	arousal.active_spurts?.pulse()
	TEST_ASSERT(bucket.reagents.get_reagent_amount(/datum/reagent/consumable/cum) > 0, "Re-aiming between spurts should send the next one to the new spot.")
	var/mob/living/carbon/human/third = allocate(/mob/living/carbon/human)
	climaxer.zone_selected = BODY_ZONE_HEAD
	grip.aim_at(third, climaxer)
	arousal.active_spurts?.pulse()
	TEST_ASSERT(get_spurt_test_coat(third, FLUID_COAT_FACE) > 0, "A spurt aimed afresh should land right where aimed, without drifting.")
	qdel(arousal.active_spurts)

/datum/unit_test/climax_edge_squeeze_holds_back_or_ruins/Run()
	var/mob/living/carbon/human/owner = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/penis/penis = give_spurt_test_genitals(owner)
	var/datum/component/arousal/arousal = owner.LoadComponent(/datum/component/arousal)
	owner.zone_selected = BODY_ZONE_PRECISE_GROIN
	owner.try_grip_penis(owner)
	var/obj/item/penis_grip/grip = penis.grip

	SEND_SIGNAL(owner, COMSIG_SEX_SET_ORGASM_PROG, 90)
	TEST_ASSERT(grip.squeeze(owner), "A squeeze should land.")
	TEST_ASSERT(arousal.orgasm_progress < 90, "A squeeze should pull the climax back.")
	TEST_ASSERT(arousal.edging_charge > 0, "A squeeze should build edging.")
	TEST_ASSERT(!grip.squeeze(owner), "Squeezes should have a cooldown.")

	COOLDOWN_RESET(grip, squeeze_cooldown)
	arousal.spurt_onto(partner, FLUID_COAT_CHEST, 40)
	var/datum/climax_spurts/spurts = arousal.active_spurts
	TEST_ASSERT_NOTNULL(spurts, "The climax should still be spurting.")
	grip.squeeze(owner)
	TEST_ASSERT(QDELETED(spurts), "A squeeze mid-climax should choke off the rest.")
	TEST_ASSERT_NULL(arousal.active_spurts, "No spurts should be left.")
	TEST_ASSERT_NOTNULL(owner.has_stress_type(/datum/stress_event/ruined_orgasm), "A ruined climax should sour the mood.")
	TEST_ASSERT(arousal.arousal >= RUINED_ORGASM_AROUSAL, "A ruined climax should leave arousal high.")
	TEST_ASSERT_EQUAL(get_spurt_test_coat(partner, FLUID_COAT_BELLY), 0, "The choked spurts should never land.")

/datum/unit_test/climax_aim_warns_its_target/Run()
	var/mob/living/carbon/human/owner = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/penis/penis = give_spurt_test_genitals(owner)
	var/datum/climax_aim/aim = penis.get_climax_aim()
	aim.set_target(partner, FLUID_COAT_FACE, owner)
	TEST_ASSERT_NOTNULL(partner.alerts["cock_aimed"], "The target should see an alert while aimed at.")
	aim.clear()
	TEST_ASSERT_NULL(partner.alerts["cock_aimed"], "The alert should go when the aim does.")

/datum/unit_test/climax_aim_respects_logged_off_players/Run()
	var/mob/living/carbon/human/owner = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/penis/penis = give_spurt_test_genitals(owner)
	var/datum/climax_aim/aim = penis.get_climax_aim()
	aim.set_target(partner, FLUID_COAT_FACE, owner)
	TEST_ASSERT_EQUAL(aim.get_valid_target(), partner, "A clientless body with no player should be a valid aim.")

	partner.mind_initialize()
	partner.mind.key = "unit_test_partner"
	TEST_ASSERT_NULL(aim.get_valid_target(), "A logged-off player who does not allow it should not be hit.")
	partner.set_cached_erp_preferences(list(/datum/erp_preference/boolean/allow_player_erp_when_disconnected = TRUE))
	TEST_ASSERT_EQUAL(aim.get_valid_target(), partner, "A logged-off player who allows it should still be a valid aim.")

	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human)
	holder.zone_selected = BODY_ZONE_PRECISE_GROIN
	holder.try_grip_penis(owner)
	var/obj/item/penis_grip/grip = penis.grip
	TEST_ASSERT(grip?.is_hold_valid(), "The hold should start out valid.")
	owner.mind_initialize()
	owner.mind.key = "unit_test_owner"
	TEST_ASSERT(!grip.is_hold_valid(), "The hand should let go of a player who logs off without allowing it.")

/datum/unit_test/npc_jerk_over_aims_for_the_horny_ai/Run()
	var/mob/living/carbon/human/npc = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/penis/penis = give_spurt_test_genitals(npc)
	var/datum/component/arousal/arousal = npc.LoadComponent(/datum/component/arousal)
	var/list/choices = list()
	add_local_horny_ai_actions(choices, npc, target)
	TEST_ASSERT(/datum/sex_action/npc/npc_jerk_over in choices, "The horny AI should be able to pick jerking off over someone.")

	var/datum/sex_scene_controller/controller = npc.open_sex_scene(target, FALSE)
	var/datum/sex_action/npc/npc_jerk_over/action = controller.instantiate_action(/datum/sex_action/npc/npc_jerk_over)
	TEST_ASSERT(action.bind_runtime(controller), "The NPC action should bind.")
	action.on_start(npc, target)
	TEST_ASSERT_EQUAL(penis.climax_aim?.target, target, "The NPC should aim at its target.")
	TEST_ASSERT(penis.climax_aim.zone in list(FLUID_COAT_FACE, FLUID_COAT_CHEST, FLUID_COAT_BELLY, PENIS_AIM_MOUTH), "The NPC should aim high on the body.")
	TEST_ASSERT_EQUAL(arousal.get_steering_aim(action), penis.climax_aim, "The NPC's aim should steer its climax.")
	npc.sex_scene.stop_action(action)
	TEST_ASSERT_NULL(penis.climax_aim.target, "Stopping should drop the NPC's aim.")
