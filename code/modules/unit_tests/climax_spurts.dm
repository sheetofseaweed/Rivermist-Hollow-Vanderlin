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
	owner.add_stress(/datum/stress_event/cumok)
	grip.squeeze(owner)
	TEST_ASSERT(QDELETED(spurts), "A squeeze mid-climax should choke off the rest.")
	TEST_ASSERT_NULL(arousal.active_spurts, "No spurts should be left.")
	TEST_ASSERT_NOTNULL(owner.has_stress_type(/datum/stress_event/ruined_orgasm), "A ruined climax should sour the mood.")
	TEST_ASSERT_NULL(owner.has_stress_type(/datum/stress_event/cumok), "A ruined climax should bring no relief.")
	TEST_ASSERT(arousal.arousal >= RUINED_ORGASM_AROUSAL, "A ruined climax should leave arousal high.")
	TEST_ASSERT_EQUAL(get_spurt_test_coat(partner, FLUID_COAT_BELLY), 0, "The choked spurts should never land.")

/datum/unit_test/climax_spurts_outlive_the_stroking/Run()
	var/mob/living/carbon/human/owner = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/penis/penis = give_spurt_test_genitals(owner)
	var/datum/component/arousal/arousal = owner.LoadComponent(/datum/component/arousal)
	var/datum/sex_scene_controller/controller = owner.open_sex_scene(owner, FALSE)
	var/datum/sex_action/stroking = controller.instantiate_action(/datum/sex_action/masturbate/penis)
	TEST_ASSERT(stroking.bind_runtime(controller), "The jerk-off action should bind.")
	stroking.on_start(owner, owner)
	var/obj/item/penis_grip/grip = penis.grip
	TEST_ASSERT(grip?.made_by_action, "Jerking off should put a grip in hand.")
	owner.zone_selected = BODY_ZONE_HEAD
	TEST_ASSERT(grip.aim_at(partner, owner), "A face next to the owner should be a valid aim.")
	arousal.ejaculate()
	TEST_ASSERT(get_spurt_test_coat(partner, FLUID_COAT_FACE) > 0, "The first spurt should hit the face.")
	TEST_ASSERT_NOTNULL(arousal.active_spurts, "More spurts should be on the way.")
	// A climax ends the stroking, and with it the grip and its aim.
	owner.sex_scene.stop_action(stroking)
	TEST_ASSERT(QDELETED(grip), "The stroking's grip should let go when it stops.")
	arousal.active_spurts?.pulse()
	TEST_ASSERT(get_spurt_test_coat(partner, FLUID_COAT_CHEST) > 0, "The rest should drift down the body, not fall to the floor.")
	qdel(arousal.active_spurts)

	var/mob/living/carbon/human/npc = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/penis/npc_penis = give_spurt_test_genitals(npc)
	var/datum/component/arousal/npc_arousal = npc.LoadComponent(/datum/component/arousal)
	var/datum/sex_scene_controller/npc_controller = npc.open_sex_scene(target, FALSE)
	var/datum/sex_action/npc/npc_jerk_over/jerking = npc_controller.instantiate_action(/datum/sex_action/npc/npc_jerk_over)
	TEST_ASSERT(jerking.bind_runtime(npc_controller), "The NPC action should bind.")
	jerking.on_start(npc, target)
	npc_penis.get_climax_aim().set_target(target, FLUID_COAT_FACE, npc)
	npc_arousal.ejaculate()
	TEST_ASSERT_NOTNULL(npc_arousal.active_spurts, "The NPC should spurt more than once.")
	npc.sex_scene.stop_action(jerking)
	TEST_ASSERT_NULL(npc_penis.climax_aim.target, "Stopping should drop the NPC's aim.")
	npc_arousal.active_spurts?.pulse()
	TEST_ASSERT(get_spurt_test_coat(target, FLUID_COAT_CHEST) > 0, "The NPC's later spurts should still land on its target.")
	qdel(npc_arousal.active_spurts)

/datum/unit_test/climax_spurts_pump_inside_then_spill_on_pull_out/Run()
	var/mob/living/carbon/human/climaxer = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human)
	give_spurt_test_genitals(climaxer)
	var/datum/component/arousal/arousal = climaxer.LoadComponent(/datum/component/arousal)
	var/obj/item/organ/genitals/filling_organ/testicles/testicles = climaxer.getorganslot(ORGAN_SLOT_TESTICLES)
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = allocate(/obj/item/organ/genitals/filling_organ/vagina)
	vagina.Insert(partner, TRUE, TRUE)
	vagina.reagents.maximum_volume = 200
	vagina.reagents.clear_reagents()
	var/datum/sex_scene_controller/controller = climaxer.open_sex_scene(partner, FALSE)
	var/datum/sex_action/fucking = controller.instantiate_action(/datum/sex_action/sex/vaginal)
	TEST_ASSERT(fucking.bind_runtime(controller), "The vaginal action should bind.")

	// A small hole still takes the whole load: what does not fit overflows instead of staying in the balls.
	var/mob/living/carbon/human/first_partner = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/vagina/small_vagina = allocate(/obj/item/organ/genitals/filling_organ/vagina)
	small_vagina.Insert(first_partner, TRUE, TRUE)
	small_vagina.reagents.clear_reagents()
	small_vagina.reagents.maximum_volume = 20
	var/full_balls = testicles.reagents.total_volume
	arousal.handle_climax(fucking, ORGASM_LOCATION_INTO, climaxer, first_partner, FALSE, climaxer, first_partner, climaxer)
	TEST_ASSERT_NOTNULL(arousal.active_spurts, "A climax inside should come in spurts.")
	arousal.active_spurts.finish_now()
	TEST_ASSERT(full_balls - testicles.reagents.total_volume > 30, "A climax into a small hole should still empty the whole load.")
	testicles.reagents.add_reagent(/datum/reagent/consumable/cum, testicles.reagents.maximum_volume)
	fucking.stop_requested = FALSE
	fucking.just_climaxed = FALSE

	// A climax set to stop the action waits for its last spurt, so stopping meanwhile is a pull-out.
	fucking.stop_on_climax = TRUE
	arousal.begin_spurts(new /datum/climax_spurts/inside(arousal, 40, fucking, climaxer, partner, climaxer, partner, vagina))
	var/first = vagina.reagents.get_reagent_amount(/datum/reagent/consumable/cum)
	TEST_ASSERT(first > 0 && first < 40, "The first spurt should pump in only part of the load.")
	fucking.on_action_user_climax(climaxer, fucking)
	TEST_ASSERT(fucking.stop_after_spurts && !fucking.stop_requested, "The action should keep going until the spurts end.")
	arousal.active_spurts?.finish_now()
	TEST_ASSERT(vagina.reagents.get_reagent_amount(/datum/reagent/consumable/cum) > first, "Later spurts should pump inside while the action runs.")
	TEST_ASSERT(fucking.stop_requested, "The action should stop once the last spurt is done.")
	fucking.unbind_runtime()
	fucking.stop_requested = FALSE
	fucking.just_climaxed = FALSE

	TEST_ASSERT(fucking.bind_runtime(controller), "The vaginal action should bind again.")
	arousal.begin_spurts(new /datum/climax_spurts/inside(arousal, 40, fucking, climaxer, partner, climaxer, partner, vagina))
	var/inside_before_pull_out = vagina.reagents.get_reagent_amount(/datum/reagent/consumable/cum)
	fucking.unbind_runtime()
	arousal.active_spurts?.pulse()
	TEST_ASSERT_EQUAL(vagina.reagents.get_reagent_amount(/datum/reagent/consumable/cum), inside_before_pull_out, "Nothing more should go inside after a pull-out.")
	TEST_ASSERT(get_spurt_test_coat(partner, FLUID_COAT_GROIN) > 0, "After a pull-out the rest should land on the partner.")
	arousal.active_spurts?.finish_now()

	// A full hole takes what fits; the rest overflows down the thighs instead of staying in the balls.
	TEST_ASSERT(fucking.bind_runtime(controller), "The vaginal action should bind a third time.")
	vagina.reagents.clear_reagents()
	vagina.reagents.maximum_volume = 5
	testicles.reagents.add_reagent(/datum/reagent/consumable/cum, testicles.reagents.maximum_volume)
	var/balls_before = testicles.reagents.total_volume
	arousal.begin_spurts(new /datum/climax_spurts/inside(arousal, 40, fucking, climaxer, partner, climaxer, partner, vagina))
	arousal.active_spurts?.finish_now()
	TEST_ASSERT(vagina.reagents.total_volume <= 5, "A hole should never take more than it holds.")
	TEST_ASSERT(get_spurt_test_coat(partner, FLUID_COAT_THIGHS) > 0, "What does not fit should run down the thighs.")
	TEST_ASSERT(balls_before - testicles.reagents.total_volume > 30, "The whole load should leave the balls even when the hole is full.")
	fucking.unbind_runtime()
	qdel(fucking)

	var/mob/living/carbon/human/sucker = allocate(/mob/living/carbon/human)
	sucker.reagents.clear_reagents()
	var/datum/sex_scene_controller/oral_controller = climaxer.open_sex_scene(sucker, FALSE)
	var/datum/sex_action/blowjob = oral_controller.instantiate_action(/datum/sex_action/blowjob)
	TEST_ASSERT(blowjob.bind_runtime(oral_controller), "The blowjob should bind.")
	arousal.begin_spurts(new /datum/climax_spurts/inside/oral(arousal, 40, blowjob, climaxer, sucker, climaxer, sucker))
	var/obj/item/organ/stomach/stomach = sucker.getorganslot(ORGAN_SLOT_STOMACH)
	var/swallowed = stomach?.reagents.get_reagent_amount(/datum/reagent/consumable/cum) + sucker.reagents.get_reagent_amount(/datum/reagent/consumable/cum)
	TEST_ASSERT(swallowed > 0, "The first oral spurt should be swallowed.")
	blowjob.unbind_runtime()
	arousal.active_spurts?.pulse()
	TEST_ASSERT(get_spurt_test_coat(sucker, FLUID_COAT_FACE) > 0, "A mouth that pulls away should catch the rest on the face.")
	arousal.active_spurts?.finish_now()
	qdel(blowjob)

/datum/unit_test/climax_spurts_follow_position_and_choice/Run()
	var/mob/living/carbon/human/penetrator = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/receiver = allocate(/mob/living/carbon/human)
	give_spurt_test_genitals(penetrator)
	give_spurt_test_genitals(receiver)
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = allocate(/obj/item/organ/genitals/filling_organ/vagina)
	vagina.Insert(receiver, TRUE, TRUE)
	vagina.reagents.clear_reagents()
	var/datum/component/arousal/penetrator_arousal = penetrator.LoadComponent(/datum/component/arousal)
	var/datum/component/arousal/receiver_arousal = receiver.LoadComponent(/datum/component/arousal)
	var/datum/sex_scene_controller/controller = penetrator.open_sex_scene(receiver, FALSE)
	var/datum/sex_action/fucking = controller.instantiate_action(/datum/sex_action/sex/vaginal)
	TEST_ASSERT(fucking.bind_runtime(controller), "The vaginal action should bind.")

	// Set to finish outside, the penetrator pulls out and lands on the partner.
	controller.finish_outside = TRUE
	penetrator_arousal.ejaculate(fucking, penetrator, receiver, TRUE, penetrator)
	penetrator_arousal.active_spurts?.finish_now()
	TEST_ASSERT_EQUAL(vagina.reagents.get_reagent_amount(/datum/reagent/consumable/cum), 0, "Finishing outside should put nothing inside.")
	TEST_ASSERT(get_spurt_test_coat(receiver, FLUID_COAT_BELLY) > 0, "Finishing outside should land on the partner's belly.")
	controller.finish_outside = FALSE

	// Lying under the penetrator, the receiver's cock spurts over their own body.
	receiver.set_body_position(LYING_DOWN)
	receiver_arousal.handle_climax(fucking, ORGASM_LOCATION_ONTO, receiver, penetrator, FALSE, receiver, penetrator, receiver)
	receiver_arousal.active_spurts?.finish_now()
	TEST_ASSERT(get_spurt_test_coat(receiver, FLUID_COAT_CHEST) > 0, "A lying receiver should spurt over their own chest.")
	TEST_ASSERT_EQUAL(get_spurt_test_coat(penetrator, FLUID_COAT_BELLY), 0, "A lying receiver should not spurt over the one inside them.")
	receiver.set_body_position(STANDING_UP)
	receiver.set_lying_angle(0)
	receiver_arousal.handle_climax(fucking, ORGASM_LOCATION_ONTO, receiver, penetrator, FALSE, receiver, penetrator, receiver)
	receiver_arousal.active_spurts?.finish_now()
	TEST_ASSERT(get_spurt_test_coat(penetrator, FLUID_COAT_BELLY) > 0, "A standing receiver should still spurt over their partner.")
	fucking.unbind_runtime()
	qdel(fucking)

/datum/unit_test/climax_pull_outs_can_fail/Run()
	var/mob/living/carbon/human/penetrator = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/receiver = allocate(/mob/living/carbon/human)
	give_spurt_test_genitals(penetrator)
	var/datum/component/arousal/arousal = penetrator.LoadComponent(/datum/component/arousal)
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = allocate(/obj/item/organ/genitals/filling_organ/vagina)
	vagina.Insert(receiver, TRUE, TRUE)
	vagina.reagents.maximum_volume = 200
	vagina.reagents.clear_reagents()
	var/datum/sex_scene_controller/controller = penetrator.open_sex_scene(receiver, FALSE)
	var/datum/sex_action/fucking = controller.instantiate_action(/datum/sex_action/sex/vaginal)
	TEST_ASSERT(fucking.bind_runtime(controller), "The vaginal action should bind.")

	SEND_SIGNAL(penetrator, COMSIG_SEX_SET_AROUSAL, 0)
	TEST_ASSERT_EQUAL(get_pull_out_fail_chance(penetrator, receiver), 0, "A calm pull-out should never fail.")
	SEND_SIGNAL(penetrator, COMSIG_SEX_SET_AROUSAL, MAX_AROUSAL * 0.8)
	TEST_ASSERT(abs(get_pull_out_fail_chance(penetrator, receiver) - (PULL_OUT_FAIL_MIN_CHANCE + PULL_OUT_FAIL_MAX_CHANCE) / 2) < 0.01, "Arousal half way above the line should give a middling chance.")
	SEND_SIGNAL(penetrator, COMSIG_SEX_SET_AROUSAL, MAX_AROUSAL)
	TEST_ASSERT_EQUAL(get_pull_out_fail_chance(penetrator, receiver), PULL_OUT_FAIL_MAX_CHANCE, "Full arousal should give the highest chance.")

	TEST_ASSERT((penetrator in receiver.get_hole_penetrators()), "The receiver should know who is inside them.")
	var/datum/sex_scene_controller/receiver_controller = receiver.open_sex_scene(penetrator, FALSE)
	TEST_ASSERT(!receiver_controller.ui_data(receiver)["controls"]["can_leg_lock"], "A standing receiver should not see the leg lock.")
	receiver.set_body_position(LYING_DOWN)
	TEST_ASSERT(receiver_controller.ui_data(receiver)["controls"]["can_leg_lock"], "A lying receiver should see the leg lock.")
	receiver_controller.toggle_leg_lock()
	TEST_ASSERT(receiver_controller.leg_lock, "The leg lock should switch on.")
	TEST_ASSERT(!receiver.leg_locks_harder(penetrator), "Legs no stronger than the one inside should not hold them.")
	receiver.set_stat_modifier("unit_test", STATKEY_STR, 5)
	TEST_ASSERT(receiver.leg_locks_harder(penetrator), "Stronger legs should hold them in.")
	TEST_ASSERT_EQUAL(get_pull_out_fail_chance(penetrator, receiver), min(PULL_OUT_FAIL_MAX_CHANCE + LEG_LOCK_PULL_OUT_FAIL_CHANCE, PULL_OUT_FAIL_MAX_TOTAL), "A stronger leg lock should add a lot to the chance.")

	// A failed pull-out mid-climax keeps the rest inside.
	arousal.begin_spurts(new /datum/climax_spurts/inside(arousal, 40, fucking, penetrator, receiver, penetrator, receiver, vagina))
	var/datum/climax_spurts/inside/spurts = arousal.active_spurts
	spurts.pull_out_fail_chance = 100
	var/inside_before = vagina.reagents.total_volume
	fucking.unbind_runtime()
	spurts.pulse()
	TEST_ASSERT(vagina.reagents.total_volume > inside_before, "A failed pull-out should keep pumping inside.")
	TEST_ASSERT_EQUAL(get_spurt_test_coat(receiver, FLUID_COAT_GROIN), 0, "A failed pull-out should land nothing outside.")
	arousal.active_spurts?.finish_now()
	receiver.set_body_position(STANDING_UP)
	receiver.set_lying_angle(0)
	qdel(fucking)

/datum/unit_test/climax_spurts_feed_a_succubus_once/Run()
	var/mob/living/carbon/human/climaxer = allocate(/mob/living/carbon/human)
	climaxer.mind_initialize()
	give_spurt_test_genitals(climaxer)
	var/datum/component/arousal/arousal = climaxer.LoadComponent(/datum/component/arousal)
	var/mob/living/carbon/human/succubus = allocate(/mob/living/carbon/human)
	succubus.mind_initialize()
	var/datum/antagonist/succubus/antag = allocate(/datum/antagonist/succubus)
	antag.owner = succubus.mind
	antag.essence_cap = 100000
	LAZYADD(succubus.mind.antag_datums, antag)

	TEST_ASSERT(arousal.spurt_onto(succubus, FLUID_COAT_CHEST, 40), "A climax onto the succubus should spurt.")
	TEST_ASSERT_EQUAL(antag.partner_harvests[climaxer.mind], 1, "The first spurt should feed the succubus.")
	// The same-tick guard would hide a repeat here, so clear it.
	antag.last_harvest_time = -1
	arousal.active_spurts?.finish_now()
	TEST_ASSERT_EQUAL(antag.partner_harvests[climaxer.mind], 1, "Later spurts of one climax should not feed her again.")

	succubus.mind.antag_datums -= antag
	antag.owner = null

/datum/unit_test/climax_aim_warns_its_target/Run()
	var/mob/living/carbon/human/owner = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/penis/penis = give_spurt_test_genitals(owner)
	var/datum/climax_aim/aim = penis.get_climax_aim()
	aim.set_target(partner, FLUID_COAT_FACE, owner)
	TEST_ASSERT_NOTNULL(partner.alerts[aim.get_alert_category()], "The target should see an alert while aimed at.")

	var/mob/living/carbon/human/rival = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/penis/rival_penis = give_spurt_test_genitals(rival)
	var/datum/climax_aim/rival_aim = rival_penis.get_climax_aim()
	rival_aim.set_target(partner, FLUID_COAT_CHEST, rival)
	aim.clear()
	TEST_ASSERT_NULL(partner.alerts[aim.get_alert_category()], "The alert should go when the aim does.")
	TEST_ASSERT_NOTNULL(partner.alerts[rival_aim.get_alert_category()], "A second aim on the same body should keep its own alert.")

	partner.forceMove(locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	TEST_ASSERT_NULL(rival_aim.target, "Walking out of reach should drop the aim at once.")
	TEST_ASSERT_NULL(partner.alerts[rival_aim.get_alert_category()], "Walking out of reach should drop the alert too.")

	partner.forceMove(get_turf(owner))
	aim.set_target(partner, FLUID_COAT_FACE, owner)
	owner.forceMove(locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	TEST_ASSERT_NULL(aim.target, "The owner walking away should drop the aim too.")

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
