// Touching through clothes. Soft clothing (armor class light or none) never blocked interactions
// (check_location_accessible() only stops at medium and heavy armor), but the texts read as if the body were bare.
// Hand actions that rub or squeeze (not penetrating ones) now notice a soft garment over the spot: the line names it
// ("... through her linen shirt", "damp" / "soaked" when wet) and the touch arouses half as much.
// Notes: "breasts files/docs/IMPLEMENTATION_NOTES.md".

/// Arousal of a touch through a garment, as a share of the bare touch.
#define THROUGH_CLOTHES_AROUSAL_MULT 0.5

/datum/sex_action
	/// Body zone a touch reaches through clothes (BODY_ZONE_CHEST / BODY_ZONE_PRECISE_GROIN), or null.
	var/through_clothes_zone
	/// The touched one is the target (TRUE) or the user themselves (FALSE).
	var/through_clothes_on_target = TRUE

/// Outermost soft worn garment covering zone on wearer, or null when the spot is bare (or opened for access).
/proc/get_covering_soft_garment(mob/living/carbon/wearer, zone)
	if(!iscarbon(wearer))
		return null
	var/cover_flag = zone == BODY_ZONE_CHEST ? CHEST : GROIN
	var/list/candidates = list()
	if(ishuman(wearer))
		var/mob/living/carbon/human/human_wearer = wearer
		candidates += list(human_wearer.cloak, human_wearer.wear_armor, human_wearer.wear_shirt, human_wearer.wear_pants)
	candidates += list(wearer.undershirt, wearer.bra, wearer.underwear)
	for(var/obj/item/clothing/garment in candidates)
		if(!(garment.body_parts_covered & cover_flag))
			continue
		if(garment.armor_class > AC_LIGHT || garment.genital_access || garment.allow_erp_equipped)
			continue
		if(istype(garment, /obj/item/clothing/bra/shibari)) // ropes cover nothing
			continue
		return garment
	return null

/// "her linen shirt", "her damp linen shirt", "her soaked linen shirt".
/proc/get_through_clothes_name(mob/living/wearer, obj/item/clothing/garment)
	var/wet = ""
	var/datum/component/fluid_soaked/soak = garment.GetComponent(/datum/component/fluid_soaked)
	if(soak?.stain_level >= 2)
		wet = "soaked "
	else if(soak?.stain_level >= 1)
		wet = "damp "
	return "[wearer.p_their()] [wet][garment.name]"

/// The garment this action touches through right now, or null.
/datum/sex_action/proc/get_through_clothes_garment()
	if(!through_clothes_zone)
		return null
	var/mob/living/touched = through_clothes_on_target ? action_target : action_user
	return get_covering_soft_garment(touched, through_clothes_zone)

// Half the arousal for the touched one when there is cloth in between.
/datum/sex_action/perform_sex_action(mob/living/pleasure_receiver, mob/living/partner, arousal_amt, pain_amt, orgasm_prog_amt)
	if(through_clothes_zone)
		var/mob/living/touched = through_clothes_on_target ? action_target : action_user
		if(pleasure_receiver == touched && get_covering_soft_garment(touched, through_clothes_zone))
			arousal_amt *= THROUGH_CLOTHES_AROUSAL_MULT
			orgasm_prog_amt *= THROUGH_CLOTHES_AROUSAL_MULT
	return ..()

// The per-cycle line gets "through <garment>" before its final punctuation.
/datum/sex_action/spanify_force(string)
	var/obj/item/clothing/garment = get_through_clothes_garment()
	if(garment && istext(string))
		var/mob/living/touched = through_clothes_on_target ? action_target : action_user
		var/end = length(string)
		var/tail = ""
		while(end > 0 && (copytext(string, end, end + 1) in list(".", "!", "?")))
			tail = copytext(string, end, end + 1) + tail
			end--
		string = "[copytext(string, 1, end + 1)] through [get_through_clothes_name(touched, garment)][tail || "."]"
	return ..(string)

// Rubbing and squeezing by hand (penetrating ones need bare skin and are left as they are).
/datum/sex_action/masturbate/breasts
	through_clothes_zone = BODY_ZONE_CHEST
	through_clothes_on_target = FALSE

/datum/sex_action/masturbate/nipples
	through_clothes_zone = BODY_ZONE_CHEST
	through_clothes_on_target = FALSE

/datum/sex_action/masturbate/other/breasts
	through_clothes_zone = BODY_ZONE_CHEST

/datum/sex_action/masturbate/other/nipples
	through_clothes_zone = BODY_ZONE_CHEST

/datum/sex_action/masturbate/other/squeeze_breasts
	through_clothes_zone = BODY_ZONE_CHEST

/datum/sex_action/masturbate/clit_rub
	through_clothes_zone = BODY_ZONE_PRECISE_GROIN
	through_clothes_on_target = FALSE

/datum/sex_action/masturbate/vagina
	through_clothes_zone = BODY_ZONE_PRECISE_GROIN
	through_clothes_on_target = FALSE

/datum/sex_action/masturbate/other/clit_rub
	through_clothes_zone = BODY_ZONE_PRECISE_GROIN

/datum/sex_action/masturbate/other/clit
	through_clothes_zone = BODY_ZONE_PRECISE_GROIN

/datum/sex_action/masturbate/penis
	through_clothes_zone = BODY_ZONE_PRECISE_GROIN
	through_clothes_on_target = FALSE

/datum/sex_action/masturbate/other/penis
	through_clothes_zone = BODY_ZONE_PRECISE_GROIN

#undef THROUGH_CLOTHES_AROUSAL_MULT
