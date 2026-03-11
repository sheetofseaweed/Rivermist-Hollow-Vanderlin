
/datum/sex_action/object_fuck
	abstract_type = /datum/sex_action/object_fuck
	name = "object_fuck"
	requires_hole_storage = TRUE
	requires_free_hands = TRUE
	hole_id = ORGAN_SLOT_VAGINA
	stored_item_type = /obj/item

/datum/sex_action/object_fuck/get_storage_check_item(mob/living/user, mob/living/target)
	var/mob/living/storage_insertor = get_storage_insertor(user, target)
	return get_sextoy_in_hand(storage_insertor)

#define MAX_TOY_SIZE WEIGHT_CLASS_SMALL

/proc/get_sextoy_in_hand(mob/living/user)

	var/obj/item/thing = user.get_active_held_item()
	if(thing != null && thing.w_class < MAX_TOY_SIZE) //Anything smaller than this fucks the puss.
		return thing
	return null

#undef MAX_TOY_SIZE
