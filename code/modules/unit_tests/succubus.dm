// Succubus antagonist core — unit tests (Task 7)
// See docs/superpowers/plans/2026-07-17-succubus-core.md

/datum/antagonist/succubus/test_contract_upkeep
	var/test_thrall_count = 0

/datum/antagonist/succubus/test_contract_upkeep/count_thralls()
	return test_thrall_count

#ifdef FOCUS_SUCCUBUS_TEST
/datum/unit_test/succubus_novelty_decay
	focus = TRUE
/datum/unit_test/succubus_essence_cap
	focus = TRUE
/datum/unit_test/succubus_wardrobe
	focus = TRUE
/datum/unit_test/succubus_pref_gating
	focus = TRUE
/datum/unit_test/succubus_reagent_harvest
	focus = TRUE
/datum/unit_test/succubus_enthrall_gates
	focus = TRUE
/datum/unit_test/succubus_contract_pool
	focus = TRUE
/datum/unit_test/succubus_contract_harvest_feedthrough
	focus = TRUE
/datum/unit_test/succubus_contract_enthrall_feedthrough
	focus = TRUE
/datum/unit_test/succubus_contract_progression_upkeep
	focus = TRUE
/datum/unit_test/succubus_imp_ownership_lifecycle
	focus = TRUE
/datum/unit_test/succubus_imp_controller_stays_inert
	focus = TRUE
/datum/unit_test/succubus_lusthound_lifecycle
	focus = TRUE
/datum/unit_test/succubus_lusthound_command_gates
	focus = TRUE
/datum/unit_test/succubus_infernal_snare_lifecycle
	focus = TRUE
/datum/unit_test/succubus_infernal_snare_placement_gates
	focus = TRUE
/datum/unit_test/succubus_harem_team
	focus = TRUE
/datum/unit_test/succubus_true_form_gates
	focus = TRUE
/datum/unit_test/succubus_sovereign_gaze
	focus = TRUE
/datum/unit_test/succubus_rift_objective_and_unlock
	focus = TRUE
/datum/unit_test/succubus_rift_stage_lifecycle
	focus = TRUE
/datum/unit_test/succubus_rift_exclusivity_and_collapse
	focus = TRUE
/datum/unit_test/succubus_rift_incursion_lifecycle
	focus = TRUE
/datum/unit_test/succubus_rift_sealing_and_failure
	focus = TRUE
/datum/unit_test/succubus_rift_ascension_and_retinue_cleanup
	focus = TRUE
#endif

/datum/targetting_datum/basic/succubus_lusthound_unit_test/can_use_horny_ai_target(mob/living/living_mob, mob/living/carbon/human/human_target)
	return TRUE

/datum/unit_test/succubus_novelty_decay/Run()
	var/datum/antagonist/succubus/antag = allocate(/datum/antagonist/succubus)
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human)
	partner.mind_initialize() // gives a mind without a client — mirrors weapon_bind.dm's unit test pattern
	antag.essence_cap = 100000

	antag.harvest_from_climax(partner)
	// harvest_from_climax has a same-tick dedupe (succubus.dm's last_harvest_mind/last_harvest_time
	// stamp) so a multi-organ partner's single climax doesn't double-harvest within one world.time
	// tick. This whole Run() executes in a single tick, so the stamp must be reset between calls to
	// exercise the novelty-decay math instead of tripping the dedupe on every repeat call below.
	antag.last_harvest_time = -1
	var/first = antag.essence
	TEST_ASSERT_EQUAL(first, SUCCUBUS_ESSENCE_BASE_HARVEST, "an unaroused first harvest must pay the base amount")
	antag.harvest_from_climax(partner)
	antag.last_harvest_time = -1
	var/second = antag.essence - first
	TEST_ASSERT_EQUAL(second, round(SUCCUBUS_ESSENCE_BASE_HARVEST * SUCCUBUS_NOVELTY_DECAY), "a repeat harvest must follow novelty decay")
	TEST_ASSERT_EQUAL(antag.partner_harvests[partner.mind], 2, "harvest count must track per partner")

	// Even a maximally aroused ordinary partner cannot fund Enthrall alone in three harvests.
	var/mob/living/carbon/human/high_arousal_partner = allocate(/mob/living/carbon/human)
	high_arousal_partner.mind_initialize()
	var/datum/component/arousal/high_arousal_comp = high_arousal_partner.GetComponent(/datum/component/arousal)
	TEST_ASSERT_NOTNULL(high_arousal_comp, "a human partner must have an arousal component")
	high_arousal_comp.set_arousal(high_arousal_partner, MAX_AROUSAL)
	var/high_arousal_before = antag.essence
	for(var/harvest_index in 1 to SUCCUBUS_ENTHRALL_MIN_HARVESTS)
		antag.harvest_from_climax(high_arousal_partner)
		antag.last_harvest_time = -1
	var/high_arousal_gain = antag.essence - high_arousal_before
	var/expected_high_arousal_gain = 0
	for(var/harvest_index in 0 to SUCCUBUS_ENTHRALL_MIN_HARVESTS - 1)
		var/novelty = max(SUCCUBUS_NOVELTY_FLOOR, SUCCUBUS_NOVELTY_DECAY ** harvest_index)
		expected_high_arousal_gain += round(SUCCUBUS_ESSENCE_BASE_HARVEST * novelty * (1 + SUCCUBUS_AROUSAL_BONUS_MAX))
	TEST_ASSERT_EQUAL(high_arousal_gain, expected_high_arousal_gain, "max arousal must use the capped bonus for every harvest")
	TEST_ASSERT(high_arousal_gain < SUCCUBUS_COST_ENTHRALL, "three ordinary harvests must not fully fund Enthrall")

	// floor: 10 more harvests never go below floor fraction
	for(var/i in 1 to 10)
		antag.harvest_from_climax(partner)
		antag.last_harvest_time = -1
	var/datum/component/arousal/comp = partner.GetComponent(/datum/component/arousal)
	var/arousal_mult = comp ? 1 + min(comp.arousal / SUCCUBUS_AROUSAL_BONUS_DIVISOR, SUCCUBUS_AROUSAL_BONUS_MAX) : 1
	var/floor_gain = round(SUCCUBUS_ESSENCE_BASE_HARVEST * SUCCUBUS_NOVELTY_FLOOR * arousal_mult)
	var/before = antag.essence
	antag.harvest_from_climax(partner)
	TEST_ASSERT(antag.essence - before >= floor_gain * 0.9, "novelty must floor, not decay to zero")

/datum/unit_test/succubus_essence_cap/Run()
	var/datum/antagonist/succubus/antag = allocate(/datum/antagonist/succubus)
	antag.adjust_essence(SUCCUBUS_ESSENCE_CAP_BASE * 3)
	TEST_ASSERT_EQUAL(antag.essence, antag.essence_cap, "essence must clamp at cap")
	antag.adjust_essence(-(antag.essence_cap * 2))
	TEST_ASSERT_EQUAL(antag.essence, 0, "essence must clamp at zero")

/datum/unit_test/succubus_wardrobe/Run()
	var/datum/antagonist/succubus/antag = allocate(/datum/antagonist/succubus)
	for(var/i in 1 to SUCCUBUS_WARDROBE_CAP + 2)
		var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human)
		partner.mind_initialize()
		partner.real_name = "Sample [i]"
		antag.store_partner_form(partner)
	TEST_ASSERT_EQUAL(length(antag.stolen_forms), SUCCUBUS_WARDROBE_CAP, "wardrobe must cap")

/datum/unit_test/succubus_pref_gating/Run()
	// The non-negotiable test (spec §12): an opted-out target yields nothing.
	var/datum/antagonist/succubus/antag = allocate(/datum/antagonist/succubus)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	// No client and no mind -> refresh_erp_preference_cache() finds neither client.prefs nor
	// mind.cached_erp_preferences, so cached_erp_preferences stays null and get_cached_erp_pref()
	// returns FALSE (code/datums/sex/sex_procs.dm ~745-770) -> a clientless test mob reads as
	// warded by default.
	TEST_ASSERT(!target.has_erp_pref(/datum/erp_preference/boolean/lust_magic_targetable), "clientless test mob must read as warded")

	// can_target_lewd() (succubus_abilities.dm) is the single gate every lewd ability funnels
	// through, including Lust's before_cast() essence check — assert directly against it, per the
	// plan's recommended shape.
	TEST_ASSERT(!antag.can_target_lewd(target), "gate proc must reject a warded target")

	antag.essence = 100
	var/essence_before = antag.essence
	// Mirror the Lust ability's before_cast() order (succubus_abilities.dm): can_target_lewd() is
	// checked before any essence is spent, so a warded target must short-circuit before
	// adjust_essence() is ever reached.
	if(antag.can_target_lewd(target))
		antag.adjust_essence(-SUCCUBUS_COST_LUST)
	TEST_ASSERT_EQUAL(antag.essence, essence_before, "no essence may be spent on a warded target")

/datum/unit_test/succubus_reagent_harvest/Run()
	var/datum/antagonist/succubus/antag = allocate(/datum/antagonist/succubus)
	var/mob/living/carbon/human/donor = allocate(/mob/living/carbon/human)
	donor.mind_initialize()
	antag.essence_cap = 100000

	antag.harvest_from_reagent(donor.mind, 10)
	var/first_gain = antag.essence
	TEST_ASSERT_EQUAL(first_gain, SUCCUBUS_ESSENCE_PER_REAGENT_UNIT * 10, "a first tagged-fluid harvest must pay the full reagent rate")

	for(var/i in 1 to 10)
		antag.harvest_from_reagent(donor.mind, 10)
	var/before_late = antag.essence
	antag.harvest_from_reagent(donor.mind, 10)
	var/late_gain = antag.essence - before_late
	TEST_ASSERT(late_gain < first_gain, "repeat absorption from one originator must decay")
	var/floor_gain = SUCCUBUS_ESSENCE_PER_REAGENT_UNIT * 10 * SUCCUBUS_NOVELTY_FLOOR
	TEST_ASSERT(late_gain >= floor_gain * 0.9, "absorption decay must floor, not vanish")

	// Untraceable fluid always pays exactly the floor rate
	var/datum/antagonist/succubus/second_antag = allocate(/datum/antagonist/succubus)
	second_antag.essence_cap = 100000
	second_antag.harvest_from_reagent(null, 10)
	TEST_ASSERT_EQUAL(second_antag.essence, round(SUCCUBUS_ESSENCE_PER_REAGENT_UNIT * 10 * SUCCUBUS_NOVELTY_FLOOR, 0.1), "untraceable fluid must pay the floor rate")

/datum/unit_test/succubus_enthrall_gates/Run()
	var/datum/antagonist/succubus/antag = allocate(/datum/antagonist/succubus)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	target.mind_initialize()
	antag.essence_cap = 100000
	antag.essence = 1000

	// Clientless mobs read every pref FALSE -> warded -> ineligible
	TEST_ASSERT(!antag.can_enthrall(target), "warded (pref-off) target must not be enthrallable")

	// The pref gate must hold no matter how steeped the target is
	antag.partner_harvests[target.mind] = SUCCUBUS_ENTHRALL_MIN_HARVESTS
	TEST_ASSERT(!antag.can_enthrall(target), "pref gate must hold even with sufficient harvests")

/datum/unit_test/succubus_contract_pool/Run()
	var/datum/antagonist/succubus/antag = allocate(/datum/antagonist/succubus)
	var/datum/contract_pool/succubus/pool = allocate(/datum/contract_pool/succubus)

	TEST_ASSERT_EQUAL(antag.contract_pool_type, /datum/contract_pool/succubus, "succubi must opt into their patron pool")
	TEST_ASSERT_EQUAL(pool.goals_per_contract_min, 2, "succubus contracts must request two goals")
	TEST_ASSERT_EQUAL(pool.goals_per_contract_max, 2, "succubus contracts must request exactly two goals")
	TEST_ASSERT_EQUAL(pool.max_tier, SUCCUBUS_CONTRACT_TIER_MAX, "pool tier ceiling must match persistent progression")
	TEST_ASSERT_EQUAL(length(pool.goal_templates), 8, "the initial pool must expose all eight implemented-mechanic goals")
	TEST_ASSERT(/datum/contract_goal/succubus/infernal_tithe in pool.goal_templates, "pool must include the essence tithe")
	TEST_ASSERT(/datum/contract_goal/succubus/varied_appetite in pool.goal_templates, "pool must include distinct partners")
	TEST_ASSERT(/datum/contract_goal/succubus/heightened_desire in pool.goal_templates, "pool must include high-arousal feeding")
	TEST_ASSERT(/datum/contract_goal/succubus/masked_feast in pool.goal_templates, "pool must include disguised feeding")
	TEST_ASSERT(/datum/contract_goal/succubus/sacred_corruption in pool.goal_templates, "pool must include clergy corruption")
	TEST_ASSERT(/datum/contract_goal/succubus/accepted_bond in pool.goal_templates, "pool must include accepted Enthrall")
	TEST_ASSERT(/datum/contract_goal/succubus/infernal_retinue in pool.goal_templates, "pool must include maintained thralls")
	TEST_ASSERT(/datum/contract_goal/succubus/unmasked_hunger in pool.goal_templates, "pool must include true-form feeding")

/datum/unit_test/succubus_contract_harvest_feedthrough/Run()
	var/datum/antagonist/succubus/antag = allocate(/datum/antagonist/succubus)
	antag.essence_cap = 100000
	antag.contract_pool = new /datum/contract_pool/succubus

	var/datum/antag_contract/contract = new
	contract.deadline = world.time + 1 HOURS
	var/datum/contract_goal/succubus/infernal_tithe/tithe = new(antag)
	tithe.target_amount = 1000
	var/datum/contract_goal/succubus/varied_appetite/variety = new(antag)
	variety.target_amount = 2
	var/datum/contract_goal/succubus/heightened_desire/desire = new(antag)
	desire.target_amount = 1
	var/datum/contract_goal/succubus/masked_feast/masked = new(antag)
	var/datum/contract_goal/succubus/sacred_corruption/clergy = new(antag)
	var/datum/contract_goal/succubus/unmasked_hunger/unmasked = new(antag)
	contract.goals = list(tithe, variety, desire, masked, clergy, unmasked)
	antag.current_contract = contract

	var/mob/living/carbon/human/first_partner = allocate(/mob/living/carbon/human)
	first_partner.mind_initialize()
	first_partner.mind.key = "succubus_contract_partner_one"
	first_partner.mind.assigned_role = SSjob.GetJobType(/datum/job/moon_priest)
	var/datum/component/arousal/first_arousal = first_partner.GetComponent(/datum/component/arousal)
	TEST_ASSERT_NOTNULL(first_arousal, "contract test partner must have an arousal component")
	first_arousal.set_arousal(first_partner, MAX_AROUSAL)
	antag.current_form_key = first_partner.mind
	antag.harvest_from_climax(first_partner)

	var/first_gain = round(SUCCUBUS_ESSENCE_BASE_HARVEST * (1 + SUCCUBUS_AROUSAL_BONUS_MAX) * SUCCUBUS_CORRUPTION_CLERGY)
	TEST_ASSERT_EQUAL(tithe.progress, first_gain, "climax must feed its raw essence yield to the tithe")
	TEST_ASSERT_EQUAL(variety.progress, 1, "first player key must count once toward variety")
	TEST_ASSERT_EQUAL(desire.progress, 1, "high arousal must feed the heightened-desire goal")
	TEST_ASSERT_EQUAL(masked.progress, 1, "a stolen identity must feed the masked goal")
	TEST_ASSERT_EQUAL(clergy.progress, 1, "a clergy partner must feed sacred corruption")
	TEST_ASSERT_EQUAL(unmasked.progress, 0, "masked feeding must not count as true-form feeding")

	antag.last_harvest_time = -1
	antag.current_form_key = null
	antag.true_form_active = TRUE
	var/mob/living/carbon/human/second_partner = allocate(/mob/living/carbon/human)
	second_partner.mind_initialize()
	second_partner.mind.key = "succubus_contract_partner_two"
	antag.harvest_from_climax(second_partner)
	TEST_ASSERT_EQUAL(variety.progress, 2, "a second player key must complete variety")
	TEST_ASSERT_EQUAL(unmasked.progress, 1, "feeding in true form must feed unmasked hunger")

	QDEL_NULL(antag.current_contract)
	var/datum/antag_contract/npc_contract = new
	var/datum/contract_goal/succubus/infernal_tithe/npc_tithe = new(antag)
	npc_tithe.target_amount = 1000
	var/datum/contract_goal/succubus/varied_appetite/npc_variety = new(antag)
	npc_variety.target_amount = 3
	npc_contract.goals = list(npc_tithe, npc_variety)
	antag.current_contract = npc_contract
	antag.true_form_active = FALSE
	var/mob/living/carbon/human/npc_partner = allocate(/mob/living/carbon/human)
	npc_partner.mind_initialize()
	antag.harvest_from_climax(npc_partner)
	TEST_ASSERT_EQUAL(npc_tithe.progress, 0, "a keyless NPC must not satisfy the patron's essence demand")
	TEST_ASSERT_EQUAL(npc_variety.progress, 0, "a keyless NPC must not count as a distinct player partner")

/datum/unit_test/succubus_contract_enthrall_feedthrough/Run()
	var/datum/antagonist/succubus/antag = allocate(/datum/antagonist/succubus)
	var/mob/living/carbon/human/mistress = allocate(/mob/living/carbon/human)
	mistress.mind_initialize()
	antag.owner = mistress.mind
	antag.essence_cap = 1000
	antag.essence = 500
	antag.contract_pool = new /datum/contract_pool/succubus

	var/datum/antag_contract/contract = new
	var/datum/contract_goal/succubus/accepted_bond/bond = new(antag)
	contract.goals = list(bond)
	antag.current_contract = contract
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	target.mind_initialize()

	TEST_ASSERT(antag.complete_enthrallment(target), "directly completing a valid test bond must succeed")
	TEST_ASSERT_EQUAL(bond.progress, 1, "only a completed Enthrall bond must feed its contract goal")
	TEST_ASSERT_EQUAL(antag.essence, 500 - SUCCUBUS_COST_ENTHRALL, "completed Enthrall must retain its normal essence cost")

	antag.unenthrall(target.mind, keep_memories = FALSE)
	qdel(antag.harem)
	antag.harem = null
	antag.owner = null

/datum/unit_test/succubus_contract_progression_upkeep/Run()
	var/datum/antagonist/succubus/test_contract_upkeep/antag = allocate(/datum/antagonist/succubus/test_contract_upkeep)
	var/mob/living/carbon/human/succubus = allocate(/mob/living/carbon/human)
	succubus.mind_initialize()
	antag.owner = succubus.mind

	antag.contracts_completed_full = 0
	antag.refresh_succubus_contract_progression()
	TEST_ASSERT_EQUAL(antag.get_succubus_contract_tier(), 1, "zero full contracts must remain tier 1")
	TEST_ASSERT_EQUAL(antag.essence_cap, SUCCUBUS_ESSENCE_CAP_BASE, "tier 1 cap must be the base cap")
	TEST_ASSERT_NULL(succubus.get_spell(/datum/action/cooldown/spell/undirected/succubus_beguiling_doubles, TRUE), "tier 1 must not grant Beguiling Doubles")
	TEST_ASSERT_NULL(succubus.get_spell(/datum/action/cooldown/spell/undirected/succubus_true_form, TRUE), "tier 1 must not grant True Form")

	antag.contracts_completed_full = 1
	TEST_ASSERT(antag.refresh_succubus_contract_progression(), "first full contract must change the cap")
	TEST_ASSERT_EQUAL(antag.essence_cap, SUCCUBUS_ESSENCE_CAP_TIER_2, "one full contract must grant the tier 2 cap")
	var/datum/action/cooldown/spell/undirected/succubus_beguiling_doubles/doubles = succubus.get_spell(/datum/action/cooldown/spell/undirected/succubus_beguiling_doubles, TRUE)
	var/datum/action/cooldown/spell/undirected/succubus_true_form/true_form = succubus.get_spell(/datum/action/cooldown/spell/undirected/succubus_true_form, TRUE)
	TEST_ASSERT_NOTNULL(doubles, "tier 2 must grant Beguiling Doubles")
	TEST_ASSERT_NOTNULL(true_form, "tier 2 must grant True Form")
	TEST_ASSERT_NULL(succubus.get_spell(/datum/action/cooldown/spell/undirected/succubus_summon_imp, TRUE), "tier 2 must not grant Call Whispering Imp")
	TEST_ASSERT_NULL(succubus.get_spell(/datum/action/cooldown/spell/undirected/succubus_summon_lusthound, TRUE), "tier 2 must not grant Call Lustbound Hound")
	TEST_ASSERT_NULL(succubus.get_spell(/datum/action/cooldown/spell/succubus_infernal_snare, TRUE), "tier 2 must not grant Lay Infernal Snare")
	TEST_ASSERT(!antag.refresh_succubus_contract_progression(), "refreshing the same tier must be idempotent")
	TEST_ASSERT_EQUAL(succubus.get_spell(/datum/action/cooldown/spell/undirected/succubus_beguiling_doubles, TRUE), doubles, "refreshing tier 2 must not replace Beguiling Doubles")
	TEST_ASSERT_EQUAL(succubus.get_spell(/datum/action/cooldown/spell/undirected/succubus_true_form, TRUE), true_form, "refreshing tier 2 must not replace True Form")

	antag.contracts_completed_full = 2
	antag.refresh_succubus_contract_progression()
	TEST_ASSERT_EQUAL(antag.essence_cap, SUCCUBUS_ESSENCE_CAP_TIER_3, "two full contracts must grant the tier 3 cap")
	var/datum/action/cooldown/spell/undirected/succubus_summon_imp/summon_imp = succubus.get_spell(/datum/action/cooldown/spell/undirected/succubus_summon_imp, TRUE)
	var/datum/action/cooldown/spell/undirected/succubus_summon_lusthound/summon_lusthound = succubus.get_spell(/datum/action/cooldown/spell/undirected/succubus_summon_lusthound, TRUE)
	var/datum/action/cooldown/spell/succubus_infernal_snare/infernal_snare = succubus.get_spell(/datum/action/cooldown/spell/succubus_infernal_snare, TRUE)
	TEST_ASSERT_NOTNULL(summon_imp, "tier 3 must grant Call Whispering Imp")
	TEST_ASSERT_NOTNULL(summon_lusthound, "tier 3 must grant Call Lustbound Hound")
	TEST_ASSERT_NOTNULL(infernal_snare, "tier 3 must grant Lay Infernal Snare")
	TEST_ASSERT(!antag.refresh_succubus_contract_progression(), "refreshing tier 3 must be idempotent")
	TEST_ASSERT_EQUAL(succubus.get_spell(/datum/action/cooldown/spell/undirected/succubus_summon_imp, TRUE), summon_imp, "refreshing tier 3 must not replace Call Whispering Imp")
	TEST_ASSERT_EQUAL(succubus.get_spell(/datum/action/cooldown/spell/undirected/succubus_summon_lusthound, TRUE), summon_lusthound, "refreshing tier 3 must not replace Call Lustbound Hound")
	TEST_ASSERT_EQUAL(succubus.get_spell(/datum/action/cooldown/spell/succubus_infernal_snare, TRUE), infernal_snare, "refreshing tier 3 must not replace Lay Infernal Snare")

	antag.contracts_completed_full = 1
	antag.refresh_succubus_contract_progression()
	TEST_ASSERT_NULL(succubus.get_spell(/datum/action/cooldown/spell/undirected/succubus_summon_imp, TRUE), "dropping below tier 3 must remove Call Whispering Imp")
	TEST_ASSERT_NULL(succubus.get_spell(/datum/action/cooldown/spell/undirected/succubus_summon_lusthound, TRUE), "dropping below tier 3 must remove Call Lustbound Hound")
	TEST_ASSERT_NULL(succubus.get_spell(/datum/action/cooldown/spell/succubus_infernal_snare, TRUE), "dropping below tier 3 must remove Lay Infernal Snare")

	antag.contracts_completed_full = 3
	antag.refresh_succubus_contract_progression()
	TEST_ASSERT_EQUAL(antag.essence_cap, SUCCUBUS_ESSENCE_CAP_TIER_4, "three full contracts must grant the tier 4 cap")

	antag.contracts_completed_full = 10
	antag.refresh_succubus_contract_progression()
	TEST_ASSERT_EQUAL(antag.get_succubus_contract_tier(), SUCCUBUS_CONTRACT_TIER_MAX, "persistent tier must clamp at the maximum")
	TEST_ASSERT_EQUAL(antag.essence_cap, SUCCUBUS_ESSENCE_CAP_TIER_4, "later full contracts must not exceed the tier 4 cap")

	antag.test_thrall_count = 2
	antag.essence = 200
	antag.on_contract_cycle_closed(null)
	TEST_ASSERT_EQUAL(antag.essence, 200 - (2 * SUCCUBUS_THRALL_UPKEEP_PER_CYCLE), "each thrall must charge one cycle of upkeep")
	TEST_ASSERT_EQUAL(antag.test_thrall_count, 2, "upkeep must not silently release consenting thralls")

	antag.essence = 10
	antag.on_contract_cycle_closed(null)
	TEST_ASSERT_EQUAL(antag.essence, 0, "insufficient upkeep must clamp essence at zero")
	TEST_ASSERT_EQUAL(antag.test_thrall_count, 2, "unpaid upkeep must leave the harem unchanged")

	antag.owner = null

/datum/unit_test/succubus_imp_ownership_lifecycle/Run()
	var/datum/antagonist/succubus/mistress_datum = allocate(/datum/antagonist/succubus)
	var/mob/living/carbon/human/mistress = allocate(/mob/living/carbon/human)
	mistress.mind_initialize()
	mistress_datum.owner = mistress.mind

	var/mob/living/simple_animal/hostile/retaliate/infernal/imp/succubus/imp = allocate(/mob/living/simple_animal/hostile/retaliate/infernal/imp/succubus)
	imp.mind_initialize()
	var/datum/antagonist/succubus_imp/imp_datum = allocate(/datum/antagonist/succubus_imp)
	imp_datum.owner = imp.mind
	imp_datum.mistress_mind = mistress.mind
	LAZYADD(imp.mind.antag_datums, imp_datum)
	mistress_datum.summoned_imp_minds += imp.mind

	var/mob/living/carbon/human/stale_owner = allocate(/mob/living/carbon/human)
	stale_owner.mind_initialize()
	mistress_datum.summoned_imp_minds += stale_owner.mind

	TEST_ASSERT_EQUAL(mistress_datum.count_summoned_imps(), 1, "only a live imp datum linked to this succubus may count toward the cap")
	TEST_ASSERT(!(stale_owner.mind in mistress_datum.summoned_imp_minds), "counting imps must prune stale mind entries")

	qdel(imp_datum)
	TEST_ASSERT_EQUAL(mistress_datum.count_summoned_imps(), 0, "destroying the imp datum must release its mistress's cap entry")

	mistress_datum.owner = null

/datum/unit_test/succubus_imp_controller_stays_inert/Run()
	var/mob/living/simple_animal/hostile/retaliate/infernal/imp/succubus/imp = allocate(/mob/living/simple_animal/hostile/retaliate/infernal/imp/succubus)
	var/datum/ai_controller/imp/succubus/controller = imp.ai_controller
	TEST_ASSERT_NOTNULL(controller, "a whispering imp must receive its dedicated controller")
	TEST_ASSERT_EQUAL(controller.ai_status, AI_STATUS_OFF, "a clientless whispering imp must initialize inert")

	controller.on_sentience_gained()
	controller.on_sentience_lost()
	TEST_ASSERT_EQUAL(controller.ai_status, AI_STATUS_OFF, "a disconnected whispering imp must remain inert")

	controller.set_ai_status(AI_STATUS_ON)
	TEST_ASSERT_EQUAL(controller.ai_status, AI_STATUS_OFF, "other AI wake-up paths must not activate a whispering imp")

/datum/unit_test/succubus_lusthound_lifecycle/Run()
	var/datum/antagonist/succubus/mistress_datum = allocate(/datum/antagonist/succubus)
	var/mob/living/carbon/human/mistress = allocate(/mob/living/carbon/human)
	mistress.mind_initialize()
	mistress_datum.owner = mistress.mind
	mistress_datum.contracts_completed_full = 2
	mistress_datum.essence = SUCCUBUS_COST_SUMMON_LUSTHOUND * 2
	LAZYADD(mistress.mind.antag_datums, mistress_datum)

	var/datum/action/cooldown/spell/undirected/succubus_summon_lusthound/summon_spell = allocate(/datum/action/cooldown/spell/undirected/succubus_summon_lusthound)
	summon_spell.Grant(mistress)
	TEST_ASSERT(!(summon_spell.before_cast(mistress) & SPELL_CANCEL_CAST), "tier 3 with essence and clear adjacent ground must pass the hound summon gate")
	summon_spell.cast(mistress)

	TEST_ASSERT_EQUAL(mistress_datum.count_summoned_lusthounds(), 1, "a successful cast must consume the lustbound hound cap")
	TEST_ASSERT_EQUAL(mistress_datum.essence, SUCCUBUS_COST_SUMMON_LUSTHOUND, "a successful cast must charge the hound's essence cost")
	var/mob/living/simple_animal/hostile/retaliate/wolf/companion/lustbound/first_hound = mistress_datum.summoned_lusthounds[1]
	TEST_ASSERT_NOTNULL(first_hound, "a successful cast must create a tracked lustbound hound")
	TEST_ASSERT(istype(first_hound.ai_controller, /datum/ai_controller/summon/succubus_lusthound), "the hound must receive its command-driven horny controller")
	TEST_ASSERT(locate(/datum/ai_planning_subtree/horny) in first_hound.ai_controller.planning_subtrees, "the hound controller must retain the existing horny behavior")
	TEST_ASSERT(!(locate(/datum/ai_planning_subtree/simple_find_horny) in first_hound.ai_controller.planning_subtrees), "the hound must not autonomously search for horny targets")
	var/datum/component/obeys_commands/commands = first_hound.GetComponent(/datum/component/obeys_commands)
	TEST_ASSERT_NOTNULL(commands, "the hound must use the existing pet command component")
	TEST_ASSERT_NOTNULL(commands.available_commands["Ravage"], "the hound must expose the preference-gated Ravage order")
	TEST_ASSERT(summon_spell.before_cast(mistress) & SPELL_CANCEL_CAST, "the active cap must reject a second lustbound hound")

	qdel(first_hound)
	TEST_ASSERT_EQUAL(mistress_datum.count_summoned_lusthounds(), 0, "destroying the hound must immediately release its cap entry")
	summon_spell.cast(mistress)
	var/mob/living/simple_animal/hostile/retaliate/wolf/companion/lustbound/second_hound = mistress_datum.summoned_lusthounds[1]
	TEST_ASSERT_NOTNULL(second_hound, "the released cap must permit another hound")

	mistress.mind.antag_datums -= mistress_datum
	qdel(mistress_datum)
	TEST_ASSERT(QDELETED(second_hound), "removing the succubus datum must delete its owned NPC hound")

/datum/unit_test/succubus_lusthound_command_gates/Run()
	var/turf/test_turf = get_turf(run_loc_floor_bottom_left)
	var/mob/living/simple_animal/hostile/retaliate/wolf/companion/lustbound/hound = allocate(/mob/living/simple_animal/hostile/retaliate/wolf/companion/lustbound, test_turf)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human, test_turf)
	hound.gender = MALE
	target.set_cached_erp_preferences(list(
		/datum/erp_preference/bitflag/horny_mobs = HORNY_MOBS_TAG_MALES,
		/datum/erp_preference/bitflag/horny_mob_types = HORNY_MOB_TYPE_BEASTS,
	))

	var/datum/ai_controller/controller = hound.ai_controller
	var/datum/targetting_datum/basic/succubus_lusthound_unit_test/targetting_datum = allocate(/datum/targetting_datum/basic/succubus_lusthound_unit_test)
	controller.set_blackboard_key(BB_TARGETTING_DATUM, targetting_datum)
	var/datum/pet_command/succubus_lusthound_ravage/command = allocate(/datum/pet_command/succubus_lusthound_ravage, hound)

	TEST_ASSERT(command.set_command_target(hound, target), "Ravage must accept a matching beast-family and mob-gender preference")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_BASIC_MOB_CURRENT_HORNY_TARGET], target, "an accepted Ravage order must feed the existing horny target pipeline")
	controller.set_blackboard_key(BB_ACTIVE_PET_COMMAND, command)
	command.execute_action(controller)
	TEST_ASSERT_NULL(controller.blackboard[BB_ACTIVE_PET_COMMAND], "an accepted Ravage order must release pet planning so the horny subtree can execute")

	controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_HORNY_TARGET)
	target.set_cached_erp_preferences(list(
		/datum/erp_preference/bitflag/horny_mobs = NONE,
		/datum/erp_preference/bitflag/horny_mob_types = NONE,
	))
	TEST_ASSERT(!command.set_command_target(hound, target), "Ravage must refuse a target without compatible horny-mob preferences")
	TEST_ASSERT_NULL(controller.blackboard[BB_BASIC_MOB_CURRENT_HORNY_TARGET], "a refused Ravage order must not populate the horny target pipeline")

/datum/unit_test/succubus_infernal_snare_lifecycle/Run()
	var/datum/antagonist/succubus/mistress_datum = allocate(/datum/antagonist/succubus)
	var/mob/living/carbon/human/mistress = allocate(/mob/living/carbon/human)
	mistress.mind_initialize()
	mistress_datum.owner = mistress.mind
	LAZYADD(mistress.mind.antag_datums, mistress_datum)

	var/obj/structure/succubus_infernal_snare/snare = allocate(/obj/structure/succubus_infernal_snare)
	TEST_ASSERT(snare.bind_to(mistress_datum), "a snare must bind to a succubus with an owner")
	TEST_ASSERT_EQUAL(length(mistress_datum.infernal_snares), 1, "binding must consume one owner cap entry")

	snare.Crossed(mistress)
	TEST_ASSERT(!QDELETED(snare), "the owning succubus must not trigger her snare")
	TEST_ASSERT_EQUAL(mistress.AmountImmobilized(), 0, "the owning succubus must not be immobilized")

	var/mob/living/carbon/human/thrall = allocate(/mob/living/carbon/human)
	thrall.mind_initialize()
	var/datum/antagonist/succubus_thrall/thrall_datum = allocate(/datum/antagonist/succubus_thrall)
	thrall_datum.owner = thrall.mind
	thrall_datum.mistress_mind = mistress.mind
	LAZYADD(thrall.mind.antag_datums, thrall_datum)
	snare.Crossed(thrall)
	TEST_ASSERT(!QDELETED(snare), "a linked thrall must not trigger her mistress's snare")
	TEST_ASSERT_EQUAL(thrall.AmountImmobilized(), 0, "a linked thrall must not be immobilized")

	var/mob/living/simple_animal/hostile/retaliate/infernal/imp/succubus/imp = allocate(/mob/living/simple_animal/hostile/retaliate/infernal/imp/succubus)
	imp.mind_initialize()
	var/datum/antagonist/succubus_imp/imp_datum = allocate(/datum/antagonist/succubus_imp)
	imp_datum.owner = imp.mind
	imp_datum.mistress_mind = mistress.mind
	LAZYADD(imp.mind.antag_datums, imp_datum)
	snare.Crossed(imp)
	TEST_ASSERT(!QDELETED(snare), "a linked whispering imp must not trigger its mistress's snare")
	TEST_ASSERT_EQUAL(imp.AmountImmobilized(), 0, "a linked whispering imp must not be immobilized")

	var/mob/living/simple_animal/hostile/retaliate/wolf/companion/lustbound/hound = allocate(/mob/living/simple_animal/hostile/retaliate/wolf/companion/lustbound)
	TEST_ASSERT(hound.bind_to(mistress_datum), "a lustbound hound must bind to its summoner")
	snare.Crossed(hound)
	TEST_ASSERT(!QDELETED(snare), "an owned lustbound hound must not trigger its mistress's snare")
	TEST_ASSERT_EQUAL(hound.AmountImmobilized(), 0, "an owned lustbound hound must not be immobilized")
	qdel(hound)

	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	victim.mind_initialize()
	victim.movement_type |= FLYING
	snare.Crossed(victim)
	TEST_ASSERT(!QDELETED(snare), "an airborne living target must not trigger the snare")
	TEST_ASSERT_EQUAL(victim.AmountImmobilized(), 0, "an airborne living target must not be immobilized")

	victim.movement_type &= ~FLYING
	snare.Crossed(victim)
	TEST_ASSERT(QDELETED(snare), "the first unrelated grounded living target must consume the snare")
	TEST_ASSERT(victim.AmountImmobilized() > 0, "a triggered snare must immobilize its victim")
	TEST_ASSERT(victim.AmountKnockdown() > 0, "a triggered snare must knock down its victim")
	TEST_ASSERT(istype(victim.legcuffed, /obj/item/rope/chain/infernal), "a triggered snare must bind a carbon victim's legs")
	TEST_ASSERT_EQUAL(length(mistress_datum.infernal_snares), 0, "triggering must release the owner's cap entry")

	var/obj/structure/succubus_infernal_snare/deleted_snare = allocate(/obj/structure/succubus_infernal_snare)
	TEST_ASSERT(deleted_snare.bind_to(mistress_datum), "a replacement snare must bind after the first is consumed")
	qdel(deleted_snare)
	TEST_ASSERT_EQUAL(length(mistress_datum.infernal_snares), 0, "manual destruction must release the owner's cap entry")

	thrall.mind.antag_datums -= thrall_datum
	thrall_datum.owner = null
	qdel(thrall_datum)
	imp.mind.antag_datums -= imp_datum
	imp_datum.owner = null
	qdel(imp_datum)
	mistress.mind.antag_datums -= mistress_datum
	mistress_datum.owner = null

/datum/unit_test/succubus_infernal_snare_placement_gates/Run()
	var/datum/antagonist/succubus/mistress_datum = allocate(/datum/antagonist/succubus)
	var/mob/living/carbon/human/mistress = allocate(/mob/living/carbon/human)
	mistress.mind_initialize()
	mistress_datum.owner = mistress.mind
	mistress_datum.essence = SUCCUBUS_COST_INFERNAL_SNARE * 3
	LAZYADD(mistress.mind.antag_datums, mistress_datum)

	var/datum/action/cooldown/spell/succubus_infernal_snare/snare_spell = allocate(/datum/action/cooldown/spell/succubus_infernal_snare)
	snare_spell.Grant(mistress)
	var/turf/first_turf = get_turf(mistress)
	var/turf/second_turf = get_step(first_turf, EAST)
	var/turf/third_turf = get_step(first_turf, NORTH)
	TEST_ASSERT(isfloorturf(second_turf) && isfloorturf(third_turf), "placement test needs adjacent solid floor turfs")

	mistress_datum.contracts_completed_full = 1
	TEST_ASSERT(snare_spell.before_cast(first_turf) & SPELL_CANCEL_CAST, "tier 2 must fail the placement gate")
	mistress_datum.contracts_completed_full = 2
	TEST_ASSERT(!(snare_spell.before_cast(first_turf) & SPELL_CANCEL_CAST), "tier 3 with essence and clear ground must pass the placement gate")

	var/obj/structure/succubus_infernal_snare/first_snare = allocate(/obj/structure/succubus_infernal_snare, first_turf)
	TEST_ASSERT(first_snare.bind_to(mistress_datum), "the first placement test snare must bind")
	TEST_ASSERT(snare_spell.before_cast(first_turf) & SPELL_CANCEL_CAST, "a turf already holding a snare must fail the occupancy gate")

	var/obj/structure/succubus_infernal_snare/second_snare = allocate(/obj/structure/succubus_infernal_snare, second_turf)
	TEST_ASSERT(second_snare.bind_to(mistress_datum), "the second placement test snare must bind")
	TEST_ASSERT(snare_spell.before_cast(third_turf) & SPELL_CANCEL_CAST, "the active cap must reject a third snare")

	qdel(second_snare)
	TEST_ASSERT(!(snare_spell.before_cast(third_turf) & SPELL_CANCEL_CAST), "destroying a snare must immediately reopen the placement cap")

	mistress.mind.antag_datums -= mistress_datum
	mistress_datum.owner = null

/datum/unit_test/succubus_harem_team/Run()
	var/datum/antagonist/succubus/antag = allocate(/datum/antagonist/succubus)
	var/mob/living/carbon/human/mistress_mob = allocate(/mob/living/carbon/human)
	mistress_mob.mind_initialize()
	antag.owner = mistress_mob.mind

	var/datum/team/succubus_harem/team = antag.ensure_harem()
	TEST_ASSERT_NOTNULL(team, "ensure_harem must create the team")
	TEST_ASSERT_EQUAL(antag.ensure_harem(), team, "ensure_harem must be idempotent")
	TEST_ASSERT(antag.owner in team.members, "the mistress must be a team member")
	TEST_ASSERT_EQUAL(antag.get_team(), team, "get_team must expose the harem")
	TEST_ASSERT_EQUAL(antag.count_thralls(), 0, "mistress alone means zero thralls")
	qdel(team)
	antag.harem = null
	antag.owner = null // hand-set above, not via add_antag_datum; detach before harness qdel

/datum/unit_test/succubus_true_form_gates/Run()
	var/datum/antagonist/succubus/antag = allocate(/datum/antagonist/succubus)
	var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human)
	body.mind_initialize()
	antag.owner = body.mind
	body.mind.current = body
	antag.essence_cap = 100000

	antag.essence = SUCCUBUS_COST_TRUE_FORM
	TEST_ASSERT(!antag.can_assume_true_form(TRUE), "true form must remain locked at tier 1")
	antag.contracts_completed_full = 1
	antag.essence = 0
	TEST_ASSERT(!antag.can_assume_true_form(TRUE), "true form must be essence-gated")
	antag.essence = SUCCUBUS_COST_TRUE_FORM
	TEST_ASSERT(antag.can_assume_true_form(TRUE), "sufficient essence must open the gate")

	antag.grant_true_form_actions(body)
	TEST_ASSERT_NOTNULL(body.get_spell(/datum/action/cooldown/spell/succubus_wingbeat), "true form must gain Wingbeat")
	TEST_ASSERT_NOTNULL(body.get_spell(/datum/action/cooldown/spell/aoe/repulse/dragon/succubus), "true form must gain Tail Sweep")
	TEST_ASSERT_NOTNULL(body.get_spell(/datum/action/cooldown/spell/succubus_sovereign_gaze), "true form must gain Sovereign Gaze")
	TEST_ASSERT_NOTNULL(body.get_spell(/datum/action/cooldown/spell/undirected/succubus_predatory_claws), "true form must gain Predatory Claws")
	antag.remove_true_form_actions(body)
	TEST_ASSERT_NULL(body.get_spell(/datum/action/cooldown/spell/succubus_wingbeat), "leaving true form must remove Wingbeat")
	TEST_ASSERT_NULL(body.get_spell(/datum/action/cooldown/spell/aoe/repulse/dragon/succubus), "leaving true form must remove Tail Sweep")
	TEST_ASSERT_NULL(body.get_spell(/datum/action/cooldown/spell/succubus_sovereign_gaze), "leaving true form must remove Sovereign Gaze")
	TEST_ASSERT_NULL(body.get_spell(/datum/action/cooldown/spell/undirected/succubus_predatory_claws), "leaving true form must remove Predatory Claws")

	var/mob/living/carbon/human/species/succubus_true/form_body = allocate(/mob/living/carbon/human/species/succubus_true)
	var/datum/action/cooldown/spell/undirected/succubus_predatory_claws/claw_spell = allocate(/datum/action/cooldown/spell/undirected/succubus_predatory_claws)
	claw_spell.Grant(form_body)
	claw_spell.cast(form_body)
	var/obj/item/weapon/succubus_claw/left/left_claw = form_body.get_item_for_held_index(1)
	var/obj/item/weapon/succubus_claw/right/right_claw = form_body.get_item_for_held_index(2)
	TEST_ASSERT_NOTNULL(left_claw, "Predatory Claws must fill the left hand")
	TEST_ASSERT_NOTNULL(right_claw, "Predatory Claws must fill the right hand")
	TEST_ASSERT_EQUAL(left_claw.force, DAMAGE_KNIFE, "Predatory Claws must remain below werewolf claw damage")
	TEST_ASSERT_EQUAL(left_claw.possible_item_intents[1], /datum/intent/simple/succubus_claw, "Predatory Claws must use their bounded natural-weapon intent")
	TEST_ASSERT(HAS_TRAIT(left_claw, TRAIT_NODROP), "Predatory Claws must not be transferable")
	claw_spell.Remove(form_body)
	TEST_ASSERT(QDELETED(left_claw), "removing the form action must delete its left claw")
	TEST_ASSERT(QDELETED(right_claw), "removing the form action must delete its right claw")

	TEST_ASSERT(antag.is_linked_retinue(body), "the succubus's current body must be recognized as friendly")
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human)
	stranger.mind_initialize()
	TEST_ASSERT(!antag.is_linked_retinue(stranger), "an unrelated living mob must not be recognized as friendly")
	var/datum/antagonist/succubus_thrall/thrall_datum = allocate(/datum/antagonist/succubus_thrall)
	thrall_datum.owner = stranger.mind
	thrall_datum.mistress_mind = body.mind
	LAZYADD(stranger.mind.antag_datums, thrall_datum)
	TEST_ASSERT(antag.is_linked_retinue(stranger), "a linked thrall must be protected from true-form area effects")
	stranger.mind.antag_datums -= thrall_datum
	thrall_datum.owner = null
	qdel(thrall_datum)

	antag.true_form_active = TRUE
	TEST_ASSERT(!antag.can_assume_true_form(TRUE), "cannot assume while already assumed")
	antag.true_form_active = FALSE
	antag.owner = null // hand-set; detach before harness qdel

/datum/unit_test/succubus_sovereign_gaze/Run()
	var/turf/caster_turf = get_turf(run_loc_floor_bottom_left)
	var/turf/target_turf = get_step(caster_turf, EAST)
	var/turf/warded_turf = get_step(caster_turf, NORTH)
	TEST_ASSERT(isfloorturf(target_turf) && isfloorturf(warded_turf), "Sovereign Gaze test needs adjacent floor turfs")

	var/mob/living/carbon/human/species/succubus_true/caster = allocate(/mob/living/carbon/human/species/succubus_true, caster_turf)
	caster.mind_initialize()
	var/datum/antagonist/succubus/antag = allocate(/datum/antagonist/succubus)
	antag.owner = caster.mind
	LAZYADD(caster.mind.antag_datums, antag)
	var/datum/action/cooldown/spell/succubus_sovereign_gaze/gaze = allocate(/datum/action/cooldown/spell/succubus_sovereign_gaze)
	gaze.Grant(caster)

	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human, target_turf)
	caster.setDir(EAST)
	target.setDir(WEST)
	TEST_ASSERT(gaze.is_valid_target(target), "a conscious creature meeting the true form's gaze must be valid")

	target.set_eyes_closed(TRUE)
	TEST_ASSERT(!gaze.is_valid_target(target), "closing one's eyes must counter Sovereign Gaze")
	target.set_eyes_closed(FALSE)
	target.setDir(EAST)
	TEST_ASSERT(!gaze.is_valid_target(target), "turning away must counter Sovereign Gaze")
	target.setDir(WEST)

	gaze.cast(target)
	TEST_ASSERT(target.AmountImmobilized() > 0, "an unwarded target must be briefly immobilized")
	var/datum/status_effect/debuff/mesmerised/mesmerised = target.has_status_effect(/datum/status_effect/debuff/mesmerised)
	TEST_ASSERT_NOTNULL(mesmerised, "an unwarded target must be mesmerised")
	TEST_ASSERT_EQUAL(mesmerised.initial_duration, SUCCUBUS_TRUE_FORM_GAZE_MESMERISED_DURATION, "Sovereign Gaze must use its bounded mesmerise duration")

	var/mob/living/carbon/human/warded_target = allocate(/mob/living/carbon/human, warded_turf)
	caster.setDir(NORTH)
	warded_target.setDir(SOUTH)
	warded_target.apply_status_effect(/datum/status_effect/buff/protection_evil_good)
	TEST_ASSERT(HAS_TRAIT(warded_target, TRAIT_PROTECTION_EVIL_GOOD), "the protection spell must establish its ward trait")
	TEST_ASSERT(gaze.PreActivate(warded_target), "a warded gaze attempt must still complete its cast")
	TEST_ASSERT_EQUAL(warded_target.AmountImmobilized(), 0, "Protection from Evil and Good must prevent gaze immobilization")
	TEST_ASSERT_NULL(warded_target.has_status_effect(/datum/status_effect/debuff/mesmerised), "Protection from Evil and Good must prevent mesmerism")
	TEST_ASSERT(gaze.next_use_time > world.time, "a divine ward must consume the gaze's full cast and cooldown")

	var/mob/living/carbon/human/antimagic_target = allocate(/mob/living/carbon/human, target_turf)
	var/datum/component/anti_magic/mind_ward = antimagic_target.AddComponent(/datum/component/anti_magic, MAGIC_RESISTANCE_MIND)
	TEST_ASSERT_NOTNULL(mind_ward, "mental antimagic test target must receive its ward")
	gaze.cast(antimagic_target)
	TEST_ASSERT_EQUAL(antimagic_target.AmountImmobilized(), 0, "mental antimagic must prevent gaze immobilization")
	TEST_ASSERT_NULL(antimagic_target.has_status_effect(/datum/status_effect/debuff/mesmerised), "mental antimagic must prevent mesmerism")

	caster.mind.antag_datums -= antag
	antag.owner = null

/datum/unit_test/succubus_rift_objective_and_unlock/Run()
	var/datum/antagonist/succubus/antag = allocate(/datum/antagonist/succubus)
	var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human)
	body.mind_initialize()
	antag.owner = body.mind
	LAZYADD(body.mind.antag_datums, antag)

	var/datum/objective/succubus/rift/rift_objective = antag.forge_succubus_objectives()
	TEST_ASSERT_NOTNULL(rift_objective, "the Succubus must receive a Rift campaign objective")
	TEST_ASSERT_EQUAL(rift_objective.owner, body.mind, "the Rift objective must belong to the Succubus mind")
	TEST_ASSERT(!rift_objective.check_completion(), "Rift-A must not begin with its future ascension result complete")
	TEST_ASSERT_EQUAL(antag.forge_succubus_objectives(), rift_objective, "forging objectives twice must reuse the existing Rift objective")

	var/rift_objective_count = 0
	for(var/datum/objective/succubus/rift/found_objective in antag.objectives)
		rift_objective_count++
	TEST_ASSERT_EQUAL(rift_objective_count, 1, "objective forging must remain idempotent")

	antag.true_form_active = TRUE
	antag.contracts_completed_full = 2
	antag.refresh_succubus_rift_action(body)
	TEST_ASSERT_NULL(body.get_spell(/datum/action/cooldown/spell/undirected/succubus_rift, TRUE), "Tier 3 True Form must not receive the Rift ritual")

	antag.contracts_completed_full = 3
	antag.refresh_succubus_rift_action(body)
	TEST_ASSERT_NOTNULL(body.get_spell(/datum/action/cooldown/spell/undirected/succubus_rift, TRUE), "Tier 4 True Form must receive the Rift ritual")
	antag.remove_true_form_actions(body)
	TEST_ASSERT_NULL(body.get_spell(/datum/action/cooldown/spell/undirected/succubus_rift, TRUE), "leaving True Form must remove the Rift ritual")

	antag.true_form_active = FALSE
	body.mind.antag_datums -= antag
	antag.owner = null

/datum/unit_test/succubus_rift_stage_lifecycle/Run()
	var/datum/antagonist/succubus/antag = allocate(/datum/antagonist/succubus)
	var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human)
	body.mind_initialize()
	antag.owner = body.mind
	LAZYADD(body.mind.antag_datums, antag)

	var/obj/structure/succubus_rift/rift = allocate(/obj/structure/succubus_rift)
	TEST_ASSERT(rift.bind_to(antag), "an unclaimed world must accept the Succubus's first Rift")
	TEST_ASSERT_EQUAL(antag.get_active_rift(), rift, "binding must establish the owner's weak Rift link")
	TEST_ASSERT_EQUAL(rift.owner_mind_ref?.resolve(), body.mind, "binding must establish the Rift's weak owner-mind link")
	TEST_ASSERT(rift in GLOB.active_succubus_rifts, "binding must register the Rift globally")
	TEST_ASSERT_EQUAL(rift.get_next_channel_time(), SUCCUBUS_RIFT_SEED_CHANNEL, "an unseeded Rift must use the seed channel")

	TEST_ASSERT(rift.advance_stage(ignore_maturation = TRUE, trigger_stage_effects = FALSE), "the first ritual stage must seed the Rift")
	TEST_ASSERT_EQUAL(rift.current_stage, SUCCUBUS_RIFT_STAGE_SEED, "the first transition must enter the seeded stage")
	TEST_ASSERT_EQUAL(rift.max_integrity, SUCCUBUS_RIFT_SEED_INTEGRITY, "the seeded Rift must use seeded integrity")
	TEST_ASSERT_EQUAL(rift.get_integrity(), SUCCUBUS_RIFT_SEED_INTEGRITY, "advancement must fully reinforce the seeded Rift")
	TEST_ASSERT_EQUAL(rift.next_stage_at, world.time + SUCCUBUS_RIFT_MATURATION, "the seeded Rift must receive a maturation deadline")
	TEST_ASSERT_EQUAL(rift.get_next_channel_time(), SUCCUBUS_RIFT_WIDEN_CHANNEL, "a seeded Rift must use the widening channel")

	rift.next_stage_at = world.time
	TEST_ASSERT(rift.advance_stage(trigger_stage_effects = FALSE), "a mature seeded Rift must widen")
	TEST_ASSERT_EQUAL(rift.current_stage, SUCCUBUS_RIFT_STAGE_WIDENED, "the second transition must enter the widened stage")
	TEST_ASSERT_EQUAL(rift.max_integrity, SUCCUBUS_RIFT_WIDENED_INTEGRITY, "the widened Rift must use widened integrity")
	TEST_ASSERT_EQUAL(rift.get_next_channel_time(), SUCCUBUS_RIFT_OPEN_CHANNEL, "a widened Rift must use the opening channel")

	rift.next_stage_at = world.time
	TEST_ASSERT(rift.advance_stage(trigger_stage_effects = FALSE), "a mature widened Rift must open")
	TEST_ASSERT_EQUAL(rift.current_stage, SUCCUBUS_RIFT_STAGE_OPEN, "the third transition must enter the open stage")
	TEST_ASSERT_EQUAL(rift.max_integrity, SUCCUBUS_RIFT_OPEN_INTEGRITY, "the open Rift must use open integrity")
	TEST_ASSERT_EQUAL(rift.next_stage_at, 0, "the open Rift must have no further maturation deadline")
	TEST_ASSERT_EQUAL(rift.get_next_channel_time(), 0, "the open Rift must expose no further channel")
	TEST_ASSERT(!rift.advance_stage(ignore_maturation = TRUE), "the open Rift must reject further advancement")

	qdel(rift)
	TEST_ASSERT(!(rift in GLOB.active_succubus_rifts), "Rift deletion must clear the global registry")
	TEST_ASSERT_NULL(antag.get_active_rift(), "Rift deletion must clear the owner's weak link")
	TEST_ASSERT_EQUAL(antag.rift_retry_at, 0, "plain cleanup must not apply a collapse retry penalty")

	body.mind.antag_datums -= antag
	antag.owner = null

/datum/unit_test/succubus_rift_exclusivity_and_collapse/Run()
	var/datum/antagonist/succubus/first_antag = allocate(/datum/antagonist/succubus)
	var/mob/living/carbon/human/first_body = allocate(/mob/living/carbon/human)
	first_body.mind_initialize()
	first_antag.owner = first_body.mind
	LAZYADD(first_body.mind.antag_datums, first_antag)

	var/datum/antagonist/succubus/second_antag = allocate(/datum/antagonist/succubus)
	var/mob/living/carbon/human/second_body = allocate(/mob/living/carbon/human)
	second_body.mind_initialize()
	second_antag.owner = second_body.mind
	LAZYADD(second_body.mind.antag_datums, second_antag)

	var/obj/structure/succubus_rift/first_rift = allocate(/obj/structure/succubus_rift)
	var/obj/structure/succubus_rift/same_owner_rift = allocate(/obj/structure/succubus_rift)
	var/obj/structure/succubus_rift/other_owner_rift = allocate(/obj/structure/succubus_rift)
	TEST_ASSERT(first_rift.bind_to(first_antag), "the first Rift must bind")
	TEST_ASSERT(!same_owner_rift.bind_to(first_antag), "one Succubus must not bind a second Rift")
	TEST_ASSERT(!other_owner_rift.bind_to(second_antag), "a second Succubus must not bypass the one-Rift world cap")

	TEST_ASSERT(first_rift.collapse(), "gameplay collapse must resolve once")
	TEST_ASSERT(first_antag.rift_retry_at > world.time, "gameplay collapse must apply the retry lockout")
	TEST_ASSERT_NULL(first_antag.get_active_rift(), "gameplay collapse must clear owner state")
	TEST_ASSERT(!length(GLOB.active_succubus_rifts), "gameplay collapse must release the global Rift cap")

	first_antag.rift_retry_at = 0
	var/obj/structure/succubus_rift/admin_rift = allocate(/obj/structure/succubus_rift)
	TEST_ASSERT(admin_rift.bind_to(first_antag), "a cleaned world must accept a replacement debug Rift")
	TEST_ASSERT(admin_rift.collapse(apply_retry = FALSE), "administrative collapse must resolve")
	TEST_ASSERT_EQUAL(first_antag.rift_retry_at, 0, "administrative collapse must not apply a retry lockout")
	TEST_ASSERT(!length(GLOB.active_succubus_rifts), "administrative collapse must release the global Rift cap")

	qdel(same_owner_rift)
	qdel(other_owner_rift)
	first_body.mind.antag_datums -= first_antag
	first_antag.owner = null
	second_body.mind.antag_datums -= second_antag
	second_antag.owner = null

/datum/unit_test/succubus_rift_incursion_lifecycle/Run()
	var/datum/antagonist/succubus/antag = allocate(/datum/antagonist/succubus)
	var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	body.mind_initialize()
	antag.owner = body.mind
	LAZYADD(body.mind.antag_datums, antag)

	var/obj/structure/succubus_rift/rift = allocate(/obj/structure/succubus_rift, run_loc_floor_bottom_left)
	TEST_ASSERT(rift.bind_to(antag), "the incursion test Rift must bind to its Succubus")

	rift.configure_incursion_limits(1)
	TEST_ASSERT_EQUAL(rift.active_demon_cap, SUCCUBUS_RIFT_MIN_ACTIVE_DEMONS, "a low-population incursion must retain the minimum active pressure")
	TEST_ASSERT_EQUAL(rift.total_demon_cap, SUCCUBUS_RIFT_MIN_TOTAL_DEMONS, "a low-population incursion must retain the minimum total pressure")

	rift.configure_incursion_limits(13)
	TEST_ASSERT_EQUAL(rift.active_demon_cap, 3, "thirteen players must scale the active cap to three")
	TEST_ASSERT_EQUAL(rift.total_demon_cap, 11, "an active cap of three must scale the total cap to eleven")

	rift.configure_incursion_limits(40)
	TEST_ASSERT_EQUAL(rift.active_demon_cap, SUCCUBUS_RIFT_MAX_ACTIVE_DEMONS, "a large population must clamp at the maximum active cap")
	TEST_ASSERT_EQUAL(rift.total_demon_cap, SUCCUBUS_RIFT_MAX_TOTAL_DEMONS, "a large population must clamp at the maximum total cap")

	rift.current_stage = SUCCUBUS_RIFT_STAGE_OPEN
	TEST_ASSERT(rift.start_incursion(), "an Open Rift must start its bounded incursion")
	TEST_ASSERT(rift.incursion_active, "starting the incursion must set its active state")
	TEST_ASSERT(rift.incursion_wave_timer != TIMER_ID_NULL, "starting the incursion must own a stoppable wave timer")
	TEST_ASSERT(rift.incursion_end_timer != TIMER_ID_NULL, "starting the incursion must own a stoppable resolution timer")
	TEST_ASSERT_EQUAL(length(rift.incursion_demons), SUCCUBUS_RIFT_WAVE_SIZE, "starting the incursion must spawn its immediate wave")
	TEST_ASSERT_EQUAL(rift.total_demons_spawned, SUCCUBUS_RIFT_WAVE_SIZE, "the immediate wave must count against the total cap")
	for(var/mob/living/owned_demon as anything in rift.incursion_demons)
		TEST_ASSERT(owned_demon.ai_targeting_ally_check(body), "every Rift demon must recognize the owning Succubus as an ally")

	var/mob/living/first_demon = rift.incursion_demons[1]
	qdel(first_demon)
	TEST_ASSERT(!(first_demon in rift.incursion_demons), "a deleted Rift demon must release its active registry entry")

	var/list/remaining_demons = rift.incursion_demons.Copy()
	TEST_ASSERT(rift.end_incursion(show_message = FALSE), "an active incursion must end exactly once")
	TEST_ASSERT(!rift.incursion_active, "ending the incursion must clear its active state")
	TEST_ASSERT_EQUAL(rift.incursion_wave_timer, TIMER_ID_NULL, "ending the incursion must cancel the wave timer")
	TEST_ASSERT_EQUAL(rift.incursion_end_timer, TIMER_ID_NULL, "ending the incursion must cancel the resolution timer")
	TEST_ASSERT(!length(rift.incursion_demons), "ending the incursion must release the demon registry")
	for(var/mob/living/remaining_demon as anything in remaining_demons)
		TEST_ASSERT(QDELETED(remaining_demon), "ending the incursion must delete every surviving owned demon")

	qdel(rift)
	body.mind.antag_datums -= antag
	antag.owner = null

/datum/unit_test/succubus_rift_sealing_and_failure/Run()
	var/datum/antagonist/succubus/antag = allocate(/datum/antagonist/succubus)
	var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	body.mind_initialize()
	antag.owner = body.mind
	antag.contracts_completed_full = 3
	antag.essence_cap = SUCCUBUS_ESSENCE_CAP_TIER_4
	antag.essence = SUCCUBUS_ESSENCE_CAP_TIER_4
	antag.contract_pool = allocate(/datum/contract_pool/succubus)
	antag.contract_created_at = world.time
	var/datum/antag_contract/interrupted_contract = allocate(/datum/antag_contract)
	interrupted_contract.completed_early = TRUE
	antag.current_contract = interrupted_contract
	LAZYADD(body.mind.antag_datums, antag)
	var/datum/objective/succubus/rift/rift_objective = antag.forge_succubus_objectives()

	var/obj/structure/succubus_rift/rift = allocate(/obj/structure/succubus_rift, run_loc_floor_bottom_left)
	TEST_ASSERT(rift.bind_to(antag), "the sealing test Rift must bind to its Succubus")
	rift.current_stage = SUCCUBUS_RIFT_STAGE_OPEN
	var/mob/living/carbon/human/sealer = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	sealer.mind_initialize()

	antag.true_form_active = TRUE
	TEST_ASSERT(!antag.can_leave_true_form(silent = TRUE), "an Open Rift must tether its Succubus to True Form")
	antag.true_form_active = FALSE
	TEST_ASSERT(!rift.can_seal_rift(body, silent = TRUE), "the Rift owner must not contribute to sealing her own breach")
	TEST_ASSERT(rift.can_seal_rift(sealer, silent = TRUE), "an adjacent conscious outsider must be able to seal the Rift")

	TEST_ASSERT(rift.add_seal_progress(1, sealer), "the first universal sealing contribution must be accepted")
	TEST_ASSERT_EQUAL(rift.seal_progress, 1, "one contribution must advance the closure counter once")
	TEST_ASSERT(rift.add_seal_progress(1, sealer), "the second universal sealing contribution must be accepted")
	TEST_ASSERT(!QDELETED(rift), "the Rift must survive until the final sealing contribution")
	TEST_ASSERT(rift.add_seal_progress(1, sealer), "the final universal sealing contribution must resolve the Rift")

	TEST_ASSERT(QDELETED(rift), "the final sealing contribution must delete the resolved Rift")
	TEST_ASSERT(!antag.rift_banished, "closure must not banish a Succubus who defaults to survival")
	TEST_ASSERT(antag.rift_repelled, "closure must record a retryable campaign defeat")
	TEST_ASSERT(!antag.rift_ascended, "closure must not complete the ascension objective")
	TEST_ASSERT(!rift_objective.check_completion(), "a sealed Rift must fail its campaign objective")
	TEST_ASSERT_NULL(antag.get_active_rift(), "closure must clear the owner's active Rift link")
	TEST_ASSERT(!length(GLOB.active_succubus_rifts), "closure must release the world Rift cap")
	TEST_ASSERT(isturf(body.loc), "default survival must leave the mortal shell in active play")
	TEST_ASSERT_EQUAL(antag.get_succubus_contract_tier(), 1, "closure must reset infernal favor to Tier 1")
	TEST_ASSERT_EQUAL(antag.essence, 0, "closure must drain all stored essence")
	TEST_ASSERT_EQUAL(antag.essence_cap, SUCCUBUS_ESSENCE_CAP_BASE, "closure must restore the Tier 1 essence cap")
	TEST_ASSERT_EQUAL(antag.contract_history[1], interrupted_contract, "closure must preserve the interrupted contract in round-end history")
	TEST_ASSERT_EQUAL(interrupted_contract.grade, CONTRACT_GRADE_EXCUSED, "closure must excuse rather than fail the interrupted patron contract")
	TEST_ASSERT(!interrupted_contract.completed_early, "closure must prevent old early completion from raising the replacement contract's tier ceiling")
	TEST_ASSERT_NOTNULL(antag.current_contract, "default survival must issue a fresh patron contract")
	TEST_ASSERT_EQUAL(antag.current_contract.tier_ceiling, 1, "the replacement contract must roll at Tier 1")
	TEST_ASSERT_EQUAL(antag.current_contract.deadline, world.time + antag.contract_pool.cycle_length, "the replacement contract must receive one full fresh cycle")
	TEST_ASSERT(body.mind.has_antag_datum(/datum/antagonist/succubus) == antag, "survival must retain the Succubus datum for continued play and round-end reporting")

	body.mind.antag_datums -= antag
	antag.owner = null

/datum/unit_test/succubus_rift_ascension_and_retinue_cleanup/Run()
	var/datum/antagonist/succubus/antag = allocate(/datum/antagonist/succubus)
	var/mob/living/carbon/human/mortal_body = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	mortal_body.mind_initialize()
	var/datum/mind/succubus_mind = mortal_body.mind
	antag.owner = succubus_mind
	antag.contracts_completed_full = 3
	antag.essence_cap = SUCCUBUS_ESSENCE_CAP_TIER_4
	antag.essence = SUCCUBUS_ESSENCE_CAP_TIER_4
	LAZYADD(succubus_mind.antag_datums, antag)
	var/datum/objective/succubus/rift/rift_objective = antag.forge_succubus_objectives()

	var/mob/living/carbon/human/thrall = allocate(/mob/living/carbon/human)
	thrall.mind_initialize()
	var/datum/team/succubus_harem/harem = antag.ensure_harem()
	var/datum/antagonist/succubus_thrall/thrall_datum = allocate(/datum/antagonist/succubus_thrall)
	thrall_datum.owner = thrall.mind
	thrall_datum.mistress_mind = succubus_mind
	thrall_datum.harem = harem
	harem.add_member(thrall.mind)
	LAZYADD(thrall.mind.antag_datums, thrall_datum)

	var/mob/living/simple_animal/hostile/retaliate/infernal/imp/succubus/imp = allocate(/mob/living/simple_animal/hostile/retaliate/infernal/imp/succubus)
	imp.mind_initialize()
	var/datum/antagonist/succubus_imp/imp_datum = allocate(/datum/antagonist/succubus_imp)
	imp_datum.owner = imp.mind
	imp_datum.mistress_mind = succubus_mind
	LAZYADD(imp.mind.antag_datums, imp_datum)
	antag.summoned_imp_minds += imp.mind

	var/mob/living/simple_animal/hostile/retaliate/wolf/companion/lustbound/hound = allocate(/mob/living/simple_animal/hostile/retaliate/wolf/companion/lustbound, run_loc_floor_bottom_left)
	TEST_ASSERT(hound.bind_to(antag), "the verdict test hound must bind to its Succubus")
	var/obj/structure/succubus_infernal_snare/snare = allocate(/obj/structure/succubus_infernal_snare, run_loc_floor_bottom_left)
	TEST_ASSERT(snare.bind_to(antag), "the verdict test snare must bind to its Succubus")

	TEST_ASSERT(antag.assume_true_form(), "the verdict test must enter a real True Form before opening the Rift")
	var/mob/living/form_body = succubus_mind.current
	TEST_ASSERT(form_body != mortal_body, "entering True Form must transfer the mind into the spawned form")

	var/obj/structure/succubus_rift/rift = allocate(/obj/structure/succubus_rift, run_loc_floor_bottom_left)
	TEST_ASSERT(rift.bind_to(antag), "the ascension test Rift must bind to its Succubus")
	rift.current_stage = SUCCUBUS_RIFT_STAGE_OPEN
	TEST_ASSERT(rift.resolve_verdict(ascended = TRUE), "surviving the trial must resolve the Rift as an ascension")

	TEST_ASSERT(QDELETED(rift), "ascension must delete the resolved Rift")
	TEST_ASSERT(antag.rift_ascended, "ascension must persist its campaign success flag")
	TEST_ASSERT(!antag.rift_banished, "ascension must not record a banishment")
	TEST_ASSERT(rift_objective.check_completion(), "ascension must complete the campaign objective")
	TEST_ASSERT_EQUAL(succubus_mind.current, mortal_body, "ascension must safely re-home the mind in the restored mortal shell")
	TEST_ASSERT(!antag.true_form_active, "ascension must clear the True Form state")
	TEST_ASSERT(!isturf(mortal_body.loc), "ascension must retire the restored shell from active play")
	TEST_ASSERT(succubus_mind.has_antag_datum(/datum/antagonist/succubus) == antag, "ascension must retain the Succubus datum for round-end reporting")
	TEST_ASSERT_NULL(thrall.mind.has_antag_datum(/datum/antagonist/succubus_thrall), "the verdict must release consenting thralls")
	TEST_ASSERT_EQUAL(imp.mind.has_antag_datum(/datum/antagonist/succubus_imp), imp_datum, "the verdict must not delete the player-controlled Imp role")
	TEST_ASSERT_NULL(imp_datum.mistress_mind, "the verdict must detach the player Imp from its summoner")
	TEST_ASSERT(QDELETED(hound), "the verdict must delete the Succubus's NPC hound")
	TEST_ASSERT(QDELETED(snare), "the verdict must delete the Succubus's infernal snares")
	TEST_ASSERT(!length(antag.summoned_lusthounds), "the verdict must clear the hound ownership list")
	TEST_ASSERT(!length(antag.infernal_snares), "the verdict must clear the snare ownership list")

	imp.mind.antag_datums -= imp_datum
	imp_datum.owner = null
	succubus_mind.antag_datums -= antag
	antag.owner = null
	qdel(harem)
	antag.harem = null
