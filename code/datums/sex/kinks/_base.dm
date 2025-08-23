GLOBAL_LIST_INIT(available_kinks, generate_kink_list())

/datum/kink
	abstract_type = /datum/kink
	var/name = "Unknown Kink"
	var/description = "No description available."
	var/category = "General" // General, Domination, Submission, Roleplay, Fetish, etc.
	var/intensity = 1 // 1-5 scale
	var/enabled = TRUE
	var/notes = ""
	var/kink_flags = NONE

	var/list/tracked_mobs

/datum/kink/New(kink_name, kink_desc, kink_category = "General", kink_intensity = 1)
	if(kink_name)
		name = kink_name
	if(kink_desc)
		description = kink_desc
	if(kink_category)
		category = kink_category
	if(kink_intensity)
		intensity = clamp(kink_intensity, 1, 5)

	if(kink_flags & KINK_PROCESS)
		START_PROCESSING(SSobj, src)

/datum/kink/process()
	if(!length(tracked_mobs))
		return
	var/list/sexing_mobs = list()
	for(var/datum/sex_session/session in GLOB.sex_sessions)
		if(session.user in tracked_mobs)
			sexing_mobs |= session.user
		if(session.target in tracked_mobs)
			sexing_mobs |= session.target

	for(var/mob/living/mob in sexing_mobs)
		on_process(mob)

/datum/kink/proc/apply_kink(mob/target)
	return

/datum/kink/proc/on_process(mob/living/target)
	return

/proc/get_player_kinks(ckey, character_slot = 1)
	var/datum/save_manager/SM = get_save_manager(ckey)
	if(!SM)
		return list()

	var/save_name = "character_[character_slot]_kinks"
	return SM.get_data(save_name, "kinks", list())

/proc/set_player_kink(ckey, kink_name, enabled = TRUE, intensity = 3, notes = "", character_slot = 1)
	var/datum/save_manager/SM = get_save_manager(ckey)
	if(!SM)
		return FALSE

	var/save_name = "character_[character_slot]_kinks"
	var/list/kinks = SM.get_data(save_name, "kinks", list())

	if(!kinks[kink_name])
		kinks[kink_name] = list()

	kinks[kink_name]["enabled"] = enabled
	kinks[kink_name]["intensity"] = clamp(intensity, 1, 5)
	kinks[kink_name]["notes"] = notes

	return SM.set_data(save_name, "kinks", kinks)

/proc/generate_kink_list()
	var/list/kinks = list()
	for(var/datum/kink/kink as anything in subtypesof(/datum/kink))
		if(is_abstract(kink))
			continue
		kinks[initial(kink.name)] = new kink
	return kinks
