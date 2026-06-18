GLOBAL_LIST_EMPTY(player_dungeon_progress) // ckey -> /datum/dungeon_progress

/datum/dungeon_progress
	var/ckey
	var/datum/save_manager/save_manager
	/// Banked persistent currency
	var/echoes = 0
	/// assoc unlock id -> TRUE
	var/list/purchased_unlocks = list()
	/// assoc cosmetic id -> TRUE
	var/list/purchased_cosmetics = list()
	/// Currently selected title cosmetic id, or null
	var/selected_title
	/// Best floor ever reached
	var/deepest_floor = 0
	/// Lifetime boss kills
	var/bosses_killed = 0
	/// Lifetime completed runs (left safely from a break room)
	var/runs_completed = 0

/datum/dungeon_progress/New(target_ckey)
	if(!target_ckey)
		qdel(src)
		return
	ckey = ckey(target_ckey)
	save_manager = get_save_manager(ckey)
	if(!save_manager)
		qdel(src)
		return
	load_progress()

/datum/dungeon_progress/proc/load_progress()
	echoes = save_manager.get_data(DUNGEON_SAVE_FILE, "echoes", 0)
	purchased_unlocks = save_manager.get_data(DUNGEON_SAVE_FILE, "unlocks", list())
	purchased_cosmetics = save_manager.get_data(DUNGEON_SAVE_FILE, "cosmetics", list())
	selected_title = save_manager.get_data(DUNGEON_SAVE_FILE, "selected_title", null)
	deepest_floor = save_manager.get_data(DUNGEON_SAVE_FILE, "deepest_floor", 0)
	bosses_killed = save_manager.get_data(DUNGEON_SAVE_FILE, "bosses_killed", 0)
	runs_completed = save_manager.get_data(DUNGEON_SAVE_FILE, "runs_completed", 0)
	if(!islist(purchased_unlocks))
		purchased_unlocks = list()
	if(!islist(purchased_cosmetics))
		purchased_cosmetics = list()

/datum/dungeon_progress/proc/save_progress()
	save_manager.set_data(DUNGEON_SAVE_FILE, "echoes", echoes)
	save_manager.set_data(DUNGEON_SAVE_FILE, "unlocks", purchased_unlocks)
	save_manager.set_data(DUNGEON_SAVE_FILE, "cosmetics", purchased_cosmetics)
	save_manager.set_data(DUNGEON_SAVE_FILE, "selected_title", selected_title)
	save_manager.set_data(DUNGEON_SAVE_FILE, "deepest_floor", deepest_floor)
	save_manager.set_data(DUNGEON_SAVE_FILE, "bosses_killed", bosses_killed)
	save_manager.set_data(DUNGEON_SAVE_FILE, "runs_completed", runs_completed)

/datum/dungeon_progress/proc/add_echoes(amount)
	if(amount <= 0)
		return
	echoes += amount
	save_progress()

/datum/dungeon_progress/proc/spend_echoes(amount)
	if(amount <= 0 || echoes < amount)
		return FALSE
	echoes -= amount
	save_progress()
	return TRUE

/datum/dungeon_progress/proc/has_unlock(unlock_id)
	return !!purchased_unlocks[unlock_id]

/datum/dungeon_progress/proc/grant_unlock(unlock_id)
	purchased_unlocks[unlock_id] = TRUE
	save_progress()

/datum/dungeon_progress/proc/has_cosmetic(cosmetic_id)
	return !!purchased_cosmetics[cosmetic_id]

/datum/dungeon_progress/proc/grant_cosmetic(cosmetic_id)
	purchased_cosmetics[cosmetic_id] = TRUE
	save_progress()

/datum/dungeon_progress/proc/record_floor(floor)
	if(floor > deepest_floor)
		deepest_floor = floor
		save_progress()

/datum/dungeon_progress/proc/record_boss_kill()
	bosses_killed++
	save_progress()

/datum/dungeon_progress/proc/record_run_complete(floor, motes_banked)
	runs_completed++
	record_floor(floor)
	save_manager.add_to_list(DUNGEON_SAVE_FILE, "run_history", list("floor" = floor, "echoes" = motes_banked, "time" = world.realtime), 20)
	save_progress()

/proc/get_dungeon_progress(target_ckey)
	if(!target_ckey)
		return null
	target_ckey = ckey(target_ckey)
	if(target_ckey in GLOB.player_dungeon_progress)
		return GLOB.player_dungeon_progress[target_ckey]
	var/datum/dungeon_progress/progress = new(target_ckey)
	if(progress)
		GLOB.player_dungeon_progress[target_ckey] = progress
	return progress
