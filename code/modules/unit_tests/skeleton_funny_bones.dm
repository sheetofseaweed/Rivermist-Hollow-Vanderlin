/// Skeletons trade flesh genitals for a funny bone (males) or for petting (everyone else).
/datum/unit_test/skeleton_funny_bone
	abstract_type = /datum/unit_test/skeleton_funny_bone
#ifdef FOCUS_SKELETON_FUNNY_BONE_TEST
	focus = TRUE
#endif

/// Records what onlookers saw, so tests can read the skeleton's lines.
/mob/living/carbon/human/species/skeleton/npc/unit_test_echo
	var/list/seen_messages = list()

/mob/living/carbon/human/species/skeleton/npc/unit_test_echo/visible_message(message, self_message, blind_message, vision_distance = DEFAULT_MESSAGE_RANGE, list/ignored_mobs, runechat_message = null, log_seen = NONE, log_seen_msg = null)
	seen_messages += message
	return ..()

/// A skeleton NPC of the given gender; its genitals are swapped one second later, in after_creation().
/datum/unit_test/skeleton_funny_bone/proc/allocate_skeleton(gender = MALE)
	var/mob/living/carbon/human/species/skeleton/npc/unit_test_echo/skeleton = allocate(/mob/living/carbon/human/species/skeleton/npc/unit_test_echo)
	skeleton.gender = gender
	return skeleton

/datum/unit_test/skeleton_funny_bone/proc/saw_message(mob/living/carbon/human/species/skeleton/npc/unit_test_echo/skeleton, text)
	for(var/message in skeleton.seen_messages)
		if(findtext(message, text))
			return TRUE
	return FALSE

/datum/unit_test/skeleton_funny_bone/proc/list_genitals(mob/living/carbon/human/skeleton)
	var/list/genitals = list()
	for(var/obj/item/organ/genitals/organ in skeleton.internal_organs)
		genitals += "[organ.type]"
	return genitals

/datum/unit_test/skeleton_funny_bone/anatomy

/datum/unit_test/skeleton_funny_bone/anatomy/Run()
	var/mob/living/carbon/human/species/skeleton/npc/unit_test_echo/male = allocate_skeleton(MALE)
	var/mob/living/carbon/human/species/skeleton/npc/unit_test_echo/female = allocate_skeleton(FEMALE)
	sleep(15)
	// The horny AI grows genitals before every scene; a skeleton must not get flesh back.
	male.give_genitals()
	female.give_genitals()

	var/list/male_genitals = list_genitals(male)
	TEST_ASSERT_EQUAL(length(male_genitals), 1, "A male skeleton should keep one genital organ, found: [jointext(male_genitals, ", ")].")
	TEST_ASSERT(istype(male.getorganslot(ORGAN_SLOT_PENIS), /obj/item/organ/genitals/penis/funny_bone), "A male skeleton's only genital should be a funny bone.")
	var/list/female_genitals = list_genitals(female)
	TEST_ASSERT_EQUAL(length(female_genitals), 0, "A female skeleton should have no genitals, found: [jointext(female_genitals, ", ")].")

/datum/unit_test/skeleton_funny_bone/acts

/datum/unit_test/skeleton_funny_bone/acts/Run()
	var/static/list/bony_acts = list(
		/datum/sex_action/npc/npc_throat_sex/funny_bone,
		/datum/sex_action/npc/npc_anal_sex/funny_bone,
		/datum/sex_action/npc/npc_vaginal_sex/funny_bone,
		/datum/sex_action/npc/npc_jerk_over/funny_bone,
	)
	var/mob/living/carbon/human/male_partner = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/female_partner = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/species/skeleton/npc/unit_test_echo/male = allocate_skeleton(MALE)
	var/mob/living/carbon/human/species/skeleton/npc/unit_test_echo/female = allocate_skeleton(FEMALE)
	sleep(15)
	var/datum/ai_behavior/horny/horny = GET_AI_BEHAVIOR(/datum/ai_behavior/horny/human)

	var/list/male_choices = list()
	add_local_horny_ai_actions(male_choices, male, male_partner)
	TEST_ASSERT(length(male_choices), "A male skeleton should have acts to pick from.")
	for(var/action_type in male_choices)
		TEST_ASSERT(action_type in bony_acts, "A male skeleton should only pick funny bone acts, got [action_type].")
	var/list/female_choices = list()
	add_local_horny_ai_actions(female_choices, female, female_partner)
	TEST_ASSERT_EQUAL(female_choices.Join(","), "[/datum/sex_action/npc/npc_bony_petting]", "A female skeleton should only pet.")

	var/datum/sex_scene_controller/male_scene = male.open_sex_scene(male_partner, FALSE)
	var/male_act = horny.select_horny_ai_act(male.ai_controller, male, male_partner, male_scene)
	TEST_ASSERT(male_act in bony_acts, "The horny AI should start a funny bone act, got [male_act || "nothing"].")
	TEST_ASSERT_NOTNULL(male_scene.try_start_action(male_act, "ai"), "The funny bone act should start.")
	var/datum/sex_scene_controller/female_scene = female.open_sex_scene(female_partner, FALSE)
	var/female_act = horny.select_horny_ai_act(female.ai_controller, female, female_partner, female_scene)
	TEST_ASSERT_EQUAL(female_act, /datum/sex_action/npc/npc_bony_petting, "The horny AI should start petting.")
	TEST_ASSERT_NOTNULL(female_scene.try_start_action(female_act, "ai"), "The petting act should start.")

	sleep(40) // each act shows its first stroke
	TEST_ASSERT(saw_message(male, "funny bone"), "Onlookers should read about the funny bone.")
	TEST_ASSERT(saw_message(female, "finger bones"), "Onlookers should read about bony fingers.")
	male_scene.stop_action()
	female_scene.stop_action()
	sleep(2) // lets the stopped acts finish their loops before teardown

/datum/unit_test/skeleton_funny_bone/lines

/datum/unit_test/skeleton_funny_bone/lines/Run()
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human)
	partner.set_cached_erp_preferences(list(
		/datum/erp_preference/bitflag/horny_mobs = HORNY_MOBS_TAG_MALES | HORNY_MOBS_TAG_FEMALES,
		/datum/erp_preference/bitflag/horny_mob_types = HORNY_MOB_TYPE_UNDEAD,
	))
	var/mob/living/carbon/human/species/skeleton/npc/unit_test_echo/male = allocate_skeleton(MALE)
	var/mob/living/carbon/human/species/skeleton/npc/unit_test_echo/female = allocate_skeleton(FEMALE)
	sleep(15)

	for(var/mob/living/carbon/human/species/skeleton/npc/unit_test_echo/skeleton as anything in list(male, female))
		var/datum/ai_controller/controller = skeleton.ai_controller
		controller.set_blackboard_key(BB_TARGETTING_DATUM, allocate(/datum/targetting_datum/basic/unit_test_allow_clientless_horny))
		controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_HORNY_TARGET, partner)
		controller.queue_behavior(/datum/ai_behavior/horny/human, BB_BASIC_MOB_CURRENT_HORNY_TARGET, BB_TARGETTING_DATUM)
	TEST_ASSERT(saw_message(male, "funny bone rattling"), "A male skeleton should eye its target with a rattling funny bone.")
	TEST_ASSERT(saw_message(female, "finger bones twitching"), "A female skeleton should eye its target with twitching fingers.")
	TEST_ASSERT(!saw_message(female, "dripping"), "A skeleton has nothing to drip.")

	var/datum/component/arousal/male_arousal = male.GetComponent(/datum/component/arousal)
	var/datum/component/arousal/female_arousal = female.GetComponent(/datum/component/arousal)
	TEST_ASSERT(male_arousal && female_arousal, "Test setup: every human should have an arousal component.")
	male_arousal.ejaculate()
	female_arousal.ejaculate()
	TEST_ASSERT(saw_message(male, "clattering climax"), "A funny bone climax should rattle and release nothing.")
	TEST_ASSERT(saw_message(female, "contented rattle"), "A skeleton with nothing below the belt should climax with a rattle.")

/// Skilled warriors built their mind with the mob as its key, so ERP took them for a logged-off player.
/datum/unit_test/skeleton_funny_bone/skilled_warrior_starts_an_act

/datum/unit_test/skeleton_funny_bone/skilled_warrior_starts_an_act/Run()
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human)
	partner.set_cached_erp_preferences(list(
		/datum/erp_preference/bitflag/horny_mobs = HORNY_MOBS_TAG_MALES,
		/datum/erp_preference/bitflag/horny_mob_types = HORNY_MOB_TYPE_UNDEAD,
	))
	var/mob/living/carbon/human/species/skeleton/npc/warrior/skilled/skeleton = allocate(/mob/living/carbon/human/species/skeleton/npc/warrior/skilled)
	sleep(15)
	TEST_ASSERT_NOTNULL(skeleton.mind, "Test setup: skilled skeletons get a mind for their skills.")
	TEST_ASSERT(skeleton.allows_player_erp_while_disconnected(), "A skilled skeleton's mind must not read as a logged-off player.")

	var/datum/ai_controller/controller = skeleton.ai_controller
	controller.set_blackboard_key(BB_TARGETTING_DATUM, allocate(/datum/targetting_datum/basic/unit_test_allow_clientless_horny))
	controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_HORNY_TARGET, partner)
	controller.queue_behavior(/datum/ai_behavior/horny/human, BB_BASIC_MOB_CURRENT_HORNY_TARGET, BB_TARGETTING_DATUM)
	var/datum/ai_behavior/horny = GET_AI_BEHAVIOR(/datum/ai_behavior/horny/human)
	var/datum/sex_scene_controller/scene_controller = skeleton.open_sex_scene(partner, FALSE)
	TEST_ASSERT_NOTNULL(scene_controller, "Test setup: the skeleton should open a scene with the partner.")
	// Stripping its own armour takes several steps, as in a real fight.
	for(var/i in 1 to 600)
		controller.process(0.1)
		if(length(scene_controller.get_active_actions()) || !LAZYACCESS(controller.current_behaviors, horny))
			break
		sleep(1)
	TEST_ASSERT(length(scene_controller.get_active_actions()), "An armoured skilled skeleton should strip and then start an act.")
	scene_controller.stop_action()
	// Teardown deletes the partner, and a floored, grabbed mob runtimes in its async get_up().
	skeleton.stop_pulling()
	partner.SetKnockdown(0)
	sleep(2) // lets the stopped act finish its loop before teardown
