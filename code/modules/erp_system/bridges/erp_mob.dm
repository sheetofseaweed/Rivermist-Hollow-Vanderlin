/mob/living/carbon/human
	var/datum/weakref/sex_surrender_ref

/mob/living/proc/get_erp_organs()
	var/list/L = list()
	var/mob/living/carbon/human/H = src
	if(!istype(H))
		return L

	H.client?.prefs?.apply_customizer_organs_to_mob(H)

	for(var/obj/item/organ/O in H.internal_organs)
		var/datum/erp_sex_organ/erp_organ = erp_ensure_sex_organ(O)
		if(erp_organ)
			L += erp_organ

	var/obj/item/bodypart/head/HD = H.get_bodypart(BODY_ZONE_HEAD)
	if(HD)
		var/datum/erp_sex_organ/mouth/M = erp_ensure_sex_organ(HD)
		if(M)
			L += M

	return L

/mob/living/proc/get_erp_organ(type)
	for(var/datum/erp_sex_organ/O in get_erp_organs())
		if(O.erp_organ_type == type)
			return O
	return null

/mob/living/carbon/human/proc/is_lamia_taur()
	if(!islist(bodyparts) || !bodyparts.len)
		return FALSE

	for(var/obj/item/bodypart/taur/lamia/L in bodyparts)
		if(!QDELETED(L))
			return TRUE

	return FALSE

/mob/living/carbon/human/proc/is_physically_restrained(node_type)
	if(handcuffed || legcuffed)
		return TRUE

	if(node_type == SEX_ORGAN_MOUTH && is_mouth_covered())
		return TRUE

	if(node_type == SEX_ORGAN_HANDS)
		if(HAS_TRAIT(src, TRAIT_HANDS_BLOCKED))
			return TRUE

		var/L = get_item_for_held_index(LEFT_HANDS)
		var/R = get_item_for_held_index(RIGHT_HANDS)
		if((L && !is_sex_toy(L)) && (R && !is_sex_toy(R)))
			return TRUE

	if(node_type == SEX_ORGAN_LEGS && legcuffed)
		return TRUE

	return FALSE

/mob/living/carbon/human/proc/get_worn_kink_tags()
	var/list/out = list()
	for(var/obj/item/I in get_equipped_items())
		if(!istype(I, /obj/item/clothing))
			continue

		var/obj/item/clothing/C = I
		var/list/kinks = C.get_propagade_kinks()
		if(!islist(kinks) || !kinks.len)
			continue

		for(var/k in kinks)
			out[k] = TRUE

	return out

/mob/living/carbon/human/proc/is_dullahan_head_partner()
	return FALSE

/mob/living/carbon/human/proc/is_erp_blocked_as_target()
	if(is_erp_defiant_in_combat())
		return TRUE

	if(has_erp_leprosy())
		return TRUE

	return FALSE

/mob/living/carbon/human/proc/is_erp_defiant_in_combat()
	return FALSE

/mob/living/carbon/human/proc/is_erp_defiant()
	return FALSE

/mob/living/carbon/human/proc/has_erp_leprosy()
	return HAS_TRAIT(src, TRAIT_LEPROSY)

/mob/living/proc/start_erp_session(mob/living/target)
	if(!ishuman(src))
		return null

	return erp_try_start(src, target, src)

/mob/living/proc/start_erp_session_atom(atom/target_atom)
	if(!ishuman(src))
		return null

	return erp_try_start(src, target_atom, src)

/mob/living/carbon/human/proc/set_sex_surrender_to(mob/living/carbon/human/mob_object)
	if(mob_object)
		sex_surrender_ref = WEAKREF(mob_object)
	else
		sex_surrender_ref = null

/mob/living/carbon/human/proc/is_surrendering_to(mob/living/carbon/human/mob_object)
	if(!mob_object || !sex_surrender_ref)
		return FALSE

	var/mob/living/carbon/human/target = sex_surrender_ref.resolve()
	if(!target || QDELETED(target))
		sex_surrender_ref = null
		return FALSE

	return target == mob_object

/proc/erp_try_start(atom/initiator, atom/target_atom, mob/living/actor, silent = FALSE)
	if(!ishuman(actor))
		return null

	if(!target_atom || QDELETED(target_atom))
		return null

	var/mob/living/carbon/human/human_actor = actor
	var/mob/living/carbon/human/consent = SSerp.get_consent_mob_for_target(target_atom)
	if(!istype(consent))
		return null

	human_actor.client?.prefs?.apply_customizer_organs_to_mob(human_actor)
	consent.client?.prefs?.apply_customizer_organs_to_mob(consent)

	if(!human_actor.can_do_sex())
		if(!silent)
			to_chat(actor, span_warning("I can't do this."))
		return null

	if(human_actor.is_erp_blocked_as_target() || consent.is_erp_blocked_as_target())
		return null

	if(!consent.client)
		if(!silent)
			to_chat(actor, span_warning("You can't do this."))
		return null

	var/client/C = actor.client
	var/datum/erp_controller/EC = SSerp.get_or_create_controller(initiator, C, actor)
	if(!EC)
		return null

	EC.add_partner_atom(target_atom)
	EC.open_ui(actor)
	return EC
