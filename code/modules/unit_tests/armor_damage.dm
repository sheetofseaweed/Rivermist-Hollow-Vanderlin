/mob/living/armor_damage_test_dummy
	var/test_armor = 0

/mob/living/armor_damage_test_dummy/getarmor(def_zone, type, damage, armor_penetration, blade_dulling, intdamfactor = 1, used_weapon)
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
