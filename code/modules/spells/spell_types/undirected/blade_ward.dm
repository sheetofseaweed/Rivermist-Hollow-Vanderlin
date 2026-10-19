/datum/action/cooldown/spell/undirected/blade_ward
	name = "Blade Ward"
	desc = "Improves constitution for a brief duration."
	button_icon_state = "conjure_armor"

	point_cost = 1

	charge_required = FALSE
	cooldown_time = 1 MINUTES
	spell_cost = SPELL_CANTRIP_COST

	slot_level = 0
	required_form = FORM_ARCANE

	invocation = "Blades, be dulled!"
	invocation_type = INVOCATION_SHOUT
	spell_flags = SPELL_RITUOS

/datum/action/cooldown/spell/undirected/blade_ward/cast(atom/cast_on)
	. = ..()
	var/datum/status_effect/status = /datum/status_effect/buff/bladeward
	var/duration_increase = max(0, get_rank_multiplier() * 1.5 MINUTES)
	if(isliving(owner))
		var/mob/living/L = owner
		L.apply_status_effect(status, initial(status.duration) + duration_increase)
		L.visible_message(
			span_info("[L] traces a warding sigil in the air."),
			span_notice("I trace a sigil of warding in the air."),
		)

/datum/status_effect/buff/bladeward
	id = "blade ward"
	alert_type = /atom/movable/screen/alert/status_effect/buff/bladeward
	effectedstats = list(STAT_CONSTITUTION = 3)
	duration = 20 SECONDS
	var/static/mutable_appearance/ward = mutable_appearance('icons/effects/beam.dmi', "purple_lightning", -MUTATIONS_LAYER)

/atom/movable/screen/alert/status_effect/buff/bladeward
	name = "Blade Ward"
	desc = "I am resistant to damage."
	icon_state = "buff"

/datum/status_effect/buff/bladeward/on_apply()
	. = ..()
	var/mob/living/target = owner
	target.add_overlay(ward)

/datum/status_effect/buff/bladeward/on_remove()
	. = ..()
	var/mob/living/target = owner
	target.cut_overlay(ward)
