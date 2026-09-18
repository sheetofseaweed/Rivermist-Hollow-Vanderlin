SUBSYSTEM_DEF(relics)
	name = "Relics"
	flags = SS_NO_INIT | SS_BACKGROUND
	wait = 0.5 SECONDS
	/// Relics which currently need periodic processing.
	var/list/datum/component/relic/active_relics = list()
	var/list/datum/component/relic/currentrun = list()

/datum/controller/subsystem/relics/fire(resumed = FALSE)
	if(!resumed)
		currentrun = active_relics.Copy()

	while(length(currentrun))
		var/datum/component/relic/relic = currentrun[currentrun.len]
		currentrun.len--
		if(QDELETED(relic) || !relic.process_tick())
			active_relics -= relic
		if(MC_TICK_CHECK)
			return
