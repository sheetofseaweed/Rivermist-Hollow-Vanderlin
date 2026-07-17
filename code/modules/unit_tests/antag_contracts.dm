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

/datum/unit_test/contract_boundary_math/Run()
	var/datum/antagonist/antag = allocate(/datum/antagonist)
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
	var/datum/antag_contract/first_contract = antag.contract_history[1]
	TEST_ASSERT_EQUAL(first_contract.grade, CONTRACT_GRADE_FAIL, "unprogressed contract must grade FAIL")

	// Anti-repeat across the reroll: cycle 2's pool excluded cycle 1's only template
	TEST_ASSERT_EQUAL(length(antag.current_contract.goals), 0, "single-template pool must yield an empty contract on the following cycle (anti-repeat)")

	antag.teardown_contracts()

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
