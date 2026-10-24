// Staging for playtests: each preset sets the state the game enforces and hands the model a memory to match.

/datum/unit_test/agent_stage_agreed_opens_the_gate_and_tells_the_model

/datum/unit_test/agent_stage_agreed_opens_the_gate_and_tells_the_model/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/barmaid = agent_test_romantic_pawn()
	var/datum/ai_controller/agent_social/agent = barmaid.ai_controller
	var/datum/agent_binding/binding = agent.binding
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human/species/human/northern)
	binding.take_events()
	// The test world may carry a real sidecar URL from config; nothing here may reach it.
	var/saved_seed_endpoint = SSagent_npc.seed_endpoint
	SSagent_npc.seed_endpoint = ""

	var/list/staged = agent_stage(agent_stage_preset_named("agreed"), agent, partner)
	SSagent_npc.seed_endpoint = saved_seed_endpoint
	var/woke = binding.dirty
	var/agreed = agent.consent_until(partner) > world.time
	var/list/lines = agent_test_events_named(binding.events, "heard_speech")
	var/list/body = SSagent_npc.seed_body(binding, "what I recall")
	var/list/clearing = SSagent_npc.seed_body(binding, null)

	agent_test_restore_subsystem(saved, binding)
	TEST_ASSERT_NULL(staged["refusal"], "A barmaid may be staged as agreed: [staged["refusal"]]")
	TEST_ASSERT(agreed, "The yes the game enforces is granted.")
	TEST_ASSERT(findtext(staged["summary"], partner.get_visible_name()) && findtext(staged["summary"], "I said yes"), "The memory names the partner and the yes, in the first person: [staged["summary"]]")
	TEST_ASSERT_EQUAL(length(lines), 1, "The partner's line gives the next turn something to answer.")
	TEST_ASSERT_EQUAL(lines[1]["detail"]["speaker"], partner.get_visible_name(), "In the partner's name.")
	TEST_ASSERT(woke, "And wakes the model.")
	TEST_ASSERT(!staged["seeded"], "Without a sidecar endpoint the memory is not sent, and that is said.")
	TEST_ASSERT_EQUAL(body["summary"], "what I recall", "The seed body carries the text.")
	TEST_ASSERT_EQUAL(body["pawn_id"], binding.pawn_id, "And the character's identity.")
	TEST_ASSERT_EQUAL(body["binding_epoch"], binding.epoch, "Epoch included, so a reborn pawn never inherits it.")
	TEST_ASSERT(clearing["clear"] && isnull(clearing["summary"]), "A null text clears.")
	TEST_ASSERT_EQUAL(agent_seed_endpoint("http://127.0.0.1:1340/decide"), "http://127.0.0.1:1340/seed", "The memory endpoint sits beside the decision one.")
	TEST_ASSERT_EQUAL(agent_seed_endpoint(""), "", "No endpoint, no seed endpoint.")

/datum/unit_test/agent_stage_paid_makes_a_customer

/datum/unit_test/agent_stage_paid_makes_a_customer/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/performer = agent_test_shopkeeper(/datum/agent_stock/service)
	var/datum/ai_controller/agent_social/agent = performer.ai_controller
	var/datum/component/agent_shop/shop = performer.GetComponent(/datum/component/agent_shop)
	var/datum/agent_stock/service/service = shop.stock
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human/species/human/northern)
	agent.binding.take_events()

	var/list/staged = agent_stage(agent_stage_preset_named("paid"), agent, partner)
	var/customer = service.current_customer() == partner && service.paid_until > world.time
	var/list/sales = agent_test_events_named(agent.binding.events, AGENT_EVENT_TRADE)
	var/list/wrong = agent_stage(agent_stage_preset_named("haggling"), agent, partner)

	agent_test_restore_subsystem(saved, agent.binding)
	TEST_ASSERT_NULL(staged["refusal"], "A performer may be staged as paid: [staged["refusal"]]")
	TEST_ASSERT(customer, "The partner is its paying customer with time left.")
	TEST_ASSERT_EQUAL(length(sales), 1, "The sale reaches the model as the real one would.")
	TEST_ASSERT(findtext(staged["summary"], "amnas"), "The memory names the price: [staged["summary"]]")
	TEST_ASSERT(findtext(wrong["refusal"], "no stall"), "A performer keeps no stall to haggle at: [wrong["refusal"]]")

/datum/unit_test/agent_stage_mid_act_starts_an_act_the_npc_leads

/datum/unit_test/agent_stage_mid_act_starts_an_act_the_npc_leads/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/barmaid = agent_test_romantic_pawn()
	barmaid.gender = FEMALE
	var/datum/ai_controller/agent_social/agent = barmaid.ai_controller
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human/species/human/northern)
	partner.gender = MALE
	partner.give_genitals()

	var/list/staged = agent_stage(agent_stage_preset_named("mid_act_tender"), agent, partner)
	var/leading = agent.leads_private_act()
	var/agreed = agent.consent_until(partner) > world.time
	agent.stop_led_acts()

	agent_test_restore_subsystem(saved, agent.binding)
	TEST_ASSERT_NULL(staged["refusal"], "A couple beside each other can be staged mid-act: [staged["refusal"]]")
	TEST_ASSERT(leading, "The NPC leads an act.")
	TEST_ASSERT(agreed, "On a yes the game enforces.")
	TEST_ASSERT(findtext(staged["summary"], "I began to"), "The memory says how it began: [staged["summary"]]")

/datum/unit_test/agent_stage_refuses_what_the_character_is_not

/datum/unit_test/agent_stage_refuses_what_the_character_is_not/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/villager = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/agent = villager.ai_controller
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human/species/human/northern)

	var/list/agreed = agent_stage(agent_stage_preset_named("agreed"), agent, partner)
	var/list/paid = agent_stage(agent_stage_preset_named("paid"), agent, partner)
	var/list/stall = agent_stage(agent_stage_preset_named("haggling"), agent, partner)
	var/list/itself = agent_stage(agent_stage_preset_named("courted"), agent, villager)
	var/list/courted = agent_stage(agent_stage_preset_named("courted"), agent, partner)
	var/consent_untouched = !agent.consent_until(partner)

	agent_test_restore_subsystem(saved, agent.binding)
	TEST_ASSERT(findtext(agreed["refusal"], "romance"), "A villager cannot be staged as agreed: [agreed["refusal"]]")
	TEST_ASSERT(findtext(paid["refusal"], "sell"), "Nor as paid: [paid["refusal"]]")
	TEST_ASSERT(findtext(stall["refusal"], "stall"), "Nor as haggling: [stall["refusal"]]")
	TEST_ASSERT(findtext(itself["refusal"], "another"), "Nobody is staged with themselves: [itself["refusal"]]")
	TEST_ASSERT_NULL(courted["refusal"], "Anyone can be courted: [courted["refusal"]]")
	TEST_ASSERT(consent_untouched, "Courting grants no yes.")

/datum/unit_test/agent_stage_close_sets_the_bodies

/datum/unit_test/agent_stage_close_sets_the_bodies/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/villager = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/agent = villager.ai_controller
	var/mob/living/carbon/human/partner = allocate(/mob/living/carbon/human/species/human/northern)

	var/list/staged = agent_stage(agent_stage_preset_named("close"), agent, partner)
	var/list/own = agent_describe_arousal(villager)
	var/list/theirs = agent_describe_arousal(partner)

	agent_test_restore_subsystem(saved, agent.binding)
	TEST_ASSERT_NULL(staged["refusal"], "Any body can be staged close: [staged["refusal"]]")
	TEST_ASSERT_NULL(staged["summary"], "A preset that only touches the body sends no memory.")
	TEST_ASSERT(own["close"] && own["arousal"] == "burning", "The NPC reads as burning and close: [own["arousal"]]")
	TEST_ASSERT_EQUAL(theirs["arousal"], "aroused", "The partner reads as aroused: [theirs["arousal"]]")
