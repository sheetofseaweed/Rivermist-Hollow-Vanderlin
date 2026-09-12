/datum/relic_trigger/secure
	var/secure_id = SECURE_SPOT_CHURCH
	var/is_active = FALSE

/datum/relic_trigger/secure/register_events(atom/parent_atom, datum/component/relic/relic_comp)
	RegisterSignal(parent_atom, COMSIG_SECURE_SPOT_ACTIVATED, PROC_REF(handle_spot_activation))
	RegisterSignal(parent_atom, COMSIG_SECURE_SPOT_DEACTIVATED, PROC_REF(handle_spot_deactivation))

/datum/relic_trigger/secure/unregister_events(atom/parent_atom, datum/component/relic/relic_comp)
	UnregisterSignal(parent_atom, list(COMSIG_SECURE_SPOT_ACTIVATED, COMSIG_SECURE_SPOT_DEACTIVATED))
	is_active = FALSE

/datum/relic_trigger/secure/proc/handle_spot_activation(atom/source, activated_secure_id)
	SIGNAL_HANDLER
	if(activated_secure_id != secure_id)
		return
	is_active = TRUE
	fire_trigger()

/datum/relic_trigger/secure/proc/handle_spot_deactivation(atom/source, deactivated_secure_id)
	SIGNAL_HANDLER
	if(deactivated_secure_id != secure_id)
		return
	is_active = FALSE
	stored_lookup?.deactivate_relic()

/datum/relic_trigger/secure/should_fire(atom/parent_atom, datum/relic_information/info)
	return is_active
