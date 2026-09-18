/datum/relic_effect/mad_god_dream
	active_duration = -1
	signal = TRUE

/datum/relic_effect/mad_god_dream/setup_signals()
	RegisterSignal(SSdcs, COMSIG_GLOB_PLANT_HARVESTED, PROC_REF(on_global_harvest))

/datum/relic_effect/mad_god_dream/remove_signals()
	UnregisterSignal(SSdcs, COMSIG_GLOB_PLANT_HARVESTED)

/datum/relic_effect/mad_god_dream/proc/on_global_harvest(datum/source, obj/structure/soil/soil, mob/living/user, atom/drop_location)
	SIGNAL_HANDLER
	if(QDELETED(user) || !drop_location)
		return

	if(prob(2))
		new /obj/item/ore/gold(drop_location)
		to_chat(user, span_purple("A shimmering nugget of raw gold tumbles from the roots as you harvest!"))
		stored_lookup?.play_relic_effects()
		return
	if(prob(4))
		new /obj/item/ore/silver(drop_location)
		to_chat(user, span_notice("A chunk of raw silver is unearthed amidst the harvest."))
		stored_lookup?.play_relic_effects()
		return
	if(prob(6))
		new /obj/item/ore/iron(drop_location)
		to_chat(user, span_notice("You find a piece of metallic bark resembling iron ore tangled in the crop."))
		stored_lookup?.play_relic_effects()
