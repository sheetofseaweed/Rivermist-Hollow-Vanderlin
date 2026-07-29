/// Tests for the sex session TGUI data + act plumbing.
/datum/unit_test/sex_scene_controller_tgui_data/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/datum/sex_scene_controller/session = user.open_sex_scene(user, show_ui = FALSE)
	TEST_ASSERT_NOTNULL(session, "open_sex_scene should return a self-session")

	var/list/data = session.ui_data(user)
	TEST_ASSERT(islist(data["status_lines"]), "status_lines should be a list")
	TEST_ASSERT(islist(data["actions"]), "actions should be a list")
	TEST_ASSERT(length(data["actions"]), "menu actions should not be empty")

	var/list/first_action = data["actions"][1]
	TEST_ASSERT_NOTNULL(first_action["key"], "actions need a key")
	TEST_ASSERT_NOTNULL(first_action["name"], "actions need a name")

	var/list/controls = data["controls"]
	TEST_ASSERT_NOTNULL(controls, "controls should exist")
	TEST_ASSERT(controls["speed"] >= SEX_SPEED_MIN && controls["speed"] <= SEX_SPEED_MAX, "speed should be in range")

	var/list/arousal = data["arousal"]
	TEST_ASSERT_NOTNULL(arousal, "arousal block should exist")
	TEST_ASSERT(arousal["arousal_pct"] >= 0 && arousal["arousal_pct"] <= 100, "arousal_pct should be a percent")

	TEST_ASSERT(islist(data["zone_options"]), "zone_options should be a list")
	TEST_ASSERT_EQUAL(length(data["zone_options"]), 7, "zone_options should cover the 7 filters")

	// Clientless mob: intimacy + notes must degrade to empty, not runtime.
	var/list/intimacy = data["intimacy"]
	TEST_ASSERT(islist(intimacy["yours"]), "intimacy.yours should be a list")
	TEST_ASSERT_EQUAL(length(intimacy["yours"]), 0, "clientless mob should have no prefs data")
	var/list/notes = data["notes"]
	TEST_ASSERT_EQUAL(length(notes["yours"]), 0, "clientless mob should have no notes")

	TEST_ASSERT_NULL(data["bellyriding"], "no bellyriding component -> null block")
	qdel(session)

/datum/unit_test/sex_scene_controller_tgui_multi_controller_views
#ifdef FOCUS_SEX_SCENE_TGUI_LAYOUT_TEST
	focus = TRUE
#endif

/datum/unit_test/sex_scene_controller_tgui_multi_controller_views/Run()
	var/mob/living/carbon/human/first_actor = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/shared_target = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/second_actor = allocate(/mob/living/carbon/human)
	var/datum/sex_scene_controller/first_controller = first_actor.open_sex_scene(shared_target, show_ui = FALSE)
	var/datum/sex_scene_controller/second_controller = second_actor.open_sex_scene(shared_target, show_ui = FALSE)
	first_controller.set_current_speed(SEX_SPEED_LOW)
	second_controller.set_current_speed(SEX_SPEED_EXTREME)

	var/datum/sex_action/action = first_controller.instantiate_action(/datum/sex_action/rub_body)
	TEST_ASSERT(action.bind_runtime(first_controller), "the first actor should bind a shared-scene action")

	var/list/first_data = first_controller.ui_data(first_actor)
	var/list/second_data = second_controller.ui_data(second_actor)
	TEST_ASSERT_EQUAL(length(first_data["scene_participants"]), 3, "each controller view should expose all scene participants")
	TEST_ASSERT_EQUAL(length(second_data["scene_participants"]), 3, "another controller should see the same scene membership")
	TEST_ASSERT(islist(first_data["scene_participants"][1]["status_lines"]), "participant entries should expose character details for their tooltip")
	TEST_ASSERT_EQUAL(length(first_data["scene_connections"]), 1, "the actor's view should expose the active connection")
	TEST_ASSERT_EQUAL(length(second_data["scene_connections"]), 1, "another actor's view should expose the same connection")
	TEST_ASSERT(first_data["scene_connections"][1]["can_stop"], "the action owner should be able to stop their connection")
	TEST_ASSERT(!second_data["scene_connections"][1]["can_stop"], "another actor must not receive control over the connection")
	TEST_ASSERT_EQUAL(first_data["controls"]["speed"], SEX_SPEED_LOW, "the first controller should retain its actor-scoped controls")
	TEST_ASSERT_EQUAL(second_data["controls"]["speed"], SEX_SPEED_EXTREME, "the second controller should retain independent controls")

	action.unbind_runtime()
	qdel(action)
	qdel(first_controller)
	qdel(second_controller)

/datum/unit_test/sex_scene_controller_tgui_custom_fields/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/datum/sex_scene_controller/session = user.open_sex_scene(user, show_ui = FALSE)
	TEST_ASSERT_NOTNULL(session, "open_sex_scene should return a self-session")

	TEST_ASSERT(session.load_custom_action_draft_from_template("handplay"), "handplay template should load")
	TEST_ASSERT_NOTNULL(session.custom_action_editor_draft, "template load should create a draft")

	session.set_custom_action_field("name", "Test Action")
	TEST_ASSERT_EQUAL(session.custom_action_editor_draft.name, "Test Action", "name field should apply")

	session.set_custom_action_field("do_time_seconds", 99)
	TEST_ASSERT_EQUAL(session.custom_action_editor_draft.do_time_seconds, 10, "cycle time should clamp to 10")

	session.set_custom_action_field("user_arousal", "garbage")
	TEST_ASSERT_EQUAL(session.custom_action_editor_draft.user_arousal, 0, "non-numeric arousal should fall back to 0")

	TEST_ASSERT(!session.set_custom_action_field("id", "hax"), "non-whitelisted fields must be rejected")
	TEST_ASSERT(!session.set_custom_action_field("name", ""), "empty names must be rejected")

	// Clientless ckey -> save manager missing; must fail gracefully, not runtime.
	TEST_ASSERT(islist(session.get_custom_actions_ui_data()), "custom ui data should build")
	qdel(session)
