/// Exercises the real Activate/payment path without launching effects into the test map.
/datum/action/cooldown/spell/dnd_test_probe
	name = "Spell"
	dnd_use_spell_slots = TRUE
	dnd_minor_mana_cost = 2
	charge_required = FALSE
	charge_slowdown = 0
	click_to_activate = FALSE
	has_visual_effects = FALSE
	invocation_type = INVOCATION_NONE
	sound = null
	spell_requirements = NONE
	experience_modifier = 0
	var/cancel_next_cast = FALSE
	var/last_cast_level
	var/cast_count = 0
	var/last_xp_cost

/datum/action/cooldown/spell/dnd_test_probe/before_cast(atom/cast_on)
	. = ..()
	if(cancel_next_cast)
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/dnd_test_probe/cast(atom/cast_on)
	. = ..()
	last_cast_level = dnd_get_cast_level()
	last_xp_cost = invoke_cost()
	cast_count++

/datum/unit_test/dnd_casting
#ifdef FOCUS_DND_CASTING
	focus = TRUE
#endif

/datum/unit_test/dnd_casting/Run()
	var/mob/living/carbon/human/caster = allocate(/mob/living/carbon/human)
	caster.mana_pool.set_max_mana(100, TRUE)
	caster.mana_pool.attunements = list()
	caster.mana_pool.adjust_mana(100)
	var/datum/action/cooldown/spell/dnd_test_probe/probe = allocate(/datum/action/cooldown/spell/dnd_test_probe)
	probe.Grant(caster)
	caster.setup_dnd_spell_slots(list("1" = 1, "2" = 1))

	TEST_ASSERT(caster.select_dnd_spell_slot(DND_MINOR_TIER), "Minor must be selectable while slots remain.")
	TEST_ASSERT(probe.Activate(caster), "Minor cast failed with sufficient mana.")
	TEST_ASSERT_EQUAL(probe.last_cast_level, DND_MINOR_TIER, "Zero was mistaken for an unset tier.")
	TEST_ASSERT_EQUAL(caster.mana_pool.amount, 98, "Minor must spend mana exactly once.")
	TEST_ASSERT_EQUAL(caster.get_dnd_spell_slots_current(1), 1, "Minor consumed a slot.")
	TEST_ASSERT_EQUAL(probe.last_xp_cost, 0, "Minor casts must not grant repeatable casting XP.")
	TEST_ASSERT_NULL(probe.dnd_cast_slot_level, "Cast tier was not cleared after casting.")
	TEST_ASSERT(!probe.dnd_cast_paid, "Payment state survived the cast.")

	caster.select_dnd_spell_slot(1)
	TEST_ASSERT(probe.Activate(caster), "Paid cast failed.")
	TEST_ASSERT_EQUAL(caster.get_dnd_spell_slots_current(1), 0, "Paid cast did not consume exactly one slot.")
	TEST_ASSERT_EQUAL(caster.mana_pool.amount, 98, "Paid cast also consumed mana.")
	TEST_ASSERT(probe.last_xp_cost > 0, "Paid cast lost its casting XP.")
	TEST_ASSERT(!probe.Activate(caster), "An empty selected tier silently fell back or upcast.")
	TEST_ASSERT_EQUAL(caster.get_dnd_spell_slots_current(2), 1, "Empty tier consumed a higher slot.")

	caster.select_dnd_spell_slot(2)
	probe.cancel_next_cast = TRUE
	TEST_ASSERT(!probe.Activate(caster), "before_cast cancellation was ignored.")
	TEST_ASSERT_EQUAL(caster.get_dnd_spell_slots_current(2), 1, "Cancelled cast spent a slot.")
	TEST_ASSERT_NULL(probe.dnd_cast_slot_level, "Cancelled cast retained its tier.")
	probe.cancel_next_cast = FALSE

	probe.on_start_charge()
	caster.select_dnd_spell_slot(DND_MINOR_TIER)
	TEST_ASSERT_EQUAL(probe.dnd_get_cast_level(), 2, "Selection changed a charging spell's tier.")
	probe.on_end_charge(TRUE)
	TEST_ASSERT(probe.Activate(caster), "Locked paid cast failed after changing the selector.")
	TEST_ASSERT_EQUAL(probe.last_cast_level, 2, "Released cast used the new selector instead of the locked tier.")
	TEST_ASSERT_EQUAL(caster.mana_pool.amount, 98, "Locked paid cast switched to mana payment.")

	probe.on_start_charge()
	probe.on_end_charge(FALSE)
	TEST_ASSERT_NULL(probe.dnd_cast_slot_level, "Interrupted charge retained its tier.")
	caster.mana_pool.adjust_mana(-100)
	TEST_ASSERT(!probe.Activate(caster), "Minor cast succeeded without mana.")
	TEST_ASSERT_EQUAL(probe.cast_count, 3, "Rejected casts released effects.")
	caster.mana_pool.adjust_mana(2)
	TEST_ASSERT(probe.Activate(caster), "Minor cast rejected exactly enough mana.")
	TEST_ASSERT_EQUAL(caster.mana_pool.amount, 0, "Exact-cost minor cast did not consume its mana.")

	var/datum/action/cooldown/spell/healing/dnd/healing = allocate(/datum/action/cooldown/spell/healing/dnd)
	healing.Grant(caster)
	var/datum/action/cooldown/spell/conjure/familiar/dnd/familiar = allocate(/datum/action/cooldown/spell/conjure/familiar/dnd)
	familiar.Grant(caster)
	caster.mana_pool.adjust_mana(100)
	TEST_ASSERT(!healing.check_cost(feedback = FALSE), "Healing accepted minor casting.")
	TEST_ASSERT(!familiar.check_cost(feedback = FALSE), "Familiar accepted mana in place of a slot.")
	caster.setup_dnd_spell_slots(list("1" = 1, "2" = 1))
	caster.select_dnd_spell_slot(1)
	TEST_ASSERT(!familiar.check_cost(feedback = FALSE), "Familiar accepted a tier below its minimum.")
	caster.select_dnd_spell_slot(2)
	TEST_ASSERT(familiar.check_cost(feedback = FALSE), "Familiar rejected a valid slot.")

	var/datum/action/cooldown/spell/projectile/dnd_fireball/fireball = allocate(/datum/action/cooldown/spell/projectile/dnd_fireball)
	fireball.Grant(caster)
	var/datum/action/cooldown/spell/projectile/frost_bolt/dnd/frost = allocate(/datum/action/cooldown/spell/projectile/frost_bolt/dnd)
	frost.Grant(caster)
	caster.select_dnd_spell_slot(DND_MINOR_TIER)
	var/obj/projectile/ember = allocate(fireball.dnd_minor_projectile_type)
	var/obj/projectile/ice = allocate(frost.dnd_minor_projectile_type)
	TEST_ASSERT(!istype(ember, /obj/projectile/magic/aoe/fireball), "Minor fire inherited full-strength fireball impact behavior.")
	TEST_ASSERT(!istype(ice, /obj/projectile/magic/frostbolt), "Minor frost inherited frostbite.")
	var/turf/target = get_step(caster, NORTH)
	fireball.attuned_strength = 2.5
	frost.attuned_strength = 2.5
	fireball.ready_projectile(ember, target, caster, 1)
	frost.ready_projectile(ice, target, caster, 1)
	TEST_ASSERT_EQUAL(ember.damage, 15, "Minor fire exceeded its attunement cap.")
	TEST_ASSERT_EQUAL(ice.damage, 15, "Minor frost exceeded its attunement cap.")

	var/datum/action/cooldown/spell/projectile/frost_bolt/ordinary = allocate(/datum/action/cooldown/spell/projectile/frost_bolt)
	ordinary.Grant(caster)
	var/mana_before = caster.mana_pool.amount
	ordinary.invoke_cost()
	TEST_ASSERT(caster.mana_pool.amount < mana_before, "Ordinary mana spells stopped spending mana.")
	TEST_ASSERT_EQUAL(caster.get_dnd_spell_slots_current(2), 1, "Ordinary mana spell spent a slot.")

/// Allocation, interruption and progression checks; explicit focus also exercises both full timers.
/datum/unit_test/dnd_recovery
#ifdef FOCUS_DND_CASTING
	focus = TRUE
#endif

/datum/unit_test/dnd_recovery/Run()
	var/mob/living/carbon/human/dummy/caster = allocate(/mob/living/carbon/human/dummy)
	// Godmode prevents the ordinary wake-up stat update. Keep the dummy's inert Life, but use real sleep/wake behavior.
	caster.status_flags &= ~GODMODE
	caster.setup_default_dnd_spell_slots()
	caster.set_resting(TRUE, TRUE)
	TEST_ASSERT(!caster.use_dnd_rest(), "Full slots consumed a short rest.")
	TEST_ASSERT_EQUAL(caster.get_dnd_short_rest_current(), 2, "An empty recovery spent a charge.")
	caster.dnd_short_rest_current = 0
	caster.unlock_dnd_extra_short_rest()
	TEST_ASSERT_EQUAL(caster.get_dnd_short_rest_max(), 3, "Wellspring did not raise the maximum.")
	TEST_ASSERT_EQUAL(caster.get_dnd_short_rest_current(), 1, "Wellspring refilled spent charges instead of adding one.")
	caster.unlock_dnd_extra_short_rest()
	TEST_ASSERT_EQUAL(caster.get_dnd_short_rest_current(), 1, "The extra-rest unlock was not idempotent.")
	caster.setup_default_dnd_spell_slots()
	TEST_ASSERT_EQUAL(caster.get_dnd_short_rest_current(), 3, "Slot setup lost the earlier Wellspring unlock.")
	for(var/key in caster.dnd_spell_slots_current)
		caster.dnd_spell_slots_current[key] = 0
	var/list/recovery = caster.get_dnd_short_rest_recovery(5)
	TEST_ASSERT_EQUAL(recovery["5"], 1, "Selected fifth tier was not prioritized.")
	TEST_ASSERT_EQUAL(recovery["1"], 3, "Remaining budget did not recover three first-tier slots.")
	TEST_ASSERT_EQUAL(length(recovery), 2, "The recovery exceeded its budget.")
	recovery = caster.get_dnd_short_rest_recovery(DND_MINOR_TIER)
	TEST_ASSERT_EQUAL(recovery["1"], 4, "Minor selection did not prioritize the cheapest tier.")
	TEST_ASSERT_EQUAL(recovery["2"], 2, "Cheap-slot recovery did not spend the remaining four points.")
	caster.dnd_spell_slots_current["1"] = 3
	caster.dnd_spell_slots_current["5"] = 1
	recovery = caster.get_dnd_short_rest_recovery(1)
	TEST_ASSERT_EQUAL(recovery["1"], 1, "Recovery exceeded a tier's capacity.")
	TEST_ASSERT_EQUAL(recovery["2"], 3, "Recovery skipped affordable missing slots.")
	TEST_ASSERT_NULL(recovery["3"], "An unusable remainder paid for an expensive slot.")

	var/list/interruptions = list(COMSIG_MOVABLE_MOVED, COMSIG_MOB_ITEM_ATTACK, COMSIG_MOB_BEFORE_SPELL_CAST, COMSIG_MOB_APPLY_DAMAGE)
	for(var/signal in interruptions)
		INVOKE_ASYNC(caster, TYPE_PROC_REF(/mob/living/carbon/human, use_dnd_rest))
		sleep(1 SECONDS)
		TEST_ASSERT(caster.dnd_rest_in_progress, "Short rest failed to start.")
		TEST_ASSERT(!caster.use_dnd_rest(), "Concurrent rests were allowed.")
		SEND_SIGNAL(caster, signal, 1)
		sleep(1 SECONDS)
		TEST_ASSERT(!caster.dnd_rest_in_progress, "Movement, attack, cast or damage failed to interrupt rest.")
		TEST_ASSERT_EQUAL(caster.get_dnd_short_rest_current(), 3, "An interrupted rest spent a charge.")
		TEST_ASSERT_EQUAL(caster.get_dnd_spell_slots_current(1), 3, "An interrupted rest recovered slots.")

	INVOKE_ASYNC(caster, TYPE_PROC_REF(/mob/living/carbon/human, use_dnd_rest), TRUE)
	sleep(1 SECONDS)
	TEST_ASSERT(caster.IsSleeping(), "Deliberate long rest did not put the caster to sleep.")
	TEST_ASSERT(caster.dnd_rest_in_progress, "Long rest failed to start.")
	TEST_ASSERT_EQUAL(caster.get_dnd_spell_slots_current(2), 0, "Starting sleep instantly restored slots.")
	caster.SetSleeping(0)
	sleep(1 SECONDS)
	TEST_ASSERT(!caster.dnd_rest_in_progress, "Waking failed to interrupt long rest.")
	TEST_ASSERT_EQUAL(caster.get_dnd_spell_slots_current(2), 0, "Interrupted sleep restored slots.")

#ifdef FOCUS_DND_CASTING
	// Keep the six-minute wall-clock integration check out of ordinary test runs.
	caster.set_resting(TRUE, TRUE)
	caster.selected_dnd_spell_slot_level = 5
	caster.dnd_spell_slots_current["1"] = 0
	caster.dnd_spell_slots_current["5"] = 0
	var/started_at = world.time
	TEST_ASSERT(caster.use_dnd_rest(), "Uninterrupted short rest failed.")
	TEST_ASSERT(world.time - started_at >= DND_SHORT_REST_DURATION, "Short rest completed early.")
	TEST_ASSERT_EQUAL(caster.get_dnd_short_rest_current(), 2, "Completed short rest did not spend exactly one charge.")
	TEST_ASSERT_EQUAL(caster.get_dnd_spell_slots_current(5), 1, "Completed short rest lost its priority tier.")
	TEST_ASSERT_EQUAL(caster.get_dnd_spell_slots_current(1), 3, "Completed short rest recovered the wrong amount.")
	caster.dnd_short_rest_current = 0
	started_at = world.time
	TEST_ASSERT(caster.use_dnd_rest(TRUE), "Uninterrupted long rest failed.")
	TEST_ASSERT(world.time - started_at >= DND_LONG_REST_DURATION, "Long rest completed early.")
	TEST_ASSERT_EQUAL(caster.get_dnd_short_rest_current(), 3, "Long rest did not restore all three charges.")
	for(var/key in caster.dnd_spell_slots_max)
		TEST_ASSERT_EQUAL(caster.dnd_spell_slots_current[key], caster.dnd_spell_slots_max[key], "Long rest did not fully restore a tier.")
#endif
