/mob/living/armor_damage_test_dummy
	var/test_armor = 0

/mob/living/armor_damage_test_dummy/getarmor(def_zone, type, damage, armor_penetration, blade_dulling, intdamfactor = 1, used_weapon, mob/living/attacker)
	return test_armor

/datum/unit_test/armor_damage_legacy_raw_armor_normalizes_to_heavy/Run()
	var/mob/living/armor_damage_test_dummy/dummy = allocate(/mob/living/armor_damage_test_dummy)
	dummy.test_armor = 70

	var/blocked = dummy.run_armor_check(attack_flag = "slash", armor_penetration = 25, damage = 10)

	TEST_ASSERT_EQUAL(blocked, 100, "Legacy raw 70 armor should normalize to heavy and fully block medium penetration")

/datum/unit_test/armor_damage_legacy_raw_penetration_normalizes_to_heavy/Run()
	var/mob/living/armor_damage_test_dummy/dummy = allocate(/mob/living/armor_damage_test_dummy)
	dummy.test_armor = 70

	var/blocked = dummy.run_armor_check(attack_flag = "stab", armor_penetration = 35, damage = 20)

	TEST_ASSERT_EQUAL(blocked, 18, "Legacy raw 35 penetration should normalize to heavy and allow 10 percent passthrough")

/datum/unit_test/armor_damage_dblock_below_tier_fully_blocks/Run()
	var/mob/living/armor_damage_test_dummy/dummy = allocate(/mob/living/armor_damage_test_dummy)
	dummy.test_armor = 50

	var/blocked = dummy.run_armor_check(attack_flag = "slash", armor_penetration = 25, damage = 10)

	TEST_ASSERT_EQUAL(blocked, 100, "DBLOCK armor should fully block attacks below its tier")

/datum/unit_test/armor_damage_dblock_equal_tier_allows_passthrough/Run()
	var/mob/living/armor_damage_test_dummy/dummy = allocate(/mob/living/armor_damage_test_dummy)
	dummy.test_armor = 25

	var/blocked = dummy.run_armor_check(attack_flag = "stab", armor_penetration = 25, damage = 20)

	TEST_ASSERT_EQUAL(blocked, 18, "DBLOCK armor should allow 10 percent passthrough when penetration meets tier")

/datum/unit_test/armor_damage_blunt_dr_absorbs_hp_damage/Run()
	var/mob/living/armor_damage_test_dummy/dummy = allocate(/mob/living/armor_damage_test_dummy)
	dummy.test_armor = 50

	var/blocked = dummy.run_armor_check(attack_flag = "blunt", armor_penetration = 0, damage = 10)

	TEST_ASSERT_EQUAL(blocked, 10, "Blunt DR armor should absorb HP damage")

/datum/unit_test/armor_damage_fire_dr_pierce_reduces_hp_damage/Run()
	var/mob/living/armor_damage_test_dummy/dummy = allocate(/mob/living/armor_damage_test_dummy)
	dummy.test_armor = 50

	var/blocked = dummy.run_armor_check(attack_flag = "fire", armor_penetration = 0, damage = 16)

	TEST_ASSERT_EQUAL(blocked, 6, "Fire DR armor should reduce, not fully absorb, incoming HP damage")

/datum/unit_test/weapon_pen_sword_thrust_is_medium/Run()
	TEST_ASSERT_EQUAL(normalize_penetration(AP_SWORD_THRUST), ARMOR_TIER_MEDIUM, "Sword thrust should normalize to medium pen tier (TA: penetrates player light armor)")

/datum/unit_test/weapon_pen_spear_thrust_is_heavy/Run()
	TEST_ASSERT_EQUAL(normalize_penetration(AP_SPEAR_THRUST), ARMOR_TIER_HEAVY, "Spear thrust should normalize to heavy pen tier (TA: penetrates mail/brigandine/plate)")

/datum/unit_test/weapon_pen_axe_chop_is_light/Run()
	TEST_ASSERT_EQUAL(normalize_penetration(AP_AXE_CHOP), ARMOR_TIER_LIGHT, "Axe chop should stay light pen tier")

/datum/unit_test/weapon_pen_greataxe_chop_is_medium/Run()
	TEST_ASSERT_EQUAL(normalize_penetration(AP_GREATAXE_CHOP), ARMOR_TIER_MEDIUM, "Greataxe chop should normalize to medium pen tier")

/datum/unit_test/armor_define_cuirass_not_bsteel/Run()
	var/list/cuirass = ARMOR_CUIRASS
	TEST_ASSERT_EQUAL(normalize_armor_rating("slash", cuirass["slash"]), ARMOR_TIER_HEAVY, "Cuirass slash protection should be heavy tier, not blacksteel")

/datum/unit_test/armor_define_studded_blunt_capped/Run()
	var/list/studded = ARMOR_LEATHER_STUDDED
	TEST_ASSERT_EQUAL(normalize_armor_rating("blunt", studded["blunt"]), ARMOR_TIER_ULTRA, "Studded leather blunt DR should normalize to ultra tier")
	TEST_ASSERT_EQUAL(normalize_armor_rating("slash", studded["slash"]), ARMOR_TIER_MEDIUM, "Studded leather is player light armor: DBLOCK_MEDIUM vs slash")

/datum/unit_test/armor_pen_overmatch_increases_passthrough/Run()
	var/mob/living/armor_damage_test_dummy/dummy = allocate(/mob/living/armor_damage_test_dummy)
	dummy.test_armor = DBLOCK_LIGHT // tier 1 armor

	// Equal-tier pen vs big overmatch: overmatch must let more damage through (= block less)
	var/blocked_light_pen = dummy.run_armor_check(attack_flag = "stab", armor_penetration = PEN_LIGHT, damage = 30)
	var/blocked_bsteel_pen = dummy.run_armor_check(attack_flag = "stab", armor_penetration = PEN_BSTEEL, damage = 30)
	TEST_ASSERT(blocked_bsteel_pen < blocked_light_pen, "Heavy pen overmatch vs light armor should pass more damage through than equal-tier pen (got blocked [blocked_bsteel_pen] vs [blocked_light_pen])")

/datum/unit_test/armor_blunt_integrity_multiplier/Run()
	// Steel plate chest has ARMOR_PLATE which gives blunt = DR_LIGHT = tier 1.
	// Without the 1.6x multiplier: intdamage = 20 / (1 + 0.2*1) = 16.67
	// With    the 1.6x multiplier: intdamage = 20 * 1.6 / 1.2 = 26.67
	// Threshold > 20 discriminates the two cases reliably.
	var/mob/living/carbon/human/dummy = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/armor/plate/chestpiece = allocate(/obj/item/clothing/armor/plate)
	TEST_ASSERT(dummy.equip_to_slot_if_possible(chestpiece, ITEM_SLOT_ARMOR, disable_warning = TRUE), "Test setup: failed to equip plate chestpiece")
	var/integrity_before = chestpiece.get_integrity()
	dummy.checkarmor(BODY_ZONE_CHEST, "blunt", 20, 0)
	var/blunt_integrity_loss = integrity_before - chestpiece.get_integrity()
	TEST_ASSERT(blunt_integrity_loss > 20, "Blunt should deal multiplied (1.6x) integrity damage to armor, got [blunt_integrity_loss] — expected > 20")
