/proc/defeat_unit_place_adjacent(mob/living/first, mob/living/second, turf/base_turf)
	var/turf/first_turf = get_step(base_turf, EAST)
	var/turf/second_turf = get_step(first_turf, EAST)
	first.forceMove(first_turf)
	second.forceMove(second_turf)

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

/datum/unit_test/defeat_stabilization_clears_live_injuries_after_snapshot

/datum/unit_test/defeat_stabilization_clears_live_injuries_after_snapshot/Run()
	var/mob/living/carbon/human/test_human = allocate(/mob/living/carbon/human)
	test_human.defeat_system_ai_opt_in = TRUE
	var/obj/item/bodypart/chest = test_human.get_bodypart(BODY_ZONE_CHEST)
	chest.create_injury(WOUND_SLASH, 45, TRUE)
	test_human.setBruteLoss(200, FALSE, TRUE)

	TEST_ASSERT(length(test_human.all_injuries), "The setup should create active injury data before defeat.")
	TEST_ASSERT(test_human.defeat_stabilize_active_injuries(FALSE), "The dedicated defeat injury stabilizer should report that it cleared active injuries.")
	TEST_ASSERT(!length(test_human.all_injuries), "The dedicated defeat injury stabilizer should clear live injury datums.")
	TEST_ASSERT_EQUAL(test_human.get_bleed_rate(), 0, "Cleared defeat injuries should not keep bleeding invisibly.")

	chest.create_injury(WOUND_PIERCE, 50, TRUE)
	TEST_ASSERT(test_human.enter_defeat(DEFEAT_REASON_DAMAGE, DEFEAT_SEVERITY_NORMAL), "Eligible damage should enter defeat.")
	TEST_ASSERT_EQUAL(test_human.last_defeat_snapshot.worst_injury_type, WOUND_PIERCE, "Defeat should capture the worst injury before stabilizing it.")
	TEST_ASSERT(!length(test_human.all_injuries), "Defeat stabilization should clear live injury datums after snapshot capture.")
	TEST_ASSERT_EQUAL(test_human.getBruteLoss(), 0, "Defeat stabilization should still clear live damage.")

/datum/unit_test/defeat_death_signal_is_conservative_fallback

/datum/unit_test/defeat_death_signal_is_conservative_fallback/Run()
	var/mob/living/carbon/human/normal_dead = allocate(/mob/living/carbon/human)
	normal_dead.defeat_system_ai_opt_in = TRUE
	normal_dead.stat = DEAD
	var/datum/component/defeat_monitor/normal_monitor = normal_dead.AddComponent(/datum/component/defeat_monitor)

	normal_monitor.on_death(normal_dead)
	TEST_ASSERT_NULL(normal_dead.has_status_effect(/datum/status_effect/defeat_knockout), "Ordinary completed death should not be converted into defeat KO by the death signal fallback.")
	TEST_ASSERT_NULL(normal_dead.last_defeat_snapshot, "Ordinary completed death should not capture a defeat snapshot in the death signal fallback.")

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

/datum/unit_test/defeat_damage_threshold_uses_total_damage

/datum/unit_test/defeat_damage_threshold_uses_total_damage/Run()
	var/mob/living/carbon/human/test_human = allocate(/mob/living/carbon/human)
	test_human.defeat_system_ai_opt_in = TRUE
	test_human.defeat_damage_threshold = 150
	var/datum/component/defeat_monitor/monitor = test_human.AddComponent(/datum/component/defeat_monitor)

	// Neither pool reaches 150 on its own (so the old max-pool rule would NOT fire), but together
	// they total 160 - the threshold is now total damage, so defeat should trigger.
	test_human.setBruteLoss(100, FALSE, TRUE)
	test_human.setFireLoss(60, FALSE, TRUE)
	test_human.updatehealth()
	monitor.check_defeat_triggers()
	TEST_ASSERT_NOTNULL(test_human.has_status_effect(/datum/status_effect/defeat_knockout), "Combined damage across pools should trigger defeat even when no single pool hits the threshold.")
	TEST_ASSERT_EQUAL(test_human.last_defeat_snapshot.reason, DEFEAT_REASON_DAMAGE, "Total-damage defeat should be recorded as a damage defeat, not death.")

/datum/unit_test/defeat_near_death_covers_blood_loss

/datum/unit_test/defeat_near_death_covers_blood_loss/Run()
	var/mob/living/carbon/human/test_human = allocate(/mob/living/carbon/human)
	TEST_ASSERT(!test_human.defeat_is_near_death(), "A healthy mob should not read as near death.")
	test_human.blood_volume = BLOOD_VOLUME_SURVIVE
	TEST_ASSERT(test_human.defeat_is_near_death(), "Bleeding to the survive floor should read as near death (the real brute/burn death path).")
	test_human.blood_volume = BLOOD_VOLUME_NORMAL
	TEST_ASSERT(!test_human.defeat_is_near_death(), "Restored blood should clear the near-death state.")

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

/datum/unit_test/defeat_knockout_has_alert_and_overlay_feedback

/datum/unit_test/defeat_knockout_has_alert_and_overlay_feedback/Run()
	var/mob/living/carbon/human/test_human = allocate(/mob/living/carbon/human)
	test_human.defeat_system_ai_opt_in = TRUE

	TEST_ASSERT(test_human.enter_defeat(DEFEAT_REASON_DAMAGE, DEFEAT_SEVERITY_NORMAL), "Eligible damage should enter defeat.")
	var/datum/status_effect/defeat_knockout/knockout = test_human.has_status_effect(/datum/status_effect/defeat_knockout)
	TEST_ASSERT_NOTNULL(knockout, "Defeat should apply the custom KO status.")
	TEST_ASSERT_NOTNULL(knockout.alert_type, "Defeat KO should expose a status alert.")
	TEST_ASSERT_NOTNULL(test_human.screens["defeat"], "Defeat KO should apply a limited-vision fullscreen overlay.")

	test_human.remove_status_effect(/datum/status_effect/defeat_knockout)
	TEST_ASSERT_NULL(test_human.screens["defeat"], "Removing defeat KO should clear the fullscreen overlay.")

/datum/unit_test/defeat_shock_warning_feedback_is_throttled

/datum/unit_test/defeat_shock_warning_feedback_is_throttled/Run()
	var/mob/living/carbon/human/test_human = allocate(/mob/living/carbon/human)
	test_human.defeat_system_ai_opt_in = TRUE
	var/datum/component/defeat_monitor/monitor = test_human.AddComponent(/datum/component/defeat_monitor)

	TEST_ASSERT(monitor.maybe_warn_shock_defeat(DEFEAT_SHOCK_WARNING_STAGE), "Shock warning stage should produce an initial warning.")
	TEST_ASSERT(!monitor.maybe_warn_shock_defeat(DEFEAT_SHOCK_WARNING_STAGE), "Shock warnings should be throttled during their cooldown.")
	monitor.shock_warning_last_at = world.time - DEFEAT_SHOCK_WARNING_COOLDOWN
	TEST_ASSERT(monitor.maybe_warn_shock_defeat(DEFEAT_SHOCK_WARNING_STAGE), "Shock warning should fire again after the cooldown.")

	test_human.setShockStage(DEFEAT_SHOCK_WARNING_STAGE - 1, FALSE, TRUE)
	monitor.check_defeat_triggers()
	TEST_ASSERT_EQUAL(monitor.shock_warning_last_at, 0, "Dropping below the shock warning stage should clear the warning cooldown.")

/datum/unit_test/defeat_rescue_applies_aftermath_debuff

/datum/unit_test/defeat_rescue_applies_aftermath_debuff/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/helper = allocate(/mob/living/carbon/human)
	defeat_unit_place_adjacent(victim, helper, run_loc_floor_bottom_left)
	victim.defeat_system_ai_opt_in = TRUE
	victim.setBruteLoss(200, FALSE, TRUE)
	victim.enter_defeat(DEFEAT_REASON_DAMAGE, DEFEAT_SEVERITY_NORMAL)

	TEST_ASSERT(victim.defeat_rescue(helper), "A non-hostile adjacent helper should be able to rescue a defeated mob.")
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/defeat_knockout), "Rescue should clear the defeat KO status.")
	TEST_ASSERT(victim.has_any_defeat_physical_trauma(), "Damage defeat should leave physical trauma after rescue.")

/datum/unit_test/defeat_rescue_allows_inactive_recent_attacker

/datum/unit_test/defeat_rescue_allows_inactive_recent_attacker/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	defeat_unit_place_adjacent(victim, attacker, run_loc_floor_bottom_left)
	victim.defeat_system_ai_opt_in = TRUE
	victim.setBruteLoss(200, FALSE, TRUE)
	victim.enter_defeat(DEFEAT_REASON_DAMAGE, DEFEAT_SEVERITY_NORMAL, attacker)
	victim.recent_damage_source_attacker_weakref = WEAKREF(attacker)
	victim.recent_damage_source_time = world.time - DEFEAT_ACTIVE_HARM_WINDOW - 1

	TEST_ASSERT(victim.defeat_rescue(attacker), "A recent attacker should be able to rescue once active harm has stopped.")
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/defeat_knockout), "Accepted rescues should clear defeat KO.")

/datum/unit_test/defeat_rescue_blocks_active_harm

/datum/unit_test/defeat_rescue_blocks_active_harm/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	defeat_unit_place_adjacent(victim, attacker, run_loc_floor_bottom_left)
	victim.defeat_system_ai_opt_in = TRUE
	victim.setBruteLoss(200, FALSE, TRUE)
	victim.enter_defeat(DEFEAT_REASON_DAMAGE, DEFEAT_SEVERITY_NORMAL, attacker)
	victim.recent_damage_source_attacker_weakref = WEAKREF(attacker)
	victim.recent_damage_source_time = world.time

	TEST_ASSERT(!victim.defeat_rescue(attacker), "Very recent direct harm should block rescues.")
	TEST_ASSERT_NOTNULL(victim.has_status_effect(/datum/status_effect/defeat_knockout), "Blocked rescues should leave defeat KO in place.")

	victim.recent_damage_source_time = world.time - DEFEAT_ACTIVE_HARM_WINDOW - 1
	attacker.pulling = victim
	attacker.grab_state = GRAB_AGGRESSIVE
	TEST_ASSERT(!victim.defeat_rescue(attacker), "Active aggressive grabs should block rescues.")

/datum/unit_test/defeat_auto_rescue_from_healing_threshold

/datum/unit_test/defeat_auto_rescue_from_healing_threshold/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/helper = allocate(/mob/living/carbon/human)
	defeat_unit_place_adjacent(victim, helper, run_loc_floor_bottom_left)
	victim.defeat_system_ai_opt_in = TRUE
	victim.setBruteLoss(200, FALSE, TRUE)
	victim.enter_defeat(DEFEAT_REASON_DAMAGE, DEFEAT_SEVERITY_NORMAL)

	TEST_ASSERT(!victim.defeat_try_auto_rescue_from_healing(helper, DEFEAT_AUTO_RESCUE_HEALING_THRESHOLD - 1, "small healing"), "Tiny healing should not auto-rescue defeated targets.")
	TEST_ASSERT_NOTNULL(victim.has_status_effect(/datum/status_effect/defeat_knockout), "Sub-threshold healing should leave KO in place.")
	TEST_ASSERT(victim.defeat_try_auto_rescue_from_healing(helper, DEFEAT_AUTO_RESCUE_HEALING_THRESHOLD, "meaningful healing"), "Meaningful healing should auto-rescue when the helper is allowed.")
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/defeat_knockout), "Auto-rescue should clear defeat KO.")

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

/datum/unit_test/defeat_tool_treatment_clears_matching_trauma_only

/datum/unit_test/defeat_tool_treatment_clears_matching_trauma_only/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/doctor = allocate(/mob/living/carbon/human)
	doctor.set_skillrank(/datum/skill/misc/medicine, SKILL_RANK_APPRENTICE, TRUE)
	patient.apply_status_effect(/datum/status_effect/debuff/defeat/physical/wound, null, DEFEAT_SEVERITY_NORMAL)
	patient.apply_status_effect(/datum/status_effect/debuff/defeat/physical/burn, null, DEFEAT_SEVERITY_NORMAL)
	patient.apply_status_effect(/datum/status_effect/debuff/defeat/pain, null, DEFEAT_SEVERITY_NORMAL)

	TEST_ASSERT(patient.defeat_treat_tool_physical_trauma(doctor, list(/datum/status_effect/debuff/defeat/physical/wound)), "Qualified wound care should clear wound trauma.")
	TEST_ASSERT_NULL(patient.has_status_effect(/datum/status_effect/debuff/defeat/physical/wound), "Wound care should remove wound trauma.")
	TEST_ASSERT_NOTNULL(patient.has_status_effect(/datum/status_effect/debuff/defeat/physical/burn), "Wound care should not remove burn trauma.")
	TEST_ASSERT_NOTNULL(patient.has_status_effect(/datum/status_effect/debuff/defeat/pain), "Wound care should not remove pain trauma.")

/datum/unit_test/defeat_universal_treatment_and_priest_spell_surface

/datum/unit_test/defeat_universal_treatment_and_priest_spell_surface/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	patient.apply_status_effect(/datum/status_effect/debuff/defeat/pain, null, DEFEAT_SEVERITY_NORMAL)
	patient.apply_status_effect(/datum/status_effect/debuff/defeat/rune, null, DEFEAT_SEVERITY_NORMAL)

	TEST_ASSERT(patient.defeat_treat_trauma(patient, DEFEAT_TREATMENT_UNIVERSAL), "Universal defeat treatment should clear one trauma.")
	TEST_ASSERT_NULL(patient.has_status_effect(/datum/status_effect/debuff/defeat/pain), "Universal treatment should clear the highest-priority matching trauma.")
	TEST_ASSERT_NOTNULL(patient.has_status_effect(/datum/status_effect/debuff/defeat/rune), "Universal treatment should clear only one trauma at a time.")

	var/datum/devotion/devotion = allocate(/datum/devotion)
	devotion.make_priest()
	TEST_ASSERT((/datum/action/cooldown/spell/defeat_absolution in devotion.miracles_extra), "Priest setup should grant the dedicated defeat-absolution spell.")

	var/datum/container_craft/cooking/herbal_tea/mercy_draught/recipe = allocate(/datum/container_craft/cooking/herbal_tea/mercy_draught)
	TEST_ASSERT_EQUAL(recipe.created_reagent, /datum/reagent/medicine/herbal/mercy_draught, "Mercy Draught recipe should create the universal trauma-clearing reagent.")

/datum/unit_test/defeat_debuff_fallback_duration_by_severity

/datum/unit_test/defeat_debuff_fallback_duration_by_severity/Run()
	var/mob/living/carbon/human/light_patient = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/severe_patient = allocate(/mob/living/carbon/human)
	var/datum/status_effect/debuff/defeat/light_effect = light_patient.apply_status_effect(/datum/status_effect/debuff/defeat/physical, null, DEFEAT_SEVERITY_LIGHT)
	var/datum/status_effect/debuff/defeat/severe_effect = severe_patient.apply_status_effect(/datum/status_effect/debuff/defeat/physical, null, DEFEAT_SEVERITY_SEVERE)

	TEST_ASSERT_EQUAL(light_effect.initial_duration, 10 MINUTES, "Light defeat trauma should decay slowly but sooner than worse trauma.")
	TEST_ASSERT_EQUAL(severe_effect.initial_duration, 60 MINUTES, "Severe defeat trauma should have the longest fallback decay.")

/datum/unit_test/defeat_trauma_subtypes_have_distinct_stat_profiles

/datum/unit_test/defeat_trauma_subtypes_have_distinct_stat_profiles/Run()
	var/mob/living/carbon/human/wound_patient = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/burn_patient = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/concussion_patient = allocate(/mob/living/carbon/human)
	var/datum/status_effect/debuff/defeat/wound_effect = wound_patient.apply_status_effect(/datum/status_effect/debuff/defeat/physical/wound, null, DEFEAT_SEVERITY_NORMAL)
	var/datum/status_effect/debuff/defeat/burn_effect = burn_patient.apply_status_effect(/datum/status_effect/debuff/defeat/physical/burn, null, DEFEAT_SEVERITY_NORMAL)
	var/datum/status_effect/debuff/defeat/concussion_effect = concussion_patient.apply_status_effect(/datum/status_effect/debuff/defeat/physical/concussion, null, DEFEAT_SEVERITY_NORMAL)

	TEST_ASSERT_NOTNULL(wound_effect.effectedstats[STAT_SPEED], "Wound trauma should pressure speed.")
	TEST_ASSERT_NOTNULL(burn_effect.effectedstats[STAT_CONSTITUTION], "Burn trauma should pressure constitution.")
	TEST_ASSERT_NOTNULL(concussion_effect.effectedstats[STAT_INTELLIGENCE], "Concussion trauma should pressure intelligence.")
	TEST_ASSERT_NULL(burn_effect.effectedstats[STAT_SPEED], "Burn trauma should not use the old generic speed profile.")

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

/datum/unit_test/defeat_trauma_escalates_on_repeat_defeat

/datum/unit_test/defeat_trauma_escalates_on_repeat_defeat/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)

	patient.apply_defeat_trauma_status(/datum/status_effect/debuff/defeat/pain, DEFEAT_SEVERITY_LIGHT)
	var/datum/status_effect/debuff/defeat/first = patient.has_status_effect(/datum/status_effect/debuff/defeat/pain)
	TEST_ASSERT_EQUAL(first.severity, DEFEAT_SEVERITY_LIGHT, "A first defeat should apply at the rolled severity.")

	patient.apply_defeat_trauma_status(/datum/status_effect/debuff/defeat/pain, DEFEAT_SEVERITY_LIGHT)
	var/datum/status_effect/debuff/defeat/second = patient.has_status_effect(/datum/status_effect/debuff/defeat/pain)
	TEST_ASSERT_EQUAL(second.severity, DEFEAT_SEVERITY_NORMAL, "An untreated repeat defeat should escalate one stage (light -> moderate).")

	patient.apply_defeat_trauma_status(/datum/status_effect/debuff/defeat/pain, DEFEAT_SEVERITY_LIGHT)
	var/datum/status_effect/debuff/defeat/third = patient.has_status_effect(/datum/status_effect/debuff/defeat/pain)
	TEST_ASSERT_EQUAL(third.severity, DEFEAT_SEVERITY_SEVERE, "A third untreated defeat should escalate to severe.")

	patient.apply_defeat_trauma_status(/datum/status_effect/debuff/defeat/pain, DEFEAT_SEVERITY_LIGHT)
	var/datum/status_effect/debuff/defeat/fourth = patient.has_status_effect(/datum/status_effect/debuff/defeat/pain)
	TEST_ASSERT_EQUAL(fourth.severity, DEFEAT_SEVERITY_SEVERE, "Severe trauma should cap and not overflow on further defeats.")

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
	monitor.horny_defeat_climax_threshold = 1

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

/datum/unit_test/defeat_ai_opt_in_component_sets_monitor

/datum/unit_test/defeat_ai_opt_in_component_sets_monitor/Run()
	var/mob/living/carbon/human/ai_body = allocate(/mob/living/carbon/human)
	TEST_ASSERT(!ai_body.defeat_system_is_eligible(), "Clientless, mindless AI bodies should not be eligible before explicit opt-in.")

	var/datum/component/defeat_ai_opt_in/opt_in = ai_body.AddComponent(/datum/component/defeat_ai_opt_in)
	TEST_ASSERT(ai_body.defeat_system_ai_opt_in, "The opt-in component should set the explicit AI defeat flag.")
	TEST_ASSERT_NOTNULL(ai_body.GetComponent(/datum/component/defeat_monitor), "The opt-in component should ensure the defeat monitor.")

	opt_in.UnregisterFromParent()
	TEST_ASSERT(!ai_body.defeat_system_ai_opt_in, "Removing the opt-in component should restore the previous opt-in flag.")

/datum/unit_test/defeat_threshold_quirk_modifier

/datum/unit_test/defeat_threshold_quirk_modifier/Run()
	var/mob/living/carbon/human/test_human = allocate(/mob/living/carbon/human)
	test_human.defeat_damage_threshold = 200
	TEST_ASSERT_EQUAL(test_human.get_effective_defeat_threshold(), 200, "With no fragility quirks the effective threshold should equal the base.")

	var/datum/quirk/vice/frail/frail_quirk = new()
	test_human.quirks += frail_quirk
	TEST_ASSERT_EQUAL(test_human.get_effective_defeat_threshold(), round(200 * 0.6), "A fragility quirk should lower the effective defeat threshold.")

	test_human.quirks -= frail_quirk
	qdel(frail_quirk)
	TEST_ASSERT_EQUAL(test_human.get_effective_defeat_threshold(), 200, "Removing the quirk should restore the base threshold.")

/datum/unit_test/defeat_rune_charge_cost_ladder

/datum/unit_test/defeat_rune_charge_cost_ladder/Run()
	var/list/full = defeat_rune_charge_cost(5)
	TEST_ASSERT_EQUAL(full["coin"], 1, "Spending from a full five charges should cost one coin.")
	TEST_ASSERT_EQUAL(full["blood"], 100, "Spending from a full five charges should cost 100 blood.")

	var/list/last = defeat_rune_charge_cost(1)
	TEST_ASSERT_EQUAL(last["coin"], 30, "Spending the final charge should cost thirty coin.")
	TEST_ASSERT_EQUAL(last["blood"], DEFEAT_RUNE_BLOOD_FRACTION_SENTINEL, "The final charge should bill a fraction of current blood, flagged by sentinel.")

	var/list/none = defeat_rune_charge_cost(0)
	TEST_ASSERT_EQUAL(none["coin"], 0, "With no charges available there is no charge cost.")

/datum/unit_test/defeat_collect_blood_tax_drains_blood

/datum/unit_test/defeat_collect_blood_tax_drains_blood/Run()
	var/mob/living/carbon/human/test_human = allocate(/mob/living/carbon/human)
	test_human.blood_volume = 500

	var/drawn = test_human.collect_blood_tax(120)
	TEST_ASSERT_EQUAL(drawn, 120, "Collecting a blood tax should report the blood drawn.")
	TEST_ASSERT_EQUAL(test_human.blood_volume, 380, "The blood tax should be removed from the mob's blood volume.")

	var/overdraw = test_human.collect_blood_tax(99999)
	TEST_ASSERT_EQUAL(overdraw, 380, "A blood tax larger than available blood should draw only what remains.")
	TEST_ASSERT_EQUAL(test_human.blood_volume, 0, "Over-drawing blood should leave the mob empty, not negative.")

/datum/unit_test/defeat_openspace_is_immediate_hazard

/datum/unit_test/defeat_openspace_is_immediate_hazard/Run()
	var/turf/original_turf = get_step(run_loc_floor_bottom_left, EAST)
	var/original_turf_type = original_turf.type
	var/list/original_baseturfs = original_turf.baseturfs
	var/mob/living/carbon/human/test_human = allocate(/mob/living/carbon/human, original_turf)

	TEST_ASSERT(!test_human.defeat_is_immediate_hazard(), "A normal floor should not count as an immediate defeat hazard.")

	var/turf/open/openspace/pit = original_turf.ChangeTurf(/turf/open/openspace)
	test_human.forceMove(pit)
	TEST_ASSERT(test_human.defeat_is_immediate_hazard(), "Open space (a pit/chasm) should count as an immediate defeat hazard.")

	pit.ChangeTurf(original_turf_type, original_baseturfs)

/datum/unit_test/defeat_injury_profiles_match_design

/datum/unit_test/defeat_injury_profiles_match_design/Run()
	var/mob/living/carbon/human/concussion_patient = allocate(/mob/living/carbon/human)
	var/datum/status_effect/debuff/defeat/concussion_effect = concussion_patient.apply_status_effect(/datum/status_effect/debuff/defeat/physical/concussion, null, DEFEAT_SEVERITY_NORMAL)
	TEST_ASSERT_EQUAL(concussion_effect.effectedstats[STAT_PERCEPTION], -3, "Concussion should drop perception by 3 at normal severity.")
	TEST_ASSERT_EQUAL(concussion_effect.effectedstats[STAT_INTELLIGENCE], -2, "Concussion should drop intelligence by 2 at normal severity.")
	TEST_ASSERT_EQUAL(concussion_effect.effectedstats[STAT_FORTUNE], -2, "Concussion should drop fortune by 2 at normal severity.")

	var/mob/living/carbon/human/body_patient = allocate(/mob/living/carbon/human)
	var/datum/status_effect/debuff/defeat/body_effect = body_patient.apply_status_effect(/datum/status_effect/debuff/defeat/physical/body, null, DEFEAT_SEVERITY_NORMAL)
	TEST_ASSERT_EQUAL(body_effect.effectedstats[STAT_CONSTITUTION], -3, "Internal bruising should drop constitution by 3 at normal severity.")
	TEST_ASSERT_EQUAL(body_effect.effectedstats[STAT_STRENGTH], -2, "Internal bruising should drop strength by 2 at normal severity.")

	var/mob/living/carbon/human/leg_patient = allocate(/mob/living/carbon/human)
	var/datum/status_effect/debuff/defeat/leg_effect = leg_patient.apply_status_effect(/datum/status_effect/debuff/defeat/physical/leg, null, DEFEAT_SEVERITY_NORMAL)
	TEST_ASSERT_EQUAL(leg_effect.effectedstats[STAT_SPEED], -4, "A leg injury should drop speed by 4 at normal severity.")

	var/mob/living/carbon/human/arm_patient = allocate(/mob/living/carbon/human)
	var/datum/status_effect/debuff/defeat/arm_effect = arm_patient.apply_status_effect(/datum/status_effect/debuff/defeat/physical/arm, null, DEFEAT_SEVERITY_NORMAL)
	TEST_ASSERT_EQUAL(arm_effect.effectedstats[STAT_STRENGTH], -4, "An arm injury should drop strength by 4 at normal severity.")

	var/mob/living/carbon/human/mana_patient = allocate(/mob/living/carbon/human)
	var/datum/status_effect/debuff/defeat/mana_effect = mana_patient.apply_status_effect(/datum/status_effect/debuff/defeat/rune, null, DEFEAT_SEVERITY_NORMAL)
	TEST_ASSERT_EQUAL(mana_effect.effectedstats[STAT_INTELLIGENCE], -4, "Mana-backlash should drop intelligence by 4 at normal severity.")

	var/mob/living/carbon/human/severe_patient = allocate(/mob/living/carbon/human)
	var/datum/status_effect/debuff/defeat/severe_effect = severe_patient.apply_status_effect(/datum/status_effect/debuff/defeat/physical/concussion, null, DEFEAT_SEVERITY_SEVERE)
	TEST_ASSERT_EQUAL(severe_effect.effectedstats[STAT_PERCEPTION], -5, "Severe concussion should scale perception up to -5.")

/datum/unit_test/defeat_leg_injury_blocks_jump

/datum/unit_test/defeat_leg_injury_blocks_jump/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	patient.apply_status_effect(/datum/status_effect/debuff/defeat/physical/leg, null, DEFEAT_SEVERITY_NORMAL)
	TEST_ASSERT(HAS_TRAIT(patient, TRAIT_DEFEAT_NO_JUMP), "A leg injury should block jumping while active.")
	patient.remove_status_effect(/datum/status_effect/debuff/defeat/physical/leg)
	TEST_ASSERT(!HAS_TRAIT(patient, TRAIT_DEFEAT_NO_JUMP), "Clearing the leg injury should restore jumping.")

/datum/unit_test/defeat_limb_zone_injuries_map_to_limb_trauma

/datum/unit_test/defeat_limb_zone_injuries_map_to_limb_trauma/Run()
	var/mob/living/carbon/human/arm_patient = allocate(/mob/living/carbon/human)
	arm_patient.defeat_system_ai_opt_in = TRUE
	var/obj/item/bodypart/arm = arm_patient.get_bodypart(BODY_ZONE_R_ARM)
	arm.create_injury(WOUND_BLUNT, 45, TRUE)
	arm_patient.enter_defeat(DEFEAT_REASON_DAMAGE, DEFEAT_SEVERITY_NORMAL)
	arm_patient.apply_defeat_snapshot_debuffs()
	TEST_ASSERT_NOTNULL(arm_patient.has_status_effect(/datum/status_effect/debuff/defeat/physical/arm), "Arm-zone injuries should produce arm trauma.")

	var/mob/living/carbon/human/leg_patient = allocate(/mob/living/carbon/human)
	leg_patient.defeat_system_ai_opt_in = TRUE
	var/obj/item/bodypart/leg = leg_patient.get_bodypart(BODY_ZONE_L_LEG)
	leg.create_injury(WOUND_BLUNT, 45, TRUE)
	leg_patient.enter_defeat(DEFEAT_REASON_DAMAGE, DEFEAT_SEVERITY_NORMAL)
	leg_patient.apply_defeat_snapshot_debuffs()
	TEST_ASSERT_NOTNULL(leg_patient.has_status_effect(/datum/status_effect/debuff/defeat/physical/leg), "Leg-zone injuries should produce leg trauma.")

/datum/unit_test/defeat_knockout_applies_and_clears_cleanly

/datum/unit_test/defeat_knockout_applies_and_clears_cleanly/Run()
	var/mob/living/carbon/human/test_human = allocate(/mob/living/carbon/human)
	var/datum/status_effect/defeat_knockout/knockout = test_human.apply_status_effect(/datum/status_effect/defeat_knockout)
	TEST_ASSERT_NOTNULL(knockout, "Knockout should apply.")
	TEST_ASSERT(HAS_TRAIT(test_human, TRAIT_PACIFISM), "Knockout should pacify the victim.")
	test_human.remove_status_effect(/datum/status_effect/defeat_knockout)
	TEST_ASSERT_NULL(test_human.has_status_effect(/datum/status_effect/defeat_knockout), "Knockout should clear without runtime.")
	TEST_ASSERT(!HAS_TRAIT(test_human, TRAIT_PACIFISM), "Clearing knockout should drop its pacifism.")

/datum/unit_test/defeat_horny_debuff_variants_are_valid

/datum/unit_test/defeat_horny_debuff_variants_are_valid/Run()
	// Loop so the random variant pick is exercised across multiple draws.
	for(var/i in 1 to 12)
		var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
		patient.defeat_system_ai_opt_in = TRUE
		patient.enter_defeat(DEFEAT_REASON_HORNY, DEFEAT_SEVERITY_NORMAL)
		patient.apply_defeat_snapshot_debuffs()
		var/datum/status_effect/debuff/defeat/horny/trauma = patient.has_status_effect(/datum/status_effect/debuff/defeat/horny)
		TEST_ASSERT_NOTNULL(trauma, "A horny defeat should always produce a horny trauma variant.")
		TEST_ASSERT(length(trauma.effectedstats) > 0, "Each horny debuff variant should carry a stat profile.")

/datum/unit_test/defeat_horny_threshold_is_randomized

/datum/unit_test/defeat_horny_threshold_is_randomized/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/grabber = allocate(/mob/living/carbon/human)
	victim.defeat_system_ai_opt_in = TRUE
	victim.pulledby = grabber
	grabber.pulling = victim
	grabber.grab_state = GRAB_AGGRESSIVE
	var/datum/component/defeat_monitor/monitor = victim.AddComponent(/datum/component/defeat_monitor)

	monitor.on_climax(victim, null, victim, grabber, grabber)
	TEST_ASSERT(monitor.horny_defeat_climax_threshold >= 10 && monitor.horny_defeat_climax_threshold <= 20, "Horny defeat threshold should roll within the 10-20 design band.")
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/defeat_knockout), "A single climax should not reach the randomized horny knockout threshold.")

/datum/unit_test/defeat_horny_instigator_combat_mode_gate

/datum/unit_test/defeat_horny_instigator_combat_mode_gate/Run()
	// NPC / AI instigators (not player-controlled) always count, combat mode or not.
	TEST_ASSERT(horny_defeat_instigator_counts(FALSE, FALSE), "A non-player instigator should count regardless of combat mode.")
	TEST_ASSERT(horny_defeat_instigator_counts(FALSE, TRUE), "A non-player instigator should count regardless of combat mode.")
	// A player instigator only counts while in combat mode.
	TEST_ASSERT(horny_defeat_instigator_counts(TRUE, TRUE), "A player instigator in combat mode should count.")
	TEST_ASSERT(!horny_defeat_instigator_counts(TRUE, FALSE), "A player instigator out of combat mode (consensual) should not count.")

/datum/unit_test/defeat_horny_warning_stage_escalates

/datum/unit_test/defeat_horny_warning_stage_escalates/Run()
	// No warning before the design's opening climax count.
	TEST_ASSERT_EQUAL(horny_defeat_warning_stage(1, 15), 0, "Warnings should not fire before the second climax.")
	// Warnings always open at DEFEAT_HORNY_WARNING_START, even for a low rolled threshold.
	TEST_ASSERT_EQUAL(horny_defeat_warning_stage(2, 15), 1, "The second climax should open the faint warning.")
	TEST_ASSERT_EQUAL(horny_defeat_warning_stage(2, 10), 1, "Even a low threshold opens at the second climax.")
	// Mid-encounter the warning builds (>= 60% of threshold).
	TEST_ASSERT_EQUAL(horny_defeat_warning_stage(9, 15), 2, "Past 60% of the threshold the warning should build.")
	// The climax right before collapse is the imminent warning.
	TEST_ASSERT_EQUAL(horny_defeat_warning_stage(14, 15), 3, "The climax before the threshold should warn of imminent collapse.")
	// A never-rolled threshold yields no warning.
	TEST_ASSERT_EQUAL(horny_defeat_warning_stage(5, 0), 0, "An unrolled threshold should produce no warning.")

/datum/unit_test/defeat_potion_feed_rescues_downed_victim

/datum/unit_test/defeat_potion_feed_rescues_downed_victim/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/healer = allocate(/mob/living/carbon/human)
	defeat_unit_place_adjacent(victim, healer, run_loc_floor_bottom_left)
	victim.apply_status_effect(/datum/status_effect/defeat_knockout)

	var/obj/item/reagent_containers/glass/bottle/vial/curative = allocate(/obj/item/reagent_containers/glass/bottle/vial, run_loc_floor_bottom_left)
	curative.reagents.add_reagent(/datum/reagent/medicine/herbal/symphitum_tea, 20)
	TEST_ASSERT(curative.defeat_try_potion_rescue(victim, healer), "Feeding a downed victim a curative drink should rescue them.")
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/defeat_knockout), "Potion rescue should clear the knockout.")

	var/mob/living/carbon/human/loner = allocate(/mob/living/carbon/human)
	loner.apply_status_effect(/datum/status_effect/defeat_knockout)
	TEST_ASSERT(!curative.defeat_try_potion_rescue(loner, loner), "A victim cannot revive themselves with their own drink.")
	TEST_ASSERT_NOTNULL(loner.has_status_effect(/datum/status_effect/defeat_knockout), "Self-administered drinks must leave the knockout in place.")

	var/mob/living/carbon/human/thirsty = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/water_bearer = allocate(/mob/living/carbon/human)
	defeat_unit_place_adjacent(thirsty, water_bearer, run_loc_floor_bottom_left)
	thirsty.apply_status_effect(/datum/status_effect/defeat_knockout)
	var/obj/item/reagent_containers/glass/bottle/vial/plain = allocate(/obj/item/reagent_containers/glass/bottle/vial, run_loc_floor_bottom_left)
	plain.reagents.add_reagent(/datum/reagent/water, 20)
	TEST_ASSERT(!plain.defeat_try_potion_rescue(thirsty, water_bearer), "Plain water is not curative and should not rescue.")
	TEST_ASSERT_NOTNULL(thirsty.has_status_effect(/datum/status_effect/defeat_knockout), "A non-curative drink must leave the knockout in place.")

/datum/unit_test/defeat_treatment_requires_zone

/datum/unit_test/defeat_treatment_requires_zone/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	TEST_ASSERT(!patient.defeat_treatment_zone_ok(DEFEAT_TREATMENT_MEDICAL), "Medical defeat cures should require a clinic zone (the test reservation is neither).")
	TEST_ASSERT(!patient.defeat_treatment_zone_ok(DEFEAT_TREATMENT_SPIRITUAL), "Spiritual defeat cures should require a church zone.")
	TEST_ASSERT(patient.defeat_treatment_zone_ok(DEFEAT_TREATMENT_UNIVERSAL), "The expensive universal cure should bypass the zone requirement.")

/obj/effect/landmark/kidnap/entrance/unit_test
	lair_tag = "unit_test_kidnap_lair"

/obj/effect/landmark/kidnap/escape/unit_test
	lair_tag = "unit_test_kidnap_lair"

/datum/unit_test/defeat_kidnap_to_lair_and_escape

/datum/unit_test/defeat_kidnap_to_lair_and_escape/Run()
	var/turf/lair_turf = get_step(run_loc_floor_bottom_left, EAST)
	var/turf/escape_turf = get_step(lair_turf, EAST)
	allocate(/obj/effect/landmark/kidnap/entrance/unit_test, lair_turf)
	var/obj/effect/landmark/kidnap/escape/unit_test/escape_marker = allocate(/obj/effect/landmark/kidnap/escape/unit_test, escape_turf)

	TEST_ASSERT(("unit_test_kidnap_lair" in GLOB.kidnap_entrance_markers), "Entrance markers should register under their lair tag.")

	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	victim.apply_status_effect(/datum/status_effect/defeat_knockout)

	TEST_ASSERT(victim.kidnap_to_lair("unit_test_kidnap_lair"), "Kidnap should succeed when a lair entrance exists for the tag.")
	TEST_ASSERT_EQUAL(get_turf(victim), lair_turf, "Kidnap should move the victim onto a lair entrance marker.")
	var/datum/component/kidnap_captivity/captivity = victim.GetComponent(/datum/component/kidnap_captivity)
	TEST_ASSERT_NOTNULL(captivity, "Kidnap should attach the captivity component.")

	captivity.release_from_knockout()
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/defeat_knockout), "Captivity release should clear the knockout state.")
	TEST_ASSERT(HAS_TRAIT_FROM(victim, TRAIT_PACIFISM, KIDNAP_TRAIT), "A released captive should be held in captive pacifism.")

	escape_marker.Crossed(victim)
	TEST_ASSERT_NULL(victim.GetComponent(/datum/component/kidnap_captivity), "Reaching an escape marker should end captivity.")
	TEST_ASSERT(!HAS_TRAIT_FROM(victim, TRAIT_PACIFISM, KIDNAP_TRAIT), "Escaping should strip the captive pacifism.")

/datum/unit_test/defeat_faction_mob_kidnaps_defeated_prey

/datum/unit_test/defeat_faction_mob_kidnaps_defeated_prey/Run()
	var/turf/lair_turf = get_step(run_loc_floor_bottom_left, EAST)
	allocate(/obj/effect/landmark/kidnap/entrance/unit_test, lair_turf)

	var/mob/living/carbon/human/captor = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	defeat_unit_place_adjacent(victim, captor, run_loc_floor_bottom_left)

	victim.apply_status_effect(/datum/status_effect/defeat_knockout)
	victim.recent_damage_source_attacker_weakref = WEAKREF(captor)
	// Kidnapping only claims horny-defeated prey, so stamp the snapshot the gate checks.
	victim.last_defeat_snapshot = new /datum/defeat_snapshot
	victim.last_defeat_snapshot.reason = DEFEAT_REASON_HORNY

	TEST_ASSERT(!captor.can_kidnap_defeated_prey(victim), "A mob with no lair tag cannot kidnap.")
	captor.kidnap_lair_tag = "unit_test_kidnap_lair"
	TEST_ASSERT(captor.can_kidnap_defeated_prey(victim), "A faction captor beside prey it just defeated should be able to kidnap.")

	TEST_ASSERT(captor.try_kidnap_defeated_prey(victim), "The kidnap attempt should succeed.")
	TEST_ASSERT_NOTNULL(victim.GetComponent(/datum/component/kidnap_captivity), "The kidnapped victim should be in captivity.")
	TEST_ASSERT(!captor.can_kidnap_defeated_prey(victim), "An already-captive victim cannot be kidnapped again.")

/datum/unit_test/defeat_kidnap_only_claims_horny_prey

/datum/unit_test/defeat_kidnap_only_claims_horny_prey/Run()
	var/turf/lair_turf = get_step(run_loc_floor_bottom_left, EAST)
	allocate(/obj/effect/landmark/kidnap/entrance/unit_test, lair_turf)

	var/mob/living/carbon/human/captor = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	defeat_unit_place_adjacent(victim, captor, run_loc_floor_bottom_left)
	captor.kidnap_lair_tag = "unit_test_kidnap_lair"

	victim.apply_status_effect(/datum/status_effect/defeat_knockout)
	victim.recent_damage_source_attacker_weakref = WEAKREF(captor)
	// A plain beatdown defeat - the lighthearted gate must refuse to drag them off.
	victim.last_defeat_snapshot = new /datum/defeat_snapshot
	victim.last_defeat_snapshot.reason = DEFEAT_REASON_DAMAGE
	TEST_ASSERT(!captor.can_kidnap_defeated_prey(victim), "A regular (non-horny) defeat should never be kidnappable.")

	// Switch the same victim's defeat to a horny one and now they can be claimed.
	victim.last_defeat_snapshot.reason = DEFEAT_REASON_HORNY
	TEST_ASSERT(captor.can_kidnap_defeated_prey(victim), "A horny defeat beside its captor should be kidnappable.")

/datum/unit_test/defeat_kidnap_candidate_ignores_distance

/datum/unit_test/defeat_kidnap_candidate_ignores_distance/Run()
	var/mob/living/carbon/human/captor = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	captor.kidnap_lair_tag = "unit_test_kidnap_lair"
	victim.apply_status_effect(/datum/status_effect/defeat_knockout)
	victim.recent_damage_source_attacker_weakref = WEAKREF(captor)
	victim.last_defeat_snapshot = new /datum/defeat_snapshot
	victim.last_defeat_snapshot.reason = DEFEAT_REASON_HORNY

	// The AI candidate check holds without adjacency, so a captor can path toward distant prey...
	TEST_ASSERT(captor.is_kidnap_candidate(victim), "A horny-defeated victim should be a kidnap candidate regardless of distance.")
	// ...while a non-horny defeat is never a candidate, and a mob with no lair never kidnaps.
	victim.last_defeat_snapshot.reason = DEFEAT_REASON_DAMAGE
	TEST_ASSERT(!captor.is_kidnap_candidate(victim), "A non-horny defeat is never a kidnap candidate.")
	victim.last_defeat_snapshot.reason = DEFEAT_REASON_HORNY
	captor.kidnap_lair_tag = null
	TEST_ASSERT(!captor.is_kidnap_candidate(victim), "A mob with no lair tag is never a kidnap candidate.")

/datum/unit_test/defeat_kidnap_blocked_when_outnumbered

/datum/unit_test/defeat_kidnap_blocked_when_outnumbered/Run()
	var/mob/living/carbon/human/captor = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/rescuer_one = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/rescuer_two = allocate(/mob/living/carbon/human)
	defeat_unit_place_adjacent(victim, captor, run_loc_floor_bottom_left)
	rescuer_one.forceMove(get_turf(captor))
	rescuer_two.forceMove(get_turf(captor))

	captor.faction = list("kidnap_unit_test_captor")
	captor.kidnap_lair_tag = "unit_test_kidnap_lair"
	victim.apply_status_effect(/datum/status_effect/defeat_knockout)
	victim.recent_damage_source_attacker_weakref = WEAKREF(captor)
	// Kidnapping only claims horny-defeated prey, so stamp the snapshot the gate checks.
	victim.last_defeat_snapshot = new /datum/defeat_snapshot
	victim.last_defeat_snapshot.reason = DEFEAT_REASON_HORNY

	TEST_ASSERT(captor.kidnap_is_outnumbered(victim), "Two nearby rescuers against a lone captor should count as outnumbered.")
	TEST_ASSERT(!captor.can_kidnap_defeated_prey(victim), "An outnumbered captor should not be able to drag prey off.")

/datum/unit_test/defeat_distress_npc_spawns_and_rewards

/datum/unit_test/defeat_distress_npc_spawns_and_rewards/Run()
	var/turf/spot = get_step(run_loc_floor_bottom_left, EAST)
	var/mob/living/carbon/human/npc_in_distress/captive = allocate(/mob/living/carbon/human/npc_in_distress, spot)
	var/datum/component/npc_in_distress/distress = captive.GetComponent(/datum/component/npc_in_distress)
	TEST_ASSERT_NOTNULL(distress, "An ambient distress NPC should carry the distress component.")

	var/mob/living/carbon/human/rescuer = allocate(/mob/living/carbon/human)
	distress.complete_rescue(rescuer)
	var/coins = 0
	for(var/obj/item/coin/silver/coin in spot)
		coins++
	TEST_ASSERT(coins >= NPC_DISTRESS_REWARD_MIN && coins <= NPC_DISTRESS_REWARD_MAX, "Rescue should drop the silver reward on the ground.")
	TEST_ASSERT(QDELETED(captive), "A rescued distress NPC should be removed (taken by the Rune).")
	for(var/obj/item/coin/silver/coin in spot)
		qdel(coin)

/datum/unit_test/defeat_distress_drop_carried_clears_hands

/datum/unit_test/defeat_distress_drop_carried_clears_hands/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/obj/item/coin/silver/trinket = allocate(/obj/item/coin/silver, get_turf(victim))
	victim.put_in_hands(trinket)
	TEST_ASSERT((trinket in victim.held_items), "Setup: the trinket should start in hand.")
	victim.npc_in_distress_drop_carried()
	TEST_ASSERT(!(trinket in victim.held_items), "Surrender should drop carried items out of the hands.")

/datum/unit_test/defeat_kidnap_remembers_captor_faction

/datum/unit_test/defeat_kidnap_remembers_captor_faction/Run()
	var/turf/lair_turf = get_step(run_loc_floor_bottom_left, EAST)
	allocate(/obj/effect/landmark/kidnap/entrance/unit_test, lair_turf)
	var/mob/living/carbon/human/captor = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	defeat_unit_place_adjacent(victim, captor, run_loc_floor_bottom_left)
	captor.faction = list("greenskin_unit_test")
	captor.kidnap_lair_tag = "unit_test_kidnap_lair"
	victim.apply_status_effect(/datum/status_effect/defeat_knockout)
	victim.recent_damage_source_attacker_weakref = WEAKREF(captor)
	// Kidnapping only claims horny-defeated prey, so stamp the snapshot the gate checks.
	victim.last_defeat_snapshot = new /datum/defeat_snapshot
	victim.last_defeat_snapshot.reason = DEFEAT_REASON_HORNY

	TEST_ASSERT(captor.try_kidnap_defeated_prey(victim), "Kidnap should succeed.")
	var/datum/component/kidnap_captivity/captivity = victim.GetComponent(/datum/component/kidnap_captivity)
	TEST_ASSERT_NOTNULL(captivity, "Captivity should be attached after a kidnap.")
	TEST_ASSERT(("greenskin_unit_test" in captivity.captor_faction), "Captivity should remember the captor's faction so a surrendered captive shares it.")

/datum/unit_test/defeat_kidnap_climaxes_offer_surrender

/datum/unit_test/defeat_kidnap_climaxes_offer_surrender/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/datum/component/kidnap_captivity/captivity = victim.AddComponent(/datum/component/kidnap_captivity, "unit_test_kidnap_lair")
	TEST_ASSERT_NOTNULL(captivity, "Captivity component should attach.")
	TEST_ASSERT(!captivity.surrender_available, "Surrender should not be offered before enough climaxes.")

	for(var/i in 1 to KIDNAP_SURRENDER_CLIMAXES)
		captivity.on_captive_climax(victim, null, victim, null, null)
	TEST_ASSERT(captivity.surrender_available, "Enough climaxes endured in captivity should offer surrender early.")

/datum/unit_test/defeat_healing_spring_rescues

/datum/unit_test/defeat_healing_spring_rescues/Run()
	var/turf/spring_turf = get_step(run_loc_floor_bottom_left, EAST)
	var/obj/structure/well/fountain/healing/spring = allocate(/obj/structure/well/fountain/healing, spring_turf)
	var/turf/victim_turf = get_step(spring_turf, EAST)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, victim_turf)
	victim.apply_status_effect(/datum/status_effect/defeat_knockout)

	spring.process(1)
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/defeat_knockout), "A healing spring should free a defeated mob lingering beside it.")

/datum/unit_test/defeat_holy_communion_rescues_downed

/datum/unit_test/defeat_holy_communion_rescues_downed/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/saint = allocate(/mob/living/carbon/human)
	defeat_unit_place_adjacent(victim, saint, run_loc_floor_bottom_left)
	var/datum/component/defeat_monitor/monitor = victim.AddComponent(/datum/component/defeat_monitor)
	victim.apply_status_effect(/datum/status_effect/defeat_knockout)
	ADD_TRAIT(saint, TRAIT_HOLY, TRAIT_GENERIC)

	monitor.on_climax(victim, null, victim, saint, saint)
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/defeat_knockout), "A holy character's communion should free a downed victim.")

	var/mob/living/carbon/human/victim_two = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/layperson = allocate(/mob/living/carbon/human)
	defeat_unit_place_adjacent(victim_two, layperson, run_loc_floor_bottom_left)
	var/datum/component/defeat_monitor/monitor_two = victim_two.AddComponent(/datum/component/defeat_monitor)
	victim_two.apply_status_effect(/datum/status_effect/defeat_knockout)

	monitor_two.on_climax(victim_two, null, victim_two, layperson, layperson)
	TEST_ASSERT_NOTNULL(victim_two.has_status_effect(/datum/status_effect/defeat_knockout), "A non-holy partner's climax should not free the victim.")

/datum/unit_test/defeat_monitor_attaches_once_controlled

/datum/unit_test/defeat_monitor_attaches_once_controlled/Run()
	var/mob/living/carbon/human/player = allocate(/mob/living/carbon/human)
	player.defeat_mode = DEFEAT_MODE_KO_RUNE
	// Mirrors apply_prefs_to running before the client/mind is attached: not yet eligible -> no monitor.
	player.ensure_defeat_monitor()
	TEST_ASSERT_NULL(player.GetComponent(/datum/component/defeat_monitor), "Without a client or mind, the monitor must not attach (the spawn-time pref-cache case).")

	// Once the player actually controls the body (as at Login), it must attach.
	player.mind = allocate(/datum/mind, "defeat-monitor-attach-test")
	player.mind.current = player
	player.ensure_defeat_monitor()
	TEST_ASSERT_NOTNULL(player.GetComponent(/datum/component/defeat_monitor), "With a mind present, ensure_defeat_monitor must attach the defeat monitor.")

	player.mind.current = null
	player.mind = null

/datum/unit_test/defeat_pet_rescues_downed_ally

/datum/unit_test/defeat_pet_rescues_downed_ally/Run()
	var/mob/living/carbon/human/pet = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/fallen = allocate(/mob/living/carbon/human)
	defeat_unit_place_adjacent(fallen, pet, run_loc_floor_bottom_left)
	fallen.apply_status_effect(/datum/status_effect/defeat_knockout)

	TEST_ASSERT(pet.try_rescue_downed_ally(fallen), "A pet beside a downed ally should free them.")
	TEST_ASSERT_NULL(fallen.has_status_effect(/datum/status_effect/defeat_knockout), "Pet rescue should clear the ally's knockout.")

	var/mob/living/carbon/human/standing = allocate(/mob/living/carbon/human)
	standing.forceMove(get_turf(pet))
	TEST_ASSERT(!pet.try_rescue_downed_ally(standing), "A pet cannot 'rescue' someone who is not defeated.")

/datum/unit_test/defeat_revive_time_scales_with_medicine

/datum/unit_test/defeat_revive_time_scales_with_medicine/Run()
	var/mob/living/carbon/human/medic = allocate(/mob/living/carbon/human)

	medic.set_skillrank(/datum/skill/misc/medicine, SKILL_RANK_NONE, TRUE)
	TEST_ASSERT_EQUAL(medic.defeat_revive_time(), DEFEAT_REVIVE_TIME_MAX, "No medical skill should take the longest to revive.")

	medic.set_skillrank(/datum/skill/misc/medicine, SKILL_RANK_LEGENDARY, TRUE)
	TEST_ASSERT_EQUAL(medic.defeat_revive_time(), DEFEAT_REVIVE_TIME_MIN, "Legendary medicine should revive fastest.")

	medic.set_skillrank(/datum/skill/misc/medicine, SKILL_RANK_JOURNEYMAN, TRUE)
	var/mid = medic.defeat_revive_time()
	TEST_ASSERT(mid > DEFEAT_REVIVE_TIME_MIN && mid < DEFEAT_REVIVE_TIME_MAX, "Middling medicine should land between the extremes.")
