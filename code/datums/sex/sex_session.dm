/datum/sex_action_effect_context
	var/mob/living/receiver
	var/mob/living/partner
	var/datum/sex_action/action
	var/mob/living/action_initiator
	var/mob/living/action_target
	var/mob/living/action_performer
	var/datum/sex_session/session
	var/giving = TRUE
	var/arousal_amt = 0
	var/pain_amt = 0
	var/orgasm_prog_amt = 0
	var/force = SEX_FORCE_MID
	var/speed = SEX_SPEED_MID
	var/resistance = RESIST_NONE
	var/climax_type = null
	var/mob/living/climaxer
	var/atom/climax_destination
	var/climax_method = null

/datum/sex_action_effect_context/New(mob/living/_receiver, mob/living/_partner, datum/sex_action/_action, mob/living/_action_initiator, mob/living/_action_target, _giving = TRUE)
	receiver = _receiver
	partner = _partner
	action = _action
	action_initiator = _action_initiator
	action_target = _action_target
	giving = _giving

/datum/sex_action_effect
	var/obj/item/source_item

/datum/sex_action_effect/New(obj/item/_source_item)
	source_item = _source_item

/datum/sex_action_effect/proc/modify_action(datum/sex_action_effect_context/context)
	return

/datum/sex_action_effect/proc/after_action(datum/sex_action_effect_context/context)
	return

/datum/sex_action_effect/proc/intercept_climax(datum/sex_action_effect_context/context, datum/reagents/source_reagents, amount)
	return 0

/obj/item/proc/get_sex_action_effects(datum/sex_action_effect_context/context)
	return null

/proc/collect_sex_action_effects(datum/sex_action_effect_context/context)
	var/list/effects = list()
	if(!context)
		return effects
	var/list/seen_items = list()
	collect_sex_action_effects_from_mob(context.action_initiator, context, effects, seen_items)
	collect_sex_action_effects_from_mob(context.action_target, context, effects, seen_items)
	return effects

/proc/collect_sex_action_effects_from_mob(mob/living/effect_mob, datum/sex_action_effect_context/context, list/effects, list/seen_items)
	if(!ishuman(effect_mob))
		return
	var/mob/living/carbon/human/human = effect_mob
	var/static/list/effect_slots = list(
		ORGAN_SLOT_PENIS,
		ORGAN_SLOT_VAGINA,
		ORGAN_SLOT_ANUS,
		ORGAN_SLOT_LEFT_NIP,
		ORGAN_SLOT_RIGHT_NIP,
		ORGAN_SLOT_BREASTS,
	)
	for(var/slot in effect_slots)
		var/obj/item/organ/organ = human.getorganslot(slot)
		if(!organ)
			continue
		var/list/stored_items = SEND_SIGNAL(organ, COMSIG_BODYSTORAGE_GET_2D_ITEM_LIST)
		if(!length(stored_items))
			continue
		for(var/obj/item/stored_item as anything in stored_items)
			if(!stored_item || (stored_item in seen_items))
				continue
			seen_items += stored_item
			var/list/item_effects = stored_item.get_sex_action_effects(context)
			if(length(item_effects))
				effects += item_effects

/proc/qdel_sex_action_effects(list/effects)
	for(var/datum/sex_action_effect/effect as anything in effects)
		qdel(effect)

/proc/apply_sex_action_climax_effects(mob/living/climaxer, mob/living/target, datum/sex_action/action, climax_type, datum/reagents/source_reagents, amount, atom/climax_destination, climax_method, mob/living/action_initiator, mob/living/action_target, mob/living/action_performer)
	if(!source_reagents || amount <= 0)
		return amount
	var/datum/sex_action_effect_context/context = new(climaxer, target, action, action_initiator ? action_initiator : climaxer, action_target ? action_target : target, TRUE)
	context.climaxer = climaxer
	context.climax_type = climax_type
	context.climax_destination = climax_destination
	context.climax_method = climax_method
	context.action_performer = action_performer
	var/list/effects = collect_sex_action_effects(context)
	var/remaining = amount
	for(var/datum/sex_action_effect/effect as anything in effects)
		if(remaining <= 0)
			break
		var/consumed = effect.intercept_climax(context, source_reagents, remaining)
		remaining = max(0, remaining - max(consumed, 0))
	qdel_sex_action_effects(effects)
	return remaining

/datum/sex_session //! TODO SEX SOUNDS
	/// The initiating user
	var/mob/living/user
	/// Target of our actions
	var/mob/living/target
	/// Active actions currently running in this session
	var/list/datum/sex_action/active_actions = list()
	/// Compatibility pointer for older callers that still expect one current action
	var/datum/sex_action/current_action = null
	/// Optional remote interaction context, such as Mage Hand.
	var/datum/sex_remote_context/remote_context = null
	/// Enum of desired speed
	var/speed = SEX_SPEED_MID
	/// Enum of desired force
	var/force = SEX_FORCE_MID
	/// Makes genital arousal automatic by default
	var/manual_arousal = SEX_MANUAL_AROUSAL_DEFAULT
	/// Whether we want to screw until finished, or non stop
	var/do_until_finished = TRUE
	///inactivity bumps
	var/inactivity = 0
	/// Reference to the collective this session belongs to
	var/datum/collective_message/collective = null
	///have we just climaxed?
	var/just_climaxed = FALSE

	var/static/sex_id = 0
	var/our_sex_id = 0

	/// Level of pleasure resistance
	var/resistance_to_pleasure = RESIST_NONE
	/// Level of edging others
	var/edging_other = FALSE

	var/static/list/action_zone_filter_options = list(
		"Any" = SEX_UI_ZONE_ANY,
		"Mouth" = SEX_UI_ZONE_MOUTH,
		"Genitals" = SEX_UI_ZONE_GENITALS,
		"Arms" = SEX_UI_ZONE_ARMS,
		"Legs" = SEX_UI_ZONE_LEGS,
		"Body" = SEX_UI_ZONE_BODY,
		"Misc" = SEX_UI_ZONE_MISC,
	)

/datum/sex_session/New(mob/living/session_user, mob/living/session_target)
	user = session_user
	target = session_target
	sex_id++
	our_sex_id = sex_id
	assign_to_collective()

	RegisterSignal(user, COMSIG_SEX_CLIMAX, PROC_REF(on_climax))
	RegisterSignal(user, COMSIG_SEX_AROUSAL_CHANGED, PROC_REF(on_arousal_changed))
	RegisterSignal(user, list(COMSIG_PARENT_QDELETING, COMSIG_LIVING_DEATH), PROC_REF(on_participant_invalidated))
	if(target != user)
		RegisterSignal(target, list(COMSIG_PARENT_QDELETING, COMSIG_LIVING_DEATH), PROC_REF(on_participant_invalidated))

	addtimer(CALLBACK(src, PROC_REF(check_sex)), 30 SECONDS)

/datum/sex_session/Destroy(force, ...)
	if(user)
		UnregisterSignal(user, list(COMSIG_SEX_CLIMAX, COMSIG_SEX_AROUSAL_CHANGED, COMSIG_PARENT_QDELETING, COMSIG_LIVING_DEATH))
	if(target && target != user)
		UnregisterSignal(target, list(COMSIG_PARENT_QDELETING, COMSIG_LIVING_DEATH))
	stop_current_action()
	clear_remote_context()
	unregister_sex_session(src)
	// Remove from collective
	if(collective)
		collective.sessions -= src
		// If this was the last session in the collective, remove the collective
		if(!length(collective.sessions))
			//collective.unregister_collective_tab()
			LAZYREMOVE(GLOB.sex_collectives, collective)
			qdel(collective)
		collective = null

	if(active_actions)
		active_actions.Cut()
	active_actions = null
	current_action = null
	remote_context = null
	user = null
	target = null
	. = ..()


/datum/sex_session/proc/assign_to_collective()
	// Check if we can merge with an existing collective
	for(var/datum/collective_message/existing_collective in GLOB.sex_collectives)
		if(existing_collective.can_merge_session(src))
			existing_collective.merge_session(src)
			return

	// No existing collective found, create a new one
	var/datum/collective_message/new_collective = new /datum/collective_message(src)
	LAZYADD(GLOB.sex_collectives, new_collective)
	collective = new_collective

/datum/sex_session/proc/check_sex()
	if(length(active_actions) || is_ui_open())
		inactivity--
		inactivity = CLAMP(inactivity, 0, 11)
		addtimer(CALLBACK(src, PROC_REF(check_sex)), 30 SECONDS)
		return

	inactivity++

	if(inactivity < 5)
		addtimer(CALLBACK(src, PROC_REF(check_sex)), 30 SECONDS)
		return
	qdel(src)

/datum/sex_session/proc/on_participant_invalidated()
	SIGNAL_HANDLER
	qdel(src)

/datum/sex_session/proc/is_ui_open()
	if(!user?.client)
		return FALSE
	return !!SStgui.get_open_ui(user, src)

/datum/sex_session/proc/show_ui()
	if(!user?.client)
		return
	ui_interact(user)

/datum/sex_session/proc/on_arousal_changed()
	SIGNAL_HANDLER
	SStgui.update_uis(src)

/datum/sex_session/proc/check_climax()
	var/list/arousal_data = list()
	SEND_SIGNAL(user, COMSIG_SEX_GET_AROUSAL, arousal_data)
	if(arousal_data["arousal"] < ACTIVE_EJAC_THRESHOLD)
		return FALSE
	return TRUE

/datum/sex_session/proc/get_active_action(action_ref)
	if(istype(action_ref, /datum/sex_action))
		var/datum/sex_action/action = action_ref
		if(action in active_actions)
			return action
		action_ref = action.get_menu_action_key()

	var/action_key = get_action_key(action_ref)
	for(var/datum/sex_action/action as anything in active_actions)
		if(action_key && action.get_menu_action_key() == action_key)
			return action
		if(ispath(action_ref, /datum/sex_action) && action.type == action_ref)
			return action
	return null

/datum/sex_session/proc/is_action_active(action_type)
	return !isnull(get_active_action(action_type))

/datum/sex_session/proc/get_action_priority(datum/sex_action/action, mob/living/viewer)
	if(!action || !viewer)
		return -1000000
	if(viewer == target)
		return action.target_priority
	if(viewer == user)
		return action.user_priority
	return -1000000

/datum/sex_session/proc/get_highest_priority_action_for(mob/living/viewer)
	var/datum/sex_action/highest_action
	for(var/datum/sex_action/action as anything in active_actions)
		if(!highest_action)
			highest_action = action
			continue
		if(get_action_priority(action, viewer) > get_action_priority(highest_action, viewer))
			highest_action = action
	return highest_action

/datum/sex_session/proc/update_current_action()
	current_action = get_highest_priority_action_for(user)

/datum/sex_session/proc/try_start_action(action_type)
	if(is_action_active(action_type))
		try_stop_current_action(action_type)
		return
	var/datum/sex_action/action = instantiate_action(action_type)
	if(!action)
		return
	if(!can_perform_action(action))
		return

	active_actions += action
	update_current_action()
	inactivity = 0
	log_combat(user, target, "Started sex action: [action.name] with [target.name].")
	INVOKE_ASYNC(src, PROC_REF(sex_action_loop), action)

/datum/sex_session/proc/try_stop_current_action(action_ref)
	if(!length(active_actions))
		return
	if(!action_ref)
		stop_current_action()
		return

	var/datum/sex_action/action = get_active_action(action_ref)
	if(action)
		stop_current_action(action)

/datum/sex_session/proc/considered_limp(mob/limper)
	if(QDELETED(limper))
		return TRUE // If no limper or deleted, consider it limp
	var/list/arousal_data = list()
	SEND_SIGNAL(limper, COMSIG_SEX_GET_AROUSAL, arousal_data)
	var/arousal_value = arousal_data["arousal"]
	if(arousal_value >= VISIBLE_AROUSAL_THRESHOLD)
		return FALSE
	return TRUE

/datum/sex_session/proc/sex_action_loop(datum/sex_action/action)
	if(!action || !(action in active_actions))
		return
	if(!can_perform_action(action, TRUE))
		stop_current_action(action)
		return
	var/suppress_visible_messages = begin_remote_action_visible_message_suppression(action)
	var/start_result = action.on_start(user, target)
	end_remote_action_visible_message_suppression(suppress_visible_messages)
	if(start_result == FALSE)
		stop_current_action(action)
		return
	var/datum/sex_remote_context/action_remote_context = get_valid_remote_context(action)
	if(action_remote_context)
		action_remote_context.show_action_overlay(action)
		action_remote_context.show_action_message(action, MAGE_HAND_ACTION_MESSAGE_START)

	while(action in active_actions)
		//if(isnull(target.client))
		//	break

		var/stamina_cost = action.stamina_cost * get_stamina_cost_multiplier()
		if(!user.adjust_stamina(-stamina_cost))
			break

		var/do_time = action.do_time / get_speed_multiplier()
		var/do_after_flags = IGNORE_USER_DIR_CHANGE | IGNORE_HELD_ITEM | IGNORE_SLOWDOWNS | IGNORE_SLOWDOWNS | IGNORE_USER_DOING | IGNORE_USER_LOC_CHANGE | IGNORE_TARGET_LOC_CHANGE
		var/interaction_key = "sex_action_[REF(action)]"
		//loc check for proximity instead of move disruption.
		if(!(target in view(1, user)) && !can_remote_interact_with_action(action))
			if(current_action)
				stop_current_action()
			return
		if(!do_after(user, do_time, target = target, timed_action_flags = do_after_flags, interaction_key = interaction_key))
			break

		if(QDELETED(action) || !(action in active_actions))
			break
		if(!can_perform_action(action, TRUE))
			break
		if(action.is_finished(user, target))
			break
		if(action.stop_requested)
			break

		suppress_visible_messages = begin_remote_action_visible_message_suppression(action)
		action.on_perform(user, target)
		end_remote_action_visible_message_suppression(suppress_visible_messages)
		action_remote_context = get_valid_remote_context(action)
		if(action_remote_context)
			action_remote_context.show_action_message(action, MAGE_HAND_ACTION_MESSAGE_PERFORM)
		if(QDELETED(action) || !(action in active_actions))
			break
		if(istype(user.loc, /obj/structure/closet))
			var/obj/structure/closet/sex_shack = user.loc
			sex_shack.Shake(1, 3, 15)

		if(user.has_kink(KINK_VISUAL_EFFECTS)) //Hearts played on action that can be turned off at will
			action.show_sex_effects(user)

		if(action.is_finished(user, target))
			break
		if(!action.continous)
			break

	stop_current_action(action)

/datum/sex_session/proc/stop_current_action(action_ref)
	if(!length(active_actions))
		return
	if(!action_ref)
		var/list/actions_to_stop = active_actions.Copy()
		for(var/datum/sex_action/action as anything in actions_to_stop)
			stop_current_action(action)
		return

	var/datum/sex_action/action = get_active_action(action_ref)
	if(user && target)
		var/key = "sex_action_[REF(action)]"
		user.stop_doing(key)
	if(!action)
		return

	active_actions -= action
	var/datum/sex_remote_context/action_remote_context = get_valid_remote_context(action)
	if(action_remote_context)
		action_remote_context.show_action_message(action, MAGE_HAND_ACTION_MESSAGE_FINISH)
		action_remote_context.clear_action_overlay(action)
	else
		remote_context?.clear_action_overlay(action)
	var/suppress_visible_messages = begin_remote_action_visible_message_suppression(action)
	action.on_finish(user, target)
	end_remote_action_visible_message_suppression(suppress_visible_messages)
	update_current_action()
	if(!length(active_actions))
		// This is only a one-shot "finish the current loop" latch; don't let it leak into a future encounter.
		just_climaxed = FALSE
	qdel(action)
	SStgui.update_uis(src)

/datum/sex_session/proc/begin_remote_action_visible_message_suppression(action_type)
	if(!get_valid_remote_context(action_type))
		return FALSE
	user?.push_visible_message_suppression()
	if(target && target != user)
		target.push_visible_message_suppression()
	return TRUE

/datum/sex_session/proc/end_remote_action_visible_message_suppression(was_suppressed)
	if(!was_suppressed)
		return
	user?.pop_visible_message_suppression()
	if(target && target != user)
		target.pop_visible_message_suppression()

/datum/sex_session/proc/set_remote_context(datum/sex_remote_context/context)
	if(remote_context == context)
		return
	clear_remote_context()
	remote_context = context
	if(remote_context)
		remote_context.session = src

/datum/sex_session/proc/clear_remote_context()
	if(!remote_context)
		return
	var/datum/sex_remote_context/context = remote_context
	remote_context = null
	qdel(context)

/datum/sex_session/proc/get_valid_remote_context(action_type)
	if(!remote_context)
		return null
	var/datum/sex_action/action = get_action_template(action_type)
	if(!action)
		return null
	if(!remote_context.is_valid(src))
		clear_remote_context()
		return null
	if(!remote_context.allows_action(action))
		return null
	return remote_context

/datum/sex_session/proc/can_remote_interact_with_action(action_type)
	return !!get_valid_remote_context(action_type)

/datum/sex_session/proc/can_perform_action(action_type, performing = FALSE)
	var/datum/sex_action/action = get_action_template(action_type)
	if(!action)
		return FALSE
	if(user != target)
		if(!user.allows_player_erp_while_disconnected())
			return FALSE
		if(!target.allows_player_erp_while_disconnected())
			return FALSE
	if(!inherent_perform_check(action))
		return FALSE
	if(!action.can_perform(user, target) && !performing)
		return FALSE
	return TRUE

/datum/sex_session/proc/inherent_perform_check(action_type)
	var/datum/sex_action/action = get_action_template(action_type)
	if(!action)
		return FALSE
	if(!user || !target)
		return FALSE
	if(QDELETED(user) || QDELETED(target))
		return FALSE
	if(user.stat != CONSCIOUS)
		return FALSE
	if(target.stat == DEAD)
		return FALSE
	var/remote_interaction = can_remote_interact_with_action(action)
	if(!remote_interaction && !user.adjacent_or_closet(target) && action.check_distance)
		return FALSE
	if(action.check_incapacitated)
		var/incapacitated_flags = IGNORE_GRAB
		if(!action.requires_free_hands)
			incapacitated_flags |= IGNORE_RESTRAINTS
		if(user.incapacitated(incapacitated_flags))
			return FALSE
	if(action.requires_free_hands && !user.has_free_sex_hands())
		return FALSE
	if(!remote_interaction && action.check_same_tile && !user.check_closet(target))
		var/same_tile = (get_turf(user) == get_turf(target))
		var/grab_bypass = (action.aggro_grab_instead_same_tile && user.get_effective_grab_state_on(target) == GRAB_AGGRESSIVE)
		if(!same_tile && !grab_bypass)
			return FALSE
	if(!remote_interaction && action.require_grab)
		var/grabstate = user.get_effective_grab_state_on(target)
		if(grabstate == null || grabstate < action.required_grab_state)
			return FALSE
	return TRUE

/**
 * Applies one "tick" of a sex action's stimulation.
 *
 * `pleasure_receiver` is the participant who actually RECEIVES the arousal, pain and orgasm progress (and the
 * COMSIG_SEX_RECEIVE_ACTION signal that can trigger their climax). `partner` is the other participant, read for
 * edging-the-other and good-lover bonuses but not stimulated by this call.
 *
 * To stimulate BOTH participants in one action, call this once per side with the first two arguments swapped
 * (see the penetrative "other" actions, e.g. "Ride them anally", for examples).
 */
/datum/sex_session/proc/perform_sex_action(mob/living/pleasure_receiver, mob/living/partner, arousal_amt, pain_amt, orgasm_prog_amt, datum/sex_action/sex_act)
	var/list/arousal_data_partner = list()
	SEND_SIGNAL(partner, COMSIG_SEX_GET_AROUSAL, arousal_data_partner)

	// A skilled lover stimulating someone else makes it feel better for the one receiving it.
	if(HAS_TRAIT(user, TRAIT_GOODLOVER) && user != pleasure_receiver)
		arousal_amt *= 1.5
		orgasm_prog_amt *= 1.5
		if(prob(10))
			var/lovermessage = pick("This feels so good!","I am in nirvana!","This is too good to be possible!","By the Gods!","I can't stop, too good!~")
			to_chat(partner, span_love(lovermessage))

	// edging_other: the session owner tries to hold their partner back from the edge.
	if(partner != user && edging_other)
		if(arousal_data_partner["arousal"] >= AROUSAL_EDGING_THRESHOLD + 15)
			var/succes_chance = 100
			if(prob(5))
				to_chat(user, span_love("I try to match my movements so that they don't climax too soon..."))
			if(speed > SEX_SPEED_MID || force > SEX_FORCE_MID)
				succes_chance *= 0.5
			if(partner.has_status_effect(/datum/status_effect/edging_overstimulation))
				succes_chance *= 0.3
				if(prob(10))
					to_chat(user, span_love("They are just too sensitive for me to control their pleasure..."))
			if(user.get_stat_level(STATKEY_PER) < 7)
				succes_chance *= 0.7
				if(prob(10))
					to_chat(user, span_love("I can't tell if they are close or not..."))
			if(prob(succes_chance))
				SEND_SIGNAL(partner, COMSIG_SEX_EDGED_BY_OTHER_STATE, TRUE)

	// "giving" is TRUE when the session owner is the one being pleasured by this call.
	var/giving = (user == pleasure_receiver)

	var/list/arousal_data_receiver = list()
	SEND_SIGNAL(pleasure_receiver, COMSIG_SEX_GET_AROUSAL, arousal_data_receiver)
	var/res_send = arousal_data_receiver["resistance_to_pleasure"]

	var/datum/sex_action_effect_context/effect_context = new(pleasure_receiver, partner, sex_act, pleasure_receiver, partner, giving)
	effect_context.session = src
	effect_context.action_performer = user
	effect_context.arousal_amt = arousal_amt
	effect_context.pain_amt = pain_amt
	effect_context.orgasm_prog_amt = orgasm_prog_amt
	effect_context.force = force
	effect_context.speed = speed
	effect_context.resistance = res_send
	var/list/effects = collect_sex_action_effects(effect_context)
	for(var/datum/sex_action_effect/effect as anything in effects)
		effect.modify_action(effect_context)

	SEND_SIGNAL(pleasure_receiver, COMSIG_SEX_RECEIVE_ACTION, sex_act, pleasure_receiver, partner, effect_context.arousal_amt, effect_context.pain_amt, effect_context.orgasm_prog_amt, giving, force, speed, res_send, user)

	for(var/datum/sex_action_effect/effect as anything in effects)
		effect.after_action(effect_context)
	qdel_sex_action_effects(effects)

/datum/sex_session/proc/handle_passive_ejaculation(mob/living/handler)
	if(!handler)
		handler = user
	var/list/arousal_data = list()
	SEND_SIGNAL(handler, COMSIG_SEX_GET_AROUSAL, arousal_data)
	var/arousal_multiplier = arousal_data["arousal_multiplier"]
	var/arousal_value = arousal_data["arousal"]

	if(arousal_multiplier > 1.5 && user.check_handholding())
		if(prob(5))
			SEND_SIGNAL(handler, COMSIG_SEX_RECEIVE_ACTION, 3, 0, 1, 0)
		if(arousal_value < 70)
			SEND_SIGNAL(handler, COMSIG_SEX_ADJUST_AROUSAL, 0.2)

		if(iscarbon(handler))
			var/mob/living/carbon/carbon_handler = handler
			if(carbon_handler.handcuffed)
				if(prob(8))
					var/chaffepain = pick(10,10,10,10,20,20,30)
					SEND_SIGNAL(handler, COMSIG_SEX_RECEIVE_ACTION, 3, chaffepain, 1, 0)
					handler.visible_message(("<span class='love_mid'>[handler] squirms uncomfortably in [handler.p_their()] restraints.</span>"), \
						("<span class='love_extreme'>I feel [carbon_handler.handcuffed] rub uncomfortably against my skin.</span>"))
				if(arousal_value < ACTIVE_EJAC_THRESHOLD)
					SEND_SIGNAL(handler, COMSIG_SEX_ADJUST_AROUSAL, 0.25)

/datum/sex_session/proc/perform_deepthroat_oxyloss(mob/living/action_target, oxyloss_amt)
	var/oxyloss_multiplier = 0
	switch(force)
		if(SEX_FORCE_LOW)
			oxyloss_multiplier = 0
		if(SEX_FORCE_MID)
			oxyloss_multiplier = 0
		if(SEX_FORCE_HIGH)
			oxyloss_multiplier = 0.5
		if(SEX_FORCE_EXTREME)
			oxyloss_multiplier = 1.0
	oxyloss_amt *= oxyloss_multiplier
	if((oxyloss_amt <= 0) || (action_target.getOxyLoss() > 30))
		return
	action_target.adjustOxyLoss(oxyloss_amt)
	// Indicate someone is choking through sex
	if(action_target.oxyloss >= 25 && prob(33))
		action_target.emote(pick(list("gag", "choke", "gasp")), forced = TRUE)

/datum/sex_session/proc/get_speed_multiplier()
	switch(speed)
		if(SEX_SPEED_LOW)
			return 1
		if(SEX_SPEED_MID)
			return 1.5
		if(SEX_SPEED_HIGH)
			return 2.25
		if(SEX_SPEED_EXTREME)
			return 3

/datum/sex_session/proc/get_stamina_cost_multiplier()
	switch(force)
		if(SEX_FORCE_LOW)
			return 1.0
		if(SEX_FORCE_MID)
			return 1.5
		if(SEX_FORCE_HIGH)
			return 2.0
		if(SEX_FORCE_EXTREME)
			return 2.5

/datum/sex_session/proc/finished_check()
	if(!do_until_finished)
		return FALSE
	if(just_climaxed)
		just_climaxed = FALSE
		return TRUE
	return FALSE

/datum/sex_session/proc/on_climax(mob/source, datum/sex_action/action, mob/living/action_receiver, mob/living/action_partner, mob/living/action_performer)
	if(!do_until_finished)
		return
	just_climaxed = TRUE
	try_stop_current_action()


/datum/sex_session/proc/get_generic_force_adjective()
	switch(force)
		if(SEX_FORCE_LOW)
			return pick(list("gently", "carefully", "tenderly", "gingerly", "delicately", "lazily"))
		if(SEX_FORCE_MID)
			return pick(list("firmly", "vigorously", "eagerly", "steadily", "intently"))
		if(SEX_FORCE_HIGH)
			return pick(list("roughly", "carelessly", "forcefully", "fervently", "fiercely"))
		if(SEX_FORCE_EXTREME)
			return pick(list("brutally", "violently", "relentlessly", "savagely", "mercilessly"))

/datum/sex_session/proc/spanify_force(string)
	switch(force)
		if(SEX_FORCE_LOW)
			return "<span class='love_low'>[string]</span>"
		if(SEX_FORCE_MID)
			return "<span class='love_mid'>[string]</span>"
		if(SEX_FORCE_HIGH)
			return "<span class='love_high'>[string]</span>"
		if(SEX_FORCE_EXTREME)
			return "<span class='love_extreme'>[string]</span>"

/datum/sex_session/proc/get_force_sound()
	switch(force)
		if(SEX_FORCE_LOW, SEX_FORCE_MID)
			return pick(SEX_SOUNDS_SLOW)
		if(SEX_FORCE_HIGH, SEX_FORCE_EXTREME)
			return pick(SEX_SOUNDS_HARD)

/datum/sex_session/proc/get_bellyriding_component()
	if(!user || !target)
		return null
	var/datum/component/bellyriding/belly_comp = user.GetComponent(/datum/component/bellyriding)
	if(belly_comp && belly_comp.current_victim == target)
		return belly_comp
	belly_comp = target.GetComponent(/datum/component/bellyriding)
	if(belly_comp && belly_comp.current_victim == user)
		return belly_comp
	return null

/datum/sex_session/proc/get_current_speed()
	return speed || SEX_SPEED_LOW

/datum/sex_session/proc/get_current_force()
	return force || SEX_FORCE_LOW

/datum/sex_session/proc/get_current_resist()
	return resistance_to_pleasure || RESIST_NONE

/datum/sex_session/proc/set_current_speed(new_speed)
	speed = clamp(new_speed, SEX_SPEED_MIN, SEX_SPEED_MAX)

/datum/sex_session/proc/set_current_force(new_force)
	force = clamp(new_force, SEX_FORCE_MIN, SEX_FORCE_MAX)

/datum/sex_session/proc/set_current_resist(new_resist)
	resistance_to_pleasure = clamp(new_resist, RESIST_NONE, RESIST_HIGH)
	SEND_SIGNAL(user, COMSIG_SEX_SET_HOLDING, resistance_to_pleasure)

/datum/sex_session/proc/get_character_slot(mob/target_mob)
	return target_mob?.client?.prefs.current_slot || 1

/proc/get_player_notes_about(viewer_ckey, target_ckey, character_slot = 1)
	var/datum/save_manager/SM = get_save_manager(viewer_ckey)
	if(!SM)
		return list()

	var/save_name = "character_[character_slot]_notes"
	var/list/all_notes = SM.get_data(save_name, "partner_notes", list())

	return all_notes[ckey(target_ckey)] || list()

/proc/set_player_note_about(writer_ckey, target_ckey, note_title, note_content, character_slot = 1)
	var/datum/save_manager/SM = get_save_manager(writer_ckey)
	if(!SM)
		return FALSE

	var/save_name = "character_[character_slot]_notes"
	var/list/all_notes = SM.get_data(save_name, "partner_notes", list())

	if(!all_notes[ckey(target_ckey)])
		all_notes[ckey(target_ckey)] = list()

	all_notes[ckey(target_ckey)][note_title] = list(
		"content" = note_content,
		"created" = world.realtime,
		"last_modified" = world.realtime
	)

	return SM.set_data(save_name, "partner_notes", all_notes)



