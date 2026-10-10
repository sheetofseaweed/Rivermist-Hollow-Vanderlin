/datum/config_entry/flag/agent_npc_enabled

/datum/config_entry/string/agent_npc_url
	default = "http://127.0.0.1:1340/decide"

/datum/config_entry/string/agent_npc_url/ValidateAndSet(str_val)
	if(!findtext(str_val, GLOB.is_http_protocol))
		return FALSE
	return ..()

/// Requests allowed in flight across every agent NPC at once.
/datum/config_entry/number/agent_npc_max_concurrent
	default = 4
	min_val = 1
	max_val = 16

/// Token ceiling for the whole round. Zero means no ceiling.
/datum/config_entry/number/agent_npc_round_token_budget
	default = 0
	min_val = 0
