// ==================== STOCKPILE WITHDRAW ONLY ====================

/obj/structure/fake_machine/stockpile_withdraw
	name = "stockpile extractor"
	desc = "Terminal for withdrawing items from the town stockpile."
	icon = 'icons/roguetown/misc/machines.dmi'
	icon_state = "submit"
	density = FALSE
	blade_dulling = DULLING_BASH
	pixel_y = 32

	var/stockpile_index = 1
	var/datum/withdraw_tab/withdraw_tab = null

/obj/structure/fake_machine/stockpile_withdraw/Initialize(mapload)
	. = ..()
	SSroguemachine.stock_machines += src
	withdraw_tab = new(stockpile_index, src)

/obj/structure/fake_machine/stockpile_withdraw/Destroy()
	SSroguemachine.stock_machines -= src
	QDEL_NULL(withdraw_tab)
	return ..()

/obj/structure/fake_machine/stockpile_withdraw/attackby(obj/item/P, mob/user, params)
	if(istype(P, /obj/item/coin))
		withdraw_tab.insert_coins(P)
		SStgui.update_uis(src) //RMH EDITED
		return attack_hand(user)

	playsound(src, 'sound/misc/machineno.ogg', 100, FALSE, -1)
	say("TAKING ONLY YOUR COINS! NOT YOUR TRASH!")
	return

//RMH EDITED START
/obj/structure/fake_machine/stockpile_withdraw/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return
	if(!ishuman(user))
		return
	user.changeNext_move(CLICK_CD_MELEE)
	playsound(loc, 'sound/misc/keyboard_enter.ogg', 100, FALSE, -1)
	ui_interact(user)

/obj/structure/fake_machine/stockpile_withdraw/ui_state(mob/user)
	return GLOB.physical_state

/obj/structure/fake_machine/stockpile_withdraw/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Stockpile", "STOCKPILE EXTRACTOR", 480, 640)
		ui.open()

/obj/structure/fake_machine/stockpile_withdraw/ui_data(mob/user)
	var/list/data = list()
	data["title"] = "STOCKPILE EXTRACTOR"
	data["budget"] = withdraw_tab.budget
	data["compact"] = withdraw_tab.compact
	data["can_read"] = user.can_read(src, TRUE) ? TRUE : FALSE
	data["is_full"] = FALSE
	data["view"] = "withdraw"
	data["items"] = withdraw_tab.get_ui_items()
	return data

/obj/structure/fake_machine/stockpile_withdraw/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	if(!ishuman(usr))
		return
	if(!usr.can_perform_action(src, NEED_DEXTERITY|FORBID_TELEKINESIS_REACH))
		return
	switch(action)
		if("toggle_compact")
			withdraw_tab.perform_action(null, list("compact" = "1"))
			return TRUE
		if("change")
			withdraw_tab.perform_action(null, list("change" = "1"))
			return TRUE
		if("withdraw")
			if(withdraw_tab.perform_action(null, list("withdraw" = params["ref"])))
				playsound(loc, 'sound/misc/disposalflush.ogg', 100, FALSE, -1)
				flick("submit_anim", src)
			return TRUE
//RMH EDITED END
