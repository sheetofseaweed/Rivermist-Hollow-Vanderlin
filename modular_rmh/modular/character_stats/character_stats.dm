// Logs each played character to character_stats.csv in the round log folder at round end.

GLOBAL_DATUM_INIT(character_stats, /datum/character_stats, new)

/datum/character_stats
	/// One record per player-controlled character spawned this round.
	var/list/datum/character_stats_record/records = list()
	/// Set once the round end callback is queued.
	var/round_end_hooked = FALSE
	/// Set once the report is written; later spawns are ignored.
	var/written = FALSE

/datum/character_stats/New()
	. = ..()
	RegisterSignal(SSdcs, COMSIG_GLOB_JOB_AFTER_SPAWN, PROC_REF(on_job_spawn))

/datum/character_stats/proc/on_job_spawn(datum/source, datum/job/job, mob/living/carbon/human/spawned, client/player_client)
	SIGNAL_HANDLER

	if(written || !istype(spawned))
		return
	var/ckey = player_client?.ckey || spawned.ckey
	if(!ckey)
		return
	if(!round_end_hooked)
		round_end_hooked = TRUE
		LAZYADD(SSticker.round_end_events, CALLBACK(src, PROC_REF(write_report)))

	// Class pickers re-run EquipRank, so one body can spawn several times.
	for(var/datum/character_stats_record/record as anything in records)
		if(record.body == spawned)
			record.snapshot()
			return
	records += new /datum/character_stats_record(spawned, ckey, job?.title)

/datum/character_stats/proc/write_report()
	if(written)
		return
	written = TRUE

	var/list/lines = list("round_id,ckey,name,species,gender,futa,age,job,playtime_minutes")
	for(var/datum/character_stats_record/record as anything in records)
		record.finish()
		lines += record.to_csv_row()
	rustg_file_write(jointext(lines, "\n") + "\n", "[GLOB.log_directory]/character_stats.csv")
	QDEL_LIST(records)

/// Tracks one character; play time counts only while its player is in the living body.
/datum/character_stats_record
	var/mob/living/carbon/human/body
	var/ckey
	var/job_title
	var/name
	var/species
	var/gender
	var/futa
	var/age
	/// Finished play time in deciseconds.
	var/played_time = 0
	/// world.time the open play segment began, null when not counting.
	var/segment_start

/datum/character_stats_record/New(mob/living/carbon/human/body, ckey, job_title)
	. = ..()
	src.body = body
	src.ckey = ckey
	src.job_title = job_title
	snapshot()
	RegisterSignal(body, COMSIG_MOB_LOGIN, PROC_REF(on_login))
	RegisterSignal(body, COMSIG_LIVING_REVIVE, PROC_REF(on_login))
	RegisterSignals(body, list(COMSIG_MOB_LOGOUT, COMSIG_LIVING_DEATH), PROC_REF(on_leave))
	RegisterSignal(body, COMSIG_PARENT_QDELETING, PROC_REF(on_body_deleted))
	on_login()

/datum/character_stats_record/Destroy()
	release_body()
	return ..()

/// Copies the character's traits from the body as it is now.
/datum/character_stats_record/proc/snapshot()
	if(QDELETED(body))
		return
	name = body.real_name
	species = body.dna?.species?.name || "Unknown"
	gender = capitalize(body.gender)
	age = body.age
	// Futa means a real penis on a female body or alongside a real vagina; strapons do not count.
	var/has_penis = !!get_real_organ(body, ORGAN_SLOT_PENIS)
	futa = has_penis && (body.gender == FEMALE || !!get_real_organ(body, ORGAN_SLOT_VAGINA))

/datum/character_stats_record/proc/on_login()
	SIGNAL_HANDLER

	if(isnull(segment_start) && body.ckey == ckey && body.stat != DEAD)
		segment_start = world.time

/datum/character_stats_record/proc/on_leave()
	SIGNAL_HANDLER

	stop_segment()

/datum/character_stats_record/proc/on_body_deleted()
	SIGNAL_HANDLER

	stop_segment()
	release_body()

/datum/character_stats_record/proc/stop_segment()
	if(isnull(segment_start))
		return
	played_time += world.time - segment_start
	segment_start = null

/datum/character_stats_record/proc/release_body()
	if(!body)
		return
	UnregisterSignal(body, list(COMSIG_MOB_LOGIN, COMSIG_LIVING_REVIVE, COMSIG_MOB_LOGOUT, COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
	body = null

/// Closes the open segment and picks up late renames, such as villain name choices.
/datum/character_stats_record/proc/finish()
	stop_segment()
	if(!QDELETED(body))
		name = body.real_name

/datum/character_stats_record/proc/to_csv_row()
	var/list/cells = list(
		GLOB.rogue_round_id,
		ckey,
		name,
		species,
		gender,
		futa ? "Yes" : "No",
		age,
		job_title,
		round(played_time / (1 MINUTES)),
	)
	for(var/i in 1 to length(cells))
		cells[i] = csv_cell(cells[i])
	return jointext(cells, ",")

/// Quotes a value for CSV, doubling inner quotes and flattening newlines.
/datum/character_stats_record/proc/csv_cell(value)
	var/text = replacetext(replacetext("[value]", "\n", " "), "\"", "\"\"")
	return "\"[text]\""
