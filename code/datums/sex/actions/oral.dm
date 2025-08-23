
/datum/sex_action/oral_sex
	name = "Oral Sex"
	requires_hole_storage = TRUE
	hole_id = "mouth"
	stored_item_type = /obj/item/organ/penis
	stored_item_name = "receiving member"
	require_grab = FALSE
	check_same_tile = TRUE

/datum/sex_action/oral_sex/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!.)
		return FALSE

	/*
	// Check if user has required anatomy
	if(!user.getorganslot(ORGAN_SLOT_PENIS))
		return FALSE
	*/

	return TRUE
