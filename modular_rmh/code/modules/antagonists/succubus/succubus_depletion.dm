// Recoverable consequences and persistent evidence left by direct Succubus harvesting.

/datum/status_effect/debuff/succubus_depletion
	id = "succubus_depletion"
	status_type = STATUS_EFFECT_UNIQUE
	duration = SUCCUBUS_DEPLETION_TOUCHED_DURATION
	alert_type = /atom/movable/screen/alert/status_effect/debuff/succubus_depletion
	effectedstats = list(STAT_ENDURANCE = -1)
	remove_on_fullheal = TRUE
	var/stage = SUCCUBUS_DEPLETION_SOUL_TOUCHED

/datum/status_effect/debuff/succubus_depletion/on_creation(mob/living/new_owner, duration_override, ...)
	. = ..()
	update_alert()

/datum/status_effect/debuff/succubus_depletion/on_apply()
	. = ..()
	if(!.)
		return FALSE
	to_chat(owner, span_warning("The sweetness ebbs, leaving a hollow hunger in its wake."))
	return TRUE

/datum/status_effect/debuff/succubus_depletion/get_examine_text(mob/user, list/pronouns)
	switch(stage)
		if(SUCCUBUS_DEPLETION_SOUL_DRAINED)
			return span_warning("SUBJECTPRONOUN looks unusually pale and tired.")
		if(SUCCUBUS_DEPLETION_HOLLOWED)
			return span_danger("SUBJECTPRONOUN looks deathly pale; a faint shiver runs through cold skin.")
	return null

/datum/status_effect/debuff/succubus_depletion/proc/add_harvest()
	set_stage(min(stage + 1, SUCCUBUS_DEPLETION_MAX_STAGE))

/datum/status_effect/debuff/succubus_depletion/proc/set_stage(new_stage)
	var/previous_stage = stage
	stage = clamp(new_stage, SUCCUBUS_DEPLETION_SOUL_TOUCHED, SUCCUBUS_DEPLETION_MAX_STAGE)
	switch(stage)
		if(SUCCUBUS_DEPLETION_SOUL_TOUCHED)
			duration = world.time + SUCCUBUS_DEPLETION_TOUCHED_DURATION
			initial_duration = SUCCUBUS_DEPLETION_TOUCHED_DURATION
			effectedstats = list(STAT_ENDURANCE = -1)
		if(SUCCUBUS_DEPLETION_SOUL_DRAINED)
			duration = world.time + SUCCUBUS_DEPLETION_DRAINED_DURATION
			initial_duration = SUCCUBUS_DEPLETION_DRAINED_DURATION
			effectedstats = list(
				STAT_ENDURANCE = -1,
				STAT_CONSTITUTION = -1,
				STAT_PERCEPTION = -1,
			)
			if(stage > previous_stage)
				to_chat(owner, span_warning("The hunger returns sharper than before. My limbs feel leaden, and warmth flees my skin."))
		if(SUCCUBUS_DEPLETION_HOLLOWED)
			duration = world.time + SUCCUBUS_DEPLETION_HOLLOWED_DURATION
			initial_duration = SUCCUBUS_DEPLETION_HOLLOWED_DURATION
			effectedstats = list(
				STAT_ENDURANCE = -2,
				STAT_CONSTITUTION = -2,
				STAT_STRENGTH = -1,
				STAT_PERCEPTION = -1,
			)
			if(stage > previous_stage)
				to_chat(owner, span_userdanger("Something vital tears loose. I feel achingly, ravenously hollow."))
	owner.set_stat_modifier("[id]", effectedstats)
	update_alert()

/datum/status_effect/debuff/succubus_depletion/proc/relieve_one_stage()
	if(stage <= SUCCUBUS_DEPLETION_SOUL_TOUCHED)
		to_chat(owner, span_notice("Warmth returns as the last of the hollow hunger loosens its grip."))
		owner.remove_status_effect(/datum/status_effect/debuff/succubus_depletion)
		return TRUE

	set_stage(stage - 1)
	to_chat(owner, span_notice("A little warmth returns, and the unnatural hunger recedes."))
	return TRUE

/datum/status_effect/debuff/succubus_depletion/proc/apply_nutrition_loss()
	var/nutrition_loss
	switch(stage)
		if(SUCCUBUS_DEPLETION_SOUL_TOUCHED)
			nutrition_loss = SUCCUBUS_DEPLETION_TOUCHED_NUTRITION
		if(SUCCUBUS_DEPLETION_SOUL_DRAINED)
			nutrition_loss = SUCCUBUS_DEPLETION_DRAINED_NUTRITION
		if(SUCCUBUS_DEPLETION_HOLLOWED)
			nutrition_loss = SUCCUBUS_DEPLETION_HOLLOWED_NUTRITION
	if(owner.nutrition > NUTRITION_LEVEL_STARVING)
		owner.set_nutrition(max(owner.nutrition - nutrition_loss, NUTRITION_LEVEL_STARVING))

/datum/status_effect/debuff/succubus_depletion/proc/update_alert()
	if(!linked_alert)
		return
	switch(stage)
		if(SUCCUBUS_DEPLETION_SOUL_TOUCHED)
			linked_alert.name = "Soul-Touched"
			linked_alert.desc = "A sweet encounter left behind an unnatural hunger."
		if(SUCCUBUS_DEPLETION_SOUL_DRAINED)
			linked_alert.name = "Soul-Drained"
			linked_alert.desc = "Repeated infernal feeding has left me pale, weak, and ravenous."
		if(SUCCUBUS_DEPLETION_HOLLOWED)
			linked_alert.name = "Hollowed"
			linked_alert.desc = "Too much of my vitality has been torn away. I need help."

/atom/movable/screen/alert/status_effect/debuff/succubus_depletion
	name = "Soul-Touched"
	desc = "A sweet encounter left behind an unnatural hunger."
	icon_state = "hunger2"

/datum/status_effect/succubus_brand
	id = "succubus_brand"
	status_type = STATUS_EFFECT_UNIQUE
	duration = -1
	tick_interval = -1
	alert_type = null
	var/brand_location
	var/strongest_stage = SUCCUBUS_DEPLETION_SOUL_TOUCHED
	var/revealed = FALSE
	/// A light blessing can relieve this brand's victim once. Full cleansing removes the brand.
	var/light_blessing_used = FALSE

/datum/status_effect/succubus_brand/on_apply()
	. = ..()
	if(!brand_location)
		brand_location = pick(
			"on the inside of the left wrist",
			"on the inside of the right wrist",
			"beneath the collarbone",
			"over the heart",
			"low on the abdomen",
			"between the shoulder blades",
		)
	return .

/datum/status_effect/succubus_brand/get_examine_text(mob/user, list/pronouns)
	if(!revealed)
		return null
	return span_danger("A dark, thorn-ringed brand is visible [brand_location].")

/datum/status_effect/succubus_brand/proc/record_stage(new_stage)
	strongest_stage = max(strongest_stage, new_stage)

/datum/status_effect/succubus_brand/proc/reveal()
	if(revealed)
		return FALSE
	revealed = TRUE
	return TRUE

/mob/living/carbon/human/proc/get_succubus_depletion_diagnosis()
	var/datum/status_effect/debuff/succubus_depletion/depletion = has_status_effect(/datum/status_effect/debuff/succubus_depletion)
	if(!depletion || depletion.stage < SUCCUBUS_DEPLETION_SOUL_DRAINED)
		return null

	if(depletion.stage >= SUCCUBUS_DEPLETION_HOLLOWED)
		return "The deathly pallor, cold skin, and profound weakness do not match ordinary hunger. Their vitality has been unnaturally leeched away."
	return "The pallor and fatigue are too severe for ordinary hunger. Something has unnaturally depleted their vitality."

/mob/living/carbon/human/proc/apply_succubus_blessing(mob/living/blesser)
	var/changed = FALSE
	var/datum/status_effect/succubus_brand/brand = has_status_effect(/datum/status_effect/succubus_brand)
	if(brand?.reveal())
		changed = TRUE
		visible_message(
			span_boldwarning("A dark, thorn-ringed brand blooms [brand.brand_location] on [src] beneath the holy light!"),
			span_userdanger("Holy light bites into my skin as a dark, thorn-ringed brand blooms [brand.brand_location]!"),
		)

	var/datum/status_effect/debuff/succubus_depletion/depletion = has_status_effect(/datum/status_effect/debuff/succubus_depletion)
	if(brand && !brand.light_blessing_used && depletion?.relieve_one_stage())
		brand.light_blessing_used = TRUE
		changed = TRUE

	if(changed && blesser)
		to_chat(blesser, span_notice("The blessing exposes and relieves an infernal affliction within [src]."))
	return changed

/mob/living/carbon/human/proc/cleanse_succubus_afflictions()
	var/changed = FALSE
	if(has_status_effect(/datum/status_effect/debuff/succubus_depletion))
		remove_status_effect(/datum/status_effect/debuff/succubus_depletion)
		changed = TRUE
	if(has_status_effect(/datum/status_effect/succubus_fatal_drain_scar))
		remove_status_effect(/datum/status_effect/succubus_fatal_drain_scar)
		changed = TRUE
	if(has_status_effect(/datum/status_effect/succubus_brand))
		remove_status_effect(/datum/status_effect/succubus_brand)
		changed = TRUE
	return changed

/mob/living/carbon/human/proc/apply_succubus_harvest_depletion()
	var/datum/status_effect/debuff/succubus_depletion/depletion = has_status_effect(/datum/status_effect/debuff/succubus_depletion)
	if(depletion)
		depletion.add_harvest()
	else
		depletion = apply_status_effect(/datum/status_effect/debuff/succubus_depletion)
	if(!depletion)
		return null

	depletion.apply_nutrition_loss()
	var/datum/status_effect/succubus_brand/brand = has_status_effect(/datum/status_effect/succubus_brand)
	if(!brand)
		brand = apply_status_effect(/datum/status_effect/succubus_brand)
	brand?.record_stage(depletion.stage)
	return depletion
