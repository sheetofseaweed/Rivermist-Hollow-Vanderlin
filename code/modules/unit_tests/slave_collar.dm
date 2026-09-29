/datum/unit_test/slave_collar_lock_blocks_drop/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/neck/slave_collar/collar = allocate(/obj/item/clothing/neck/slave_collar)
	human.equip_to_slot_if_possible(collar, ITEM_SLOT_NECK, disable_warning = TRUE)
	TEST_ASSERT_EQUAL(human.wear_neck, collar, "The collar should be worn on the neck.")

	collar.stuck = TRUE
	TEST_ASSERT(!human.dropItemToGround(collar), "A locked collar should refuse to drop.")
	TEST_ASSERT_EQUAL(human.wear_neck, collar, "A locked collar should still be worn.")

	collar.stuck = FALSE
	TEST_ASSERT(human.dropItemToGround(collar), "An unlocked collar should come off.")
	TEST_ASSERT_NULL(human.wear_neck, "An unlocked collar should leave the neck slot empty.")
