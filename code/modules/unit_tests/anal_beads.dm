/// A shaped steel string ready for a test.
/datum/unit_test/proc/make_test_beads(shape_type = /datum/bead_shape/standard)
	var/obj/item/anal_beads/steel/beads = allocate(/obj/item/anal_beads/steel)
	beads.set_shape(GLOB.bead_shapes[shape_type])
	return beads

/datum/unit_test/proc/get_inner_bulk(obj/item/organ/organ)
	var/datum/component/body_storage/storage = organ.GetComponent(/datum/component/body_storage)
	return storage.layer_storage_cur_bulk[STORAGE_LAYER_INNER]

/datum/unit_test/anal_bead_shapes_match_sprites/Run()
	var/list/shape_names = list()
	for(var/shape_type in GLOB.bead_shapes)
		var/datum/bead_shape/shape = GLOB.bead_shapes[shape_type]
		TEST_ASSERT(length(shape.beads), "[shape_type] should have beads.")
		TEST_ASSERT(icon_exists('modular_rmh/icons/obj/lewd/beads.dmi', shape.icon_state), "[shape_type] has no sprite \"[shape.icon_state]\".")
		TEST_ASSERT(!(shape.name in shape_names), "Two bead shapes share the name [shape.name].")
		shape_names += shape.name
	TEST_ASSERT_EQUAL(length(shape_names), 13, "Every bead sprite should have its shape.")
	TEST_ASSERT(icon_exists('modular_rmh/icons/obj/lewd/beads.dmi', "glass_overlay"), "Glass beads need their shine overlay.")
	for(var/hole in list("anus", "vagina"))
		for(var/hanging in 1 to 3)
			TEST_ASSERT(icon_exists('modular_rmh/icons/obj/lewd/beads_onmob.dmi', "beads_[hole]_[hanging]"), "Missing worn beads state beads_[hole]_[hanging].")

/datum/unit_test/anal_beads_feed_and_draw_keep_storage_in_step/Run()
	var/mob/living/carbon/human/wearer = allocate(/mob/living/carbon/human)
	give_chastity_test_organs(wearer, list(ORGAN_SLOT_ANUS))
	var/obj/item/organ/anus = wearer.getorganslot(ORGAN_SLOT_ANUS)
	var/obj/item/anal_beads/beads = make_test_beads()
	TEST_ASSERT_EQUAL(beads.push_bead(anus), INSERT_FEEDBACK_OK, "The first bead should slip in.")
	TEST_ASSERT(beads in anus.contents, "The string should sit in the hole once a bead is in.")
	TEST_ASSERT_EQUAL(beads.host, wearer, "The string should know its wearer.")
	beads.push_bead(anus)
	beads.push_bead(anus)
	TEST_ASSERT_EQUAL(beads.beads_inside, 3, "Three pushes should put three beads in.")
	TEST_ASSERT_EQUAL(get_inner_bulk(anus), beads.get_inserted_bulk(), "The hole should be filled by exactly the inside beads.")
	TEST_ASSERT_NOTNULL(beads.hanging_overlay, "A partly inserted string should hang out.")

	var/mob/living/carbon/human/puller = allocate(/mob/living/carbon/human)
	TEST_ASSERT_EQUAL(beads.pull_bead(puller), BEAD_MEDIUM, "Drawing should pop out the outermost bead.")
	TEST_ASSERT_EQUAL(beads.beads_inside, 2, "One draw should leave two beads in.")
	TEST_ASSERT_EQUAL(get_inner_bulk(anus), beads.get_inserted_bulk(), "Drawing should shrink the filled room.")
	beads.pull_bead(puller)
	beads.pull_bead(puller)
	TEST_ASSERT(!(beads in anus.contents), "The last bead out should free the string.")
	TEST_ASSERT_NULL(beads.host, "A freed string should forget its wearer.")
	TEST_ASSERT_EQUAL(get_inner_bulk(anus), 0, "An empty hole should hold no bulk.")
	TEST_ASSERT(puller.is_holding(beads), "The last draw should leave the string in the puller's hand.")

/datum/unit_test/anal_beads_respect_fullness_and_depth/Run()
	var/mob/living/carbon/human/wearer = allocate(/mob/living/carbon/human)
	give_chastity_test_organs(wearer, list(ORGAN_SLOT_ANUS, ORGAN_SLOT_VAGINA))
	var/obj/item/organ/anus = wearer.getorganslot(ORGAN_SLOT_ANUS)
	var/datum/component/body_storage/storage = anus.GetComponent(/datum/component/body_storage)
	var/obj/item/anal_beads/giant = make_test_beads(/datum/bead_shape/giant)
	var/result
	for(var/push in 1 to 6)
		result = giant.push_bead(anus)
		if(result == INSERT_FEEDBACK_TRY_FORCE || result == INSERT_FEEDBACK_STUFFED)
			break
	TEST_ASSERT(result == INSERT_FEEDBACK_TRY_FORCE || result == INSERT_FEEDBACK_STUFFED, "Six giant beads should overfill an unstretched ass without force.")
	TEST_ASSERT(get_inner_bulk(anus) <= storage.layer_storage_max_bulk[STORAGE_LAYER_INNER], "Gentle feeding should never overfill the hole.")
	if(result == INSERT_FEEDBACK_TRY_FORCE)
		var/inside = giant.beads_inside
		TEST_ASSERT_EQUAL(giant.push_bead(anus, TRUE), INSERT_FEEDBACK_OK_FORCE, "Force should push one more bead past the strain.")
		TEST_ASSERT_EQUAL(giant.beads_inside, inside + 1, "A forced bead should count as inside.")

	var/obj/item/organ/vagina = wearer.getorganslot(ORGAN_SLOT_VAGINA)
	var/obj/item/anal_beads/standard = make_test_beads()
	for(var/push in 1 to 8)
		result = standard.push_bead(vagina)
		if(result == BEADS_TOO_DEEP)
			break
	TEST_ASSERT_EQUAL(result, BEADS_TOO_DEEP, "A pussy should only take beads so deep.")
	TEST_ASSERT(standard.get_inserted_depth() <= vagina.get_insertion_depth_limit(), "Beads should never pass the depth limit.")
	var/shallow = standard.beads_inside
	vagina.stretched_coefficient = 2
	TEST_ASSERT_EQUAL(standard.push_bead(vagina), INSERT_FEEDBACK_OK, "A stretched pussy should take more beads.")
	TEST_ASSERT_EQUAL(standard.beads_inside, shallow + 1, "The extra bead should count as inside.")
	TEST_ASSERT_NULL(anus.get_insertion_depth_limit(), "An ass has no depth limit, only fullness.")

/datum/unit_test/anal_beads_hold_firm_and_show_only_when_partly_out/Run()
	var/mob/living/carbon/human/wearer = allocate(/mob/living/carbon/human)
	give_chastity_test_organs(wearer, list(ORGAN_SLOT_ANUS))
	var/obj/item/organ/anus = wearer.getorganslot(ORGAN_SLOT_ANUS)
	var/obj/item/anal_beads/beads = make_test_beads(/datum/bead_shape/graduated_petite)
	beads.push_bead(anus)
	TEST_ASSERT(!SEND_SIGNAL(anus, COMSIG_BODYSTORAGE_REMOVE_RAND_ITEM, STORAGE_LAYER_INNER), "Beads should never fall out at random.")
	TEST_ASSERT(beads in anus.contents, "Beads should hold firm like a plug.")
	TEST_ASSERT_EQUAL(beads.get_fluid_displacement(), round(beads.get_inserted_bulk() * 4), "Beads should displace fluid by what is inside.")
	beads.push_bead(anus)
	beads.push_bead(anus)
	TEST_ASSERT_EQUAL(beads.beads_inside, beads.get_bead_count(), "Three pushes should seat a three-bead string.")
	TEST_ASSERT_NULL(beads.hanging_overlay, "A fully inserted string should show nothing.")

/datum/unit_test/anal_beads_generic_removal_is_a_yank/Run()
	var/mob/living/carbon/human/wearer = allocate(/mob/living/carbon/human)
	give_chastity_test_organs(wearer, list(ORGAN_SLOT_ANUS))
	var/obj/item/organ/anus = wearer.getorganslot(ORGAN_SLOT_ANUS)
	var/obj/item/anal_beads/beads = make_test_beads()
	for(var/push in 1 to 4)
		beads.push_bead(anus)
	var/list/arousal_before = list()
	SEND_SIGNAL(wearer, COMSIG_SEX_GET_AROUSAL, arousal_before)
	TEST_ASSERT(SEND_SIGNAL(anus, COMSIG_BODYSTORAGE_TRY_REMOVE, beads, STORAGE_LAYER_INNER, BODYSTORAGE_REMOVE_MANUAL), "Fishing the string out should work.")
	var/list/arousal_after = list()
	SEND_SIGNAL(wearer, COMSIG_SEX_GET_AROUSAL, arousal_after)
	TEST_ASSERT_EQUAL(beads.beads_inside, 0, "A fished-out string has no beads inside.")
	TEST_ASSERT_NULL(beads.host, "A fished-out string should forget its wearer.")
	TEST_ASSERT_EQUAL(get_inner_bulk(anus), 0, "Fishing the string out should empty the hole.")
	TEST_ASSERT(arousal_after["arousal"] > arousal_before["arousal"], "Pulling the whole string at once should feel like a yank.")

/datum/unit_test/anal_beads_climax_pushes_out_unless_held/Run()
	var/mob/living/carbon/human/wearer = allocate(/mob/living/carbon/human)
	give_chastity_test_organs(wearer, list(ORGAN_SLOT_ANUS))
	var/obj/item/organ/anus = wearer.getorganslot(ORGAN_SLOT_ANUS)
	var/obj/item/anal_beads/beads = make_test_beads()
	for(var/push in 1 to 6)
		beads.push_bead(anus)
	wearer.auto_clench_override = TRUE
	SEND_SIGNAL(wearer, COMSIG_SEX_CLIMAX, null, wearer, wearer, wearer)
	TEST_ASSERT_EQUAL(beads.beads_inside, 6, "A clenching wearer should keep every bead in at climax.")
	wearer.auto_clench_override = FALSE
	SEND_SIGNAL(wearer, COMSIG_SEX_CLIMAX, null, wearer, wearer, wearer)
	TEST_ASSERT(beads.beads_inside >= 3 && beads.beads_inside <= 5, "A relaxed climax should push one to three beads out.")

/datum/unit_test/anal_bead_actions_run/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	give_chastity_test_organs(target, list(ORGAN_SLOT_ANUS))
	var/obj/item/anal_beads/beads = make_test_beads()
	user.put_in_active_hand(beads)
	var/datum/sex_scene_controller/controller = user.open_sex_scene(target, FALSE)
	var/runtimed = FALSE
	var/datum/sex_action/beads/feed/anus/feed = controller.instantiate_action(/datum/sex_action/beads/feed/anus)
	TEST_ASSERT(feed.shows_on_menu(user, target), "Held beads should offer feeding.")
	TEST_ASSERT(feed.bind_runtime(controller), "Feeding should bind to the scene.")
	TEST_ASSERT(feed.can_perform(user, target), "A bare ass should take beads.")
	var/list/arousal_before = list()
	SEND_SIGNAL(target, COMSIG_SEX_GET_AROUSAL, arousal_before)
	try
		for(var/cycle in 1 to 6)
			feed.on_perform(user, target)
	catch
		runtimed = TRUE
	user.sex_scene?.stop_action(feed)
	var/list/arousal_after = list()
	SEND_SIGNAL(target, COMSIG_SEX_GET_AROUSAL, arousal_after)
	TEST_ASSERT(!runtimed, "Feeding beads should not runtime.")
	TEST_ASSERT(beads.beads_inside >= 6, "Six feeding cycles should push at least six beads in.")
	TEST_ASSERT(arousal_after["arousal"] > arousal_before["arousal"], "Feeding beads should arouse.")

	for(var/action_type in list(/datum/sex_action/beads/tug/anus, /datum/sex_action/beads/work/anus, /datum/sex_action/beads/draw/anus))
		var/datum/sex_action/beads/action = controller.instantiate_action(action_type)
		TEST_ASSERT(action.shows_on_menu(user, target), "[action_type] should show for worn beads.")
		TEST_ASSERT(action.bind_runtime(controller), "[action_type] should bind to the scene.")
		try
			action.on_perform(user, target)
		catch
			runtimed = TRUE
		user.sex_scene?.stop_action(action)
		TEST_ASSERT(!runtimed, "[action_type] should not runtime.")
	var/inside = beads.beads_inside
	TEST_ASSERT(inside >= 4, "Beads should still be in after one draw from six or more.")

	target.cmode = TRUE
	target.auto_clench_override = TRUE
	var/datum/sex_action/beads/yank/anus/yank = controller.instantiate_action(/datum/sex_action/beads/yank/anus)
	TEST_ASSERT(yank.bind_runtime(controller), "Yanking should bind to the scene.")
	try
		yank.on_perform(user, target)
	catch
		runtimed = TRUE
	TEST_ASSERT(!runtimed, "A caught yank should not runtime.")
	TEST_ASSERT(inside - beads.beads_inside <= 2, "A clench should catch the string after one or two beads.")
	target.auto_clench_override = FALSE
	if(beads.host)
		try
			yank.on_perform(user, target)
		catch
			runtimed = TRUE
	user.sex_scene?.stop_action(yank)
	qdel(controller)
	TEST_ASSERT(!runtimed, "A full yank should not runtime.")
	TEST_ASSERT_NULL(beads.host, "A full yank should empty the hole.")
	TEST_ASSERT(user.is_holding(beads), "A yanked string should end in the yanker's hand.")

/datum/unit_test/anal_beads_bear_down_is_self_only/Run()
	var/mob/living/carbon/human/wearer = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human)
	give_chastity_test_organs(wearer, list(ORGAN_SLOT_ANUS))
	var/obj/item/anal_beads/beads = make_test_beads(/datum/bead_shape/graduated_petite)
	beads.push_bead(wearer.getorganslot(ORGAN_SLOT_ANUS))
	var/datum/sex_action/beads/bear_down/anus/bear_down = allocate(/datum/sex_action/beads/bear_down/anus)
	TEST_ASSERT(bear_down.shows_on_menu(wearer, wearer), "The wearer should be able to push beads out.")
	TEST_ASSERT(!bear_down.shows_on_menu(partner, wearer), "Bearing down is the wearer's own action.")
	var/datum/sex_action/beads/feed/vagina/feed_vagina = allocate(/datum/sex_action/beads/feed/vagina)
	partner.put_in_active_hand(make_test_beads())
	TEST_ASSERT(!feed_vagina.shows_on_menu(partner, wearer), "No pussy, no vaginal bead play.")

/datum/unit_test/anal_bead_pain_stays_arousal_pain/Run()
	var/mob/living/carbon/human/receiver = allocate(/mob/living/carbon/human)
	var/datum/component/arousal/arousal = receiver.GetComponent(/datum/component/arousal)
	TEST_ASSERT_NOTNULL(arousal, "Humans should have an arousal component.")
	var/capped = cap_bead_pain(receiver, 50, SEX_FORCE_EXTREME, SEX_SPEED_EXTREME)
	TEST_ASSERT(arousal.get_scaled_pain(capped, SEX_FORCE_EXTREME, SEX_SPEED_EXTREME) < PAIN_MINIMUM_FOR_DAMAGE, "Bead pain should stay under the body-pain threshold.")
	TEST_ASSERT_EQUAL(cap_bead_pain(receiver, 1, SEX_FORCE_LOW, SEX_SPEED_LOW), 1, "Light bead pain should pass through unchanged.")

/datum/unit_test/plugs_take_no_fluid_room/Run()
	var/obj/item/dildo/plug/wood/plug = allocate(/obj/item/dildo/plug/wood)
	TEST_ASSERT_EQUAL(plug.get_fluid_displacement(), 0, "Every plug, not just the unfinished one, should sit in the opening.")
	var/obj/item/dildo/wood/dildo = allocate(/obj/item/dildo/wood)
	TEST_ASSERT_EQUAL(dildo.get_fluid_displacement(), dildo.w_class * 10, "Other stored toys should still take room.")
