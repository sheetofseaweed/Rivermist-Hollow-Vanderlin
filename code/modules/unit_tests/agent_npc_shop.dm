// Shops: the endless supplier, the dealer's real goods and purse, haggling, and the stall in the scene.

/// A bound pawn keeping a shop of this kind.
/datum/unit_test/proc/agent_test_shopkeeper(stock_type)
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	pawn.AddComponent(/datum/component/agent_shop, stock_type)
	return pawn

/// A supplier whose one ware is cloth, from a ten-mammon pack, so prices do not ride the live market.
/proc/agent_test_cloth_supplier(datum/component/agent_shop/shop)
	var/datum/agent_stock/supplier/stock = shop.stock
	var/datum/supply_pack/pack = new()
	pack.cost = 10
	pack.contains = /obj/item/natural/cloth
	stock.catalog = list(/obj/item/natural/cloth = pack)
	return stock

/datum/unit_test/proc/agent_test_coins(mob/living/holder, coin_type, amount)
	var/obj/item/coin/coins = allocate(coin_type, null, amount)
	holder.put_in_hands(coins)
	return coins

/// Things of this type the mob holds, carries or stands on. Bought goods land in hand or at the feet.
/proc/agent_test_count_near(mob/living/who, type)
	. = 0
	var/turf/floor = get_turf(who)
	for(var/atom/movable/thing in who.GetAllContents() + floor.contents)
		if(istype(thing, type))
			.++

// ------------------------------------------------------------------ the supplier

/datum/unit_test/agent_shop_supplier_sells_endlessly

/datum/unit_test/agent_shop_supplier_sells_endlessly/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_shopkeeper(/datum/agent_stock/supplier)
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/component/agent_shop/shop = pawn.GetComponent(/datum/component/agent_shop)
	var/mob/living/carbon/human/customer = allocate(/mob/living/carbon/human/species/human/northern)
	var/obj/item/natural/cloth/scrap = allocate(/obj/item/natural/cloth)
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	TEST_ASSERT_NOTNULL(shop, "Setup failed: the pawn must keep a shop.")
	agent_test_cloth_supplier(shop)
	agent_test_coins(customer, /obj/item/coin/silver, 4)
	controller.binding.take_events()

	var/price = shop.price_for(customer, /obj/item/natural/cloth)
	var/cloth_before = agent_test_count_near(customer, /obj/item/natural/cloth)
	var/first = shop.sell_to(customer, /obj/item/natural/cloth)
	var/second = shop.sell_to(customer, /obj/item/natural/cloth)
	var/cloth_after = agent_test_count_near(customer, /obj/item/natural/cloth)
	var/money_left = get_mammons_in_atom(customer)
	var/list/events = controller.binding.take_events()
	var/list/trades = agent_test_events_named(events, AGENT_EVENT_TRADE)
	var/third = shop.sell_to(customer, /obj/item/natural/cloth)
	var/cloth_unpaid = agent_test_count_near(customer, /obj/item/natural/cloth)
	var/money_unpaid = get_mammons_in_atom(customer)
	var/list/refusals = agent_test_events_named(controller.binding.take_events(), AGENT_EVENT_TRADE_REFUSED)
	// Asked of the stock: the customer's hands are full of change by now, which would refuse for another reason.
	var/sold_back = shop.stock.buy_refusal(scrap)
	var/buys_anything = shop.stock.buys_text()
	var/datum/agent_stock/supplier/food/market = new(null)
	var/market_wares = length(market.wares())
	qdel(market)
	agent_test_restore_subsystem(saved, controller.binding)

	TEST_ASSERT_EQUAL(price, 15, "A ten-mammon pack of one sells for half as much again.")
	TEST_ASSERT_NULL(first, "The first sale must go through.")
	TEST_ASSERT_NULL(second, "An endless stock must sell the same thing again.")
	TEST_ASSERT_EQUAL(cloth_after - cloth_before, 2, "Each sale must put the ware with the buyer.")
	TEST_ASSERT_EQUAL(money_left, 10, "Two sales at 15 must take 30 of 40.")
	TEST_ASSERT_EQUAL(length(trades), 2, "Each sale must reach the model.")
	TEST_ASSERT_NOTNULL(third, "Ten mammons must not buy a fifteen-mammon ware.")
	TEST_ASSERT_EQUAL(cloth_unpaid, cloth_after, "Nothing must be handed over unpaid.")
	TEST_ASSERT_EQUAL(money_unpaid, 10, "And nothing taken.")
	TEST_ASSERT_EQUAL(length(refusals), 1, "The model must hear that the customer could not pay.")
	TEST_ASSERT_NOTNULL(sold_back, "A supplier must not buy: with endless stock and coin from nowhere it would print money.")
	TEST_ASSERT_NULL(buys_anything, "Nor offer to, so the menu shows no Sell.")
	TEST_ASSERT(market_wares > 0, "A supplier must find its wares among the town's supply packs.")

// ------------------------------------------------------------------ the dealer

/datum/unit_test/agent_shop_dealer_buys_and_resells_real_goods

/datum/unit_test/agent_shop_dealer_buys_and_resells_real_goods/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_shopkeeper(/datum/agent_stock/dealer)
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/component/agent_shop/shop = pawn.GetComponent(/datum/component/agent_shop)
	var/datum/agent_stock/dealer/stock = shop?.stock
	var/mob/living/carbon/human/seller = allocate(/mob/living/carbon/human/species/human/northern)
	var/mob/living/carbon/human/buyer = allocate(/mob/living/carbon/human/species/human/northern)
	var/obj/item/natural/cloth/ware = allocate(/obj/item/natural/cloth)
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	TEST_ASSERT(istype(stock), "Setup failed: the shop must be a dealer.")
	ware.sellprice = 40
	TEST_ASSERT_EQUAL(ware.get_real_price(), 40, "Setup failed: the ware must be worth 40.")
	stock.purse = 100
	seller.put_in_hands(ware)
	agent_test_coins(buyer, /obj/item/coin/gold, 1)
	controller.binding.take_events()

	var/offered = shop.offer_for(seller, ware)
	var/bought = shop.buy_from(seller, ware)
	var/stocked = (ware in stock.wares()) && ware.loc == stock.stockroom
	var/purse_after_buying = stock.purse
	var/seller_paid = get_mammons_in_atom(seller)
	var/asking = shop.price_for(buyer, ware)
	var/sold = shop.sell_to(buyer, ware)
	var/with_buyer = (ware in buyer.held_items) || ware.loc == get_turf(buyer)
	var/list/trades = agent_test_events_named(controller.binding.take_events(), AGENT_EVENT_TRADE)
	agent_test_restore_subsystem(saved, controller.binding)

	TEST_ASSERT_EQUAL(offered, 20, "A dealer pays half of what a thing is worth.")
	TEST_ASSERT_NULL(bought, "The dealer must buy it.")
	TEST_ASSERT(stocked, "A bought item must go into stock, the real item and not a copy.")
	TEST_ASSERT_EQUAL(purse_after_buying, 80, "Buying must come out of the purse.")
	TEST_ASSERT_EQUAL(seller_paid, 20, "The seller must be paid.")
	TEST_ASSERT_EQUAL(asking, 40, "A dealer asks the whole worth.")
	TEST_ASSERT_NULL(sold, "The dealer must sell it on.")
	TEST_ASSERT(with_buyer, "The very same item must go to the buyer.")
	TEST_ASSERT_EQUAL(stock.purse, 120, "Selling must refill the purse.")
	TEST_ASSERT(!(ware in stock.wares()), "A sold item must leave the stock.")
	TEST_ASSERT_EQUAL(length(trades), 2, "Both trades must reach the model.")
	var/list/first = trades[1]
	var/list/detail = first["detail"]
	TEST_ASSERT_EQUAL(detail["what"], "sold", "The first trade was the seller selling to the dealer.")
	TEST_ASSERT_EQUAL(detail["price"], 20, "And it must carry the price.")

/datum/unit_test/agent_shop_dealer_refuses_what_it_should

/datum/unit_test/agent_shop_dealer_refuses_what_it_should/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_shopkeeper(/datum/agent_stock/dealer)
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/component/agent_shop/shop = pawn.GetComponent(/datum/component/agent_shop)
	var/datum/agent_stock/dealer/stock = shop?.stock
	var/mob/living/carbon/human/seller = allocate(/mob/living/carbon/human/species/human/northern)
	var/obj/item/coin/silver/coin = allocate(/obj/item/coin/silver, null, 1)
	var/obj/item/natural/cloth/worthless = allocate(/obj/item/natural/cloth)
	var/obj/item/natural/cloth/outer = allocate(/obj/item/natural/cloth)
	var/obj/item/natural/cloth/inner = allocate(/obj/item/natural/cloth)
	var/obj/item/natural/cloth/dear = allocate(/obj/item/natural/cloth)
	TEST_ASSERT(istype(stock), "Setup failed: the shop must be a dealer.")
	worthless.sellprice = 0
	outer.sellprice = 10
	inner.forceMove(outer)
	dear.sellprice = 1000
	stock.purse = 100

	var/coin_refusal = stock.buy_refusal(coin)
	var/worthless_refusal = stock.buy_refusal(worthless)
	var/nested_refusal = stock.buy_refusal(outer)
	seller.put_in_hands(dear)
	var/dear_refusal = shop.buy_from(seller, dear)
	var/kept = (dear in seller.held_items)
	stock.max_wares = 0
	var/full_refusal = stock.buy_refusal(dear)
	agent_test_restore_subsystem(saved, controller.binding)

	TEST_ASSERT_NOTNULL(coin_refusal, "Coin must not be bought with coin.")
	TEST_ASSERT_NOTNULL(worthless_refusal, "Nothing must be paid for the worthless.")
	TEST_ASSERT_NOTNULL(nested_refusal, "What is inside an item must not ride along unpriced.")
	TEST_ASSERT_NOTNULL(dear_refusal, "The dealer must not pay more than its purse holds.")
	TEST_ASSERT(kept, "A refused item must stay with its owner.")
	TEST_ASSERT_EQUAL(stock.purse, 100, "A refused trade must not touch the purse.")
	TEST_ASSERT_NOTNULL(full_refusal, "A full stock must refuse more.")

/datum/unit_test/agent_shop_no_discount_makes_a_coin_mill

/datum/unit_test/agent_shop_no_discount_makes_a_coin_mill/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_shopkeeper(/datum/agent_stock/dealer)
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/component/agent_shop/shop = pawn.GetComponent(/datum/component/agent_shop)
	var/datum/agent_stock/dealer/stock = shop?.stock
	var/mob/living/carbon/human/favourite = allocate(/mob/living/carbon/human/species/human/northern)
	var/obj/item/natural/cloth/ware = allocate(/obj/item/natural/cloth)
	TEST_ASSERT(istype(stock), "Setup failed: the shop must be a dealer.")
	ware.sellprice = 40
	// A greedy mapping: the dealer pays nearly full worth.
	stock.buy_ratio = 0.9
	stock.purse = 1000
	shop.set_discount(favourite, AGENT_SHOP_MAX_DISCOUNT)

	var/paid_for_it = shop.offer_for(favourite, ware)
	favourite.put_in_hands(ware)
	shop.buy_from(favourite, ware)
	var/asked_back = shop.price_for(favourite, ware)
	agent_test_restore_subsystem(saved, controller.binding)

	TEST_ASSERT(asked_back > paid_for_it, "Selling the same thing back and forth must never pay, at any discount.")

// ------------------------------------------------------------------ haggling

/datum/unit_test/agent_shop_haggle_through_dispatch

/datum/unit_test/agent_shop_haggle_through_dispatch/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_shopkeeper(/datum/agent_stock/supplier)
	var/mob/living/carbon/human/species/human/northern/agent_social/plain = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/ai_controller/agent_social/plain_controller = plain.ai_controller
	var/datum/agent_binding/binding = controller?.binding
	var/datum/component/agent_shop/shop = pawn.GetComponent(/datum/component/agent_shop)
	var/mob/living/carbon/human/customer = allocate(/mob/living/carbon/human/species/human/northern)
	TEST_ASSERT_NOTNULL(binding, "Setup failed: the pawn must be bound.")
	TEST_ASSERT_NOTNULL(plain_controller?.binding, "Setup failed: the plain pawn must be bound.")
	agent_test_cloth_supplier(shop)

	var/handle = agent_test_handle_of(binding, pawn, customer)
	SSagent_npc.dispatch_decision(binding, agent_test_decision(list("name" = "haggle", "handle" = handle, "key" = "10")))
	var/haggled = shop.discount_for(customer)
	var/haggled_price = shop.price_for(customer, /obj/item/natural/cloth)
	SSagent_npc.dispatch_decision(binding, agent_test_decision(list("name" = "haggle", "handle" = handle, "key" = "50")))
	var/half_price = shop.price_for(customer, /obj/item/natural/cloth)
	binding.take_events()
	SSagent_npc.dispatch_decision(binding, agent_test_decision(list("name" = "haggle", "handle" = handle, "key" = "90%")))
	var/clamped = shop.discount_for(customer)
	var/list/clamp_results = agent_test_events_named(binding.take_events(), "action_result")
	SSagent_npc.dispatch_decision(binding, agent_test_decision(list("name" = "haggle", "handle" = handle, "key" = "")))
	var/list/blank_results = agent_test_events_named(binding.take_events(), "action_result")
	var/after_blank = shop.discount_for(customer)
	SSagent_npc.dispatch_decision(binding, agent_test_decision(list("name" = "haggle", "handle" = handle, "key" = "0")))
	var/taken_back = shop.discount_for(customer)
	var/list/shop_payload = binding.profile_payload()
	var/list/plain_payload = plain_controller.binding.profile_payload()
	var/list/shop_actions = shop_payload["permitted_actions"]
	var/list/plain_actions = plain_payload["permitted_actions"]
	var/plain_may = plain_controller.binding.profile_permits("haggle")
	agent_test_restore_subsystem(saved, binding)
	agent_test_restore_subsystem(saved, plain_controller.binding)

	TEST_ASSERT_EQUAL(haggled, 10, "Haggling must set the customer's discount.")
	TEST_ASSERT_EQUAL(haggled_price, 14, "Ten percent off 15 is 13.5, rounded up.")
	// A live model said fifty percent while the old twenty percent cap charged otherwise, and nobody was told.
	TEST_ASSERT_EQUAL(half_price, 8, "Half off must be half off: 15 halved rounds up to 8.")
	TEST_ASSERT_EQUAL(clamped, AGENT_SHOP_MAX_DISCOUNT, "No discount may pass the cap, whatever the model asks.")
	TEST_ASSERT_EQUAL(length(clamp_results), 1, "Setup failed: the capped haggle must report back.")
	var/list/clamp_entry = clamp_results[1]
	var/list/clamp_detail = clamp_entry["detail"]
	TEST_ASSERT(findtext(clamp_detail["detail"], "the most you can give"), "A capped haggle must say so, or the model quotes a price the stall does not charge.")
	TEST_ASSERT_EQUAL(length(blank_results), 1, "Setup failed: the blank haggle must report back.")
	var/list/blank_entry = blank_results[1]
	var/list/blank_detail = blank_entry["detail"]
	TEST_ASSERT_EQUAL(blank_detail["state"], AGENT_RESULT_REJECTED, "A haggle without a percent must be refused, not read as zero.")
	TEST_ASSERT_EQUAL(after_blank, AGENT_SHOP_MAX_DISCOUNT, "A refused haggle must leave the discount alone.")
	TEST_ASSERT_EQUAL(taken_back, 0, "Zero takes a discount back.")
	TEST_ASSERT("haggle" in shop_actions, "A shopkeeper must be told it can haggle.")
	TEST_ASSERT(!("haggle" in plain_actions), "Nobody else may be told so.")
	TEST_ASSERT(!plain_may, "Nor allowed to.")

// ------------------------------------------------------------------ the stall and the agent

/datum/unit_test/agent_shop_will_not_serve_aggressors

/datum/unit_test/agent_shop_will_not_serve_aggressors/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_shopkeeper(/datum/agent_stock/supplier)
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/component/agent_shop/shop = pawn.GetComponent(/datum/component/agent_shop)
	var/mob/living/carbon/human/brute = allocate(/mob/living/carbon/human/species/human/northern)
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human/species/human/northern)
	agent_test_cloth_supplier(shop)
	agent_test_coins(brute, /obj/item/coin/gold, 1)

	controller.note_aggressor(brute)
	var/refused = shop.sell_to(brute, /obj/item/natural/cloth)
	var/money_kept = get_mammons_in_atom(brute)
	var/stranger_welcome = isnull(shop.refusal_for(stranger))
	agent_test_restore_subsystem(saved, controller.binding)

	TEST_ASSERT_NOTNULL(refused, "Whoever hit the keeper must not be served.")
	TEST_ASSERT_EQUAL(money_kept, 100, "And must not be charged.")
	TEST_ASSERT(stranger_welcome, "Everyone else is still served.")

/datum/unit_test/agent_shop_customers_reach_the_agent

/datum/unit_test/agent_shop_customers_reach_the_agent/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_shopkeeper(/datum/agent_stock/supplier)
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/agent_binding/binding = controller?.binding
	var/datum/component/agent_shop/shop = pawn.GetComponent(/datum/component/agent_shop)
	var/mob/living/carbon/human/customer = allocate(/mob/living/carbon/human/species/human/northern)
	var/mob/living/carbon/human/regular = allocate(/mob/living/carbon/human/species/human/northern)
	TEST_ASSERT_NOTNULL(binding, "Setup failed: the pawn must be bound.")
	binding.take_events()

	// No client can open a menu, so another NPC's hand stays a touch.
	customer.used_intent = new /datum/intent/unarmed/help(customer)
	var/clientless_shops = shop.wants_click(customer)
	SEND_SIGNAL(pawn, COMSIG_ATOM_ATTACK_HAND, customer, null)
	var/list/touches = agent_test_events_named(binding.take_events(), "physical")
	customer.used_intent = null

	binding.dirty = FALSE
	controller.note_shop_event(AGENT_EVENT_CUSTOMER, customer)
	controller.note_shop_event(AGENT_EVENT_CUSTOMER, customer)
	var/stranger_bought_a_turn = binding.dirty
	var/list/browsing = agent_test_events_named(binding.take_events(), AGENT_EVENT_CUSTOMER)
	binding.note_candidate(regular)
	binding.engage_candidate()
	binding.dirty = FALSE
	controller.note_shop_event(AGENT_EVENT_CUSTOMER, regular)
	var/regular_bought_a_turn = binding.dirty
	var/list/regular_browsing = agent_test_events_named(binding.take_events(), AGENT_EVENT_CUSTOMER)
	agent_test_restore_subsystem(saved, binding)

	TEST_ASSERT(!clientless_shops, "Only a player can open the stall.")
	TEST_ASSERT_EQUAL(length(touches), 1, "An NPC's hand on a shopkeeper must stay a touch.")
	TEST_ASSERT(stranger_bought_a_turn, "A new customer is worth a greeting.")
	TEST_ASSERT_EQUAL(length(browsing), 1, "Browsing twice is one event with a count.")
	var/list/browse_entry = browsing[1]
	var/list/browse_detail = browse_entry["detail"]
	TEST_ASSERT_EQUAL(browse_detail["count"], 2, "And it must say twice.")
	TEST_ASSERT(!regular_bought_a_turn, "Someone it is already talking to must not buy a second turn by browsing.")
	TEST_ASSERT_EQUAL(length(regular_browsing), 1, "But the NPC must still learn of it.")

/datum/unit_test/agent_shop_dealer_spills_its_goods_on_death

/datum/unit_test/agent_shop_dealer_spills_its_goods_on_death/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_shopkeeper(/datum/agent_stock/dealer)
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/component/agent_shop/shop = pawn.GetComponent(/datum/component/agent_shop)
	var/datum/agent_stock/dealer/stock = shop?.stock
	var/obj/item/natural/cloth/ware = allocate(/obj/item/natural/cloth)
	TEST_ASSERT(istype(stock), "Setup failed: the shop must be a dealer.")
	var/turf/floor = get_turf(pawn)
	ware.sellprice = 40
	stock.take_in(ware, 0)
	stock.purse = 50
	var/coin_before = get_mammons_in_atom(floor)

	pawn.death()
	var/died = pawn.stat == DEAD
	var/ware_dropped = ware.loc == floor
	var/coin_dropped = get_mammons_in_atom(floor) - coin_before
	agent_test_restore_subsystem(saved, controller.binding)

	TEST_ASSERT(died, "Setup failed: the keeper must die.")
	TEST_ASSERT(ware_dropped, "A dead dealer's goods must fall where it fell, not vanish.")
	TEST_ASSERT_EQUAL(coin_dropped, 50, "So must its purse.")
	TEST_ASSERT_EQUAL(length(stock.wares()), 0, "Nothing is left in stock.")

/datum/unit_test/agent_shop_scene_shows_the_stall

/datum/unit_test/agent_shop_scene_shows_the_stall/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_shopkeeper(/datum/agent_stock/dealer)
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/component/agent_shop/shop = pawn.GetComponent(/datum/component/agent_shop)
	var/datum/agent_stock/dealer/stock = shop?.stock
	var/mob/living/carbon/human/customer = allocate(/mob/living/carbon/human/species/human/northern)
	var/obj/item/natural/cloth/ware = allocate(/obj/item/natural/cloth)
	TEST_ASSERT(istype(stock), "Setup failed: the shop must be a dealer.")
	ware.sellprice = 40
	stock.take_in(ware, 0)
	stock.purse = 60
	shop.set_discount(customer, 10)

	var/list/built = agent_build_observation(pawn, 1)
	var/list/payload = built["payload"]
	var/list/myself = payload["self"]
	var/list/described = myself["shop"]
	agent_test_restore_subsystem(saved, controller.binding)

	TEST_ASSERT_NOTNULL(described, "A shopkeeper must see its stall.")
	TEST_ASSERT_EQUAL(described["kind"], "dealer", "And what kind of trader it is.")
	var/list/selling = described["selling"]
	TEST_ASSERT_EQUAL(length(selling), 1, "Its wares must be listed.")
	var/list/first = selling[1]
	TEST_ASSERT_EQUAL(first["price"], 40, "With their prices.")
	TEST_ASSERT_EQUAL(described["purse"], 60, "A dealer must know its purse, or it cannot judge an offer.")
	TEST_ASSERT_NOTNULL(described["buys"], "And what it buys.")
	var/list/discounts = described["discounts"]
	TEST_ASSERT_EQUAL(discounts?[customer.get_visible_name()], 10, "And who it gave a deal.")

// ------------------------------------------------------------------ setting shops up

/datum/unit_test/agent_shop_can_be_set_swapped_and_removed

/datum/unit_test/agent_shop_can_be_set_swapped_and_removed/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/obj/item/natural/cloth/ware = allocate(/obj/item/natural/cloth)
	var/turf/floor = get_turf(pawn)

	var/set_refusal = agent_set_shop(pawn, /datum/agent_stock/dealer)
	var/datum/component/agent_shop/first = pawn.GetComponent(/datum/component/agent_shop)
	var/datum/agent_stock/dealer/first_stock = first?.stock
	TEST_ASSERT(istype(first_stock), "Setup failed: the first shop must be a dealer.")
	first_stock.take_in(ware, 0)
	var/swap_refusal = agent_set_shop(pawn, /datum/agent_stock/supplier/food)
	var/datum/component/agent_shop/second = pawn.GetComponent(/datum/component/agent_shop)
	var/swapped_to_supplier = istype(second?.stock, /datum/agent_stock/supplier/food)
	var/goods_dropped = ware.loc == floor
	agent_set_shop(pawn, null)
	var/removed = isnull(pawn.GetComponent(/datum/component/agent_shop))
	var/nonsense_refusal = agent_set_shop(pawn, /datum/agent_profile/merchant)
	agent_test_restore_subsystem(saved, controller.binding)

	TEST_ASSERT_NULL(set_refusal, "A shop must be settable on a living NPC.")
	TEST_ASSERT_NULL(swap_refusal, "And swappable.")
	TEST_ASSERT(swapped_to_supplier, "A swap must leave the new kind of shop, not the old one.")
	TEST_ASSERT(goods_dropped, "A dealer swapped away must drop its goods, not delete them.")
	TEST_ASSERT(removed, "Null must remove the shop.")
	TEST_ASSERT_NOTNULL(nonsense_refusal, "Anything but a kind of shop must be refused.")

/datum/unit_test/agent_shop_every_offered_shop_works

/datum/unit_test/agent_shop_every_offered_shop_works/Run()
	var/offered = 0
	for(var/datum/agent_stock/stock_type as anything in subtypesof(/datum/agent_stock))
		if(!initial(stock_type.shop_label))
			continue
		offered++
		var/datum/agent_stock/stock = new stock_type(null)
		// Admins pick these from a list. Each must either sell something or buy something.
		TEST_ASSERT(length(stock.wares()) || stock.buys_text(), "[stock_type] is offered to admins but neither sells nor buys.")
		qdel(stock)
	TEST_ASSERT(offered >= 4, "The grocer, toolseller, clothier and pawnbroker must all be offered.")
	var/datum/agent_stock/supplier/bare = /datum/agent_stock/supplier
	TEST_ASSERT_NULL(initial(bare.shop_label), "A supplier with no packs must not be offered.")

// ------------------------------------------------------------------ knowing what the stall will do

/datum/unit_test/agent_shop_refusals_reach_the_model

/datum/unit_test/agent_shop_refusals_reach_the_model/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_shopkeeper(/datum/agent_stock/dealer)
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/component/agent_shop/shop = pawn.GetComponent(/datum/component/agent_shop)
	var/mob/living/carbon/human/seller = allocate(/mob/living/carbon/human/species/human/northern)
	var/obj/item/natural/cloth/stick = allocate(/obj/item/natural/cloth)
	TEST_ASSERT_NOTNULL(controller?.binding, "Setup failed: the pawn must be bound.")
	stick.sellprice = 0
	seller.put_in_hands(stick)
	controller.binding.take_events()

	var/told_seller = shop.buy_from(seller, stick)
	var/list/refusals = agent_test_events_named(controller.binding.take_events(), AGENT_EVENT_TRADE_REFUSED)
	agent_test_restore_subsystem(saved, controller.binding)

	// A live model promised to buy a worthless item; the stall refused it without a word to the model.
	TEST_ASSERT(findtext(told_seller, "it is worthless"), "The seller must be told why.")
	TEST_ASSERT_EQUAL(length(refusals), 1, "So must the model.")
	var/list/entry = refusals[1]
	var/list/detail = entry["detail"]
	TEST_ASSERT_EQUAL(detail["what"], "sell", "As a refused sale.")
	TEST_ASSERT_EQUAL(detail["reason"], "it is worthless", "With the reason.")

/datum/unit_test/agent_shop_keeper_sees_what_customers_could_sell

/datum/unit_test/agent_shop_keeper_sees_what_customers_could_sell/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_shopkeeper(/datum/agent_stock/dealer)
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/mob/living/carbon/human/near = allocate(/mob/living/carbon/human/species/human/northern)
	var/mob/living/carbon/human/far = allocate(/mob/living/carbon/human/species/human/northern, run_loc_floor_top_right)
	var/obj/item/natural/cloth/sword = allocate(/obj/item/natural/cloth)
	var/obj/item/natural/cloth/stick = allocate(/obj/item/natural/cloth)
	var/obj/item/natural/cloth/far_ware = allocate(/obj/item/natural/cloth)
	TEST_ASSERT(get_dist(pawn, far) > AGENT_SHOP_OFFER_RANGE, "Setup failed: one customer must stand beyond the stall.")
	sword.sellprice = 40
	stick.sellprice = 0
	far_ware.sellprice = 40
	near.put_in_hands(sword)
	near.put_in_hands(stick)
	far.put_in_hands(far_ware)

	var/list/built = agent_build_observation(pawn, 1)
	var/list/payload = built["payload"]
	var/list/near_entry
	var/list/far_entry
	for(var/list/entity as anything in payload["entities"])
		if(entity["name"] == near.get_visible_name())
			near_entry = entity
		if(entity["name"] == far.get_visible_name())
			far_entry = entity
	agent_test_restore_subsystem(saved, controller.binding)

	TEST_ASSERT_NOTNULL(near_entry, "Setup failed: the near customer must be in the scene.")
	TEST_ASSERT_NOTNULL(far_entry, "Setup failed: the far customer must be in the scene.")
	var/list/offers = near_entry["offers"]
	TEST_ASSERT_EQUAL(length(offers), 2, "Each thing a customer at the stall holds must be priced.")
	var/list/first = offers[1]
	var/list/second = offers[2]
	var/list/priced = first["offer"] ? first : second
	var/list/refused = first["offer"] ? second : first
	TEST_ASSERT_EQUAL(priced["offer"], 20, "With what the keeper would really pay.")
	TEST_ASSERT_EQUAL(refused["refused"], "it is worthless", "Or why it would not buy it.")
	TEST_ASSERT_NULL(far_entry["offers"], "Nobody beyond the stall is priced; it costs tokens and they are not customers.")

/datum/unit_test/agent_shop_big_discounts_stop_at_cost

/datum/unit_test/agent_shop_big_discounts_stop_at_cost/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_shopkeeper(/datum/agent_stock/dealer)
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	var/datum/component/agent_shop/shop = pawn.GetComponent(/datum/component/agent_shop)
	var/datum/agent_stock/dealer/stock = shop?.stock
	var/mob/living/carbon/human/friend = allocate(/mob/living/carbon/human/species/human/northern)
	var/obj/item/natural/cloth/bought_cheap = allocate(/obj/item/natural/cloth)
	var/obj/item/natural/cloth/bought_dear = allocate(/obj/item/natural/cloth)
	TEST_ASSERT(istype(stock), "Setup failed: the shop must be a dealer.")
	bought_cheap.sellprice = 40
	bought_dear.sellprice = 40
	stock.take_in(bought_cheap, 10)
	stock.take_in(bought_dear, 30)
	shop.set_discount(friend, 50)

	var/cheap_price = shop.price_for(friend, bought_cheap)
	var/dear_price = shop.price_for(friend, bought_dear)
	agent_test_restore_subsystem(saved, controller.binding)

	TEST_ASSERT_EQUAL(cheap_price, 20, "Half off a 40-mammon ware bought for 10 is a real half off.")
	TEST_ASSERT_EQUAL(dear_price, 31, "But never below what the keeper paid for it.")
