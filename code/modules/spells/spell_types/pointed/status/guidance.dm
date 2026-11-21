/datum/action/cooldown/spell/status/guidance
	name = "Arcane Guidance"
	desc = "Blesses your target with arcane luck, improving their ability in combat."
	button_icon_state = "guidance"
	sound = 'sound/magic/haste.ogg'

	point_cost = 2
	school = SCHOOL_TRANSMUTATION

	charge_time = 4 SECONDS
	charge_drain = 1
	charge_slowdown = 0.7
	cooldown_time = 5 MINUTES
	spell_cost = SPELL_CANTRIP_COST
	spell_flags = SPELL_RITUOS
	status_effect = /datum/status_effect/buff/guidance
	duration_scaling = TRUE
	duration_modification = 30 SECONDS

	// A cantrip again: reserve cost, no slot and no concentration seat.
	slot_level = 0
	slot_label = "Guidance"
	required_form = FORM_EARTH

/datum/action/cooldown/spell/status/guidance/cast(mob/living/cast_on)
	. = ..()
	if(cast_on != owner)
		owner.visible_message("[owner] mutters an incantation and [cast_on] briefly shines orange.")
	else
		owner.visible_message("[owner] mutters an incantation and they briefly shine orange.")

/datum/status_effect/buff/guidance
	id = "guidance"
	alert_type = /atom/movable/screen/alert/status_effect/buff/guidance
	duration = 1 MINUTES
	effectedstats = list(STAT_INTELLIGENCE = 2)
	var/static/mutable_appearance/guided = mutable_appearance('icons/effects/effects.dmi', "blessed")

/datum/status_effect/buff/guidance/on_apply()
	. = ..()
	var/mob/living/target = owner
	target.attributes?.add_diceroll_modifier(/datum/diceroll_modifier/guidance)
	target.add_overlay(guided)

/datum/status_effect/buff/guidance/on_remove()
	. = ..()
	var/mob/living/target = owner
	target.attributes?.remove_diceroll_modifier(/datum/diceroll_modifier/guidance)
	target.cut_overlay(guided)

/atom/movable/screen/alert/status_effect/buff/guidance
	name = "Guidance"
	desc = span_nicegreen("Arcane assistance guides my senses in combat.")
	icon_state = "buff"
