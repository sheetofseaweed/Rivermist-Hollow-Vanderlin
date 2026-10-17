// Bare penis and testicles seen from the front go above gloves, wrists, rings, belts and sleeves,
// under the lifted breasts (PENIS_FRONT_LAYER, TESTICLES_FRONT_LAYER). Same split as body_breasts_front.dm.
// Only when nothing is worn over the groin. Taur genitals are drawn on the taur body and are left alone.

/// Whether the front view of the groin genitals goes above hands, gloves and rings.
/mob/living/carbon/human/proc/can_lift_groin_front()
	if(wear_pants || underwear || wear_shirt || wear_armor)
		return FALSE
	if(cloak?.alternate_worn_layer == TABARD_LAYER)
		return FALSE
	return TRUE

/// Splits the front view off appearances drawn on from_layer when owner's groin is bare.
/datum/sprite_accessory/genitals/proc/lift_groin_front(list/appearance_list, obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/human/owner, from_layer, front_layer)
	if(draw_above_clothes || !istype(owner) || is_taur_owner(owner) || !owner.can_lift_groin_front())
		return
	var/icon_file = get_icon(organ, bodypart, owner)
	for(var/mutable_appearance/appearance as anything in appearance_list.Copy())
		if(appearance.layer != -from_layer)
			continue
		var/cache_key = "[type]|[icon_file]|[appearance.icon_state]|[organ?.accessory_colors]"
		appearance_list += split_south_view(appearance, cache_key, front_layer)

/datum/sprite_accessory/genitals/penis/adjust_appearance_list(list/appearance_list, obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/human/owner)
	..()
	lift_groin_front(appearance_list, organ, bodypart, owner, BODY_ADJ_MID_LAYER, PENIS_FRONT_LAYER)

/datum/sprite_accessory/genitals/testicles/adjust_appearance_list(list/appearance_list, obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/human/owner)
	..()
	lift_groin_front(appearance_list, organ, bodypart, owner, BODY_ADJ_LAYER, TESTICLES_FRONT_LAYER)

/obj/item/organ/genitals/penis/get_render_key_state()
	. = ..()
	if(ishuman(owner))
		var/mob/living/carbon/human/human_owner = owner
		if(human_owner.can_lift_groin_front())
			. = "[.]_front"

/obj/item/organ/genitals/filling_organ/testicles/get_render_key_state()
	. = ..()
	if(ishuman(owner))
		var/mob/living/carbon/human/human_owner = owner
		if(human_owner.can_lift_groin_front())
			. = "[.]_front"
