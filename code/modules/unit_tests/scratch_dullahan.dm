// Scratch tests for the dullahan port. Not in the dme: include from a throwaway test build.

/datum/unit_test/scratch_dullahan_detach_attach

/datum/unit_test/scratch_dullahan_detach_attach/Run()
	var/mob/living/carbon/human/dullahan = allocate(/mob/living/carbon/human/species/dullahan)
	var/datum/species/dullahan/dullahan_species = dullahan.dna.species
	TEST_ASSERT(istype(dullahan_species), "The spawned mob should be a dullahan.")
	var/obj/item/bodypart/head/dullahan/head = dullahan.get_bodypart(BODY_ZONE_HEAD)
	TEST_ASSERT(istype(head), "A dullahan should spawn with a dullahan head, got [dullahan.get_bodypart(BODY_ZONE_HEAD)].")
	TEST_ASSERT_EQUAL(dullahan_species.my_head, head, "The species should track the fitted head.")
	var/obj/item/organ/brain/brain = dullahan.getorganslot(ORGAN_SLOT_BRAIN)
	TEST_ASSERT_NOTNULL(brain, "The dullahan should have a brain.")
	TEST_ASSERT_NOTNULL(dullahan.getorganslot(ORGAN_SLOT_LUNGS), "The dullahan should keep lungs, or blood oxygenation reads low.")
	TEST_ASSERT(dullahan.get_blood_oxygenation() >= BLOOD_VOLUME_SAFE, "A fresh dullahan should not be short of blood oxygen.")
	TEST_ASSERT_NOTNULL(dullahan_species.lift_action, "The dullahan should have a Lift Head action.")
	TEST_ASSERT(dullahan_species.lift_action.IsAvailable(), "Lift Head should be usable while whole.")
	var/obj/item/clothing/head/hat = allocate(/obj/item/clothing/head/chaperon)
	var/hat_equipped = dullahan.equip_to_slot_if_possible(hat, ITEM_SLOT_HEAD, disable_warning = TRUE, bypass_equip_delay_self = TRUE, initial = TRUE)
	TEST_ASSERT(hat_equipped, "The test hat should equip.")

	TEST_ASSERT(dullahan_species.detach_head(dullahan, null), "Detaching the head should succeed.")
	TEST_ASSERT(dullahan_species.headless, "The species should be headless after detaching.")
	TEST_ASSERT_NULL(dullahan.get_bodypart(BODY_ZONE_HEAD), "The body should have no head after detaching.")
	TEST_ASSERT_EQUAL(head.loc, get_turf(dullahan), "The head should drop at the body's feet.")
	TEST_ASSERT_EQUAL(dullahan.getorganslot(ORGAN_SLOT_BRAIN), brain, "The brain stays in the body.")
	TEST_ASSERT_NOTNULL(dullahan.getorganslot(ORGAN_SLOT_EYES), "The eyes stay in the body.")
	TEST_ASSERT_NOTNULL(dullahan.getorganslot(ORGAN_SLOT_EARS), "The ears stay in the body.")
	TEST_ASSERT(dullahan.stat != DEAD, "Losing the head must not kill a dullahan.")
	TEST_ASSERT_NULL(dullahan.has_status_effect(/datum/status_effect/defeat_knockout), "Losing the head must not be a defeat.")
	TEST_ASSERT(dullahan in GLOB.sense_relay_mobs, "A headless dullahan should be a sense relay mob.")
	TEST_ASSERT_EQUAL(dullahan.get_sense_anchor(), head, "The sense anchor should be the detached head.")
	TEST_ASSERT(HAS_TRAIT(head, TRAIT_HEARING_SENSITIVE), "The detached head should hear.")
	TEST_ASSERT(head in get_hearers_in_view(3, dullahan), "The detached head should be among hearers near it.")
	TEST_ASSERT_EQUAL(head.stored_hat, hat, "The hat should travel with the head.")
	TEST_ASSERT_EQUAL(hat.loc, head, "The hat should be inside the head.")
	TEST_ASSERT(dullahan.has_status_effect(/datum/status_effect/grouped/blindness) == null, "Looking through the head on open ground should not be blind.")
	var/debrained = FALSE
	for(var/image/overlay in head.get_limb_icon(TRUE))
		if(overlay.icon_state == "debrained")
			debrained = TRUE
	TEST_ASSERT(!debrained, "A detached dullahan head should not draw the empty-skull overlay.")
	TEST_ASSERT(!dullahan_species.lift_action.IsAvailable(), "Lift Head should be unusable while headless.")
	TEST_ASSERT(head.body_storage_bulk > WEIGHT_CLASS_NORMAL, "A head should be bulkier than a normal item for hole storage.")

	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human/species/dullahan)
	var/datum/species/dullahan/stranger_species = stranger.dna.species
	TEST_ASSERT(stranger_species.detach_head(stranger, null), "The stranger should detach too.")
	TEST_ASSERT(!head.attach_limb(stranger), "Only the owner's head fits the owner.")
	TEST_ASSERT_NULL(stranger.get_bodypart(BODY_ZONE_HEAD), "A refused attach must leave the stranger headless.")

	TEST_ASSERT(head.attach_limb(dullahan), "The owner should get the head back on.")
	TEST_ASSERT(!dullahan_species.headless, "The species should no longer be headless.")
	TEST_ASSERT_EQUAL(dullahan.get_bodypart(BODY_ZONE_HEAD), head, "The same head should be back on the body.")
	TEST_ASSERT(!(dullahan in GLOB.sense_relay_mobs), "A whole dullahan is not a sense relay mob.")
	TEST_ASSERT_EQUAL(dullahan.get_sense_anchor(), dullahan, "The sense anchor returns to the body.")
	TEST_ASSERT(!HAS_TRAIT(head, TRAIT_HEARING_SENSITIVE), "An attached head should stop hearing on its own.")
	TEST_ASSERT_EQUAL(dullahan.get_item_by_slot(ITEM_SLOT_HEAD), hat, "The hat should be worn again.")
	TEST_ASSERT_NULL(head.stored_hat, "The head should no longer store the hat.")

/datum/unit_test/scratch_dullahan_head_strike_enters_defeat

/datum/unit_test/scratch_dullahan_head_strike_enters_defeat/Run()
	var/mob/living/carbon/human/dullahan = allocate(/mob/living/carbon/human/species/dullahan)
	var/datum/species/dullahan/dullahan_species = dullahan.dna.species
	dullahan.defeat_system_ai_opt_in = TRUE
	dullahan.AddComponent(/datum/component/defeat_monitor)
	TEST_ASSERT(dullahan_species.detach_head(dullahan, null), "Detaching the head should succeed.")
	var/obj/item/bodypart/head/dullahan/head = dullahan_species.my_head
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	var/obj/item/club = allocate(/obj/item)
	club.force = 50
	for(var/i in 1 to 4)
		head.attacked_by(club, attacker)
	TEST_ASSERT(dullahan.getOrganLoss(ORGAN_SLOT_BRAIN) > 0, "Strikes on the severed head should damage the brain.")
	TEST_ASSERT(dullahan.stat != DEAD, "Strikes on the severed head must not kill outright.")
	TEST_ASSERT_NOTNULL(dullahan.has_status_effect(/datum/status_effect/defeat_knockout), "Enough strikes on the severed head should drop the dullahan into defeat.")
	TEST_ASSERT(dullahan_species.headless, "Defeat alone does not reattach the head.")
	TEST_ASSERT(!QDELETED(head), "The head survives the beating.")

/datum/unit_test/scratch_dullahan_head_loss_and_regrowth

/datum/unit_test/scratch_dullahan_head_loss_and_regrowth/Run()
	var/mob/living/carbon/human/dullahan = allocate(/mob/living/carbon/human/species/dullahan)
	var/datum/species/dullahan/dullahan_species = dullahan.dna.species
	dullahan.defeat_system_ai_opt_in = TRUE
	dullahan.AddComponent(/datum/component/defeat_monitor)
	TEST_ASSERT(dullahan_species.detach_head(dullahan, null), "Detaching the head should succeed.")
	var/obj/item/bodypart/head/dullahan/head = dullahan_species.my_head
	qdel(head)
	TEST_ASSERT_NULL(dullahan_species.my_head, "A destroyed head should be forgotten.")
	TEST_ASSERT(dullahan.stat != DEAD, "A defeat-eligible dullahan whose head is destroyed should not die.")
	TEST_ASSERT_NOTNULL(dullahan.has_status_effect(/datum/status_effect/defeat_knockout), "Head destruction should route into defeat.")
	TEST_ASSERT(!(dullahan in GLOB.sense_relay_mobs), "No head, no relay.")
	dullahan.revive(HEAL_ALL)
	var/obj/item/bodypart/head/dullahan/new_head = dullahan.get_bodypart(BODY_ZONE_HEAD)
	TEST_ASSERT(istype(new_head), "Revival should grow a new dullahan head, got [dullahan.get_bodypart(BODY_ZONE_HEAD)].")
	TEST_ASSERT(!dullahan_species.headless, "The regrown head should count as attached.")
	TEST_ASSERT_EQUAL(dullahan_species.my_head, new_head, "The species should track the regrown head.")

	var/mob/living/carbon/human/mortal = allocate(/mob/living/carbon/human/species/dullahan)
	var/datum/species/dullahan/mortal_species = mortal.dna.species
	TEST_ASSERT(mortal_species.detach_head(mortal, null), "Detaching the mortal's head should succeed.")
	qdel(mortal_species.my_head)
	TEST_ASSERT_EQUAL(mortal.stat, DEAD, "Without defeat eligibility, losing the head outright is death.")

/datum/unit_test/scratch_dullahan_revive_recalls_head

/datum/unit_test/scratch_dullahan_revive_recalls_head/Run()
	var/mob/living/carbon/human/dullahan = allocate(/mob/living/carbon/human/species/dullahan)
	var/datum/species/dullahan/dullahan_species = dullahan.dna.species
	var/mob/living/carbon/human/thief = allocate(/mob/living/carbon/human)
	thief.forceMove(run_loc_floor_top_right)
	TEST_ASSERT(dullahan_species.detach_head(dullahan, thief), "The thief should take the head.")
	var/obj/item/bodypart/head/dullahan/head = dullahan_species.my_head
	TEST_ASSERT(thief.is_holding(head), "The thief should hold the head.")
	TEST_ASSERT_EQUAL(dullahan.get_sense_anchor(), head, "The anchor is the held head.")
	TEST_ASSERT_EQUAL(dullahan_species.get_default_perspective(dullahan), thief, "Looking through a held head looks from the holder.")
	dullahan.revive(HEAL_ALL)
	TEST_ASSERT(!dullahan_species.headless, "Revival should bring the head home.")
	TEST_ASSERT_EQUAL(dullahan.get_bodypart(BODY_ZONE_HEAD), head, "The original head should be back on.")
	TEST_ASSERT(!thief.is_holding(head), "The thief should no longer hold the head.")

/datum/unit_test/scratch_dullahan_species_loss_restores_plain_head

/datum/unit_test/scratch_dullahan_species_loss_restores_plain_head/Run()
	var/mob/living/carbon/human/dullahan = allocate(/mob/living/carbon/human/species/dullahan)
	var/datum/species/dullahan/dullahan_species = dullahan.dna.species
	TEST_ASSERT(dullahan_species.detach_head(dullahan, null), "Detaching the head should succeed.")
	dullahan.set_species(/datum/species/human/northern)
	var/obj/item/bodypart/head/new_head = dullahan.get_bodypart(BODY_ZONE_HEAD)
	TEST_ASSERT(istype(new_head), "A former dullahan should have a head again.")
	TEST_ASSERT(!istype(new_head, /obj/item/bodypart/head/dullahan), "A former dullahan should wear a plain head.")
	TEST_ASSERT(dullahan.stat != DEAD, "Losing the species must not kill.")
	TEST_ASSERT(!(dullahan in GLOB.sense_relay_mobs), "A former dullahan is not a relay mob.")
	TEST_ASSERT_EQUAL(dullahan.get_sense_anchor(), dullahan, "A former dullahan senses from its body.")

/datum/unit_test/scratch_dullahan_head_context_reaches_mouth_only

/datum/unit_test/scratch_dullahan_head_context_reaches_mouth_only/Run()
	var/mob/living/carbon/human/dullahan = allocate(/mob/living/carbon/human/species/dullahan)
	var/datum/species/dullahan/dullahan_species = dullahan.dna.species
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human)
	TEST_ASSERT(dullahan_species.detach_head(dullahan, null), "Detaching the head should succeed.")
	var/obj/item/bodypart/head/dullahan/head = dullahan_species.my_head
	TEST_ASSERT(partner.put_in_hands(head), "The partner should pick up the head.")
	partner.forceMove(run_loc_floor_top_right)
	TEST_ASSERT(get_dist(partner, dullahan) > 1, "The partner should be out of body reach.")

	head.MiddleMouseDrop_T(partner, partner)
	var/datum/sex_scene/scene = partner.sex_scene
	TEST_ASSERT_NOTNULL(scene, "Dragging onto the head should open a scene.")
	TEST_ASSERT(dullahan in scene.participants, "The head's owner should join the scene.")
	var/datum/sex_remote_context/dullahan_head/to_head = scene.get_remote_context(partner, dullahan, null)
	var/datum/sex_remote_context/dullahan_head/from_head = scene.get_remote_context(dullahan, partner, null)
	TEST_ASSERT(istype(to_head), "The partner should get a head context toward the dullahan.")
	TEST_ASSERT(istype(from_head), "The dullahan should get a head context toward the partner.")
	TEST_ASSERT(to_head.is_valid(scene), "A held head is a valid context.")

	var/datum/sex_action/kissing/kiss = new
	var/datum/sex_action/blowjob/suck = new
	var/datum/sex_action/tonguebath/lick = new
	var/datum/sex_action/rub_body/rub = new
	TEST_ASSERT(to_head.allows_action(kiss), "Kissing the held head is allowed.")
	TEST_ASSERT(!to_head.allows_action(suck), "The partner cannot suck the dullahan's genitals through the head.")
	TEST_ASSERT(!to_head.allows_action(lick), "The partner cannot lick the dullahan's body through the head.")
	TEST_ASSERT(!to_head.allows_action(rub), "Body rubbing never goes through the head.")
	TEST_ASSERT(from_head.allows_action(kiss), "The dullahan can kiss back through the head.")
	TEST_ASSERT(from_head.allows_action(suck), "The dullahan can use their mouth on the partner through the held head.")
	TEST_ASSERT(from_head.allows_action(lick), "The dullahan can lick the partner through the held head.")
	TEST_ASSERT(!from_head.allows_action(rub), "The dullahan cannot rub with far-away hands.")
	qdel(kiss)
	qdel(suck)
	qdel(lick)
	qdel(rub)

	var/datum/sex_scene_controller/session = scene.get_controller(partner)
	TEST_ASSERT_NOTNULL(session, "The partner should own a controller.")
	var/datum/sex_action_proposal/proposal = session.create_action_proposal(/datum/sex_action/kissing, "unit_test")
	TEST_ASSERT_NOTNULL(proposal?.action, "A kissing proposal should build.")
	TEST_ASSERT_EQUAL(proposal.action.remote_context, to_head, "The kissing proposal should carry the head context.")
	TEST_ASSERT(proposal.action.can_remote_interact(), "Kissing through the head counts as remote interaction.")
	TEST_ASSERT(!proposal.action.begin_remote_visible_message_suppression(), "Head contexts keep ordinary visible messages.")
	qdel(proposal)
	var/datum/sex_action_proposal/rub_proposal = session.create_action_proposal(/datum/sex_action/rub_body, "unit_test")
	TEST_ASSERT_NOTNULL(rub_proposal?.action, "A rub proposal should build.")
	TEST_ASSERT_NULL(rub_proposal.action.remote_context, "Body actions get no head context.")
	qdel(rub_proposal)

	TEST_ASSERT(dullahan.has_mouth(), "A headless dullahan still has a mouth, on the head.")

	partner.dropItemToGround(head, force = TRUE)
	partner.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT(!to_head.is_valid(scene), "A head left behind out of reach invalidates the context.")

	head.forceMove(get_turf(dullahan))
	TEST_ASSERT(head.attach_limb(dullahan), "The owner should get the head back.")
	TEST_ASSERT(QDELETED(to_head), "Reattaching clears the head context.")
	TEST_ASSERT(QDELETED(from_head), "Reattaching clears the reverse head context too.")
	qdel(session)

/datum/unit_test/scratch_dullahan_head_context_from_scene_open

/datum/unit_test/scratch_dullahan_head_context_from_scene_open/Run()
	var/mob/living/carbon/human/dullahan = allocate(/mob/living/carbon/human/species/dullahan)
	var/datum/species/dullahan/dullahan_species = dullahan.dna.species
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human)
	partner.forceMove(run_loc_floor_top_right)
	TEST_ASSERT(dullahan_species.detach_head(dullahan, null), "Detaching the head should succeed.")
	var/obj/item/bodypart/head/dullahan/head = dullahan_species.my_head
	var/datum/sex_scene_controller/session = dullahan.open_sex_scene(partner, show_ui = FALSE)
	TEST_ASSERT_NOTNULL(session, "The dullahan should open a scene from afar.")
	TEST_ASSERT_NULL(session.scene.get_remote_context(dullahan, partner, null), "No context while the head is far from the partner.")
	head.forceMove(get_turf(partner))
	var/datum/sex_remote_context/dullahan_head/context = session.scene.get_remote_context(dullahan, partner, null)
	TEST_ASSERT(istype(context), "Moving the head onto the partner's tile should create the context.")
	TEST_ASSERT(context.is_valid(session.scene), "A head on the partner's tile is valid.")
	qdel(session)

/datum/unit_test/scratch_dullahan_polish_flame_bite_feed

/datum/unit_test/scratch_dullahan_polish_flame_bite_feed/Run()
	var/mob/living/carbon/human/dullahan = allocate(/mob/living/carbon/human/species/dullahan)
	var/datum/species/dullahan/dullahan_species = dullahan.dna.species
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human)
	partner.forceMove(run_loc_floor_top_right)
	TEST_ASSERT(!dullahan.bite_reach(partner), "A whole dullahan cannot bite someone far away.")
	TEST_ASSERT(dullahan_species.detach_head(dullahan, null), "Detaching the head should succeed.")
	var/obj/item/bodypart/head/dullahan/head = dullahan_species.my_head

	var/found_flame = FALSE
	for(var/mutable_appearance/overlay in dullahan.overlays_standing[BODY_LAYER])
		if(overlay.icon_state == "neckfire")
			found_flame = TRUE
	TEST_ASSERT(found_flame, "A headless dullahan should show the neck flame.")

	TEST_ASSERT(!dullahan.bite_reach(partner), "A head on the floor far from the partner cannot bite them.")
	TEST_ASSERT(!dullahan.is_facing_feeder(partner), "A partner far from the head cannot feed the dullahan.")
	TEST_ASSERT(partner.put_in_hands(head), "The partner should pick up the head.")
	TEST_ASSERT(dullahan.bite_reach(partner), "A dullahan bites whoever holds their head.")
	TEST_ASSERT(dullahan.is_facing_feeder(partner), "Whoever holds the head can feed the dullahan.")
	var/obj/item/reagent_containers/food/snacks/badrecipe/snack = allocate(/obj/item/reagent_containers/food/snacks/badrecipe)
	TEST_ASSERT(snack.canconsume(dullahan, partner), "Feeding through the held head should pass the consume gate.")

	partner.dropItemToGround(head, force = TRUE)
	head.forceMove(get_turf(dullahan))
	TEST_ASSERT(head.attach_limb(dullahan), "The owner should get the head back.")
	found_flame = FALSE
	for(var/mutable_appearance/overlay in dullahan.overlays_standing[BODY_LAYER])
		if(overlay.icon_state == "neckfire")
			found_flame = TRUE
	TEST_ASSERT(!found_flame, "A whole dullahan shows no neck flame.")

/datum/unit_test/scratch_dullahan_head_wardrobe

/datum/unit_test/scratch_dullahan_head_wardrobe/Run()
	var/mob/living/carbon/human/dullahan = allocate(/mob/living/carbon/human/species/dullahan)
	var/datum/species/dullahan/dullahan_species = dullahan.dna.species
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/head/hat = allocate(/obj/item/clothing/head/chaperon)
	TEST_ASSERT(dullahan.equip_to_slot_if_possible(hat, ITEM_SLOT_HEAD, disable_warning = TRUE, bypass_equip_delay_self = TRUE, initial = TRUE), "The test hat should equip.")
	TEST_ASSERT(dullahan_species.detach_head(dullahan, null), "Detaching the head should succeed.")
	var/obj/item/bodypart/head/dullahan/head = dullahan_species.my_head
	TEST_ASSERT_EQUAL(head.stored_hat, hat, "The hat rides on the head.")
	TEST_ASSERT(head.user_can_reach(partner), "A partner on the head's tile can reach it.")

	TEST_ASSERT(head.strip_stored_item(partner, "head"), "Stripping the hat should succeed.")
	TEST_ASSERT_NULL(head.stored_hat, "The head should no longer store the hat.")
	TEST_ASSERT(partner.is_holding(hat), "The partner should hold the stripped hat.")

	TEST_ASSERT(!head.dress_stored_item(partner, "mask"), "A hat does not go in the mask slot.")
	TEST_ASSERT(head.dress_stored_item(partner, "head"), "Dressing the head with the hat should succeed.")
	TEST_ASSERT_EQUAL(head.stored_hat, hat, "The head should store the hat again.")
	TEST_ASSERT_EQUAL(hat.loc, head, "The hat should be inside the head.")
	TEST_ASSERT(!partner.is_holding(hat), "The partner should no longer hold the hat.")

	TEST_ASSERT(head.attach_limb(dullahan), "The owner should get the head back.")
	TEST_ASSERT_EQUAL(dullahan.get_item_by_slot(ITEM_SLOT_HEAD), hat, "The hat should be worn again.")

/datum/unit_test/scratch_dullahan_self_oral_with_held_head

/datum/unit_test/scratch_dullahan_self_oral_with_held_head/Run()
	var/mob/living/carbon/human/dullahan = allocate(/mob/living/carbon/human/species/dullahan)
	var/datum/species/dullahan/dullahan_species = dullahan.dna.species
	if(!dullahan.getorganslot(ORGAN_SLOT_PENIS))
		var/obj/item/organ/genitals/penis/penis = allocate(/obj/item/organ/genitals/penis)
		penis.Insert(dullahan)
	TEST_ASSERT_NOTNULL(dullahan.getorganslot(ORGAN_SLOT_PENIS), "The test dullahan needs a penis.")
	var/datum/sex_action/blowjob/plain = new
	var/datum/sex_action/blowjob/own_head/own = new
	TEST_ASSERT(!own.shows_on_menu(dullahan, dullahan), "Self-oral needs the head off and in hand.")
	TEST_ASSERT(dullahan_species.detach_head(dullahan, dullahan), "Detaching into the own hand should succeed.")
	var/obj/item/bodypart/head/dullahan/head = dullahan_species.my_head
	TEST_ASSERT(dullahan.is_holding(head), "The dullahan should hold their own head.")
	TEST_ASSERT(!plain.shows_on_menu(dullahan, dullahan), "The plain blowjob never targets yourself.")
	TEST_ASSERT(own.shows_on_menu(dullahan, dullahan), "Holding your own head unlocks self-oral.")
	qdel(plain)
	qdel(own)

	var/datum/sex_scene_controller/session = dullahan.open_sex_scene(dullahan, show_ui = FALSE)
	TEST_ASSERT_NOTNULL(session, "A dullahan should open a scene on themselves.")
	var/datum/sex_remote_context/dullahan_head/context = session.scene.get_remote_context(dullahan, dullahan, null)
	TEST_ASSERT(istype(context), "Holding your own head should create a self context.")
	var/datum/sex_action/action = session.try_start_action(/datum/sex_action/blowjob/own_head, "unit_test")
	TEST_ASSERT_NOTNULL(action, "Self-oral through the held head should start.")
	TEST_ASSERT_EQUAL(action.remote_context, context, "The self-oral action should run through the head context.")
	action.stop_runtime()
	qdel(session)

/datum/unit_test/scratch_dullahan_held_head_on_others

/datum/unit_test/scratch_dullahan_held_head_on_others/Run()
	var/mob/living/carbon/human/dullahan = allocate(/mob/living/carbon/human/species/dullahan)
	var/datum/species/dullahan/dullahan_species = dullahan.dna.species
	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/third = allocate(/mob/living/carbon/human)
	if(!third.getorganslot(ORGAN_SLOT_PENIS))
		var/obj/item/organ/genitals/penis/penis = allocate(/obj/item/organ/genitals/penis)
		penis.Insert(third)
	TEST_ASSERT(dullahan_species.detach_head(dullahan, holder), "The holder should take the head.")
	var/obj/item/bodypart/head/dullahan/head = dullahan_species.my_head
	TEST_ASSERT(holder.is_holding(head), "The holder should hold the head.")
	holder.forceMove(run_loc_floor_top_right)
	third.forceMove(run_loc_floor_top_right)

	var/datum/sex_action/held_head_oral/penis/use_head = new
	var/datum/sex_scene_controller/session = holder.open_sex_scene(third, show_ui = FALSE)
	TEST_ASSERT_NOTNULL(session, "The holder should open a scene with the third person.")
	TEST_ASSERT(use_head.shows_on_menu(holder, third), "Holding a live foreign head is enough for the menu; the owner joins at start.")
	TEST_ASSERT_NOTNULL(holder.open_sex_scene(dullahan, show_ui = FALSE), "The holder should bring the head's owner into the scene.")
	session = holder.open_sex_scene(third, show_ui = FALSE)
	TEST_ASSERT_NOTNULL(session, "The holder should still control the scene toward the third person.")
	TEST_ASSERT(dullahan in session.scene.participants, "The head's owner should share the merged scene.")
	TEST_ASSERT(use_head.shows_on_menu(holder, third), "With the owner in the scene the held head can be used on the third person.")
	qdel(use_head)

	var/datum/sex_action/action = session.try_start_action(/datum/sex_action/held_head_oral/penis, "unit_test")
	TEST_ASSERT_NOTNULL(action, "Using the held head on the third person should start.")
	sleep(5 SECONDS)
	TEST_ASSERT(!QDELETED(action), "The held-head action should survive its first cycle.")
	var/mouth_locked = FALSE
	for(var/datum/sex_scene_resource_claim/claim as anything in action.resource_claims)
		if(claim.locked_host == dullahan && claim.locked_organ_slot == BODY_ZONE_PRECISE_MOUTH)
			mouth_locked = TRUE
	TEST_ASSERT(mouth_locked, "The head owner's mouth should be locked by the action.")
	action.stop_runtime()

	var/datum/sex_scene_controller/head_session = holder.open_sex_scene(dullahan, show_ui = FALSE)
	var/datum/sex_action/tuck = head_session.try_start_action(/datum/sex_action/thigh_head, "unit_test")
	TEST_ASSERT_NOTNULL(tuck, "Tucking the held head between the thighs should start.")
	tuck.stop_runtime()

	// Far-body report: the body is far from the head and looking through it.
	TEST_ASSERT(dullahan_species.viewing_head, "The dullahan should be looking through the head.")
	var/datum/sex_action/rub_body/probe = new
	dullahan_species.on_owner_feels_action(dullahan, probe, dullahan, holder)
	TEST_ASSERT_EQUAL(dullahan_species.last_felt_action_ref?.resolve(), probe, "The body should report a far-away action once.")
	qdel(probe)
	qdel(session)

/datum/unit_test/scratch_dullahan_held_head_pleasure_routing

/datum/unit_test/scratch_dullahan_held_head_pleasure_routing/Run()
	var/mob/living/carbon/human/dullahan = allocate(/mob/living/carbon/human/species/dullahan)
	var/datum/species/dullahan/dullahan_species = dullahan.dna.species
	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/third = allocate(/mob/living/carbon/human)
	if(!third.getorganslot(ORGAN_SLOT_PENIS))
		var/obj/item/organ/genitals/penis/penis = allocate(/obj/item/organ/genitals/penis)
		penis.Insert(third)
	TEST_ASSERT(dullahan_species.detach_head(dullahan, holder), "The holder should take the head.")
	holder.forceMove(run_loc_floor_top_right)
	third.forceMove(run_loc_floor_top_right)
	var/datum/sex_scene_controller/session = holder.open_sex_scene(third, show_ui = FALSE)
	TEST_ASSERT_NOTNULL(session, "The holder should open a scene with the third person.")
	TEST_ASSERT(!(dullahan in session.scene.participants), "The owner starts outside the scene.")
	session.set_current_speed(SEX_SPEED_EXTREME)
	var/datum/sex_action/action = session.try_start_action(/datum/sex_action/held_head_oral/penis, "unit_test")
	TEST_ASSERT_NOTNULL(action, "Using the held head should start without the owner pre-joined.")
	sleep(8 SECONDS)
	TEST_ASSERT(!QDELETED(action), "The held-head action should keep running.")
	TEST_ASSERT(dullahan in session.scene.participants, "Starting the action should pull the owner into the scene.")
	var/datum/component/arousal/holder_arousal = holder.GetComponent(/datum/component/arousal)
	var/datum/component/arousal/third_arousal = third.GetComponent(/datum/component/arousal)
	var/datum/component/arousal/dullahan_arousal = dullahan.GetComponent(/datum/component/arousal)
	TEST_ASSERT(third_arousal?.arousal > 0, "The receiver should be aroused, got [third_arousal?.arousal].")
	TEST_ASSERT(dullahan_arousal?.arousal > 0, "The head's owner should feel it too, got [dullahan_arousal?.arousal].")
	TEST_ASSERT(!holder_arousal || holder_arousal.arousal <= 0, "The holder should get nothing from someone else's mouth, got [holder_arousal?.arousal].")
	action.stop_runtime()
	qdel(session)

/datum/unit_test/scratch_dullahan_held_head_on_own_pussy

/datum/unit_test/scratch_dullahan_held_head_on_own_pussy/Run()
	var/mob/living/carbon/human/dullahan = allocate(/mob/living/carbon/human/species/dullahan)
	var/datum/species/dullahan/dullahan_species = dullahan.dna.species
	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human)
	if(!holder.getorganslot(ORGAN_SLOT_VAGINA))
		var/obj/item/organ/genitals/filling_organ/vagina/vagina = allocate(/obj/item/organ/genitals/filling_organ/vagina)
		vagina.Insert(holder)
	TEST_ASSERT(dullahan_species.detach_head(dullahan, holder), "The holder should take the head.")
	holder.forceMove(run_loc_floor_top_right)
	var/datum/sex_scene_controller/session = holder.open_sex_scene(holder, show_ui = FALSE)
	TEST_ASSERT_NOTNULL(session, "The holder should open a scene on themselves.")
	var/datum/sex_action/held_head_oral/vagina/use_head = new
	TEST_ASSERT(use_head.shows_on_menu(holder, holder), "Holding a dullahan's head should offer pressing it to your own cunt.")
	qdel(use_head)
	var/datum/sex_action/action = session.try_start_action(/datum/sex_action/held_head_oral/vagina, "unit_test")
	TEST_ASSERT_NOTNULL(action, "Pressing the held head to your own cunt should start.")
	TEST_ASSERT(dullahan in session.scene.participants, "The head's owner should join the self scene.")
	action.stop_runtime()
	qdel(session)
