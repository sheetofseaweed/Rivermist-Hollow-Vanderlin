// Metamagic hooks: the armed option is read along the cast chain and paid once after the cast.

/datum/action/cooldown/spell
	/// Twinned can give this spell a free second cast on another target.
	var/twinnable = FALSE
	/// Extended can double this spell's duration.
	var/extendable = FALSE
	var/tmp/twin_free_until = 0
	var/tmp/datum/weakref/twin_first_target_ref
	var/tmp/twin_level
	var/tmp/twin_timer
	/// The cast in progress is the free twin cast.
	var/tmp/twin_cast_active = FALSE

/datum/action/cooldown/spell/proc/get_metamagic_cost(id)
	switch(id)
		if(METAMAGIC_QUICKENED)
			return METAMAGIC_QUICKENED_COST
		if(METAMAGIC_TWINNED)
			return max(1, isnull(cast_slot_level) ? (slot_level || 1) : cast_slot_level)
		if(METAMAGIC_EXTENDED)
			return METAMAGIC_EXTENDED_COST
		if(METAMAGIC_DISTANT)
			return METAMAGIC_DISTANT_COST
		if(METAMAGIC_SUBTLE)
			return METAMAGIC_SUBTLE_COST
	return 0

/// Whether a metamagic can shape this spell at all.
/datum/action/cooldown/spell/proc/metamagic_fits(id)
	switch(id)
		if(METAMAGIC_QUICKENED)
			return charge_required && charge_time > 0
		if(METAMAGIC_TWINNED)
			return twinnable && click_to_activate
		if(METAMAGIC_EXTENDED)
			return extendable
		if(METAMAGIC_DISTANT)
			return click_to_activate && cast_range > SPELL_RANGE_ADJACENT
		if(METAMAGIC_SUBTLE)
			return invocation_type != INVOCATION_NONE
	return FALSE

/// The armed metamagic applies when it fits this cast and the points cover it. The free twin cast carries none.
/datum/action/cooldown/spell/proc/metamagic_applies(id)
	if(is_free_cast())
		return FALSE
	var/datum/spell_slots/slots = get_spell_slots()
	if(!slots || slots.get_armed_metamagic() != id || !metamagic_fits(id))
		return FALSE
	return slots.get_feature_charges(FEATURE_SORCERY_POINTS) >= get_metamagic_cost(id)

/datum/action/cooldown/spell/proc/get_cast_range()
	return metamagic_applies(METAMAGIC_DISTANT) ? cast_range * 2 : cast_range

/datum/action/cooldown/spell/proc/get_metamagic_duration_multiplier()
	return metamagic_applies(METAMAGIC_EXTENDED) ? 2 : 1

/datum/action/cooldown/spell/proc/twin_cast_ready()
	return twin_free_until > world.time

/// Pays the armed metamagic after a successful cast. Returns TRUE when a twin window opened.
/datum/action/cooldown/spell/proc/finish_metamagic(atom/target)
	if(is_free_cast())
		return FALSE
	var/datum/spell_slots/slots = get_spell_slots()
	var/armed = slots?.get_armed_metamagic()
	if(!armed || !metamagic_fits(armed))
		return FALSE
	var/cost = get_metamagic_cost(armed)
	if(!slots.use_feature(FEATURE_SORCERY_POINTS, cost))
		owner.balloon_alert(owner, "not enough sorcery points for [armed]!")
		return FALSE
	slots.arm_metamagic(null)
	owner.balloon_alert(owner, "[armed] [name]: [cost] point[cost == 1 ? "" : "s"]")
	if(armed != METAMAGIC_TWINNED)
		return FALSE
	twin_free_until = world.time + TWINNED_CAST_WINDOW
	twin_first_target_ref = WEAKREF(target)
	twin_level = cast_slot_level
	twin_timer = addtimer(CALLBACK(src, PROC_REF(expire_twin)), TWINNED_CAST_WINDOW, TIMER_STOPPABLE | TIMER_UNIQUE | TIMER_OVERRIDE)
	to_chat(owner, span_notice("The twinned [name] lingers in my hands. I may cast it again at another target within ten seconds."))
	return TRUE

/// The window closed unused; the cooldown the twinned cast skipped starts now.
/datum/action/cooldown/spell/proc/expire_twin()
	if(!twin_free_until)
		return
	twin_free_until = 0
	twin_first_target_ref = null
	twin_level = null
	twin_timer = null
	StartCooldown()

/// Closes the window after the free cast; Activate then starts the normal cooldown.
/datum/action/cooldown/spell/proc/end_twin_cast()
	if(!twin_cast_active)
		return
	twin_cast_active = FALSE
	twin_free_until = 0
	twin_first_target_ref = null
	twin_level = null
	if(twin_timer)
		deltimer(twin_timer)
		twin_timer = null
