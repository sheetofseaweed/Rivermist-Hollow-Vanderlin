// Staging for playtests: an admin puts an NPC into a gated state and gives the model a memory to match.

/datum/agent_stage_preset
	var/id
	var/name
	/// What the character must be: "romance", "service", "shop", "private" (either of the first two), or null.
	var/needs

/// The memory the model gets, in the character's own voice. Null for a preset that touches only the body.
/datum/agent_stage_preset/proc/summary(datum/ai_controller/agent_social/agent, mob/living/partner)
	return null

/// DM state and the event hook. Returns a refusal, or null when done.
/datum/agent_stage_preset/proc/apply(datum/ai_controller/agent_social/agent, mob/living/partner)
	return null

/// Every preset, once. Presets hold no state, so one instance serves every staging.
/proc/agent_stage_presets()
	var/static/list/presets
	if(!presets)
		presets = list()
		for(var/preset_type in subtypesof(/datum/agent_stage_preset))
			presets += new preset_type()
	return presets

/proc/agent_stage_preset_named(id)
	for(var/datum/agent_stage_preset/preset as anything in agent_stage_presets())
		if(preset.id == id)
			return preset
	return null

/// Why this preset cannot be staged on this character with this partner, or null.
/proc/agent_stage_refusal(datum/agent_stage_preset/preset, datum/ai_controller/agent_social/agent, mob/living/partner)
	if(!preset || !istype(agent) || !agent.binding || QDELETED(agent.binding))
		return "that NPC is not bound to the agent subsystem"
	if(!isliving(partner) || partner == agent.pawn)
		return "the partner must be another living person"
	var/datum/component/agent_shop/shop = agent.pawn.GetComponent(/datum/component/agent_shop)
	var/service = istype(shop?.stock, /datum/agent_stock/service)
	switch(preset.needs)
		if("romance")
			if(!agent.romance_enabled())
				return "[agent.pawn] does not choose its own company: romance is off in its profile"
		if("service")
			if(!service)
				return "[agent.pawn] does not sell its company"
		if("shop")
			if(!shop || service)
				return "[agent.pawn] keeps no stall"
		if("private")
			if(!agent.romance_enabled() && !service)
				return "[agent.pawn] neither chooses its company nor sells it"
	return null

/// Stage a preset: DM state, the event hook, then the memory sent to the sidecar. Returns refusal, summary, seeded.
/proc/agent_stage(datum/agent_stage_preset/preset, datum/ai_controller/agent_social/agent, mob/living/partner)
	var/refusal = agent_stage_refusal(preset, agent, partner)
	if(refusal)
		return list("refusal" = refusal)
	refusal = preset.apply(agent, partner)
	if(refusal)
		return list("refusal" = refusal)
	var/summary = preset.summary(agent, partner)
	var/seeded = summary ? SSagent_npc.seed_memory(agent.binding, summary) : FALSE
	return list("refusal" = null, "summary" = summary, "seeded" = seeded)

/// A line from the partner, pushed as if heard, so the next turn has something to answer.
/proc/agent_stage_line(datum/ai_controller/agent_social/agent, mob/living/partner, text)
	var/datum/agent_binding/binding = agent.binding
	if(!binding || QDELETED(binding))
		return
	binding.note_candidate(partner)
	binding.mark_dirty("heard_speech", AGENT_EVENT_LOW, list(
		"speaker" = partner.get_visible_name(),
		"text" = text,
		"distance" = get_dist(agent.pawn, partner),
		"whispered" = FALSE,
		"shouted" = FALSE,
		"nearby_people" = 0,
		"addressing" = AGENT_SPEECH_DIRECTED,
		"from_partner" = TRUE,
		"spoken_to_you" = TRUE,
	), replenish = TRUE)

/// Both bodies get the component the acts would give them, then the numbers.
/proc/agent_stage_arousal(mob/living/who, arousal, progress)
	if(!who.GetComponent(/datum/component/arousal))
		who.AddComponent(/datum/component/arousal)
	SEND_SIGNAL(who, COMSIG_SEX_SET_AROUSAL, arousal)
	SEND_SIGNAL(who, COMSIG_SEX_SET_ORGASM_PROG, progress)

/// The performer's service, with the partner made its paying customer. Null when it will not sell to them.
/proc/agent_stage_paid(datum/ai_controller/agent_social/agent, mob/living/partner)
	var/datum/component/agent_shop/shop = agent.pawn.GetComponent(/datum/component/agent_shop)
	var/datum/agent_stock/service/service = shop?.stock
	if(!istype(service) || !service.hand_over(AGENT_SERVICE_WARE, partner))
		return null
	// The sale as the model would have heard of it, the same event the real purchase sends.
	agent.note_shop_event(AGENT_EVENT_TRADE, partner, list("what" = service.sold_verb, "item" = service.ware_name(AGENT_SERVICE_WARE), "price" = AGENT_SERVICE_PRICE))
	return service

/datum/agent_stage_preset/courted
	id = "courted"
	name = "Courted: an evening of flirting, nothing agreed"

/datum/agent_stage_preset/courted/summary(datum/ai_controller/agent_social/agent, mob/living/partner)
	return "[partner.get_visible_name()] has been at my side all evening: bought me a drink, made me laugh, and let me tease without taking offence. I have not minded the attention one bit."

/datum/agent_stage_preset/courted/apply(datum/ai_controller/agent_social/agent, mob/living/partner)
	agent_stage_line(agent, partner, "Find me when the crowd thins?")

/datum/agent_stage_preset/agreed
	id = "agreed"
	name = "Agreed: said yes to private time"
	needs = "romance"

/datum/agent_stage_preset/agreed/summary(datum/ai_controller/agent_social/agent, mob/living/partner)
	return "[partner.get_visible_name()] has been at my side all evening: bought me a drink, made me laugh, and let me tease without taking offence. When they asked to go somewhere private, I said yes."

/datum/agent_stage_preset/agreed/apply(datum/ai_controller/agent_social/agent, mob/living/partner)
	agent.grant_consent(partner)
	agent_stage_line(agent, partner, "Shall we, then?")

/datum/agent_stage_preset/welcomed
	id = "welcomed"
	name = "Welcomed intimate: the NPC may lead, up to rough"
	needs = "romance"

/datum/agent_stage_preset/welcomed/summary(datum/ai_controller/agent_social/agent, mob/living/partner)
	return "[partner.get_visible_name()] courted me all evening and I said yes to going somewhere private. Upstairs they welcomed my kisses and a good deal more, and told me to take the lead."

/datum/agent_stage_preset/welcomed/apply(datum/ai_controller/agent_social/agent, mob/living/partner)
	agent.grant_consent(partner)
	agent.advance_record(partner).welcomed_intimate = TRUE
	agent_stage_line(agent, partner, "Come here.")

/datum/agent_stage_preset/paid
	id = "paid"
	name = "Paid customer: a quarter hour bought"
	needs = "service"

/datum/agent_stage_preset/paid/summary(datum/ai_controller/agent_social/agent, mob/living/partner)
	return "[partner.get_visible_name()] paid me [AGENT_SERVICE_PRICE] amnas for a quarter hour of my company just now, and we have gone somewhere quiet."

/datum/agent_stage_preset/paid/apply(datum/ai_controller/agent_social/agent, mob/living/partner)
	if(!agent_stage_paid(agent, partner))
		return "[agent.pawn] will not sell to [partner] right now"

/// The act the NPC leads right now, or null.
/proc/agent_stage_led_act(mob/living/leader)
	var/datum/sex_scene_controller/controller = leader?.sex_scene?.get_controller(leader)
	var/list/owned = controller?.get_owned_actions()
	return length(owned) ? owned[1] : null

/// "Kiss them" as the character would recall it: "kiss them".
/proc/agent_stage_act_words(datum/sex_action/act)
	var/name = "[act.name]"
	return lowertext(copytext(name, 1, 2)) + copytext(name, 2)

/datum/agent_stage_preset/mid_act
	needs = "private"
	/// How far the staged act goes, on the advance ladder.
	var/rank = AGENT_ADVANCE_TENDER

/datum/agent_stage_preset/mid_act/summary(datum/ai_controller/agent_social/agent, mob/living/partner)
	var/datum/sex_action/act = agent_stage_led_act(agent.pawn)
	var/began = act ? "I began to [agent_stage_act_words(act)]." : "I began."
	var/datum/component/agent_shop/shop = agent.pawn.GetComponent(/datum/component/agent_shop)
	if(istype(shop?.stock, /datum/agent_stock/service))
		return "[partner.get_visible_name()] paid me [AGENT_SERVICE_PRICE] amnas for a quarter hour of my company and we went somewhere quiet. [began]"
	return "[partner.get_visible_name()] courted me all evening and I said yes to going somewhere private. We are there now. [began]"

/datum/agent_stage_preset/mid_act/apply(datum/ai_controller/agent_social/agent, mob/living/partner)
	var/datum/component/agent_shop/shop = agent.pawn.GetComponent(/datum/component/agent_shop)
	if(istype(shop?.stock, /datum/agent_stock/service))
		if(!agent_stage_paid(agent, partner))
			return "[agent.pawn] will not sell to [partner] right now"
	else
		agent.grant_consent(partner)
	var/act_type = agent.pick_advance_act(partner, rank)
	if(!act_type)
		return "nothing at that level fits the two of them right now: parts, armour, or distance"
	if(!agent.start_advance_act(partner, act_type, rank))
		return "the act did not start"

/datum/agent_stage_preset/mid_act/tender
	id = "mid_act_tender"
	name = "Mid-act, tender: the NPC is leading a kiss or a caress"
	rank = AGENT_ADVANCE_TENDER

/datum/agent_stage_preset/mid_act/intimate
	id = "mid_act_intimate"
	name = "Mid-act, intimate: the NPC is leading something more"
	rank = AGENT_ADVANCE_INTIMATE

/datum/agent_stage_preset/aroused
	id = "aroused"
	name = "Aroused: both bodies burning"

/datum/agent_stage_preset/aroused/apply(datum/ai_controller/agent_social/agent, mob/living/partner)
	agent_stage_arousal(agent.pawn, 420, 40)
	agent_stage_arousal(partner, 320, 40)

/datum/agent_stage_preset/close
	id = "close"
	name = "Close: the NPC near its peak"

/datum/agent_stage_preset/close/apply(datum/ai_controller/agent_social/agent, mob/living/partner)
	agent_stage_arousal(agent.pawn, 450, 110)
	agent_stage_arousal(partner, 350, 60)

/datum/agent_stage_preset/haggling
	id = "haggling"
	name = "Haggling: a liked customer at the stall"
	needs = "shop"

/datum/agent_stage_preset/haggling/summary(datum/ai_controller/agent_social/agent, mob/living/partner)
	return "[partner.get_visible_name()] has been bargaining at my stall all day, good-humoured about it, and I have taken a liking to them."

/datum/agent_stage_preset/haggling/apply(datum/ai_controller/agent_social/agent, mob/living/partner)
	var/datum/component/agent_shop/shop = agent.pawn.GetComponent(/datum/component/agent_shop)
	agent.note_shop_event(AGENT_EVENT_CUSTOMER, partner, list("kind" = shop?.stock?.kind))
	agent_stage_line(agent, partner, "What's your best price for me, then?")
