/// Item-driven actions borrow something the user is holding. Losing the item has to end the
/// action even when nobody moves, because can_run() skips can_perform() once the loop is running.
/datum/unit_test/sex_action_stops_when_toy_dropped/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human)
	var/obj/item/dildo/toy = allocate(/obj/item/dildo)

	var/datum/sex_scene_controller/session = user.open_sex_scene(partner, show_ui = FALSE)
	TEST_ASSERT_NOTNULL(session, "the pair session should start")

	var/datum/sex_action/object_fuck/action = session.instantiate_action(/datum/sex_action/object_fuck/object_vaginal_other)
	TEST_ASSERT_NOTNULL(action, "an object action should instantiate")
	TEST_ASSERT(action.bind_runtime(session), "the scene should accept the object action")

	TEST_ASSERT(user.put_in_active_hand(toy), "the user should be holding the toy")
	action.selected_toy = action.get_storage_check_item(user, partner)
	TEST_ASSERT_EQUAL(action.selected_toy, toy, "starting the action should latch onto the held toy")

	TEST_ASSERT(action.can_run(TRUE), "a running object action should continue while the toy is held")

	user.dropItemToGround(toy)
	TEST_ASSERT_EQUAL(toy.loc, get_turf(user), "the dropped toy should land on the user's own tile")
	TEST_ASSERT(!action.can_run(TRUE), "a running object action should stop once the toy leaves the user's hand")

	action.unbind_runtime()
	qdel(action)
	qdel(session)

/// Same rule for the collection actions, which need a container in hand rather than a toy.
/datum/unit_test/sex_action_stops_when_container_dropped/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human)
	var/obj/item/reagent_containers/glass/cup/container = allocate(/obj/item/reagent_containers/glass/cup)

	var/datum/sex_scene_controller/session = user.open_sex_scene(partner, show_ui = FALSE)
	TEST_ASSERT_NOTNULL(session, "the pair session should start")

	var/datum/sex_action/collect_fluid/action = session.instantiate_action(/datum/sex_action/collect_fluid/other)
	TEST_ASSERT_NOTNULL(action, "a collect action should instantiate")
	TEST_ASSERT(action.bind_runtime(session), "the scene should accept the collect action")

	TEST_ASSERT(user.put_in_active_hand(container), "the user should be holding the container")
	TEST_ASSERT(action.can_run(TRUE), "a running collect action should continue while the container is held")

	user.dropItemToGround(container)
	TEST_ASSERT(!action.can_run(TRUE), "a running collect action should stop once the container leaves the user's hand")

	action.unbind_runtime()
	qdel(action)
	qdel(session)

/// A proc override written against a path that was never declared silently creates that type, and
/// build_sex_actions() then registers the accidental subtype as a real, selectable action. Those
/// strays inherit their parent's name verbatim, so a subtype sharing a name with an ancestor is
/// the signature to look for.
/datum/unit_test/sex_action_types_are_declared/Run()
	for(var/action_type in GLOB.sex_actions)
		var/datum/sex_action/action = GLOB.sex_actions[action_type]
		var/ancestor = action_type
		while(TRUE)
			ancestor = type2parent(ancestor)
			if(!ancestor || !ispath(ancestor, /datum/sex_action))
				break
			var/datum/sex_action/ancestor_action = GLOB.sex_actions[ancestor]
			if(!ancestor_action)
				continue
			TEST_ASSERT_NOTEQUAL(action.name, ancestor_action.name, "[action_type] shares the name \"[action.name]\" with its ancestor [ancestor], which usually means it is an undeclared type created by a typo'd proc path.")

	/// The interaction menu keys entries off name, so two unrelated actions sharing one produces two
	/// identical labels that do different things.
	var/list/names_to_types = list()
	for(var/action_type in GLOB.sex_actions)
		var/datum/sex_action/action = GLOB.sex_actions[action_type]
		var/name_key = "[action.name]"
		var/claimed_by = names_to_types[name_key]
		TEST_ASSERT_NULL(claimed_by, "[action_type] and [claimed_by] are both named \"[action.name]\"; give one of them a distinct label.")
		names_to_types[name_key] = action_type

/// flipped means the TARGET is the one doing the inserting. Actions where the user works on the
/// target with their own hands or an item they hold are not flipped.
/datum/unit_test/sex_action_flipped_marks_target_as_inserter/Run()
	var/list/expected_flipped = list(
		/datum/sex_action/blowjob,
		/datum/sex_action/sex/other/vagina,
	)
	var/list/expected_not_flipped = list(
		/datum/sex_action/masturbate/other/vagina,
		/datum/sex_action/masturbate/other/anus,
		/datum/sex_action/masturbate/other/penis,
		/datum/sex_action/collect_fluid/other,
		/datum/sex_action/object_fuck/object_vaginal_other,
	)

	for(var/datum/sex_action/action_type as anything in expected_flipped)
		TEST_ASSERT(initial(action_type.flipped), "[action_type] takes the target's part into the user, so it should be flipped.")

	for(var/datum/sex_action/action_type as anything in expected_not_flipped)
		TEST_ASSERT(!initial(action_type.flipped), "[action_type] is performed by the user on the target, so it should not be flipped.")
