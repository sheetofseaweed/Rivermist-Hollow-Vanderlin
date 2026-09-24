#define PAINTING_DIRECTORY "data/player_generated_paintings/"
/// pre-rewrite archives kept images here, named by raw title
#define LEGACY_IMAGE_DIRECTORY "data/player_generated_paintings/paintings/"
#define LEGACY_INDEX_FILENAME "_painting_titles.json"
/// migrated pre-rewrite files are moved here instead of deleted
#define LEGACY_BACKUP_DIRECTORY "data/player_generated_paintings/legacy/"

SUBSYSTEM_DEF(paintings)
	name = "Paintings"
	init_order = INIT_ORDER_PATH
	flags = SS_NO_FIRE

	/// painting_id -> metadata list, mirrors what is on disk
	var/list/paintings = list()
	/// set once the archive directory has been walked
	var/archive_scanned = FALSE
	/// ids already hung this round, so random canvases prefer unseen work
	var/list/shown_painting_ids = list()

/datum/controller/subsystem/paintings/Initialize(start_timeofday)
	update_paintings()
	return ..()

/datum/controller/subsystem/paintings/proc/get_painting_filename(painting_id)
	return "[PAINTING_DIRECTORY][painting_id].png"

/datum/controller/subsystem/paintings/proc/get_metadata_filename(painting_id)
	return "[PAINTING_DIRECTORY][painting_id].json"

/datum/controller/subsystem/paintings/proc/get_legacy_image_filename(legacy_title)
	return "[LEGACY_IMAGE_DIRECTORY][legacy_title].png"

/datum/controller/subsystem/paintings/proc/get_legacy_backup_filename(backup_name)
	return "[LEGACY_BACKUP_DIRECTORY][backup_name]"

/// map-spawned canvases initialize before this subsystem, so let them pull the archive in early
/datum/controller/subsystem/paintings/proc/ensure_loaded()
	if(!archive_scanned)
		update_paintings()

/// rebuilds the index by walking the directory, so there is no master list to lose or grief
/datum/controller/subsystem/paintings/proc/update_paintings()
	archive_scanned = TRUE
	migrate_legacy_archive()
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

/// moves pre-rewrite title-named files onto derived ids, keeping the originals in a backup folder
/datum/controller/subsystem/paintings/proc/migrate_legacy_archive()
	if(!length(flist(LEGACY_IMAGE_DIRECTORY)))
		return
	var/migrated = 0
	for(var/filename in flist(PAINTING_DIRECTORY))
		if(filename == LEGACY_INDEX_FILENAME || !findtext(filename, ".json", -5))
			continue
		var/stem = copytext(filename, 1, -5)
		if(fexists(get_painting_filename(stem)))
			continue
		var/list/metadata = file2painting(stem)
		var/legacy_title = metadata["painting_title"]
		// old titles were raw player text, never let one walk out of the image folder
		if(!istext(legacy_title) || findtext(legacy_title, "/") || findtext(legacy_title, "\\") || findtext(legacy_title, ".."))
			continue
		var/legacy_image = get_legacy_image_filename(legacy_title)
		if(!fexists(legacy_image))
			continue
		var/painting_id = generate_painting_id(metadata["author_ckey"])
		if(!fcopy(legacy_image, get_painting_filename(painting_id)))
			continue
		metadata["id"] = painting_id
		text2file(json_encode(metadata), get_metadata_filename(painting_id))
		move_to_legacy_backup(get_metadata_filename(stem), filename)
		move_to_legacy_backup(legacy_image, "[legacy_title].png")
		migrated++
	move_to_legacy_backup("[PAINTING_DIRECTORY][LEGACY_INDEX_FILENAME]", LEGACY_INDEX_FILENAME)
	if(migrated)
		log_game("PAINTING: migrated [migrated] pre-rewrite paintings into the archive")

/datum/controller/subsystem/paintings/proc/move_to_legacy_backup(source_path, backup_name)
	if(!fexists(source_path))
		return
	if(fcopy(source_path, get_legacy_backup_filename(backup_name)))
		fdel(source_path)

/// ids are derived, never player text, so a title can never steer the filename
/datum/controller/subsystem/paintings/proc/generate_painting_id(author_ckey)
	var/stem = "art_[ckey(author_ckey) || "unknown"]_[time2text(world.realtime, "YYYYMMDDhhmmss")]"
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
	if(!can_amend(canvas.painting_id, archivist?.ckey))
		return "This work is already in the archive, and only its painter may amend it."

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

/// an archived painting may only be replaced or re-signed by the ckey that painted it
/datum/controller/subsystem/paintings/proc/can_amend(painting_id, amending_ckey)
	if(!painting_id)
		return TRUE
	ensure_loaded()
	var/list/metadata = paintings[painting_id]
	if(!length(metadata))
		return TRUE
	return !isnull(amending_ckey) && metadata["author_ckey"] == amending_ckey

/datum/controller/subsystem/paintings/proc/pick_painting_id(canvas_size)
	ensure_loaded()
	var/list/unseen = list()
	var/list/seen = list()
	for(var/painting_id in paintings)
		var/list/metadata = paintings[painting_id]
		if(metadata["canvas_size"] != canvas_size)
			continue
		if(shown_painting_ids[painting_id])
			seen += painting_id
		else
			unseen += painting_id
	// repeats only once every matching painting is already on show
	var/chosen_id = length(unseen) ? pick(unseen) : (length(seen) ? pick(seen) : null)
	if(chosen_id)
		shown_painting_ids[chosen_id] = TRUE
	return chosen_id

/datum/controller/subsystem/paintings/proc/del_player_painting(painting_id)
	if(!painting_id || !paintings[painting_id])
		return FALSE
	fdel(get_metadata_filename(painting_id))
	fdel(get_painting_filename(painting_id))
	paintings -= painting_id
	shown_painting_ids -= painting_id
	return TRUE

#undef PAINTING_DIRECTORY
#undef LEGACY_IMAGE_DIRECTORY
#undef LEGACY_INDEX_FILENAME
#undef LEGACY_BACKUP_DIRECTORY
