/// Lobby players only receive ghost-role polls when their account settings allow it.
/datum/unit_test/lobby_role_calls_preference_gate

/datum/unit_test/lobby_role_calls_preference_gate/Run()
	var/datum/preferences/prefs = allocate(/datum/preferences)
	TEST_ASSERT(prefs.accepts_role_calls(), "Role calls should be on by default.")
	TEST_ASSERT(!prefs.accepts_lobby_role_calls(), "Accounts that have not finished the defeat introduction must not receive lobby role calls.")
	prefs.defeat_introduction_complete = TRUE
	TEST_ASSERT(prefs.accepts_lobby_role_calls(), "Lobby role calls should be on once the introduction is complete.")
	prefs.migrant.active = TRUE
	TEST_ASSERT(!prefs.accepts_lobby_role_calls(), "Players in the migrant queue must not receive role calls.")
	prefs.migrant.active = FALSE
	prefs.update_preference(/datum/preference/toggle/role_calls, FALSE)
	TEST_ASSERT(!prefs.accepts_role_calls(), "Turning role calls off must keep ghosts out of polls.")
	TEST_ASSERT(!prefs.accepts_lobby_role_calls(), "Turning role calls off must keep lobby players out of polls.")

/// Lobby mobs without a client never enter the ghost poll pool.
/datum/unit_test/lobby_role_calls_pool

/datum/unit_test/lobby_role_calls_pool/Run()
	var/mob/dead/new_player/lobby_player = allocate(/mob/dead/new_player)
	TEST_ASSERT(lobby_player in GLOB.new_player_list, "The test lobby player should be registered.")
	TEST_ASSERT(!lobby_player.can_answer_role_poll(), "A lobby mob without a client cannot answer a poll.")
	TEST_ASSERT(!(lobby_player in get_ghost_poll_pool()), "A lobby mob without a client must not enter the poll pool.")

/// Returning from spectating starts a rejoin wait that runs out on its own.
/datum/unit_test/spectate_rejoin_delay

/datum/unit_test/spectate_rejoin_delay/Run()
	var/test_ckey = "spectaterejoinunittest"
	TEST_ASSERT_EQUAL(get_spectate_rejoin_wait_for(test_ckey), 0, "A player who never spectated should not wait.")
	note_spectate_rejoin(test_ckey)
	TEST_ASSERT_EQUAL(get_spectate_rejoin_delay(), CONFIG_GET(number/spectate_rejoin_delay) * 600, "The configured delay is in minutes.")
	TEST_ASSERT_EQUAL(get_spectate_rejoin_wait_for(test_ckey), get_spectate_rejoin_delay(), "Returning from spectating should start the full rejoin wait.")
	GLOB.spectate_rejoin_times[test_ckey] = world.time - 1
	TEST_ASSERT_EQUAL(get_spectate_rejoin_wait_for(test_ckey), 0, "An expired wait should no longer block joining.")
	TEST_ASSERT_EQUAL(get_spectate_rejoin_wait(null), 0, "A missing client should never be blocked.")

/datum/unit_test/spectate_rejoin_delay/Destroy()
	GLOB.spectate_rejoin_times -= "spectaterejoinunittest"
	return ..()

/// The lobby buttons need every state that update_icon and the Click flick can ask for.
/datum/unit_test/lobby_role_calls_button_states

/datum/unit_test/lobby_role_calls_button_states/Run()
	var/list/call_states = icon_states('modular_rmh/icons/hud/lobby_role_calls.dmi')
	for(var/base in list("role_calls_on", "role_calls_off"))
		for(var/suffix in list("", "_highlighted", "_pressed"))
			TEST_ASSERT("[base][suffix]" in call_states, "Missing lobby button state [base][suffix].")
	var/list/spectate_states = icon_states('modular_rmh/icons/hud/lobby_spectate.dmi')
	for(var/suffix in list("", "_highlighted", "_pressed", "_disabled"))
		TEST_ASSERT("spectate[suffix]" in spectate_states, "Missing lobby button state spectate[suffix].")
