/// Builds a relic component from trigger, effect, and information datum types.
/atom/proc/make_relic(trigger_type, effect_type, information_type = /datum/relic_information)
	if(!ispath(trigger_type, /datum/relic_trigger) || !ispath(effect_type, /datum/relic_effect) || !ispath(information_type, /datum/relic_information))
		return FALSE

	AddComponent(/datum/component/relic, new trigger_type, new effect_type, new information_type)
	return TRUE
