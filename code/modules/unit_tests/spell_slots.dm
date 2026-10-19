/// Exercises the real Activate and payment path without launching effects into the test map.
/datum/action/cooldown/spell/slot_test_probe
	name = "Spell"
	slot_level = 1
	minor_cost = 2
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
	var/concentration_broken_reason

/datum/action/cooldown/spell/slot_test_probe/before_cast(atom/cast_on)
	. = ..()
	if(cancel_next_cast)
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/slot_test_probe/cast(atom/cast_on)
	. = ..()
	last_cast_level = get_cast_level()
	last_xp_cost = invoke_cost()
	cast_count++

/datum/action/cooldown/spell/slot_test_probe/on_concentration_broken(reason)
	concentration_broken_reason = reason

/datum/action/cooldown/spell/slot_test_probe/focus
	concentration = TRUE

/datum/unit_test/spell_slots
#ifdef FOCUS_SPELL_SLOTS
	focus = TRUE
#endif

/datum/unit_test/spell_slots/Run()
	var/mob/living/carbon/human/caster = allocate(/mob/living/carbon/human)
	caster.mind_initialize()
	caster.mana_pool.set_max_mana(100, TRUE)
	caster.mana_pool.attunements = list()
	caster.mana_pool.adjust_mana(100)
	var/datum/action/cooldown/spell/slot_test_probe/probe = allocate(/datum/action/cooldown/spell/slot_test_probe)
	probe.Grant(caster)
	TEST_ASSERT(!probe.uses_spell_slots(), "A caster without slot state used slots.")
	var/datum/spell_slots/slots = caster.mind.setup_spell_slots(CASTER_FULL)
	slots.set_fixed_slots(list(1, 1, 0, 0, 0))
	TEST_ASSERT(probe.uses_spell_slots(), "Slot state did not switch the spell to slot casting.")

	TEST_ASSERT(slots.select_level(SPELL_SLOT_MINOR), "Minor must be selectable while slots remain.")
	TEST_ASSERT(probe.Activate(caster), "Minor cast failed with sufficient mana.")
	TEST_ASSERT_EQUAL(probe.last_cast_level, SPELL_SLOT_MINOR, "Zero was mistaken for an unset tier.")
	TEST_ASSERT_EQUAL(caster.mana_pool.amount, 98, "Minor must spend mana exactly once.")
	TEST_ASSERT_EQUAL(slots.get_current(1), 1, "Minor consumed a slot.")
	TEST_ASSERT_EQUAL(probe.last_xp_cost, 0, "Minor casts must not grant repeatable casting XP.")
	TEST_ASSERT_NULL(probe.cast_slot_level, "Cast tier was not cleared after casting.")
	TEST_ASSERT(!probe.cast_paid, "Payment state survived the cast.")

	slots.select_level(1)
	TEST_ASSERT(probe.Activate(caster), "Paid cast failed.")
	TEST_ASSERT_EQUAL(slots.get_current(1), 0, "Paid cast did not consume exactly one slot.")
	TEST_ASSERT_EQUAL(caster.mana_pool.amount, 98, "Paid cast also consumed mana.")
	TEST_ASSERT(probe.last_xp_cost > 0, "Paid cast lost its casting XP.")
	TEST_ASSERT(!probe.Activate(caster), "An empty selected tier silently fell back or upcast.")
	TEST_ASSERT_EQUAL(slots.get_current(2), 1, "Empty tier consumed a higher slot.")

	slots.select_level(2)
	probe.cancel_next_cast = TRUE
	TEST_ASSERT(!probe.Activate(caster), "before_cast cancellation was ignored.")
	TEST_ASSERT_EQUAL(slots.get_current(2), 1, "Cancelled cast spent a slot.")
	TEST_ASSERT_NULL(probe.cast_slot_level, "Cancelled cast retained its tier.")
	probe.cancel_next_cast = FALSE

	probe.on_start_charge()
	slots.select_level(SPELL_SLOT_MINOR)
	TEST_ASSERT_EQUAL(probe.get_cast_level(), 2, "Selection changed a charging spell's tier.")
	probe.on_end_charge(TRUE)
	TEST_ASSERT(probe.Activate(caster), "Locked paid cast failed after changing the selector.")
	TEST_ASSERT_EQUAL(probe.last_cast_level, 2, "Released cast used the new selector instead of the locked tier.")
	TEST_ASSERT_EQUAL(caster.mana_pool.amount, 98, "Locked paid cast switched to mana payment.")

	probe.on_start_charge()
	probe.on_end_charge(FALSE)
	TEST_ASSERT_NULL(probe.cast_slot_level, "Interrupted charge retained its tier.")
	caster.mana_pool.adjust_mana(-100)
	TEST_ASSERT(!probe.Activate(caster), "Minor cast succeeded without mana.")
	TEST_ASSERT_EQUAL(probe.cast_count, 3, "Rejected casts released effects.")
	caster.mana_pool.adjust_mana(2)
	TEST_ASSERT(probe.Activate(caster), "Minor cast rejected exactly enough mana.")
	TEST_ASSERT_EQUAL(caster.mana_pool.amount, 0, "Exact-cost minor cast did not consume its mana.")

	var/datum/action/cooldown/spell/healing/healing = allocate(/datum/action/cooldown/spell/healing)
	healing.Grant(caster)
	var/datum/action/cooldown/spell/conjure/familiar/familiar = allocate(/datum/action/cooldown/spell/conjure/familiar)
	familiar.Grant(caster)
	caster.mana_pool.adjust_mana(100)
	TEST_ASSERT(!healing.check_cost(feedback = FALSE), "Healing accepted minor casting.")
	TEST_ASSERT(!familiar.check_cost(feedback = FALSE), "Familiar accepted mana in place of a slot.")
	slots.set_fixed_slots(list(1, 1, 0, 0, 0))
	slots.select_level(1)
	TEST_ASSERT(!familiar.check_cost(feedback = FALSE), "Familiar accepted a tier below its minimum.")
	slots.select_level(2)
	TEST_ASSERT(familiar.check_cost(feedback = FALSE), "Familiar rejected a valid slot.")

	var/datum/action/cooldown/spell/projectile/fireball/fireball = allocate(/datum/action/cooldown/spell/projectile/fireball)
	fireball.Grant(caster)
	var/datum/action/cooldown/spell/projectile/frost_bolt/frost = allocate(/datum/action/cooldown/spell/projectile/frost_bolt)
	frost.Grant(caster)
	slots.select_level(SPELL_SLOT_MINOR)
	var/obj/projectile/ember = allocate(fireball.minor_projectile_type)
	var/obj/projectile/ice = allocate(frost.minor_projectile_type)
	TEST_ASSERT(!istype(ember, /obj/projectile/magic/aoe/fireball), "Minor fire inherited full-strength fireball impact behavior.")
	TEST_ASSERT(!istype(ice, /obj/projectile/magic/frostbolt), "Minor frost inherited frostbite.")
	var/turf/target = get_step(caster, NORTH)
	fireball.attuned_strength = 2.5
	frost.attuned_strength = 2.5
	caster.set_skillrank(/datum/attribute/skill/magic/arcane, SKILL_RANK_NONE)
	slots.sync_to_rank(TRUE)
	fireball.ready_projectile(ember, target, caster, 1)
	frost.ready_projectile(ice, target, caster, 1)
	TEST_ASSERT_EQUAL(ember.damage, 10, "Minor fire scaled with attunement instead of rank.")
	TEST_ASSERT_EQUAL(ice.damage, 10, "Minor frost scaled with attunement instead of rank.")
	caster.set_skillrank(/datum/attribute/skill/magic/arcane, SKILL_RANK_MASTER)
	slots.sync_to_rank(TRUE)
	var/obj/projectile/master_ember = allocate(fireball.minor_projectile_type)
	fireball.ready_projectile(master_ember, target, caster, 1)
	TEST_ASSERT_EQUAL(master_ember.damage, 20, "Master rank did not double the minor cast.")

	slots.set_fixed_slots(null)
	TEST_ASSERT_EQUAL(slots.get_max(1), 4, "Master ladder row did not apply to level one.")
	TEST_ASSERT_EQUAL(slots.get_max(5), 1, "Master ladder row did not apply to level five.")
	caster.set_skillrank(/datum/attribute/skill/magic/arcane, SKILL_RANK_JOURNEYMAN)
	slots.sync_to_rank(TRUE)
	TEST_ASSERT_EQUAL(slots.get_max(3), 2, "Journeyman ladder row did not apply to level three.")
	TEST_ASSERT_EQUAL(slots.get_max(4), 0, "Journeyman ladder row kept a level four slot.")
	slots.select_level(3)
	var/obj/projectile/magic/aoe/fireball/rogue/full = allocate(/obj/projectile/magic/aoe/fireball/rogue)
	fireball.ready_projectile(full, target, caster, 1)
	TEST_ASSERT(abs(full.damage - 63) < 0.01, "Level three fireball did not use its profile and rank multiplier (got [full.damage]).")

	slots.archetype = CASTER_PACT
	slots.sync_to_rank(TRUE)
	TEST_ASSERT_EQUAL(slots.get_max(2), 2, "Journeyman pact casters should have two level two slots.")
	TEST_ASSERT_EQUAL(slots.get_max(1), 0, "Pact casters gained slots outside their pact level.")
	slots.slots_current["2"] = 0
	var/list/pact_recovery = slots.get_recovery(1)
	TEST_ASSERT_EQUAL(pact_recovery["2"], 2, "A pact short rest did not refill every pact slot.")
	slots.archetype = CASTER_FULL
	slots.sync_to_rank(TRUE)

	var/mob/living/carbon/human/mundane = allocate(/mob/living/carbon/human)
	mundane.mana_pool.set_max_mana(100, TRUE)
	mundane.mana_pool.attunements = list()
	mundane.mana_pool.adjust_mana(100)
	var/datum/action/cooldown/spell/projectile/frost_bolt/ordinary = allocate(/datum/action/cooldown/spell/projectile/frost_bolt)
	ordinary.Grant(mundane)
	var/mana_before = mundane.mana_pool.amount
	ordinary.invoke_cost()
	TEST_ASSERT(mundane.mana_pool.amount < mana_before, "Legacy casters stopped spending mana on slot spells.")

	slots.restore_all_slots()
	slots.select_level(1)
	var/datum/action/cooldown/spell/slot_test_probe/focus/first = allocate(/datum/action/cooldown/spell/slot_test_probe/focus)
	first.Grant(caster)
	TEST_ASSERT(first.Activate(caster), "Concentration probe failed to cast.")
	TEST_ASSERT_EQUAL(slots.get_concentration(), first, "Casting did not start concentration.")
	var/datum/action/cooldown/spell/slot_test_probe/focus/second = allocate(/datum/action/cooldown/spell/slot_test_probe/focus)
	second.Grant(caster)
	TEST_ASSERT(second.Activate(caster), "Second concentration probe failed to cast.")
	TEST_ASSERT_EQUAL(first.concentration_broken_reason, CONCENTRATION_REPLACED, "A second concentration effect did not end the first.")
	TEST_ASSERT_EQUAL(slots.get_concentration(), second, "The second effect did not take over concentration.")
	SEND_SIGNAL(caster, COMSIG_MOB_DEATH)
	TEST_ASSERT_EQUAL(second.concentration_broken_reason, CONCENTRATION_DEATH, "Death did not break concentration.")
	TEST_ASSERT_NULL(slots.get_concentration(), "Concentration survived death.")

	slots.add_feature(FEATURE_ARCANE_RECOVERY, 1, REST_LONG)
	TEST_ASSERT(slots.use_feature(FEATURE_ARCANE_RECOVERY), "Feature charge could not be used.")
	TEST_ASSERT(!slots.use_feature(FEATURE_ARCANE_RECOVERY), "Feature charge was used twice.")
	slots.refill_features(REST_SHORT)
	TEST_ASSERT_EQUAL(slots.get_feature_charges(FEATURE_ARCANE_RECOVERY), 0, "A short rest refilled a long-rest feature.")
	slots.refill_features(REST_LONG)
	TEST_ASSERT_EQUAL(slots.get_feature_charges(FEATURE_ARCANE_RECOVERY), 1, "A long rest did not refill the feature.")

	slots.slots_current["1"] = 0
	slots.next_long_rest = world.time + 1 MINUTES
	TEST_ASSERT(!slots.use_rest(TRUE, TRUE), "A long rest ignored the daily gate.")
	TEST_ASSERT_EQUAL(slots.get_current(1), 0, "The gated long rest restored slots.")
	TEST_ASSERT_EQUAL(slots.grant_free_short_rest(), 4, "The potion recovery did not restore four level one slots.")
	TEST_ASSERT_EQUAL(slots.get_short_rest_current(), slots.get_short_rest_max(), "The potion recovery spent a short rest charge.")

/// Allocation, interruption and progression checks; explicit focus also exercises both full timers.
/datum/unit_test/spell_rests
#ifdef FOCUS_SPELL_SLOTS
	focus = TRUE
#endif

/datum/unit_test/spell_rests/Run()
	var/mob/living/carbon/human/dummy/caster = allocate(/mob/living/carbon/human/dummy)
	// Godmode prevents the ordinary wake-up stat update. Keep the dummy's inert Life, but use real sleep/wake behavior.
	caster.status_flags &= ~GODMODE
	caster.mind_initialize()
	var/datum/spell_slots/slots = caster.mind.setup_spell_slots(CASTER_FULL)
	slots.set_fixed_slots(list(4, 3, 3, 2, 1))
	caster.set_resting(TRUE, TRUE)
	TEST_ASSERT(!slots.use_rest(), "Full slots consumed a short rest.")
	TEST_ASSERT_EQUAL(slots.get_short_rest_current(), 2, "An empty recovery spent a charge.")
	slots.short_rest_current = 0
	slots.unlock_extra_short_rest()
	TEST_ASSERT_EQUAL(slots.get_short_rest_max(), 3, "The extra rest unlock did not raise the maximum.")
	TEST_ASSERT_EQUAL(slots.get_short_rest_current(), 1, "The extra rest unlock refilled spent charges instead of adding one.")
	slots.unlock_extra_short_rest()
	TEST_ASSERT_EQUAL(slots.get_short_rest_current(), 1, "The extra-rest unlock was not idempotent.")
	for(var/level in SPELL_SLOT_MIN to SPELL_SLOT_MAX)
		slots.slots_current[num2text(level)] = 0
	var/list/recovery = slots.get_recovery(5)
	TEST_ASSERT_EQUAL(recovery["5"], 1, "Selected fifth tier was not prioritized.")
	TEST_ASSERT_EQUAL(recovery["1"], 3, "Remaining budget did not recover three first-tier slots.")
	TEST_ASSERT_EQUAL(length(recovery), 2, "The recovery exceeded its budget.")
	recovery = slots.get_recovery(SPELL_SLOT_MINOR)
	TEST_ASSERT_EQUAL(recovery["1"], 4, "Minor selection did not prioritize the cheapest tier.")
	TEST_ASSERT_EQUAL(recovery["2"], 2, "Cheap-slot recovery did not spend the remaining four points.")
	slots.slots_current["1"] = 3
	slots.slots_current["5"] = 1
	recovery = slots.get_recovery(1)
	TEST_ASSERT_EQUAL(recovery["1"], 1, "Recovery exceeded a tier's capacity.")
	TEST_ASSERT_EQUAL(recovery["2"], 3, "Recovery skipped affordable missing slots.")
	TEST_ASSERT_NULL(recovery["3"], "An unusable remainder paid for an expensive slot.")

	var/list/interruptions = list(COMSIG_MOVABLE_MOVED, COMSIG_MOB_ITEM_ATTACK, COMSIG_MOB_BEFORE_SPELL_CAST, COMSIG_MOB_APPLY_DAMAGE)
	for(var/signal in interruptions)
		INVOKE_ASYNC(slots, TYPE_PROC_REF(/datum/spell_slots, use_rest))
		sleep(1 SECONDS)
		TEST_ASSERT(slots.rest_in_progress, "Short rest failed to start.")
		TEST_ASSERT(!slots.use_rest(), "Concurrent rests were allowed.")
		SEND_SIGNAL(caster, signal, 1)
		sleep(1 SECONDS)
		TEST_ASSERT(!slots.rest_in_progress, "Movement, attack, cast or damage failed to interrupt rest.")
		TEST_ASSERT_EQUAL(slots.get_short_rest_current(), 1, "An interrupted rest spent a charge.")
		TEST_ASSERT_EQUAL(slots.get_current(1), 3, "An interrupted rest recovered slots.")

	INVOKE_ASYNC(slots, TYPE_PROC_REF(/datum/spell_slots, use_rest), TRUE)
	sleep(1 SECONDS)
	TEST_ASSERT(caster.IsSleeping(), "Deliberate long rest did not put the caster to sleep.")
	TEST_ASSERT(slots.rest_in_progress, "Long rest failed to start.")
	TEST_ASSERT_EQUAL(slots.get_current(2), 0, "Starting sleep instantly restored slots.")
	caster.SetSleeping(0)
	sleep(1 SECONDS)
	TEST_ASSERT(!slots.rest_in_progress, "Waking failed to interrupt long rest.")
	TEST_ASSERT_EQUAL(slots.get_current(2), 0, "Interrupted sleep restored slots.")

#ifdef FOCUS_SPELL_SLOTS
	// Keep the six-minute wall-clock integration check out of ordinary test runs.
	caster.set_resting(TRUE, TRUE)
	slots.selected_level = 5
	slots.slots_current["1"] = 0
	slots.slots_current["5"] = 0
	slots.short_rest_current = 3
	var/started_at = world.time
	TEST_ASSERT(slots.use_rest(), "Uninterrupted short rest failed.")
	TEST_ASSERT(world.time - started_at >= SHORT_REST_DURATION, "Short rest completed early.")
	TEST_ASSERT_EQUAL(slots.get_short_rest_current(), 2, "Completed short rest did not spend exactly one charge.")
	TEST_ASSERT_EQUAL(slots.get_current(5), 1, "Completed short rest lost its priority tier.")
	TEST_ASSERT_EQUAL(slots.get_current(1), 3, "Completed short rest recovered the wrong amount.")
	slots.short_rest_current = 0
	started_at = world.time
	TEST_ASSERT(slots.use_rest(TRUE), "Uninterrupted long rest failed.")
	TEST_ASSERT(world.time - started_at >= LONG_REST_DURATION, "Long rest completed early.")
	TEST_ASSERT_EQUAL(slots.get_short_rest_current(), 3, "Long rest did not restore all three charges.")
	for(var/level in SPELL_SLOT_MIN to SPELL_SLOT_MAX)
		TEST_ASSERT_EQUAL(slots.get_current(level), slots.get_max(level), "Long rest did not fully restore level [level].")
	TEST_ASSERT(slots.long_rest_ready_in() > 0, "A completed long rest did not start the daily gate.")
	TEST_ASSERT(!slots.use_rest(TRUE), "A second long rest ignored the daily gate.")
#endif

/// Grimoire binding, learning, preparing, recall and mind transfer.
/datum/unit_test/spell_mastery
#ifdef FOCUS_SPELL_SLOTS
	focus = TRUE
#endif

/datum/unit_test/spell_mastery/Run()
	var/mob/living/carbon/human/caster = allocate(/mob/living/carbon/human)
	caster.mind_initialize()
	caster.set_skillrank(/datum/attribute/skill/magic/arcane, SKILL_RANK_JOURNEYMAN)
	var/datum/spell_mastery/mastery = caster.mind.get_spell_mastery()
	mastery.uses_preparation = TRUE
	TEST_ASSERT_EQUAL(mastery.get_max_prepared(), 10, "A journeyman should prepare ten spells.")

	var/obj/item/spellbook/apprentice/starter/fire/book = allocate(/obj/item/spellbook/apprentice/starter/fire, get_turf(caster))
	TEST_ASSERT_EQUAL(book.base_form_points, 4, "Apprentice quality should scale seven form points to four.")
	TEST_ASSERT_EQUAL(book.base_technique_points, 2, "Apprentice quality should scale three technique points to two.")
	book.bind_owner(caster.mind)
	TEST_ASSERT_EQUAL(mastery.get_form_level(FORM_FIRE), 2, "Half the form points should land in the themed form.")
	TEST_ASSERT_EQUAL(mastery.unspent_form_points, 2, "The other half of the form points should stay unspent.")
	TEST_ASSERT_EQUAL(mastery.unspent_technique_points, 2, "Technique points were not granted.")
	book.bind_owner(caster.mind)
	TEST_ASSERT_EQUAL(mastery.unspent_form_points, 2, "Rebinding claimed the points again.")

	var/fireball_path = /datum/action/cooldown/spell/projectile/fireball
	TEST_ASSERT(!mastery.can_learn_spell(fireball_path), "Fireball was learnable without a destruction investment.")
	TEST_ASSERT(mastery.invest_technique(TECHNIQUE_DESTRUCTION), "Could not invest a technique point.")
	TEST_ASSERT(mastery.can_learn_spell(fireball_path), "Fireball was not learnable with fire two and destruction one.")
	TEST_ASSERT(!mastery.can_learn_spell(/datum/action/cooldown/spell/projectile/fireball/greater), "Greater fireball was learnable before its prerequisite and rank.")
	TEST_ASSERT(mastery.try_learn_spell(fireball_path), "Learning fireball failed.")
	TEST_ASSERT(mastery.is_prepared(fireball_path), "A freshly learned spell with room was not prepared.")
	TEST_ASSERT_NOTNULL(caster.get_spell(fireball_path), "The prepared spell was not granted to the body.")

	TEST_ASSERT(!mastery.set_prepared(fireball_path, FALSE), "The prepared set changed without the grimoire at hand.")
	caster.put_in_hands(book)
	TEST_ASSERT(mastery.is_book_at_hand(), "A grimoire in hand was not detected.")
	caster.cmode = TRUE
	TEST_ASSERT(!mastery.set_prepared(fireball_path, FALSE), "The prepared set changed in combat mode.")
	caster.cmode = FALSE
	TEST_ASSERT(mastery.set_prepared(fireball_path, FALSE), "Could not unprepare fireball.")
	TEST_ASSERT_NULL(caster.get_spell(fireball_path), "An unprepared spell stayed granted.")
	TEST_ASSERT(mastery.set_prepared(fireball_path, TRUE), "Could not prepare fireball again.")
	TEST_ASSERT_NOTNULL(caster.get_spell(fireball_path), "A re-prepared spell was not granted.")

	var/light_path = /datum/action/cooldown/spell/undirected/conjure_item/light
	TEST_ASSERT(mastery.invest_form(FORM_ARCANE), "Could not invest a form point.")
	TEST_ASSERT(mastery.invest_technique(TECHNIQUE_CREATION), "Could not invest the second technique point.")
	TEST_ASSERT(mastery.try_learn_spell(light_path), "Learning the light cantrip failed.")
	TEST_ASSERT(!mastery.needs_preparation(light_path), "A cantrip demanded preparation.")
	TEST_ASSERT_NOTNULL(caster.get_spell(light_path), "The cantrip was not granted.")
	TEST_ASSERT(mastery.try_unlearn_spell(light_path), "Unlearning the cantrip failed.")
	TEST_ASSERT_NULL(caster.get_spell(light_path), "An unlearned spell stayed granted.")
	TEST_ASSERT_EQUAL(mastery.spendable_form_points[FORM_ARCANE], 1, "Unlearning did not refund the form point.")

	book.forceMove(get_step(caster, NORTH))
	SEND_SIGNAL(caster.mind, COMSIG_MIND_SPELL_REST, REST_LONG)
	TEST_ASSERT_EQUAL(book.loc, caster, "A long rest did not recall the grimoire.")
	qdel(book)
	TEST_ASSERT(mastery.bound_book_lost, "Destroying the bound grimoire was not noticed.")
	SEND_SIGNAL(caster.mind, COMSIG_MIND_SPELL_REST, REST_LONG)
	var/obj/item/spellbook/replacement = mastery.bound_book_ref?.resolve()
	TEST_ASSERT_NOTNULL(replacement, "A long rest did not replace the destroyed grimoire.")
	TEST_ASSERT_EQUAL(replacement.loc, caster, "The replacement grimoire was not handed over.")
	TEST_ASSERT(!mastery.bound_book_lost, "The replacement grimoire did not clear the loss.")

	var/mob/living/carbon/human/vessel = allocate(/mob/living/carbon/human)
	caster.mind.transfer_to(vessel)
	TEST_ASSERT_NOTNULL(vessel.get_spell(fireball_path), "The prepared spell did not follow the mind.")
	TEST_ASSERT_NULL(caster.get_spell(fireball_path), "The prepared spell stayed on the old body.")
	qdel(replacement)
