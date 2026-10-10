// Agent NPC shops. DM runs every trade through a menu; the model only talks and haggles.

/// Granted by having a shop, the way combat limits grant fight and stop.
GLOBAL_LIST_INIT(agent_shop_actions, list("haggle"))

/// A price in the town's coin.
/proc/agent_amnas(amount)
	return "[amount] amna[amount == 1 ? "" : "s"]"

/// The first whole number in text, or null. Models write "10", "10%" or "-5".
/proc/agent_parse_percent(text)
	var/static/regex/whole_number = regex(@"-?\d+")
	if(isnum(text))
		return round(text, 1)
	if(!istext(text) || !whole_number.Find(text))
		return null
	return text2num(whole_number.match)

/// What a shop sells and buys. Subtypes decide where goods and coin come from.
/datum/agent_stock
	/// Told to the model, so it knows what kind of trader it is.
	var/kind = "trader"
	/// Shown to admins choosing a shop. Null on types too incomplete to use.
	var/shop_label
	/// What a sale is called in the event the model gets.
	var/sold_verb = "bought"
	var/mob/living/keeper

/datum/agent_stock/New(mob/living/new_keeper)
	keeper = new_keeper

/datum/agent_stock/Destroy(force)
	keeper = null
	return ..()

/// Everything on sale: typepaths for a catalog, the items themselves for real goods.
/datum/agent_stock/proc/wares()
	return list()

/datum/agent_stock/proc/ware_name(ware)
	return "something"

/// The asking price before any haggling, or null if it is not for sale.
/datum/agent_stock/proc/ware_price(ware)
	return null

/// Haggling never takes a price below this.
/datum/agent_stock/proc/price_floor(ware)
	return 1

/datum/agent_stock/proc/ware_image(ware)
	return null

/// Put the ware in the buyer's hands. Returns the item, or null if it is gone.
/datum/agent_stock/proc/hand_over(ware, mob/living/buyer)
	return null

/// Coin from a sale. A catalog lets it vanish; a dealer keeps it to buy with.
/datum/agent_stock/proc/receive(amount)
	return

/// Why it will not buy this item, or null if it will.
/datum/agent_stock/proc/buy_refusal(obj/item/offered)
	return "this shop only sells"

/// What it pays for an item before haggling.
/datum/agent_stock/proc/worth_offered(obj/item/offered)
	return 0

/datum/agent_stock/proc/take_in(obj/item/offered, price)
	return

/// What it buys, as a phrase for the model, or null if it buys nothing.
/datum/agent_stock/proc/buys_text()
	return null

/// Coin it can buy with, or null where coin never runs out.
/datum/agent_stock/proc/purse_amount()
	return null

/// The keeper fell. Whatever it really held goes to the floor.
/datum/agent_stock/proc/spill(turf/where)
	return

/// Why this customer cannot buy right now, as words after the keeper's name, or null.
/datum/agent_stock/proc/sale_refusal(mob/living/customer)
	return null

/// Extra menu choices for this customer, label -> image, or null.
/datum/agent_stock/proc/menu_extras(mob/living/customer)
	return null

/// Act on a choice from menu_extras.
/datum/agent_stock/proc/pick_extra(choice, mob/living/customer)
	return

/// More for the model to know about this shop, merged into its description, or null.
/datum/agent_stock/proc/describe_extra()
	return null

/// Sells goods from the town's supply packs at their live price plus a markup. Never runs out, never buys.
/datum/agent_stock/supplier
	kind = "supplier"
	/// Supply pack types it sells from; every pack under them counts.
	var/list/pack_types = list()
	/// Over the import cost, so players who import goods themselves can undercut it.
	var/markup = 1.5
	/// item type -> its supply pack. Built on first use: SSmerchant makes its packs after the map loads.
	var/list/catalog

/datum/agent_stock/supplier/Destroy(force)
	catalog = null
	return ..()

/datum/agent_stock/supplier/proc/build_catalog()
	catalog = list()
	for(var/pack_type in SSmerchant.supply_packs)
		var/datum/supply_pack/pack = SSmerchant.supply_packs[pack_type]
		if(pack.hidden || pack.contraband || !is_type_in_list(pack, pack_types))
			continue
		var/list/contents = islist(pack.contains) ? pack.contains : list(pack.contains)
		for(var/item_type in contents)
			if(ispath(item_type, /obj/item) && !catalog[item_type])
				catalog[item_type] = pack

/datum/agent_stock/supplier/wares()
	if(!length(catalog))
		build_catalog()
	return catalog

/datum/agent_stock/supplier/ware_name(ware)
	var/datum/supply_pack/pack = catalog?[ware]
	// A single-item pack is named for what it holds, and better than the item's own generic name.
	if(pack && !islist(pack.contains))
		return LOWER_TEXT(pack.name)
	var/obj/item/item_type = ware
	return initial(item_type.name)

/datum/agent_stock/supplier/ware_price(ware)
	var/datum/supply_pack/pack = catalog?[ware]
	if(!pack)
		return null
	var/count = islist(pack.contains) ? max(1, length(pack.contains)) : 1
	var/cost = pack.cost || pack.baseline_price || 20
	return max(1, CEILING(cost / count * markup, 1))

/datum/agent_stock/supplier/ware_image(ware)
	var/obj/item/item_type = ware
	return image(icon = initial(item_type.icon), icon_state = initial(item_type.icon_state))

/datum/agent_stock/supplier/hand_over(ware, mob/living/buyer)
	if(!catalog?[ware])
		return null
	var/obj/item/made = new ware(get_turf(buyer))
	buyer.put_in_hands(made)
	return made

/datum/agent_stock/supplier/food
	shop_label = "grocer: sells food, endless"
	pack_types = list(/datum/supply_pack/food)

/datum/agent_stock/supplier/tools
	shop_label = "toolseller: sells tools, endless"
	pack_types = list(/datum/supply_pack/tools)

/datum/agent_stock/supplier/apparel
	shop_label = "clothier: sells clothes, endless"
	pack_types = list(/datum/supply_pack/apparel)

/// Buys what players bring for part of its worth and resells it. Only selling refills its purse.
/datum/agent_stock/dealer
	kind = "dealer"
	shop_label = "pawnbroker: buys from players and resells"
	/// Share of an item's worth it pays.
	var/buy_ratio = 0.5
	/// Share of an item's worth it asks.
	var/sell_ratio = 1
	/// Coin it can buy with.
	var/purse = 100
	var/max_wares = 30
	/// What it deals in, and the same in words for the model.
	var/list/accepted_types = list(/obj/item)
	var/deals_in = "most goods"
	/// Inside the keeper, so the goods move with it and drop where it falls.
	var/obj/effect/agent_stockroom/stockroom
	/// The goods, oldest first, each with what it paid for it.
	var/list/obj/item/goods = list()

/datum/agent_stock/dealer/New(mob/living/new_keeper)
	. = ..()
	stockroom = new(new_keeper)

/datum/agent_stock/dealer/Destroy(force)
	spill(get_turf(keeper))
	QDEL_NULL(stockroom)
	goods = null
	return ..()

/datum/agent_stock/dealer/wares()
	return goods

/datum/agent_stock/dealer/ware_name(obj/item/ware)
	return "[ware.name]"

/datum/agent_stock/dealer/ware_price(obj/item/ware)
	if(!(ware in goods))
		return null
	return max(1, CEILING(ware.get_real_price() * sell_ratio, 1))

/// Never resold for less than it paid, so no discount makes selling it back and forth pay.
/datum/agent_stock/dealer/price_floor(obj/item/ware)
	return (goods[ware] || 0) + 1

/datum/agent_stock/dealer/ware_image(obj/item/ware)
	var/image/picture = image(icon = ware.icon, icon_state = ware.icon_state)
	picture.color = ware.color
	return picture

/datum/agent_stock/dealer/hand_over(obj/item/ware, mob/living/buyer)
	if(!(ware in goods) || QDELETED(ware) || ware.loc != stockroom)
		return null
	release(ware)
	ware.forceMove(get_turf(buyer))
	buyer.put_in_hands(ware)
	return ware

/datum/agent_stock/dealer/receive(amount)
	purse += amount

/datum/agent_stock/dealer/buy_refusal(obj/item/offered)
	if(QDELETED(offered) || (offered.item_flags & ABSTRACT))
		return "that cannot be sold"
	if(!is_type_in_list(offered, accepted_types))
		return "this shop does not deal in that"
	if(istype(offered, /obj/item/coin))
		return "coin is not bought with coin"
	// Nothing rides along unpriced: no goods inside goods, and never a person in a sack.
	for(var/atom/movable/inside as anything in offered.GetAllContents())
		if(inside != offered && (isitem(inside) || ismob(inside)))
			return "there is something inside it, so it must be emptied first"
	if(worth_offered(offered) <= 0)
		return "it is worthless"
	if(length(goods) >= max_wares)
		return "the stock is full"
	return null

/datum/agent_stock/dealer/worth_offered(obj/item/offered)
	return FLOOR(offered.get_real_price() * buy_ratio, 1)

/datum/agent_stock/dealer/take_in(obj/item/offered, price)
	offered.forceMove(stockroom)
	goods[offered] = price
	RegisterSignal(offered, COMSIG_PARENT_QDELETING, PROC_REF(on_ware_deleted))
	purse -= price

/datum/agent_stock/dealer/buys_text()
	return "[deals_in], paying about [round(buy_ratio * 100)]% of what they are worth"

/datum/agent_stock/dealer/purse_amount()
	return purse

/datum/agent_stock/dealer/spill(turf/where)
	for(var/obj/item/ware as anything in goods.Copy())
		release(ware)
		if(QDELETED(ware))
			continue
		if(where)
			ware.forceMove(where)
		else
			qdel(ware)
	if(where && purse > 0)
		add_mammons_to_atom(where, purse)
	purse = 0

/datum/agent_stock/dealer/proc/release(obj/item/ware)
	goods -= ware
	UnregisterSignal(ware, COMSIG_PARENT_QDELETING)

/// Food rots and things break; a ware deleted in stock is simply gone.
/datum/agent_stock/dealer/proc/on_ware_deleted(datum/source)
	SIGNAL_HANDLER
	goods -= source

/// Holds a dealer's goods inside the NPC. Never seen, never touched.
/obj/effect/agent_stockroom
	name = "stockroom"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE

/// A shop on an NPC. DM runs the menu, so it works with the sidecar down or no agent.
/datum/component/agent_shop
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/datum/agent_stock/stock
	/// Haggled discounts: weakref -> list(percent, world.time it lapses).
	var/list/discounts

/datum/component/agent_shop/Initialize(stock_type)
	if(!isliving(parent) || !ispath(stock_type, /datum/agent_stock))
		return COMPONENT_INCOMPATIBLE
	stock = new stock_type(parent)

/datum/component/agent_shop/Destroy(force)
	QDEL_NULL(stock)
	discounts = null
	return ..()

/datum/component/agent_shop/RegisterWithParent()
	RegisterSignal(parent, COMSIG_ATOM_ATTACK_HAND, PROC_REF(on_attack_hand))
	RegisterSignal(parent, COMSIG_LIVING_DEATH, PROC_REF(on_keeper_death))

/datum/component/agent_shop/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_ATOM_ATTACK_HAND, COMSIG_LIVING_DEATH))

/// A player's open hand outside combat mode. Grabs, shoves and blows stay what they are.
/datum/component/agent_shop/proc/wants_click(mob/living/customer)
	return isliving(customer) && customer != parent && customer.client && !customer.cmode && agent_touch_kind(customer) == AGENT_STIMULUS_TOUCHED

/datum/component/agent_shop/proc/on_attack_hand(datum/source, mob/living/customer, list/modifiers)
	SIGNAL_HANDLER
	if(!wants_click(customer))
		return
	var/refusal = refusal_for(customer)
	if(refusal)
		to_chat(customer, span_warning("[parent] [refusal]."))
		return COMPONENT_CANCEL_ATTACK_CHAIN
	var/mob/living/keeper = parent
	keeper.face_atom(customer)
	notify(AGENT_EVENT_CUSTOMER, customer, list("kind" = stock.kind))
	INVOKE_ASYNC(src, PROC_REF(open_menu), customer)
	return COMPONENT_CANCEL_ATTACK_CHAIN

/// Why the keeper will not trade with them now, or null.
/datum/component/agent_shop/proc/refusal_for(mob/living/customer)
	var/mob/living/keeper = parent
	if(keeper.stat != CONSCIOUS || keeper.incapacitated(IGNORE_GRAB))
		return "is in no state to trade"
	var/datum/ai_controller/agent_social/agent = keeper.ai_controller
	if(istype(agent))
		if(agent.in_combat())
			return "is busy fighting"
		if(agent.is_aggressor(customer))
			return "will not trade with you after what you did"
	return null

/datum/component/agent_shop/proc/discount_for(mob/living/customer)
	var/list/entry = LAZYACCESS(discounts, WEAKREF(customer))
	if(!entry || world.time > entry[2])
		return 0
	return entry[1]

/// Haggling, in percent. Returns what was granted after clamping; 0 takes a discount back.
/datum/component/agent_shop/proc/set_discount(mob/living/customer, percent)
	percent = clamp(round(percent, 1), 0, AGENT_SHOP_MAX_DISCOUNT)
	if(!percent)
		LAZYREMOVE(discounts, WEAKREF(customer))
		return 0
	LAZYSET(discounts, WEAKREF(customer), list(percent, world.time + AGENT_SHOP_DISCOUNT_DURATION))
	return percent

/// What this customer pays for a ware, or null if it is not for sale.
/datum/component/agent_shop/proc/price_for(mob/living/customer, ware)
	var/base = stock.ware_price(ware)
	if(isnull(base))
		return null
	var/price = CEILING(base * (100 - discount_for(customer)) / 100, 1)
	return max(price, stock.price_floor(ware), 1)

/// What this customer is paid for an item, or null if the shop will not buy it.
/datum/component/agent_shop/proc/offer_for(mob/living/customer, obj/item/offered)
	if(stock.buy_refusal(offered))
		return null
	return FLOOR(stock.worth_offered(offered) * (100 + discount_for(customer)) / 100, 1)

/// What the keeper would pay for each thing this customer holds, or why not. So the model quotes real prices.
/datum/component/agent_shop/proc/offers_for(mob/living/customer)
	var/list/offers = list()
	if(!stock.buys_text())
		return offers
	var/purse = stock.purse_amount()
	for(var/obj/item/held in customer.held_items)
		var/list/entry = list("item" = "[held.name]")
		var/refusal = stock.buy_refusal(held)
		var/price = refusal ? null : offer_for(customer, held)
		if(!isnull(price) && !isnull(purse) && price > purse)
			refusal = "your purse is too light to pay [agent_amnas(price)]"
		if(refusal)
			entry["refused"] = refusal
		else
			entry["offer"] = price
		offers += list(entry)
	return offers

/// The customer buys a ware. Null on success, else why not, as words after the keeper's name.
/datum/component/agent_shop/proc/sell_to(mob/living/customer, ware)
	var/refusal = refusal_for(customer) || stock.sale_refusal(customer)
	if(refusal)
		return refusal
	var/price = price_for(customer, ware)
	if(isnull(price) || !(ware in stock.wares()))
		return "no longer has that"
	var/name = stock.ware_name(ware)
	if(remove_mammons_from_atom(customer, price) < price)
		notify(AGENT_EVENT_TRADE_REFUSED, customer, list("what" = "buy", "item" = name, "reason" = "they could not pay [agent_amnas(price)]"))
		return "wants [agent_amnas(price)], more than you have"
	// The item for goods; a service hands over time, and only says that it did.
	var/handed = stock.hand_over(ware, customer)
	if(!handed)
		add_mammons_to_atom(customer, price)
		return "no longer has that"
	stock.receive(price)
	var/mob/living/keeper = parent
	log_game("[key_name(customer)] bought [name] for [price] from agent shop [key_name(keeper)] at [AREACOORD(keeper)].")
	notify(AGENT_EVENT_TRADE, customer, list("what" = stock.sold_verb, "item" = name, "price" = price))
	return null

/// The customer sells a held item. Null on success, else why not.
/datum/component/agent_shop/proc/buy_from(mob/living/customer, obj/item/offered)
	var/refusal = refusal_for(customer)
	if(refusal)
		return refusal
	if(QDELETED(offered) || !(offered in customer.held_items))
		return "sees nothing in your hands to buy"
	var/name = "[offered.name]"
	// The model hears every refusal, or it goes on promising to buy what the stall turns away.
	var/stock_refusal = stock.buy_refusal(offered)
	if(stock_refusal)
		notify(AGENT_EVENT_TRADE_REFUSED, customer, list("what" = "sell", "item" = name, "reason" = stock_refusal))
		return "will not buy it: [stock_refusal]"
	var/price = offer_for(customer, offered)
	var/purse = stock.purse_amount()
	if(!isnull(purse) && price > purse)
		notify(AGENT_EVENT_TRADE_REFUSED, customer, list("what" = "sell", "item" = name, "reason" = "your purse is too light to pay [agent_amnas(price)]"))
		return "cannot afford [agent_amnas(price)] for it"
	if(!customer.temporarilyRemoveItemFromInventory(offered))
		return "cannot take that from you"
	stock.take_in(offered, price)
	add_mammons_to_atom(customer, price)
	var/mob/living/keeper = parent
	log_game("[key_name(customer)] sold [name] for [price] to agent shop [key_name(keeper)] at [AREACOORD(keeper)].")
	notify(AGENT_EVENT_TRADE, customer, list("what" = "sold", "item" = name, "price" = price))
	return null

/// Tell the agent, if there is one. The trade itself never waits on the model.
/datum/component/agent_shop/proc/notify(event_name, mob/living/customer, list/detail)
	var/mob/living/keeper = parent
	var/datum/ai_controller/agent_social/agent = keeper.ai_controller
	if(istype(agent))
		agent.note_shop_event(event_name, customer, detail)

/datum/component/agent_shop/proc/on_keeper_death(datum/source, gibbed)
	SIGNAL_HANDLER
	stock.spill(get_turf(parent))

/datum/component/agent_shop/proc/menu_check(mob/living/customer)
	return !QDELETED(customer) && !IS_DEAD_OR_INCAP(customer) && get_dist(parent, customer) <= 1 && !refusal_for(customer)

/datum/component/agent_shop/proc/open_menu(mob/living/customer)
	var/list/options = list()
	if(length(stock.wares()))
		options["Buy"] = image(icon = 'icons/hud/radial.dmi', icon_state = "radial_buy")
	if(stock.buys_text())
		options["Sell"] = image(icon = 'icons/hud/radial.dmi', icon_state = "radial_sell")
	var/list/extras = stock.menu_extras(customer)
	if(extras)
		options += extras
	if(!length(options))
		to_chat(customer, span_notice("[parent] has nothing to trade right now."))
		return
	var/choice = show_radial_menu(customer, parent, options, custom_check = CALLBACK(src, PROC_REF(menu_check), customer), require_near = TRUE, radial_slice_icon = "radial_thaum")
	switch(choice)
		if("Buy")
			buy_menu(customer)
		if("Sell")
			sell_menu(customer)
		else
			if(choice && extras && (choice in extras) && menu_check(customer))
				stock.pick_extra(choice, customer)

/datum/component/agent_shop/proc/confirm(mob/living/customer)
	var/list/answers = list(
		"Yes" = image(icon = 'icons/hud/radial.dmi', icon_state = "radial_yes"),
		"No" = image(icon = 'icons/hud/radial.dmi', icon_state = "radial_no"),
	)
	var/answer = show_radial_menu(customer, parent, answers, custom_check = CALLBACK(src, PROC_REF(menu_check), customer), require_near = TRUE, radial_slice_icon = "radial_thaum")
	return answer == "Yes" && menu_check(customer)

/datum/component/agent_shop/proc/buy_menu(mob/living/customer)
	var/list/choices = list()
	var/list/ware_by_label = list()
	for(var/ware in stock.wares())
		var/price = price_for(customer, ware)
		if(isnull(price))
			continue
		var/label = "[stock.ware_name(ware)] ([agent_amnas(price)])"
		// Two of the same thing at the same price still need two entries.
		if(ware_by_label[label])
			label = "[label] #[length(ware_by_label) + 1]"
		ware_by_label[label] = ware
		choices[label] = stock.ware_image(ware)
	var/picked = show_radial_menu(customer, parent, choices, custom_check = CALLBACK(src, PROC_REF(menu_check), customer), require_near = TRUE, tooltips = TRUE, radial_slice_icon = "radial_thaum")
	if(!picked || !menu_check(customer))
		return
	var/ware = ware_by_label[picked]
	var/name = stock.ware_name(ware)
	var/price = price_for(customer, ware)
	if(isnull(price))
		return
	to_chat(customer, span_notice("[parent] asks [agent_amnas(price)] for the [name]."))
	if(!confirm(customer))
		return
	var/refusal = sell_to(customer, ware)
	if(refusal)
		to_chat(customer, span_warning("[parent] [refusal]."))
	else
		to_chat(customer, span_notice("You buy the [name] from [parent]."))

/datum/component/agent_shop/proc/sell_menu(mob/living/customer)
	var/obj/item/offered
	var/obj/item/first_refused
	for(var/obj/item/held in list(customer.get_active_held_item(), customer.get_inactive_held_item()))
		if(!stock.buy_refusal(held))
			offered = held
			break
		first_refused ||= held
	if(!offered)
		if(!first_refused)
			to_chat(customer, span_warning("Hold what you want to sell."))
			return
		// Through buy_from, so the refusal reaches the model as well as the customer.
		to_chat(customer, span_warning("[parent] [buy_from(customer, first_refused)]."))
		return
	var/name = "[offered.name]"
	var/price = offer_for(customer, offered)
	to_chat(customer, span_notice("[parent] offers [agent_amnas(price)] for your [name]."))
	if(!confirm(customer))
		return
	var/refusal = buy_from(customer, offered)
	if(refusal)
		to_chat(customer, span_warning("[parent] [refusal]."))
	else
		to_chat(customer, span_notice("You sell the [name] to [parent]."))

/// The shop as the model sees it: wares for sale, what it buys, its purse, and who got a deal.
/datum/component/agent_shop/proc/describe_for_agent()
	var/list/selling = list()
	var/list/all_wares = stock.wares()
	for(var/ware in all_wares)
		if(length(selling) >= AGENT_SHOP_SHOWN_WARES)
			break
		var/price = stock.ware_price(ware)
		if(!isnull(price))
			selling += list(list("name" = stock.ware_name(ware), "price" = price))
	var/list/described = list("kind" = stock.kind, "selling" = selling, "more" = max(0, length(all_wares) - length(selling)))
	var/buys = stock.buys_text()
	if(buys)
		described["buys"] = buys
	var/purse = stock.purse_amount()
	if(!isnull(purse))
		described["purse"] = purse
	var/list/favoured = list()
	var/list/lapsed = list()
	for(var/datum/weakref/reference as anything in discounts)
		var/mob/living/customer = reference.resolve()
		var/percent = customer ? discount_for(customer) : 0
		if(percent)
			favoured[customer.get_visible_name()] = percent
		else
			lapsed += reference
	for(var/datum/weakref/reference as anything in lapsed)
		LAZYREMOVE(discounts, reference)
	if(length(favoured))
		described["discounts"] = favoured
	var/list/extra = stock.describe_extra()
	for(var/key in extra)
		described[key] = extra[key]
	return described

/// Give a mob a shop of this type, replacing any it keeps; null removes it. Returns why not, or null.
/proc/agent_set_shop(mob/living/keeper, stock_type)
	if(QDELETED(keeper) || !isliving(keeper))
		return "that mob is gone"
	if(stock_type && !ispath(stock_type, /datum/agent_stock))
		return "that is not a kind of shop"
	// A dealer being replaced drops its goods and purse at its feet, the same as dying.
	var/datum/component/agent_shop/current = keeper.GetComponent(/datum/component/agent_shop)
	if(current)
		qdel(current)
	if(stock_type)
		keeper.AddComponent(/datum/component/agent_shop, stock_type)
	return null
