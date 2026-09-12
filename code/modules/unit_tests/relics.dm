/datum/relic_effect/unit_test_lifecycle
	signal = TRUE
	var/setup_calls = 0
	var/removal_calls = 0
	var/harvest_signals_received = 0

/datum/relic_effect/unit_test_lifecycle/setup_signals()
	setup_calls++
	RegisterSignal(SSdcs, COMSIG_GLOB_PLANT_HARVESTED, PROC_REF(on_global_harvest))

/datum/relic_effect/unit_test_lifecycle/remove_signals()
	removal_calls++
	UnregisterSignal(SSdcs, COMSIG_GLOB_PLANT_HARVESTED)

/datum/relic_effect/unit_test_lifecycle/proc/on_global_harvest()
	SIGNAL_HANDLER
	harvest_signals_received++

/datum/relic_information/unit_test_lifecycle
	var/effect_calls = 0

/datum/relic_information/unit_test_lifecycle/play_relic_effects(atom/parent)
	effect_calls++

/datum/unit_test/relic_secure_spot_lifecycle

#ifdef FOCUS_RELIC_SYSTEM_TESTS
/datum/unit_test/relic_secure_spot_lifecycle
	focus = TRUE
#endif

/datum/unit_test/relic_secure_spot_lifecycle/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/relic = allocate(/obj/item)
	var/obj/structure/secure_spot/holder = allocate(/obj/structure/secure_spot)
	var/datum/component/relic/component = relic.AddComponent(/datum/component/relic, new /datum/relic_trigger/secure, new /datum/relic_effect/unit_test_lifecycle, new /datum/relic_information)
	TEST_ASSERT_NOTNULL(component, "The relic component should attach to an item.")
	var/datum/relic_effect/unit_test_lifecycle/effect = component.effect

	SEND_SIGNAL(relic, COMSIG_SECURE_SPOT_ACTIVATED, "wrong secure id")
	TEST_ASSERT(!component.signal_effect_active, "A secure trigger must ignore a holder with the wrong ID.")

	user.put_in_hands(relic)
	TEST_ASSERT(holder.attackby(relic, user, list()), "The secure spot should accept a held item.")
	TEST_ASSERT_EQUAL(holder.stored_item, relic, "The secure spot lost its stored relic.")
	TEST_ASSERT(component.signal_effect_active, "Securing a matching relic should activate its signal effect.")
	TEST_ASSERT_EQUAL(effect.setup_calls, 1, "The relic effect should register its signals exactly once.")

	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_PLANT_HARVESTED, holder, user, get_turf(holder))
	TEST_ASSERT_EQUAL(effect.harvest_signals_received, 1, "An active relic should receive global harvest signals.")
	SEND_SIGNAL(relic, COMSIG_SECURE_SPOT_ACTIVATED, holder.secure_id)
	TEST_ASSERT_EQUAL(effect.setup_calls, 1, "Repeated activation must not duplicate signal registrations.")

	holder.empty_spot(user)
	TEST_ASSERT_NULL(holder.stored_item, "Removing a relic should clear the holder's stored item.")
	TEST_ASSERT(!component.signal_effect_active, "Removing a relic should deactivate its signal effect.")
	TEST_ASSERT_EQUAL(effect.removal_calls, 1, "Removing a relic should unregister its signals exactly once.")
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_PLANT_HARVESTED, holder, user, get_turf(holder))
	TEST_ASSERT_EQUAL(effect.harvest_signals_received, 1, "A removed relic must not continue receiving harvest signals.")

	var/obj/item/periodic_relic = allocate(/obj/item)
	var/datum/relic_information/unit_test_lifecycle/periodic_info = new
	var/datum/component/relic/periodic_component = periodic_relic.AddComponent(/datum/component/relic, new /datum/relic_trigger, new /datum/relic_effect, periodic_info)
	periodic_component.activate_relic()
	TEST_ASSERT(periodic_component in SSrelics.active_relics, "A periodic relic should register with SSrelics when activated.")
	SSrelics.fire(resumed = FALSE)
	TEST_ASSERT(!(periodic_component in SSrelics.active_relics), "SSrelics should remove a completed periodic effect.")
	TEST_ASSERT_EQUAL(periodic_info.effect_calls, 1, "A one-tick effect should execute once instead of expiring before its effect runs.")
