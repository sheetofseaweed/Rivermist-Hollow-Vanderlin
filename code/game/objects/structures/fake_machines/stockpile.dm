/obj/structure/fake_machine/stockpile
	name = "stockpile"
	desc = ""
	icon = 'icons/roguetown/misc/machines.dmi'
	icon_state = "stockpile_vendor"
	density = FALSE
	blade_dulling = DULLING_BASH
	SET_BASE_PIXEL(0, 32)
	var/stockpile_index = 1
	var/datum/withdraw_tab/withdraw_tab = null
	//RMH EDITED START
	/// Which TGUI tab is shown: "withdraw" (Extract) or "deposit" (Feed).
	var/ui_view = "withdraw"
	//RMH EDITED END

/obj/structure/fake_machine/stockpile/Initialize()
	. = ..()
	SSroguemachine.stock_machines += src
	withdraw_tab = new(stockpile_index, src)

/obj/structure/fake_machine/stockpile/Destroy()
	SSroguemachine.stock_machines -= src
	QDEL_NULL(withdraw_tab)
	return ..()

//RMH EDITED START
/obj/structure/fake_machine/stockpile/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return
	if(!ishuman(user))
		return
	user.changeNext_move(CLICK_CD_MELEE)
	playsound(src, 'sound/misc/keyboard_enter.ogg', 100, FALSE, -1)
	ui_interact(user)

/obj/structure/fake_machine/stockpile/ui_state(mob/user)
	return GLOB.physical_state

/obj/structure/fake_machine/stockpile/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Stockpile", "TOWN STOCKPILE", 520, 700)
		ui.open()

/obj/structure/fake_machine/stockpile/ui_data(mob/user)
	var/list/data = list()
	data["title"] = "TOWN STOCKPILE"
	data["budget"] = withdraw_tab.budget
	data["compact"] = withdraw_tab.compact
	data["can_read"] = user.can_read(src, TRUE) ? TRUE : FALSE
	data["is_full"] = TRUE
	data["view"] = ui_view
	data["items"] = withdraw_tab.get_ui_items()
	if(ui_view == "deposit")
		var/list/bounties = list()
		for(var/datum/stock/bounty/R in SStreasury.stockpile_datums)
			bounties += list(list(
				"name" = R.name,
				"payout" = R.payout_price,
				"percent" = R.percent_bounty ? TRUE : FALSE,
			))
		data["bounties"] = bounties
		var/list/stocks = list()
		for(var/datum/stock/stockpile/R in SStreasury.stockpile_datums)
			stocks += list(list(
				"name" = R.name,
				"payout" = R.get_payout_price(),
				"held" = R.get_held_count(),
				"oversupply" = R.oversupply_amount,
				"oversupplied" = (R.get_held_count() >= R.oversupply_amount) ? TRUE : FALSE,
			))
		data["stocks"] = stocks
	return data

/obj/structure/fake_machine/stockpile/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	if(!ishuman(usr))
		return
	if(!usr.can_perform_action(src, NEED_DEXTERITY|FORBID_TELEKINESIS_REACH))
		return
	switch(action)
		if("set_view")
			var/v = params["view"]
			if(v == "withdraw" || v == "deposit")
				ui_view = v
			return TRUE
		if("toggle_compact")
			withdraw_tab.perform_action(null, list("compact" = "1"))
			return TRUE
		if("change")
			withdraw_tab.perform_action(null, list("change" = "1"))
			return TRUE
		if("withdraw")
			if(withdraw_tab.perform_action(null, list("withdraw" = params["ref"])))
				playsound(src, 'sound/misc/disposalflush.ogg', 100, FALSE, -1)
			return TRUE
//RMH EDITED END

/obj/structure/fake_machine/stockpile/proc/attemptsell(obj/item/I, mob/H, message = TRUE, sound = TRUE)
	for(var/datum/stock/R in SStreasury.stockpile_datums)
		if(istype(I, /obj/item/natural/bundle))
			var/obj/item/natural/bundle/B = I
			if(B.stacktype == R.item_type)
				var/amt = 0
				if(istype(R, /datum/stock/stockpile))
					for(var/i in 1 to B.amount)
						amt += R.get_payout_price(I)
				else
					amt = R.get_payout_price(I)

				// Move to stockpile instead of deleting
				if(R.add_item_to_stockpile(B))
					if(message == TRUE)
						stock_announce("[B.amount] units of [R.name] has been stockpiled.")
					if(sound == TRUE)
						playsound(src, 'sound/misc/hiss.ogg', 100, FALSE, -1)
					if(!SStreasury.give_money_account(amt, H, "+[amt] from [R.name] bounty") && message == TRUE)
						say("No account found. Submit your fingers to a Meister for inspection.")
					record_round_statistic(STATS_STOCKPILE_EXPANSES, amt)
					return amt
			continue
		else if(I.type == R.item_type)
			if(!R.check_item(I))
				continue
			var/amt = R.get_payout_price(I)
			if(!R.transport_item)
				// Move to stockpile instead of deleting
				if(R.add_item_to_stockpile(I))
					if(message == TRUE)
						stock_announce("[R.name] has been stockpiled.")
					if(sound == TRUE)
						playsound(src, 'sound/misc/hiss.ogg', 100, FALSE, -1)
				else
					say("Stockpile area not accessible.")
					return
			else
				var/area/A = GLOB.areas_by_type[R.transport_item]
				if(!A && message == TRUE)
					say("Couldn't find where to send the submission.")
					return
				var/list/turfs = list()
				for(var/turf/T in A.get_turfs_from_all_zlevels())
					turfs += T
				var/turf/T = pick(turfs)
				I.forceMove(T)
				if(sound == TRUE)
					playsound(src, 'sound/misc/hiss.ogg', 100, FALSE, -1)
					playsound(src, 'sound/misc/disposalflush.ogg', 100, FALSE, -1)
			if(amt)
				if(!SStreasury.give_money_account(amt, H, "+[amt] from [R.name] bounty") && message == TRUE)
					say("No account found. Submit your fingers to a Meister for inspection.")
				record_round_statistic(STATS_STOCKPILE_REVENUE, amt)
			return amt

/obj/structure/fake_machine/stockpile/attackby(obj/item/P, mob/user, list/modifiers)
	if(ishuman(user))
		if(user.real_name in GLOB.outlawed_players)
			say("OUTLAW DETECTED! REFUSING SERVICE!")
			return
		if(istype(P, /obj/item/coin))
			withdraw_tab.insert_coins(P)
			SStgui.update_uis(src) //RMH EDITED
			return attack_hand(user)
		else
			attemptsell(P, user, TRUE, TRUE)
			SStgui.update_uis(src) //RMH EDITED

/obj/structure/fake_machine/stockpile/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return
	. = SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	if(ishuman(user))
		if(user.real_name in GLOB.outlawed_players)
			say("OUTLAW DETECTED! REFUSING SERVICE!")
			return
		var/total_value = 0
		for(var/obj/I in get_turf(src))
			total_value += attemptsell(I, user, FALSE, FALSE)
		playsound(src, 'sound/misc/hiss.ogg', 100, FALSE, -1)
		playsound(src, 'sound/misc/disposalflush.ogg', 100, FALSE, -1)
		if(user in SStreasury.bank_accounts)
			say("Bulk sold for [total_value] amna...")
		else
			say("No account found. Submit your fingers to a Meister for inspection.")
		SStgui.update_uis(src) //RMH EDITED

/datum/withdraw_tab
	var/stockpile_index = -1
	var/budget = 0
	var/compact = FALSE
	var/obj/structure/fake_machine/parent_structure = null

/datum/withdraw_tab/New(stockpile_param, obj/structure/fake_machine/structure_param)
	. = ..()
	stockpile_index = stockpile_param
	parent_structure = structure_param

//RMH EDITED START
/// Builds the list of withdrawable stockpile entries for the TGUI.
/datum/withdraw_tab/proc/get_ui_items()
	var/list/items = list()
	for(var/datum/stock/stockpile/A in SStreasury.stockpile_datums)
		items += list(list(
			"ref" = "[REF(A)]",
			"name" = A.name,
			"desc" = A.desc,
			"held" = A.get_held_count(),
			"price" = A.withdraw_price,
			"disabled" = A.withdraw_disabled ? TRUE : FALSE,
			"affordable" = (budget >= A.withdraw_price) ? TRUE : FALSE,
		))
	return items
//RMH EDITED END

/datum/withdraw_tab/proc/perform_action(href, href_list)
	if(href_list["withdraw"])
		var/datum/stock/D = locate(href_list["withdraw"]) in SStreasury.stockpile_datums

		var/total_price = D.withdraw_price

		if(!D)
			return FALSE
		if(D.withdraw_disabled)
			return FALSE
		if(D.get_held_count() <= 0)
			parent_structure.say("Insufficient stock.")
		else if(total_price > budget)
			parent_structure.say("Insufficient amna.")
		else
			var/obj/item/I = D.withdraw_item()
			if(!I)
				parent_structure.say("Could not retrieve item from stockpile.")
				return FALSE

			budget -= total_price
			record_round_statistic(STATS_STOCKPILE_REVENUE, total_price)
			SStreasury.give_money_treasury(D.withdraw_price, "stockpile withdraw")

			var/mob/user = usr
			if(!user.put_in_hands(I))
				I.forceMove(get_turf(user))
			playsound(parent_structure, 'sound/misc/hiss.ogg', 100, FALSE, -1)
		return TRUE
	if(href_list["compact"])
		if(!usr.can_perform_action(parent_structure, NEED_DEXTERITY|FORBID_TELEKINESIS_REACH))
			return FALSE
		if(ishuman(usr))
			compact = !compact
		return TRUE
	if(href_list["change"])
		if(!usr.can_perform_action(parent_structure, NEED_DEXTERITY|FORBID_TELEKINESIS_REACH))
			return FALSE
		if(ishuman(usr))
			if(budget > 0)
				parent_structure.budget2change(budget, usr)
				budget = 0
		return TRUE

/datum/withdraw_tab/proc/insert_coins(obj/item/coin/C)
	budget += C.get_real_price()
	qdel(C)
	playsound(parent_structure, 'sound/misc/coininsert.ogg', 100, TRUE, -1)

/proc/stock_announce(message)
	for(var/obj/structure/fake_machine/stockpile/S in SSroguemachine.stock_machines)
		S.say(message, spans = list("info"))
