// RMH - Клеймо: one permanent brand per limb, plus a temporary fiery handprint.
// General examine reports only where the mark is; inspect_limb reveals the text.

// A target counts as held still when unconscious, cuffed, buckled, or held in an
// aggressive grab by the person doing the work.
/proc/is_held_still(mob/living/carbon/patient, mob/living/user)
	if(patient.stat >= UNCONSCIOUS || patient.handcuffed || patient.buckled)
		return TRUE
	if(user && user.pulling == patient && user.grab_state >= GRAB_AGGRESSIVE)
		return TRUE
	return FALSE

/obj/item/bodypart
	/// Text burned into this limb. One brand per limb.
	var/brand_text
	/// Precise body zone the brand sits on, used for clothing coverage.
	var/brand_zone
	/// Precise body zone of a temporary fiery handprint.
	var/handprint_zone
	/// world.time the handprint fades at.
	var/handprint_expire = 0

/obj/item/bodypart/proc/zone_is_exposed(zone, mob/user)
	if(!owner || isobserver(user))
		return TRUE
	return get_location_accessible(owner, zone)

/obj/item/bodypart/proc/get_visible_brand_zone(mob/user)
	if(!brand_text || !zone_is_exposed(brand_zone, user))
		return null
	return brand_zone

/obj/item/bodypart/proc/get_visible_handprint_zone(mob/user)
	if(!handprint_zone)
		return null
	if(world.time >= handprint_expire)
		handprint_zone = null
		return null
	if(!zone_is_exposed(handprint_zone, user))
		return null
	return handprint_zone

/obj/item/bodypart/proc/set_handprint(zone, duration)
	handprint_zone = zone
	handprint_expire = world.time + duration

/obj/item/bodypart/proc/clear_brand()
	brand_text = null
	brand_zone = null

/obj/item/bodypart/proc/get_brand_examine_lines(mob/user)
	. = list()
	var/brand_visible = get_visible_brand_zone(user)
	if(brand_visible)
		. += span_danger("Branded on the [parse_zone(brand_visible)]: <B>\"[uppertext(brand_text)]\"</B>")
	var/hand_visible = get_visible_handprint_zone(user)
	if(hand_visible)
		. += span_danger("A fiery handprint is seared across the [parse_zone(hand_visible)].")

// Reported in the body pass, not the face pass: get_examine_face is skipped
// entirely when the face is covered, which would let a mask hide the notice for a
// brand on a bare arm.
/mob/living/carbon/proc/get_brand_body_lines(mob/user, list/P)
	. = list()
	var/handprint_seen = FALSE
	for(var/obj/item/bodypart/part as anything in bodyparts)
		var/brand_zone = part.get_visible_brand_zone(user)
		if(brand_zone)
			. += span_danger("[capitalize(P[THEY])] [P[HAVE]] a brand burned onto [P[THEIR]] [parse_zone(brand_zone)].")
		if(!handprint_seen && part.get_visible_handprint_zone(user))
			handprint_seen = TRUE
	if(handprint_seen)
		. += span_danger("There is a fiery handprint seared onto [P[THEM]].")

// Only a legendary healer can burn a brand away. Called from the cautery's own
// interact_with_atom in surgery_tools_rogue.dm: that handler runs before attack()
// and would otherwise answer "no wounds!" first. Returns NONE to fall through.
/obj/item/weapon/surgery/cautery/proc/try_remove_brand(mob/living/carbon/patient, mob/living/user)
	if(!istype(patient) || !istype(user.a_intent, INTENT_USE))
		return NONE
	var/obj/item/bodypart/limb = patient.get_bodypart(check_zone(user.zone_selected))
	if(!limb || !limb.brand_text)
		return NONE

	if(user.get_skill_level(/datum/skill/misc/medicine) < SKILL_RANK_LEGENDARY)
		to_chat(user, span_warning("Scarring like this is beyond my craft. Only a legendary healer could cut it away cleanly."))
		return ITEM_INTERACT_BLOCKING

	if(!is_held_still(patient, user))
		to_chat(user, span_warning("[patient] needs to be held still for this."))
		return ITEM_INTERACT_BLOCKING

	if(!get_location_accessible(patient, limb.brand_zone))
		to_chat(user, span_warning("The clothing is in the way!"))
		return ITEM_INTERACT_BLOCKING

	var/brand_zone = limb.brand_zone
	patient.visible_message(span_danger("[user] begins carefully burning the brand from [patient]'s [parse_zone(brand_zone)]..."), \
		span_userdanger("[user] begins burning the brand from your [parse_zone(brand_zone)]!"))

	if(!do_after(user, 15 SECONDS, patient))
		return ITEM_INTERACT_BLOCKING
	if(QDELETED(patient) || QDELETED(limb) || !limb.brand_text)
		return ITEM_INTERACT_BLOCKING
	if(!get_temperature() || !is_held_still(patient, user) || !user.Adjacent(patient) || !get_location_accessible(patient, brand_zone))
		to_chat(user, span_warning("The work is interrupted."))
		return ITEM_INTERACT_BLOCKING

	limb.clear_brand()
	patient.apply_damage(10, BURN, limb.body_zone)
	patient.visible_message(span_notice("[user] burns the brand away, leaving only clean scar tissue."), \
		span_notice("The brand is gone. Only smooth scarring remains."))
	return ITEM_INTERACT_SUCCESS
