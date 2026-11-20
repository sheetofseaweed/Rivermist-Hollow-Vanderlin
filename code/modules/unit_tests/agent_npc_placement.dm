// Placement: the post an NPC walks back to when idle, and the spawner that puts NPCs on the map.

/obj/effect/agent_npc_spawner/test_dealer
	profile_type = /datum/agent_profile/merchant
	shop_type = /datum/agent_stock/dealer
	npc_name = "Testy Tradesman"
	dir = WEST

/obj/effect/agent_npc_spawner/test_custom
	profile_name = "Test Baker"
	npc_name = "Testy Baker"

/obj/effect/agent_npc_spawner/test_missing
	profile_name = "No Such Character"
	profile_type = /datum/agent_profile/guard
	npc_name = "Testy Guard"

/// The mob a spawner left on this turf, by the name it was given.
/proc/agent_test_spawned_named(turf/where, wanted)
	RETURN_TYPE(/mob/living)
	for(var/mob/living/found in where)
		if(found.real_name == wanted)
			return found
	return null

/// A turf on this z more than AGENT_FOCUS_RANGE from the mob, or null when the level is too small.
/proc/agent_test_far_turf(mob/living/from)
	for(var/turf/corner in list(locate(1, 1, from.z), locate(world.maxx, world.maxy, from.z), locate(1, world.maxy, from.z), locate(world.maxx, 1, from.z)))
		if(corner && get_dist(from, corner) > AGENT_FOCUS_RANGE)
			return corner
	return null

/datum/unit_test/agent_npc_keeps_slow_company_before_going_home

/datum/unit_test/agent_npc_keeps_slow_company_before_going_home/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/barmaid = agent_test_romantic_pawn()
	barmaid.gender = FEMALE
	var/datum/ai_controller/agent_social/controller = barmaid.ai_controller
	var/datum/agent_binding/binding = controller.binding
	var/mob/living/carbon/human/person = allocate(/mob/living/carbon/human/species/human/northern)
	person.gender = MALE
	person.give_genitals()
	var/mob/living/carbon/human/species/human/northern/agent_social/other = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/other_controller = other.ai_controller
	var/turf/far = agent_test_far_turf(barmaid)
	TEST_ASSERT_NOTNULL(binding, "Setup failed: the barmaid must be bound.")
	TEST_ASSERT_NOTNULL(far, "Setup failed: the test level must have a turf out of view.")
	controller.set_post(run_loc_floor_top_right, NORTH)

	// They talked, then fell quiet for longer than a reply takes, but they are still right here.
	binding.note_candidate(person)
	binding.engage_candidate()
	binding.partner_until = world.time - 1
	var/lapsed = isnull(binding.current_partner())
	var/company = binding.recent_company() == person
	var/stays = controller.busy_away_from_post()
	// Quiet for longer than the grace, and the NPC may go.
	binding.partner_until = world.time - AGENT_POST_COMPANY_GRACE - 1
	var/goes_after_grace = !controller.busy_away_from_post()
	// Within the grace, but they walked out of view.
	binding.partner_until = world.time - 1
	var/turf/start = get_turf(person)
	person.forceMove(far)
	var/goes_when_left = !controller.busy_away_from_post()
	person.forceMove(start)
	// Another agent NPC is no company to keep.
	binding.note_candidate(other)
	binding.engage_candidate()
	binding.partner_until = world.time - 1
	var/npc_is_company = !isnull(binding.recent_company())
	binding.end_conversation()
	var/free_again = !controller.busy_away_from_post()

	// An act is never left mid-way, even once the yes behind it has run out.
	controller.grant_consent(person)
	var/datum/sex_scene_controller/scene = barmaid.open_sex_scene(person, FALSE)
	var/datum/sex_action/act = scene?.try_start_action(/datum/sex_action/rub_body, "unit_test")
	controller.withdraw_consent(person)
	var/consent_gone = !controller.has_live_consent()
	var/stays_in_act = act && controller.busy_away_from_post()
	act?.scene?.stop_action(act)
	var/free_after_act = !controller.busy_away_from_post()

	agent_test_restore_subsystem(saved, binding)
	SSagent_npc.unregister_pawn(other_controller.binding, "test teardown")
	TEST_ASSERT(lapsed, "Setup failed: the conversation must have lapsed.")
	TEST_ASSERT(company, "The person it talked with, still in view, is company.")
	TEST_ASSERT(stays, "So the NPC stays, however slowly they type.")
	TEST_ASSERT(goes_after_grace, "Quiet past the grace, it may go home.")
	TEST_ASSERT(goes_when_left, "Once they walk out of view, it may go home.")
	TEST_ASSERT(!npc_is_company, "Another agent NPC is not company.")
	TEST_ASSERT(free_again, "Nothing else holds it.")
	TEST_ASSERT_NOTNULL(act, "Setup failed: the act must start.")
	TEST_ASSERT(consent_gone, "Setup failed: the yes must be withdrawn.")
	TEST_ASSERT(stays_in_act, "Mid-act, it stays even without a live yes.")
	TEST_ASSERT(free_after_act, "The act over, nothing holds it.")

/datum/unit_test/agent_npc_walks_back_to_its_post

/datum/unit_test/agent_npc_walks_back_to_its_post/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/mob/living/carbon/human/person = allocate(/mob/living/carbon/human/species/human/northern)
	var/datum/ai_planning_subtree/agent_return_to_post/subtree = new()
	var/datum/ai_behavior/agent_return_to_post/walk = GET_AI_BEHAVIOR(/datum/ai_behavior/agent_return_to_post)
	var/turf/post = run_loc_floor_top_right
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	TEST_ASSERT(get_turf(pawn) != post, "Setup failed: the pawn must start away from its post.")
	controller.set_post(post, NORTH)

	subtree.SelectBehaviors(controller, 1)
	var/clock_started = !isnull(controller.blackboard[BB_AGENT_POST_IDLE_SINCE])
	// A second plan inside the delay: the clock is running but has not run out.
	subtree.SelectBehaviors(controller, 1)
	var/walked_at_once = !isnull(LAZYACCESS(controller.current_behaviors, walk))
	controller.set_blackboard_key(BB_AGENT_POST_IDLE_SINCE, world.time - AGENT_POST_RETURN_DELAY - 1)
	subtree.SelectBehaviors(controller, 1)
	var/walked_later = !isnull(LAZYACCESS(controller.current_behaviors, walk))
	// Cancelling ends the walk as failed, which sets a retry wait that would hide every check below.
	controller.CancelActions()
	controller.clear_blackboard_key(BB_AGENT_POST_RETRY_AT)

	controller.start_combat(person, AGENT_COMBAT_BRAWL, "test")
	controller.set_blackboard_key(BB_AGENT_POST_IDLE_SINCE, world.time - AGENT_POST_RETURN_DELAY - 1)
	subtree.SelectBehaviors(controller, 1)
	var/walked_mid_fight = !isnull(LAZYACCESS(controller.current_behaviors, walk))
	controller.end_combat("test", report = FALSE)
	controller.CancelActions()
	controller.clear_blackboard_key(BB_AGENT_POST_RETRY_AT)

	controller.binding.note_candidate(person)
	controller.binding.engage_candidate()
	controller.set_blackboard_key(BB_AGENT_POST_IDLE_SINCE, world.time - AGENT_POST_RETURN_DELAY - 1)
	subtree.SelectBehaviors(controller, 1)
	var/walked_mid_chat = !isnull(LAZYACCESS(controller.current_behaviors, walk))
	controller.binding.end_conversation()
	controller.CancelActions()

	var/far_ok = controller.is_hot_pursuit_target(post)
	var/elsewhere_ok = controller.is_hot_pursuit_target(get_turf(person))
	pawn.forceMove(post)
	controller.set_blackboard_key(BB_AGENT_POST_IDLE_SINCE, world.time)
	walk.perform(1, controller, BB_AGENT_POST)
	var/faces_out = pawn.dir == NORTH
	qdel(subtree)
	agent_test_restore_subsystem(saved, controller.binding)

	TEST_ASSERT(clock_started, "Idling away from the post must start the clock.")
	TEST_ASSERT(!walked_at_once, "Lingering after an errand is natural; the NPC must not leave at once.")
	TEST_ASSERT(walked_later, "Idle long enough, the NPC must walk back.")
	TEST_ASSERT(!walked_mid_fight, "A fight comes before going home.")
	TEST_ASSERT(!walked_mid_chat, "So does a conversation.")
	TEST_ASSERT(far_ok, "The post must never be dropped as too far away to walk to.")
	TEST_ASSERT(!elsewhere_ok, "Only the post: everything else keeps the usual range.")
	TEST_ASSERT(faces_out, "Back at its post, the NPC faces the way it was placed.")

/datum/unit_test/agent_npc_failed_walk_home_waits_before_retrying

/datum/unit_test/agent_npc_failed_walk_home_waits_before_retrying/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/ai_planning_subtree/agent_return_to_post/subtree = new()
	var/datum/ai_behavior/agent_return_to_post/walk = GET_AI_BEHAVIOR(/datum/ai_behavior/agent_return_to_post)
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	controller.set_post(run_loc_floor_top_right, NORTH)

	// Walking since longer than the delay and the timeout together: an unreachable post.
	controller.set_blackboard_key(BB_AGENT_POST_IDLE_SINCE, world.time - AGENT_POST_RETURN_DELAY - AGENT_POST_RETURN_TIMEOUT - 1)
	walk.perform(1, controller, BB_AGENT_POST)
	var/retry_at = controller.blackboard[BB_AGENT_POST_RETRY_AT]
	controller.set_blackboard_key(BB_AGENT_POST_IDLE_SINCE, world.time - AGENT_POST_RETURN_DELAY - 1)
	subtree.SelectBehaviors(controller, 1)
	var/walked_again = !isnull(LAZYACCESS(controller.current_behaviors, walk))
	controller.CancelActions()
	qdel(subtree)
	agent_test_restore_subsystem(saved, controller.binding)

	TEST_ASSERT(retry_at > world.time, "A walk home that never arrives must give up and set a time to retry.")
	TEST_ASSERT(!walked_again, "Until then it must not try again, or an unreachable post burns pathfinding every plan.")

/datum/unit_test/agent_npc_spawner_places_a_ready_npc

/datum/unit_test/agent_npc_spawner_places_a_ready_npc/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/turf/here = run_loc_floor_top_right
	var/obj/effect/agent_npc_spawner/test_dealer/spawner = new(here)
	var/spawner_gone = QDELETED(spawner)
	var/mob/living/spawned = agent_test_spawned_named(here, "Testy Tradesman")
	TEST_ASSERT_NOTNULL(spawned, "The spawner must leave its NPC where it stood.")
	var/datum/ai_controller/agent_social/controller = spawned.ai_controller
	var/datum/component/agent_shop/shop = spawned.GetComponent(/datum/component/agent_shop)
	var/keeps_dealer = istype(shop?.stock, /datum/agent_stock/dealer)
	var/label = controller?.profile?.label
	var/bound = !isnull(controller?.binding)
	var/post = controller?.blackboard[BB_AGENT_POST]
	var/post_dir = controller?.blackboard[BB_AGENT_POST_DIR]
	agent_test_restore_subsystem(saved, controller?.binding)
	qdel(spawned)

	TEST_ASSERT(spawner_gone, "A spawner must remove itself once it has spawned.")
	TEST_ASSERT_EQUAL(label, "merchant", "The NPC must play the character the mapper chose.")
	TEST_ASSERT(bound, "It must be ready to think without an admin touching it.")
	TEST_ASSERT(keeps_dealer, "It must keep the shop the mapper chose.")
	TEST_ASSERT_EQUAL(post, here, "Its post is where it was placed.")
	TEST_ASSERT_EQUAL(post_dir, WEST, "Facing the way it was placed.")

/datum/unit_test/agent_npc_spawner_finds_saved_characters

/datum/unit_test/agent_npc_spawner_finds_saved_characters/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/turf/here = run_loc_floor_top_right
	var/datum/agent_profile/baker = new()
	baker.label = "baker"
	GLOB.agent_custom_profiles["Test Baker"] = baker

	new /obj/effect/agent_npc_spawner/test_custom(here)
	new /obj/effect/agent_npc_spawner/test_missing(here)
	var/mob/living/custom = agent_test_spawned_named(here, "Testy Baker")
	var/mob/living/fallback = agent_test_spawned_named(here, "Testy Guard")
	var/datum/ai_controller/agent_social/custom_controller = custom?.ai_controller
	var/datum/ai_controller/agent_social/fallback_controller = fallback?.ai_controller
	var/custom_label = custom_controller?.profile?.label
	var/fallback_label = fallback_controller?.profile?.label
	var/shopless = isnull(custom?.GetComponent(/datum/component/agent_shop))
	GLOB.agent_custom_profiles -= "Test Baker"
	qdel(baker)
	agent_test_restore_subsystem(saved, custom_controller?.binding)
	agent_test_restore_subsystem(saved, fallback_controller?.binding)
	qdel(custom)
	qdel(fallback)

	TEST_ASSERT_EQUAL(custom_label, "baker", "A character saved in the profile menu must be placeable by name.")
	TEST_ASSERT_EQUAL(fallback_label, "guard", "A name not saved on this server must fall back to the built-in type, not a villager.")
	TEST_ASSERT(shopless, "No shop unless the mapper sets one.")

/datum/unit_test/agent_npc_merchant_presets_open_their_shops

/datum/unit_test/agent_npc_merchant_presets_open_their_shops/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/turf/here = run_loc_floor_top_right
	for(var/obj/effect/agent_npc_spawner/preset_type as anything in typesof(/obj/effect/agent_npc_spawner/merchant))
		var/list/before = list()
		for(var/mob/living/already in here)
			before += already
		new preset_type(here)
		var/mob/living/spawned
		for(var/mob/living/found in here)
			if(!(found in before))
				spawned = found
				break
		TEST_ASSERT_NOTNULL(spawned, "[preset_type] must leave an NPC.")
		var/datum/ai_controller/agent_social/controller = spawned.ai_controller
		var/datum/component/agent_shop/shop = spawned.GetComponent(/datum/component/agent_shop)
		var/label = controller?.profile?.label
		var/right_shop = shop?.stock?.type == initial(preset_type.shop_type)
		agent_test_restore_subsystem(saved, controller?.binding)
		qdel(spawned)
		TEST_ASSERT_EQUAL(label, "merchant", "[preset_type] must spawn a merchant.")
		TEST_ASSERT(right_shop, "[preset_type] must open its own kind of shop.")
