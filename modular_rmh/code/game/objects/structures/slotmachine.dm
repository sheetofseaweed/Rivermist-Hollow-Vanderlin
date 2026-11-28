/obj/structure/fake_machine/slotmachine
	name = "slotmachine"
	desc = "Wasting your amnas with style. Tymora watches the reels."
	icon = 'modular_rmh/icons/obj/structures/slotmachine.dmi'
	icon_state = "slotmachine"
	density = TRUE
	anchored = TRUE
	var/spinning = FALSE
	var/bet = 0
	var/jackpot = 0
	var/plays = 0
	var/slots = list()
	var/variants = list("Diamond", "Heart", "Cherry", "Bar", "Lemon", "Watermelon", "Seven")
	var/weights = list("Diamond" = 10, "Heart" = 8, "Cherry" = 8, "Bar" = 6, "Lemon" = 4, "Watermelon" = 2, "Seven" = 1)
	var/icon_type
	light_outer_range = 3
	light_color = "#E58B16"

/obj/structure/fake_machine/slotmachine/New()
	..()
	icon_type = initial(icon_state)

/obj/structure/fake_machine/slotmachine/Initialize()
	. = ..()
	jackpot = rand(500, 2000)
	plays = rand(10, 50)
	slots = list("1" = "Seven", "2" = "Seven", "3" = "Seven")
	update_icon()

/obj/structure/fake_machine/slotmachine/update_icon()
	overlays.Cut()
	var/offset = -6
	var/image/img
	for(var/slot in slots)
		img = new/image(icon, "slot_[slots[slot]]")
		img.pixel_x += offset
		overlays += img
		offset += 6

/obj/structure/fake_machine/slotmachine/proc/check_streak()
	var/win_slot = null
	for(var/slot in slots)
		if(isnull(win_slot))
			win_slot = slots[slot]
		else if(win_slot != slots[slot])
			return FALSE
	return TRUE

/obj/structure/fake_machine/slotmachine/proc/set_spin_ovarlay()
	for(var/slot in slots)
		slots[slot] = "spin"
	update_icon()

/obj/structure/fake_machine/slotmachine/proc/set_pull_overlay()
	icon_state = "[icon_type]_pull"
	update_icon()

/obj/structure/fake_machine/slotmachine/proc/set_slots_overlay(mob/user, fortune_total = 0, natural = null)
	var/last_slot = null
	var/match_chance = clamp(plays + max(0, fortune_total) * 2, 5, 95)
	if(natural == TRUE)
		match_chance = min(match_chance + 25, 98)
	else if(natural == FALSE)
		match_chance = max(match_chance - 20, 2)

	for(var/slot in slots)
		sleep(10)
		if(prob(match_chance) && !isnull(last_slot))
			plays = 0
			slots[slot] = last_slot
		else
			if(fortune_total >= 15 && prob(30))
				slots[slot] = pick(list("Diamond", "Heart", "Cherry", "Bar", "Seven"))
			else if(fortune_total <= 5 && prob(40))
				slots[slot] = pick(list("Lemon", "Watermelon", "Bar", "Cherry"))
			else
				slots[slot] = pick(variants)
			last_slot = slots[slot]
		icon_state = "[icon_type]"
		update_icon()
		src.visible_message(span_notice("The reel stops at... \the [slots[slot]]!"))
		playsound(src.loc, 'modular_rmh/sound/machines/ping.ogg', 50, 1)

/obj/structure/fake_machine/slotmachine/proc/dispense_coins(amount, atom/drop_location, mob/living/user = null)
	var/list/coin_types = list(
		/obj/item/coin/gold,
		/obj/item/coin/electrum,
		/obj/item/coin/silver,
		/obj/item/coin/copper
	)
	var/list/coin_values = list(100, 50, 10, 1)

	if(amount <= 0)
		return

	for(var/i in 1 to coin_types.len)
		var/coin_type = coin_types[i]
		var/coin_value = coin_values[i]
		var/coin_count = floor(amount / coin_value)

		while(coin_count > 0)
			var/stack_amount = min(coin_count, 20)
			var/atom/spawn_location = user ? user.loc : drop_location
			var/obj/item/coin/new_coin = new coin_type(spawn_location, stack_amount)

			if(user)
				user.put_in_hands(new_coin)

			coin_count -= stack_amount
			amount -= stack_amount * coin_value

/obj/structure/fake_machine/slotmachine/proc/check_win(mob/user, fortune_total = 0, natural = null)
	if(check_streak())
		playsound(src.loc, 'modular_rmh/sound/machines/jackpot.ogg', 50, 1)
		var/weight = weights[slots["1"]]
		var/prize = bet * weight          // Normal small/medium win

		if(weight == 1) // Three Sevens → Jackpot
			prize = jackpot
			jackpot = 0
			var/jackpot_msg
			if(natural == TRUE)
				jackpot_msg = "[span_bold(name)] states, \"JACKPOT!!! Tymora herself spins the reels for you!\""
			else if(fortune_total >= 18)
				jackpot_msg = "[span_bold(name)] states, \"JACKPOT!!! Fortune smiles so brightly the machine nearly bursts!\""
			else if(fortune_total <= 6)
				jackpot_msg = "[span_bold(name)] states, \"JACKPOT!!! Even the unluckiest dog can find a bone...\""
			else
				jackpot_msg = "[span_bold(name)] states, \"JACKPOT!!! Congratulations!\""
			src.visible_message(jackpot_msg)
		else
			// Normal win messages
			var/win_msg
			if(natural == TRUE)
				win_msg = "[span_bold(name)] states, \"Natural fortune! You won [prize] amnas!\""
			else if(fortune_total >= 16)
				win_msg = "[span_bold(name)] states, \"Tymora favors you! You won [prize] amnas!\""
			else if(fortune_total >= 12)
				win_msg = "[span_bold(name)] states, \"Lady Luck nods. You won [prize] amnas!\""
			else if(fortune_total <= 5)
				win_msg = "[span_bold(name)] states, \"Somehow... you still won [prize] amnas. Miracle.\""
			else
				win_msg = "[span_bold(name)] states, \"Congratulations! You won [prize] amnas!\""
			src.visible_message(win_msg)

		dispense_coins(prize, src.loc, isliving(user) ? user : null)
		return TRUE

	return FALSE

/obj/structure/fake_machine/slotmachine/proc/pull_leaver(mob/user, fortune_total = 0, natural = null)
	sleep(5)
	if(!check_win(user, fortune_total, natural))
		playsound(src.loc, 'sound/misc/machineno.ogg', 50, 1)
		var/lose_msg
		if(natural == FALSE)
			lose_msg = "[span_bold(name)] states, \"Natural 1... the reels spit in your face. Better luck never.\""
		else if(fortune_total <= 4)
			lose_msg = "[span_bold(name)] states, \"Your fortune is a dry well. Sorry...\""
		else if(fortune_total <= 8)
			lose_msg = "[span_bold(name)] states, \"The odds were never in your favor. Maybe next time..\""
		else if(fortune_total >= 16)
			lose_msg = "[span_bold(name)] states, \"Even strong fortune couldn't force these reels. Cruel.\""
		else
			lose_msg = "[span_bold(name)] states, \"Sorry, maybe next time..\""
		src.visible_message(lose_msg)
		jackpot += bet

/obj/structure/fake_machine/slotmachine/attack_hand(mob/user)
	if(spinning)
		to_chat(user, span_warning("It is currently spinning."))
		return

	if(bet == 0)
		to_chat(user, span_notice("Today's jackpot: [jackpot] amnas. Insert 1-100 amnas."))
		return

	spinning = TRUE
	plays++

	src.visible_message(span_notice("[name] states, \"Your bet is [bet] amnas. Good luck, buddy!\""))
	playsound(src.loc, 'sound/misc/letsgogambling.ogg', 50, 1)

	var/fortune_total = 0
	var/natural = null
	var/stat_value = 10
	var/modifier = 0
	var/trait_effect = 0

	if(isliving(user))
		var/mob/living/L = user
		stat_value = L.get_stat(STATKEY_LCK)
		modifier = stat_roll_modifier(stat_value)
		trait_effect = L.get_roll_trait_effect(STATKEY_LCK)
		var/die = rand(1, 20)
		fortune_total = die + modifier + trait_effect
		natural = natural_roll_outcome(die)

	set_spin_ovarlay()
	set_pull_overlay()
	set_slots_overlay(user, fortune_total, natural)
	pull_leaver(user, fortune_total, natural)

	src.add_fingerprint(user)
	update_icon()
	bet = 0
	spinning = FALSE

/obj/structure/fake_machine/slotmachine/attackby(obj/item/C, mob/user)
	if(spinning)
		return

	if(!istype(C, /obj/item/coin))
		return ..()

	var/obj/item/coin/cash = C
	var/coin_value = cash.sellprice * cash.quantity
	if(coin_value <= 0)
		to_chat(user, span_warning("This coin has no value to the machine."))
		return

	if(bet + coin_value > 100)
		to_chat(user, span_warning("You can bet up to 100 amnas. Your current bet is [bet], so this coin stack is too valuable."))
		return

	to_chat(user, span_notice("You insert [coin_value] amnas into [src]."))
	bet += coin_value
	qdel(cash)
	src.add_fingerprint(user)

// RMB = withdraw only the coins YOU inserted (bet)
/obj/structure/fake_machine/slotmachine/attack_hand_secondary(mob/living/user, params)
	if(spinning)
		to_chat(user, span_warning("You cannot withdraw money while the machine is spinning."))
		return

	if(!Adjacent(user))
		return

	if(bet <= 0)
		to_chat(user, span_warning("You have not inserted any coins to withdraw."))
		return

	var/list/withdrawal_options = list()
	if(bet >= 100)
		withdrawal_options += "GOLD (100 amnas)"
	if(bet >= 50)
		withdrawal_options += "ELECTRUM (50 amnas)"
	if(bet >= 10)
		withdrawal_options += "SILVER (10 amnas)"
	withdrawal_options += "COPPER (1 amna)"

	var/selection = input(user, "You currently have [bet] amnas inserted. Choose a coin denomination to withdraw.", src) as null|anything in withdrawal_options
	if(!selection)
		return

	var/coin_type
	var/coin_value
	switch(selection)
		if("GOLD (100 amnas)")
			coin_type = /obj/item/coin/gold
			coin_value = 100
		if("ELECTRUM (50 amnas)")
			coin_type = /obj/item/coin/electrum
			coin_value = 50
		if("SILVER (10 amnas)")
			coin_type = /obj/item/coin/silver
			coin_value = 10
		if("COPPER (1 amna)")
			coin_type = /obj/item/coin/copper
			coin_value = 1

	var/coin_amount = input(user, "You have [bet] amnas inserted. How many coins would you like to withdraw?", src) as null|num
	if(isnull(coin_amount))
		return

	coin_amount = round(coin_amount)
	if(coin_amount < 1)
		return

	if(!Adjacent(user) || spinning)
		return

	var/total_cost = coin_amount * coin_value
	if(total_cost > bet)
		to_chat(user, span_warning("You do not have enough inserted money for that withdrawal."))
		return

	var/remaining = coin_amount
	while(remaining > 0)
		var/stack_amount = min(remaining, 20)
		var/obj/item/coin/new_coin = new coin_type(user.loc, stack_amount)
		user.put_in_hands(new_coin)
		remaining -= stack_amount

	bet -= total_cost
	to_chat(user, span_notice("You withdraw [total_cost] amnas from [src]. Remaining inserted: [bet] amnas."))
	src.add_fingerprint(user)
