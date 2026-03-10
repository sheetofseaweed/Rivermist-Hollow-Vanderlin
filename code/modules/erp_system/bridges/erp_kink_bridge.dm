/datum/kink/proc/is_active_for(datum/erp_actor/owner, datum/erp_actor/partner, datum/erp_sex_link/L)
	return FALSE

/datum/kink/bondage/is_active_for(datum/erp_actor/owner, datum/erp_actor/partner, datum/erp_sex_link/L)
	if(!owner || !partner || !L)
		return FALSE

	if(owner.is_restrained() || partner.is_restrained())
		return TRUE

	if(owner.has_kink_tag(type) || partner.has_kink_tag(type))
		return TRUE

	return FALSE

/datum/kink/domination/is_active_for(datum/erp_actor/owner, datum/erp_actor/partner, datum/erp_sex_link/L)
	if(!owner || !partner || !L)
		return FALSE

	if(!L.is_giving(owner))
		return FALSE

	if(partner.is_restrained())
		return TRUE

	if(partner.is_surrendering_to(owner))
		return TRUE

	if(owner.has_kink_tag(type))
		return TRUE

	return FALSE

/datum/kink/submissive/is_active_for(datum/erp_actor/owner, datum/erp_actor/partner, datum/erp_sex_link/L)
	if(!owner || !partner || !L)
		return FALSE

	if(L.is_giving(owner))
		return FALSE

	if(owner.is_restrained())
		return TRUE

	if(owner.is_surrendering_to(partner))
		return TRUE

	if(owner.has_kink_tag(type))
		return TRUE

	return FALSE

/datum/kink/gentle/is_active_for(datum/erp_actor/owner, datum/erp_actor/partner, datum/erp_sex_link/L)
	return L && (L.force <= SEX_FORCE_LOW && L.speed <= SEX_SPEED_LOW)

/datum/kink/rough/is_active_for(datum/erp_actor/owner, datum/erp_actor/partner, datum/erp_sex_link/L)
	return L && (L.force >= SEX_FORCE_HIGH || L.speed >= SEX_SPEED_HIGH)

/datum/kink/public/is_active_for(datum/erp_actor/owner, datum/erp_actor/partner, datum/erp_sex_link/L)
	var/mob/M = owner?.physical
	if(!M)
		return FALSE

	var/turf/T = get_turf(M)
	if(!T)
		return FALSE

	if(T.outdoor_effect?.weatherproof)
		return TRUE

	for(var/mob/living/kink_object in view(5, M))
		if(kink_object == owner?.physical || kink_object == partner?.physical)
			continue
		if(kink_object.client)
			return TRUE

	return FALSE
