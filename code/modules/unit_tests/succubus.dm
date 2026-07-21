// Succubus antagonist core — unit tests (Task 7)
// See docs/superpowers/plans/2026-07-17-succubus-core.md

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
	TEST_ASSERT(first > 0, "first harvest must yield essence")
	antag.harvest_from_climax(partner)
	antag.last_harvest_time = -1
	var/second = antag.essence - first
	TEST_ASSERT(second < first, "repeat harvest must decay")
	TEST_ASSERT_EQUAL(antag.partner_harvests[partner.mind], 2, "harvest count must track per partner")

	// floor: 10 more harvests never go below floor fraction
	for(var/i in 1 to 10)
		antag.harvest_from_climax(partner)
		antag.last_harvest_time = -1
	var/datum/component/arousal/comp = partner.GetComponent(/datum/component/arousal)
	var/arousal_mult = comp ? 1 + comp.arousal / 200 : 1
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
	TEST_ASSERT(first_gain > 0, "absorbing tagged fluid must yield essence")

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

	antag.essence = 0
	TEST_ASSERT(!antag.can_assume_true_form(TRUE), "true form must be essence-gated")
	antag.essence = SUCCUBUS_COST_TRUE_FORM
	TEST_ASSERT(antag.can_assume_true_form(TRUE), "sufficient essence must open the gate")
	antag.true_form_active = TRUE
	TEST_ASSERT(!antag.can_assume_true_form(TRUE), "cannot assume while already assumed")
	antag.true_form_active = FALSE
	antag.owner = null // hand-set; detach before harness qdel
