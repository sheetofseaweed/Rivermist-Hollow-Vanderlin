/datum/unit_test/defeat_preferences_defaults_and_sanitize

/datum/unit_test/defeat_preferences_defaults_and_sanitize/Run()
	var/datum/preferences/prefs = allocate(/datum/preferences)

	TEST_ASSERT_EQUAL(prefs.get_defeat_mode(), DEFEAT_MODE_KO_RUNE, "Defeat mode should default to knockout plus rune.")
	TEST_ASSERT_EQUAL(prefs.get_defeat_damage_threshold(), DEFEAT_DAMAGE_THRESHOLD_DEFAULT, "Defeat damage threshold should default to the conservative baseline.")

	prefs.set_defeat_mode(DEFEAT_MODE_NO_RETURN)
	TEST_ASSERT_EQUAL(prefs.get_defeat_mode(), DEFEAT_MODE_NO_RETURN, "No Return must be a valid explicit opt-out.")

	prefs.set_defeat_mode("bad-mode")
	TEST_ASSERT_EQUAL(prefs.get_defeat_mode(), DEFEAT_MODE_KO_RUNE, "Invalid defeat modes should sanitize back to the default.")

	prefs.set_defeat_damage_threshold(250)
	TEST_ASSERT_EQUAL(prefs.get_defeat_damage_threshold(), 250, "Listed threshold choices should be accepted.")

	prefs.set_defeat_damage_threshold(999)
	TEST_ASSERT_EQUAL(prefs.get_defeat_damage_threshold(), DEFEAT_DAMAGE_THRESHOLD_DEFAULT, "Unlisted threshold choices should sanitize back to the default.")

/datum/unit_test/defeat_monitor_eligibility_respects_player_and_opt_in_ai

/datum/unit_test/defeat_monitor_eligibility_respects_player_and_opt_in_ai/Run()
	var/mob/living/carbon/human/test_human = allocate(/mob/living/carbon/human)
	var/datum/component/defeat_monitor/monitor = test_human.AddComponent(/datum/component/defeat_monitor)

	TEST_ASSERT(!monitor.is_defeat_eligible(), "Clientless, mindless humans should not be defeat-monitored by default.")

	test_human.defeat_system_ai_opt_in = TRUE
	TEST_ASSERT(monitor.is_defeat_eligible(), "Explicit opt-in bodies should be eligible even without a player client.")

	test_human.defeat_system_ai_opt_in = FALSE
	test_human.mind = allocate(/datum/mind, "defeat-test-mind")
	test_human.mind.current = test_human
	TEST_ASSERT(monitor.is_defeat_eligible(), "Player minds should be eligible for defeat monitoring.")
	test_human.mind.current = null
	test_human.mind = null

/datum/unit_test/defeat_snapshot_records_damage_and_worst_injury

/datum/unit_test/defeat_snapshot_records_damage_and_worst_injury/Run()
	var/mob/living/carbon/human/test_human = allocate(/mob/living/carbon/human)
	test_human.setToxLoss(200, FALSE, TRUE)
	var/obj/item/bodypart/chest = test_human.get_bodypart(BODY_ZONE_CHEST)
	chest.create_injury(WOUND_SLASH, 15, TRUE)
	var/obj/item/bodypart/head = test_human.get_bodypart(BODY_ZONE_HEAD)
	head.create_injury(WOUND_BLUNT, 40, TRUE)

	var/datum/defeat_snapshot/snapshot = new
	snapshot.capture_from(test_human, DEFEAT_REASON_DAMAGE, DEFEAT_SEVERITY_NORMAL)

	TEST_ASSERT_EQUAL(snapshot.reason, DEFEAT_REASON_DAMAGE, "The snapshot should preserve the defeat reason.")
	TEST_ASSERT_EQUAL(snapshot.severity, DEFEAT_SEVERITY_NORMAL, "The snapshot should preserve the defeat severity.")
	TEST_ASSERT_EQUAL(snapshot.tox_loss, test_human.getToxLoss(), "The snapshot should preserve major damage totals before stabilization.")
	TEST_ASSERT_EQUAL(snapshot.worst_body_zone, BODY_ZONE_HEAD, "The snapshot should prefer the highest-damage injury bodypart.")
	TEST_ASSERT_EQUAL(snapshot.worst_injury_type, WOUND_BLUNT, "The snapshot should preserve the worst injury type for aftermath mapping.")

/datum/unit_test/defeat_damage_threshold_edges

/datum/unit_test/defeat_damage_threshold_edges/Run()
	var/mob/living/carbon/human/test_human = allocate(/mob/living/carbon/human)
	test_human.defeat_mode = DEFEAT_MODE_KO_RUNE
	test_human.defeat_damage_threshold = 200
	test_human.defeat_system_ai_opt_in = TRUE
	var/datum/component/defeat_monitor/monitor = test_human.AddComponent(/datum/component/defeat_monitor)

	test_human.setToxLoss(199)
	monitor.check_defeat_triggers()
	TEST_ASSERT_NULL(test_human.has_status_effect(/datum/status_effect/defeat_knockout), "Damage below the selected threshold should not trigger defeat.")

	test_human.setToxLoss(200)
	monitor.check_defeat_triggers()
	TEST_ASSERT_NOTNULL(test_human.has_status_effect(/datum/status_effect/defeat_knockout), "Damage at the selected threshold should trigger defeat.")
	TEST_ASSERT_NOTNULL(test_human.last_defeat_snapshot, "Damage defeat should capture a snapshot before stabilization.")
	TEST_ASSERT_EQUAL(test_human.last_defeat_snapshot.tox_loss, 200, "The snapshot should retain the threshold-crossing damage.")
	TEST_ASSERT_EQUAL(test_human.getToxLoss(), 0, "Live toxin damage should be stabilized after defeat.")

/datum/unit_test/defeat_shock_sustain_and_hard_stage

/datum/unit_test/defeat_shock_sustain_and_hard_stage/Run()
	var/mob/living/carbon/human/test_human = allocate(/mob/living/carbon/human)
	test_human.defeat_system_ai_opt_in = TRUE
	var/datum/component/defeat_monitor/monitor = test_human.AddComponent(/datum/component/defeat_monitor)

	test_human.setShockStage(SHOCK_STAGE_6, FALSE, TRUE)
	monitor.check_defeat_triggers()
	TEST_ASSERT_NULL(test_human.has_status_effect(/datum/status_effect/defeat_knockout), "Stage 6 shock should require sustained pain before defeat.")

	monitor.shock_defeat_started_at = world.time - DEFEAT_SHOCK_SUSTAIN_DURATION
	monitor.check_defeat_triggers()
	TEST_ASSERT_NOTNULL(test_human.has_status_effect(/datum/status_effect/defeat_knockout), "Stage 6 shock should trigger after the sustain window.")
	TEST_ASSERT_EQUAL(test_human.last_defeat_snapshot.reason, DEFEAT_REASON_PAIN, "Sustained shock defeat should be recorded as pain defeat.")

	var/mob/living/carbon/human/hard_shock_human = allocate(/mob/living/carbon/human)
	hard_shock_human.defeat_system_ai_opt_in = TRUE
	var/datum/component/defeat_monitor/hard_monitor = hard_shock_human.AddComponent(/datum/component/defeat_monitor)
	hard_shock_human.setShockStage(SHOCK_STAGE_8, FALSE, TRUE)
	hard_monitor.check_defeat_triggers()
	TEST_ASSERT_NOTNULL(hard_shock_human.has_status_effect(/datum/status_effect/defeat_knockout), "Stage 8 shock should trigger immediate defeat.")
	TEST_ASSERT_EQUAL(hard_shock_human.last_defeat_snapshot.severity, DEFEAT_SEVERITY_SEVERE, "Stage 8 shock should be severe.")

/datum/unit_test/defeat_no_return_bypasses_new_routing

/datum/unit_test/defeat_no_return_bypasses_new_routing/Run()
	var/mob/living/carbon/human/test_human = allocate(/mob/living/carbon/human)
	test_human.defeat_mode = DEFEAT_MODE_NO_RETURN
	test_human.defeat_system_ai_opt_in = TRUE
	var/datum/component/defeat_monitor/monitor = test_human.AddComponent(/datum/component/defeat_monitor)

	test_human.setBruteLoss(300, FALSE, TRUE)
	monitor.check_defeat_triggers()
	TEST_ASSERT_NULL(test_human.has_status_effect(/datum/status_effect/defeat_knockout), "No Return should bypass defeat KO routing even if a monitor is present.")
	TEST_ASSERT_NULL(test_human.last_defeat_snapshot, "No Return should not generate a defeat snapshot.")

/datum/unit_test/defeat_death_threshold_uses_death_reason

/datum/unit_test/defeat_death_threshold_uses_death_reason/Run()
	var/mob/living/carbon/human/test_human = allocate(/mob/living/carbon/human)
	test_human.defeat_system_ai_opt_in = TRUE
	test_human.defeat_damage_threshold = 300
	var/datum/component/defeat_monitor/monitor = test_human.AddComponent(/datum/component/defeat_monitor)

	test_human.set_health(HEALTH_THRESHOLD_DEAD)
	monitor.check_defeat_triggers()
	TEST_ASSERT_NOTNULL(test_human.has_status_effect(/datum/status_effect/defeat_knockout), "Lethal health should trigger defeat even when no single damage category reaches the selected threshold.")
	TEST_ASSERT_EQUAL(test_human.last_defeat_snapshot.reason, DEFEAT_REASON_DEATH, "Lethal health defeat should be captured as death defeat.")
	TEST_ASSERT_EQUAL(test_human.last_defeat_snapshot.severity, DEFEAT_SEVERITY_SEVERE, "Lethal health defeat should be severe.")

/datum/unit_test/defeat_ko_only_hazard_can_emergency_rune

/datum/unit_test/defeat_ko_only_hazard_can_emergency_rune/Run()
	var/turf/original_turf = get_step(run_loc_floor_bottom_left, EAST)
	var/original_turf_type = original_turf.type
	var/list/original_baseturfs = original_turf.baseturfs
	var/turf/lava_turf = original_turf.ChangeTurf(/turf/open/lava)
	var/obj/structure/resurrection_rune/test_rune = allocate(/obj/structure/resurrection_rune, get_step(lava_turf, EAST))
	test_rune.rune_tag = "defeat_unit_hazard_[world.time]"
	var/datum/resurrection_rune_controller/controller = test_rune.resrunecontroler
	var/mob/living/carbon/human/test_human = allocate(/mob/living/carbon/human, lava_turf)
	test_human.defeat_system_ai_opt_in = TRUE
	test_human.defeat_mode = DEFEAT_MODE_KO_ONLY
	test_human.mind = allocate(/datum/mind, "defeat-hazard-rune-user")
	test_human.mind.current = test_human
	controller.add_user(test_human)
	var/datum/component/defeat_monitor/monitor = test_human.AddComponent(/datum/component/defeat_monitor)

	monitor.check_defeat_triggers()
	controller.handle_linked_user_update(test_human)
	var/has_defeat_knockout = test_human.has_status_effect(/datum/status_effect/defeat_knockout)
	var/defeat_reason = test_human.last_defeat_snapshot?.reason
	var/queued_for_resurrection = (test_human in controller.resurrecting)

	test_human.mind.current = null
	test_human.mind = null
	lava_turf.ChangeTurf(original_turf_type, original_baseturfs)

	TEST_ASSERT_NOTNULL(has_defeat_knockout, "KO Only should still enter defeat before a live linked rune emergency hazard rescue.")
	TEST_ASSERT_EQUAL(defeat_reason, DEFEAT_REASON_HAZARD, "Immediate rune hazards should preserve the hazard defeat reason.")
	TEST_ASSERT(queued_for_resurrection, "Immediate hazards should queue emergency rune rescue even for KO Only users.")

/datum/unit_test/defeat_knockout_traits_are_custom

/datum/unit_test/defeat_knockout_traits_are_custom/Run()
	var/mob/living/carbon/human/test_human = allocate(/mob/living/carbon/human)
	test_human.defeat_system_ai_opt_in = TRUE
	test_human.setBruteLoss(200, FALSE, TRUE)

	TEST_ASSERT(test_human.enter_defeat(DEFEAT_REASON_DAMAGE, DEFEAT_SEVERITY_NORMAL), "Eligible damage should enter defeat.")
	TEST_ASSERT_NOTNULL(test_human.has_status_effect(/datum/status_effect/defeat_knockout), "Defeat should apply the custom KO status.")
	TEST_ASSERT(HAS_TRAIT(test_human, TRAIT_NODEATH), "Defeat KO should protect against normal death.")
	TEST_ASSERT(HAS_TRAIT(test_human, TRAIT_PACIFISM), "Defeat KO should pacify hostile actions.")
	TEST_ASSERT(HAS_TRAIT(test_human, TRAIT_IMMOBILIZED), "Defeat KO should block movement.")
	TEST_ASSERT(HAS_TRAIT(test_human, TRAIT_HANDS_BLOCKED), "Defeat KO should block normal item combat.")
	TEST_ASSERT(!HAS_TRAIT(test_human, TRAIT_KNOCKEDOUT), "Defeat KO must not use normal unconsciousness.")
	TEST_ASSERT(test_human.stat != DEAD, "Defeat KO should not make the mob dead.")

/datum/unit_test/defeat_rescue_applies_aftermath_debuff

/datum/unit_test/defeat_rescue_applies_aftermath_debuff/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/helper = allocate(/mob/living/carbon/human)
	victim.defeat_system_ai_opt_in = TRUE
	victim.setBruteLoss(200, FALSE, TRUE)
	victim.enter_defeat(DEFEAT_REASON_DAMAGE, DEFEAT_SEVERITY_NORMAL)

	TEST_ASSERT(victim.defeat_rescue(helper), "A non-hostile adjacent helper should be able to rescue a defeated mob.")
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/defeat_knockout), "Rescue should clear the defeat KO status.")
	TEST_ASSERT(victim.has_any_defeat_physical_trauma(), "Damage defeat should leave physical trauma after rescue.")

/datum/unit_test/defeat_rescue_rejects_recent_attacker

/datum/unit_test/defeat_rescue_rejects_recent_attacker/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	victim.defeat_system_ai_opt_in = TRUE
	victim.setBruteLoss(200, FALSE, TRUE)
	victim.enter_defeat(DEFEAT_REASON_DAMAGE, DEFEAT_SEVERITY_NORMAL, attacker)

	TEST_ASSERT(!victim.defeat_rescue(attacker), "The recent attacker should not be able to trivially erase defeat consequences.")
	TEST_ASSERT_NOTNULL(victim.has_status_effect(/datum/status_effect/defeat_knockout), "Rejected rescues should leave defeat KO in place.")

/datum/unit_test/defeat_treatment_clears_correct_trauma

/datum/unit_test/defeat_treatment_clears_correct_trauma/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/doctor = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/priest = allocate(/mob/living/carbon/human)
	patient.apply_status_effect(/datum/status_effect/debuff/defeat/physical, null, DEFEAT_SEVERITY_NORMAL)
	patient.apply_status_effect(/datum/status_effect/debuff/defeat/pain, null, DEFEAT_SEVERITY_NORMAL)
	patient.apply_status_effect(/datum/status_effect/debuff/defeat/rune, null, DEFEAT_SEVERITY_NORMAL)

	doctor.set_skillrank(/datum/skill/misc/medicine, SKILL_RANK_APPRENTICE, TRUE)
	TEST_ASSERT(patient.defeat_treat_trauma(doctor, DEFEAT_TREATMENT_MEDICAL), "A medically trained helper should clear physical and pain trauma.")
	TEST_ASSERT_NULL(patient.has_status_effect(/datum/status_effect/debuff/defeat/physical), "Medical treatment should clear physical trauma.")
	TEST_ASSERT_NULL(patient.has_status_effect(/datum/status_effect/debuff/defeat/pain), "Medical treatment should clear pain trauma.")
	TEST_ASSERT_NOTNULL(patient.has_status_effect(/datum/status_effect/debuff/defeat/rune), "Medical treatment should not clear rune trauma.")

	ADD_TRAIT(priest, TRAIT_HOLY, TRAIT_GENERIC)
	TEST_ASSERT(patient.defeat_treat_trauma(priest, DEFEAT_TREATMENT_SPIRITUAL), "A priestly helper should clear rune trauma.")
	TEST_ASSERT_NULL(patient.has_status_effect(/datum/status_effect/debuff/defeat/rune), "Spiritual treatment should clear rune trauma.")

/datum/unit_test/defeat_debuff_fallback_duration_by_severity

/datum/unit_test/defeat_debuff_fallback_duration_by_severity/Run()
	var/mob/living/carbon/human/light_patient = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/severe_patient = allocate(/mob/living/carbon/human)
	var/datum/status_effect/debuff/defeat/light_effect = light_patient.apply_status_effect(/datum/status_effect/debuff/defeat/physical, null, DEFEAT_SEVERITY_LIGHT)
	var/datum/status_effect/debuff/defeat/severe_effect = severe_patient.apply_status_effect(/datum/status_effect/debuff/defeat/physical, null, DEFEAT_SEVERITY_SEVERE)

	TEST_ASSERT_EQUAL(light_effect.initial_duration, 10 MINUTES, "Light defeat trauma should decay slowly but sooner than worse trauma.")
	TEST_ASSERT_EQUAL(severe_effect.initial_duration, 60 MINUTES, "Severe defeat trauma should have the longest fallback decay.")

/datum/unit_test/defeat_rune_charge_first_free_spend_and_recharge

/datum/unit_test/defeat_rune_charge_first_free_spend_and_recharge/Run()
	var/datum/mind/test_mind = allocate(/datum/mind, "defeat-rune-charge-test")

	TEST_ASSERT_EQUAL(test_mind.get_defeat_rune_charges(), DEFEAT_RUNE_MAX_CHARGES, "Rune charges should start full for the round.")

	var/list/first_spend = test_mind.spend_defeat_rune_charge()
	TEST_ASSERT_EQUAL(first_spend[DEFEAT_RUNE_SPEND_KIND], DEFEAT_RUNE_SPEND_FIRST_FREE, "The first defeat rune return should be free.")
	TEST_ASSERT_EQUAL(test_mind.get_defeat_rune_charges(), DEFEAT_RUNE_MAX_CHARGES, "The first free return should not spend a stored charge.")

	var/list/charged_spend = test_mind.spend_defeat_rune_charge()
	TEST_ASSERT_EQUAL(charged_spend[DEFEAT_RUNE_SPEND_KIND], DEFEAT_RUNE_SPEND_CHARGED, "Later returns should spend stored charges.")
	TEST_ASSERT_EQUAL(charged_spend[DEFEAT_RUNE_CHARGES_REMAINING], DEFEAT_RUNE_MAX_CHARGES - 1, "Charged returns should report remaining charges.")

	test_mind.defeat_rune_charges = 0
	test_mind.defeat_rune_last_recharge_time = world.time - DEFEAT_RUNE_RECHARGE_TIME
	test_mind.recharge_defeat_rune_charges()
	TEST_ASSERT_EQUAL(test_mind.get_defeat_rune_charges(), 1, "One rune charge should recharge each recharge interval.")

/datum/unit_test/defeat_rune_depletion_and_emergency

/datum/unit_test/defeat_rune_depletion_and_emergency/Run()
	var/datum/mind/test_mind = allocate(/datum/mind, "defeat-rune-depletion-test")
	test_mind.defeat_rune_first_free_used = TRUE
	test_mind.defeat_rune_charges = 0

	TEST_ASSERT(!test_mind.can_spend_defeat_rune_charge(), "Depleted non-emergency rune returns should be blocked.")

	var/list/emergency_spend = test_mind.spend_defeat_rune_charge(TRUE)
	TEST_ASSERT_EQUAL(emergency_spend[DEFEAT_RUNE_SPEND_KIND], DEFEAT_RUNE_SPEND_EMERGENCY, "Emergency hazard returns should be allowed even at zero charges.")
	TEST_ASSERT_EQUAL(emergency_spend[DEFEAT_RUNE_CHARGES_REMAINING], 0, "Emergency hazard returns should not create negative charges.")

/datum/unit_test/defeat_rune_preference_routing

/datum/unit_test/defeat_rune_preference_routing/Run()
	var/obj/structure/resurrection_rune/test_rune = allocate(/obj/structure/resurrection_rune)
	var/datum/resurrection_rune_controller/controller = test_rune.resrunecontroler
	var/mob/living/carbon/human/ko_rune_user = allocate(/mob/living/carbon/human)
	ko_rune_user.defeat_system_ai_opt_in = TRUE
	ko_rune_user.defeat_mode = DEFEAT_MODE_KO_RUNE
	ko_rune_user.mind = allocate(/datum/mind, "defeat-ko-rune-user")
	ko_rune_user.mind.current = ko_rune_user
	controller.linked_users += ko_rune_user
	ko_rune_user.enter_defeat(DEFEAT_REASON_DAMAGE, DEFEAT_SEVERITY_NORMAL)
	TEST_ASSERT(controller.can_offer_defeat_rune_return(ko_rune_user), "KO + Rune defeated users should be offered voluntary rune return when charges are available.")

	var/mob/living/carbon/human/ko_only_user = allocate(/mob/living/carbon/human)
	ko_only_user.defeat_system_ai_opt_in = TRUE
	ko_only_user.defeat_mode = DEFEAT_MODE_KO_ONLY
	ko_only_user.mind = allocate(/datum/mind, "defeat-ko-only-user")
	ko_only_user.mind.current = ko_only_user
	controller.linked_users += ko_only_user
	ko_only_user.enter_defeat(DEFEAT_REASON_DAMAGE, DEFEAT_SEVERITY_NORMAL)
	TEST_ASSERT(!controller.can_offer_defeat_rune_return(ko_only_user), "KO Only defeated users should not receive voluntary rune return.")

	ko_rune_user.mind.defeat_rune_first_free_used = TRUE
	ko_rune_user.mind.defeat_rune_charges = 0
	TEST_ASSERT(!controller.can_offer_defeat_rune_return(ko_rune_user), "Depleted KO + Rune users should stay KO-only until charges recharge.")
	ko_rune_user.mind.current = null
	ko_rune_user.mind = null
	ko_only_user.mind.current = null
	ko_only_user.mind = null

/datum/unit_test/defeat_rune_fatigue_mapping

/datum/unit_test/defeat_rune_fatigue_mapping/Run()
	var/datum/resurrection_rune_controller/controller = allocate(/datum/resurrection_rune_controller)
	var/mob/living/carbon/human/first_free_user = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/last_charge_user = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/emergency_user = allocate(/mob/living/carbon/human)

	controller.apply_revival_debuffs(first_free_user, TRUE, list(DEFEAT_RUNE_SPEND_KIND = DEFEAT_RUNE_SPEND_FIRST_FREE, DEFEAT_RUNE_CHARGES_REMAINING = DEFEAT_RUNE_MAX_CHARGES))
	TEST_ASSERT_NOTNULL(first_free_user.has_status_effect(/datum/status_effect/debuff/revived/rune/light), "First free rune return should apply light rune fatigue.")

	controller.apply_revival_debuffs(last_charge_user, TRUE, list(DEFEAT_RUNE_SPEND_KIND = DEFEAT_RUNE_SPEND_CHARGED, DEFEAT_RUNE_CHARGES_REMAINING = 0))
	TEST_ASSERT_NOTNULL(last_charge_user.has_status_effect(/datum/status_effect/debuff/revived/rune/rough), "Spending the last charge should apply rough rune fatigue.")

	controller.apply_revival_debuffs(emergency_user, TRUE, list(DEFEAT_RUNE_SPEND_KIND = DEFEAT_RUNE_SPEND_EMERGENCY, DEFEAT_RUNE_CHARGES_REMAINING = 0))
	TEST_ASSERT_NOTNULL(emergency_user.has_status_effect(/datum/status_effect/debuff/revived/rune/rough), "Emergency depleted rescues should apply rough rune fatigue.")

/datum/unit_test/defeat_snapshot_debuff_maps_worst_injury

/datum/unit_test/defeat_snapshot_debuff_maps_worst_injury/Run()
	var/mob/living/carbon/human/burn_patient = allocate(/mob/living/carbon/human)
	burn_patient.defeat_system_ai_opt_in = TRUE
	var/obj/item/bodypart/chest = burn_patient.get_bodypart(BODY_ZONE_CHEST)
	chest.create_injury(WOUND_BURN, 45, TRUE)
	burn_patient.enter_defeat(DEFEAT_REASON_DAMAGE, DEFEAT_SEVERITY_NORMAL)
	burn_patient.apply_defeat_snapshot_debuffs()
	TEST_ASSERT_NOTNULL(burn_patient.has_status_effect(/datum/status_effect/debuff/defeat/physical/burn), "Burn injuries should produce burn trauma.")

	var/mob/living/carbon/human/head_patient = allocate(/mob/living/carbon/human)
	head_patient.defeat_system_ai_opt_in = TRUE
	var/obj/item/bodypart/head = head_patient.get_bodypart(BODY_ZONE_HEAD)
	head.create_injury(WOUND_BLUNT, 45, TRUE)
	head_patient.enter_defeat(DEFEAT_REASON_DAMAGE, DEFEAT_SEVERITY_NORMAL)
	head_patient.apply_defeat_snapshot_debuffs()
	TEST_ASSERT_NOTNULL(head_patient.has_status_effect(/datum/status_effect/debuff/defeat/physical/concussion), "Head blunt injuries should produce concussion trauma.")

/datum/unit_test/defeat_trauma_refresh_keeps_highest_severity

/datum/unit_test/defeat_trauma_refresh_keeps_highest_severity/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	patient.apply_defeat_trauma_status(/datum/status_effect/debuff/defeat/pain, DEFEAT_SEVERITY_SEVERE)
	patient.apply_defeat_trauma_status(/datum/status_effect/debuff/defeat/pain, DEFEAT_SEVERITY_LIGHT)
	var/datum/status_effect/debuff/defeat/pain/pain_trauma = patient.has_status_effect(/datum/status_effect/debuff/defeat/pain)
	TEST_ASSERT_EQUAL(pain_trauma.severity, DEFEAT_SEVERITY_SEVERE, "Repeated lighter trauma should not downgrade an existing severe defeat trauma.")

/datum/unit_test/defeat_horny_requires_valid_hostile_source

/datum/unit_test/defeat_horny_requires_valid_hostile_source/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/grabber = allocate(/mob/living/carbon/human)
	victim.defeat_system_ai_opt_in = TRUE
	victim.hostile_grab_horny_climax_threshold = 1
	victim.pulledby = grabber
	grabber.pulling = victim
	grabber.grab_state = GRAB_AGGRESSIVE
	var/datum/component/defeat_monitor/monitor = victim.AddComponent(/datum/component/defeat_monitor)

	monitor.on_climax(victim, null, victim, grabber, grabber)
	TEST_ASSERT_NOTNULL(victim.has_status_effect(/datum/status_effect/defeat_knockout), "Hostile grab climax metadata should trigger horny defeat when the threshold is met.")
	TEST_ASSERT_EQUAL(victim.last_defeat_snapshot.reason, DEFEAT_REASON_HORNY, "Horny defeat should preserve its reason in the snapshot.")

/datum/unit_test/defeat_horny_rejects_self_farming_and_unopted_ai

/datum/unit_test/defeat_horny_rejects_self_farming_and_unopted_ai/Run()
	var/mob/living/carbon/human/self_target = allocate(/mob/living/carbon/human)
	self_target.defeat_system_ai_opt_in = TRUE
	self_target.hostile_grab_horny_climax_threshold = 1
	var/datum/component/defeat_monitor/self_monitor = self_target.AddComponent(/datum/component/defeat_monitor)
	self_monitor.on_climax(self_target, null, self_target, self_target, self_target)
	TEST_ASSERT_NULL(self_target.has_status_effect(/datum/status_effect/defeat_knockout), "Self-generated climax metadata must not farm horny defeat.")

	var/mob/living/carbon/human/unopted_ai = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/grabber = allocate(/mob/living/carbon/human)
	unopted_ai.hostile_grab_horny_climax_threshold = 1
	unopted_ai.pulledby = grabber
	grabber.pulling = unopted_ai
	grabber.grab_state = GRAB_AGGRESSIVE
	var/datum/component/defeat_monitor/unopted_monitor = unopted_ai.AddComponent(/datum/component/defeat_monitor)
	unopted_monitor.on_climax(unopted_ai, null, unopted_ai, grabber, grabber)
	TEST_ASSERT_NULL(unopted_ai.has_status_effect(/datum/status_effect/defeat_knockout), "AI without explicit opt-in should not be defeated through horny defeat.")
