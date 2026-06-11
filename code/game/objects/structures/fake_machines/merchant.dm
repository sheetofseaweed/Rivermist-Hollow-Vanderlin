/obj/item/fake_machine/merchant
	name = "SKY HANDLER"
	desc = "A machine that attracts the attention of trading balloons."
	icon = 'icons/roguetown/misc/machines.dmi'
	icon_state = "ballooner"
	density = TRUE
	blade_dulling = DULLING_BASH
	var/next_airlift
	anchored = TRUE
	w_class = WEIGHT_CLASS_GIGANTIC

/obj/structure/fake_machine/balloon_pad
	name = ""
	desc = ""
	icon = 'icons/roguetown/misc/machines.dmi'
	icon_state = ""
	density = FALSE
	layer = BELOW_OBJ_LAYER
	anchored = TRUE

/obj/item/fake_machine/merchant/attack_hand(mob/living/user)
	if(!anchored)
		return ..()
	user.changeNext_move(CLICK_CD_MELEE)

	var/contents

	contents += "<center>MERCHANT'S GUILD<BR>"
	contents += "--------------<BR>"
	//contents += "Guild's Tax: [SStreasury.queens_tax*100]%<BR>"
	contents += "Next Balloon: [time2text((next_airlift - world.time), "mm:ss")]</center><BR>"

	if(!user.can_read(src, TRUE))
		contents = stars(contents)
	var/datum/browser/popup = new(user, "VENDORTHING", "", 370, 220)
	popup.set_content(contents)
	popup.open()

/obj/item/fake_machine/merchant/Initialize()
	. = ..()
	if(anchored)
		START_PROCESSING(SSroguemachine, src)
	set_light(2, 2, 2, l_color =  "#1b7bf1")
	for(var/X in GLOB.alldirs)
		var/T = get_step(src, X)
		if(!T)
			continue
		new /obj/structure/fake_machine/balloon_pad(T)

/obj/item/fake_machine/merchant/Destroy()
	STOP_PROCESSING(SSroguemachine, src)
	set_light(0)
	return ..()

/obj/item/fake_machine/merchant/process()
	if(world.time > next_airlift)
		next_airlift = world.time + rand(2 MINUTES, 3 MINUTES)
#ifdef TESTSERVER
		next_airlift = world.time + 5 SECONDS
#endif
		var/play_sound = FALSE
		for(var/D in GLOB.alldirs)
			var/budgie = 0
			var/turf/T = get_step(src, D)
			if(!T)
				continue
			var/obj/structure/fake_machine/balloon_pad/E = locate() in T
			if(!E)
				continue
			for(var/obj/I in T)
				var/prize
				if(I.anchored)
					continue
				if(!isturf(I.loc))
					continue
				if (istype(I, /obj/item/coin))
					continue
				prize = I.get_real_price()// - (I.get_real_price() * SStreasury.queens_tax)
				if(prize >= 1)
					play_sound=TRUE
					budgie += prize
					I.visible_message("<span class='warning'>[I] is sucked into the air!</span>")
					qdel(I)
			budgie = round(budgie)
			if(budgie > 0)
				play_sound=TRUE
				E.budget2change(budgie)
				budgie = 0
		if(play_sound)
			playsound(src, 'sound/misc/hiss.ogg', 100, FALSE, -1)

/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////

#define UPGRADE_NOTAX		(1<<0)

/obj/structure/fake_machine/merchantvend
	name = "GOLDFACE"
	desc = "Gilded tombs do worms enfold."
	icon = 'icons/roguetown/misc/machines.dmi'
	icon_state = "goldvendor"
	density = TRUE
	blade_dulling = DULLING_BASH
	anchored = TRUE
	layer = BELOW_OBJ_LAYER
	rattle_sound = 'sound/misc/machineno.ogg'
	unlock_sound = 'sound/misc/beep.ogg'
	lock_sound = 'sound/misc/beep.ogg'
	lock = /datum/lock/key/goldface
	var/list/held_items = list()
	var/budget = 200
	var/upgrade_flags
	var/current_cat
	var/base_price = 0
	var/final_price = 0
	var/taxes = 0
	//RMH EDITED START
	/// Flat percentage markup added on top of the base pack cost (0.5 = +50%).
	/// Used by the public SILVERFACE tier; GOLDFACE keeps it at 0.
	var/extra_fee = 0
	/// Which round statistic to log spending under. Lets SILVERFACE track separately.
	var/value_record_key = STATS_GOLDFACE_VALUE_SPENT
	/// Tagline shown at the top of the TGUI window.
	var/motto = "GOLDFACE - In the name of greed."
	/// TRUE on the public SILVERFACE tier (anyone may buy; cannot be locked).
	var/is_public = FALSE
	/// Active text search across all categories (empty = browse by category).
	var/search = ""
	/// Cap on search results sent to the UI.
	var/result_cap = 60
	/// Running tally of import tax paid / dodged through this machine.
	var/tariff_paid = 0
	var/tariff_evaded = 0
	//RMH EDITED END
	// this is the list of supply groups that you can purchase with this machine
	var/list/unlocked_cats = list("Apparel","Storage","Armor(Light)","Armor(Steel)","Food","Drinks","Jewelry","Luxury","Tools","Seeds","Shields","Medicine","Raw Materials",
								"Weapons (Iron)","Weapons (Steel)","Weapons (Ranged)","Ammunition")

/obj/structure/fake_machine/merchantvend/Initialize()
	. = ..()
	set_light(1, 1, 1, l_color =  "#1b7bf1")

/obj/structure/fake_machine/merchantvend/atom_break(damage_flag)
	. = ..()
	budget2change(budget)
	set_light(0)

/obj/structure/fake_machine/merchantvend/atom_fix()
	. = ..()
	set_light(1, 1, 1, l_color =  "#1b7bf1")

/obj/structure/fake_machine/merchantvend/Destroy()
	. = ..()
	budget2change(budget)
	set_light(0)

//RMH EDITED START
/// The effective service-fee multiplier for this machine (0 on GOLDFACE).
/obj/structure/fake_machine/merchantvend/proc/get_effective_fee()
	return extra_fee

/// Shared price calc so the display and the buy path can never disagree.
/// The service fee is a markup on the good; import tax is charged on the
/// raw pack cost only (mirrors the original GOLDFACE tax behaviour).
/obj/structure/fake_machine/merchantvend/proc/get_pack_price(datum/supply_pack/PA, include_tax = TRUE)
	if(!PA)
		return 0
	var/cost = PA.cost + (PA.cost * get_effective_fee())
	if(include_tax && !(upgrade_flags & UPGRADE_NOTAX))
		cost += round(SStreasury.tax_value * PA.cost)
	return round(cost)
//RMH EDITED END

/obj/structure/fake_machine/merchantvend/attackby(obj/item/I, mob/user, list/modifiers)
	if(istype(I, /obj/item/coin))
		var/money = I.get_real_price()
		budget += money
		qdel(I)
		to_chat(user, span_info("I put [money] amna in [src]."))
		playsound(src, 'sound/misc/machinevomit.ogg', 100, TRUE, -1)
		SStgui.update_uis(src) //RMH EDITED
		return attack_hand(user)
	return ..()

//RMH EDITED START
/obj/structure/fake_machine/merchantvend/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return
	if(!ishuman(user))
		return
	if(locked() && !is_public)
		to_chat(user, span_warning("It's locked. Of course."))
		return
	user.changeNext_move(CLICK_CD_MELEE)
	playsound(src, 'sound/misc/beep.ogg', 100, FALSE, -1)
	ui_interact(user)

/obj/structure/fake_machine/merchantvend/ui_state(mob/user)
	return GLOB.physical_state

/obj/structure/fake_machine/merchantvend/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Goldface", name, 880, 800)
		ui.open()

/obj/structure/fake_machine/merchantvend/proc/is_proprietor(mob/user)
	if(!ishuman(user))
		return FALSE
	var/mob/living/carbon/human/H = user
	return H.job == "Merchant"

/obj/structure/fake_machine/merchantvend/ui_data(mob/user)
	var/list/data = list()
	var/dodging = (upgrade_flags & UPGRADE_NOTAX) ? TRUE : FALSE
	data["motto"] = motto
	data["budget"] = budget
	data["can_read"] = user.can_read(src, TRUE) ? TRUE : FALSE
	data["locked"] = locked() ? TRUE : FALSE
	data["is_public"] = is_public
	data["is_proprietor"] = is_proprietor(user)
	data["is_agent"] = FALSE
	data["is_command_center"] = FALSE
	data["tariff_rate_pct"] = round(SStreasury.tax_value * 100)
	data["tariff_paid"] = tariff_paid
	data["tariff_evaded"] = tariff_evaded
	data["dodging"] = dodging
	if(get_effective_fee() > 0)
		data["public_margin_pct"] = round(get_effective_fee() * 100)
		data["public_margin_label"] = "Waterdeep's Margin"
	data["categories"] = unlocked_cats
	data["current_category"] = current_cat
	data["search"] = search
	data["search_mode"] = (length(search) > 0) ? TRUE : FALSE
	data["result_cap"] = result_cap

	var/list/packs = list()
	var/total_matches = 0
	var/searching = (length(search) > 0)
	if(searching || (current_cat && (current_cat in unlocked_cats)))
		var/list/matched = list()
		for(var/pack in SSmerchant.supply_packs)
			var/datum/supply_pack/P = SSmerchant.supply_packs[pack]
			if(searching)
				if(!findtext(P.name, search))
					continue
			else if(P.group != current_cat)
				continue
			matched += P
		total_matches = length(matched)
		var/count = 0
		for(var/datum/supply_pack/P in sortList(matched))
			count++
			if(searching && count > result_cap)
				break
			var/price_base = round(P.cost + (P.cost * get_effective_fee()))
			var/price_tariff = dodging ? 0 : round(SStreasury.tax_value * P.cost)
			packs += list(list(
				"ref" = "[P.type]",
				"name" = P.name,
				"category" = P.group,
				"qty" = (islist(P.contains) ? length(P.contains) : 1),
				"price" = price_base + price_tariff,
				"price_base" = price_base,
				"price_tariff" = price_tariff,
			))
	data["total_matches"] = total_matches
	data["packs"] = packs
	return data

/obj/structure/fake_machine/merchantvend/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	if(!ishuman(usr))
		return
	if(!usr.can_perform_action(src, NEED_DEXTERITY|FORBID_TELEKINESIS_REACH) || (locked() && !is_public))
		return
	var/mob/living/carbon/human/human_mob = usr
	switch(action)
		if("changecat")
			var/selected_category = params["category"]
			if(selected_category && (selected_category in unlocked_cats))
				current_cat = selected_category
			else
				current_cat = null
			return TRUE
		if("set_search")
			search = trim(params["search"])
			return TRUE
		if("clear_search")
			search = ""
			return TRUE
		if("change")
			if(budget > 0)
				budget2change(budget, human_mob)
				budget = 0
				playsound(src, 'sound/misc/beep.ogg', 100, FALSE, -1)
			return TRUE
		if("secrets")
			if(!is_proprietor(human_mob) || is_public)
				return TRUE
			if(upgrade_flags & UPGRADE_NOTAX)
				upgrade_flags &= ~UPGRADE_NOTAX
			else
				upgrade_flags |= UPGRADE_NOTAX
			playsound(src, 'sound/misc/beep.ogg', 100, FALSE, -1)
			return TRUE
		if("buy")
			var/path = text2path(params["ref"])
			if(!ispath(path, /datum/supply_pack))
				message_admins("MERCHANT [usr.key] IS TRYING TO BUY A [path] WITH THE GOLDFACE. THIS IS AN EXPLOIT.")
				return TRUE
			var/datum/supply_pack/picked_pack = SSmerchant.supply_packs[path]
			if(!picked_pack)
				return TRUE
			base_price = round(picked_pack.cost + (picked_pack.cost * get_effective_fee()))
			taxes = round(SStreasury.tax_value * picked_pack.cost)
			final_price = round(base_price + taxes)
			if(upgrade_flags & UPGRADE_NOTAX)
				final_price = base_price
			if(budget < final_price)
				say("Not enough!")
				return TRUE
			budget -= final_price
			record_round_statistic(value_record_key, final_price)
			if(!(upgrade_flags & UPGRADE_NOTAX))
				SStreasury.give_money_treasury(taxes, "goldface import tax")
				record_featured_stat(FEATURED_STATS_TAX_PAYERS, human_mob, taxes)
				record_round_statistic(STATS_TAXES_COLLECTED, taxes)
				tariff_paid += taxes
			else
				record_round_statistic(STATS_TAXES_EVADED, taxes)
				tariff_evaded += taxes
			if(ispath(picked_pack.contains))
				var/obj/item/packitem = picked_pack.contains
				new packitem(get_turf(human_mob))
			else
				for(var/obj/item/packitem as anything in picked_pack.contains)
					new packitem(get_turf(human_mob))
			qdel(picked_pack)
			playsound(src, 'sound/misc/beep.ogg', 100, FALSE, -1)
			return TRUE
//RMH EDITED END

#undef UPGRADE_NOTAX

//RMH EDITED START
/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////
// SILVERFACE
// Public-access tier of the GOLDFACE, ported from Azure Peak.
// Anyone may buy from it; in exchange the Company tacks on a flat
// service fee (extra_fee). It cannot be locked. Themed variants
// simply expose a different slice of the supply catalogue.
/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////

/obj/structure/fake_machine/merchantvend/public
	name = "SILVERFACE"
	desc = "A public cousin of the GOLDFACE. The Company charges a hefty fee for the privilege of using it. By agreement, it cannot be locked by anyone."
	icon_state = "streetvendor1"
	lock = null				// public: always usable, can never be locked
	is_public = TRUE
	budget = 0				// no starting float; load it with coins
	extra_fee = 0.5			// +50% Company service margin
	value_record_key = STATS_SILVERFACE_VALUE_SPENT
	motto = "SILVERFACE - Commerce for all."
	unlocked_cats = list(
		"Apparel",
		"Storage",
		"Drinks",
		"Food",
		"Jewelry",
		"Instruments",
		"Luxury",
		"Livestock",
		"Seeds",
		"Tools",
		"Medicine",
	)

/obj/structure/fake_machine/merchantvend/public/examine(mob/user)
	. = ..()
	. += span_info("A public version of the GOLDFACE. The Company charges a hefty fee for its usage. Per agreement, it cannot be locked by anyone.")

/obj/structure/fake_machine/merchantvend/public/smith
	name = "Smithy's SILVERFACE"
	desc = "A public SILVERFACE stocked with the wares of the smithing trade."
	unlocked_cats = list(
		"Armor",
		"Armor(Steel)",
		"Shields",
		"Weapons (Iron)",
		"Weapons (Steel)",
		"Weapons (Ranged)",
		"Ammunition",
	)

/obj/structure/fake_machine/merchantvend/public/tailor
	name = "Tailor's SILVERFACE"
	desc = "A public SILVERFACE stocked with garments and light protection."
	unlocked_cats = list(
		"Apparel",
		"Armor(Light)",
		"Storage",
	)

/obj/structure/fake_machine/merchantvend/public/apothecary
	name = "Apothecary's SILVERFACE"
	desc = "A public SILVERFACE stocked with tinctures and remedies."
	unlocked_cats = list(
		"Medicine",
	)
//RMH EDITED END
