/datum/erp_actor_effects_bridge

/obj/item
	var/list/erp_item_tags = null

/obj/item/clothing
	var/list/propagade_kink = null

/obj/item/clothing/proc/get_propagade_kinks()
	if(islist(propagade_kink) && propagade_kink.len)
		return propagade_kink
	return null

/obj/item/organ
	var/datum/erp_sex_organ/sex_organ

/obj/item/bodypart
	var/datum/erp_sex_organ/sex_organ

/proc/erp_ensure_sex_organ(atom/source)
	if(!source || QDELETED(source))
		return null

	if(istype(source, /obj/item/organ))
		var/obj/item/organ/O = source
		if(O.sex_organ && !QDELETED(O.sex_organ))
			return O.sex_organ

		if(istype(O, /obj/item/organ/genitals/penis))
			O.sex_organ = new /datum/erp_sex_organ/penis(O)
		else if(istype(O, /obj/item/organ/genitals/filling_organ/vagina))
			O.sex_organ = new /datum/erp_sex_organ/vagina(O)
		else if(istype(O, /obj/item/organ/genitals/filling_organ/breasts))
			O.sex_organ = new /datum/erp_sex_organ/breasts(O)
		else if(istype(O, /obj/item/organ/genitals/filling_organ/anus))
			O.sex_organ = new /datum/erp_sex_organ/anus(O)

		return O.sex_organ

	if(istype(source, /obj/item/bodypart/head))
		var/obj/item/bodypart/head/H = source
		if(!H.sex_organ || QDELETED(H.sex_organ))
			H.sex_organ = new /datum/erp_sex_organ/mouth(H)
		return H.sex_organ

	return null

/proc/erp_get_controller_for_actor(mob/living/actor, create = FALSE)
	if(!actor || QDELETED(actor))
		return null

	var/datum/erp_controller/controller = null
	if(actor.client)
		controller = SSerp.get_controller_for_client(actor.client)
	if(!controller)
		controller = SSerp.get_controller_for(actor)
	if(!controller && create)
		controller = SSerp.get_or_create_controller(actor, actor.client, actor)

	return controller

/proc/erp_prepare_controller(mob/living/actor, atom/partner_atom = null, create = TRUE, set_active = TRUE)
	var/datum/erp_controller/controller = erp_get_controller_for_actor(actor, create)
	if(!controller)
		return null

	if(partner_atom && !QDELETED(partner_atom))
		controller.add_partner_atom(partner_atom, set_active)
	else if(set_active && controller.owner)
		controller.active_partner = controller.owner

	return controller

/proc/erp_link_matches_pair(datum/erp_sex_link/link, atom/actor_atom, atom/partner_atom)
	if(!link || QDELETED(link))
		return FALSE

	var/atom/link_a_physical = link.actor_active?.physical
	var/atom/link_b_physical = link.actor_passive?.physical
	var/atom/link_a_active = link.actor_active?.active_actor
	var/atom/link_b_active = link.actor_passive?.active_actor
	if(!link_a_physical && !link_a_active)
		return FALSE
	if(!link_b_physical && !link_b_active)
		return FALSE

	var/actor_as_a = (link_a_physical == actor_atom || link_a_active == actor_atom)
	var/actor_as_b = (link_b_physical == actor_atom || link_b_active == actor_atom)
	var/partner_as_a = (link_a_physical == partner_atom || link_a_active == partner_atom)
	var/partner_as_b = (link_b_physical == partner_atom || link_b_active == partner_atom)

	return (actor_as_a && partner_as_b) || (actor_as_b && partner_as_a)

/proc/erp_get_pair_links(mob/living/actor, atom/partner_atom = null)
	var/list/out = list()
	var/datum/erp_controller/controller = erp_prepare_controller(actor, null, FALSE, FALSE)
	if(!controller)
		return out

	if(!partner_atom || QDELETED(partner_atom))
		partner_atom = controller.active_partner?.physical || controller.active_partner?.active_actor || actor

	for(var/datum/erp_sex_link/link in controller.links)
		if(erp_link_matches_pair(link, actor, partner_atom))
			out += link

	return out

/proc/erp_pair_has_active_links(mob/living/actor, atom/partner_atom = null)
	for(var/datum/erp_sex_link/link in erp_get_pair_links(actor, partner_atom))
		if(!link || QDELETED(link))
			continue
		if(!link.is_valid())
			continue
		if(link.state && link.state != LINK_STATE_ACTIVE)
			continue
		return TRUE

	return FALSE

/proc/erp_pick_action_organ(datum/erp_controller/controller, list/by_type, datum/erp_sex_organ/any_organ, preferred_type)
	if(!controller)
		return null

	if(preferred_type)
		return by_type[controller.actions_d.normalize_organ_type(preferred_type)]

	return any_organ

/proc/erp_start_action_pair(mob/living/actor, atom/partner_atom, action_id, base_force = null, base_speed = null, stop_existing = TRUE)
	if(!actor || QDELETED(actor))
		return null

	var/datum/erp_controller/controller = erp_prepare_controller(actor, partner_atom, TRUE, TRUE)
	if(!controller || !controller.owner || !controller.active_partner)
		return null

	var/datum/erp_action/action = controller.get_action_by_id_or_path(action_id)
	if(!action)
		return null

	var/list/owner_pick = controller.actions_d.pick_first_by_type(controller.owner, TRUE)
	var/list/partner_pick = controller.actions_d.pick_first_by_type(controller.active_partner, FALSE)

	var/datum/erp_sex_organ/init_organ = erp_pick_action_organ(controller, owner_pick["by"], owner_pick["any"], action.required_init_organ)
	var/datum/erp_sex_organ/target_organ = erp_pick_action_organ(controller, partner_pick["by"], partner_pick["any"], action.required_target_organ)
	if(!init_organ || !target_organ)
		return null

	var/reason = controller.get_action_block_reason(action, init_organ, target_organ)
	if(!isnull(reason))
		return null

	if(stop_existing)
		for(var/datum/erp_sex_link/existing in erp_get_pair_links(actor, partner_atom))
			controller.stop_link_runtime(existing)

	var/list/organs = list(
		"init" = init_organ,
		"target" = target_organ,
	)
	var/datum/erp_sex_link/link = new(controller.owner, controller.active_partner, action, organs, controller)

	if(!isnull(base_force))
		link.force = clamp(round(base_force), SEX_FORCE_MIN, SEX_FORCE_MAX)
	if(!isnull(base_speed))
		link.speed = clamp(round(base_speed), SEX_SPEED_MIN, SEX_SPEED_MAX)

	controller.links += link
	action.on_link_started(link)
	if(QDELETED(link) || !(link in controller.links) || link.state == LINK_STATE_FINISHED)
		controller.ui?.request_update()
		return null
	controller._send_link_start_message(link)
	controller.ui?.request_update()
	return link

/proc/erp_stop_action_pair(mob/living/actor, atom/partner_atom = null)
	var/datum/erp_controller/controller = erp_prepare_controller(actor, null, FALSE, FALSE)
	if(!controller)
		return FALSE

	var/list/pair_links = erp_get_pair_links(actor, partner_atom)
	if(!length(pair_links))
		if(isnull(partner_atom))
			return !!controller.links_d?.full_stop()
		return FALSE

	for(var/datum/erp_sex_link/link in pair_links)
		controller.stop_link_runtime(link)

	controller.ui?.request_update()
	return TRUE
