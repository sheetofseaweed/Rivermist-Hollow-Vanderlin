/// Tests for the sex session TGUI data + act plumbing.
/datum/unit_test/sex_session_tgui_data/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/datum/sex_session/session = user.start_sex_session(user, show_ui = FALSE)
	TEST_ASSERT_NOTNULL(session, "start_sex_session should return a self-session")

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

/datum/unit_test/sex_session_tgui_custom_fields/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/datum/sex_session/session = user.start_sex_session(user, show_ui = FALSE)
	TEST_ASSERT_NOTNULL(session, "start_sex_session should return a self-session")

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
