/**
 * A composable relic made from a trigger, an effect, and presentation information.
 *
 * The component owns all three datums passed to it and deletes them with itself.
 */
/datum/component/relic
	var/datum/relic_trigger/trigger
	var/datum/relic_effect/effect
	var/datum/relic_information/info
	/// Whether a signal-driven effect currently has its listeners registered.
	var/signal_effect_active = FALSE
	/// Prevents a one-shot relic from being activated again.
	var/has_fired = FALSE

/datum/component/relic/Initialize(datum/relic_trigger/relic_trigger, datum/relic_effect/relic_effect, datum/relic_information/relic_info)
	if(!isatom(parent) || !istype(relic_trigger) || !istype(relic_effect) || !istype(relic_info))
		return COMPONENT_INCOMPATIBLE

	trigger = relic_trigger
	effect = relic_effect
	info = relic_info
	trigger.stored_lookup = src
	effect.stored_lookup = src
	trigger.register_events(parent, src)
	info.register_information(parent)

/datum/component/relic/Destroy()
	deactivate_relic()
	if(trigger)
		if(parent)
			trigger.unregister_events(parent, src)
		trigger.stored_lookup = null
	if(effect)
		effect.stored_lookup = null
	QDEL_NULL(trigger)
	QDEL_NULL(effect)
	QDEL_NULL(info)
	return ..()

/// Activates this relic's effect, or refreshes it when its trigger permits that.
/datum/component/relic/proc/activate_relic()
	if(has_fired && trigger.one_shot)
		return

	if(effect.signal)
		if(!signal_effect_active)
			effect.setup_signals()
			signal_effect_active = TRUE
		return

	SSrelics.active_relics |= src
	if(trigger.duration_refreshing)
		effect.refresh()

/// Stops all processing and signal listeners belonging to this relic's effect.
/datum/component/relic/proc/deactivate_relic()
	SSrelics?.active_relics -= src
	if(signal_effect_active)
		effect?.remove_signals()
		signal_effect_active = FALSE

/datum/component/relic/proc/play_relic_trigger_effects()
	info?.play_relic_trigger_effects(parent)

/datum/component/relic/proc/play_relic_effects()
	info?.play_relic_effects(parent)

/**
 * Called by SSrelics while a periodic relic is active.
 *
 * Returns TRUE while the relic still needs processing.
 */
/datum/component/relic/proc/process_tick()
	if(QDELETED(parent) || QDELETED(trigger) || QDELETED(effect))
		return FALSE
	if(!trigger.should_fire(parent, info) && !effect.is_lingering)
		return FALSE

	effect.execute_effect(parent, info, src)

	if(trigger.one_shot)
		has_fired = TRUE
		trigger.unregister_events(parent, src)
		return FALSE

	return effect.is_lingering
