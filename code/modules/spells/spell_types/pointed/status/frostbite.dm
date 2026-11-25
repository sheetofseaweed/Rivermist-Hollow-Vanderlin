/datum/action/cooldown/spell/status/frostbite
	name = "Frostbite"
	desc = "Freeze your enemy with an icy blast that does low damage, but reduces the target's Speed for a considerable length of time."
	button_icon_state = "frostbite"
	self_cast_possible = FALSE

	sound = 'sound/magic/whiteflame.ogg'
	point_cost = 1

	invocation = "Bite of Frost!!"
	invocation_type = INVOCATION_SHOUT

	charge_time = 3 SECONDS
	charge_drain = 1
	cooldown_time = 25 SECONDS
	spell_cost = 50
	spell_flags = SPELL_RITUOS
	status_effect = /datum/status_effect/debuff/frostbite

	slot_level = 1
	slot_only = TRUE
	slot_label = "Frostbite"
	required_form = FORM_ICE
	required_technique = TECHNIQUE_ALTERATION

/datum/action/cooldown/spell/status/frostbite/cast(mob/living/cast_on)
	// The parent applies the status, so its strength must be set first.
	// Half a point of strength costs one more Speed; upcasts add it every two levels.
	extra_args = list(get_rank_multiplier() + 0.5 * round(get_upcast_steps() / 2))
	. = ..()
	if(iscarbon(cast_on))
		var/mob/living/carbon/C = cast_on
		C.adjustFireLoss(15 * get_rank_multiplier() * get_upcast_multiplier())
