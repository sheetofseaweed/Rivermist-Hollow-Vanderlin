// RMH - Searing Palm: a fire touch spell granting a hand with two intents.
// Brand intent burns a permanent mark and puts the spell on cooldown.
// Slap intent deals light burn damage and leaves a temporary handprint,
// and never consumes the hand or starts the cooldown.

#define SEARING_BRAND	/datum/intent/searing_palm/brand
#define SEARING_SLAP	/datum/intent/searing_palm/slap

/datum/action/cooldown/spell/undirected/touch/searing_palm
	name = "Searing Palm"
	desc = "Wreathe your hand in clinging flame, able to sear a permanent mark into flesh or leave a burning print with a slap."
	button_icon_state = "fireball_greater"
	sound = 'sound/magic/fireball.ogg'

	point_cost = 3
	school = SCHOOL_EVOCATION
	attunements = list(
		/datum/attunement/fire = 0.8,
	)

	cooldown_time = 10 MINUTES
	spell_cost = 100
	infinite_use = TRUE

	hand_path = /obj/item/melee/touch_attack/searing_palm
	draw_message = span_warning("Flame crawls across my palm and clings there.")
	drop_message = span_notice("The flame on my palm gutters out.")

	invocation = "IGNIS SIGILLUM!"
	invocation_type = INVOCATION_SHOUT

	var/slap_cooldown = 5 SECONDS
	var/next_slap = 0
	var/slap_damage = 5
	var/handprint_duration = 3 MINUTES
	var/max_brand_length = 20

/datum/action/cooldown/spell/undirected/touch/searing_palm/is_valid_target(atom/cast_on)
	return iscarbon(cast_on)

/datum/action/cooldown/spell/undirected/touch/searing_palm/cast_on_hand_hit(obj/item/melee/touch_attack/hand, atom/victim, mob/living/carbon/caster, list/modifiers)
	var/mob/living/carbon/patient = victim
	if(!istype(patient))
		return FALSE

	switch(caster.used_intent.type)
		if(SEARING_BRAND)
			return try_brand(patient, caster)
		if(SEARING_SLAP)
			return try_slap(patient, caster)
	return FALSE

/datum/action/cooldown/spell/undirected/touch/searing_palm/proc/try_brand(mob/living/carbon/patient, mob/living/carbon/caster)
	if(!is_held_still(patient, caster))
		to_chat(caster, span_warning("[patient] would need to be restrained or helpless to hold still for this."))
		return FALSE

	var/target_zone = caster.zone_selected
	var/obj/item/bodypart/limb = patient.get_bodypart(check_zone(target_zone))
	if(!limb)
		to_chat(caster, span_warning("[patient] is missing that limb."))
		return FALSE
	if(limb.brand_text)
		to_chat(caster, span_warning("[patient] is already branded there."))
		return FALSE
	if(!get_location_accessible(patient, target_zone))
		to_chat(caster, span_warning("The clothing is in the way!"))
		return FALSE

	// max_length is deliberately not passed: stripped_input trims with copytext,
	// which cuts by bytes and halves Cyrillic input. Clamp by character instead.
	var/chosen_text = stripped_input(caster, "Что выжечь на [parse_zone(target_zone)]? (максимум [max_brand_length] символов)", "Клеймо", "")
	if(!chosen_text)
		return FALSE
	chosen_text = trimtext(copytext_char(chosen_text, 1, max_brand_length + 1))
	if(!length(chosen_text))
		return FALSE
	if(QDELETED(patient) || QDELETED(limb) || limb != patient.get_bodypart(limb.body_zone) || limb.brand_text)
		return FALSE

	patient.visible_message(span_danger("[caster] presses a burning palm against [patient]'s [parse_zone(target_zone)]!"), \
		span_userdanger("[caster] presses a burning palm against your [parse_zone(target_zone)]!"))
	playsound(patient, 'sound/foley/burning_sacrifice.ogg', 50, TRUE)

	if(!do_after(caster, 4 SECONDS, patient))
		return FALSE
	// Re-check everything: do_after only watches the caster's own position, so the
	// victim can break free, walk off or pull armour on while the prompt is open.
	if(QDELETED(patient) || QDELETED(limb) || limb != patient.get_bodypart(limb.body_zone) || limb.brand_text)
		return FALSE
	if(!caster.Adjacent(patient) || !is_held_still(patient, caster) || !get_location_accessible(patient, target_zone))
		to_chat(caster, span_warning("The branding is interrupted."))
		return FALSE

	limb.brand_text = chosen_text
	limb.brand_zone = target_zone
	patient.apply_damage(10, BURN, limb.body_zone)
	patient.visible_message(span_danger("[patient]'s [parse_zone(target_zone)] sizzles as the sigil bites in!"), \
		span_userdanger("The sigil bites into your [parse_zone(target_zone)]. It will stay with you forever."))

	remove_hand(caster)
	return TRUE

/datum/action/cooldown/spell/undirected/touch/searing_palm/proc/try_slap(mob/living/carbon/patient, mob/living/carbon/caster)
	if(world.time < next_slap)
		to_chat(caster, span_warning("The flame on my palm has not gathered again yet."))
		return FALSE
	next_slap = world.time + slap_cooldown

	var/target_zone = caster.zone_selected
	var/obj/item/bodypart/limb = patient.get_bodypart(check_zone(target_zone))
	if(!limb)
		return FALSE
	if(!get_location_accessible(patient, target_zone))
		to_chat(caster, span_warning("The clothing is in the way - the flame finds no skin."))
		return FALSE

	patient.visible_message(span_danger("[caster] slaps [patient] across the [parse_zone(target_zone)] with a burning hand!"), \
		span_userdanger("[caster] slaps your [parse_zone(target_zone)] with a burning hand!"))
	playsound(patient, 'sound/foley/slap.ogg', 60, TRUE)
	patient.apply_damage(slap_damage, BURN, limb.body_zone)

	// Only one print at a time; the zone is already known to be bare.
	for(var/obj/item/bodypart/other as anything in patient.bodyparts)
		other.handprint_zone = null
	limb.set_handprint(target_zone, handprint_duration)

	return TRUE

/obj/item/melee/touch_attack/searing_palm
	name = "\improper searing palm"
	desc = "Your hand is wreathed in clinging flame.\n \
	<b>Brand</b>: Sear a permanent mark into a helpless target. Spends the spell.\n \
	<b>Slap</b>: Strike with the open flame, leaving a burning print for a few minutes."
	color = "#FF7B24"
	possible_item_intents = list(SEARING_BRAND, SEARING_SLAP)

/datum/intent/searing_palm
	reach = 1
	noaa = TRUE
	misscost = 0
	releasedrain = 0
	candodge = TRUE
	canparry = TRUE

/datum/intent/searing_palm/brand
	name = "brand"
	icon_state = "inuse"

/datum/intent/searing_palm/slap
	name = "slap"
	icon_state = "intouch"

/datum/spell_node/searing_palm
	name = "Searing Palm"
	desc = "Wreathe your hand in flame to brand flesh or leave a burning print."
	cost = 3
	node_x = RIGHT_X_TIER_1
	node_y = RIGHT_Y_RIGHT + 50
	prerequisites = list(/datum/spell_node/fire_affinity)
	spell_type = /datum/action/cooldown/spell/undirected/touch/searing_palm

#undef SEARING_BRAND
#undef SEARING_SLAP
