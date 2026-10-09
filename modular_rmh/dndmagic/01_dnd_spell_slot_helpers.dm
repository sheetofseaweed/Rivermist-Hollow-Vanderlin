// Opt-in hybrid casting. The base spell lifecycle owns validation and payment.
/datum/action/cooldown/spell
	var/dnd_use_spell_slots = FALSE
	var/dnd_min_spell_slot_level = 1
	var/dnd_max_spell_slot_level = 5
	/// Zero disables minor casting. Otherwise this is its attunement-adjusted mana cost.
	var/dnd_minor_mana_cost = 0
	var/obj/projectile/dnd_minor_projectile_type
	/// Null means no cast is in progress; zero is a real, minor cast.
	var/tmp/dnd_cast_slot_level = null
	var/tmp/dnd_cast_paid = FALSE
	var/dnd_spell_slot_label

/datum/action/cooldown/spell/proc/dnd_get_cast_level()
	if(!isnull(dnd_cast_slot_level))
		return dnd_cast_slot_level
	var/mob/living/carbon/human/caster = owner
	if(!istype(caster))
		return null
	return caster.get_selected_dnd_spell_slot_level()

/datum/action/cooldown/spell/proc/dnd_get_spell_label()
	return dnd_spell_slot_label || name

/datum/action/cooldown/spell/proc/dnd_spell_slot_can_cast(feedback = TRUE)
	var/mob/living/carbon/human/caster = owner
	if(!istype(caster))
		return FALSE
	if(dnd_cast_paid)
		return TRUE

	var/level = dnd_get_cast_level()
	if(level == DND_MINOR_TIER)
		if(dnd_minor_mana_cost <= 0)
			if(feedback)
				to_chat(caster, span_warning("[dnd_get_spell_label()] requires a spell slot; it has no minor form."))
			return FALSE
		var/available_mana = 0
		for(var/datum/mana_pool/pool as anything in caster.get_all_pools())
			available_mana += pool.get_attuned_amount(attunements, caster)
		if(available_mana < dnd_minor_mana_cost)
			if(feedback)
				caster.balloon_alert(caster, "Not enough mana for minor cast!")
			return FALSE
		return TRUE

	if(level < dnd_min_spell_slot_level || level > dnd_max_spell_slot_level)
		if(feedback)
			to_chat(caster, span_warning("[dnd_get_spell_label()] requires a level [dnd_min_spell_slot_level]-[dnd_max_spell_slot_level] slot."))
		return FALSE
	return caster.can_spend_dnd_spell_slot(level, feedback)

/// Called after before_cast and final validation, before releasing the effect.
/datum/action/cooldown/spell/proc/dnd_pay_cast()
	if(dnd_cast_paid || !dnd_spell_slot_can_cast())
		return FALSE

	var/mob/living/carbon/human/caster = owner
	dnd_cast_slot_level = dnd_get_cast_level()
	// HUD/mana signals can ask whether this action is available during payment.
	dnd_cast_paid = TRUE
	if(dnd_cast_slot_level == DND_MINOR_TIER)
		caster.consume_mana(attunements, dnd_minor_mana_cost)
		caster.balloon_alert(caster, "[dnd_get_spell_label()]: minor")
	else
		if(!caster.spend_dnd_spell_slot(dnd_cast_slot_level))
			dnd_cast_paid = FALSE
			return FALSE
		caster.balloon_alert(caster, "[dnd_get_spell_label()]: level [dnd_cast_slot_level]")
	return TRUE
