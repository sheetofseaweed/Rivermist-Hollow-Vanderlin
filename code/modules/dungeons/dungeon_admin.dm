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

/client/proc/dungeon_meta_debug()
	set name = "Dungeon Meta Debug"
	set category = "Debug.Dungeon"
	if(!check_rights(R_DEBUG))
		return
	var/list/targets = list()
	for(var/client/candidate as anything in GLOB.clients)
		if(candidate.ckey)
			targets["[candidate.ckey]"] = candidate.ckey
	if(!length(targets))
		to_chat(usr, "No connected clients to edit.")
		return
	var/picked_label = input(usr, "Whose dungeon progress?", "Dungeon Meta Debug") as null|anything in targets
	var/target_ckey = targets[picked_label]
	if(!target_ckey)
		return
	var/datum/dungeon_progress/progress = get_dungeon_progress(target_ckey)
	if(!progress)
		to_chat(usr, "Could not load progress for [target_ckey].")
		return
	var/action = input(usr, "[target_ckey] — echoes: [progress.echoes], unlocks: [length(progress.purchased_unlocks)]", "Dungeon Meta Debug") as null|anything in list("Grant echoes", "Set echoes", "Grant unlock", "Revoke unlock", "Reset echoes & unlocks", "Show progress")
	switch(action)
		if("Grant echoes")
			var/amount = input(usr, "Grant how many echoes?", "Grant Echoes", 100) as null|num
			if(isnull(amount))
				return
			progress.add_echoes(amount)
			log_admin("[key_name(usr)] granted [amount] dungeon echoes to [target_ckey].")
			to_chat(usr, span_adminnotice("Granted [amount] echoes to [target_ckey] (now [progress.echoes])."))
		if("Set echoes")
			var/amount = input(usr, "Set echoes to?", "Set Echoes", progress.echoes) as null|num
			if(isnull(amount))
				return
			progress.echoes = max(0, round(amount))
			progress.save_progress()
			log_admin("[key_name(usr)] set [target_ckey]'s dungeon echoes to [progress.echoes].")
			to_chat(usr, span_adminnotice("Set [target_ckey]'s echoes to [progress.echoes]."))
		if("Grant unlock")
			admin_grant_dungeon_unlock(progress, target_ckey)
		if("Revoke unlock")
			admin_revoke_dungeon_unlock(progress, target_ckey)
		if("Reset echoes & unlocks")
			if(alert(usr, "Wipe [target_ckey]'s echoes and all unlocks?", "Confirm", "Yes", "No") != "Yes")
				return
			progress.echoes = 0
			progress.purchased_unlocks = list()
			progress.save_progress()
			log_admin("[key_name(usr)] reset [target_ckey]'s dungeon echoes and unlocks.")
			to_chat(usr, span_adminnotice("Reset [target_ckey]'s echoes and unlocks."))
		if("Show progress")
			to_chat(usr, span_notice("<b>[target_ckey]</b> — echoes: [progress.echoes], unlocks: [json_encode(progress.purchased_unlocks)], deepest floor: [progress.deepest_floor], bosses: [progress.bosses_killed], runs: [progress.runs_completed]"))

/// Helper: picks a catalogue unlock and grants it. Not a verb (no category).
/client/proc/admin_grant_dungeon_unlock(datum/dungeon_progress/progress, target_ckey)
	var/list/catalogue = get_dungeon_unlock_catalogue()
	var/list/by_label = list()
	for(var/datum/dungeon_unlock/unlock as anything in catalogue)
		by_label["[unlock.name] ([unlock.id])[progress.has_unlock(unlock.id) ? " — owned" : ""]"] = unlock.id
	var/picked = input(usr, "Grant which unlock?", "Grant Unlock") as null|anything in by_label
	var/unlock_id = by_label[picked]
	for(var/datum/dungeon_unlock/unlock as anything in catalogue)
		qdel(unlock)
	if(!unlock_id)
		return
	progress.grant_unlock(unlock_id)
	log_admin("[key_name(usr)] granted dungeon unlock '[unlock_id]' to [target_ckey].")
	to_chat(usr, span_adminnotice("Granted unlock '[unlock_id]' to [target_ckey]."))

/// Helper: picks one of the target's owned unlocks and strips it. Not a verb.
/client/proc/admin_revoke_dungeon_unlock(datum/dungeon_progress/progress, target_ckey)
	if(!length(progress.purchased_unlocks))
		to_chat(usr, "[target_ckey] owns no unlocks.")
		return
	var/list/owned = list()
	for(var/unlock_id in progress.purchased_unlocks)
		owned["[unlock_id]"] = unlock_id
	var/picked = input(usr, "Revoke which unlock?", "Revoke Unlock") as null|anything in owned
	var/unlock_id = owned[picked]
	if(!unlock_id)
		return
	progress.purchased_unlocks -= unlock_id
	progress.save_progress()
	log_admin("[key_name(usr)] revoked dungeon unlock '[unlock_id]' from [target_ckey].")
	to_chat(usr, span_adminnotice("Revoked unlock '[unlock_id]' from [target_ckey]."))
