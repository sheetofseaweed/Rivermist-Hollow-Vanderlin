/**
 * Tests that mana-capacity gear keeps overload threshold in step with the
 * extra hardcap it grants, and that both values revert when unequipped.
 */
/datum/unit_test/mana_capacity_enchantment_updates_overload_threshold

/datum/unit_test/mana_capacity_enchantment_updates_overload_threshold/Run()
	var/mob/living/carbon/human/wizard = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/neck/mana_star/mana_star = allocate(/obj/item/clothing/neck/mana_star)
	var/datum/enchantment/mana_capacity/capacity_enchant = mana_star.get_enchantment(/datum/enchantment/mana_capacity)

	TEST_ASSERT_NOTNULL(capacity_enchant, "Mana star failed to initialize its mana capacity enchantment.")
	TEST_ASSERT_NOTNULL(wizard.mana_pool, "Wizard test mob did not initialize with a mana pool.")

	var/starting_max = wizard.mana_pool.maximum_mana_capacity
	var/starting_threshold = wizard.mana_overload_threshold
	var/starting_softcap = wizard.mana_pool.softcap

	capacity_enchant.on_equip(mana_star, wizard, ITEM_SLOT_NECK)
	TEST_ASSERT_EQUAL(wizard.mana_pool.maximum_mana_capacity, starting_max + capacity_enchant.hardcap_increase, "Mana capacity enchantment did not raise the wizard's max mana.")
	TEST_ASSERT_EQUAL(wizard.mana_overload_threshold, starting_threshold + capacity_enchant.hardcap_increase, "Mana capacity enchantment did not raise the wizard's overload threshold alongside max mana.")
	TEST_ASSERT_EQUAL(wizard.mana_pool.softcap, starting_softcap, "Mana capacity enchantment should not move the softcap on equip.")

	capacity_enchant.on_drop(mana_star, wizard)
	TEST_ASSERT_EQUAL(wizard.mana_pool.maximum_mana_capacity, starting_max, "Mana capacity enchantment did not restore the wizard's max mana after being removed.")
	TEST_ASSERT_EQUAL(wizard.mana_overload_threshold, starting_threshold, "Mana capacity enchantment did not restore the wizard's overload threshold after being removed.")
	TEST_ASSERT_EQUAL(wizard.mana_pool.softcap, starting_softcap, "Mana capacity enchantment should not move the softcap on drop.")

	// Repeated equip/drop cycles must not drift any value (regression: softcap
	// was sinking by hardcap_increase every cycle, reaching negative thousands).
	for(var/i in 1 to 5)
		capacity_enchant.on_equip(mana_star, wizard, ITEM_SLOT_NECK)
		capacity_enchant.on_drop(mana_star, wizard)

	TEST_ASSERT_EQUAL(wizard.mana_pool.maximum_mana_capacity, starting_max, "Repeated equip/drop cycles drifted the wizard's max mana.")
	TEST_ASSERT_EQUAL(wizard.mana_overload_threshold, starting_threshold, "Repeated equip/drop cycles drifted the wizard's overload threshold.")
	TEST_ASSERT_EQUAL(wizard.mana_pool.softcap, starting_softcap, "Repeated equip/drop cycles drifted the wizard's softcap.")
