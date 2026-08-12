// Contract framework state, added to every antagonist via type reopening.
// Antags opt in by setting contract_pool_type; everything is inert otherwise.
/datum/antagonist
	var/contract_pool_type
	var/datum/contract_pool/contract_pool
	var/datum/antag_contract/current_contract
	var/list/datum/antag_contract/contract_history = list()
	var/contracts_completed_full = 0
	var/contract_created_at = 0

/datum/antagonist/proc/setup_contracts()
	if(!contract_pool_type || contract_pool)
		return
	contract_pool = new contract_pool_type
	contract_created_at = world.time
	RegisterSignal(owner, COMSIG_MIND_TRANSFERRED, PROC_REF(on_contract_mind_transfer))
	if(owner?.current && !(/mob/living/proc/review_patron_contract in owner.current.verbs))
		add_verb(owner.current, /mob/living/proc/review_patron_contract)
	SScontracts.register(src)
	issue_next_contract()

/datum/antagonist/proc/teardown_contracts()
	if(!contract_pool)
		return
	UnregisterSignal(owner, COMSIG_MIND_TRANSFERRED)
	var/has_other_contract = FALSE
	for(var/datum/antagonist/other_antag as anything in owner?.antag_datums)
		if(other_antag != src && other_antag.contract_pool)
			has_other_contract = TRUE
			break
	if(!has_other_contract && owner?.current)
		remove_verb(owner.current, /mob/living/proc/review_patron_contract)
	SScontracts.deregister(src)
	QDEL_NULL(current_contract)
	QDEL_LIST(contract_history)
	QDEL_NULL(contract_pool)

/datum/antagonist/proc/on_contract_mind_transfer(datum/mind/source, mob/living/old_body)
	SIGNAL_HANDLER
	if(old_body)
		remove_verb(old_body, /mob/living/proc/review_patron_contract)
	if(isliving(source.current) && !(/mob/living/proc/review_patron_contract in source.current.verbs))
		add_verb(source.current, /mob/living/proc/review_patron_contract)

/// Re-anchor the fixed clock after an administrative or campaign reset archives
/// a contract without waiting for its natural three-hour boundary.
/datum/antagonist/proc/reanchor_contract_clock()
	contract_created_at = world.time
	if(contract_pool)
		contract_created_at -= length(contract_history) * contract_pool.cycle_length

/datum/antagonist/proc/issue_next_contract()
	var/cycle = length(contract_history) + 1
	var/tier_ceiling = 1 + contracts_completed_full
	var/datum/antag_contract/previous = length(contract_history) ? contract_history[length(contract_history)] : null
	if(previous?.completed_early)
		tier_ceiling++
	tier_ceiling = min(tier_ceiling, contract_pool.max_tier)

	var/list/exclude = list()
	if(previous)
		for(var/datum/contract_goal/goal as anything in previous.goals)
			exclude += goal.type

	var/datum/antag_contract/contract = new
	contract.cycle_number = cycle
	contract.issued_at = world.time
	contract.tier_ceiling = tier_ceiling
	// Fixed clock: boundaries anchored to contract_created_at; never drift.
	// Re-anchor forward only if a boundary is already in the past (admin warp, server hitch).
	var/next_deadline = contract_created_at + cycle * contract_pool.cycle_length
	while(next_deadline <= world.time)
		next_deadline += contract_pool.cycle_length
	contract.deadline = next_deadline
	contract.goals = contract_pool.roll_goals(src, tier_ceiling, exclude)
	current_contract = contract

	if(owner?.current && length(contract.goals))
		to_chat(owner.current, span_notice("<b>[contract_pool.issue_text]</b>"))
		for(var/datum/contract_goal/goal as anything in contract.goals)
			to_chat(owner.current, span_notice("- [goal.get_description()]"))

/// Routes live progress to matching COUNTER goals on the current contract.
/datum/antagonist/proc/record_contract_progress(goal_type_path, amount = 1)
	if(!current_contract)
		return
	for(var/datum/contract_goal/goal as anything in current_contract.goals)
		if(istype(goal, goal_type_path))
			goal.add_progress(amount)

/// Called by contract_goal.complete(). Opportunistically evaluates STATE goals
/// so mixed contracts can finish early; flags early completion for tier bump.
/datum/antagonist/proc/check_contract_early_completion()
	var/datum/antag_contract/contract = current_contract
	if(!contract || contract.completed_early)
		return
	// Completion at/after the deadline (cycle close, admin warp) is on-time, not early
	if(world.time >= contract.deadline)
		return
	for(var/datum/contract_goal/goal as anything in contract.goals)
		if(!goal.completed && goal.goal_type == CONTRACT_GOAL_STATE)
			goal.evaluate()
	if(!contract.all_goals_completed())
		return
	if(contract.completed_early)
		return
	contract.completed_early = TRUE
	if(owner?.current)
		to_chat(owner.current, span_notice("<b>[contract_pool.patron_name]'s demands are fulfilled early. Its appetite grows...</b>"))

/datum/antagonist/proc/close_contract_cycle(reanchor_clock = FALSE)
	var/datum/antag_contract/contract = current_contract
	if(!contract)
		return
	for(var/datum/contract_goal/goal as anything in contract.goals)
		goal.evaluate()
	contract.grade = contract.compute_grade(contract_pool.cycle_length)
	switch(contract.grade)
		if(CONTRACT_GRADE_FULL)
			contracts_completed_full++
			owner?.adjust_triumphs(contract_pool.contract_bonus_triumphs, TRUE, "contract cycle [contract.cycle_number] fulfilled")
			escalate_contract_omens(contract)
			on_contract_completed(contract)
			notify_contract(contract_pool.success_text)
		if(CONTRACT_GRADE_FAIL)
			on_contract_failed(contract)
			notify_contract(contract_pool.failure_text)
		if(CONTRACT_GRADE_EXCUSED)
			notify_contract(contract_pool.excused_text)
		// PARTIAL: goal triumphs were already paid live; no bonus, no penalty
	on_contract_cycle_closed(contract)
	contract_history += contract
	current_contract = null
	if(reanchor_clock)
		reanchor_contract_clock()
	issue_next_contract()

/// Antag-specific boon hook (ability unlocks etc.) — override per antag
/datum/antagonist/proc/on_contract_completed(datum/antag_contract/contract)
	return

/// Antag-specific penance hook — override per antag
/datum/antagonist/proc/on_contract_failed(datum/antag_contract/contract)
	return

/// Antag-specific all-grade cycle consequence hook (upkeep, recurring costs, etc.)
/datum/antagonist/proc/on_contract_cycle_closed(datum/antag_contract/contract)
	return

/datum/antagonist/proc/notify_contract(text)
	if(owner?.current && text)
		to_chat(owner.current, span_notice(text))

/// Subtle storyteller nudges per user direction: 2.5%·tier omens, 1%·tier intervention.
/// Mirrors /datum/objective/personal/escalate_objective().
/datum/antagonist/proc/escalate_contract_omens(datum/antag_contract/contract)
	var/omen_points = SSgamemode.point_thresholds[EVENT_TRACK_OMENS] * CONTRACT_OMEN_ESCALATION_FRACTION * contract.tier_ceiling
	SSgamemode.event_track_points[EVENT_TRACK_OMENS] += omen_points
	var/intervention_points = SSgamemode.point_thresholds[EVENT_TRACK_INTERVENTION] * CONTRACT_INTERVENTION_ESCALATION_FRACTION * contract.tier_ceiling
	SSgamemode.event_track_points[EVENT_TRACK_INTERVENTION] += intervention_points

/// Roundend contract ledger; null when this antag doesn't use contracts.
/datum/antagonist/proc/contract_roundend_ledger()
	if(!contract_pool)
		return null
	var/list/lines = list("<b>Contracts of [contract_pool.patron_name]:</b>")
	var/list/all_contracts = contract_history.Copy()
	if(current_contract)
		all_contracts += current_contract
	for(var/datum/antag_contract/contract as anything in all_contracts)
		var/list/goal_bits = list()
		for(var/datum/contract_goal/goal as anything in contract.goals)
			goal_bits += "[goal.get_description()][goal.completed ? " (done)" : ""]"
		lines += "Cycle [contract.cycle_number] — [contract.grade || "in progress"]: [goal_bits.Join("; ")]"
	return lines.Join("<br>")
