// Paying in coin: whole coins only, change given, all or nothing. Traders used to hand goods over unpaid.

/datum/unit_test/proc/coin_test_purse(mob/living/holder, coin_type, amount)
	var/obj/item/coin/coins = allocate(coin_type, null, amount)
	holder.put_in_hands(coins)
	return coins

/datum/unit_test/coin_payment_takes_whole_coins_and_gives_change

/datum/unit_test/coin_payment_takes_whole_coins_and_gives_change/Run()
	var/mob/living/carbon/human/rich = allocate(/mob/living/carbon/human/species/human/northern)
	var/mob/living/carbon/human/poor = allocate(/mob/living/carbon/human/species/human/northern)
	var/mob/living/carbon/human/mixed = allocate(/mob/living/carbon/human/species/human/northern)
	var/mob/living/carbon/human/stacked = allocate(/mob/living/carbon/human/species/human/northern)
	coin_test_purse(rich, /obj/item/coin/gold, 1)
	coin_test_purse(poor, /obj/item/coin/copper, 5)
	coin_test_purse(mixed, /obj/item/coin/copper, 3)
	coin_test_purse(mixed, /obj/item/coin/silver, 1)
	var/obj/item/coin/gold/stack = coin_test_purse(stacked, /obj/item/coin/gold, 3)
	// Change that does not fit in full hands lands at the feet, so count the whole floor they share.
	var/turf/floor = get_turf(rich)
	TEST_ASSERT(get_turf(poor) == floor && get_turf(mixed) == floor && get_turf(stacked) == floor, "Setup failed: the payers must share a floor.")

	var/before = get_mammons_in_atom(floor)
	var/rich_taken = remove_mammons_from_atom(rich, 15)
	var/rich_cost = before - get_mammons_in_atom(floor)
	before = get_mammons_in_atom(floor)
	var/poor_taken = remove_mammons_from_atom(poor, 10)
	var/poor_cost = before - get_mammons_in_atom(floor)
	before = get_mammons_in_atom(floor)
	var/mixed_taken = remove_mammons_from_atom(mixed, 5)
	var/mixed_cost = before - get_mammons_in_atom(floor)
	before = get_mammons_in_atom(floor)
	var/stacked_taken = remove_mammons_from_atom(stacked, 150)
	var/stacked_cost = before - get_mammons_in_atom(floor)

	// The old helper took nothing here, and every trader handed the goods over anyway.
	TEST_ASSERT_EQUAL(rich_taken, 15, "A gold piece must pay for something cheaper.")
	TEST_ASSERT_EQUAL(rich_cost, 15, "And cost exactly that: the rest comes back as change.")
	TEST_ASSERT_EQUAL(poor_taken, 0, "Five coppers must not pay ten.")
	TEST_ASSERT_EQUAL(poor_cost, 0, "A payment that cannot be made must take nothing.")
	TEST_ASSERT_EQUAL(mixed_taken, 5, "Mixed coins must pay together.")
	TEST_ASSERT_EQUAL(mixed_cost, 5, "And cost exactly the price.")
	TEST_ASSERT_EQUAL(get_mammons_in_atom(mixed), 8, "Small coins go first: the three coppers and the silver pay 13, and 8 comes back.")
	TEST_ASSERT_EQUAL(stacked_taken, 150, "A stack must pay more than one coin's worth.")
	TEST_ASSERT_EQUAL(stacked_cost, 150, "And cost exactly that.")
	// The old helper left a stack of 1.5 gold coins here.
	TEST_ASSERT(QDELETED(stack) || stack.quantity == round(stack.quantity), "No coin stack may be left with a fraction of a coin.")

/datum/unit_test/faction_trader_charges_what_it_asks

/datum/unit_test/faction_trader_charges_what_it_asks/Run()
	var/mob/living/carbon/human/trader_body = allocate(/mob/living/carbon/human/species/human/northern)
	var/mob/living/carbon/human/customer = allocate(/mob/living/carbon/human/species/human/northern)
	trader_body.AddComponent(/datum/component/trader, null, new /datum/trader_data())
	var/datum/component/trader/trader = trader_body.GetComponent(/datum/component/trader)
	TEST_ASSERT_NOTNULL(trader, "Setup failed: the trader component must attach.")
	coin_test_purse(customer, /obj/item/coin/gold, 1)
	var/turf/floor = get_turf(customer)

	var/before = get_mammons_in_atom(floor)
	var/paid = trader.spend_buyer_offhand_money(customer, 15)
	var/cost = before - get_mammons_in_atom(floor)

	TEST_ASSERT(paid, "A gold piece must buy a fifteen-mammon ware.")
	TEST_ASSERT_EQUAL(cost, 15, "The trader must take 15 and give the rest back, not hand the ware over free.")
