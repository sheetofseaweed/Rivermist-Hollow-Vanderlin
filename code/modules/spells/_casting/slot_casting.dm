// Spell slot casting. A spell joins the slot economy only when it has a slot level
// and its caster's mind carries a /datum/spell_slots; everything else keeps legacy mana costs.

/datum/action/cooldown/spell
	/// Base slot level 1 to 5. Null keeps legacy costing; zero marks a cantrip.
	var/slot_level = null
	/// Highest level whose profile differs; higher slots still cast at this profile.
	var/slot_level_max = SPELL_SLOT_MAX
	/// Reserve mana cost of the Minor form. Zero means no Minor form.
	var/minor_cost = 0
	/// Projectile fired by the Minor form of projectile spells.
	var/obj/projectile/minor_projectile_type
	/// Slot-only spells refuse Minor casting even with a Minor profile.
	var/slot_only = FALSE
	/// One concentration effect per caster; wounds can break it.
	var/concentration = FALSE
	/// Label used in slot feedback. Defaults to the name.
	var/slot_label
	/// Null means no cast in progress; zero is a real Minor cast.
	var/tmp/cast_slot_level = null
	var/tmp/cast_paid = FALSE

/datum/action/cooldown/spell/proc/get_spell_slots()
	RETURN_TYPE(/datum/spell_slots)
	var/mob/living/caster = owner
	if(!istype(caster))
		return null
	return caster.mind?.spell_slots

/datum/action/cooldown/spell/proc/uses_spell_slots()
	return slot_level > 0 && !isnull(get_spell_slots())

/// The level locked for the cast in progress, or the caster's selection.
/datum/action/cooldown/spell/proc/get_cast_level()
	if(!isnull(cast_slot_level))
		return cast_slot_level
	var/datum/spell_slots/slots = get_spell_slots()
	if(!slots)
		return null
	return slots.get_selected_level()

/// Level for scaling tables: the cast level clamped to the profile range. Null outside slot casting.
/datum/action/cooldown/spell/proc/get_effect_level()
	if(!uses_spell_slots())
		return null
	var/level = get_cast_level()
	if(isnull(level) || level == SPELL_SLOT_MINOR)
		return level
	return clamp(level, slot_level, slot_level_max)

/datum/action/cooldown/spell/proc/get_slot_label()
	return slot_label || name

/datum/action/cooldown/spell/proc/get_minor_cost()
	return minor_cost

/// Skill multiplier: 0.9 at no rank, 1.2 at legendary; slotless casters use the spell's own skill.
// CHARISMA_LATER: bards, sorcerers and warlocks should read a Charisma stat here once it exists.
/datum/action/cooldown/spell/proc/get_rank_multiplier()
	var/datum/spell_slots/slots = get_spell_slots()
	if(slots)
		return 0.9 + 0.05 * slots.get_rank()
	var/mob/living/caster = owner
	// Skill-less abilities, such as organ or racial spells, stay neutral.
	if(!istype(caster) || !associated_skill)
		return 1
	return 0.9 + 0.05 * clamp(round(caster.get_skill_level(associated_skill)), SKILL_RANK_NONE, SKILL_RANK_LEGENDARY)

/// Gear magnitude for the cast in progress, already capped.
/datum/action/cooldown/spell/proc/get_gear_multiplier()
	return clamp(spell_magnitude_modifier, 0.5, SPELLMOD_MAGNITUDE_CAP)

/// Cantrip and Minor scaling: x1 until journeyman, x1.5 until master, x2 after.
/datum/action/cooldown/spell/proc/get_cantrip_multiplier()
	var/datum/spell_slots/slots = get_spell_slots()
	var/rank = slots ? slots.get_rank() : 0
	if(rank >= SKILL_RANK_MASTER)
		return 2
	if(rank >= SKILL_RANK_JOURNEYMAN)
		return 1.5
	return 1

/datum/action/cooldown/spell/proc/slot_can_cast(feedback = TRUE)
	var/mob/living/caster = owner
	var/datum/spell_slots/slots = get_spell_slots()
	if(!istype(caster) || !slots)
		return FALSE
	if(cast_paid)
		return TRUE
	var/level = get_cast_level()
	if(level == SPELL_SLOT_MINOR)
		var/cost = get_minor_cost()
		if(slot_only || cost <= 0)
			if(feedback)
				to_chat(caster, span_warning("[get_slot_label()] requires a spell slot; it has no minor form."))
			return FALSE
		if(!caster.has_mana_available(cost))
			if(feedback)
				caster.balloon_alert(caster, "not enough mana for a minor cast!")
			return FALSE
		return TRUE
	if(level < slot_level)
		if(feedback)
			to_chat(caster, span_warning("[get_slot_label()] requires a level [slot_level] or higher slot."))
		return FALSE
	return slots.can_spend(level, feedback)

/// Pays once, after validation and before the effect. Cancelling earlier is free.
/datum/action/cooldown/spell/proc/pay_slot_cast()
	if(cast_paid || !slot_can_cast())
		return FALSE
	var/mob/living/caster = owner
	var/datum/spell_slots/slots = get_spell_slots()
	cast_slot_level = get_cast_level()
	// HUD and mana signals may ask whether this action is available during payment.
	cast_paid = TRUE
	if(cast_slot_level == SPELL_SLOT_MINOR)
		caster.consume_mana(get_minor_cost())
		caster.balloon_alert(caster, "[get_slot_label()]: minor")
		return TRUE
	if(!slots.spend(cast_slot_level))
		cast_paid = FALSE
		return FALSE
	caster.balloon_alert(caster, "[get_slot_label()]: level [cast_slot_level]")
	return TRUE

/datum/action/cooldown/spell/proc/clear_slot_cast()
	cast_slot_level = null
	cast_paid = FALSE

/// Ends this spell's concentration effect. Subtypes end their effect in on_concentration_broken.
/datum/action/cooldown/spell/proc/break_concentration(reason)
	get_spell_slots()?.clear_concentration(src)
	on_concentration_broken(reason)

/datum/action/cooldown/spell/proc/on_concentration_broken(reason)
	return
