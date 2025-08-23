/datum/sex_action/penetrate_vagina
	name = "Penetrate Vagina"
	requires_hole_storage = TRUE
	hole_id = "vagina"
	stored_item_type = /obj/item/organ/genitals/penis // Or whatever penis item type you use
	stored_item_name = "penetrating member"
	require_grab = TRUE
	check_same_tile = TRUE

/datum/sex_action/penetrate_vagina/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!.)
		return FALSE
	/*
	if(!user.getorganslot(ORGAN_SLOT_PENIS))
		return FALSE

	if(!target.getorganslot(ORGAN_SLOT_VAGINA))
		return FALSE
	*/
	return TRUE

/datum/sex_action/penetrate_anus
	name = "Penetrate Anus"
	requires_hole_storage = TRUE
	hole_id = "anus"
	stored_item_type = /obj/item/organ/genitals/penis
	stored_item_name = "penetrating member"
	require_grab = TRUE
	check_same_tile = TRUE

/datum/sex_action/penetrate_anus/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!.)
		return FALSE

	/*
	// Check if user has required anatomy
	if(!user.getorganslot(ORGAN_SLOT_PENIS))
		return FALSE
	*/

	return TRUE
