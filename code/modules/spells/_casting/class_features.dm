// Class feature pools on the slot datum: charges per rest, spent by spells that carry a feature id.

/datum/action/cooldown/spell
	/// Feature pool this spell spends; null for ordinary spells.
	var/feature_id
	/// Rest that refills the pool.
	var/feature_rest = REST_SHORT

/datum/action/cooldown/spell/proc/get_feature_slots()
	RETURN_TYPE(/datum/spell_slots)
	var/datum/spell_slots/slots = get_spell_slots()
	if(slots)
		return slots
	var/mob/living/living_owner = owner
	return istype(living_owner) ? living_owner.ensure_spell_slots_for_job() : null

/// Rank of the skill that sizes the owner's pools; zero without slot state.
/datum/action/cooldown/spell/proc/get_feature_rank()
	var/datum/spell_slots/slots = get_feature_slots()
	return slots ? slots.get_rank() : 0

/// Pool size by rank. Channel pools hold one charge, two from Expert; other classes scale their own way.
/datum/action/cooldown/spell/proc/get_feature_max_charges()
	var/rank = get_feature_rank()
	switch(feature_id)
		if(FEATURE_ARCANE_RECOVERY)
			return 1
		if(FEATURE_LAY_ON_HANDS)
			return max(LAY_ON_HANDS_POOL_PER_RANK, LAY_ON_HANDS_POOL_PER_RANK * rank)
		if(FEATURE_CHANNEL_OATH)
			return 1
		if(FEATURE_WILD_SHAPE)
			return WILD_SHAPE_CHARGES
		if(FEATURE_SORCERY_POINTS, FEATURE_BARDIC_INSPIRATION, FEATURE_KI, FEATURE_HUNTERS_MARK)
			return rank + 1
		if(FEATURE_RAGE)
			return RAGE_CHARGES_BASE + (rank >= SKILL_RANK_MASTER ? 2 : (rank >= SKILL_RANK_EXPERT ? 1 : 0))
	return rank >= SKILL_RANK_EXPERT ? 2 : 1

/// Rest that refills this pool. Bardic Inspiration also returns on a short rest from Journeyman.
/datum/action/cooldown/spell/proc/get_feature_rest()
	if(feature_id == FEATURE_BARDIC_INSPIRATION && get_feature_rank() >= SKILL_RANK_JOURNEYMAN)
		return REST_SHORT | REST_LONG
	return feature_rest

/// Ensures the pool on the slot datum, resizing it when the rank moved, and shows the rest HUD.
/datum/action/cooldown/spell/proc/register_feature()
	RETURN_TYPE(/datum/spell_slots)
	if(!feature_id)
		return null
	var/datum/spell_slots/slots = get_feature_slots()
	if(!slots)
		return null
	var/max_charges = get_feature_max_charges()
	var/rest_type = get_feature_rest()
	if(!slots.has_feature(feature_id) || slots.get_feature_max(feature_id) != max_charges || slots.get_feature_rest(feature_id) != rest_type)
		slots.add_feature(feature_id, max_charges, rest_type)
	if(ishuman(owner))
		var/mob/living/carbon/human/human_owner = owner
		human_owner.grant_spell_slot_hud()
	return slots

/// Charges spent per cast. Lay on Hands overrides this with its touch size.
/datum/action/cooldown/spell/proc/get_feature_cost()
	return 1

/datum/action/cooldown/spell/proc/feature_ready(feedback = TRUE)
	var/datum/spell_slots/slots = register_feature()
	if(!slots)
		if(feedback)
			owner.balloon_alert(owner, "no power to draw on!")
		return FALSE
	if(slots.get_feature_charges(feature_id) < get_feature_cost())
		if(feedback)
			owner.balloon_alert(owner, "[get_slot_label()] needs a rest!")
		return FALSE
	return TRUE

/datum/action/cooldown/spell/proc/spend_feature(amount = 1)
	var/datum/spell_slots/slots = register_feature()
	return slots?.use_feature(feature_id, amount)

/// Pool readout for the action button: "Rage (2/4)".
/datum/action/cooldown/spell/proc/get_feature_button_suffix()
	if(!feature_id)
		return ""
	var/datum/spell_slots/slots = get_spell_slots()
	if(!slots || !slots.has_feature(feature_id))
		return ""
	return " ([slots.get_feature_charges(feature_id)]/[slots.get_feature_max(feature_id)])"
