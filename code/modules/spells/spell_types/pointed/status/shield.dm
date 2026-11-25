// Shield: a reaction that raises a brief arcane ward.
/datum/action/cooldown/spell/status/shield
	name = "Shield"
	desc = "Raise a brief shimmering ward that helps you turn aside blows. Higher slots make it last longer."
	button_icon_state = "conjure_aegis"
	sound = 'sound/magic/holyshield.ogg'

	// A reaction fires on the button press and only ever wards the caster.
	click_to_activate = FALSE
	self_cast_possible = TRUE

	invocation_type = INVOCATION_NONE
	charge_required = FALSE
	cooldown_time = 30 SECONDS
	spell_cost = 20
	status_effect = /datum/status_effect/buff/arcane_shield

	slot_level = 1
	slot_only = TRUE
	reaction = TRUE
	slot_label = "Shield"
	required_form = FORM_ARCANE
	required_technique = TECHNIQUE_IMBUE
	required_level = MASTERY_RANK_NOVICE

/datum/action/cooldown/spell/status/shield/is_valid_target(atom/cast_on)
	return ..() && cast_on == owner

/datum/action/cooldown/spell/status/shield/cast(mob/living/cast_on)
	. = ..()
	cast_on.visible_message(
		span_notice("A shimmering ward flares up around [cast_on]!"),
		span_notice("A shimmering ward flares up around me!"),
	)

/datum/status_effect/buff/arcane_shield
	id = "arcane_shield"
	alert_type = /atom/movable/screen/alert/status_effect/buff/arcane_shield
	duration = 10 SECONDS
	tick_interval = STATUS_EFFECT_NO_TICK
	var/static/mutable_appearance/shimmer = mutable_appearance('icons/effects/effects.dmi', "shield-old", -HALO_LAYER)

/datum/status_effect/buff/arcane_shield/on_apply()
	. = ..()
	owner.attributes?.add_diceroll_modifier(/datum/diceroll_modifier/arcane_shield)
	owner.add_overlay(shimmer)

/datum/status_effect/buff/arcane_shield/on_remove()
	. = ..()
	owner.attributes?.remove_diceroll_modifier(/datum/diceroll_modifier/arcane_shield)
	owner.cut_overlay(shimmer)
	to_chat(owner, span_warning("My arcane ward fades."))

/// A recast keeps whichever ward lasts longer, so a weaker cast never shortens it.
/datum/status_effect/buff/arcane_shield/refresh(mob/living/new_owner, duration_override, ...)
	var/new_length = isnum(duration_override) ? duration_override : initial_duration
	duration = max(duration, world.time + new_length)

/atom/movable/screen/alert/status_effect/buff/arcane_shield
	name = "Shield"
	desc = span_nicegreen("A shimmering ward helps me turn aside blows.")
	icon_state = "buff"

/// Physical rolls of the warded caster, parries and dodges included, gain three points.
/datum/diceroll_modifier/arcane_shield
	modification = 3
	applicable_contexts = list(
		DICE_CONTEXT_PHYSICAL = TRUE,
	)
