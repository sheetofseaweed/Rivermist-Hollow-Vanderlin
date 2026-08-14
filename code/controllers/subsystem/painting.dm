#define PAINTING_DIRECTORY "data/player_generated_paintings/"

SUBSYSTEM_DEF(paintings)
	name = "Paintings"
	init_order = INIT_ORDER_PATH
	flags = SS_NO_FIRE

	/// painting_id -> metadata list, mirrors what is on disk
	var/list/paintings = list()
	/// set once the archive directory has been walked
	var/archive_scanned = FALSE

/datum/controller/subsystem/paintings/Initialize(start_timeofday)
	update_paintings()
	return ..()

/datum/controller/subsystem/paintings/proc/get_painting_filename(painting_id)
	return "[PAINTING_DIRECTORY][painting_id].png"

/datum/controller/subsystem/paintings/proc/get_metadata_filename(painting_id)
	return "[PAINTING_DIRECTORY][painting_id].json"

/// map-spawned canvases initialize before this subsystem, so let them pull the archive in early
/datum/controller/subsystem/paintings/proc/ensure_loaded()
	if(!archive_scanned)
		update_paintings()

/// rebuilds the index by walking the directory, so there is no master list to lose or grief
/datum/controller/subsystem/paintings/proc/update_paintings()
	archive_scanned = TRUE
	paintings = list()
	for(var/filename in flist(PAINTING_DIRECTORY))
		if(!findtext(filename, ".json", -5))
			continue
		var/painting_id = copytext(filename, 1, -5)
		var/list/metadata = file2painting(painting_id)
		if(!length(metadata))
			continue
		if(!fexists(get_painting_filename(painting_id)))
			continue
		paintings[painting_id] = metadata

/datum/controller/subsystem/paintings/proc/file2painting(painting_id)
	if(!painting_id)
		return list()
	var/json_file = get_metadata_filename(painting_id)
	if(!fexists(json_file))
		return list()
	var/list/contents = json_decode(file2text(json_file))
	if(isnull(contents))
		return list()
	return contents

/// ids are derived, never player text, so a title can never steer the filename
/datum/controller/subsystem/paintings/proc/generate_painting_id(author_ckey)
	var/stem = "art_[ckey(author_ckey) || "unknown"]_[world.realtime]"
	var/painting_id = "[stem]_[rand(1000, 9999)]"
	for(var/attempt in 1 to 50)
		if(!fexists(get_metadata_filename(painting_id)))
			break
		painting_id = "[stem]_[rand(1000, 9999)]"
	return painting_id

/datum/controller/subsystem/paintings/proc/save_painting(obj/item/canvas/canvas, mob/archivist)
	if(!canvas?.painting_id)
		return "This painting has no mark to file it under!"
	if(!istext(canvas.title) || !istext(canvas.author))
		return "This painting is incorrectly formatted!"

	var/list/metadata = list(
		"id" = canvas.painting_id,
		"painting_title" = canvas.title,
		"author" = canvas.author,
		"author_ckey" = canvas.author_ckey,
		"canvas_size" = canvas.canvas_size,
	)

	var/image_path = get_painting_filename(canvas.painting_id)
	var/metadata_path = get_metadata_filename(canvas.painting_id)
	fdel(image_path)
	fdel(metadata_path)

	if(!fcopy(canvas.icon, image_path))
		return "The archive rejects this painting, its likeness will not hold."

	text2file(json_encode(metadata), metadata_path)
	paintings[canvas.painting_id] = metadata
	// the archivist is whoever fed the press, which need not be the painter
	var/archivist_key = archivist?.ckey || "unknown"
	log_game("PAINTING: [archivist_key] archived '[canvas.title]' by [canvas.author_ckey] as [canvas.painting_id]")
	message_admins("Painting '[canvas.title]' by [canvas.author] ([canvas.author_ckey]) was archived by [archivist_key]")
	return "You have a feeling this painting will hang in the archive for a very long time..."

/datum/controller/subsystem/paintings/proc/pick_painting_id(canvas_size)
	ensure_loaded()
	var/list/candidates = list()
	for(var/painting_id in paintings)
		var/list/metadata = paintings[painting_id]
		if(metadata["canvas_size"] != canvas_size)
			continue
		candidates += painting_id
	if(!length(candidates))
		return null
	return pick(candidates)

/datum/controller/subsystem/paintings/proc/del_player_painting(painting_id)
	if(!painting_id || !paintings[painting_id])
		return FALSE
	fdel(get_metadata_filename(painting_id))
	fdel(get_painting_filename(painting_id))
	paintings -= painting_id
	return TRUE

#undef PAINTING_DIRECTORY
