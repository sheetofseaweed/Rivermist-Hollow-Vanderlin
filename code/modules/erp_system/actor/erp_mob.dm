/datum/erp_actor/mob
	parent_type = /datum/erp_actor

/datum/erp_actor/mob/New(atom/A)
	var/mob/M = A
	if(!istype(M))
		qdel(src)
		return

	. = ..(A)

	client = M.client
	post_init()

/datum/erp_actor/mob/collect_organs()
	var/mob/M = get_mob()
	if(!M)
		return

	var/datum/erp_sex_organ/mouth/mouth = get_or_create_mouth_organ()
	if(!(mouth in organs))
		add_organ(mouth)

	if(!hascall(M, "getorganslot"))
		return

	for(var/slot in list(ORGAN_SLOT_PENIS, ORGAN_SLOT_VAGINA, ORGAN_SLOT_BREASTS, ORGAN_SLOT_ANUS))
		var/obj/item/organ/organ = call(M, "getorganslot")(slot)
		var/datum/erp_sex_organ/erp_organ = erp_ensure_sex_organ(organ)
		if(erp_organ)
			add_organ(erp_organ)

/datum/erp_actor/mob/proc/get_or_create_mouth_organ()
	for(var/datum/erp_sex_organ/O in organs)
		if(O.erp_organ_type == SEX_ORGAN_MOUTH)
			return O

	var/datum/erp_sex_organ/mouth/M = new(physical)
	M.erp_organ_type = SEX_ORGAN_MOUTH
	return M

/// Returns physical as a mob if possible.
/datum/erp_actor/mob/get_mob()
	var/mob/M = physical
	return istype(M) ? M : null

/// Mob-backed actors can register signals.
/datum/erp_actor/mob/can_register_signals()
	return TRUE
