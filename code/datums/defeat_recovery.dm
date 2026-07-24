/// Data contract for one way of returning from Defeat. Profiles decide whether a recovery may start,
/// how long it takes, and what it costs; they never perform the wake-up cleanup themselves.
/datum/defeat_recovery_profile
	var/profile_id = "recovery"
	var/requires_helper = FALSE
	var/requires_adjacent_helper = FALSE
	var/helper_stamina_cost = 0
	var/aftermath_severity = DEFEAT_SEVERITY_NORMAL
	var/apply_snapshot_aftermath = TRUE
	var/additional_aftermath_type
	var/additional_aftermath_severity = DEFEAT_SEVERITY_NORMAL
	/// Passive sources use a stoppable channel-owned timer instead of requiring an incapacitated
	/// victim to perform a normal do_after interaction.
	var/uses_passive_timer = FALSE

/datum/defeat_recovery_profile/proc/can_recover(datum/defeat_recovery_channel/channel)
	var/mob/living/victim = channel.resolve_victim()
	if(!victim || victim.stat == DEAD)
		return FALSE
	if(!victim.has_status_effect(/datum/status_effect/defeat_knockout))
		return FALSE

	var/mob/living/helper = channel.resolve_helper()
	if(requires_helper && !helper)
		return FALSE
	if(helper)
		if(helper == victim || helper.stat == DEAD)
			return FALSE
		if(requires_adjacent_helper && !victim.defeat_can_be_rescued_by(helper))
			return FALSE
	if(channel.had_source && !channel.resolve_source())
		return FALSE
	return TRUE

/datum/defeat_recovery_profile/proc/recovery_time(datum/defeat_recovery_channel/channel)
	return 0

/// Reservation and consumption are hooks for prepared sources with bespoke inventories. Existing
/// medical actions already reserve their tool/reagent during their own completed interaction.
/datum/defeat_recovery_profile/proc/reserve_resources(datum/defeat_recovery_channel/channel)
	return TRUE

/datum/defeat_recovery_profile/proc/consume_resources(datum/defeat_recovery_channel/channel)
	return TRUE

/// Undo a reservation which never reached successful consumption.
/datum/defeat_recovery_profile/proc/release_resources(datum/defeat_recovery_channel/channel)
	return TRUE

/datum/defeat_recovery_profile/proc/apply_aftermath(datum/defeat_recovery_channel/channel)
	var/mob/living/victim = channel.resolve_victim()
	if(!victim)
		return FALSE
	if(apply_snapshot_aftermath)
		victim.apply_defeat_snapshot_debuffs(aftermath_severity)
	if(additional_aftermath_type)
		victim.apply_defeat_trauma_status(additional_aftermath_type, additional_aftermath_severity)
	return TRUE

/datum/defeat_recovery_profile/proc/apply_helper_cost(datum/defeat_recovery_channel/channel)
	if(helper_stamina_cost <= 0)
		return
	var/mob/living/helper = channel.resolve_helper()
	helper?.adjust_stamina(helper_stamina_cost)

/datum/defeat_recovery_profile/proc/on_channel_started(datum/defeat_recovery_channel/channel)
	return

/datum/defeat_recovery_profile/proc/on_channel_finished(datum/defeat_recovery_channel/channel)
	return

/datum/defeat_recovery_profile/manual
	profile_id = DEFEAT_RECOVERY_MANUAL
	requires_helper = TRUE
	requires_adjacent_helper = TRUE
	helper_stamina_cost = DEFEAT_MANUAL_HELPER_STAMINA_COST
	aftermath_severity = DEFEAT_SEVERITY_SEVERE

/datum/defeat_recovery_profile/manual/recovery_time(datum/defeat_recovery_channel/channel)
	var/mob/living/helper = channel.resolve_helper()
	return helper?.defeat_revive_time() || DEFEAT_REVIVE_TIME_MAX

/datum/defeat_recovery_profile/prepared
	profile_id = DEFEAT_RECOVERY_PREPARED
	requires_helper = TRUE
	aftermath_severity = DEFEAT_SEVERITY_NORMAL

/datum/defeat_recovery_profile/campfire
	profile_id = DEFEAT_RECOVERY_CAMPFIRE
	aftermath_severity = DEFEAT_SEVERITY_NORMAL
	uses_passive_timer = TRUE

/datum/defeat_recovery_profile/campfire/can_recover(datum/defeat_recovery_channel/channel)
	if(!..())
		return FALSE
	var/obj/machinery/light/fueled/campfire/campfire = channel.resolve_source()
	var/mob/living/victim = channel.resolve_victim()
	if(!istype(campfire) || !campfire.player_built || !campfire.on || campfire.fueluse <= 0)
		return FALSE
	if(!victim.Adjacent(campfire))
		return FALSE
	var/mob/living/helper = channel.resolve_helper()
	if(helper && (!helper.Adjacent(campfire) || !helper.Adjacent(victim)))
		return FALSE
	return TRUE

/datum/defeat_recovery_profile/campfire/recovery_time(datum/defeat_recovery_channel/channel)
	return DEFEAT_CAMPFIRE_PASSIVE_RECOVERY_TIME

/datum/defeat_recovery_profile/campfire/on_channel_started(datum/defeat_recovery_channel/channel)
	var/obj/machinery/light/fueled/campfire/campfire = channel.resolve_source()
	campfire?.register_defeat_recovery_channel(channel)

/datum/defeat_recovery_profile/campfire/on_channel_finished(datum/defeat_recovery_channel/channel)
	var/obj/machinery/light/fueled/campfire/campfire = channel.resolve_source()
	campfire?.unregister_defeat_recovery_channel(channel)

/datum/defeat_recovery_profile/campfire/tended
	requires_helper = TRUE
	requires_adjacent_helper = TRUE
	uses_passive_timer = FALSE

/datum/defeat_recovery_profile/campfire/tended/recovery_time(datum/defeat_recovery_channel/channel)
	return DEFEAT_CAMPFIRE_TENDED_RECOVERY_TIME

/datum/defeat_recovery_profile/self_recovery
	profile_id = DEFEAT_RECOVERY_SELF
	aftermath_severity = DEFEAT_SEVERITY_NORMAL

/datum/defeat_recovery_profile/self_recovery/ko_only
	additional_aftermath_type = /datum/status_effect/debuff/defeat/grievous
	additional_aftermath_severity = DEFEAT_SEVERITY_SEVERE

/datum/defeat_recovery_profile/environmental
	profile_id = DEFEAT_RECOVERY_ENVIRONMENTAL
	aftermath_severity = DEFEAT_SEVERITY_NORMAL

/datum/defeat_recovery_profile/rune
	profile_id = DEFEAT_RECOVERY_RUNE
	aftermath_severity = DEFEAT_SEVERITY_NORMAL
	additional_aftermath_type = /datum/status_effect/debuff/defeat/rune

/// One in-progress recovery. All non-owned participants are weak references; the victim owns the
/// channel through defeat_recovery_channel and clears it when this datum is destroyed.
/datum/defeat_recovery_channel
	var/datum/defeat_recovery_profile/profile
	var/datum/weakref/victim_ref
	var/datum/weakref/helper_ref
	var/datum/weakref/source_ref
	var/had_source = FALSE
	var/rescue_source = "recovery"
	var/active = FALSE
	var/resources_reserved = FALSE
	var/resources_consumed = FALSE
	var/interrupt_signals_registered = FALSE
	var/channel_started = FALSE
	var/passive_completion_timer
	var/victim_relay_attached = FALSE
	var/helper_relay_attached = FALSE

/datum/defeat_recovery_channel/New(datum/defeat_recovery_profile/profile, mob/living/victim, mob/living/helper, rescue_source, datum/source)
	. = ..()
	src.profile = profile
	victim_ref = WEAKREF(victim)
	if(helper)
		helper_ref = WEAKREF(helper)
	if(source)
		had_source = TRUE
		source_ref = WEAKREF(source)
	if(rescue_source)
		src.rescue_source = rescue_source

/datum/defeat_recovery_channel/Destroy()
	deltimer(passive_completion_timer)
	passive_completion_timer = null
	if(channel_started)
		profile?.on_channel_finished(src)
		channel_started = FALSE
	release_reserved_resources()
	unregister_interrupt_signals()
	var/mob/living/victim = resolve_victim()
	if(victim?.defeat_recovery_channel == src)
		victim.defeat_recovery_channel = null
	QDEL_NULL(profile)
	victim_ref = null
	helper_ref = null
	source_ref = null
	return ..()

/datum/defeat_recovery_channel/proc/resolve_victim()
	var/mob/living/victim = victim_ref?.resolve()
	if(QDELETED(victim))
		return null
	return victim

/datum/defeat_recovery_channel/proc/resolve_helper()
	var/mob/living/helper = helper_ref?.resolve()
	if(QDELETED(helper))
		return null
	return helper

/datum/defeat_recovery_channel/proc/resolve_source()
	var/datum/source = source_ref?.resolve()
	if(QDELETED(source))
		return null
	return source

/datum/defeat_recovery_channel/proc/is_valid()
	return active && profile?.can_recover(src)

/datum/defeat_recovery_channel/proc/cancel()
	if(!active)
		return FALSE
	var/was_passive = profile?.uses_passive_timer
	active = FALSE
	deltimer(passive_completion_timer)
	passive_completion_timer = null
	unregister_interrupt_signals()
	release_reserved_resources()
	var/mob/living/performer = resolve_helper() || resolve_victim()
	performer?.stop_doing(DEFEAT_RECOVERY_INTERACTION_KEY)
	if(was_passive)
		qdel(src)
	return TRUE

/datum/defeat_recovery_channel/proc/release_reserved_resources()
	if(!resources_reserved || resources_consumed)
		return FALSE
	profile?.release_resources(src)
	resources_reserved = FALSE
	return TRUE

/datum/defeat_recovery_channel/proc/register_interrupt_signals()
	if(interrupt_signals_registered)
		return
	var/mob/living/victim = resolve_victim()
	var/mob/living/helper = resolve_helper()
	if(victim)
		if(!HAS_TRAIT(victim, TRAIT_RELAYING_ATTACKER))
			victim.AddElement(/datum/element/relay_attackers)
			victim_relay_attached = TRUE
		RegisterSignal(victim, COMSIG_ATOM_WAS_ATTACKED, PROC_REF(on_participant_attacked))
		RegisterSignal(victim, COMSIG_MOVABLE_MOVED, PROC_REF(on_participant_moved))
		RegisterSignal(victim, COMSIG_PARENT_QDELETING, PROC_REF(on_participant_deleted))
	if(helper)
		if(!HAS_TRAIT(helper, TRAIT_RELAYING_ATTACKER))
			helper.AddElement(/datum/element/relay_attackers)
			helper_relay_attached = TRUE
		RegisterSignal(helper, COMSIG_ATOM_WAS_ATTACKED, PROC_REF(on_participant_attacked))
		RegisterSignal(helper, COMSIG_MOVABLE_MOVED, PROC_REF(on_participant_moved))
		RegisterSignal(helper, COMSIG_PARENT_QDELETING, PROC_REF(on_participant_deleted))
	var/datum/source = resolve_source()
	if(source)
		RegisterSignal(source, COMSIG_PARENT_QDELETING, PROC_REF(on_participant_deleted))
		if(ismovable(source))
			RegisterSignal(source, COMSIG_MOVABLE_MOVED, PROC_REF(on_participant_moved))
	interrupt_signals_registered = TRUE

/datum/defeat_recovery_channel/proc/unregister_interrupt_signals()
	if(!interrupt_signals_registered)
		return
	var/mob/living/victim = resolve_victim()
	var/mob/living/helper = resolve_helper()
	if(victim)
		UnregisterSignal(victim, list(COMSIG_ATOM_WAS_ATTACKED, COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING))
		if(victim_relay_attached)
			victim.RemoveElement(/datum/element/relay_attackers)
	if(helper)
		UnregisterSignal(helper, list(COMSIG_ATOM_WAS_ATTACKED, COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING))
		if(helper_relay_attached)
			helper.RemoveElement(/datum/element/relay_attackers)
	victim_relay_attached = FALSE
	helper_relay_attached = FALSE
	var/datum/source = resolve_source()
	if(source)
		UnregisterSignal(source, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING))
	interrupt_signals_registered = FALSE

/datum/defeat_recovery_channel/proc/on_participant_attacked(datum/source, atom/attacker, damage)
	SIGNAL_HANDLER
	if(damage)
		cancel()

/datum/defeat_recovery_channel/proc/on_participant_moved(datum/source)
	SIGNAL_HANDLER
	cancel()

/datum/defeat_recovery_channel/proc/on_participant_deleted(datum/source)
	SIGNAL_HANDLER
	cancel()

/datum/defeat_recovery_channel/proc/execute()
	if(active || !profile?.can_recover(src))
		return FALSE
	if(!profile.reserve_resources(src))
		return FALSE
	resources_reserved = TRUE
	active = TRUE
	channel_started = TRUE
	profile.on_channel_started(src)

	var/recovery_time = profile.recovery_time(src)
	if(recovery_time > 0)
		register_interrupt_signals()
		if(profile.uses_passive_timer)
			passive_completion_timer = addtimer(CALLBACK(src, PROC_REF(complete_passive_recovery)), recovery_time, TIMER_STOPPABLE)
			return TRUE
		var/mob/living/performer = resolve_helper() || resolve_victim()
		var/mob/living/victim = resolve_victim()
		if(!performer || !victim || !do_after(
			performer,
			recovery_time,
			target = victim,
			extra_checks = CALLBACK(src, PROC_REF(is_valid)),
			interaction_key = DEFEAT_RECOVERY_INTERACTION_KEY,
		))
			active = FALSE
			unregister_interrupt_signals()
			release_reserved_resources()
			return FALSE
		unregister_interrupt_signals()

	if(!is_valid())
		active = FALSE
		release_reserved_resources()
		return FALSE
	var/mob/living/victim = resolve_victim()
	return victim?.complete_defeat_recovery(src)

/datum/defeat_recovery_channel/proc/complete_passive_recovery()
	passive_completion_timer = null
	if(!is_valid())
		cancel()
		qdel(src)
		return
	var/mob/living/victim = resolve_victim()
	victim?.complete_defeat_recovery(src)
	qdel(src)
