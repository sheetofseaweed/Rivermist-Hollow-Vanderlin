/datum/unit_test/quest_lockdown_keeps_erp_access

/datum/unit_test/quest_lockdown_keeps_erp_access/Run()
	var/mob/living/carbon/human/npc = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/armor/plate/plate = allocate(/obj/item/clothing/armor/plate)
	TEST_ASSERT(npc.equip_to_slot_if_possible(plate, ITEM_SLOT_ARMOR, disable_warning = TRUE), "Test setup: failed to equip plate armor.")
	var/datum/sex_action/npc/npc_vaginal_sex/action = SEX_ACTION(/datum/sex_action/npc/npc_vaginal_sex)
	TEST_ASSERT_NOTNULL(action, "The NPC vaginal sex action singleton is missing.")
	TEST_ASSERT(!action.check_location_accessible(npc, npc, BODY_ZONE_PRECISE_GROIN, TRUE), "Test setup: plate over the groin should block ERP before the lockdown.")

	npc.setup_quest_spawn_lockdown()

	TEST_ASSERT(HAS_TRAIT_FROM(plate, TRAIT_NODROP, QUEST_SPAWN_LOCK_TRAIT), "The quest lockdown must still lock worn gear in place.")
	TEST_ASSERT(action.check_location_accessible(npc, npc, BODY_ZONE_PRECISE_GROIN, TRUE), "Locked quest gear cannot come off, so it must stop blocking ERP.")

/datum/unit_test/quest_spawn_turf_skips_dense_objects

/datum/unit_test/quest_spawn_turf_skips_dense_objects/Run()
	var/obj/effect/landmark/quest_spawner/landmark = allocate(/obj/effect/landmark/quest_spawner)
	var/turf/clear_turf = get_step(landmark, EAST)
	var/turf/blocked_turf = get_step(landmark, NORTH)
	var/obj/item/blocker = allocate(/obj/item/natural/stone, blocked_turf)
	blocker.density = TRUE

	TEST_ASSERT(landmark.is_valid_spawn_turf(clear_turf), "An open floor beside the landmark should be a valid spawn turf.")
	TEST_ASSERT(!landmark.is_valid_spawn_turf(blocked_turf), "A turf holding a dense object must not be a spawn turf.")

/datum/unit_test/quest_posted_target_loss_shrinks_posting

/datum/unit_test/quest_posted_target_loss_shrinks_posting/Run()
	var/datum/quest/kill/hunt/quest = new
	quest.target_mob_type = /mob/living/simple_animal/hostile/retaliate/bigrat
	quest.target_risk_value = 2
	var/mob/living/first = allocate(/mob/living/simple_animal/hostile/retaliate/bigrat)
	var/mob/living/second = allocate(/mob/living/simple_animal/hostile/retaliate/bigrat)
	for(var/mob/living/target as anything in list(first, second))
		target.AddComponent(/datum/component/quest_object/kill, quest)
		quest.add_tracked_atom(target)
	quest.progress_required = 2
	SSquestboard.add_quest(quest)

	first.death()
	var/required_after_first = quest.progress_required
	var/progress_after_first = quest.progress_current
	var/posted_after_first = SSquestboard.is_posted(quest)
	second.death()
	var/deleted_after_second = QDELETED(quest)
	var/posted_after_second = SSquestboard.is_posted(quest)
	if(!QDELETED(quest))
		SSquestboard.remove_quest(quest)
		qdel(quest)

	TEST_ASSERT_EQUAL(required_after_first, 1, "A board posting that loses an unclaimed target must ask for one less.")
	TEST_ASSERT_EQUAL(progress_after_first, 0, "A target lost before anyone claimed the posting must not count as progress.")
	TEST_ASSERT(posted_after_first, "A posting with targets left must stay on the board.")
	TEST_ASSERT(deleted_after_second, "A posting that lost every target must be withdrawn.")
	TEST_ASSERT(!posted_after_second, "A withdrawn posting must leave the board.")

/datum/unit_test/quest_ambush_mobs_leave_with_contract

/datum/unit_test/quest_ambush_mobs_leave_with_contract/Run()
	var/datum/quest/kill/hunt/quest = new
	var/mob/living/ambusher = allocate(/mob/living/simple_animal/hostile/retaliate/bigrat)
	var/mob/living/fallen_ambusher = allocate(/mob/living/simple_animal/hostile/retaliate/bigrat)
	fallen_ambusher.death()
	quest.add_ambush_mob(ambusher)
	quest.add_ambush_mob(fallen_ambusher)

	qdel(quest)

	TEST_ASSERT(QDELETED(ambusher), "Living ambush mobs must leave when their contract ends.")
	TEST_ASSERT(!QDELETED(fallen_ambusher), "Ambush corpses stay where they fell.")

/datum/unit_test/quest_idle_leash_steers_home

/datum/unit_test/quest_idle_leash_steers_home/Run()
	var/mob/living/simple_animal/hostile/retaliate/bigrat/rat = allocate(/mob/living/simple_animal/hostile/retaliate/bigrat)
	var/datum/ai_controller/controller = rat.ai_controller
	TEST_ASSERT(istype(controller), "Test setup: the rat has no AI controller.")
	var/turf/start = get_turf(rat)
	var/turf/home = locate(start.x + 3, start.y, start.z)
	var/datum/idle_behavior/idle_random_walk/walker = new

	var/no_leash_dir = walker.get_leash_step_dir(controller, rat)
	controller.set_blackboard_key(BB_IDLE_LEASH_TURF, home)
	controller.set_blackboard_key(BB_IDLE_LEASH_RANGE, 1)
	var/strayed_dir = walker.get_leash_step_dir(controller, rat)
	controller.set_blackboard_key(BB_IDLE_LEASH_RANGE, 5)
	var/in_range_dir = walker.get_leash_step_dir(controller, rat)
	controller.set_blackboard_key(BB_IDLE_LEASH_RANGE, 1)
	var/obj/item/blocker = allocate(/obj/item/natural/stone, get_step(rat, EAST))
	blocker.density = TRUE
	var/blocked_dir = walker.get_leash_step_dir(controller, rat)
	qdel(walker)

	TEST_ASSERT_NULL(no_leash_dir, "A walker without a leash must wander freely.")
	TEST_ASSERT_EQUAL(strayed_dir, EAST, "A leashed walker past its range must step back toward its landmark.")
	TEST_ASSERT_NULL(in_range_dir, "A leashed walker within range must wander freely.")
	TEST_ASSERT_NULL(blocked_dir, "A blocked step home must fall back to a random step.")

/datum/unit_test/carnal_contract_pools

/datum/unit_test/carnal_contract_pools/Run()
	var/list/pools = list(
		"Sate and Mark" = QUEST_CARNAL_SATE_LIST,
		"Clutch Recovery" = QUEST_CARNAL_EGG_LIST,
		"Fluid Harvest" = QUEST_CARNAL_FLUID_LIST,
	)
	var/list/checked_types = list()
	for(var/pool_name in pools)
		for(var/mob_type in pools[pool_name])
			if(checked_types[mob_type])
				continue
			checked_types[mob_type] = TRUE
			var/mob/living/creature = allocate(mob_type)
			var/datum/ai_controller/controller = creature.ai_controller
			TEST_ASSERT(istype(controller), "[mob_type] in the [pool_name] pool has no AI controller.")
			TEST_ASSERT(locate(/datum/ai_planning_subtree/horny) in controller.planning_subtrees, "[mob_type] in the [pool_name] pool does not run the horny AI subtree.")
			TEST_ASSERT(controller.horny_pref_family_flag, "[mob_type] in the [pool_name] pool has no horny-mob family.")
			TEST_ASSERT_EQUAL(get_horny_family_for_mob_type(mob_type), controller.horny_pref_family_flag, "The static family lookup disagrees with [mob_type]'s live controller.")

	for(var/mob_type in QUEST_CARNAL_EGG_LIST)
		var/mob/living/layer = allocate(mob_type)
		var/obj/item/organ/genitals/penis/ovipositor/ovipositor = layer.getorganslot(ORGAN_SLOT_PENIS)
		TEST_ASSERT(istype(ovipositor), "[mob_type] in the egg pool has no ovipositor.")

	for(var/mob_type in QUEST_CARNAL_FLUID_LIST)
		var/seed_type = get_creature_fluid_type(mob_type, QUEST_FLUID_SEED)
		var/nectar_type = get_creature_fluid_type(mob_type, QUEST_FLUID_NECTAR)
		TEST_ASSERT_NOTNULL(seed_type, "[mob_type] in the fluid pool has no creature seed.")
		TEST_ASSERT_NOTNULL(nectar_type, "[mob_type] in the fluid pool has no creature nectar.")

		var/mob/living/male = allocate(mob_type)
		male.gender = MALE
		male.give_genitals()
		var/obj/item/organ/genitals/filling_organ/testicles/testes = male.getorganslot(ORGAN_SLOT_TESTICLES)
		TEST_ASSERT_NOTNULL(testes, "A male [mob_type] grew no testicles.")
		TEST_ASSERT_EQUAL(testes.reagent_to_make, seed_type, "A male [mob_type] must make its own creature seed.")
		TEST_ASSERT(testes.reagents.get_reagent_amount(seed_type) > 0, "A fresh male [mob_type] must start with some seed stored.")

		var/mob/living/female = allocate(mob_type)
		female.gender = FEMALE
		female.give_genitals()
		var/obj/item/organ/genitals/filling_organ/vagina/vagina = female.getorganslot(ORGAN_SLOT_VAGINA)
		TEST_ASSERT_NOTNULL(vagina, "A female [mob_type] grew no vagina.")
		TEST_ASSERT_EQUAL(vagina.reagent_to_make, nectar_type, "A female [mob_type] must make its own creature nectar.")

/datum/unit_test/carnal_contract_visibility_follows_prefs

/datum/unit_test/carnal_contract_visibility_follows_prefs/Run()
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human)
	var/datum/quest/kill/carnal/sate/troll_quest = new
	troll_quest.target_family_flag = HORNY_MOB_TYPE_TROLLS
	var/datum/quest/kill/carnal/fluid/nectar_quest = new
	nectar_quest.fluid_kind = QUEST_FLUID_NECTAR
	nectar_quest.target_family_flag = HORNY_MOB_TYPE_TROLLS

	viewer.set_cached_erp_preferences(null)
	var/hidden_without_prefs = !troll_quest.is_visible_to(viewer)
	viewer.set_cached_erp_preferences(list(
		/datum/erp_preference/bitflag/horny_mobs = HORNY_MOBS_TAG_MALES,
		/datum/erp_preference/bitflag/horny_mob_types = HORNY_MOB_TYPE_BEASTS,
	))
	var/hidden_for_other_family = !troll_quest.is_visible_to(viewer)
	troll_quest.prepare_for_issuer(viewer)
	var/troll_weight = troll_quest.get_mob_spawn_weight(/mob/living/simple_animal/hostile/retaliate/troll/bog)
	var/wolf_weight = troll_quest.get_mob_spawn_weight(/mob/living/simple_animal/hostile/retaliate/wolf)
	viewer.set_cached_erp_preferences(list(
		/datum/erp_preference/bitflag/horny_mobs = HORNY_MOBS_TAG_MALES,
		/datum/erp_preference/bitflag/horny_mob_types = HORNY_MOB_TYPE_TROLLS,
	))
	var/shown_for_family = troll_quest.is_visible_to(viewer)
	var/nectar_hidden_for_males_only = !nectar_quest.is_visible_to(viewer)
	qdel(troll_quest)
	qdel(nectar_quest)

	TEST_ASSERT(hidden_without_prefs, "Carnal contracts must stay hidden from players who did not opt into horny creatures.")
	TEST_ASSERT(hidden_for_other_family, "A carnal posting must stay hidden when its creature family is not allowed.")
	TEST_ASSERT_EQUAL(troll_weight, 0, "A taker's disallowed families must drop out of the creature pool.")
	TEST_ASSERT(wolf_weight > 0, "A taker's allowed families must stay in the creature pool.")
	TEST_ASSERT(shown_for_family, "A carnal posting must show when its creature family is allowed.")
	TEST_ASSERT(nectar_hidden_for_males_only, "A nectar contract needs female creatures allowed.")

/datum/unit_test/carnal_fluid_turn_in

/datum/unit_test/carnal_fluid_turn_in/Run()
	var/datum/quest/kill/carnal/fluid/quest = new
	quest.fluid_kind = QUEST_FLUID_SEED
	quest.required_fluid_type = /datum/reagent/consumable/cum/creature/troll
	quest.units_required = 10
	quest.progress_required = 1
	var/turf/input_point = run_loc_floor_bottom_left
	var/obj/item/reagent_containers/glass/bottle/first = allocate(/obj/item/reagent_containers/glass/bottle, input_point)
	first.reagents.add_reagent(/datum/reagent/consumable/cum/creature/troll, 6)
	var/obj/item/reagent_containers/glass/bottle/decoy = allocate(/obj/item/reagent_containers/glass/bottle, input_point)
	decoy.reagents.add_reagent(/datum/reagent/consumable/cum, 20)

	var/ready_short = quest.has_turn_in_goods(input_point)
	var/collected_short = quest.try_collect_turn_in_goods(input_point, null)
	var/obj/item/reagent_containers/glass/bottle/second = allocate(/obj/item/reagent_containers/glass/bottle, input_point)
	second.reagents.add_reagent(/datum/reagent/consumable/cum/creature/troll, 6)
	var/ready_full = quest.has_turn_in_goods(input_point)
	var/collected_full = quest.try_collect_turn_in_goods(input_point, null)
	var/seed_left = first.reagents.get_reagent_amount(/datum/reagent/consumable/cum/creature/troll) + second.reagents.get_reagent_amount(/datum/reagent/consumable/cum/creature/troll)
	var/decoy_left = decoy.reagents.get_reagent_amount(/datum/reagent/consumable/cum)
	var/completed = quest.complete
	qdel(quest)

	TEST_ASSERT(!ready_short, "Six units must not satisfy a ten-unit fluid contract; ordinary seed must not count.")
	TEST_ASSERT(!collected_short, "A short delivery must not complete the contract.")
	TEST_ASSERT(ready_full, "Seed split across two containers must add up.")
	TEST_ASSERT(collected_full, "A full delivery must be collected.")
	TEST_ASSERT(completed, "Collecting the fluid must complete the contract.")
	TEST_ASSERT_EQUAL(seed_left, 2, "Collection must take only the units the contract asks for.")
	TEST_ASSERT_EQUAL(decoy_left, 20, "Collection must leave other fluids alone.")

/datum/unit_test/carnal_egg_turn_in

/datum/unit_test/carnal_egg_turn_in/Run()
	var/datum/quest/kill/carnal/eggs/quest = new
	quest.required_egg_type = OVI_EGG_SPIDER
	quest.eggs_required = 2
	quest.progress_required = 1
	var/turf/input_point = run_loc_floor_bottom_left
	var/obj/item/oviposition_egg/first = allocate(/obj/item/oviposition_egg, input_point)
	first.set_egg_type(OVI_EGG_SPIDER)
	var/obj/item/oviposition_egg/decoy = allocate(/obj/item/oviposition_egg, input_point)
	decoy.set_egg_type(OVI_EGG_NORMAL)

	var/ready_short = quest.has_turn_in_goods(input_point)
	var/obj/item/oviposition_egg/second = allocate(/obj/item/oviposition_egg, input_point)
	second.set_egg_type(OVI_EGG_SPIDER)
	var/ready_full = quest.has_turn_in_goods(input_point)
	var/collected = quest.try_collect_turn_in_goods(input_point, null)
	var/took_spider_eggs = QDELETED(first) && QDELETED(second)
	var/kept_decoy = !QDELETED(decoy)
	var/completed = quest.complete
	qdel(quest)

	TEST_ASSERT(!ready_short, "One spider egg and a player's egg must not satisfy a two-egg contract.")
	TEST_ASSERT(ready_full, "Two spider eggs must satisfy the contract.")
	TEST_ASSERT(collected, "A full clutch must be collected.")
	TEST_ASSERT(took_spider_eggs, "Collection must take the contract eggs.")
	TEST_ASSERT(kept_decoy, "Collection must leave other eggs alone.")
	TEST_ASSERT(completed, "Collecting the eggs must complete the contract.")

/datum/unit_test/carnal_sate_mark_needs_spent_target

/datum/unit_test/carnal_sate_mark_needs_spent_target/Run()
	var/mob/living/carbon/human/contractor = allocate(/mob/living/carbon/human)
	var/datum/quest/kill/carnal/sate/quest = new
	quest.target_mob_type = /mob/living/simple_animal/hostile/retaliate/bigrat
	quest.quest_receiver_reference = WEAKREF(contractor)
	var/mob/living/target = allocate(/mob/living/simple_animal/hostile/retaliate/bigrat)
	var/mob/living/doomed = allocate(/mob/living/simple_animal/hostile/retaliate/bigrat)
	for(var/mob/living/creature as anything in list(target, doomed))
		creature.AddComponent(/datum/component/quest_object/kill/carnal/sate, quest)
		quest.add_tracked_atom(creature)
	quest.progress_required = 1
	quest.spawned_target_count = 2
	var/obj/item/quest_ribbons/ribbons = allocate(/obj/item/quest_ribbons)
	ribbons.bind_to_quest(quest, 2)

	doomed.death()
	var/progress_after_kill = quest.progress_current
	var/marked_while_standing = ribbons.finish_tie(target, contractor)
	target.apply_status_effect(/datum/status_effect/mob_horny_knockout)
	var/marked_while_spent = ribbons.finish_tie(target, contractor)
	var/datum/component/quest_object/kill/carnal/sate/target_tag = target.GetComponent(/datum/component/quest_object/kill/carnal/sate)
	var/tag_marked = target_tag?.marked
	var/target_still_here = !QDELETED(target)
	var/ribbons_left = ribbons.ribbons_left
	var/completed = quest.complete
	target.remove_status_effect(/datum/status_effect/mob_horny_knockout)
	qdel(quest)

	TEST_ASSERT_EQUAL(progress_after_kill, 0, "Killing a Sate and Mark creature must not count.")
	TEST_ASSERT(!marked_while_standing, "A creature that is not spent must not take a ribbon.")
	TEST_ASSERT(marked_while_spent, "A spent creature must take a ribbon.")
	TEST_ASSERT(target_still_here, "A marked creature must stay where it lies.")
	TEST_ASSERT(tag_marked, "The ribbon must mark the creature.")
	TEST_ASSERT_EQUAL(ribbons_left, 1, "Tying a ribbon must use one up.")
	TEST_ASSERT(completed, "Marking the last target must complete the contract.")

/datum/unit_test/carnal_contract_generation

/datum/unit_test/carnal_contract_generation/Run()
	var/obj/effect/landmark/quest_spawner/landmark = allocate(/obj/effect/landmark/quest_spawner)
	var/turf/landmark_turf = get_turf(landmark)
	var/mob/living/carbon/human/taker = allocate(/mob/living/carbon/human)
	taker.set_cached_erp_preferences(list(
		/datum/erp_preference/bitflag/horny_mobs = HORNY_MOBS_TAG_FEMALES,
		/datum/erp_preference/bitflag/horny_mob_types = HORNY_MOB_TYPE_BEASTS,
	))

	var/datum/quest/kill/carnal/fluid/fluid_quest = new
	fluid_quest.requested_tier = QUEST_TIER_ROUTINE
	fluid_quest.prepare_for_issuer(taker)
	var/fluid_generated = fluid_quest.generate(landmark)
	var/fluid_kind = fluid_quest.fluid_kind
	var/fluid_type = fluid_quest.required_fluid_type
	var/fluid_family = fluid_quest.target_family_flag
	var/fluid_units = fluid_quest.units_required
	var/fluid_targets = length(fluid_quest.tracked_atoms)
	var/list/problems = list()
	for(var/datum/weakref/target_ref as anything in fluid_quest.tracked_atoms)
		var/mob/living/creature = target_ref.resolve()
		if(!creature)
			problems += "a tracked creature is missing"
			continue
		if(creature.gender != FEMALE)
			problems += "[creature.type] is not female"
		var/obj/item/organ/genitals/filling_organ/vagina/vagina = creature.getorganslot(ORGAN_SLOT_VAGINA)
		if(vagina?.reagent_to_make != fluid_type)
			problems += "[creature.type] makes [vagina?.reagent_to_make]"
		if(!creature.mob_horny_defeat_enabled)
			problems += "[creature.type] cannot be horny-defeated"
		if(creature.ai_controller?.blackboard[BB_IDLE_LEASH_TURF] != landmark_turf)
			problems += "[creature.type] is not leashed to its landmark"
	qdel(fluid_quest)

	var/datum/quest/kill/carnal/sate/sate_quest = new
	sate_quest.requested_tier = QUEST_TIER_ROUTINE
	sate_quest.prepare_for_issuer(taker)
	var/sate_generated = sate_quest.generate(landmark)
	var/sate_required = sate_quest.progress_required
	var/sate_spawned = sate_quest.spawned_target_count
	qdel(sate_quest)

	var/datum/quest/kill/carnal/eggs/egg_quest = new
	egg_quest.requested_tier = QUEST_TIER_ROUTINE
	var/egg_generated = egg_quest.generate(landmark)
	var/egg_type = egg_quest.required_egg_type
	var/eggs_required = egg_quest.eggs_required
	qdel(egg_quest)

	TEST_ASSERT(fluid_generated, "A fluid contract must generate at a quest landmark.")
	TEST_ASSERT_EQUAL(fluid_kind, QUEST_FLUID_NECTAR, "A taker who allows only female creatures must get a nectar contract.")
	TEST_ASSERT(ispath(fluid_type, /datum/reagent/consumable/femcum/creature), "A nectar contract must ask for a creature nectar.")
	TEST_ASSERT_EQUAL(fluid_family, HORNY_MOB_TYPE_BEASTS, "The taker's family filter must pick the creature.")
	TEST_ASSERT(fluid_units > 0, "A fluid contract must ask for some units.")
	TEST_ASSERT(fluid_targets > 0, "A fluid contract must spawn creatures.")
	TEST_ASSERT(!length(problems), "Spawned fluid creatures are wrong: [jointext(problems, "; ")]")
	TEST_ASSERT(sate_generated, "A Sate and Mark contract must generate at a quest landmark.")
	TEST_ASSERT(sate_spawned > 0, "A Sate and Mark contract must spawn creatures.")
	TEST_ASSERT_EQUAL(sate_required, sate_spawned, "Sate and Mark must ask for one mark per creature.")
	TEST_ASSERT(egg_generated, "A clutch contract must generate at a quest landmark.")
	TEST_ASSERT(egg_type in list(OVI_EGG_SPIDER, OVI_EGG_BOG_BUG, OVI_EGG_TENTACLE), "A clutch contract must ask for a creature egg, not [egg_type].")
	TEST_ASSERT(eggs_required > 0, "A clutch contract must ask for some eggs.")
