/datum/quest/custom
	abstract_type = /datum/quest/custom
	quest_type = QUEST_CUSTOM
	contract_group = QUEST_GROUP_COMMISSIONS
	player_commission = TRUE
	minimum_tier = QUEST_TIER_ROUTINE
	maximum_tier = QUEST_TIER_MYTHIC
	var/custom_quest_flags = CUSTOM_QUEST_PLEDGE
	var/issue_label = ""
	var/datum/weakref/pledge_ref
	var/requires_steward_validation = TRUE

/datum/quest/custom/get_title()
	return title ? title : "Special Commission"

/datum/quest/custom/get_objective_text()
	return "Speak with [quest_giver_name ? quest_giver_name : "the patron"] for details."

/datum/quest/custom/get_location_text()
	return "No fixed destination. Follow the commission instructions."

/datum/quest/custom/get_target_map_text(turf/reference_turf)
	return "No fixed map."

/datum/quest/custom/generate(obj/effect/landmark/quest_spawner/landmark)
	if(!title)
		title = get_title()
	threat_tier = requested_tier
	progress_required = max(1, progress_required)
	return TRUE

/datum/quest/custom/check_completion()
	return progress_current >= progress_required

/datum/quest/custom/calculate_deposit(reward_override)
	return 0

/datum/quest/custom/proc/build_from_user(mob/user)
	return FALSE

/datum/quest/custom/proc/build_from_pledge(obj/item/paper/scroll/quest/pledge/pledge, mob/steward)
	if(!pledge || pledge.pledge_state != QUEST_PLEDGE_SEALED || pledge.escrowed_mammons < 1)
		return FALSE
	requested_tier = pledge.pledge_tier
	threat_tier = requested_tier
	reward_amount = pledge.escrowed_mammons
	title = pledge.pledge_title
	quest_giver_reference = pledge.pledge_author_reference
	quest_giver_name = pledge.pledge_author_name
	pledge_ref = WEAKREF(pledge)
	return !!title

/datum/quest/custom/proc/build_pledge(obj/item/paper/scroll/quest/pledge/pledge)
	pledge.pledge_tier = requested_tier
	pledge.pledge_reward = reward_amount
	pledge.pledge_title = title

/datum/quest/custom/proc/validate(mob/steward, turf/input_point, obj/structure/fake_machine/contractledger/ledger)
	return steward_validate(steward, ledger)

/datum/quest/custom/proc/on_return_to_board()
	return

/datum/quest/custom/proc/on_validate_fail(mob/steward)
	to_chat(steward, span_warning("Validation failed for \"[title]\". Make sure its stated conditions are met."))

/datum/quest/custom/proc/steward_validate(mob/steward, obj/structure/fake_machine/contractledger/ledger)
	if(!ishuman(steward) || !ledger?.is_quest_handler(steward))
		to_chat(steward, span_warning("Only a quest-issuing role can validate commissions."))
		return FALSE
	if(complete)
		to_chat(steward, span_notice("This commission is already complete."))
		return FALSE
	log_quest(steward.ckey, steward.mind, steward, "Validate player commission: [title]")
	progress_current = progress_required
	mark_complete()
	to_chat(steward, span_notice("You validate \"[title]\" as complete."))
	return TRUE

/datum/quest/custom/proc/fill_common_fields(mob/user)
	var/list/tier_choices = get_tier_choices()
	var/tier_label = tgui_input_list(user, "How dangerous or demanding is this commission?", "Commission Tier", tier_choices)
	if(!tier_label)
		return FALSE
	requested_tier = tier_choices[tier_label]
	threat_tier = requested_tier

	var/suggested_reward = max(10, requested_tier * 25)
	var/reward = tgui_input_number(user, "Set the promised reward in amna. Suggested: [suggested_reward]", "Commission Reward", suggested_reward, 10000, 1)
	if(!reward)
		return FALSE
	reward_amount = reward
	return TRUE
