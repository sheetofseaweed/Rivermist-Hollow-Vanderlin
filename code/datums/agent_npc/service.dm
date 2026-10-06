// Selling company. Paid time is the only way to share a scene with an agent NPC, and DM runs all of it.

/// Acts a performer offers to lead. The customer can still lead any act through the normal scene window.
GLOBAL_LIST_INIT(agent_service_acts, list(
	/datum/sex_action/kissing,
	/datum/sex_action/rub_body,
	/datum/sex_action/masturbate/other/breasts,
	/datum/sex_action/suck_nipples,
	/datum/sex_action/masturbate/other/penis,
	/datum/sex_action/blowjob,
	/datum/sex_action/sex/other/thighjob,
	/datum/sex_action/sex/other/boobjob,
	/datum/sex_action/sex/other/vagina,
	/datum/sex_action/frotting,
	/datum/sex_action/masturbate/other/clit,
	/datum/sex_action/masturbate/other/vagina,
	/datum/sex_action/cunnilingus,
	/datum/sex_action/sex/vaginal,
	/datum/sex_action/scissoring,
	/datum/sex_action/sex/anal,
	/datum/sex_action/sex/other/anal,
	/datum/sex_action/masturbate/other/anus,
	/datum/sex_action/rimming,
	/datum/sex_action/suck_balls,
	/datum/sex_action/facesitting,
	/datum/sex_action/tonguebath,
))

/// Offered only once the customer asks for it rough.
GLOBAL_LIST_INIT(agent_service_rough_acts, list(
	/datum/sex_action/sex/throat,
	/datum/sex_action/spanking,
	/datum/sex_action/masturbate/other/slap_balls,
	/datum/sex_action/masturbate/other/slap_breasts,
	/datum/sex_action/masturbate/other/slap_pussy,
	/datum/sex_action/foot_lick,
	/datum/sex_action/sex/other/footjob,
	/datum/sex_action/armpit_nuzzle,
	/datum/sex_action/crotch_nuzzle,
	/datum/sex_action/penis_head_worship,
	/datum/sex_action/tailjob/penis,
	/datum/sex_action/tailjob/vagina,
	/datum/sex_action/masturbate/penis_over,
))

/// Sells time in the keeper's company. A customer with time left may share a scene with it, or have it lead one.
/datum/agent_stock/service
	kind = "service"
	shop_label = "performer: sells company by the quarter hour"
	sold_verb = "paid"
	/// One block of paid time, and what it costs.
	var/block = AGENT_SERVICE_BLOCK
	var/block_price = AGENT_SERVICE_PRICE
	/// The price is multiplied by this while a player works one of rival_jobs, so players keep the trade.
	var/rival_markup = AGENT_SERVICE_RIVAL_MARKUP
	var/list/rival_jobs = list(/datum/job/advclass/tavern_wench/courtesan, /datum/job/advclass/tavern_wench/bath_wench)
	/// Who has paid, and when their time runs out.
	var/datum/weakref/customer_ref
	var/paid_until = 0
	/// The customer asked for it rough: the rough acts are offered, and every act is harder.
	var/rough = FALSE
	/// Coin taken. It falls where the keeper dies.
	var/purse = 0
	/// Whether an act was running at the last look, so its end reaches the model once.
	var/was_private = FALSE
	var/watch_timer

/datum/agent_stock/service/New(mob/living/new_keeper)
	. = ..()
	// A body that offers this needs the parts for it.
	keeper?.give_genitals()

/datum/agent_stock/service/Destroy(force)
	deltimer(watch_timer)
	spill(get_turf(keeper))
	customer_ref = null
	return ..()

/datum/agent_stock/service/wares()
	return list(AGENT_SERVICE_WARE)

/datum/agent_stock/service/ware_name(ware)
	return "[round(block / (1 MINUTES))] minutes of company"

/datum/agent_stock/service/ware_price(ware)
	if(ware != AGENT_SERVICE_WARE)
		return null
	return rivals_at_work() ? block_price * rival_markup : block_price

/datum/agent_stock/service/ware_image(ware)
	return image(icon = 'icons/hud/radial.dmi', icon_state = "radial_mob")

/// Grants the time. Buying again adds to it; someone else must wait until it runs out.
/datum/agent_stock/service/hand_over(ware, mob/living/buyer)
	if(ware != AGENT_SERVICE_WARE || sale_refusal(buyer))
		return FALSE
	if(current_customer() != buyer)
		customer_ref = WEAKREF(buyer)
		paid_until = world.time
		rough = FALSE
		was_private = FALSE
	paid_until = max(paid_until, world.time) + block
	start_watching()
	return TRUE

/datum/agent_stock/service/receive(amount)
	purse += amount

/datum/agent_stock/service/purse_amount()
	return purse

/datum/agent_stock/service/spill(turf/where)
	if(where && purse > 0)
		add_mammons_to_atom(where, purse)
	purse = 0

/datum/agent_stock/service/sale_refusal(mob/living/customer)
	var/mob/living/current = current_customer()
	if(current && current != customer)
		return "is with someone else for now"
	return null

/datum/agent_stock/service/menu_extras(mob/living/customer)
	if(!customer || customer != current_customer())
		return null
	var/list/extras = list()
	extras[AGENT_SERVICE_LEAD] = image(icon = 'icons/hud/radial.dmi', icon_state = "radial_use")
	if(rough)
		extras[AGENT_SERVICE_GENTLE] = image(icon = 'icons/hud/radial.dmi', icon_state = "pink")
	else
		extras[AGENT_SERVICE_ROUGH] = image(icon = 'icons/hud/radial.dmi', icon_state = "radial_damage")
	if(length(leading_acts()))
		extras[AGENT_SERVICE_STOP] = image(icon = 'icons/hud/radial.dmi', icon_state = "radial_no")
	return extras

/datum/agent_stock/service/pick_extra(choice, mob/living/customer)
	if(!customer || customer != current_customer())
		return
	switch(choice)
		if(AGENT_SERVICE_LEAD)
			lead_menu(customer)
		if(AGENT_SERVICE_ROUGH, AGENT_SERVICE_GENTLE)
			set_rough(choice == AGENT_SERVICE_ROUGH, customer)
		if(AGENT_SERVICE_STOP)
			keeper_controller()?.stop_action()

/datum/agent_stock/service/describe_extra()
	var/mob/living/current = current_customer()
	if(!current)
		return null
	return list("with" = current.get_visible_name(), "minutes_left" = max(1, CEILING((paid_until - world.time) / (1 MINUTES), 1)))

/// The customer with paid time left, or null.
/datum/agent_stock/service/proc/current_customer()
	RETURN_TYPE(/mob/living)
	if(world.time >= paid_until)
		return null
	var/mob/living/current = customer_ref?.resolve()
	return QDELETED(current) ? null : current

/// Why the keeper will not share a scene with them, as words after its name, or null.
/datum/agent_stock/service/proc/consent_refusal(mob/living/other)
	if(QDELETED(keeper) || keeper.stat != CONSCIOUS)
		return "is in no state for that"
	var/datum/ai_controller/agent_social/agent = keeper.ai_controller
	if(istype(agent))
		if(agent.in_combat())
			return "is busy fighting"
		if(agent.is_aggressor(other))
			return "will have nothing to do with you after what you did"
	var/mob/living/current = current_customer()
	if(other && other == current)
		return null
	if(current)
		return "is with someone else for now"
	return "wants to be paid first"

/// A player at work in a job that sells the same. The keeper charges more then.
/datum/agent_stock/service/proc/rivals_at_work()
	for(var/mob/living/carbon/human/worker in GLOB.player_list)
		if(worker.stat != DEAD && worker.mind?.assigned_role && is_type_in_list(worker.mind.assigned_role, rival_jobs))
			return TRUE
	return FALSE

/// The keeper's own side of the scene, if it has one.
/datum/agent_stock/service/proc/keeper_controller()
	RETURN_TYPE(/datum/sex_scene_controller)
	return keeper?.sex_scene?.get_controller(keeper)

/// Acts the keeper is running on its customer.
/datum/agent_stock/service/proc/leading_acts()
	var/datum/sex_scene_controller/controller = keeper_controller()
	return controller?.get_active_actions()

/// The acts the keeper could start on this customer right now, by name.
/datum/agent_stock/service/proc/startable_acts(mob/living/customer)
	var/list/acts = list()
	var/datum/sex_scene_controller/controller = keeper.open_sex_scene(customer, FALSE)
	if(!controller)
		return acts
	var/list/offered = rough ? GLOB.agent_service_acts + GLOB.agent_service_rough_acts : GLOB.agent_service_acts
	for(var/act_type in offered)
		var/datum/sex_action_proposal/proposal = controller.create_action_proposal(act_type, "ai")
		if(proposal?.can_start())
			acts[proposal.action.name] = act_type
		qdel(proposal)
	return acts

/// The customer picks what the keeper does. Nothing starts until they do.
/datum/agent_stock/service/proc/lead_menu(mob/living/customer)
	var/list/acts = startable_acts(customer)
	if(!length(acts))
		to_chat(customer, span_warning("[keeper] can do nothing with you like this. Armour may be in the way."))
		return
	var/picked = tgui_input_list(customer, "What should [keeper] do?", "[keeper]", acts)
	if(!picked || !acts[picked] || customer != current_customer() || get_dist(keeper, customer) > 1)
		return
	start_act(customer, acts[picked])

/// One act at a time: a new pick replaces whatever the keeper was doing.
/datum/agent_stock/service/proc/start_act(mob/living/customer, act_type)
	var/datum/sex_scene_controller/controller = keeper.open_sex_scene(customer, FALSE)
	if(!controller)
		return null
	controller.stop_action()
	keeper.face_atom(customer)
	apply_pace(controller)
	var/datum/sex_action/started = controller.try_start_action(act_type, "ai")
	if(!started)
		to_chat(customer, span_warning("[keeper] cannot do that right now."))
	return started

/datum/agent_stock/service/proc/apply_pace(datum/sex_scene_controller/controller)
	controller.set_current_force(rough ? SEX_FORCE_HIGH : SEX_FORCE_MID)
	controller.set_current_speed(rough ? SEX_SPEED_HIGH : SEX_SPEED_MID)

/// Asking for it gentle also ends any rough act already running.
/datum/agent_stock/service/proc/set_rough(new_rough, mob/living/customer)
	rough = !!new_rough
	to_chat(customer, span_notice(rough ? "[keeper] will be rough with you." : "[keeper] will be gentle with you."))
	var/datum/sex_scene_controller/controller = keeper_controller()
	if(!controller)
		return
	apply_pace(controller)
	if(rough)
		return
	for(var/datum/sex_action/action as anything in controller.get_active_actions())
		if(action.type in GLOB.agent_service_rough_acts)
			controller.stop_action(action)

/datum/agent_stock/service/proc/start_watching()
	if(!watch_timer)
		watch_timer = addtimer(CALLBACK(src, PROC_REF(watch)), AGENT_SERVICE_WATCH_INTERVAL, TIMER_STOPPABLE)

/// While someone has paid: tell the model when an act ends, and when the time is up.
/datum/agent_stock/service/proc/watch()
	// Called early, a pending look would otherwise run alongside the next one.
	deltimer(watch_timer)
	watch_timer = null
	if(QDELETED(keeper))
		return
	var/mob/living/current = customer_ref?.resolve()
	var/private = length(keeper.sex_scene?.get_actions_involving(keeper)) > 0
	if(was_private && !private && current)
		tell_agent(current, "spent")
	was_private = private
	if(world.time < paid_until)
		start_watching()
		return
	// Consent ends with the time, so any act still running stops on its next step.
	customer_ref = null
	rough = FALSE
	was_private = FALSE
	if(current)
		tell_agent(current, "time_up")

/datum/agent_stock/service/proc/tell_agent(mob/living/customer, what)
	var/datum/ai_controller/agent_social/agent = keeper?.ai_controller
	if(istype(agent) && !QDELETED(customer))
		agent.note_shop_event(AGENT_EVENT_PRIVATE_TIME, customer, list("what" = what))
