/obj/item/paper/scroll/quest/pledge
	name = "blank quest pledge"
	desc = "A heavy parchment bearing an ornate guild seal. It can hold a player-funded commission."
	icon_state = "scroll_quest"
	base_icon_state = "scroll_quest"
	var/pledge_state = QUEST_PLEDGE_BLANK
	var/pledge_title = ""
	var/pledge_objective = ""
	var/pledge_mode = ""
	var/pledge_tier = QUEST_TIER_ROUTINE
	var/pledge_reward = 0
	var/pledge_item_type
	var/pledge_item_name = ""
	var/pledge_item_count = 1
	var/pledge_reagent_type
	var/pledge_reagent_name = ""
	var/pledge_reagent_volume = 10
	var/pledge_assassin_target = ""
	var/pledge_assassin_target_ckey = ""
	var/pledge_delivery_target = ""
	var/pledge_delivery_target_ckey = ""
	var/list/obj/item/packed_delivery_items = list()
	var/escrowed_mammons = 0
	var/datum/weakref/pledge_author_reference
	var/pledge_author_name = ""
	var/datum/weakref/posted_quest_ref

/obj/item/paper/scroll/quest/pledge/Destroy()
	if(pledge_state == QUEST_PLEDGE_SEALED && escrowed_mammons > 0)
		var/mob/author = pledge_author_reference?.resolve()
		if(author)
			add_mammons_to_atom(author, escrowed_mammons)
			escrowed_mammons = 0
	for(var/obj/item/item as anything in packed_delivery_items.Copy())
		if(!QDELETED(item))
			item.forceMove(get_turf(src))
	packed_delivery_items.Cut()
	return ..()

/obj/item/paper/scroll/quest/pledge/examine(mob/user)
	. = ..()
	switch(pledge_state)
		if(QUEST_PLEDGE_BLANK)
			. += span_notice("Use it in-hand to write a commission.")
		if(QUEST_PLEDGE_FILLED)
			. += span_notice("[pledge_title] — [get_quest_tier_label(pledge_tier)] — [pledge_reward] amna.")
			. += span_warning("It is not sealed and holds no money yet.")
		if(QUEST_PLEDGE_SEALED)
			. += span_notice("[pledge_title] — [get_quest_tier_label(pledge_tier)] — [escrowed_mammons] amna escrowed.")
			. += span_warning("A quest handler can post it at the Grand Contract Ledger.")
		if(QUEST_PLEDGE_POSTED)
			. += span_notice("The guild has posted this commission.")
	if(pledge_mode == "Item delivery" && length(packed_delivery_items))
		. += span_notice("It contains [length(packed_delivery_items)] packed item[ length(packed_delivery_items) == 1 ? "" : "s"].")

/obj/item/paper/scroll/quest/pledge/attack_self(mob/living/carbon/human/user)
	switch(pledge_state)
		if(QUEST_PLEDGE_BLANK)
			fill_out(user)
		if(QUEST_PLEDGE_FILLED)
			var/choice = tgui_input_list(user, "What would you like to do?", "Quest Pledge", list("Edit", "Seal and escrow reward", "Discard"))
			switch(choice)
				if("Edit")
					fill_out(user)
				if("Seal and escrow reward")
					seal(user)
				if("Discard")
					qdel(src)
		if(QUEST_PLEDGE_SEALED)
			if(pledge_author_reference?.resolve() != user)
				to_chat(user, span_warning("Only the author can break this pledge's escrow seal."))
				return
			if(tgui_alert(user, "Break the seal and reclaim [escrowed_mammons] amna?", "Quest Pledge", list("Unseal", "Cancel")) == "Unseal")
				unseal(user)
		if(QUEST_PLEDGE_POSTED)
			to_chat(user, span_warning("This pledge has already been posted and cannot be altered."))

/obj/item/paper/scroll/quest/pledge/attackby(obj/item/used_item, mob/living/carbon/human/user, params)
	if(pledge_mode == "Item delivery" && pledge_state == QUEST_PLEDGE_FILLED)
		if(!(used_item in user))
			return ..()
		if(length(packed_delivery_items) >= 5)
			to_chat(user, span_warning("A pledge can contain at most five delivery items."))
			return
		used_item.forceMove(src)
		packed_delivery_items += used_item
		to_chat(user, span_notice("You fold [used_item] into the pledge. ([length(packed_delivery_items)]/5)"))
		return
	return ..()

/obj/item/paper/scroll/quest/pledge/proc/fill_out(mob/user)
	var/list/available_modes = list()
	for(var/datum/quest/custom/quest_path as anything in subtypesof(/datum/quest/custom))
		if(IS_ABSTRACT(quest_path) || !(initial(quest_path.custom_quest_flags) & CUSTOM_QUEST_PLEDGE))
			continue
		var/label = initial(quest_path.issue_label)
		if(label)
			available_modes[label] = quest_path
	var/mode_choice = tgui_input_list(user, "What kind of commission are you writing?", "Quest Pledge", available_modes)
	if(!mode_choice)
		return FALSE
	var/quest_path = available_modes[mode_choice]
	var/datum/quest/custom/commission = new quest_path()
	if(!commission.build_from_user(user))
		qdel(commission)
		return FALSE

	if(pledge_mode == "Item delivery" && mode_choice != pledge_mode)
		for(var/obj/item/item as anything in packed_delivery_items.Copy())
			item.forceMove(get_turf(user))
		packed_delivery_items.Cut()
	pledge_mode = mode_choice
	commission.build_pledge(src)
	qdel(commission)
	pledge_author_reference = WEAKREF(user)
	pledge_author_name = user.real_name
	pledge_state = QUEST_PLEDGE_FILLED
	name = "quest pledge: [pledge_title]"
	desc = "A written quest pledge offering [pledge_reward] amna. Seal it to commit the reward."
	to_chat(user, span_notice("The pledge is written. Use it again to seal and escrow the promised reward."))
	return TRUE

/obj/item/paper/scroll/quest/pledge/proc/seal(mob/user)
	if(pledge_state != QUEST_PLEDGE_FILLED || !pledge_title || !pledge_mode || pledge_reward < 1)
		return FALSE
	if(pledge_mode == "Item delivery" && !length(packed_delivery_items))
		to_chat(user, span_warning("Fold at least one delivery item into the pledge before sealing it."))
		return FALSE
	var/available_mammons = get_mammons_in_atom(user)
	if(available_mammons < pledge_reward)
		to_chat(user, span_warning("You need [pledge_reward] amna in carried coin, but only have [available_mammons]."))
		return FALSE
	if(tgui_alert(user, "Sealing this pledge will escrow [pledge_reward] amna in carried coin.", "Confirm Escrow", list("Seal", "Cancel")) != "Seal")
		return FALSE
	var/removed_mammons = remove_mammons_from_atom(user, pledge_reward)
	if(removed_mammons != pledge_reward)
		if(removed_mammons > 0)
			add_mammons_to_atom(user, removed_mammons)
		to_chat(user, span_warning("The pledge could not make exact change from your carried coins."))
		return FALSE
	escrowed_mammons = removed_mammons
	pledge_state = QUEST_PLEDGE_SEALED
	name = "sealed quest pledge: [pledge_title]"
	desc = "A sealed quest pledge holding [escrowed_mammons] amna in escrow."
	to_chat(user, span_notice("The reward is escrowed. Give this pledge to a quest handler to post at the ledger."))
	return TRUE

/obj/item/paper/scroll/quest/pledge/proc/unseal(mob/user)
	if(pledge_state != QUEST_PLEDGE_SEALED)
		return FALSE
	var/refund = escrowed_mammons
	escrowed_mammons = 0
	add_mammons_to_atom(user, refund)
	pledge_state = QUEST_PLEDGE_FILLED
	name = "quest pledge: [pledge_title]"
	desc = "A written quest pledge offering [pledge_reward] amna. Seal it to commit the reward."
	to_chat(user, span_notice("You break the seal and reclaim [refund] amna."))
	return TRUE

/obj/item/paper/scroll/quest/pledge/proc/post_to_ledger(mob/steward, obj/structure/fake_machine/contractledger/ledger)
	if(pledge_state != QUEST_PLEDGE_SEALED || escrowed_mammons < 1)
		to_chat(steward, span_warning("This pledge is not sealed with a funded reward."))
		return null
	var/quest_path
	for(var/datum/quest/custom/candidate_path as anything in subtypesof(/datum/quest/custom))
		if(IS_ABSTRACT(candidate_path) || initial(candidate_path.issue_label) != pledge_mode)
			continue
		quest_path = candidate_path
		break
	if(!quest_path)
		to_chat(steward, span_warning("The ledger does not recognize this commission type."))
		return null

	var/datum/quest/custom/commission = new quest_path()
	if(!commission.build_from_pledge(src, steward) || !commission.generate(null))
		qdel(commission)
		to_chat(steward, span_warning("The ledger cannot construct a valid commission from this pledge."))
		return null
	commission.on_issued_from_ledger(ledger, steward)
	if(!SSquestboard.add_quest(commission))
		qdel(commission)
		return null

	escrowed_mammons = 0
	pledge_state = QUEST_PLEDGE_POSTED
	posted_quest_ref = WEAKREF(commission)
	name = "posted quest pledge: [pledge_title]"
	desc = "A receipt for a player-funded commission now posted in the Grand Contract Ledger."
	log_quest(steward.ckey, steward.mind, steward, "Post player commission: [pledge_title]")
	to_chat(steward, span_notice("You post \"[pledge_title]\" to the shared contract board."))
	return commission

/proc/get_quest_tier_label(tier)
	switch(tier)
		if(QUEST_TIER_ROUTINE)
			return "Tier I - Routine"
		if(QUEST_TIER_RISKY)
			return "Tier II - Risky"
		if(QUEST_TIER_DANGEROUS)
			return "Tier III - Dangerous"
		if(QUEST_TIER_DEADLY)
			return "Tier IV - Deadly"
		if(QUEST_TIER_LETHAL)
			return "Tier V - Lethal"
		if(QUEST_TIER_MYTHIC)
			return "Tier VI - Mythic"
	return "Unknown tier"
