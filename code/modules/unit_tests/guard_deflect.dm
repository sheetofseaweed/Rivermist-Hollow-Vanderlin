/datum/unit_test/guard_deflects_marked_projectile/Run()
	var/mob/living/carbon/human/dummy = allocate(/mob/living/carbon/human)
	// Give a weapon so tick() does not call bad_guard() before our assertions
	dummy.put_in_active_hand(allocate(/obj/item/weapon/sword/sabre))
	dummy.apply_status_effect(/datum/status_effect/buff/clash, 1 MINUTES)
	var/obj/projectile/bolt = allocate(/obj/projectile/magic)
	bolt.guard_deflectable = TRUE
	TEST_ASSERT(dummy.guard_deflect_projectile(bolt), "Guard must deflect a deflectable projectile")
	TEST_ASSERT(!dummy.has_status_effect(/datum/status_effect/buff/clash), "Deflection consumes the guard")
	TEST_ASSERT(dummy.has_status_effect(/datum/status_effect/buff/parry_buffer), "Deflection grants a volley buffer")
	TEST_ASSERT(!dummy.has_status_effect(/datum/status_effect/debuff/clashcd), "Clean deflection must not trigger the clash cooldown")

/datum/unit_test/guard_ignores_unmarked_projectile/Run()
	var/mob/living/carbon/human/dummy = allocate(/mob/living/carbon/human)
	dummy.put_in_active_hand(allocate(/obj/item/weapon/sword/sabre))
	dummy.apply_status_effect(/datum/status_effect/buff/clash, 1 MINUTES)
	var/obj/projectile/bolt = allocate(/obj/projectile/magic)
	bolt.guard_deflectable = FALSE
	TEST_ASSERT(!dummy.guard_deflect_projectile(bolt), "Unmarked projectiles must not be deflected")
	TEST_ASSERT(dummy.has_status_effect(/datum/status_effect/buff/clash), "Guard must survive an unmarked projectile check")

/datum/unit_test/parry_buffer_deflects_volley/Run()
	var/mob/living/carbon/human/dummy = allocate(/mob/living/carbon/human)
	dummy.apply_status_effect(/datum/status_effect/buff/parry_buffer)
	var/obj/projectile/bolt = allocate(/obj/projectile/magic)
	bolt.guard_deflectable = TRUE
	TEST_ASSERT(dummy.guard_deflect_projectile(bolt), "Parry buffer must deflect follow-up volley projectiles")
