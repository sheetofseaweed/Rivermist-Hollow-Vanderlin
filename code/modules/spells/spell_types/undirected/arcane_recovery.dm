/// Wizard feature: once per long rest, ten quiet seconds bring spent slot levels back.
/datum/action/cooldown/spell/undirected/arcane_recovery
	name = "Arcane Recovery"
	desc = "Once per long rest, spend ten quiet seconds outside combat to recover spent spell slots: two levels per rank of arcane skill, up to ten. The selected tier is restored first."
	button_icon_state = "book1"
	sound = 'sound/magic/charged.ogg'

	spell_type = SPELL_MANA
	spell_cost = 0
	charge_required = TRUE
	charge_time = 10 SECONDS
	charge_slowdown = 0
	charge_drain = 0
	cooldown_time = 30 SECONDS
	invocation_type = INVOCATION_NONE
	spell_requirements = SPELL_REQUIRES_NO_ANTIMAGIC | SPELL_REQUIRES_NO_MOVE
	spell_flags = SPELL_IGNORE_SPELLBLOCK
	learnable = FALSE
	feature_id = FEATURE_ARCANE_RECOVERY
	feature_rest = REST_LONG

/datum/action/cooldown/spell/undirected/arcane_recovery/proc/get_budget(datum/spell_slots/slots)
	return min(2 * slots.get_rank(), 10)

/datum/action/cooldown/spell/undirected/arcane_recovery/can_cast_spell(feedback = TRUE)
	. = ..()
	if(!.)
		return FALSE
	var/datum/spell_slots/slots = get_feature_slots()
	if(!slots)
		if(feedback)
			owner.balloon_alert(owner, "no spell slots to recover!")
		return FALSE
	if(owner.cmode)
		if(feedback)
			owner.balloon_alert(owner, "cannot focus while ready for combat!")
		return FALSE
	if(!length(slots.get_recovery(slots.get_selected_level(), get_budget(slots))))
		if(feedback)
			owner.balloon_alert(owner, "no spent slots to recover!")
		return FALSE
	return TRUE

/// Druid feature: the same recovery read from the druidic rank on the slot datum.
/datum/action/cooldown/spell/undirected/arcane_recovery/natural
	name = "Natural Recovery"
	desc = "Once per long rest, spend ten quiet seconds in communion with the land to recover spent spell slots: two levels per rank of druidic skill, up to ten."
	button_icon_state = "shapeshift"

/// The charge was spent by the cast chain; only the recovery itself happens here.
/datum/action/cooldown/spell/undirected/arcane_recovery/cast(atom/cast_on)
	. = ..()
	var/datum/spell_slots/slots = get_spell_slots()
	if(!slots)
		return
	var/list/recovery = slots.get_recovery(slots.get_selected_level(), get_budget(slots))
	var/restored = slots.apply_recovery(recovery)
	to_chat(owner, span_notice("Arcane power seeps back into me. [restored] spell slot[restored == 1 ? "" : "s"] restored."))
