/datum/unit_test/change_next_def_adjusts_active_intent/Run()
	var/mob/living/carbon/human/dummy = allocate(/mob/living/carbon/human)
	dummy.d_intent = INTENT_DODGE
	dummy.changeNext_def(20)
	TEST_ASSERT_EQUAL(dummy.dodgetime, 20, "changeNext_def on dodge intent must set dodgetime")
	dummy.d_intent = INTENT_PARRY
	dummy.changeNext_def(18)
	TEST_ASSERT_EQUAL(dummy.setparrytime, 18, "changeNext_def on parry intent must set setparrytime")

/datum/unit_test/change_next_def_clamps/Run()
	var/mob/living/carbon/human/dummy = allocate(/mob/living/carbon/human)
	dummy.d_intent = INTENT_DODGE
	dummy.changeNext_def(999)
	TEST_ASSERT_EQUAL(dummy.dodgetime, DEFENSE_CD_MAX, "changeNext_def must clamp to DEFENSE_CD_MAX")
	dummy.changeNext_def(-50)
	TEST_ASSERT_EQUAL(dummy.dodgetime, DEFENSE_CD_MIN, "changeNext_def must clamp to DEFENSE_CD_MIN")

/datum/unit_test/defense_cooldowns_reset_out_of_combat/Run()
	var/mob/living/carbon/human/dummy = allocate(/mob/living/carbon/human)
	dummy.dodgetime = 30
	dummy.setparrytime = 30
	dummy.reset_defense_cooldowns()
	TEST_ASSERT_EQUAL(dummy.dodgetime, initial(dummy.dodgetime), "Dodge cooldown must reset to the mob's compiled baseline")
	TEST_ASSERT_EQUAL(dummy.setparrytime, initial(dummy.setparrytime), "Parry cooldown must reset to the mob's compiled baseline")

/datum/unit_test/change_next_def_noop_without_defense_intent/Run()
	var/mob/living/carbon/human/dummy = allocate(/mob/living/carbon/human)
	var/old_dodge = dummy.dodgetime
	var/old_parry = dummy.setparrytime
	dummy.d_intent = 999 // arbitrary non-defense intent value (d_intent is unvalidated client input elsewhere)
	dummy.changeNext_def(20)
	TEST_ASSERT_EQUAL(dummy.dodgetime, old_dodge, "changeNext_def must not touch dodgetime without a defensive intent")
	TEST_ASSERT_EQUAL(dummy.setparrytime, old_parry, "changeNext_def must not touch setparrytime without a defensive intent")
