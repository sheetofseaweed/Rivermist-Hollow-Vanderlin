/datum/contract_pool/bandit
	goal_templates = list(
		/datum/contract_goal/bandit/case_districts,
		/datum/contract_goal/bandit/lockpicks,
		/datum/contract_goal/bandit/stolen_access,
		/datum/contract_goal/bandit/tribute,
	)
	goals_per_contract_min = 2
	goals_per_contract_max = 3
	max_tier = 5
	patron_name = "Mask"
	issue_text = "The free company's next marks are agreed. Every bandit shares this work."
	success_text = "Mask smiles behind the shadow. The company has made good on its word."
	failure_text = "The company's name is diminished; Mask leaves no sign of approval."
	excused_text = "With too few hands in the field, the company lets this opportunity pass."

/datum/contract_goal/bandit
	triumph_reward = 2

/datum/contract_goal/bandit/is_valid(datum/antagonist/antag)
	return istype(antag, /datum/antagonist/bandit)

/datum/contract_goal/bandit/case_districts
	name = "case the town"
	description_template = "Quietly case %TARGET% distinct town districts with a casing ledger."
	target_minimum = 2
	target_maximum = 3
	var/list/cased_area_types = list()

/datum/contract_goal/bandit/case_districts/proc/record_area(area/cased_area)
	if(completed || !cased_area || (cased_area.type in cased_area_types))
		return FALSE
	cased_area_types += cased_area.type
	add_progress(1)
	return TRUE

/datum/contract_goal/bandit/lockpicks
	name = "open forbidden doors"
	description_template = "Pick %TARGET% distinct locks in town without bloodshed."
	target_minimum = 2
	target_maximum = 4
	var/list/picked_lock_refs = list()

/datum/contract_goal/bandit/lockpicks/proc/record_lock(obj/picked_lock)
	if(completed || !picked_lock)
		return FALSE
	var/lock_ref = REF(picked_lock)
	if(lock_ref in picked_lock_refs)
		return FALSE
	picked_lock_refs += lock_ref
	add_progress(1)
	return TRUE

/datum/contract_goal/bandit/stolen_access
	name = "steal the town's access"
	description_template = "Offer keys bearing %TARGET% distinct town accesses to the faceless idol."
	target_minimum = 2
	target_maximum = 3
	var/list/offered_accesses = list()

/datum/contract_goal/bandit/stolen_access/proc/record_key(obj/item/key/offered_key)
	if(completed || !offered_key || istype(offered_key, /obj/item/key/custom) || istype(offered_key, /obj/item/key/bandit) || !length(offered_key.lockids))
		return FALSE
	var/recorded_access = FALSE
	for(var/access_id in offered_key.lockids)
		if(access_id in offered_accesses)
			continue
		offered_accesses += access_id
		add_progress(1)
		recorded_access = TRUE
		if(completed)
			break
	return recorded_access

/datum/contract_goal/bandit/tribute
	name = "fence tribute"
	description_template = "Offer valuables worth %TARGET% mammon to the faceless idol."
	target_minimum = 240
	target_maximum = 360
	triumph_reward = 3

/datum/antagonist/bandit/proc/get_active_bandit_goal(goal_type)
	var/datum/contract_party/party = get_or_create_contract_party()
	if(!party.current_contract)
		return null
	for(var/datum/contract_goal/goal as anything in party.current_contract.goals)
		if(istype(goal, goal_type))
			return goal
	return null

/datum/antagonist/bandit/proc/record_cased_area(area/cased_area)
	var/datum/contract_goal/bandit/case_districts/goal = get_active_bandit_goal(/datum/contract_goal/bandit/case_districts)
	return goal?.record_area(cased_area)

/datum/antagonist/bandit/proc/record_picked_lock(obj/picked_lock)
	var/area/lock_area = get_area(picked_lock)
	if(!istype(lock_area, /area/indoors/town) && !istype(lock_area, /area/outdoors/town) && !istype(lock_area, /area/outdoors/exposed/town) && !istype(lock_area, /area/under/town))
		return FALSE
	var/datum/contract_goal/bandit/lockpicks/goal = get_active_bandit_goal(/datum/contract_goal/bandit/lockpicks)
	return goal?.record_lock(picked_lock)

/datum/antagonist/bandit/proc/record_offered_key(obj/item/key/offered_key)
	var/datum/contract_goal/bandit/stolen_access/goal = get_active_bandit_goal(/datum/contract_goal/bandit/stolen_access)
	return goal?.record_key(offered_key)

/obj/item/book/bandit_casing_ledger
	name = "casing ledger"
	desc = "A thief's shorthand ledger for noting patrols, windows, locks, and quiet routes. Use it while standing in a town district to case the area."
	icon_state = "basic_book_1"
	unique = TRUE

/obj/item/book/bandit_casing_ledger/attack_self(mob/user, list/modifiers)
	if(!isbandit(user))
		to_chat(user, span_warning("The cant and symbols in this ledger mean nothing to me."))
		return
	var/area/starting_area = get_area(user)
	if(!istype(starting_area, /area/indoors/town) && !istype(starting_area, /area/outdoors/town) && !istype(starting_area, /area/outdoors/exposed/town) && !istype(starting_area, /area/under/town))
		to_chat(user, span_warning("There is nothing useful about the town to case here."))
		return
	to_chat(user, span_notice("I begin noting entrances, witnesses, and escape routes..."))
	if(!do_after(user, 10 SECONDS, src))
		return
	if(QDELETED(src) || QDELETED(user) || get_area(user) != starting_area || !isbandit(user))
		return
	var/datum/antagonist/bandit/bandit = user.mind.has_antag_datum(/datum/antagonist/bandit)
	if(bandit.record_cased_area(starting_area))
		to_chat(user, span_notice("The company now has a useful survey of [starting_area.name]."))
	else
		to_chat(user, span_warning("The company cannot learn anything new from surveying [starting_area.name] right now."))
