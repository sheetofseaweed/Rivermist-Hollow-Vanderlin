// Succubus patron contracts, full-completion progression, and thrall upkeep.

/datum/antagonist/succubus
	contract_pool_type = /datum/contract_pool/succubus

/datum/contract_pool/succubus
	patron_name = "Asmodeus"
	issue_text = "A velvet voice recites fresh clauses of my infernal bargain..."
	success_text = "Asmodeus accepts my offering. My infernal vessel deepens."
	failure_text = "The terms go unmet. Asmodeus's displeasure burns beneath my skin."
	excused_text = "My silence is noted, but the clause is stayed — for now."
	goals_per_contract_min = 2
	goals_per_contract_max = 2
	max_tier = SUCCUBUS_CONTRACT_TIER_MAX
	goal_templates = list(
		/datum/contract_goal/succubus/infernal_tithe,
		/datum/contract_goal/succubus/varied_appetite,
		/datum/contract_goal/succubus/heightened_desire,
		/datum/contract_goal/succubus/masked_feast,
		/datum/contract_goal/succubus/sacred_corruption,
		/datum/contract_goal/succubus/accepted_bond,
		/datum/contract_goal/succubus/infernal_retinue,
		/datum/contract_goal/succubus/unmasked_hunger,
	)

/datum/contract_goal/succubus/proc/count_available_partners(datum/antagonist/succubus/succubus_antag)
	var/count = 0
	for(var/mob/living/carbon/human/candidate in GLOB.player_list)
		if(candidate == succubus_antag.owner?.current)
			continue
		if(!candidate.client || !candidate.mind?.key)
			continue
		count++
	return count

/datum/contract_goal/succubus/proc/count_enthrallable_candidates(datum/antagonist/succubus/succubus_antag)
	var/count = 0
	for(var/mob/living/carbon/human/candidate in GLOB.player_list)
		if(candidate == succubus_antag.owner?.current)
			continue
		if(!candidate.client || !candidate.mind?.key)
			continue
		if(!candidate.has_erp_pref(/datum/erp_preference/boolean/enthrallable))
			continue
		if(IS_SUCCUBUS(candidate) || candidate.mind.has_antag_datum(/datum/antagonist/succubus_thrall))
			continue
		count++
	return count

/datum/contract_goal/succubus/is_valid(datum/antagonist/antag)
	var/datum/antagonist/succubus/succubus_antag = antag
	if(!istype(succubus_antag))
		return FALSE
	return count_available_partners(succubus_antag) >= 1

/datum/contract_goal/succubus/infernal_tithe
	name = "infernal tithe"
	description_template = "Draw %TARGET% essence from player partners' climaxes."
	tier = 1
	weight = 14
	target_minimum = 75
	target_maximum = 125

/datum/contract_goal/succubus/varied_appetite
	name = "varied appetite"
	description_template = "Feed from %TARGET% different player partners."
	tier = 1
	weight = 12
	target_minimum = 2
	target_maximum = 3
	var/list/partner_keys = list()

/datum/contract_goal/succubus/varied_appetite/Destroy()
	partner_keys = null
	return ..()

/datum/contract_goal/succubus/varied_appetite/is_valid(datum/antagonist/antag)
	var/datum/antagonist/succubus/succubus_antag = antag
	if(!istype(succubus_antag))
		return FALSE
	return count_available_partners(succubus_antag) >= target_amount

/datum/contract_goal/succubus/varied_appetite/proc/record_partner(partner_key)
	if(completed || !partner_key || partner_key in partner_keys)
		return
	partner_keys += partner_key
	add_progress()

/datum/contract_goal/succubus/heightened_desire
	name = "heightened desire"
	description_template = "Feed from %TARGET% partner(s) at heightened arousal."
	tier = 1
	weight = 10
	target_minimum = 1
	target_maximum = 2

/datum/contract_goal/succubus/masked_feast
	name = "masked feast"
	description_template = "Feed from %TARGET% partner while wearing a stolen face."
	tier = 1
	weight = 8
	target_minimum = 1
	target_maximum = 1

/datum/contract_goal/succubus/sacred_corruption
	name = "sacred corruption"
	description_template = "Feed from %TARGET% member of the clergy."
	tier = 2
	weight = 6
	target_minimum = 1
	target_maximum = 1

/datum/contract_goal/succubus/sacred_corruption/is_valid(datum/antagonist/antag)
	var/datum/antagonist/succubus/succubus_antag = antag
	if(!istype(succubus_antag))
		return FALSE
	for(var/mob/living/carbon/human/candidate in GLOB.player_list)
		if(candidate == succubus_antag.owner?.current)
			continue
		if(!candidate.client || !candidate.mind?.key)
			continue
		if(candidate.mind.assigned_role?.title in GLOB.succubus_clergy_roles)
			return TRUE
	return FALSE

/datum/contract_goal/succubus/accepted_bond
	name = "accepted bond"
	description_template = "Forge %TARGET% freely accepted thrall bond."
	tier = 2
	weight = 6
	target_minimum = 1
	target_maximum = 1

/datum/contract_goal/succubus/accepted_bond/is_valid(datum/antagonist/antag)
	var/datum/antagonist/succubus/succubus_antag = antag
	if(!istype(succubus_antag))
		return FALSE
	if(succubus_antag.count_thralls() >= SUCCUBUS_THRALL_CAP)
		return FALSE
	return count_enthrallable_candidates(succubus_antag) >= 1

/datum/contract_goal/succubus/infernal_retinue
	name = "infernal retinue"
	description_template = "Maintain %TARGET% willing thrall bond(s)."
	goal_type = CONTRACT_GOAL_STATE
	tier = 2
	weight = 8
	target_minimum = 1
	target_maximum = 2

/datum/contract_goal/succubus/infernal_retinue/is_valid(datum/antagonist/antag)
	var/datum/antagonist/succubus/succubus_antag = antag
	if(!istype(succubus_antag))
		return FALSE
	var/current_thralls = succubus_antag.count_thralls()
	if(current_thralls >= target_amount)
		return TRUE
	return current_thralls + count_enthrallable_candidates(succubus_antag) >= target_amount

/datum/contract_goal/succubus/infernal_retinue/get_state_progress()
	var/datum/antagonist/succubus/succubus_antag = antag
	if(!istype(succubus_antag))
		return 0
	return succubus_antag.count_thralls()

/datum/contract_goal/succubus/unmasked_hunger
	name = "unmasked hunger"
	description_template = "Feed from %TARGET% player partner while in true form."
	tier = 3
	weight = 4
	target_minimum = 1
	target_maximum = 1

/datum/antagonist/succubus/proc/get_succubus_contract_tier()
	return clamp(contracts_completed_full + 1, 1, SUCCUBUS_CONTRACT_TIER_MAX)

/datum/antagonist/succubus/proc/refresh_succubus_contract_progression()
	var/static/list/essence_caps = list(
		SUCCUBUS_ESSENCE_CAP_BASE,
		SUCCUBUS_ESSENCE_CAP_TIER_2,
		SUCCUBUS_ESSENCE_CAP_TIER_3,
		SUCCUBUS_ESSENCE_CAP_TIER_4,
	)
	var/old_cap = essence_cap
	essence_cap = essence_caps[get_succubus_contract_tier()]
	essence = clamp(essence, 0, essence_cap)
	if(old_cap == essence_cap)
		return FALSE
	if(owner?.current)
		to_chat(owner.current, span_notice("Asmodeus deepens my vessel. I can now hold [essence_cap] essence."))
	return TRUE

/datum/antagonist/succubus/on_contract_completed(datum/antag_contract/contract)
	. = ..()
	refresh_succubus_contract_progression()

/datum/antagonist/succubus/on_contract_cycle_closed(datum/antag_contract/contract)
	. = ..()
	var/thrall_count = count_thralls()
	if(!thrall_count)
		return
	var/upkeep = thrall_count * SUCCUBUS_THRALL_UPKEEP_PER_CYCLE
	var/essence_before = essence
	adjust_essence(-upkeep)
	var/paid = essence_before - essence
	if(owner?.current)
		to_chat(owner.current, span_notice("My [thrall_count == 1 ? "bond demands" : "bonds demand"] [upkeep] essence in upkeep. I pay [paid], leaving [essence]/[essence_cap]."))
