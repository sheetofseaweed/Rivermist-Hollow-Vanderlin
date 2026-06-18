/client/proc/dungeon_run_debug()
	set name = "Dungeon Run Debug"
	set category = "Debug.Dungeon"
	if(!check_rights(R_DEBUG))
		return
	var/list/runs = list()
	for(var/datum/dungeon_run/run in get_active_dungeon_runs())
		runs["floor [run.floor] | motes [run.motes] | rooms [length(run.get_all_rooms())] | [REF(run)]"] = run
	if(!length(runs))
		to_chat(usr, "No active dungeon runs.")
		return
	var/picked = input(usr, "Active runs:", "Dungeon Debug") as null|anything in runs
	var/datum/dungeon_run/chosen = runs[picked]
	if(!chosen)
		return
	var/action = input(usr, "Action on floor [chosen.floor] run:", "Dungeon Debug") as null|anything in list("Grant 500 motes", "Force end run", "Advance floor (debug)")
	switch(action)
		if("Grant 500 motes")
			chosen.award_motes(500, null)
		if("Force end run")
			qdel(chosen)
		if("Advance floor (debug)")
			chosen.floor++
			chosen.floor_config = get_dungeon_floor_config(chosen.floor)
			to_chat(usr, "Run advanced to floor [chosen.floor].")
