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

	/// Path of status effect to add
	var/datum/status_effect/status_effect = /datum/status_effect/buff/calm
	/// Duration of the status effect, null to use status effect duration
	var/duration = null
	/// If attunement strength scales the duration
	var/duration_scaling = FALSE
	/// Base duration increase, if null multiply duration by attuned strength
	var/duration_modification = 2 MINUTES
	/// Extra arguments to pass, must be a list
	/// Will have no effect unless on_creation has 3+ args
	var/extra_args
	/// Last target of a concentration cast, so a broken concentration can strip the effect.
	var/datum/weakref/concentration_target_ref

/datum/action/cooldown/spell/status/Destroy()
	concentration_target_ref = null
	return ..()

/// Breaking concentration removes the buff from the last target.
/datum/action/cooldown/spell/status/on_concentration_broken(reason)
	var/mob/living/target = concentration_target_ref?.resolve()
	concentration_target_ref = null
	if(QDELETED(target) || !target.has_status_effect(status_effect))
		return
	target.remove_status_effect(status_effect)
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
			new_duration += duration_modification * attuned_strength
		else
			new_duration *= attuned_strength
	var/list/status_args = list(
		status_effect,
		new_duration,
	)
	if(extra_args && islist(extra_args))
		status_args += extra_args
	if(concentration && uses_spell_slots())
		// A second concentration cast ends the first target's buff.
		on_concentration_broken(CONCENTRATION_REPLACED)
		concentration_target_ref = WEAKREF(cast_on)
	cast_on.apply_status_effect(arglist(status_args))
	cooldown_time = cooldown_time || duration
