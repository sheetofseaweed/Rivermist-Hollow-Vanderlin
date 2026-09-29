/// Gives a test human a penis and full testicles; returns the penis.
/proc/give_penis_grip_test_genitals(mob/living/carbon/human/human)
	var/obj/item/organ/genitals/penis/penis = new
	penis.Insert(human, TRUE, FALSE)
	var/obj/item/organ/genitals/filling_organ/testicles/testicles = new
	testicles.Insert(human, TRUE, FALSE)
	refill_penis_grip_test_testicles(human)
	return penis

/proc/refill_penis_grip_test_testicles(mob/living/carbon/human/human)
	var/obj/item/organ/genitals/filling_organ/testicles/testicles = human.getorganslot(ORGAN_SLOT_TESTICLES)
	testicles.reagents.clear_reagents()
	testicles.reagents.add_reagent(/datum/reagent/consumable/cum, testicles.reagents.maximum_volume)

/// Climaxes without letting a runtime pass the test silently; TRUE when it ran clean.
/proc/penis_grip_test_climax(datum/component/arousal/arousal, datum/sex_action/action, mob/living/performer)
	try
		if(action)
			arousal.ejaculate(action, performer, performer, FALSE, performer)
		else
			arousal.ejaculate()
	catch
		return FALSE
	return TRUE

/datum/unit_test/penis_grip_intent_plates_exist/Run()
	for(var/intent_type in list(/datum/intent/penis_grip/aim, /datum/intent/penis_grip/slap))
		var/datum/intent/intent = new intent_type
		TEST_ASSERT(icon_exists(intent.hud_icon, intent.icon_state), "[intent_type] has no HUD plate '[intent.icon_state]' in [intent.hud_icon].")
		qdel(intent)
	var/datum/intent/stock = new /datum/intent
	TEST_ASSERT_EQUAL(stock.hud_icon, 'icons/mob/roguehud.dmi', "Stock intents should keep the stock HUD plates.")
	qdel(stock)

/datum/unit_test/penis_grip_help_click_takes_and_lets_go/Run()
	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/owner = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/penis/penis = give_penis_grip_test_genitals(owner)

	holder.zone_selected = BODY_ZONE_CHEST
	TEST_ASSERT(!holder.try_grip_penis(owner), "Only a hand on the groin should take hold.")
	holder.zone_selected = BODY_ZONE_PRECISE_GROIN
	owner.on_fire = TRUE
	TEST_ASSERT(!holder.try_grip_penis(owner), "Patting out a fire should win over taking hold.")
	owner.on_fire = FALSE
	TEST_ASSERT(holder.dna.species.help(holder, owner), "A help hand on the groin should take hold of the cock.")
	var/obj/item/penis_grip/grip = holder.get_active_held_item()
	TEST_ASSERT(istype(grip), "Taking hold should put a grip in the hand.")
	TEST_ASSERT_EQUAL(penis.grip, grip, "The cock should know its grip.")
	TEST_ASSERT_EQUAL(grip.owner, owner, "The grip should know whose cock it holds.")

	var/mob/living/carbon/human/rival = allocate(/mob/living/carbon/human)
	rival.zone_selected = BODY_ZONE_PRECISE_GROIN
	TEST_ASSERT(rival.try_grip_penis(owner), "A second hand should be told the cock is taken.")
	TEST_ASSERT_NULL(rival.get_active_held_item(), "Only one hand can hold a cock.")

	holder.dropItemToGround(grip)
	TEST_ASSERT(QDELETED(grip), "Letting go should delete the grip.")
	TEST_ASSERT_NULL(penis.grip, "Letting go should free the cock.")

	holder.try_grip_penis(owner)
	grip = penis.grip
	TEST_ASSERT_NOTNULL(grip, "The hand should take hold again.")
	owner.forceMove(locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	TEST_ASSERT(QDELETED(grip), "Walking out of reach should end the hold.")

	owner.zone_selected = BODY_ZONE_PRECISE_GROIN
	TEST_ASSERT(owner.try_grip_penis(owner), "Anyone should be able to take hold of their own cock.")
	TEST_ASSERT_EQUAL(penis.grip?.holder, owner, "The owner should hold their own cock.")

/datum/unit_test/penis_grip_aim_steers_the_climax/Run()
	var/mob/living/carbon/human/owner = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/penis/penis = give_penis_grip_test_genitals(owner)
	var/datum/component/arousal/arousal = owner.LoadComponent(/datum/component/arousal)
	owner.zone_selected = BODY_ZONE_PRECISE_GROIN
	owner.try_grip_penis(owner)
	var/obj/item/penis_grip/grip = penis.grip

	var/obj/item/reagent_containers/glass/bucket/bucket = allocate(/obj/item/reagent_containers/glass/bucket)
	TEST_ASSERT(grip.aim_at(bucket, owner), "An open bucket should be a valid aim.")
	TEST_ASSERT(penis_grip_test_climax(arousal), "A climax into a bucket should not runtime.")
	TEST_ASSERT(bucket.reagents.get_reagent_amount(/datum/reagent/consumable/cum) > 0, "The load should go into the aimed bucket.")

	bucket.reagents.clear_reagents()
	bucket.reagents.add_reagent(/datum/reagent/water, bucket.reagents.maximum_volume - 1)
	refill_penis_grip_test_testicles(owner)
	var/obj/item/organ/genitals/filling_organ/testicles/testicles = owner.getorganslot(ORGAN_SLOT_TESTICLES)
	var/before = testicles.reagents.total_volume
	TEST_ASSERT(penis_grip_test_climax(arousal), "An overflowing climax should not runtime.")
	TEST_ASSERT_EQUAL(bucket.reagents.total_volume, bucket.reagents.maximum_volume, "The bucket should fill to the brim.")
	TEST_ASSERT(before - testicles.reagents.total_volume > 1, "What does not fit should spill, not stay in the balls.")

	var/obj/item/clothing/shoes/heels/heels = allocate(/obj/item/clothing/shoes/heels)
	TEST_ASSERT(partner.equip_to_slot_if_possible(heels, ITEM_SLOT_SHOES, disable_warning = TRUE, bypass_equip_delay_self = TRUE), "The partner should wear the heels.")
	owner.zone_selected = BODY_ZONE_PRECISE_L_FOOT
	TEST_ASSERT(grip.aim_at(partner, owner), "Feet next to the owner should be a valid aim.")
	refill_penis_grip_test_testicles(owner)
	TEST_ASSERT(penis_grip_test_climax(arousal), "A climax into worn heels should not runtime.")
	TEST_ASSERT(heels.reagents.get_reagent_amount(/datum/reagent/consumable/cum) > 0, "Aiming at feet in heels should fill the heels.")

	owner.zone_selected = BODY_ZONE_PRECISE_MOUTH
	grip.aim_at(partner, owner)
	refill_penis_grip_test_testicles(owner)
	TEST_ASSERT(penis_grip_test_climax(arousal), "A climax into a mouth should not runtime.")
	var/obj/item/organ/stomach/stomach = partner.getorganslot(ORGAN_SLOT_STOMACH)
	var/swallowed = stomach?.reagents.get_reagent_amount(/datum/reagent/consumable/cum) + partner.reagents.get_reagent_amount(/datum/reagent/consumable/cum)
	TEST_ASSERT(swallowed > 0, "A shot into an open mouth should be swallowed.")
	var/datum/component/fluid_coated/coated = partner.GetComponent(/datum/component/fluid_coated)
	TEST_ASSERT_NOTNULL(coated?.coats[FLUID_COAT_FACE], "Some of a mouth shot should glaze the face.")

	owner.zone_selected = BODY_ZONE_CHEST
	partner.forceMove(locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	partner.setDir(EAST)
	grip.aim_at(partner, owner)
	TEST_ASSERT_EQUAL(grip.resolve_coat_zone(partner), FLUID_COAT_BACK, "A chest shot on someone facing away should land on the back.")
	partner.forceMove(get_turf(owner))
	partner.setDir(SOUTH)

	var/datum/sex_scene_controller/controller = owner.open_sex_scene(owner, FALSE)
	var/datum/sex_action/stroking = controller.instantiate_action(/datum/sex_action/masturbate/penis)
	TEST_ASSERT(stroking.bind_runtime(controller), "The jerk-off action should bind.")
	grip.aim_at(partner, owner)
	TEST_ASSERT_EQUAL(arousal.get_steering_grip(stroking), grip, "Jerking off should follow the grip's aim.")
	var/datum/sex_action/sex/vaginal/fucking = allocate(/datum/sex_action/sex/vaginal)
	TEST_ASSERT_NULL(arousal.get_steering_grip(fucking), "A climax inside someone should ignore the grip.")
	refill_penis_grip_test_testicles(owner)
	TEST_ASSERT(penis_grip_test_climax(arousal, stroking, owner), "A steered action climax should not runtime.")
	TEST_ASSERT(coated.coats[FLUID_COAT_CHEST], "Jerking off at the chest should coat it.")
	owner.sex_scene?.stop_action(stroking)

	grip = penis.grip
	grip.aim_at(bucket, owner)
	bucket.forceMove(locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	bucket.reagents.clear_reagents()
	refill_penis_grip_test_testicles(owner)
	TEST_ASSERT(penis_grip_test_climax(arousal), "A climax with a lost aim should not runtime.")
	TEST_ASSERT_EQUAL(bucket.reagents.total_volume, 0, "A bucket out of reach should stay empty.")
	TEST_ASSERT_NULL(grip.aim_target, "An aim out of reach should be dropped.")

/datum/unit_test/penis_grip_slap_knockback_follows_heft/Run()
	var/mob/living/carbon/human/owner = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/penis/penis = give_penis_grip_test_genitals(owner)
	penis.organ_size = MAX_PENIS_SIZE
	penis.erect_state = ERECT_STATE_HARD
	var/turf/victim_spot = locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/turf/landing = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	victim.forceMove(victim_spot)
	owner.zone_selected = BODY_ZONE_PRECISE_GROIN
	owner.try_grip_penis(owner)
	var/obj/item/penis_grip/grip = penis.grip

	TEST_ASSERT_EQUAL(grip.get_slap_heft(victim, 1), PENIS_SLAP_KNOCKBACK_HEFT, "A large hard cock at normal force should just knock back an equal body.")
	penis.organ_size = DEFAULT_PENIS_SIZE
	TEST_ASSERT(grip.get_slap_heft(victim, 1) < PENIS_SLAP_KNOCKBACK_HEFT, "An average cock at normal force should not knock back.")
	TEST_ASSERT(grip.get_slap_heft(victim, 1.5) >= PENIS_SLAP_KNOCKBACK_HEFT, "An average cock swung hard should knock back.")
	penis.erect_state = ERECT_STATE_NONE
	TEST_ASSERT(grip.get_slap_heft(victim, 1.5) < PENIS_SLAP_KNOCKBACK_HEFT, "A soft cock should not knock anyone back.")
	penis.erect_state = ERECT_STATE_HARD
	victim.extra_mob_weight = SEELIE_WEIGHT - HUMAN_WEIGHT
	TEST_ASSERT(grip.get_slap_heft(victim, 0.5) >= PENIS_SLAP_KNOCKBACK_HEFT, "Any slap should knock back a seelie-sized body.")
	victim.extra_mob_weight = 0

	// Real slaps change arousal, which sets the erection, so keep the owner properly hard.
	SEND_SIGNAL(owner, COMSIG_SEX_SET_AROUSAL, ACTIVE_EJAC_THRESHOLD)
	TEST_ASSERT_EQUAL(penis.erect_state, ERECT_STATE_HARD, "High arousal should make the cock hard.")
	penis.organ_size = MAX_PENIS_SIZE
	owner.zone_selected = BODY_ZONE_HEAD
	TEST_ASSERT(grip.slap(victim, owner), "The slap should land.")
	TEST_ASSERT_EQUAL(get_turf(victim), landing, "A heavy slap should knock the victim back a tile.")
	victim.forceMove(victim_spot)
	TEST_ASSERT(!grip.slap(victim, owner), "Slaps should have a cooldown.")

	COOLDOWN_RESET(grip, slap_cooldown)
	penis.organ_size = DEFAULT_PENIS_SIZE
	TEST_ASSERT(grip.slap(victim, owner), "A light slap should land too.")
	TEST_ASSERT_EQUAL(get_turf(victim), victim_spot, "A light slap should not move anyone.")

	COOLDOWN_RESET(grip, slap_cooldown)
	penis.organ_size = MAX_PENIS_SIZE
	var/obj/structure/blocker = allocate(/obj/structure/table/wood, landing)
	TEST_ASSERT(grip.get_slap_heft(victim, 1) >= PENIS_SLAP_KNOCKBACK_HEFT, "This slap should be heavy enough to knock back.")
	TEST_ASSERT(!grip.is_safe_landing(landing), "A table should make the landing unsafe.")
	grip.slap(victim, owner)
	TEST_ASSERT_EQUAL(get_turf(victim), victim_spot, "A blocked landing should only jolt the victim.")
	qdel(blocker)

	COOLDOWN_RESET(grip, slap_cooldown)
	owner.cmode = TRUE
	TEST_ASSERT(!grip.slap(victim, owner), "No cock slaps in combat mode.")
	owner.cmode = FALSE

/datum/unit_test/penis_grip_follows_the_stroking/Run()
	var/mob/living/carbon/human/owner = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/penis/penis = give_penis_grip_test_genitals(owner)
	var/datum/sex_scene_controller/controller = owner.open_sex_scene(owner, FALSE)
	var/datum/sex_action/stroking = controller.instantiate_action(/datum/sex_action/masturbate/penis)
	TEST_ASSERT(stroking.bind_runtime(controller), "The jerk-off action should bind.")
	stroking.on_start(owner, owner)
	var/obj/item/penis_grip/grip = penis.grip
	TEST_ASSERT_NOTNULL(grip, "Jerking off should put the cock in hand.")
	TEST_ASSERT(grip.made_by_action, "That grip should belong to the stroking.")
	TEST_ASSERT_EQUAL(grip.stroke_action, stroking, "The grip should know its stroking.")
	owner.sex_scene.stop_action(stroking)
	TEST_ASSERT(QDELETED(grip), "The hand should let go when the stroking stops.")

	stroking = controller.instantiate_action(/datum/sex_action/masturbate/penis)
	TEST_ASSERT(stroking.bind_runtime(controller), "The jerk-off action should bind again.")
	stroking.on_start(owner, owner)
	grip = penis.grip
	grip.attack_self(owner)
	TEST_ASSERT(QDELETED(stroking), "Using the grip in hand should stop the stroking.")
	TEST_ASSERT(!QDELETED(grip), "Stopping by hand should keep the hold, even when the stroking made it.")
	owner.dropItemToGround(grip)

	owner.zone_selected = BODY_ZONE_PRECISE_GROIN
	owner.try_grip_penis(owner)
	grip = penis.grip
	grip.attack_self(owner)
	stroking = grip.stroke_action
	TEST_ASSERT_NOTNULL(stroking, "Using the grip in hand should start stroking.")
	grip.attack_self(owner)
	TEST_ASSERT(QDELETED(stroking), "Using it again should stop the stroking.")
	TEST_ASSERT(!QDELETED(grip), "A hold taken by hand should stay after the stroking stops.")

	grip.attack_self(owner)
	stroking = grip.stroke_action
	TEST_ASSERT_NOTNULL(stroking, "The stroking should start again.")
	owner.dropItemToGround(grip)
	TEST_ASSERT(QDELETED(stroking), "Letting go should stop the stroking.")

	owner.try_grip_penis(owner)
	grip = penis.grip
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human)
	var/datum/sex_action/sex/vaginal/fucking = allocate(/datum/sex_action/sex/vaginal)
	TEST_ASSERT(ispath(fucking.stored_item_type, /obj/item/organ/genitals/penis), "Vaginal sex should put the penis inside.")
	fucking.sync_penis_grip(owner, partner)
	TEST_ASSERT(QDELETED(grip), "The hand should let go when the cock goes inside someone.")
