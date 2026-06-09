/datum/unit_test/mage_hand_targeting
	procs_tested = list(/datum/action/cooldown/spell/mage_hand/is_valid_target)

#ifdef FOCUS_MAGE_HAND_TEST
/datum/unit_test/mage_hand_targeting
	focus = TRUE
#endif

/datum/unit_test/mage_hand_session_replaces_previous_tether
	procs_tested = list(/datum/action/cooldown/spell/mage_hand/cast)

#ifdef FOCUS_MAGE_HAND_TEST
/datum/unit_test/mage_hand_session_replaces_previous_tether
	focus = TRUE
#endif

/datum/unit_test/mage_hand_remote_action_gating
	procs_tested = list(/datum/sex_session/proc/can_perform_action)

#ifdef FOCUS_MAGE_HAND_TEST
/datum/unit_test/mage_hand_remote_action_gating
	focus = TRUE
#endif

/datum/unit_test/mage_hand_remote_context_invalidates
	procs_tested = list(/datum/sex_session/proc/can_perform_action)

#ifdef FOCUS_MAGE_HAND_TEST
/datum/unit_test/mage_hand_remote_context_invalidates
	focus = TRUE
#endif

/datum/unit_test/mage_hand_overlay_lifecycle
	procs_tested = list(/datum/sex_remote_context/mage_hand/show_action_overlay)

#ifdef FOCUS_MAGE_HAND_TEST
/datum/unit_test/mage_hand_overlay_lifecycle
	focus = TRUE
#endif

/datum/unit_test/mage_hand_scry_upgrade_gate
	procs_tested = list(/proc/can_start_scrying_mage_hand)

#ifdef FOCUS_MAGE_HAND_TEST
/datum/unit_test/mage_hand_scry_upgrade_gate
	focus = TRUE
#endif

/datum/unit_test/mage_hand_scry_start_remote_context
	procs_tested = list(/proc/start_scrying_mage_hand)

#ifdef FOCUS_MAGE_HAND_TEST
/datum/unit_test/mage_hand_scry_start_remote_context
	focus = TRUE
#endif

/datum/unit_test/mage_hand_remote_messages_are_anonymous
	procs_tested = list(/datum/sex_remote_context/mage_hand/proc/sanitize_action_message)

#ifdef FOCUS_MAGE_HAND_TEST
/datum/unit_test/mage_hand_remote_messages_are_anonymous
	focus = TRUE
#endif

/datum/unit_test/mage_hand_remote_visible_message_suppression
	procs_tested = list(
		/datum/sex_session/proc/begin_remote_action_visible_message_suppression,
		/datum/sex_session/proc/end_remote_action_visible_message_suppression,
	)

#ifdef FOCUS_MAGE_HAND_TEST
/datum/unit_test/mage_hand_remote_visible_message_suppression
	focus = TRUE
#endif

/datum/unit_test/mage_hand_line_of_sight_grace
	procs_tested = list(/datum/sex_remote_context/proc/has_required_line_of_sight)
	var/turf/line_of_sight_blocker
	var/original_blocker_turf_type
	var/original_blocker_baseturfs

#ifdef FOCUS_MAGE_HAND_TEST
/datum/unit_test/mage_hand_line_of_sight_grace
	focus = TRUE
#endif

/datum/unit_test/mage_hand_visible_range_grace
	procs_tested = list(/datum/sex_remote_context/proc/has_required_line_of_sight)

#ifdef FOCUS_MAGE_HAND_TEST
/datum/unit_test/mage_hand_visible_range_grace
	focus = TRUE
#endif

/datum/unit_test/mage_hand_line_of_sight_grace/Destroy()
	if(line_of_sight_blocker && original_blocker_turf_type)
		line_of_sight_blocker.ChangeTurf(original_blocker_turf_type, original_blocker_baseturfs)
	return ..()

/datum/unit_test/mage_hand_targeting/Run()
	var/mob/living/carbon/human/caster = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	place_for_mage_hand(caster, target, 4)

	var/datum/action/cooldown/spell/mage_hand/spell = allocate(/datum/action/cooldown/spell/mage_hand)
	spell.owner = caster

	TEST_ASSERT(spell.is_valid_target(target), "Mage Hand should accept a visible living target in range.")
	TEST_ASSERT(!spell.is_valid_target(caster), "Mage Hand should not target the caster.")

	target.stat = DEAD
	TEST_ASSERT(!spell.is_valid_target(target), "Mage Hand should reject dead targets.")
	target.stat = CONSCIOUS

	place_for_mage_hand(caster, target, spell.cast_range + 1)
	TEST_ASSERT(!spell.is_valid_target(target), "Mage Hand should reject targets outside cast range.")

/datum/unit_test/mage_hand_session_replaces_previous_tether/Run()
	var/mob/living/carbon/human/caster = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/first_target = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/second_target = allocate(/mob/living/carbon/human)
	place_for_mage_hand(caster, first_target, 3)
	second_target.forceMove(get_step(caster, NORTH))

	var/datum/action/cooldown/spell/mage_hand/spell = allocate(/datum/action/cooldown/spell/mage_hand)
	spell.owner = caster

	spell.cast(first_target)
	var/datum/sex_session/first_session = get_sex_session(caster, first_target)
	TEST_ASSERT_NOTNULL(first_session, "Mage Hand should create a sex session with the first target.")
	TEST_ASSERT_NOTNULL(first_session.remote_context, "Mage Hand should attach a remote context to the first session.")

	spell.cast(second_target)
	var/datum/sex_session/second_session = get_sex_session(caster, second_target)
	TEST_ASSERT_NOTNULL(second_session, "Mage Hand should create a sex session with the second target.")
	TEST_ASSERT_NULL(first_session.remote_context, "Recasting Mage Hand should clear the caster's previous remote tether.")
	TEST_ASSERT_NOTNULL(second_session.remote_context, "Recasting Mage Hand should attach the new remote tether.")

/datum/unit_test/mage_hand_remote_action_gating/Run()
	var/mob/living/carbon/human/caster = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	place_for_mage_hand(caster, target, 4)

	var/datum/sex_session/session = caster.start_sex_session(target, FALSE)
	var/datum/sex_remote_context/mage_hand/context = allocate(/datum/sex_remote_context/mage_hand, caster, target)
	session.set_remote_context(context)

	TEST_ASSERT(session.can_perform_action(/datum/sex_action/spanking), "Mage Hand should let curated hand actions run at range.")
	TEST_ASSERT(!session.can_perform_action(/datum/sex_action/kissing), "Mage Hand should not let non-curated actions run at range.")

/datum/unit_test/mage_hand_remote_context_invalidates/Run()
	var/mob/living/carbon/human/caster = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	place_for_mage_hand(caster, target, 4)

	var/datum/sex_session/session = caster.start_sex_session(target, FALSE)
	var/datum/sex_remote_context/mage_hand/context = allocate(/datum/sex_remote_context/mage_hand, caster, target)
	session.set_remote_context(context)

	TEST_ASSERT(session.can_perform_action(/datum/sex_action/spanking), "Test setup should allow ranged Mage Hand action before expiry.")
	context.expires_at = world.time - 1
	TEST_ASSERT(!session.can_perform_action(/datum/sex_action/spanking), "Expired Mage Hand context should stop enabling ranged actions.")
	TEST_ASSERT_NULL(session.remote_context, "Expired Mage Hand context should clear itself from the session.")

/datum/unit_test/mage_hand_overlay_lifecycle/Run()
	var/mob/living/carbon/human/caster = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	place_for_mage_hand(caster, target, 4)

	var/datum/sex_session/session = caster.start_sex_session(target, FALSE)
	var/datum/sex_remote_context/mage_hand/context = allocate(/datum/sex_remote_context/mage_hand, caster, target)
	session.set_remote_context(context)

	var/datum/sex_action/spanking/action = allocate(/datum/sex_action/spanking)
	context.show_action_overlay(action)
	TEST_ASSERT(context.get_active_overlay_count() > 0, "Mage Hand should add placeholder overlays for active human-target actions.")

	context.clear_action_overlay(action)
	TEST_ASSERT_EQUAL(context.get_active_overlay_count(), 0, "Mage Hand should remove placeholder overlays when the action ends.")

	var/mob/living/simple_animal/nonhuman_target = allocate(/mob/living/simple_animal)
	place_for_mage_hand(caster, nonhuman_target, 4)
	var/datum/sex_remote_context/mage_hand/nonhuman_context = allocate(/datum/sex_remote_context/mage_hand, caster, nonhuman_target)
	nonhuman_context.show_action_overlay(action)
	TEST_ASSERT_EQUAL(nonhuman_context.get_active_overlay_count(), 0, "Mage Hand should skip overlays on nonhuman living targets.")

/datum/unit_test/mage_hand_scry_upgrade_gate/Run()
	var/mob/living/carbon/human/caster = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	place_for_mage_hand(caster, target, 10)

	TEST_ASSERT(!can_start_scrying_mage_hand(caster, target), "Scrying Mage Hand should be locked without its upgrade.")

	var/datum/action/cooldown/spell/mage_hand/base_spell = allocate(/datum/action/cooldown/spell/mage_hand)
	base_spell.Grant(caster)
	TEST_ASSERT(!can_start_scrying_mage_hand(caster, target), "Regular Mage Hand alone should not unlock scrying projection.")

	var/datum/action/cooldown/spell/mage_hand/scrying/upgrade = allocate(/datum/action/cooldown/spell/mage_hand/scrying)
	upgrade.Grant(caster)
	TEST_ASSERT(can_start_scrying_mage_hand(caster, target), "Scrying Mage Hand should unlock remote projection through a scrying eye.")
	TEST_ASSERT(!can_start_scrying_mage_hand(caster, caster), "Scrying Mage Hand should not target the caster.")

/datum/unit_test/mage_hand_scry_start_remote_context/Run()
	var/mob/living/carbon/human/caster = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	place_for_mage_hand(caster, target, 10)

	var/datum/action/cooldown/spell/mage_hand/scrying/upgrade = allocate(/datum/action/cooldown/spell/mage_hand/scrying)
	upgrade.Grant(caster)

	TEST_ASSERT(start_scrying_mage_hand(caster, target, FALSE), "Scrying Mage Hand should start a remote session when unlocked.")
	var/datum/sex_session/session = get_sex_session(caster, target)
	TEST_ASSERT_NOTNULL(session, "Scrying Mage Hand should create or reuse a sex session.")
	TEST_ASSERT(istype(session.remote_context, /datum/sex_remote_context/mage_hand), "Scrying Mage Hand should attach a Mage Hand context.")

	var/datum/sex_remote_context/mage_hand/context = session.remote_context
	TEST_ASSERT(!context.requires_range, "Scrying Mage Hand context should not require body-to-target range.")
	TEST_ASSERT(!context.requires_line_of_sight, "Scrying Mage Hand context should not require body-to-target line of sight.")
	TEST_ASSERT(session.can_perform_action(/datum/sex_action/spanking), "Scrying Mage Hand should allow curated hand actions at scrying distance.")

/datum/unit_test/mage_hand_remote_messages_are_anonymous/Run()
	var/mob/living/carbon/human/caster = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	caster.real_name = "Scry Tester"
	caster.name = "Scry Tester"
	place_for_mage_hand(caster, target, 4)

	var/datum/sex_session/session = caster.start_sex_session(target, FALSE)
	var/datum/sex_remote_context/mage_hand/context = allocate(/datum/sex_remote_context/mage_hand, caster, target)
	session.set_remote_context(context)

	var/sanitized = context.sanitize_action_message("[caster.real_name] performs an action on [target].", caster)
	TEST_ASSERT(findtext(sanitized, "Someone"), "Mage Hand message sanitization should use anonymous actor wording.")
	TEST_ASSERT(!findtext(sanitized, caster.real_name), "Mage Hand messages should not reveal the caster name.")

	var/datum/sex_action/spanking/action = allocate(/datum/sex_action/spanking)
	TEST_ASSERT(!action.can_show_action_message(caster, target), "Curated actions should not emit their normal local visible messages during Mage Hand.")

	var/datum/sex_action/masturbate/other/vagina/vagina_action = allocate(/datum/sex_action/masturbate/other/vagina)
	var/target_message = context.get_action_message(vagina_action, MAGE_HAND_ACTION_MESSAGE_PERFORM, TRUE)
	TEST_ASSERT_EQUAL(target_message, "Someone's ghostly hand continues fingering my pussy.", "Mage Hand target messages should turn action names into readable phrases.")
	TEST_ASSERT(!findtext(target_message, "their pussy on me"), "Mage Hand target messages should not paste the raw action name into an 'on me' sentence.")

/datum/unit_test/mage_hand_remote_visible_message_suppression/Run()
	var/mob/living/carbon/human/caster = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	place_for_mage_hand(caster, target, 4)

	var/datum/sex_session/session = caster.start_sex_session(target, FALSE)
	var/datum/sex_remote_context/mage_hand/context = allocate(/datum/sex_remote_context/mage_hand, caster, target)
	session.set_remote_context(context)

	var/datum/sex_action/spanking/action = allocate(/datum/sex_action/spanking)
	TEST_ASSERT_EQUAL(caster.visible_message_suppression_count, 0, "Test setup should start with no visible message suppression.")
	TEST_ASSERT_EQUAL(target.visible_message_suppression_count, 0, "Test setup should start with no target visible message suppression.")

	TEST_ASSERT(session.begin_remote_action_visible_message_suppression(action), "Mage Hand should enable central visible_message suppression for curated remote actions.")
	TEST_ASSERT_EQUAL(caster.visible_message_suppression_count, 1, "Remote action suppression should apply to the acting mob.")
	TEST_ASSERT_EQUAL(target.visible_message_suppression_count, 1, "Remote action suppression should apply to the target mob.")

	session.end_remote_action_visible_message_suppression(TRUE)
	TEST_ASSERT_EQUAL(caster.visible_message_suppression_count, 0, "Remote action suppression should unwind on the acting mob.")
	TEST_ASSERT_EQUAL(target.visible_message_suppression_count, 0, "Remote action suppression should unwind on the target mob.")

	var/datum/sex_action/kissing/kiss = allocate(/datum/sex_action/kissing)
	TEST_ASSERT(!session.begin_remote_action_visible_message_suppression(kiss), "Non-curated actions should not enter the remote suppression scope.")

/datum/unit_test/mage_hand_line_of_sight_grace/Run()
	var/mob/living/carbon/human/caster = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	place_for_mage_hand(caster, target, 2)

	line_of_sight_blocker = get_step(run_loc_floor_bottom_left, EAST)
	original_blocker_turf_type = line_of_sight_blocker.type
	original_blocker_baseturfs = islist(line_of_sight_blocker.baseturfs) ? line_of_sight_blocker.baseturfs.Copy() : line_of_sight_blocker.baseturfs
	line_of_sight_blocker = line_of_sight_blocker.ChangeTurf(/turf/closed/wall)

	var/datum/sex_session/session = caster.start_sex_session(target, FALSE)
	var/datum/sex_remote_context/mage_hand/context = allocate(/datum/sex_remote_context/mage_hand, caster, target)
	session.set_remote_context(context)

	TEST_ASSERT(!can_see(caster, target, context.range), "Test setup should block line of sight while keeping the target in range.")
	TEST_ASSERT(session.can_perform_action(/datum/sex_action/spanking), "Freshly broken Mage Hand line of sight should stay valid during the grace period.")
	TEST_ASSERT(context.line_of_sight_lost_at > 0, "Broken line of sight should start the grace timer.")

	context.line_of_sight_lost_at = world.time - (context.line_of_sight_break_grace - 1)
	TEST_ASSERT(session.can_perform_action(/datum/sex_action/spanking), "Mage Hand should stay valid until the full line-of-sight grace expires.")

	line_of_sight_blocker = line_of_sight_blocker.ChangeTurf(original_blocker_turf_type, original_blocker_baseturfs)
	TEST_ASSERT(can_see(caster, target, context.range), "Test setup should restore line of sight.")
	TEST_ASSERT(session.can_perform_action(/datum/sex_action/spanking), "Restored line of sight should keep Mage Hand valid.")
	TEST_ASSERT_EQUAL(context.line_of_sight_lost_at, 0, "Restored line of sight should clear the grace timer.")

	line_of_sight_blocker = line_of_sight_blocker.ChangeTurf(/turf/closed/wall)
	context.line_of_sight_lost_at = world.time - (context.line_of_sight_break_grace + 1)
	TEST_ASSERT(!session.can_perform_action(/datum/sex_action/spanking), "Mage Hand should stop once line of sight has been broken for the full grace period.")
	TEST_ASSERT_NULL(session.remote_context, "Expired Mage Hand line-of-sight grace should clear the remote context.")

/datum/unit_test/mage_hand_visible_range_grace/Run()
	var/mob/living/carbon/human/caster = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	place_for_mage_hand(caster, target, 2)

	var/datum/sex_session/session = caster.start_sex_session(target, FALSE)
	var/datum/sex_remote_context/mage_hand/context = allocate(/datum/sex_remote_context/mage_hand, caster, target)
	session.set_remote_context(context)

	place_for_mage_hand(caster, target, context.range + 1)
	TEST_ASSERT(!can_see(caster, target, context.range), "Test setup should move the target out of Mage Hand visible range.")
	TEST_ASSERT(session.can_perform_action(/datum/sex_action/spanking), "Mage Hand should stay valid during grace when the target leaves visible range.")
	TEST_ASSERT(context.line_of_sight_lost_at > 0, "Leaving visible range should start the line-of-sight grace timer.")

	place_for_mage_hand(caster, target, context.range)
	TEST_ASSERT(can_see(caster, target, context.range), "Test setup should move the target back into Mage Hand visible range.")
	TEST_ASSERT(session.can_perform_action(/datum/sex_action/spanking), "Restored visible range should keep Mage Hand valid.")
	TEST_ASSERT_EQUAL(context.line_of_sight_lost_at, 0, "Restored visible range should clear the grace timer.")

	place_for_mage_hand(caster, target, context.range + 1)
	context.line_of_sight_lost_at = world.time - (context.line_of_sight_break_grace + 1)
	TEST_ASSERT(!session.can_perform_action(/datum/sex_action/spanking), "Mage Hand should stop once the target stays outside visible range for the full grace period.")
	TEST_ASSERT_NULL(session.remote_context, "Expired visible-range grace should clear the remote context.")

/datum/unit_test/proc/place_for_mage_hand(mob/living/caster, mob/living/target, distance)
	caster.forceMove(run_loc_floor_bottom_left)
	var/turf/target_turf = run_loc_floor_bottom_left
	for(var/i in 1 to distance)
		target_turf = get_step(target_turf, EAST)
	target.forceMove(target_turf)
