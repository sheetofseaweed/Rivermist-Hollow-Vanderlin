// Healthy organs leave the life loop after one tick, so each test settles first and then ticks again.

/datum/unit_test/ears_temporary_deafness_wears_off_on_healthy_ears/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	tick_organ_life(human, 3)

	// Humans have paired ears and sound damage picks one at random.
	human.sound_damage(0, 5 SECONDS)
	var/obj/item/organ/ears/deaf_ear
	for(var/obj/item/organ/ears/ear as anything in human.getorganslotlist(ORGAN_SLOT_EARS))
		if(ear.temporary_deafness)
			deaf_ear = ear
	TEST_ASSERT_NOTNULL(deaf_ear, "Sound damage should start a deafness countdown.")
	TEST_ASSERT(HAS_TRAIT_FROM(human, TRAIT_DEAF, EAR_DAMAGE), "Sound damage should deafen the owner.")
	tick_organ_life(human, 8)

	TEST_ASSERT_EQUAL(deaf_ear.temporary_deafness, 0, "Temporary deafness never counted down on healthy ears.")
	TEST_ASSERT(!HAS_TRAIT_FROM(human, TRAIT_DEAF, EAR_DAMAGE), "The owner stayed deaf after the countdown should have ended.")

/datum/unit_test/cursed_heart_keeps_demanding_pumps/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/heart/cursed/heart = allocate(/obj/item/organ/heart/cursed)
	heart.Insert(human, TRUE, FALSE)
	tick_organ_life(human, 3)

	// Without a client, a due pump only resets last_pump, which proves on_life ran.
	heart.last_pump = world.time - heart.pump_delay - 1
	tick_organ_life(human, 1)
	TEST_ASSERT_EQUAL(heart.last_pump, world.time, "The cursed heart stopped checking for pumps after its first life tick.")

/datum/unit_test/lungs_failure_flag_clears_after_instant_heal/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/lungs/lungs = human.getorganslot(ORGAN_SLOT_LUNGS)
	TEST_ASSERT_NOTNULL(lungs, "A new human should have lungs.")
	tick_organ_life(human, 3)

	lungs.setOrganDamage((lungs.high_threshold + lungs.maxHealth) / 2)
	tick_organ_life(human, 1)
	TEST_ASSERT(lungs.failed, "Lungs past the high threshold should flag failure.")

	lungs.setOrganDamage(0)
	tick_organ_life(human, 2)
	TEST_ASSERT(!lungs.failed, "Fully healed lungs kept a stale failure flag.")
