// Mage Armor: an hour-long arcane ward.
/datum/action/cooldown/spell/status/mage_armor
	name = "Mage Armor"
	desc = "Wrap yourself in a faint arcyne ward for 60 minutes: +1 on physical rolls, parries and dodges included. It works alongside Shield. Each slot level above the first lengthens it by half."
	button_icon_state = "stoneskin"
	sound = 'sound/magic/crystal.ogg'

	// The ward only ever settles on the caster.
	click_to_activate = FALSE
	self_cast_possible = TRUE

	invocation = "Weave, ward me."
	invocation_type = INVOCATION_WHISPER
	charge_required = FALSE
	cooldown_time = 60 SECONDS
	spell_cost = 30
	status_effect = /datum/status_effect/buff/mage_armor

	slot_level = 1
	slot_only = TRUE
	slot_label = "Mage Armor"
	required_form = FORM_ARCANE
	required_technique = TECHNIQUE_IMBUE
	required_level = MASTERY_RANK_NOVICE
	learnable = TRUE

/datum/action/cooldown/spell/status/mage_armor/is_valid_target(atom/cast_on)
	return ..() && cast_on == owner

/datum/action/cooldown/spell/status/mage_armor/cast(mob/living/cast_on)
	. = ..()
	cast_on.visible_message(
		span_notice("A faint arcyne sheen settles over [cast_on]."),
		span_notice("A faint arcyne ward settles over me."),
	)

/datum/status_effect/buff/mage_armor
	id = "mage_armor"
	alert_type = /atom/movable/screen/alert/status_effect/buff/mage_armor
	duration = 60 MINUTES
	tick_interval = STATUS_EFFECT_NO_TICK
	var/static/mutable_appearance/ward = mutable_appearance('icons/effects/effects.dmi', "shield-grey", -HALO_LAYER, alpha = 70)

/datum/status_effect/buff/mage_armor/on_apply()
	. = ..()
	owner.attributes?.add_diceroll_modifier(/datum/diceroll_modifier/mage_armor)
	owner.add_overlay(ward)

/datum/status_effect/buff/mage_armor/on_remove()
	. = ..()
	owner.attributes?.remove_diceroll_modifier(/datum/diceroll_modifier/mage_armor)
	owner.cut_overlay(ward)
	to_chat(owner, span_warning("My mage armor fades."))

/// A recast keeps whichever ward lasts longer, so a weaker cast never shortens it.
/datum/status_effect/buff/mage_armor/refresh(mob/living/new_owner, duration_override, ...)
	var/new_length = isnum(duration_override) ? duration_override : initial_duration
	duration = max(duration, world.time + new_length)

/atom/movable/screen/alert/status_effect/buff/mage_armor
	name = "Mage Armor"
	desc = span_nicegreen("A faint arcyne ward turns aside glancing blows.")
	icon_state = "buff"

/// Physical rolls of the warded caster, parries and dodges included, gain one point.
/datum/diceroll_modifier/mage_armor
	modification = 1
	applicable_contexts = list(
		DICE_CONTEXT_PHYSICAL = TRUE,
	)
