/datum/antagonist/proc/add_contract_admin_commands(list/commands)
	if(!contract_pool)
		return
	commands["Contract: View"] = CALLBACK(src, PROC_REF(admin_view_contract))
	commands["Contract: Reroll"] = CALLBACK(src, PROC_REF(admin_reroll_contract))
	commands["Contract: Warp To Deadline"] = CALLBACK(src, PROC_REF(admin_warp_cycle))
	commands["Contract: Extend Deadline"] = CALLBACK(src, PROC_REF(admin_extend_deadline))

/datum/antagonist/proc/admin_view_contract(mob/admin)
	if(!current_contract)
		to_chat(admin, span_notice("No active contract."))
		return
	var/minutes_left = round((current_contract.deadline - world.time) / (1 MINUTES))
	to_chat(admin, span_notice("Cycle [current_contract.cycle_number] (tier [current_contract.tier_ceiling]), deadline in [minutes_left] min, offline [round(current_contract.offline_deciseconds / (1 MINUTES))] min:"))
	for(var/datum/contract_goal/goal as anything in current_contract.goals)
		to_chat(admin, span_notice("- [goal.get_description()][goal.completed ? " (done)" : ""]"))

/datum/antagonist/proc/admin_reroll_contract(mob/admin)
	if(current_contract)
		current_contract.grade = CONTRACT_GRADE_EXCUSED
		contract_history += current_contract
		current_contract = null
	issue_next_contract()
	message_admins("[key_name_admin(admin)] rerolled [key_name_admin(owner)]'s contract.")

/datum/antagonist/proc/admin_warp_cycle(mob/admin)
	if(!current_contract)
		return
	current_contract.deadline = world.time
	close_contract_cycle()
	message_admins("[key_name_admin(admin)] warped [key_name_admin(owner)]'s contract cycle to its deadline.")

/datum/antagonist/proc/admin_extend_deadline(mob/admin)
	if(!current_contract)
		return
	var/minutes = input(admin, "Extend deadline by how many minutes?", "Extend Deadline", 30) as null|num
	if(!minutes)
		return
	current_contract.deadline += minutes MINUTES
	message_admins("[key_name_admin(admin)] extended [key_name_admin(owner)]'s contract deadline by [minutes] minutes.")

/mob/living/verb/review_patron_contract()
	set name = "Review Contract"
	set category = "IC"
	if(!mind)
		return
	var/found = FALSE
	for(var/datum/antagonist/antag as anything in mind.antag_datums)
		if(!antag.contract_pool)
			continue
		found = TRUE
		var/datum/antag_contract/contract = antag.current_contract
		if(!contract)
			to_chat(src, span_notice("[antag.contract_pool.patron_name] has no demands of me right now."))
			continue
		var/minutes_left = round((contract.deadline - world.time) / (1 MINUTES))
		to_chat(src, span_notice("<b>[antag.contract_pool.patron_name]'s demands</b> ([minutes_left] min remain):"))
		for(var/datum/contract_goal/goal as anything in contract.goals)
			to_chat(src, span_notice("- [goal.get_description()][goal.completed ? " (done)" : ""]"))
	if(!found)
		to_chat(src, span_notice("No patron makes demands of me."))
