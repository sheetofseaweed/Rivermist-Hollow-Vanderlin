/datum/sex_action/hole_storage
	abstract_type = /datum/sex_action/hole_storage
	name = "hole_storage"
	requires_hole_storage = FALSE //ironic
	hole_id = ORGAN_SLOT_VAGINA
	stored_item_type = /obj/item
	continous = TRUE
	user_priority = 1
	target_priority = 1
	var/self = FALSE
	var/obj/item/organ/genitals/target_organ

/datum/sex_action/hole_storage/can_perform(mob/living/user, mob/living/target)
	. = ..()
	if(!.)
		return FALSE
	return TRUE
