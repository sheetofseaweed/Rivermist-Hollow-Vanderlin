/**
 * ## Status effect spells
 *
 * Spells that grant a status effect to a living mob.
 *
 * Always applies the effect onto cast_on but extra target handling can extend cast.
 *
 * Set cooldown_time to 0 to inherit the duration
 */
/datum/action/cooldown/spell/status
	self_cast_possible = TRUE
	twinnable = TRUE
	extendable = TRUE

	/// Path of status effect to add
	var/datum/status_effect/status_effect = /datum/status_effect/buff/calm
	/// Duration of the status effect, null to use status effect duration
	var/duration = null
	/// If the caster's rank multiplier scales the duration
	var/duration_scaling = FALSE
	/// Base duration increase, if null multiply duration by the rank multiplier
	var/duration_modification = 2 MINUTES
	/// Extra arguments to pass, must be a list
	/// Will have no effect unless on_creation has 3+ args
	var/extra_args
	/// Last target of a concentration cast, so a broken concentration can strip the effect.
	var/datum/weakref/concentration_target_ref
	/// The effect instance that cast applied; a break removes only this one.
	var/datum/weakref/concentration_effect_ref

/datum/action/cooldown/spell/status/Destroy()
	concentration_target_ref = null
	concentration_effect_ref = null
	return ..()

/// Breaking concentration removes the buff this spell applied, never another caster's copy.
/datum/action/cooldown/spell/status/on_concentration_broken(reason)
	var/datum/status_effect/sustained = concentration_effect_ref?.resolve()
	concentration_target_ref = null
	concentration_effect_ref = null
	if(QDELETED(sustained) || !sustained.before_remove())
		return
	var/mob/living/target = sustained.owner
	qdel(sustained)
	target.visible_message(span_warning("The magic sustaining [target] unravels."), span_warning("The [name] sustaining me unravels!"))

/datum/action/cooldown/spell/status/New(Target)
	. = ..()
	if(!status_effect)
		stack_trace("Status spell [type] created without status effect.")
		qdel(src)

/datum/action/cooldown/spell/status/is_valid_target(atom/cast_on)
	. = ..()
	if(!.)
		return
	return isliving(cast_on)

/datum/action/cooldown/spell/status/cast(mob/living/cast_on)
	. = ..()
	var/new_duration = duration ? duration : initial(status_effect.duration)
	if(duration_scaling)
		if(duration_modification)
			new_duration += duration_modification * get_rank_multiplier()
		else
			new_duration *= get_rank_multiplier()
	new_duration *= get_metamagic_duration_multiplier() * get_upcast_duration_multiplier()
	var/list/status_args = list(
		status_effect,
		new_duration,
	)
	if(extra_args && islist(extra_args))
		status_args += extra_args
	var/holds_concentration = concentration && uses_spell_slots()
	if(holds_concentration)
		// A second concentration cast ends the first target's buff.
		on_concentration_broken(CONCENTRATION_REPLACED)
		concentration_target_ref = WEAKREF(cast_on)
	var/datum/status_effect/applied = cast_on.apply_status_effect(arglist(status_args))
	// A cast that only refreshed someone else's copy owns nothing, so it holds no seat.
	if(holds_concentration)
		track_concentration_effect(applied)
	cooldown_time = cooldown_time || duration

/datum/action/cooldown/spell/status/after_cast(atom/cast_on)
	. = ..()
	// Activate seats concentration after the cast; a hold that slid off a ward keeps no seat.
	if(concentration && !concentration_target_ref)
		get_spell_slots()?.clear_concentration(src)

/// Watches the sustained effect so its end frees the seat; an effect that never took holds nothing.
/datum/action/cooldown/spell/status/proc/track_concentration_effect(datum/status_effect/effect)
	if(QDELETED(effect))
		concentration_target_ref = null
		concentration_effect_ref = null
		return
	concentration_effect_ref = WEAKREF(effect)
	RegisterSignal(effect, COMSIG_PARENT_QDELETING, PROC_REF(on_concentration_effect_deleted), override = TRUE)

/// The effect ended on its own, such as expiry or a shaken-off hold, so the caster's seat is free.
/datum/action/cooldown/spell/status/proc/on_concentration_effect_deleted(datum/status_effect/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, COMSIG_PARENT_QDELETING)
	// A recast or a broken concentration has already let this effect go.
	if(!concentration_effect_ref || source.weak_reference != concentration_effect_ref)
		return
	concentration_target_ref = null
	concentration_effect_ref = null
	get_spell_slots()?.clear_concentration(src)
