// Slice 9: Weapon Bind — unit tests
// Matching aim subzones + journeyman skill + no bindcd => bind fires.
// Tests use BODY_ZONE_PRECISE_R_HAND (not BODY_ZONE_CHEST) so the prob(3) chest path never interferes.

/datum/unit_test/weapon_bind_on_matching_zones/Run()
	var/mob/living/carbon/human/defender = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	attacker.mind_initialize()
	defender.mind_initialize()
	var/obj/item/weapon/sword/sabre/def_weapon = allocate(/obj/item/weapon/sword/sabre)
	var/obj/item/weapon/sword/sabre/att_weapon = allocate(/obj/item/weapon/sword/sabre)
	defender.put_in_active_hand(def_weapon)
	attacker.put_in_active_hand(att_weapon)
	defender.zone_selected = BODY_ZONE_PRECISE_R_HAND
	attacker.zone_selected = BODY_ZONE_PRECISE_R_HAND
	// Set defender to journeyman+ in the sword skill so the skill gate passes
	defender.set_skillrank(def_weapon.associated_skill, SKILL_RANK_JOURNEYMAN)
	TEST_ASSERT(defender.try_bind(def_weapon, attacker), "Matching precise zones with sufficient skill must bind")
	TEST_ASSERT(defender.has_status_effect(/datum/status_effect/buff/weapon_binded), "Defender gets bind buff")
	TEST_ASSERT(defender.has_status_effect(/datum/status_effect/debuff/bindcd), "Bind goes on cooldown")

/datum/unit_test/weapon_bind_blocked_by_cooldown/Run()
	var/mob/living/carbon/human/defender = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	attacker.mind_initialize()
	defender.mind_initialize()
	var/obj/item/weapon/sword/sabre/def_weapon = allocate(/obj/item/weapon/sword/sabre)
	var/obj/item/weapon/sword/sabre/att_weapon = allocate(/obj/item/weapon/sword/sabre)
	defender.put_in_active_hand(def_weapon)
	attacker.put_in_active_hand(att_weapon)
	defender.zone_selected = BODY_ZONE_PRECISE_R_HAND
	attacker.zone_selected = BODY_ZONE_PRECISE_R_HAND
	defender.set_skillrank(def_weapon.associated_skill, SKILL_RANK_JOURNEYMAN)
	defender.apply_status_effect(/datum/status_effect/debuff/bindcd)
	TEST_ASSERT(!defender.try_bind(def_weapon, attacker), "Bind must respect its cooldown")

/datum/unit_test/weapon_bind_requires_zone_match/Run()
	var/mob/living/carbon/human/defender = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	attacker.mind_initialize()
	defender.mind_initialize()
	var/obj/item/weapon/sword/sabre/def_weapon = allocate(/obj/item/weapon/sword/sabre)
	var/obj/item/weapon/sword/sabre/att_weapon = allocate(/obj/item/weapon/sword/sabre)
	defender.put_in_active_hand(def_weapon)
	attacker.put_in_active_hand(att_weapon)
	defender.zone_selected = BODY_ZONE_PRECISE_R_HAND
	attacker.zone_selected = BODY_ZONE_CHEST  // mismatched zone
	defender.set_skillrank(def_weapon.associated_skill, SKILL_RANK_JOURNEYMAN)
	TEST_ASSERT(!defender.try_bind(def_weapon, attacker), "Mismatched zones must not bind")

/datum/unit_test/weapon_bind_requires_skill/Run()
	var/mob/living/carbon/human/defender = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	attacker.mind_initialize()
	defender.mind_initialize()
	var/obj/item/weapon/sword/sabre/def_weapon = allocate(/obj/item/weapon/sword/sabre)
	var/obj/item/weapon/sword/sabre/att_weapon = allocate(/obj/item/weapon/sword/sabre)
	defender.put_in_active_hand(def_weapon)
	attacker.put_in_active_hand(att_weapon)
	defender.zone_selected = BODY_ZONE_PRECISE_R_HAND
	attacker.zone_selected = BODY_ZONE_PRECISE_R_HAND
	defender.set_skillrank(def_weapon.associated_skill, SKILL_RANK_APPRENTICE)
	TEST_ASSERT(!defender.try_bind(def_weapon, attacker), "Sub-journeyman skill must not bind")
