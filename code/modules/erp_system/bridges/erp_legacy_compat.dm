/datum/sex_action
	var/erp_action_path = null
	var/erp_required_init_organ = null
	var/erp_required_target_organ = null

/datum/sex_session
	var/mob/living/user
	var/mob/living/target
	var/current_action = null
	var/force = null
	var/speed = null
	var/edging_other = FALSE

/datum/sex_session/New(mob/living/new_user, mob/living/new_target)
	. = ..()
	user = new_user
	target = new_target || new_user
	_refresh_current_action()

/datum/sex_session/proc/_find_existing_controller()
	if(!user || QDELETED(user))
		return null

	var/datum/erp_controller/controller = null
	if(user.client)
		controller = SSerp.get_controller_for_client(user.client)
	if(!controller)
		controller = SSerp.get_controller_for(user)

	return controller

/datum/sex_session/proc/_resolve_controller(create = TRUE, set_active = TRUE)
	if(!user || QDELETED(user))
		return null

	var/datum/erp_controller/controller = _find_existing_controller()
	if(!controller && create)
		controller = SSerp.get_or_create_controller(user, user.client, user)
	if(!controller)
		return null

	if(set_active)
		var/atom/partner_atom = target
		if(!partner_atom || QDELETED(partner_atom))
			partner_atom = user
		controller.add_partner_atom(partner_atom, TRUE)

	return controller

/datum/sex_session/proc/_link_matches_pair(datum/erp_sex_link/link)
	if(!link || QDELETED(link))
		return FALSE

	var/mob/living/actor_a = link.actor_active?.physical
	var/mob/living/actor_b = link.actor_passive?.physical
	if(!actor_a || !actor_b)
		return FALSE

	if(user == target)
		return actor_a == user && actor_b == user

	return (actor_a == user && actor_b == target) || (actor_a == target && actor_b == user)

/datum/sex_session/proc/_get_pair_links()
	var/list/out = list()
	var/datum/erp_controller/controller = _resolve_controller(FALSE, FALSE)
	if(!controller)
		return out

	for(var/datum/erp_sex_link/link in controller.links)
		if(_link_matches_pair(link))
			out += link

	return out

/datum/sex_session/proc/_refresh_current_action()
	current_action = null

	var/list/pair_links = _get_pair_links()
	if(!length(pair_links))
		return

	var/datum/erp_sex_link/link = pair_links[1]
	if(link?.action)
		current_action = link.action.type

/datum/sex_session/proc/_pick_action_organ(datum/erp_controller/controller, list/by_type, datum/erp_sex_organ/any_organ, preferred_type)
	if(!controller)
		return null

	if(preferred_type)
		return by_type[controller.actions_d.normalize_organ_type(preferred_type)]

	return any_organ

/datum/sex_session/proc/_start_erp_action(datum/sex_action/legacy_action)
	if(!legacy_action?.erp_action_path)
		return FALSE

	var/datum/erp_controller/controller = _resolve_controller(TRUE, TRUE)
	if(!controller || !controller.owner || !controller.active_partner)
		return FALSE

	var/datum/erp_action/action = controller.get_action_by_id_or_path(legacy_action.erp_action_path)
	if(!action)
		return FALSE

	var/list/owner_pick = controller.actions_d.pick_first_by_type(controller.owner, TRUE)
	var/list/partner_pick = controller.actions_d.pick_first_by_type(controller.active_partner, FALSE)

	var/preferred_init = legacy_action.erp_required_init_organ
	if(!preferred_init)
		preferred_init = action.required_init_organ

	var/preferred_target = legacy_action.erp_required_target_organ
	if(!preferred_target)
		preferred_target = action.required_target_organ

	var/datum/erp_sex_organ/init_organ = _pick_action_organ(controller, owner_pick["by"], owner_pick["any"], preferred_init)
	var/datum/erp_sex_organ/target_organ = _pick_action_organ(controller, partner_pick["by"], partner_pick["any"], preferred_target)
	if(!init_organ || !target_organ)
		return FALSE

	var/reason = controller.get_action_block_reason(action, init_organ, target_organ)
	if(!isnull(reason))
		return FALSE

	controller.links_d?.stop_pair_links(user, target, FALSE)

	var/list/organs = list(
		"init" = init_organ,
		"target" = target_organ,
	)
	var/datum/erp_sex_link/link = new(controller.owner, controller.active_partner, action, organs, controller)

	if(!isnull(force))
		link.force = clamp(force, SEX_FORCE_MIN, SEX_FORCE_MAX)
	if(!isnull(speed))
		link.speed = clamp(speed, SEX_SPEED_MIN, SEX_SPEED_MAX)

	controller.links += link
	controller._send_link_start_message(link)
	controller.ui?.request_update()
	return TRUE

/datum/sex_session/proc/show_ui(selected_tab = "interactions")
	var/datum/erp_controller/controller = _resolve_controller(TRUE, TRUE)
	if(!controller)
		return FALSE

	controller.open_ui(user)
	return TRUE

/datum/sex_session/proc/try_start_action(action_type)
	if(!action_type || !ispath(action_type, /datum/sex_action))
		return FALSE

	_refresh_current_action()

	var/datum/sex_action/action = new action_type
	if(!action)
		return FALSE

	if(ishuman(user) && ishuman(target))
		if(!action.can_perform(user, target))
			qdel(action)
			return FALSE

	if(!_start_erp_action(action))
		qdel(action)
		return FALSE

	if(ishuman(user) && ishuman(target))
		action.on_start(user, target)

	current_action = action_type
	qdel(action)
	return TRUE

/datum/sex_session/proc/stop_current_action()
	_refresh_current_action()

	var/old_action = current_action
	var/datum/erp_controller/controller = _resolve_controller(FALSE, FALSE)
	if(controller)
		controller.links_d?.stop_pair_links(user, target, FALSE)
		controller.ui?.request_update()

	current_action = null

	if(old_action && ispath(old_action, /datum/sex_action) && ishuman(user) && ishuman(target))
		var/datum/sex_action/action = new old_action
		if(action)
			action.on_finish(user, target)
			qdel(action)

/datum/sex_session/proc/finished_check()
	if(!user || QDELETED(user))
		return TRUE
	if(!target || QDELETED(target))
		return TRUE

	return !length(_get_pair_links())

/datum/sex_session/proc/get_current_force()
	var/list/pair_links = _get_pair_links()
	if(length(pair_links))
		var/datum/erp_sex_link/link = pair_links[1]
		if(link)
			return clamp(round(link.force || SEX_FORCE_MID), SEX_FORCE_MIN, SEX_FORCE_MAX)

	var/datum/erp_controller/controller = _resolve_controller(FALSE, FALSE)
	if(controller)
		return clamp(round(controller.default_link_force || SEX_FORCE_MID), SEX_FORCE_MIN, SEX_FORCE_MAX)

	if(!isnull(force))
		return clamp(round(force), SEX_FORCE_MIN, SEX_FORCE_MAX)
	return SEX_FORCE_MID

/datum/sex_session/proc/get_current_speed()
	var/list/pair_links = _get_pair_links()
	if(length(pair_links))
		var/datum/erp_sex_link/link = pair_links[1]
		if(link)
			return clamp(round(link.speed || SEX_SPEED_MID), SEX_SPEED_MIN, SEX_SPEED_MAX)

	var/datum/erp_controller/controller = _resolve_controller(FALSE, FALSE)
	if(controller)
		return clamp(round(controller.default_link_speed || SEX_SPEED_MID), SEX_SPEED_MIN, SEX_SPEED_MAX)

	if(!isnull(speed))
		return clamp(round(speed), SEX_SPEED_MIN, SEX_SPEED_MAX)
	return SEX_SPEED_MID

/datum/sex_session/proc/set_current_force(new_force)
	force = clamp(round(new_force), SEX_FORCE_MIN, SEX_FORCE_MAX)

	var/datum/erp_controller/controller = _resolve_controller(TRUE, TRUE)
	if(!controller)
		return

	controller.default_link_force = force
	for(var/datum/erp_sex_link/link in _get_pair_links())
		link.force = force
	controller.ui?.request_update()

/datum/sex_session/proc/set_current_speed(new_speed)
	speed = clamp(round(new_speed), SEX_SPEED_MIN, SEX_SPEED_MAX)

	var/datum/erp_controller/controller = _resolve_controller(TRUE, TRUE)
	if(!controller)
		return

	controller.default_link_speed = speed
	for(var/datum/erp_sex_link/link in _get_pair_links())
		link.speed = speed
	controller.ui?.request_update()

/datum/sex_session/proc/get_generic_force_adjective()
	return SSerp?.link_presenter?.get_force_text(get_current_force()) || "firmly"

/datum/sex_session/proc/spanify_force(string)
	var/datum/erp_controller/controller = _resolve_controller(FALSE, FALSE)
	if(controller?.scene_msg_d)
		return controller.scene_msg_d.spanify_scene_text(string, get_current_force(), get_current_speed())

	switch(get_current_force())
		if(SEX_FORCE_LOW)
			return "<span class='love_low'>[string]</span>"
		if(SEX_FORCE_HIGH)
			return "<span class='love_high'>[string]</span>"
		if(SEX_FORCE_EXTREME)
			return "<span class='love_extreme'>[string]</span>"

	return "<span class='love_mid'>[string]</span>"

/datum/sex_session/proc/get_force_sound()
	switch(get_current_force())
		if(SEX_FORCE_HIGH, SEX_FORCE_EXTREME)
			return pick(SEX_SOUNDS_HARD)

	return pick(SEX_SOUNDS_SLOW)

/datum/sex_session/proc/perform_sex_action(mob/living/action_target, mob/living/action_initiator, arousal_amt, pain_amt, orgasm_prog_amt, sex_act = null)
	if(!action_target || !action_initiator || !user)
		return

	var/current_force = get_current_force()
	var/current_speed = get_current_speed()

	var/list/arousal_data_target = list()
	SEND_SIGNAL(action_target, COMSIG_SEX_GET_AROUSAL, arousal_data_target)

	if(HAS_TRAIT(user, TRAIT_GOODLOVER) && user != action_initiator)
		arousal_amt *= 1.5
		orgasm_prog_amt *= 1.5
		if(prob(10))
			var/lovermessage = pick("This feels so good!", "I am in nirvana!", "This is too good to be possible!", "By the Gods!", "I can't stop, too good!~")
			to_chat(action_target, span_love(lovermessage))

	if(action_target != user && edging_other)
		if(arousal_data_target["arousal"] >= AROUSAL_EDGING_THRESHOLD + 15)
			var/succes_chance = 100
			if(prob(5))
				to_chat(user, span_love("I try to match my movements so that they don't climax too soon..."))
			if(current_speed > SEX_SPEED_MID || current_force > SEX_FORCE_MID)
				succes_chance *= 0.5
			if(action_target.has_status_effect(/datum/status_effect/edging_overstimulation))
				succes_chance *= 0.3
				if(prob(10))
					to_chat(user, span_love("They are just too sensitive for me to control their pleasure..."))
			if(user.get_stat_level(STATKEY_PER) < 7)
				succes_chance *= 0.7
				if(prob(10))
					to_chat(user, span_love("I can't tell if they are close or not..."))
			if(prob(succes_chance))
				SEND_SIGNAL(action_target, COMSIG_SEX_EDGED_BY_OTHER_STATE, TRUE)

	var/res_send = RESIST_NONE
	var/mob/living/action_user_final = null
	var/giving = TRUE

	if(user == action_initiator)
		action_user_final = user
	else
		action_user_final = action_initiator
		giving = FALSE

	var/list/arousal_data_user = list()
	SEND_SIGNAL(action_user_final, COMSIG_SEX_GET_AROUSAL, arousal_data_user)
	res_send = arousal_data_user["resistance_to_pleasure"]

	SEND_SIGNAL(action_user_final, COMSIG_SEX_RECEIVE_ACTION, sex_act, action_initiator, action_target, arousal_amt, pain_amt, orgasm_prog_amt, giving, current_force, current_speed, res_send)

/datum/sex_session/proc/handle_passive_ejaculation(mob/living/handler)
	if(!handler)
		handler = user
	if(!handler)
		return

	var/list/arousal_data = list()
	SEND_SIGNAL(handler, COMSIG_SEX_GET_AROUSAL, arousal_data)
	var/arousal_multiplier = arousal_data["arousal_multiplier"]
	var/arousal_value = arousal_data["arousal"]

	if(arousal_multiplier > 1.5 && user.check_handholding())
		if(prob(5))
			SEND_SIGNAL(handler, COMSIG_SEX_RECEIVE_ACTION, 3, 0, 1, 0)
		if(arousal_value < 70)
			SEND_SIGNAL(handler, COMSIG_SEX_ADJUST_AROUSAL, 0.2)

		var/mob/living/carbon/carbon_handler = handler
		if(carbon_handler?.handcuffed)
			if(prob(8))
				var/chaffepain = pick(10, 10, 10, 10, 20, 20, 30)
				SEND_SIGNAL(handler, COMSIG_SEX_RECEIVE_ACTION, 3, chaffepain, 1, 0)
				handler.visible_message("<span class='love_mid'>[handler] squirms uncomfortably in [handler.p_their()] restraints.</span>", "<span class='love_extreme'>I feel [carbon_handler.handcuffed] rub uncomfortably against my skin.</span>")
			if(arousal_value < ACTIVE_EJAC_THRESHOLD)
				SEND_SIGNAL(handler, COMSIG_SEX_ADJUST_AROUSAL, 0.25)

/proc/get_sex_session(mob/living/user, mob/living/target)
	if(!user || QDELETED(user))
		return null

	if(!target || QDELETED(target))
		target = user

	return new /datum/sex_session(user, target)

/datum/sex_action/masturbate/anus
	name = "Anal Masturbation"
	erp_action_path = /datum/erp_action/self/hands/fingering_anal
	erp_required_init_organ = SEX_ORGAN_HANDS
	erp_required_target_organ = SEX_ORGAN_ANUS
	hole_id = ORGAN_SLOT_ANUS

/datum/sex_action/masturbate/vagina
	name = "Vaginal Masturbation"
	erp_action_path = /datum/erp_action/self/hands/teasing_clitoris
	erp_required_init_organ = SEX_ORGAN_HANDS
	erp_required_target_organ = SEX_ORGAN_VAGINA
	hole_id = ORGAN_SLOT_VAGINA

/datum/sex_action/masturbate/penis
	name = "Penis Masturbation"
	erp_action_path = /datum/erp_action/self/hands/masturbate_penis
	erp_required_init_organ = SEX_ORGAN_HANDS
	erp_required_target_organ = SEX_ORGAN_PENIS
	hole_id = ORGAN_SLOT_PENIS

/datum/sex_action/rub_body
	name = "Rub Body"
	erp_action_path = /datum/erp_action/other/body/rubbing
	erp_required_init_organ = SEX_ORGAN_BODY
	erp_required_target_organ = SEX_ORGAN_BODY

/datum/sex_action/npc/npc_anal_ride_sex
	name = "Ride Anally"
	erp_action_path = /datum/erp_action/other/anus/sex
	erp_required_init_organ = SEX_ORGAN_ANUS
	erp_required_target_organ = SEX_ORGAN_PENIS
	hole_id = ORGAN_SLOT_ANUS

/datum/sex_action/npc/npc_vaginal_ride_sex
	name = "Ride Vaginally"
	erp_action_path = /datum/erp_action/other/vagina/sex
	erp_required_init_organ = SEX_ORGAN_VAGINA
	erp_required_target_organ = SEX_ORGAN_PENIS
	hole_id = ORGAN_SLOT_VAGINA

/datum/sex_action/npc/npc_throat_sex
	name = "Throat Sex"
	erp_action_path = /datum/erp_action/other/penis/oral_sex
	erp_required_init_organ = SEX_ORGAN_PENIS
	erp_required_target_organ = SEX_ORGAN_MOUTH
	hole_id = BODY_ZONE_PRECISE_MOUTH
	gags_target = TRUE

/datum/sex_action/npc/npc_anal_sex
	name = "Anal Sex"
	erp_action_path = /datum/erp_action/other/penis/anal_sex
	erp_required_init_organ = SEX_ORGAN_PENIS
	erp_required_target_organ = SEX_ORGAN_ANUS
	hole_id = ORGAN_SLOT_ANUS

/datum/sex_action/npc/npc_vaginal_sex
	name = "Vaginal Sex"
	erp_action_path = /datum/erp_action/other/penis/vaginal_sex
	erp_required_init_organ = SEX_ORGAN_PENIS
	erp_required_target_organ = SEX_ORGAN_VAGINA
	hole_id = ORGAN_SLOT_VAGINA

/datum/sex_action/npc/npc_facesitting
	name = "Facesitting"
	erp_action_path = /datum/erp_action/other/anus/face
	erp_required_init_organ = SEX_ORGAN_ANUS
	erp_required_target_organ = SEX_ORGAN_MOUTH
	hole_id = BODY_ZONE_PRECISE_MOUTH
	gags_target = TRUE

/datum/sex_action/npc/npc_rimming
	name = "Rimming"
	erp_action_path = /datum/erp_action/other/mouth/rimming
	erp_required_init_organ = SEX_ORGAN_MOUTH
	erp_required_target_organ = SEX_ORGAN_ANUS
	hole_id = ORGAN_SLOT_ANUS

/datum/sex_action/npc/npc_cunnilingus
	name = "Cunnilingus"
	erp_action_path = /datum/erp_action/other/mouth/cunnilingus
	erp_required_init_organ = SEX_ORGAN_MOUTH
	erp_required_target_organ = SEX_ORGAN_VAGINA
	hole_id = ORGAN_SLOT_VAGINA
