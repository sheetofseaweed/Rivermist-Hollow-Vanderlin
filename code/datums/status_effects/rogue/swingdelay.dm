// Non-blocking swing windup (TA port). The attack chain still sleeps for the
// windup, but this effect makes the windup *visible game state*: clicks are
// gated via is_swinging(), and disrupt-type swings can be cancelled by a hit.
/datum/status_effect/swingdelay
	id = "swingdelay"
	duration = 1 SECONDS
	alert_type = null
	status_type = STATUS_EFFECT_REPLACE

/datum/status_effect/swingdelay/on_apply()
	. = ..()
	owner.swing_state = TRUE

/datum/status_effect/swingdelay/penalty
	id = "swingdelay_penalty"

/datum/status_effect/swingdelay/disrupt
	id = "swingdelay_disrupt"
	var/is_disrupted = FALSE
	var/apply_slow = FALSE

/datum/status_effect/swingdelay/disrupt/on_creation(mob/living/new_owner, newdur, apply_slow = FALSE)
	src.apply_slow = apply_slow
	return ..()

/datum/status_effect/swingdelay/disrupt/on_apply()
	. = ..()
	if(apply_slow)
		owner.add_movespeed_modifier(MOVESPEED_ID_STATUS_EFFECT(id), multiplicative_slowdown = 2)

/datum/status_effect/swingdelay/disrupt/on_remove()
	. = ..()
	if(apply_slow)
		owner?.remove_movespeed_modifier(MOVESPEED_ID_STATUS_EFFECT(id))

/datum/status_effect/swingdelay/disrupt/proc/attacked()
	owner.swing_state = FALSE
	is_disrupted = TRUE
	owner.balloon_alert_to_viewers("<font color='#d07171'>interrupted!</font>", balloon_flag = DISABLE_BALLOON_COMBAT, y_offset = -8)

// ---- Swing state helpers (moved here from click.dm, natural home alongside the effects) ----

/mob/living/proc/add_swingdelay(datum/intent/swing_intent)
	if(!swing_intent?.swingdelay || !swing_intent.swingdelay_type)
		return FALSE
	var/delay = swing_intent.swingdelay + 2 // outlive the sleep by 2 ticks so the post-sleep disrupt check can read the effect
	switch(swing_intent.swingdelay_type)
		if(SWINGDELAY_NORMAL)
			apply_status_effect(/datum/status_effect/swingdelay, delay)
			return TRUE
		if(SWINGDELAY_PENALTY)
			apply_status_effect(/datum/status_effect/swingdelay/penalty, delay)
			return TRUE
		if(SWINGDELAY_CANCEL, SWINGDELAY_CANCELSLOW)
			apply_status_effect(/datum/status_effect/swingdelay/disrupt, delay, (swing_intent.swingdelay_type == SWINGDELAY_CANCELSLOW))
			return TRUE

/mob/living/proc/is_swinging(disrupt_only = FALSE)
	if(disrupt_only)
		return has_status_effect(/datum/status_effect/swingdelay/disrupt)
	return (has_status_effect(/datum/status_effect/swingdelay) || has_status_effect(/datum/status_effect/swingdelay/penalty) || has_status_effect(/datum/status_effect/swingdelay/disrupt))

/// Shared swing-windup wrapper: applies the windup status effect, sleeps the
/// intent's swingdelay, then reports whether the swing survived (FALSE = disrupted, abort the blow).
/mob/living/proc/do_swing_windup(datum/intent/swing_intent)
	if(swing_intent?.swingdelay)
		add_swingdelay(swing_intent)
		sleep(swing_intent.swingdelay)
	if(is_swinging() && !swing_state)
		return FALSE
	swing_state = FALSE
	return TRUE
