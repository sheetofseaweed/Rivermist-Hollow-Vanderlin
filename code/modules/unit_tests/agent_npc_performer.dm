// The performer: paid time is the only way into a scene with an agent NPC, and the model never sees inside one.

/obj/effect/agent_npc_spawner/performer/test
	npc_name = "Testy Courtesan"

/obj/effect/agent_npc_spawner/performer/male/test
	npc_name = "Testy Courtier"

/// Always sees a player at the same trade, so it always charges the higher price.
/datum/agent_stock/service/test_rivals

/datum/agent_stock/service/test_rivals/rivals_at_work()
	return TRUE

/// A man with the parts the house acts need, and coin for this many quarter hours.
/datum/unit_test/proc/agent_test_service_customer(blocks = 1)
	var/mob/living/carbon/human/customer = allocate(/mob/living/carbon/human/species/human/northern)
	customer.gender = MALE
	customer.give_genitals()
	agent_test_coins(customer, /obj/item/coin/gold, blocks)
	return customer

/datum/unit_test/agent_service_refuses_unpaid_scenes

/datum/unit_test/agent_service_refuses_unpaid_scenes/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/performer = agent_test_shopkeeper(/datum/agent_stock/service)
	var/mob/living/carbon/human/species/human/northern/agent_social/villager = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/performer_agent = performer.ai_controller
	var/datum/ai_controller/agent_social/villager_agent = villager.ai_controller
	var/mob/living/carbon/human/customer = agent_test_service_customer()
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human/species/human/northern)

	var/datum/sex_scene_controller/unpaid = customer.open_sex_scene(performer, FALSE)
	var/unpaid_reason = customer.get_sex_scene_refusal(performer)
	var/datum/sex_scene_controller/led_unpaid = performer.open_sex_scene(customer, FALSE)
	var/datum/sex_scene_controller/with_villager = customer.open_sex_scene(villager, FALSE)
	var/villager_reason = customer.get_sex_scene_refusal(villager)
	var/datum/sex_scene_controller/with_stranger = customer.open_sex_scene(stranger, FALSE)
	var/stranger_allowed = !isnull(with_stranger)
	qdel(with_stranger)
	agent_test_restore_subsystem(saved, performer_agent.binding)
	agent_test_restore_subsystem(saved, villager_agent.binding)

	TEST_ASSERT_NULL(unpaid, "An unpaid customer must not open a scene with a performer.")
	TEST_ASSERT(findtext(unpaid_reason, "wants to be paid first"), "The customer must be told why: [unpaid_reason]")
	TEST_ASSERT_NULL(led_unpaid, "Nor may the performer start one with someone who has not paid.")
	TEST_ASSERT_NULL(with_villager, "An agent NPC that sells nothing must refuse every scene.")
	TEST_ASSERT(findtext(villager_reason, "refuses"), "And say so: [villager_reason]")
	TEST_ASSERT(stranger_allowed, "Ordinary NPCs are untouched by the agent rules.")

/datum/unit_test/agent_service_sells_time_to_one_customer

/datum/unit_test/agent_service_sells_time_to_one_customer/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/performer = agent_test_shopkeeper(/datum/agent_stock/service)
	var/datum/ai_controller/agent_social/agent = performer.ai_controller
	var/datum/component/agent_shop/shop = performer.GetComponent(/datum/component/agent_shop)
	var/datum/agent_stock/service/service = shop.stock
	var/mob/living/carbon/human/customer = agent_test_service_customer(2)
	var/mob/living/carbon/human/rival = agent_test_service_customer(2)
	TEST_ASSERT_NOTNULL(agent?.binding, "Setup failed: the performer must be bound.")
	agent.binding.take_events()

	var/price = shop.price_for(customer, AGENT_SERVICE_WARE)
	var/first = shop.sell_to(customer, AGENT_SERVICE_WARE)
	var/time_after_first = service.paid_until - world.time
	var/second = shop.sell_to(customer, AGENT_SERVICE_WARE)
	var/time_after_second = service.paid_until - world.time
	var/money_left = get_mammons_in_atom(customer)
	var/rival_sale = shop.sell_to(rival, AGENT_SERVICE_WARE)
	var/rival_money = get_mammons_in_atom(rival)
	var/datum/sex_scene_controller/rival_scene = rival.open_sex_scene(performer, FALSE)
	var/datum/sex_scene_controller/paid_scene = customer.open_sex_scene(performer, FALSE)
	var/paid_allowed = !isnull(paid_scene)
	qdel(paid_scene)
	var/list/trades = agent_test_events_named(agent.binding.take_events(), AGENT_EVENT_TRADE)
	var/list/first_trade = length(trades) ? trades[1]["detail"] : list()
	var/list/payload = agent.binding.profile_payload()
	var/list/described = shop.describe_for_agent()
	var/purse = service.purse
	agent_test_restore_subsystem(saved, agent.binding)

	TEST_ASSERT_EQUAL(price, AGENT_SERVICE_PRICE, "With no player at the trade, a quarter hour costs the base price.")
	TEST_ASSERT_NULL(first, "The first payment must go through.")
	TEST_ASSERT_EQUAL(time_after_first, AGENT_SERVICE_BLOCK, "One payment buys one block of time.")
	TEST_ASSERT_NULL(second, "The same customer may buy more time.")
	TEST_ASSERT_EQUAL(time_after_second, AGENT_SERVICE_BLOCK * 2, "Buying again adds to the time left.")
	TEST_ASSERT_EQUAL(money_left, 0, "Two blocks must cost both gold coins.")
	TEST_ASSERT(findtext(rival_sale, "someone else"), "Someone else must wait until the time runs out: [rival_sale]")
	TEST_ASSERT_EQUAL(rival_money, AGENT_SERVICE_PRICE * 2, "And keep their coin.")
	TEST_ASSERT_NULL(rival_scene, "Nor share a scene with the performer meanwhile.")
	TEST_ASSERT(paid_allowed, "A customer with time left may open a scene.")
	TEST_ASSERT_EQUAL(length(trades), 2, "Each payment must reach the model.")
	TEST_ASSERT_EQUAL(first_trade["what"], "paid", "As paid time, not as goods bought.")
	TEST_ASSERT_EQUAL(payload["shop_kind"], "service", "The model must be told it sells its company, not wares.")
	TEST_ASSERT_EQUAL(described["with"], customer.get_visible_name(), "The scene must say who has paid.")
	TEST_ASSERT_EQUAL(described["minutes_left"], 30, "And how long they have left.")
	TEST_ASSERT_EQUAL(purse, AGENT_SERVICE_PRICE * 2, "The coin goes to the performer's purse.")

/datum/unit_test/agent_service_time_up_ends_the_scene

/datum/unit_test/agent_service_time_up_ends_the_scene/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/performer = agent_test_shopkeeper(/datum/agent_stock/service)
	var/datum/ai_controller/agent_social/agent = performer.ai_controller
	var/datum/component/agent_shop/shop = performer.GetComponent(/datum/component/agent_shop)
	var/datum/agent_stock/service/service = shop.stock
	var/mob/living/carbon/human/customer = agent_test_service_customer()
	TEST_ASSERT_NOTNULL(agent?.binding, "Setup failed: the performer must be bound.")
	TEST_ASSERT_NULL(shop.sell_to(customer, AGENT_SERVICE_WARE), "Setup failed: the customer must be able to pay.")

	var/datum/sex_action/led = service.start_act(customer, /datum/sex_action/rub_body)
	TEST_ASSERT_NOTNULL(led, "Setup failed: the performer must start the act the customer picked.")
	var/interaction_key = "sex_action_[REF(led)]"
	var/running = DOING_INTERACTION(performer, interaction_key)
	var/private = agent.in_private()
	agent.binding.take_events()
	agent.binding.mark_dirty("physical", AGENT_EVENT_LOW, list("what" = AGENT_STIMULUS_TOUCHED, "by" = "someone"))
	var/asked_meanwhile = agent.binding.can_start_request()
	// Cleared again, so nothing is left to send once the act ends during the wait below.
	agent.binding.take_events()
	service.watch()

	service.paid_until = world.time
	var/consent_after = performer.allows_sex_with(customer)
	sleep(3 SECONDS)
	var/stopped = QDELETED(led) || !DOING_INTERACTION(performer, interaction_key)
	service.watch()
	var/list/private_time = agent_test_events_named(agent.binding.take_events(), AGENT_EVENT_PRIVATE_TIME)
	var/list/told = list()
	for(var/list/entry as anything in private_time)
		told += entry["detail"]["what"]
	var/private_after = agent.in_private()
	var/left_with = service.current_customer()
	if(!QDELETED(led))
		led.stop_runtime()
	agent_test_restore_subsystem(saved, agent.binding)

	TEST_ASSERT(running, "The picked act must run.")
	TEST_ASSERT(private, "While it runs, the performer is in private.")
	TEST_ASSERT(!asked_meanwhile, "The model must get no turn while an act runs.")
	TEST_ASSERT(!consent_after, "Consent must end with the paid time.")
	TEST_ASSERT(stopped, "A running act must stop on its next step once the time is up.")
	TEST_ASSERT(!private_after, "Nothing must still be running afterwards.")
	TEST_ASSERT_NULL(left_with, "No one has paid time any more.")
	TEST_ASSERT(("spent" in told) && ("time_up" in told), "The model must hear that private time ended, and that the time ran out: [told.Join(", ")]")

/datum/unit_test/agent_service_menu_offers_house_acts

/datum/unit_test/agent_service_menu_offers_house_acts/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/performer = agent_test_shopkeeper(/datum/agent_stock/service)
	var/datum/ai_controller/agent_social/agent = performer.ai_controller
	var/datum/component/agent_shop/shop = performer.GetComponent(/datum/component/agent_shop)
	var/datum/agent_stock/service/service = shop.stock
	var/mob/living/carbon/human/customer = agent_test_service_customer()
	var/mob/living/carbon/human/onlooker = agent_test_service_customer()

	var/list/unpaid_acts = service.startable_acts(customer)
	var/unpaid_extras = service.menu_extras(customer)
	TEST_ASSERT_NULL(shop.sell_to(customer, AGENT_SERVICE_WARE), "Setup failed: the customer must be able to pay.")
	var/list/gentle_acts = service.startable_acts(customer)
	var/list/extras = service.menu_extras(customer)
	var/list/onlooker_extras = service.menu_extras(onlooker)
	service.set_rough(TRUE, customer)
	var/list/rough_acts = service.startable_acts(customer)
	var/list/rough_extras = service.menu_extras(customer)
	qdel(performer.sex_scene?.get_controller(performer))
	agent_test_restore_subsystem(saved, agent.binding)

	var/gentle_rough_count = 0
	var/gentle_foreign_count = 0
	for(var/name in gentle_acts)
		if(gentle_acts[name] in GLOB.agent_service_rough_acts)
			gentle_rough_count++
		else if(!(gentle_acts[name] in GLOB.agent_service_acts))
			gentle_foreign_count++
	var/rough_count = 0
	for(var/name in rough_acts)
		if(rough_acts[name] in GLOB.agent_service_rough_acts)
			rough_count++

	TEST_ASSERT_EQUAL(length(unpaid_acts), 0, "Nothing is offered before paying.")
	TEST_ASSERT_NULL(unpaid_extras, "Nor any choice beyond buying.")
	TEST_ASSERT(gentle_acts["Make out with them"], "The house list must offer kissing to anyone.")
	TEST_ASSERT(gentle_acts["Jerk them off"], "And what fits the customer's body.")
	TEST_ASSERT_EQUAL(gentle_rough_count, 0, "No rough act until the customer asks for it.")
	TEST_ASSERT_EQUAL(gentle_foreign_count, 0, "Only house acts: never the wild mobs' NPC acts.")
	TEST_ASSERT(extras[AGENT_SERVICE_LEAD] && extras[AGENT_SERVICE_ROUGH], "A paying customer can ask the performer to lead, and to be rough.")
	TEST_ASSERT_NULL(onlooker_extras, "Someone who has not paid gets no such choices.")
	TEST_ASSERT(rough_count > 0, "Asked for it rough, the rough acts are offered too.")
	TEST_ASSERT(rough_extras[AGENT_SERVICE_GENTLE], "And the customer can ask for gentle again.")

/datum/unit_test/agent_service_hears_nothing_in_private

/datum/unit_test/agent_service_hears_nothing_in_private/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/performer = agent_test_shopkeeper(/datum/agent_stock/service)
	var/datum/ai_controller/agent_social/agent = performer.ai_controller
	var/datum/component/agent_shop/shop = performer.GetComponent(/datum/component/agent_shop)
	var/datum/agent_stock/service/service = shop.stock
	var/mob/living/carbon/human/customer = agent_test_service_customer()
	TEST_ASSERT_NOTNULL(agent?.binding, "Setup failed: the performer must be bound.")
	TEST_ASSERT_NULL(shop.sell_to(customer, AGENT_SERVICE_WARE), "Setup failed: the customer must be able to pay.")
	var/datum/sex_action/led = service.start_act(customer, /datum/sex_action/rub_body)
	TEST_ASSERT_NOTNULL(led, "Setup failed: the performer must start the act the customer picked.")
	agent.binding.take_events()

	agent.on_pawn_heard(performer, list("composed", customer, null, "something said in private"))
	var/list/during = agent.binding.take_events()
	var/heard_in_private = length(agent_test_events_named(during, "heard_speech")) + length(agent_test_events_named(during, "overheard_speech"))
	var/emote_route = agent.on_emote_perceived(customer, "sighs happily", TRUE, TRUE)
	led.stop_runtime()
	agent.on_pawn_heard(performer, list("composed", customer, null, "something said after"))
	var/list/after = agent.binding.take_events()
	var/heard_after = length(agent_test_events_named(after, "heard_speech")) + length(agent_test_events_named(after, "overheard_speech"))
	agent_test_restore_subsystem(saved, agent.binding)

	TEST_ASSERT_EQUAL(heard_in_private, 0, "Nothing said during an act may reach the model, so none of it leaves the server.")
	TEST_ASSERT_EQUAL(emote_route, "private", "Nor any emote.")
	TEST_ASSERT(heard_after > 0, "Speech after the act is heard as usual.")

/datum/unit_test/agent_service_spawner_places_a_performer

/datum/unit_test/agent_service_spawner_places_a_performer/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/turf/here = run_loc_floor_top_right
	new /obj/effect/agent_npc_spawner/performer/test(here)
	new /obj/effect/agent_npc_spawner/performer/male/test(here)
	var/mob/living/carbon/human/woman = agent_test_spawned_named(here, "Testy Courtesan")
	var/mob/living/carbon/human/man = agent_test_spawned_named(here, "Testy Courtier")
	TEST_ASSERT_NOTNULL(woman, "The performer spawner must leave its NPC where it stood.")
	TEST_ASSERT_NOTNULL(man, "So must the male one.")
	var/datum/ai_controller/agent_social/woman_agent = woman.ai_controller
	var/datum/ai_controller/agent_social/man_agent = man.ai_controller
	var/datum/component/agent_shop/shop = woman.GetComponent(/datum/component/agent_shop)
	var/sells_company = istype(shop?.stock, /datum/agent_stock/service)
	var/label = woman_agent?.profile?.label
	var/woman_gender = woman.gender
	var/man_gender = man.gender
	var/woman_parts = !isnull(woman.getorganslot(ORGAN_SLOT_VAGINA))
	var/man_parts = !isnull(man.getorganslot(ORGAN_SLOT_PENIS))
	var/gowned = FALSE
	for(var/obj/item/worn in woman.get_equipped_items())
		if(istype(worn, /obj/item/clothing/shirt/nightgown))
			gowned = TRUE
	var/hands_free = !woman.get_active_held_item() && !woman.get_inactive_held_item()
	agent_test_restore_subsystem(saved, woman_agent?.binding)
	agent_test_restore_subsystem(saved, man_agent?.binding)
	qdel(woman)
	qdel(man)

	TEST_ASSERT(sells_company, "A performer must sell its company.")
	TEST_ASSERT_EQUAL(label, "performer", "And play the performer.")
	TEST_ASSERT_EQUAL(woman_gender, FEMALE, "The default performer is a woman.")
	TEST_ASSERT_EQUAL(man_gender, MALE, "The male preset is a man.")
	TEST_ASSERT(woman_parts && man_parts, "Each must have the parts that match.")
	TEST_ASSERT(gowned, "The woman wears a nightgown.")
	TEST_ASSERT(hands_free, "With both hands free for the acts that need them.")

/datum/unit_test/agent_service_charges_more_beside_players

/datum/unit_test/agent_service_charges_more_beside_players/Run()
	var/mob/living/carbon/human/keeper = allocate(/mob/living/carbon/human/species/human/northern)
	var/datum/agent_stock/service/plain = new(keeper)
	var/datum/agent_stock/service/test_rivals/beside_players = new(keeper)
	var/plain_price = plain.ware_price(AGENT_SERVICE_WARE)
	var/rival_price = beside_players.ware_price(AGENT_SERVICE_WARE)
	var/nothing_else = plain.ware_price("something else")
	qdel(plain)
	qdel(beside_players)

	TEST_ASSERT_EQUAL(plain_price, AGENT_SERVICE_PRICE, "Alone at the trade, a quarter hour costs the base price.")
	TEST_ASSERT_EQUAL(rival_price, AGENT_SERVICE_PRICE * AGENT_SERVICE_RIVAL_MARKUP, "Beside a player at the same trade, it costs more.")
	TEST_ASSERT_NULL(nothing_else, "Company is the only thing for sale.")

/datum/unit_test/agent_service_customer_may_take_a_hand

/datum/unit_test/agent_service_customer_may_take_a_hand/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/performer = agent_test_shopkeeper(/datum/agent_stock/service)
	var/datum/ai_controller/agent_social/agent = performer.ai_controller
	var/datum/component/agent_shop/shop = performer.GetComponent(/datum/component/agent_shop)
	var/mob/living/carbon/human/customer = agent_test_service_customer()
	var/mob/living/carbon/human/stranger = agent_test_service_customer()
	TEST_ASSERT_NOTNULL(agent?.binding, "Setup failed: the performer must be bound.")

	var/busy_unpaid = agent.busy_away_from_post()
	TEST_ASSERT_NULL(shop.sell_to(customer, AGENT_SERVICE_WARE), "Setup failed: the customer must be able to pay.")
	var/busy_paid = agent.busy_away_from_post()
	agent.note_stimulus(AGENT_STIMULUS_GRABBED, customer)
	var/customer_grab_is_attack = agent.is_aggressor(customer)
	agent.note_stimulus(AGENT_STIMULUS_GRABBED, stranger)
	var/stranger_grab_is_attack = agent.is_aggressor(stranger)
	agent.note_stimulus(AGENT_STIMULUS_STRUCK, customer)
	var/customer_blow_is_attack = agent.is_aggressor(customer)
	agent_test_restore_subsystem(saved, agent.binding)

	TEST_ASSERT(!busy_unpaid, "Setup failed: an idle performer is free to walk back to its post.")
	TEST_ASSERT(busy_paid, "A paid performer stays with its customer instead of walking back to its post.")
	TEST_ASSERT(!customer_grab_is_attack, "A paying customer may take the performer by the hand.")
	TEST_ASSERT(stranger_grab_is_attack, "Anyone else's grab is still an attack.")
	TEST_ASSERT(customer_blow_is_attack, "And a blow from the customer is still a blow.")

/datum/unit_test/agent_service_grip_needs_paid_time

/datum/unit_test/agent_service_grip_needs_paid_time/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/performer = agent_test_shopkeeper(/datum/agent_stock/service)
	var/datum/ai_controller/agent_social/agent = performer.ai_controller
	var/datum/component/agent_shop/shop = performer.GetComponent(/datum/component/agent_shop)
	var/datum/agent_stock/service/service = shop.stock
	// Empty-handed at first: a full hand also stops a grip, which would pass the unpaid check for the wrong reason.
	var/mob/living/carbon/human/customer = allocate(/mob/living/carbon/human/species/human/northern)
	if(!performer.getorganslot(ORGAN_SLOT_PENIS))
		give_penis_grip_test_genitals(performer)
	customer.zone_selected = BODY_ZONE_PRECISE_GROIN
	TEST_ASSERT_NULL(customer.get_active_held_item(), "Setup failed: the customer's hand must be empty.")

	var/gripped_unpaid = customer.try_grip_penis(performer)
	var/obj/item/penis_grip/unpaid_grip = customer.get_active_held_item()
	agent_test_coins(customer, /obj/item/coin/gold, 1)
	TEST_ASSERT_NULL(shop.sell_to(customer, AGENT_SERVICE_WARE), "Setup failed: the customer must be able to pay.")
	TEST_ASSERT_NULL(customer.get_active_held_item(), "Setup failed: paying the exact coin must leave the hand empty.")
	var/gripped_paid = customer.try_grip_penis(performer)
	var/obj/item/penis_grip/grip = customer.get_active_held_item()
	var/valid_paid = istype(grip) && grip.is_hold_valid()
	service.paid_until = world.time
	var/valid_after = istype(grip) && grip.is_hold_valid()
	if(istype(grip))
		customer.dropItemToGround(grip)
	agent_test_restore_subsystem(saved, agent.binding)

	TEST_ASSERT(!gripped_unpaid && !istype(unpaid_grip), "No one may take hold of a performer who has not been paid.")
	TEST_ASSERT(gripped_paid && istype(grip), "A paying customer may.")
	TEST_ASSERT(valid_paid, "And keep hold while the time lasts.")
	TEST_ASSERT(!valid_after, "But not once it is over.")
