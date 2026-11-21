// Slow: the counter to Haste.
/datum/action/cooldown/spell/status/slow
	name = "Slow"
	desc = "Drag a target through thickened time for 45 seconds: -3 Speed and a heavy drag on every step, and any Haste on them ends. Each slot level above the third lengthens it by half. Needs concentration."
	button_icon_state = "temporis"
	sound = 'sound/magic/debuffroll.ogg'
	self_cast_possible = FALSE
	// One concentration target per caster, so a twinned cast would end the first Slow.
	twinnable = FALSE

	invocation = "Lethargy take thee!"
	invocation_type = INVOCATION_SHOUT

	charge_time = 1.5 SECONDS
	charge_slowdown = 0.3
	cooldown_time = 45 SECONDS
	spell_cost = 50
	status_effect = /datum/status_effect/debuff/slowed

	slot_level = 3
	slot_only = TRUE
	concentration = TRUE
	slot_label = "Slow"
	required_form = FORM_EARTH
	required_technique = TECHNIQUE_ALTERATION
	required_level = MASTERY_RANK_EXPERT
	learnable = TRUE

/datum/action/cooldown/spell/status/slow/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	// Refusing here spends neither the slot nor the cooldown.
	if(!can_see(owner, cast_on, get_cast_range()))
		owner.balloon_alert(owner, "can't see them!")
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/status/slow/cast(mob/living/cast_on)
	// Slow checks antimagic as it lands, so the flags ride along with the status.
	extra_args = list(antimagic_flags)
	return ..()

/datum/status_effect/debuff/slowed
	id = "slowed"
	alert_type = /atom/movable/screen/alert/status_effect/debuff/slowed
	duration = 45 SECONDS
	tick_interval = STATUS_EFFECT_NO_TICK
	effectedstats = list(STAT_SPEED = -3)
	examine_text = span_warning("SUBJECTPRONOUN is moving as if through deep water.")
	/// Added to the move delay on top of the lost Speed; roughly halves a running pace.
	var/slowdown = 1.5

/datum/status_effect/debuff/slowed/on_creation(mob/living/new_owner, duration_override, antimagic_flags = NONE)
	// A warded target shrugs Slow off before it takes; the cast stays paid.
	if(antimagic_flags && new_owner?.can_block_magic(antimagic_flags))
		new_owner.visible_message(span_warning("The sluggish haze slides off [new_owner]!"), span_warning("Time thickens around me, then lets go."))
		playsound(new_owner, 'sound/magic/magic_nulled.ogg', 100)
		qdel(src)
		return FALSE
	return ..()

/datum/status_effect/debuff/slowed/on_apply()
	. = ..()
	// Haste only adds Speed, so Slow simply ends it.
	owner.remove_status_effect(/datum/status_effect/buff/haste)
	owner.add_movespeed_modifier(MOVESPEED_ID_STATUS_EFFECT(id), multiplicative_slowdown = slowdown)
	// The Speed stat only reaches the move delay when the delay is recomputed.
	owner.update_move_intent_slowdown()
	owner.visible_message(span_danger("[owner] slows, as if wading through deep water!"), span_userdanger("Time thickens around my limbs!"))

/datum/status_effect/debuff/slowed/on_remove()
	. = ..()
	if(QDELETED(owner))
		return
	owner.remove_movespeed_modifier(MOVESPEED_ID_STATUS_EFFECT(id))
	owner.update_move_intent_slowdown()
	to_chat(owner, span_notice("Time loosens its grip on my limbs."))

/atom/movable/screen/alert/status_effect/debuff/slowed
	name = "Slowed"
	desc = "Time drags at my limbs."
	icon_state = "debuff"
