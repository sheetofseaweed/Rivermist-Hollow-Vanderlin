/datum/antagonist/proc/add_contract_admin_commands(list/commands)
	if(!contract_party && !contract_pool)
		return
	commands["Contract: Advance Progression Tier"] = CALLBACK(src, PROC_REF(admin_advance_contract_tier))
	commands["Contract: View"] = CALLBACK(src, PROC_REF(admin_view_contract))
	commands["Contract: Reroll"] = CALLBACK(src, PROC_REF(admin_reroll_contract))
	commands["Contract: Force Full Completion"] = CALLBACK(src, PROC_REF(admin_force_full_contract))
	commands["Contract: Warp To Deadline"] = CALLBACK(src, PROC_REF(admin_warp_cycle))
	commands["Contract: Extend Deadline"] = CALLBACK(src, PROC_REF(admin_extend_deadline))

/datum/antagonist/proc/admin_advance_contract_tier(mob/admin)
	var/datum/contract_party/party = get_or_create_contract_party()
	var/current_tier = min(party.contracts_completed_full + 1, party.contract_pool.max_tier)
	if(current_tier >= party.contract_pool.max_tier)
		to_chat(admin, span_notice("[key_name_admin(owner)] is already at the maximum contract progression tier ([current_tier])."))
		return
	party.contracts_completed_full++
	party.sync_to_antags()
	for(var/datum/antagonist/party_antag as anything in party.antags)
		party_antag.on_contract_completed(null)
	var/new_tier = min(party.contracts_completed_full + 1, party.contract_pool.max_tier)
	to_chat(admin, span_notice("Advanced [key_name_admin(owner)] to contract progression tier [new_tier]. Their active contract was not changed."))
	message_admins("[key_name_admin(admin)] advanced [key_name_admin(owner)] to contract progression tier [new_tier].")

/datum/antagonist/proc/admin_view_contract(mob/admin)
	var/datum/contract_party/party = get_or_create_contract_party()
	if(!party.current_contract)
		to_chat(admin, span_notice("No active contract."))
		return
	var/minutes_left = round((party.current_contract.deadline - world.time) / (1 MINUTES))
	to_chat(admin, span_notice("Cycle [party.current_contract.cycle_number] (tier [party.current_contract.tier_ceiling]), deadline in [minutes_left] min, offline [round(party.current_contract.offline_deciseconds / (1 MINUTES))] min:"))
	for(var/datum/contract_goal/goal as anything in party.current_contract.goals)
		to_chat(admin, span_notice("- [goal.get_description()][goal.completed ? " (done)" : ""]"))

/datum/antagonist/proc/admin_reroll_contract(mob/admin)
	var/datum/contract_party/party = get_or_create_contract_party()
	if(party.current_contract)
		party.current_contract.grade = CONTRACT_GRADE_EXCUSED
		party.current_contract.completed_early = FALSE
		party.contract_history += party.current_contract
		party.current_contract = null
		party.reanchor_contract_clock()
	party.issue_next_contract()
	message_admins("[key_name_admin(admin)] rerolled [key_name_admin(owner)]'s contract.")

/datum/antagonist/proc/admin_force_full_contract(mob/admin)
	var/datum/contract_party/party = get_or_create_contract_party()
	var/datum/antag_contract/contract = party.current_contract
	if(!contract || !length(contract.goals))
		to_chat(admin, span_notice("No active contract goals to complete."))
		return
	// Complete at the boundary so the test tool does not grant an early-completion bump.
	contract.deadline = world.time
	for(var/datum/contract_goal/goal as anything in contract.goals)
		if(goal.completed)
			continue
		goal.progress = goal.target_amount
		goal.complete()
	party.close_contract_cycle(reanchor_clock = TRUE)
	message_admins("[key_name_admin(admin)] forced full completion of [key_name_admin(owner)]'s contract cycle.")

/datum/antagonist/proc/admin_warp_cycle(mob/admin)
	var/datum/contract_party/party = get_or_create_contract_party()
	if(!party.current_contract)
		return
	party.current_contract.deadline = world.time
	party.close_contract_cycle(reanchor_clock = TRUE)
	message_admins("[key_name_admin(admin)] warped [key_name_admin(owner)]'s contract cycle to its deadline.")

/datum/antagonist/proc/admin_extend_deadline(mob/admin)
	var/datum/contract_party/party = get_or_create_contract_party()
	if(!party.current_contract)
		return
	var/minutes = input(admin, "Extend deadline by how many minutes?", "Extend Deadline", 30) as null|num
	if(isnull(minutes) || minutes <= 0 || !party.current_contract)
		return
	party.current_contract.deadline += minutes MINUTES
	party.sync_to_antags()
	message_admins("[key_name_admin(admin)] extended [key_name_admin(owner)]'s contract deadline by [minutes] minutes.")

/mob/living/proc/review_patron_contract()
	set name = "Review Contract"
	set category = "IC"
	if(!mind)
		return
	var/found = FALSE
	var/list/seen_parties = list()
	for(var/datum/antagonist/antag as anything in mind.antag_datums)
		var/datum/contract_party/party = antag.contract_party
		if(!party || (party in seen_parties))
			continue
		seen_parties += party
		found = TRUE
		var/datum/antag_contract/contract = party.current_contract
		if(!contract)
			to_chat(src, span_notice("[party.contract_pool.patron_name] has no demands of me right now."))
			continue
		var/minutes_left = round((contract.deadline - world.time) / (1 MINUTES))
		to_chat(src, span_notice("<b>[party.contract_pool.patron_name]'s demands</b> ([minutes_left] min remain):"))
		for(var/datum/contract_goal/goal as anything in contract.goals)
			to_chat(src, span_notice("- [goal.get_description()][goal.completed ? " (done)" : ""]"))
	if(!found)
		to_chat(src, span_notice("No patron makes demands of me."))
