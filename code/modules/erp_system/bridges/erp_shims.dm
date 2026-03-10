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
