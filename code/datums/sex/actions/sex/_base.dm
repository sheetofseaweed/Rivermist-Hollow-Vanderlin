/datum/sex_action/sex
	stored_item_type = /obj/item/organ/genitals/penis
	stored_item_name = "penetrating member"
	requires_hole_storage = TRUE
	abstract_type = /datum/sex_action/sex
	user_menu_zone_mask = SEX_UI_ZONE_GENITALS
	target_menu_zone_mask = SEX_UI_ZONE_GENITALS
	knot_on_finish = TRUE
	can_knot = TRUE

/datum/sex_action/sex/can_perform(mob/living/user, mob/living/target)
	. = ..()
	if(!.)
		return FALSE
	return TRUE

/datum/sex_action/sex/get_scene_interaction()
	if(hole_id == BODY_ZONE_PRECISE_MOUTH)
		return SEX_SCENE_INTERACTION_ORAL
	if(hole_id in list(ORGAN_SLOT_VAGINA, ORGAN_SLOT_ANUS))
		return SEX_SCENE_INTERACTION_PENETRATION
	return ..()

/datum/sex_action/sex/get_scene_user_role()
	if(hole_id == BODY_ZONE_PRECISE_MOUTH)
		return SEX_SCENE_ROLE_RECEIVER
	if(hole_id in list(ORGAN_SLOT_VAGINA, ORGAN_SLOT_ANUS))
		return SEX_SCENE_ROLE_GIVER
	return ..()

/datum/sex_action/sex/get_scene_user_slot()
	return ORGAN_SLOT_PENIS

/datum/sex_action/sex/get_scene_target_role()
	if(hole_id == BODY_ZONE_PRECISE_MOUTH)
		return SEX_SCENE_ROLE_GIVER
	if(hole_id in list(ORGAN_SLOT_VAGINA, ORGAN_SLOT_ANUS))
		return SEX_SCENE_ROLE_RECEIVER
	return ..()

/datum/sex_action/sex/get_scene_target_slot()
	return hole_id

/datum/sex_action/sex/lock_sex_object(mob/living/user, mob/living/target)
	add_sex_lock(user, ORGAN_SLOT_PENIS)
	if(hole_id)
		add_sex_lock(target, hole_id, null, FALSE)

/datum/sex_action/generic

/datum/sex_action/generic/shows_on_menu(mob/living/user, mob/living/target)
	return FALSE
