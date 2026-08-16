/// A button that ends up with no screen_loc is invisible but still in the mob's action list, so it can never be recovered.
/datum/unit_test/action_buttons_survive_being_dropped_on_each_other
#ifdef FOCUS_ACTION_BUTTON_TEST
	focus = TRUE
#endif

/datum/unit_test/action_buttons_survive_being_dropped_on_each_other/proc/make_button(mob/owner, name)
	var/datum/action/action = new /datum/action(owner)
	action.name = name
	action.Grant(owner)
	return action

/datum/unit_test/action_buttons_survive_being_dropped_on_each_other/Run()
	var/mob/living/carbon/human/dummy = allocate(/mob/living/carbon/human)
	dummy.set_hud_used(new /datum/hud(dummy))
	var/datum/hud/hud = dummy.hud_used

	var/datum/action/dragged_action = make_button(dummy, "Dragged")
	var/datum/action/target_action = make_button(dummy, "Target")
	var/atom/movable/screen/movable/action_button/dragged = dragged_action.viewers[hud]
	var/atom/movable/screen/movable/action_button/target = target_action.viewers[hud]

	// Dropping onto a button that lives in the palette pulls us in there too, which is only visible while it is open
	hud.position_action(target, SCRN_OBJ_IN_PALETTE)
	hud.position_action_relative(dragged, target)
	dragged.reveal_if_palette()

	TEST_ASSERT(hud.toggle_palette.expanded, "Moving a button into the palette should open it instead of hiding the button.")
	TEST_ASSERT_NOTNULL(dragged.screen_loc, "A button dropped onto a palette button should still have a screen position.")
	TEST_ASSERT_NOTNULL(target.screen_loc, "A palette button should keep its screen position when another button joins it.")

	// A target that was never positioned has nothing to be relative to, we must not strand the dragged button
	var/datum/action/unplaced_action = new /datum/action(dummy)
	unplaced_action.name = "Unplaced"
	var/atom/movable/screen/movable/action_button/unplaced = unplaced_action.create_button()
	unplaced.our_hud = hud

	hud.position_action_relative(dragged, unplaced)

	TEST_ASSERT_NOTEQUAL(dragged.location, SCRN_OBJ_DEFAULT, "A button dropped onto an unpositioned button should still belong to a group.")
	TEST_ASSERT_NOTNULL(dragged.screen_loc, "A button dropped onto an unpositioned button should still have a screen position.")

	unplaced.our_hud = null
	qdel(unplaced)
	qdel(unplaced_action)
	qdel(dragged_action)
	qdel(target_action)
	qdel(hud)
	dummy.hud_used = null

/// Floating buttons store their coords in screen_loc alone, so anything that rehomes them has to carry those coords over.
/datum/unit_test/action_buttons_keep_floating_positions
#ifdef FOCUS_ACTION_BUTTON_TEST
	focus = TRUE
#endif

/datum/unit_test/action_buttons_keep_floating_positions/Run()
	var/mob/living/carbon/human/dummy = allocate(/mob/living/carbon/human)
	dummy.set_hud_used(new /datum/hud(dummy))
	var/datum/hud/hud = dummy.hud_used

	var/datum/action/action = new /datum/action(dummy)
	action.name = "Floater"
	action.Grant(dummy)
	var/atom/movable/screen/movable/action_button/button = action.viewers[hud]

	hud.position_action(button, "7:16,5:20")
	TEST_ASSERT_EQUAL(button.screen_loc, "7:16,5:20", "A button given a screen_loc should float there.")

	hud.build_action_groups()
	TEST_ASSERT_EQUAL(button.screen_loc, "7:16,5:20", "Rebuilding the action groups should not move a floating button.")

	// A blank position is not a screen_loc, falling through to floating would leave nothing to draw
	hud.position_action(button, null)
	TEST_ASSERT_NOTNULL(button.screen_loc, "A button positioned with no location should fall back to its default.")

	qdel(action)
	qdel(hud)
	dummy.hud_used = null

/// Destroy calls hide_action, so a button that never got placed used to abort its own cleanup and leak.
/datum/unit_test/action_buttons_clean_up_before_placement
#ifdef FOCUS_ACTION_BUTTON_TEST
	focus = TRUE
#endif

/datum/unit_test/action_buttons_clean_up_before_placement/Run()
	var/mob/living/carbon/human/dummy = allocate(/mob/living/carbon/human)
	dummy.set_hud_used(new /datum/hud(dummy))
	var/datum/hud/hud = dummy.hud_used

	var/datum/action/action = new /datum/action(dummy)
	action.name = "Unplaced"
	var/atom/movable/screen/movable/action_button/button = action.create_button()
	button.our_hud = hud
	action.viewers[hud] = button

	qdel(button)

	TEST_ASSERT_NULL(action.viewers[hud], "Destroying an unplaced action button should still unregister it from its action.")

	qdel(action)
	qdel(hud)
	dummy.hud_used = null
