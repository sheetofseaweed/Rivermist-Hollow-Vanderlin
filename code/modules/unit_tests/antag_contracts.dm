// Test-only goal templates
/datum/contract_goal/test_counter
	name = "test counter"
	description_template = "Count to %TARGET%."
	target_minimum = 2
	target_maximum = 2
	tier = 1

/datum/contract_goal/test_counter_t3
	name = "test counter t3"
	description_template = "High-tier count to %TARGET%."
	target_minimum = 1
	target_maximum = 1
	tier = 3

/datum/contract_goal/test_state
	name = "test state"
	description_template = "Hold %TARGET% things."
	goal_type = CONTRACT_GOAL_STATE
	target_minimum = 1
	target_maximum = 1
	var/fake_progress = 0

/datum/contract_goal/test_state/get_state_progress()
	return fake_progress

/datum/antagonist/test_contract_cycle_hook
	var/cycles_closed = 0

/datum/antagonist/test_contract_cycle_hook/on_contract_cycle_closed(datum/antag_contract/contract)
	. = ..()
	cycles_closed++

/datum/unit_test/contract_pool_rolling/Run()
	var/datum/antagonist/antag = allocate(/datum/antagonist)
	var/datum/contract_pool/pool = allocate(/datum/contract_pool)
	pool.goal_templates = list(/datum/contract_goal/test_counter, /datum/contract_goal/test_counter_t3)
	pool.goals_per_contract_min = 2
	pool.goals_per_contract_max = 2

	// Tier ceiling filters
	var/list/goals = pool.roll_goals(antag, 1, list())
	TEST_ASSERT_EQUAL(length(goals), 1, "tier ceiling 1 must exclude the tier-3 template even when 2 goals were requested")
	TEST_ASSERT(istype(goals[1], /datum/contract_goal/test_counter), "the rolled goal must be the tier-1 template")
	for(var/datum/contract_goal/goal as anything in goals)
		qdel(goal)

	// Anti-repeat exclusion
	var/list/goals2 = pool.roll_goals(antag, 5, list(/datum/contract_goal/test_counter))
	TEST_ASSERT_EQUAL(length(goals2), 1, "excluded template must not roll")
	TEST_ASSERT(istype(goals2[1], /datum/contract_goal/test_counter_t3), "only the non-excluded template may roll")
	for(var/datum/contract_goal/goal as anything in goals2)
		qdel(goal)

	// Dry pool
	var/list/goals3 = pool.roll_goals(antag, 5, list(/datum/contract_goal/test_counter, /datum/contract_goal/test_counter_t3))
	TEST_ASSERT_EQUAL(length(goals3), 0, "fully excluded pool must roll an empty (auto-EXCUSED) contract")

/datum/unit_test/contract_grading/Run()
	var/datum/antag_contract/contract = allocate(/datum/antag_contract)
	TEST_ASSERT_EQUAL(contract.compute_grade(3 HOURS), CONTRACT_GRADE_EXCUSED, "an empty contract must grade EXCUSED")

	var/datum/contract_goal/test_counter/goal_a = new(null)
	var/datum/contract_goal/test_counter/goal_b = new(null)
	contract.goals = list(goal_a, goal_b)
	TEST_ASSERT_EQUAL(contract.compute_grade(3 HOURS), CONTRACT_GRADE_FAIL, "no completed goals must grade FAIL")

	goal_a.add_progress(2)
	TEST_ASSERT(goal_a.completed, "counter goal must complete at target")
	TEST_ASSERT_EQUAL(contract.compute_grade(3 HOURS), CONTRACT_GRADE_PARTIAL, "one of two completed must grade PARTIAL")

	goal_b.add_progress(2)
	TEST_ASSERT_EQUAL(contract.compute_grade(3 HOURS), CONTRACT_GRADE_FULL, "all completed must grade FULL")

	contract.offline_deciseconds = (3 HOURS) * 0.6
	TEST_ASSERT_EQUAL(contract.compute_grade(3 HOURS), CONTRACT_GRADE_EXCUSED, "offline beyond the threshold must grade EXCUSED even when complete")

/datum/unit_test/contract_goal_idempotency/Run()
	var/datum/contract_goal/test_counter/goal = allocate(/datum/contract_goal/test_counter, null)
	goal.add_progress(2)
	TEST_ASSERT(goal.completed, "goal must complete at target")
	TEST_ASSERT_EQUAL(goal.progress, 2, "progress must clamp at target")
	goal.add_progress(5)
	TEST_ASSERT_EQUAL(goal.progress, 2, "progress must not accumulate after completion")

/datum/unit_test/contract_state_goal/Run()
	var/datum/contract_goal/test_state/goal = allocate(/datum/contract_goal/test_state, null)
	goal.add_progress(5)
	TEST_ASSERT(!goal.completed, "STATE goals must ignore add_progress")
	goal.fake_progress = 1
	goal.evaluate()
	TEST_ASSERT(goal.completed, "STATE goal must complete when evaluated at/above target")

/datum/unit_test/shared_bandit_contract_party/Run()
	var/datum/team/bandits/team = allocate(/datum/team/bandits)
	team.contract_party.contract_pool.goal_templates = list(/datum/contract_goal/test_counter)
	team.contract_party.contract_pool.goals_per_contract_min = 1
	team.contract_party.contract_pool.goals_per_contract_max = 1

	var/mob/living/carbon/human/first_body = allocate(/mob/living/carbon/human)
	first_body.mind_initialize()
	var/datum/antagonist/bandit/first_bandit = allocate(/datum/antagonist/bandit)
	first_bandit.owner = first_body.mind
	first_bandit.bandit_team = team
	team.add_member(first_body.mind)
	LAZYADD(first_body.mind.antag_datums, first_bandit)
	first_bandit.setup_contracts()

	var/mob/living/carbon/human/second_body = allocate(/mob/living/carbon/human)
	second_body.mind_initialize()
	var/datum/antagonist/bandit/second_bandit = allocate(/datum/antagonist/bandit)
	second_bandit.owner = second_body.mind
	second_bandit.bandit_team = team
	team.add_member(second_body.mind)
	LAZYADD(second_body.mind.antag_datums, second_bandit)
	second_bandit.setup_contracts()

	TEST_ASSERT_EQUAL(first_bandit.contract_party, team.contract_party, "the first bandit must use the team-owned contract party")
	TEST_ASSERT_EQUAL(second_bandit.contract_party, team.contract_party, "every bandit must join the same contract party")
	TEST_ASSERT_EQUAL(first_bandit.current_contract, second_bandit.current_contract, "bandit contract mirrors must point at one shared contract")
	TEST_ASSERT_EQUAL(length(team.contract_party.antags), 2, "the shared party must register both bandit antagonist datums")

	second_bandit.record_contract_progress(/datum/contract_goal/test_counter, 2)
	var/datum/contract_goal/test_counter/shared_goal = first_bandit.current_contract.goals[1]
	TEST_ASSERT(shared_goal.completed, "progress from a second bandit must complete the first bandit's visible shared goal")
	TEST_ASSERT(first_bandit.current_contract.completed_early, "shared completion must use the party's early-completion state")

	first_bandit.teardown_contracts()
	TEST_ASSERT_EQUAL(second_bandit.contract_party, team.contract_party, "removing one bandit must not destroy the team's contract party")
	TEST_ASSERT_EQUAL(shared_goal.antag, second_bandit, "shared goals must hand their antagonist hook to a remaining bandit")

	second_bandit.teardown_contracts()
	TEST_ASSERT_NULL(shared_goal.antag, "a shared party with no remaining antagonist must release its goal hook reference")
	TEST_ASSERT(!QDELETED(team.contract_party), "the team must retain its contract history after its last active bandit is removed")
	team.remove_member(first_body.mind)
	team.remove_member(second_body.mind)
	first_body.mind.antag_datums -= first_bandit
	second_body.mind.antag_datums -= second_bandit
	first_bandit.owner = null
	second_bandit.owner = null

/datum/unit_test/contract_boundary_math/Run()
	var/datum/antagonist/test_contract_cycle_hook/antag = allocate(/datum/antagonist/test_contract_cycle_hook)
	var/mob/living/carbon/human/contract_owner = allocate(/mob/living/carbon/human)
	contract_owner.mind_initialize()
	antag.owner = contract_owner.mind
	LAZYADD(contract_owner.mind.antag_datums, antag)
	antag.contract_pool = new /datum/contract_pool
	antag.contract_pool.goal_templates = list(/datum/contract_goal/test_counter)
	antag.contract_pool.goals_per_contract_min = 1
	antag.contract_pool.goals_per_contract_max = 1
	antag.contract_created_at = world.time

	antag.issue_next_contract()
	var/cycle_length = antag.contract_pool.cycle_length
	TEST_ASSERT_NOTNULL(antag.current_contract, "cycle 1 must issue")
	TEST_ASSERT_EQUAL(antag.current_contract.deadline, antag.contract_created_at + cycle_length, "cycle 1 deadline must sit on the first fixed boundary")

	antag.close_contract_cycle() // grades FAIL (no progress), issues cycle 2
	TEST_ASSERT_EQUAL(antag.current_contract.cycle_number, 2, "closing must issue the next cycle")
	TEST_ASSERT_EQUAL(antag.current_contract.deadline, antag.contract_created_at + 2 * cycle_length, "cycle 2 deadline must sit on the second fixed boundary, no drift")
	TEST_ASSERT_EQUAL(length(antag.contract_history), 1, "closed contract must be archived")
	TEST_ASSERT_EQUAL(antag.cycles_closed, 1, "the all-grade cycle-close hook must fire exactly once")
	var/datum/antag_contract/first_contract = antag.contract_history[1]
	TEST_ASSERT_EQUAL(first_contract.grade, CONTRACT_GRADE_FAIL, "unprogressed contract must grade FAIL")

	// Anti-repeat across the reroll: cycle 2's pool excluded cycle 1's only template
	TEST_ASSERT_EQUAL(length(antag.current_contract.goals), 0, "single-template pool must yield an empty contract on the following cycle (anti-repeat)")

	var/mob/dead/observer/admin = allocate(/mob/dead/observer)
	antag.current_contract.completed_early = TRUE
	antag.admin_reroll_contract(admin)
	TEST_ASSERT(!antag.contract_history[2].completed_early, "an administrative reroll must clear the discarded contract's early-completion reward")
	TEST_ASSERT_EQUAL(antag.current_contract.tier_ceiling, 1, "a reroll must not grant the replacement contract a free tier-ceiling bump")
	TEST_ASSERT_EQUAL(antag.current_contract.deadline, world.time + cycle_length, "a reroll must give the replacement contract exactly one fresh cycle")

	antag.admin_warp_cycle(admin)
	TEST_ASSERT_EQUAL(antag.current_contract.deadline, world.time + cycle_length, "an administrative deadline warp must give the replacement contract exactly one fresh cycle")

	antag.teardown_contracts()
	contract_owner.mind.antag_datums -= antag
	antag.owner = null

/datum/unit_test/werewolf_contract_feedthrough/Run()
	var/datum/antagonist/werewolf/antag = allocate(/datum/antagonist/werewolf)
	antag.contract_pool = new /datum/contract_pool/werewolf

	var/datum/antag_contract/contract = new
	contract.deadline = world.time + 1 HOURS // early-completion flag requires a live (future) deadline
	var/datum/contract_goal/werewolf/hunt_score/goal = new(antag)
	goal.target_amount = 50
	contract.goals = list(goal)
	antag.current_contract = contract

	antag.add_contract_objective_score(30)
	TEST_ASSERT_EQUAL(goal.progress, 30, "moon-hunt score must feed the contract goal")
	TEST_ASSERT_EQUAL(antag.contract_objective_score, 30, "campaign score must still accumulate from the same call")
	TEST_ASSERT(!goal.completed, "goal must not complete below target")

	antag.add_contract_objective_score(30)
	TEST_ASSERT(goal.completed, "goal must complete when fed to target")
	TEST_ASSERT_EQUAL(antag.contract_objective_score, 60, "campaign score must be unaffected by goal completion")
	TEST_ASSERT(contract.completed_early, "single-goal contract must flag early completion")

	antag.teardown_contracts()

#ifdef FOCUS_ANTAG_CONTRACTS_TEST
TEST_FOCUS(/datum/unit_test/contract_boundary_math)
TEST_FOCUS(/datum/unit_test/contract_goal_idempotency)
TEST_FOCUS(/datum/unit_test/contract_grading)
TEST_FOCUS(/datum/unit_test/contract_pool_rolling)
TEST_FOCUS(/datum/unit_test/contract_state_goal)
TEST_FOCUS(/datum/unit_test/shared_bandit_contract_party)
TEST_FOCUS(/datum/unit_test/werewolf_contract_feedthrough)
#endif
