/datum/relic_effect
	VAR_PRIVATE/duration = 0
	/// Number of subsystem ticks the effect remains active. -1 lasts until deactivated.
	var/active_duration = 1
	var/is_lingering = TRUE
	/// Signal-driven effects listen for events instead of entering SSrelics.
	var/signal = FALSE
	var/datum/component/relic/stored_lookup

/datum/relic_effect/New()
	. = ..()
	duration = active_duration

/datum/relic_effect/proc/setup_signals()
	return

/datum/relic_effect/proc/remove_signals()
	return

/datum/relic_effect/proc/refresh()
	SHOULD_CALL_PARENT(TRUE)
	duration = active_duration
	is_lingering = TRUE

/datum/relic_effect/proc/execute_effect(atom/parent_atom, datum/relic_information/info, datum/component/relic/relic_comp)
	SHOULD_CALL_PARENT(TRUE)
	stored_lookup?.play_relic_effects()
	if(active_duration == -1)
		is_lingering = TRUE
		return

	duration--
	if(duration <= 0)
		duration = active_duration
		is_lingering = FALSE
