/proc/get_active_portallight(mob/living/carbon/human/user)
	if(!istype(user))
		return null

	var/obj/item/I = user.get_active_held_item()
	if(!istype(I, /obj/item/portallight))
		return null

	return I

/datum/erp_action/portal_base
	abstract = TRUE
	allow_remote = TRUE
	skip_access_checks = TRUE
	require_same_tile = FALSE
	allow_sex_on_move = TRUE
	use_message_templates = FALSE

/datum/erp_action/portal_base/proc/get_portal_actor(datum/erp_controller/controller)
	var/mob/living/carbon/human/user = controller?.owner?.physical
	return istype(user) ? user : null

/datum/erp_action/portal_base/proc/get_portal_target(datum/erp_controller/controller)
	var/mob/living/carbon/human/target = controller?.active_partner?.physical
	return istype(target) ? target : null

/datum/erp_action/portal_base/proc/get_portal_user_from_link(datum/erp_sex_link/L)
	var/mob/living/carbon/human/user = L?.actor_active?.physical
	return istype(user) ? user : null

/datum/erp_action/portal_base/proc/get_portal_target_from_link(datum/erp_sex_link/L)
	var/mob/living/carbon/human/target = L?.actor_passive?.physical
	return istype(target) ? target : null

/datum/erp_action/portal_base/proc/get_portallight_for_controller(datum/erp_controller/controller)
	var/mob/living/carbon/human/user = get_portal_actor(controller)
	var/mob/living/carbon/human/target = get_portal_target(controller)
	var/obj/item/portallight/light = get_active_portallight(user)
	if(!light)
		return null
	if(!light.is_erp_linked_to(target, required_target_organ))
		return null
	return light

/datum/erp_action/portal_base/proc/get_portallight_for_link(datum/erp_sex_link/L)
	var/mob/living/carbon/human/user = get_portal_user_from_link(L)
	var/mob/living/carbon/human/target = get_portal_target_from_link(L)
	var/obj/item/portallight/light = get_active_portallight(user)
	if(!light)
		return null
	if(!light.is_erp_linked_to(target, required_target_organ))
		return null
	return light

/datum/erp_action/portal_base/proc/get_force_adjective(force)
	switch(clamp(round(force || SEX_FORCE_MID), SEX_FORCE_LOW, SEX_FORCE_EXTREME))
		if(SEX_FORCE_LOW)
			return "gently"
		if(SEX_FORCE_MID)
			return "firmly"
		if(SEX_FORCE_HIGH)
			return "roughly"
	return "wildly"

/datum/erp_action/portal_base/proc/send_private_messages(datum/erp_sex_link/L, user_text, target_text = null)
	var/mob/living/carbon/human/user = get_portal_user_from_link(L)
	var/mob/living/carbon/human/target = get_portal_target_from_link(L)
	if(user && user_text)
		to_chat(user, user_text)
	if(target && target_text && target != user)
		to_chat(target, target_text)

/datum/erp_action/portal_base/proc/play_force_sound(mob/living/carbon/human/user, force)
	if(!istype(user))
		return

	var/action_force = clamp(round(force || SEX_FORCE_MID), SEX_FORCE_LOW, SEX_FORCE_EXTREME)
	var/sound_pick = null
	if(action_force <= SEX_FORCE_MID)
		sound_pick = pick(SEX_SOUNDS_SLOW)
	else
		sound_pick = pick(SEX_SOUNDS_HARD)

	if(sound_pick)
		playsound(user, sound_pick, 40, TRUE, -2, ignore_walls = FALSE)

/datum/erp_action/portal_base/proc/get_active_portal_link(datum/erp_controller/controller, datum/erp_sex_link/exclude = null)
	if(!controller?.links || !controller.links.len)
		return null

	for(var/datum/erp_sex_link/L in controller.links)
		if(!L || QDELETED(L) || L == exclude)
			continue
		if(L.state == LINK_STATE_FINISHED)
			continue
		if(!istype(L.action, /datum/erp_action/portal_base))
			continue
		return L

	return null

/datum/erp_action/portal_base/get_custom_block_reason(datum/erp_controller/controller, datum/erp_sex_organ/init, datum/erp_sex_organ/target, datum/erp_action_context/ctx)
	if(!get_portallight_for_controller(controller))
		return "Hold a linked portal light in your active hand."
	if(get_active_portal_link(controller))
		return "The portal is already occupied."
	return null

/datum/erp_action/portal_base/is_link_valid(datum/erp_sex_link/L)
	return !!get_portallight_for_link(L)

/datum/erp_action/portal_base/portal_hand_vaginal
	abstract = FALSE
	name = "Portal Hand"
	required_init_organ = SEX_ORGAN_HANDS
	required_target_organ = SEX_ORGAN_VAGINA
	required_item_tags = list("portal_vagina")

/datum/erp_action/portal_base/portal_hand_vaginal/on_link_started(datum/erp_sex_link/L)
	send_private_messages(L, span_warning("You start touching the needy hole through the portal."), span_love("You feel a distant touch through the portal!"))

/datum/erp_action/portal_base/portal_hand_vaginal/on_link_tick(datum/erp_sex_link/L, dt)
	var/mob/living/carbon/human/user = get_portal_user_from_link(L)
	var/adj = get_force_adjective(L.force)
	send_private_messages(L, L.spanify_sex("You [adj] finger your target through the portal."), L.spanify_sex("Someone [adj] fingers you through the portal."))
	if(user)
		playsound(user, 'sound/misc/mat/fingering.ogg', 30, TRUE, -2, ignore_walls = FALSE)

/datum/erp_action/portal_base/portal_hand_vaginal/on_link_climax(datum/erp_sex_link/L, mob/living/carbon/human/who)
	if(who == get_portal_target_from_link(L))
		send_private_messages(L, span_love("You climax from the portal touch! Your body trembles with pleasure."), span_love("Your target shudders and reacts to your touch through the portal."))

/datum/erp_action/portal_base/portal_hand_vaginal/on_link_finished(datum/erp_sex_link/L)
	send_private_messages(L, span_notice("You withdraw your hand from the portal."), span_notice("The distant touch fades away."))

/datum/erp_action/portal_base/portal_hand_anal
	abstract = FALSE
	name = "Portal Hand"
	required_init_organ = SEX_ORGAN_HANDS
	required_target_organ = SEX_ORGAN_ANUS
	required_item_tags = list("portal_anus")

/datum/erp_action/portal_base/portal_hand_anal/on_link_started(datum/erp_sex_link/L)
	send_private_messages(L, span_warning("You start touching your target through the portal."), span_love("You feel a distant touch through the portal!"))

/datum/erp_action/portal_base/portal_hand_anal/on_link_tick(datum/erp_sex_link/L, dt)
	var/mob/living/carbon/human/user = get_portal_user_from_link(L)
	var/adj = get_force_adjective(L.force)
	send_private_messages(L, L.spanify_sex("You [adj] finger your target's ass through the portal."), L.spanify_sex("Someone [adj] fingers your ass through the portal."))
	if(user)
		playsound(user, 'sound/misc/mat/fingering.ogg', 30, TRUE, -2, ignore_walls = FALSE)

/datum/erp_action/portal_base/portal_hand_anal/on_link_climax(datum/erp_sex_link/L, mob/living/carbon/human/who)
	if(who == get_portal_target_from_link(L))
		send_private_messages(L, span_love("You climax from the portal touch! Your body trembles with pleasure."), span_love("Your target shudders and reacts to your touch through the portal."))

/datum/erp_action/portal_base/portal_hand_anal/on_link_finished(datum/erp_sex_link/L)
	send_private_messages(L, span_notice("You withdraw your hand from the portal."), span_notice("The distant touch fades away."))

/datum/erp_action/portal_base/portal_oral_vaginal
	abstract = FALSE
	name = "Portal Oral"
	required_init_organ = SEX_ORGAN_MOUTH
	required_target_organ = SEX_ORGAN_VAGINA
	required_item_tags = list("portal_vagina")

/datum/erp_action/portal_base/portal_oral_vaginal/on_link_started(datum/erp_sex_link/L)
	send_private_messages(L, span_warning("You press your mouth to the portal, reaching your target."), span_love("Warm sensations bloom between your legs!"))

/datum/erp_action/portal_base/portal_oral_vaginal/on_link_tick(datum/erp_sex_link/L, dt)
	var/mob/living/carbon/human/user = get_portal_user_from_link(L)
	var/adj = get_force_adjective(L.force)
	if(user)
		user.make_sucking_noise()
	send_private_messages(L, L.spanify_sex("You [adj] lick your target through the portal."), L.spanify_sex("Someone [adj] licks you through the portal."))

/datum/erp_action/portal_base/portal_oral_vaginal/on_link_climax(datum/erp_sex_link/L, mob/living/carbon/human/who)
	if(who == get_portal_target_from_link(L))
		send_private_messages(L, span_love("You climax from the portal oral! Your body shudders in ecstasy."), span_love("You bring your target to climax through the portal!"))

/datum/erp_action/portal_base/portal_oral_vaginal/on_link_finished(datum/erp_sex_link/L)
	send_private_messages(L, span_notice("You pull back from the portal."), span_notice("The sensations from the portal fade away."))

/datum/erp_action/portal_base/portal_oral_anal
	abstract = FALSE
	name = "Portal Oral"
	required_init_organ = SEX_ORGAN_MOUTH
	required_target_organ = SEX_ORGAN_ANUS
	required_item_tags = list("portal_anus")

/datum/erp_action/portal_base/portal_oral_anal/on_link_started(datum/erp_sex_link/L)
	send_private_messages(L, span_warning("You press your mouth to the portal, reaching your target."), span_love("Warm sensations bloom at your backside!"))

/datum/erp_action/portal_base/portal_oral_anal/on_link_tick(datum/erp_sex_link/L, dt)
	var/mob/living/carbon/human/user = get_portal_user_from_link(L)
	var/adj = get_force_adjective(L.force)
	if(user)
		user.make_sucking_noise()
	send_private_messages(L, L.spanify_sex("You [adj] lick your target through the portal."), L.spanify_sex("Someone [adj] licks you through the portal."))

/datum/erp_action/portal_base/portal_oral_anal/on_link_climax(datum/erp_sex_link/L, mob/living/carbon/human/who)
	if(who == get_portal_target_from_link(L))
		send_private_messages(L, span_love("You climax from the portal oral! Your body shudders in ecstasy."), span_love("You bring your target to climax through the portal!"))

/datum/erp_action/portal_base/portal_oral_anal/on_link_finished(datum/erp_sex_link/L)
	send_private_messages(L, span_notice("You pull back from the portal."), span_notice("The sensations from the portal fade away."))

/datum/erp_action/portal_base/portal_penis_vaginal
	abstract = FALSE
	name = "Portal Pussy Fuck"
	required_init_organ = SEX_ORGAN_PENIS
	required_target_organ = SEX_ORGAN_VAGINA
	required_item_tags = list("portal_vagina")

/datum/erp_action/portal_base/portal_penis_vaginal/on_link_started(datum/erp_sex_link/L)
	send_private_messages(L, span_warning("You slide your cock into the portal, reaching your target's pussy."), span_love("You feel something penetrating your pussy through the portal!"))

/datum/erp_action/portal_base/portal_penis_vaginal/on_link_tick(datum/erp_sex_link/L, dt)
	var/mob/living/carbon/human/user = get_portal_user_from_link(L)
	var/adj = get_force_adjective(L.force)
	send_private_messages(L, L.spanify_sex("You [adj] fuck your target's pussy through the portal."), L.spanify_sex("Someone [adj] fucks you through the portal."))
	play_force_sound(user, L.force)

/datum/erp_action/portal_base/portal_penis_vaginal/on_link_climax(datum/erp_sex_link/L, mob/living/carbon/human/who)
	var/mob/living/carbon/human/user = get_portal_user_from_link(L)
	var/mob/living/carbon/human/target = get_portal_target_from_link(L)
	if(user)
		user.virginity = FALSE
	if(target)
		target.virginity = FALSE
	if(who == target)
		send_private_messages(L, span_love("You cum from the portal fuck! Your body trembles in ecstasy."), span_love("You feel your target's pussy spasming around your member, shuddering in orgasm."))
	else if(who == user)
		send_private_messages(L, span_love("You cum inside your target! You shudder with pleasure."), span_love("You feel the invading member shudder and let out ropes of seed deep inside your pussy!"))

/datum/erp_action/portal_base/portal_penis_vaginal/on_link_finished(datum/erp_sex_link/L)
	send_private_messages(L, span_notice("You pull your cock back from the portal."), span_notice("The penetration through the portal ends."))

/datum/erp_action/portal_base/portal_penis_anal
	abstract = FALSE
	name = "Portal Ass Fuck"
	required_init_organ = SEX_ORGAN_PENIS
	required_target_organ = SEX_ORGAN_ANUS
	required_item_tags = list("portal_anus")

/datum/erp_action/portal_base/portal_penis_anal/on_link_started(datum/erp_sex_link/L)
	send_private_messages(L, span_warning("You slide your cock into the portal, reaching your target's ass."), span_love("You feel something penetrating your ass through the portal!"))

/datum/erp_action/portal_base/portal_penis_anal/on_link_tick(datum/erp_sex_link/L, dt)
	var/mob/living/carbon/human/user = get_portal_user_from_link(L)
	var/adj = get_force_adjective(L.force)
	send_private_messages(L, L.spanify_sex("You [adj] fuck your target's ass through the portal."), L.spanify_sex("Someone [adj] fucks your ass through the portal."))
	play_force_sound(user, L.force)

/datum/erp_action/portal_base/portal_penis_anal/on_link_climax(datum/erp_sex_link/L, mob/living/carbon/human/who)
	var/mob/living/carbon/human/user = get_portal_user_from_link(L)
	var/mob/living/carbon/human/target = get_portal_target_from_link(L)
	if(user)
		user.virginity = FALSE
	if(target)
		target.virginity = FALSE
	if(who == target)
		send_private_messages(L, span_love("You cum from the portal fuck! Your body trembles in ecstasy."), span_love("You feel your target's ass spasming around your member, shuddering in orgasm."))
	else if(who == user)
		send_private_messages(L, span_love("You cum inside your target! You shudder with pleasure."), span_love("You feel the invading member shudder and let out ropes of seed deep inside your ass!"))

/datum/erp_action/portal_base/portal_penis_anal/on_link_finished(datum/erp_sex_link/L)
	send_private_messages(L, span_notice("You pull your cock back from the portal."), span_notice("The penetration through the portal ends."))

/datum/erp_action/portal_base/portal_store_vaginal
	abstract = FALSE
	name = "Portal Store"
	required_init_organ = SEX_ORGAN_HANDS
	required_target_organ = SEX_ORGAN_VAGINA
	required_item_tags = list("portal_vagina")
	active_arousal_coeff = 0
	passive_arousal_coeff = 0
	active_pain_coeff = 0
	passive_pain_coeff = 0

/datum/erp_action/portal_base/portal_store_vaginal/proc/get_storage_target(datum/erp_sex_link/L)
	var/obj/item/organ/genitals/filling_organ/vagina/V = L?.target_organ?.host
	return istype(V) ? V : null

/datum/erp_action/portal_base/portal_store_vaginal/get_custom_block_reason(datum/erp_controller/controller, datum/erp_sex_organ/init, datum/erp_sex_organ/target, datum/erp_action_context/ctx)
	. = ..()
	if(!isnull(.))
		return

	var/mob/living/carbon/human/user = get_portal_actor(controller)
	var/obj/item/dildo = user?.get_inactive_held_item()
	if(!dildo)
		return "Hold an item in your other hand first."
	if(istype(dildo, /obj/item/portallight))
		return "You can't stick a portal into another one."

/datum/erp_action/portal_base/portal_store_vaginal/on_link_started(datum/erp_sex_link/L)
	var/mob/living/carbon/human/user = get_portal_user_from_link(L)
	var/mob/living/carbon/human/target = get_portal_target_from_link(L)
	var/obj/item/dildo = user?.get_inactive_held_item()
	if(!dildo)
		L.session?.stop_link_runtime(L)
		return
	send_private_messages(L, L.spanify_sex("I start inserting \the [dildo] in the portal..."), L.spanify_sex("You feel something being inserted in you through the portal..."))
	if(target)
		playsound(target, list('sound/misc/mat/insert (1).ogg', 'sound/misc/mat/insert (2).ogg'), 20, TRUE, ignore_walls = FALSE)

/datum/erp_action/portal_base/portal_store_vaginal/on_link_tick(datum/erp_sex_link/L, dt)
	var/mob/living/carbon/human/user = get_portal_user_from_link(L)
	var/obj/item/organ/genitals/filling_organ/vagina/target_organ = get_storage_target(L)
	var/obj/item/dildo = user?.get_inactive_held_item()
	var/pain_amt = 2
	var/handled = FALSE
	if(!target_organ || !dildo)
		L.session?.stop_link_runtime(L)
		return

	var/force = (L.force >= SEX_FORCE_HIGH)
	var/success = SEND_SIGNAL(target_organ, COMSIG_BODYSTORAGE_TRY_INSERT, dildo, STORAGE_LAYER_INNER, force)
	switch(success)
		if(INSERT_FEEDBACK_OK)
			handled = TRUE
			send_private_messages(L, L.spanify_sex("I stuff \the [dildo] in the portal..."), L.spanify_sex("You feel like something was inserted in you through the portal!"))
		if(INSERT_FEEDBACK_OK_FORCE)
			handled = TRUE
			if(prob(15))
				var/stuffed_res = SEND_SIGNAL(target_organ, COMSIG_BODYSTORAGE_SWAP_LAYERS_RAND, STORAGE_LAYER_INNER, STORAGE_LAYER_DEEP, force)
				if(stuffed_res == INSERT_FEEDBACK_OK_FORCE || stuffed_res == INSERT_FEEDBACK_OK)
					pain_amt += 4
					send_private_messages(L, L.spanify_sex("\The [dildo] slips deep inside of the portal!"), L.spanify_sex("You feel something slipping deep inside you!"))
			else
				pain_amt += 4
				send_private_messages(L, L.spanify_sex("I force \the [dildo] in the portal, fighting the pressure!"), L.spanify_sex("Something was forcefully inserted inside you!"))
		if(INSERT_FEEDBACK_ALMOST_FULL)
			handled = TRUE
			pain_amt += 2
			send_private_messages(L, L.spanify_sex("I stuff \the [dildo] in the portal, seems like it won't fit much more..."), L.spanify_sex("You feel another item inserted in you, stretching you to the limit."))
		if(INSERT_FEEDBACK_STUFFED)
			handled = TRUE
			if(force && prob(50))
				var/stuffed_force_res = SEND_SIGNAL(target_organ, COMSIG_BODYSTORAGE_SWAP_LAYERS_RAND, STORAGE_LAYER_INNER, STORAGE_LAYER_DEEP, force)
				if(stuffed_force_res == INSERT_FEEDBACK_OK_FORCE || stuffed_force_res == INSERT_FEEDBACK_OK)
					pain_amt += 2
					send_private_messages(L, L.spanify_sex("\The [dildo] slips deep inside of the portal!"), L.spanify_sex("You feel something slipping deep inside you!"))
			else
				send_private_messages(L, L.spanify_sex("The portal is too full to stuff even \the [dildo] in."), L.spanify_sex("You feel something probing the portal entrance, but you are too full!"))
				L.session?.stop_link_runtime(L)
				return
		if(INSERT_FEEDBACK_TRY_FORCE)
			handled = TRUE
			pain_amt += 3
			send_private_messages(L, L.spanify_sex("I feel like \the [dildo] might fit if I just use more force."), L.spanify_sex("You feel something probing the portal entrance..."))

	if(!handled)
		send_private_messages(L, L.spanify_sex("I fail to stuff \the [dildo] in the portal."), L.spanify_sex("You feel something probing the portal entrance..."))
		L.session?.stop_link_runtime(L)
		return

	user?.update_inv_hands()
	user?.update_a_intents()
	L.actor_active?.apply_erp_effect(0.5, pain_amt, TRUE, L.force, L.speed, L.init_organ?.erp_organ_type)
	L.actor_passive?.apply_erp_effect(0.5, pain_amt, FALSE, L.force, L.speed, L.target_organ?.erp_organ_type)

/datum/erp_action/portal_base/portal_remove_vaginal
	abstract = FALSE
	name = "Remove items from vagina"
	required_init_organ = SEX_ORGAN_HANDS
	required_target_organ = SEX_ORGAN_VAGINA
	required_item_tags = list("portal_vagina")
	active_arousal_coeff = 0
	passive_arousal_coeff = 0
	active_pain_coeff = 0
	passive_pain_coeff = 0

/datum/erp_action/portal_base/portal_remove_vaginal/proc/get_storage_target(datum/erp_sex_link/L)
	var/obj/item/organ/genitals/filling_organ/vagina/V = L?.target_organ?.host
	return istype(V) ? V : null

/datum/erp_action/portal_base/portal_remove_vaginal/get_custom_block_reason(datum/erp_controller/controller, datum/erp_sex_organ/init, datum/erp_sex_organ/target, datum/erp_action_context/ctx)
	. = ..()
	if(!isnull(.))
		return

	var/mob/living/carbon/human/target_human = get_portal_target(controller)
	var/obj/item/organ/genitals/filling_organ/vagina/target_organ = target_human?.getorganslot(ORGAN_SLOT_VAGINA)
	if(!target_organ)
		return "There is nothing on the other side."

	var/list/stored_items = SEND_SIGNAL(target_organ, COMSIG_BODYSTORAGE_GET_LISTS)
	var/list/stored_items_layer = stored_items ? stored_items[STORAGE_LAYER_INNER] : null
	if(!length(stored_items_layer))
		return "There is nothing stored inside."

/datum/erp_action/portal_base/portal_remove_vaginal/on_link_started(datum/erp_sex_link/L)
	var/mob/living/carbon/human/target = get_portal_target_from_link(L)
	send_private_messages(L, span_warning("I start removing items from the portal..."), span_warning("Something starts tugging from inside the portal..."))
	if(target)
		playsound(target, list('sound/misc/mat/insert (1).ogg', 'sound/misc/mat/insert (2).ogg'), 20, TRUE, ignore_walls = FALSE)

/datum/erp_action/portal_base/portal_remove_vaginal/on_link_tick(datum/erp_sex_link/L, dt)
	var/mob/living/carbon/human/user = get_portal_user_from_link(L)
	var/obj/item/organ/genitals/filling_organ/vagina/target_organ = get_storage_target(L)
	if(!target_organ)
		L.session?.stop_link_runtime(L)
		return

	var/obj/item/removed_item = SEND_SIGNAL(target_organ, COMSIG_BODYSTORAGE_REMOVE_RAND_ITEM, STORAGE_LAYER_INNER)
	if(!removed_item)
		send_private_messages(L, L.spanify_sex("I couldn't find anything inside..."), null)
		L.session?.stop_link_runtime(L)
		return

	if(user?.get_active_held_item())
		send_private_messages(L, L.spanify_sex("\The [removed_item] falls down on the floor..."), null)
		removed_item.doMove(get_turf(user))
	else
		send_private_messages(L, L.spanify_sex("I fish out \the [removed_item] from the portal..."), null)
		removed_item.doMove(get_turf(user))
		user.put_in_active_hand(removed_item)

	L.actor_active?.apply_erp_effect(0.5, 1, TRUE, L.force, L.speed, L.init_organ?.erp_organ_type)
	L.actor_passive?.apply_erp_effect(0.5, 1, FALSE, L.force, L.speed, L.target_organ?.erp_organ_type)
