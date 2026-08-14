
#define HELD_MOB_FUCK_BASE_PAIN 3

#define HELD_MOB_FUCK_SAFE_MISMATCH 1.5

#define HELD_MOB_FUCK_DAMAGE_PER_MISMATCH 0.8

/datum/sex_action/held_mob_fuck
	abstract_type = /datum/sex_action/held_mob_fuck
	requires_hole_storage = TRUE
	stored_item_type = /obj/item/organ/genitals/penis
	stored_item_name = "penetrating member"

	requires_free_hands = FALSE

	check_same_tile = FALSE
	user_menu_zone_mask = SEX_UI_ZONE_GENITALS
	target_menu_zone_mask = SEX_UI_ZONE_GENITALS
	stamina_cost = 0.5
	do_time = 3 SECONDS

	var/obj/item/mob_holder/selected_holder


/datum/sex_action/held_mob_fuck/proc/get_holder_for(mob/living/user, mob/living/target)
	if(!user || QDELETED(target))
		return null
	var/obj/item/mob_holder/holder = user.get_active_held_item()
	if(!istype(holder) || QDELETED(holder) || holder.held_mob != target)
		return null
	return holder

/datum/sex_action/held_mob_fuck/proc/get_size_mismatch(mob/living/user, mob/living/target)
	if(!user || !target)
		return 1
	var/user_weight = user.get_mob_weight()
	var/target_weight = target.get_mob_weight()
	if(user_weight <= 0 || target_weight <= 0)
		return 1
	return max(1, (user_weight / target_weight) ** (1/3))

/datum/sex_action/held_mob_fuck/shows_on_menu(mob/living/user, mob/living/target)
	if(user == target)
		return FALSE
	if(!get_holder_for(user, target))
		return FALSE
	if(!user.getorganslot(ORGAN_SLOT_PENIS))
		return FALSE
	if(!target.getorganslot(hole_id))
		return FALSE
	return TRUE

/datum/sex_action/held_mob_fuck/can_perform(mob/living/user, mob/living/target)
	. = ..()
	if(!.)
		return FALSE
	if(user == target)
		return FALSE
	var/obj/item/mob_holder/holder = get_holder_for(user, target)
	if(!holder)
		return FALSE

	if(selected_holder && holder != selected_holder)
		return FALSE
	if(!user.getorganslot(ORGAN_SLOT_PENIS))
		return FALSE
	if(!target.getorganslot(hole_id))
		return FALSE
	if(!check_location_accessible(user, user, BODY_ZONE_PRECISE_GROIN, TRUE))
		return FALSE
	if(check_sex_lock(user, ORGAN_SLOT_PENIS))
		return FALSE
	return TRUE

/datum/sex_action/held_mob_fuck/can_continue(mob/living/user, mob/living/target)
	. = ..()
	if(!.)
		return FALSE


	if(!selected_holder)
		return get_holder_for(user, target) != null

	return get_holder_for(user, target) == selected_holder && selected_holder.held_mob == target

/datum/sex_action/held_mob_fuck/on_start(mob/living/user, mob/living/target)
	selected_holder = get_holder_for(user, target)
	if(!selected_holder)
		return FALSE
	return ..()

/datum/sex_action/held_mob_fuck/on_finish(mob/living/user, mob/living/target)
	selected_holder = null
	return ..()

/datum/sex_action/held_mob_fuck/lock_sex_object(mob/living/user, mob/living/target)
	add_sex_lock(user, ORGAN_SLOT_PENIS)
	add_sex_lock(user, user.get_active_precise_hand())
	if(hole_id)
		add_sex_lock(target, hole_id, null, FALSE)

/datum/sex_action/held_mob_fuck/get_scene_interaction()
	return SEX_SCENE_INTERACTION_PENETRATION

/datum/sex_action/held_mob_fuck/get_scene_user_role()
	return SEX_SCENE_ROLE_GIVER

/datum/sex_action/held_mob_fuck/get_scene_user_slot()
	return ORGAN_SLOT_PENIS

/datum/sex_action/held_mob_fuck/get_scene_target_role()
	return SEX_SCENE_ROLE_RECEIVER

/datum/sex_action/held_mob_fuck/get_scene_target_slot()
	return hole_id

/datum/sex_action/held_mob_fuck/proc/apply_held_mob_thrust(mob/living/user, mob/living/target)
	var/mismatch = get_size_mismatch(user, target)


	perform_sex_action(user, target, 2 * min(mismatch, 2), 0, 2 * min(mismatch, 2))


	var/pain_amt = HELD_MOB_FUCK_BASE_PAIN * mismatch
	perform_sex_action(target, user, 2, pain_amt, 2)

	if(mismatch <= HELD_MOB_FUCK_SAFE_MISMATCH)
		return
	if(prob(20))
		to_chat(target, span_userdanger("[user] is far too big for me - it hurts!"))

#undef HELD_MOB_FUCK_BASE_PAIN
#undef HELD_MOB_FUCK_SAFE_MISMATCH
#undef HELD_MOB_FUCK_DAMAGE_PER_MISMATCH
