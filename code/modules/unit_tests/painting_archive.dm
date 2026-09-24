/// covers the on-disk archive: id generation, save, index rebuild, load and delete
/datum/unit_test/painting_archive_roundtrip

/datum/unit_test/painting_archive_roundtrip/Run()
	var/obj/item/canvas/canvas = allocate(/obj/item/canvas)
	canvas.author = "Testy McPainter"
	canvas.author_ckey = "unittestpainter"
	canvas.title = "A Study In Squares"
	canvas.modified_areas["4,4"] = "#ff0000"
	canvas.update_drawing(4, 4, "#ff0000")
	canvas.modified_areas["5,5"] = "#00ff00"
	canvas.update_drawing(5, 5, "#00ff00")

	var/result = canvas.upload_painting(null)
	TEST_ASSERT_NOTNULL(canvas.painting_id, "Uploading did not assign a painting id. Result was: [result]")

	var/painting_id = canvas.painting_id
	var/image_path = SSpaintings.get_painting_filename(painting_id)
	var/metadata_path = SSpaintings.get_metadata_filename(painting_id)

	TEST_ASSERT(fexists(image_path), "Upload did not write the image to [image_path]. Result was: [result]")
	TEST_ASSERT(fexists(metadata_path), "Upload did not write the metadata to [metadata_path].")

	var/list/stored = SSpaintings.paintings[painting_id]
	TEST_ASSERT(islist(stored), "The saved painting is missing from the in-memory index.")
	TEST_ASSERT_EQUAL(stored["painting_title"], "A Study In Squares", "Stored title does not match.")
	TEST_ASSERT_EQUAL(stored["author_ckey"], "unittestpainter", "Stored author ckey does not match.")
	TEST_ASSERT_EQUAL(stored["canvas_size"], "32x32", "Stored canvas size does not match.")

	// the index must be rebuildable purely from what is on disk, with no master list
	SSpaintings.update_paintings()
	var/list/rediscovered = SSpaintings.paintings[painting_id]
	TEST_ASSERT(islist(rediscovered), "Rescanning the archive directory lost the painting.")
	TEST_ASSERT_EQUAL(rediscovered["author"], "Testy McPainter", "Rescanned metadata does not match.")

	TEST_ASSERT_NOTNULL(SSpaintings.pick_painting_id("32x32"), "A 32x32 painting exists but none was picked.")
	TEST_ASSERT_NULL(SSpaintings.pick_painting_id("999x999"), "Picked a painting for a size that has none.")

	var/obj/item/canvas/reloaded = allocate(/obj/item/canvas)
	TEST_ASSERT(reloaded.load_painting(painting_id), "Loading the archived painting failed.")
	TEST_ASSERT_EQUAL(reloaded.title, "A Study In Squares", "Loaded canvas has the wrong title.")
	TEST_ASSERT_EQUAL(reloaded.author, "Testy McPainter", "Loaded canvas has the wrong author.")
	TEST_ASSERT_EQUAL(reloaded.name, "A Study In Squares", "Loaded canvas was not renamed.")
	TEST_ASSERT(reloaded.art_credited, "An archive print should not earn fresh devotion.")

	// cell 4,4 lands on icon pixel 5,5
	var/reloaded_pixel = reloaded.draw.GetPixel(5, 5)
	TEST_ASSERT_NOTNULL(reloaded_pixel, "The reloaded picture is transparent where paint was laid.")
	TEST_ASSERT_EQUAL(lowertext(reloaded_pixel), "#ff0000", "The reloaded picture lost its paint.")
	TEST_ASSERT(reloaded.has_paint(), "A reloaded painting reads as blank.")
	var/read_back = reloaded.modified_areas["4,4"]
	TEST_ASSERT_NOTNULL(read_back, "Painted cells were not read back from the loaded picture.")
	TEST_ASSERT_EQUAL(lowertext(read_back), "#ff0000", "A read back cell has the wrong colour.")
	TEST_ASSERT_NULL(reloaded.modified_areas["20,20"], "Bare canvas was read back as paint.")

	TEST_ASSERT(!SSpaintings.del_player_painting("art_nosuchpainting_1_1"), "Deleting an unknown id reported success.")

	TEST_ASSERT(SSpaintings.del_player_painting(painting_id), "Deleting the painting reported failure.")
	TEST_ASSERT(!fexists(image_path), "Deletion left the image behind.")
	TEST_ASSERT(!fexists(metadata_path), "Deletion left the metadata behind.")
	TEST_ASSERT_NULL(SSpaintings.paintings[painting_id], "Deletion left the index entry behind.")

/// a hostile title must never reach the filesystem path
/datum/unit_test/painting_id_is_filename_safe

/datum/unit_test/painting_id_is_filename_safe/Run()
	var/painting_id = SSpaintings.generate_painting_id("../../etc/Bad Ckey!")

	TEST_ASSERT(!findtext(painting_id, "/"), "Generated id [painting_id] contains a path separator.")
	TEST_ASSERT(!findtext(painting_id, "\\"), "Generated id [painting_id] contains a backslash.")
	TEST_ASSERT(!findtext(painting_id, ".."), "Generated id [painting_id] contains a parent traversal.")
	TEST_ASSERT(!findtext(painting_id, " "), "Generated id [painting_id] contains a space.")
	// a bare realtime prints in scientific notation, which puts dots and plus signs in filenames
	TEST_ASSERT(!findtext(painting_id, "."), "Generated id [painting_id] contains a dot.")
	TEST_ASSERT(!findtext(painting_id, "+"), "Generated id [painting_id] contains a plus sign.")

	var/obj/item/canvas/canvas = allocate(/obj/item/canvas)
	canvas.author = "Rude Artist"
	canvas.author_ckey = "unittestpainter"
	canvas.title = "../../../_painting_titles"
	canvas.modified_areas["1,1"] = "#ff0000"

	canvas.upload_painting(null)
	TEST_ASSERT_NOTNULL(canvas.painting_id, "Uploading a hostile title did not assign an id.")
	TEST_ASSERT(!findtext(canvas.painting_id, ".."), "A hostile title reached the painting id.")

	// the title is metadata only, it must not steer where the file lands
	TEST_ASSERT(fexists(SSpaintings.get_painting_filename(canvas.painting_id)), "The painting did not land at its derived path.")

	SSpaintings.del_player_painting(canvas.painting_id)

/// covers the brush stamp: bounds, size, erase and the per-stroke ink budget
/datum/unit_test/painting_brush_strokes

/datum/unit_test/painting_brush_strokes/Run()
	var/obj/item/canvas/canvas = allocate(/obj/item/canvas)
	var/mob/living/carbon/human/painter = allocate(/mob/living/carbon/human)
	var/atom/movable/screen/canvas/surface = canvas.used_canvas

	var/list/state = surface.get_painter_state(painter)
	state["drawing"] = TRUE

	surface.draw_pixel(-5, -5, "#ff0000", FALSE, 1, FALSE, painter)
	surface.draw_pixel(64, 64, "#ff0000", FALSE, 1, FALSE, painter)
	TEST_ASSERT_EQUAL(length(canvas.modified_areas), 0, "Painting outside the canvas bounds still marked cells.")

	surface.draw_pixel(10, 10, "#ff0000", FALSE, 3, FALSE, painter)
	TEST_ASSERT_EQUAL(length(canvas.modified_areas), 9, "A size 3 brush should stamp a 3x3 block.")
	TEST_ASSERT_EQUAL(canvas.modified_areas["10,10"], "#ff0000", "The stamp centre has the wrong colour.")

	surface.draw_pixel(10, 10, null, TRUE, 3, FALSE, painter)
	TEST_ASSERT_EQUAL(length(canvas.modified_areas), 0, "Erasing a size 3 stamp did not clear the block.")

	// a single stroke must run dry rather than let a held mouse paint forever
	state["ink"] = 0
	state["drawing"] = TRUE
	for(var/y in 0 to 3)
		for(var/x in 0 to 31)
			surface.draw_pixel(x, y, "#0000ff", FALSE, 1, FALSE, painter)

	TEST_ASSERT_EQUAL(length(canvas.modified_areas), surface.max_ink, "A stroke laid down more cells than the ink budget allows.")
	TEST_ASSERT(!state["drawing"], "Running out of ink should lift the brush.")

/// erasing baked paint must restore the bare canvas, never punch a transparent hole
/datum/unit_test/painting_erase_restores_canvas

/datum/unit_test/painting_erase_restores_canvas/Run()
	var/obj/item/canvas/canvas = allocate(/obj/item/canvas)
	var/mob/living/carbon/human/painter = allocate(/mob/living/carbon/human)
	var/atom/movable/screen/canvas/surface = canvas.used_canvas
	var/list/state = surface.get_painter_state(painter)
	state["drawing"] = TRUE

	var/bare_pixel = canvas.base.GetPixel(11, 11)
	TEST_ASSERT_NOTNULL(bare_pixel, "The bare canvas should be opaque where it is painted.")

	surface.draw_pixel(10, 10, "#ff0000", FALSE, 1, FALSE, painter)
	canvas.flatten()
	var/painted_pixel = canvas.draw.GetPixel(11, 11)
	TEST_ASSERT_NOTNULL(painted_pixel, "Flattening left the painted cell transparent.")
	TEST_ASSERT_EQUAL(lowertext(painted_pixel), "#ff0000", "Flattening did not bake the paint.")

	surface.draw_pixel(10, 10, null, TRUE, 1, FALSE, painter)
	TEST_ASSERT_EQUAL(canvas.draw.GetPixel(11, 11), bare_pixel, "Erasing left a hole instead of bare canvas.")

/// a print of someone else's archived work must neither overwrite nor re-sign the original
/datum/unit_test/painting_archive_protects_authors

/datum/unit_test/painting_archive_protects_authors/Run()
	var/obj/item/canvas/original = allocate(/obj/item/canvas)
	original.author = "Rightful Painter"
	original.author_ckey = "unittestpainter"
	original.title = "Mine Alone"
	original.modified_areas["2,2"] = "#0000ff"
	original.update_drawing(2, 2, "#0000ff")
	original.upload_painting(null)
	var/painting_id = original.painting_id
	TEST_ASSERT_NOTNULL(painting_id, "The original painting was not archived.")

	TEST_ASSERT(SSpaintings.can_amend(painting_id, "unittestpainter"), "The painter could not amend their own work.")
	TEST_ASSERT(!SSpaintings.can_amend(painting_id, "unittestthief"), "Another player could amend the painting.")
	TEST_ASSERT(!SSpaintings.can_amend(painting_id, null), "A ckeyless archivist could amend the painting.")
	TEST_ASSERT(SSpaintings.can_amend("art_nosuchpainting_1_1", "unittestthief"), "A painting that is not archived yet could not be filed.")

	var/obj/item/canvas/print = allocate(/obj/item/canvas)
	TEST_ASSERT(print.load_painting(painting_id), "Printing the archived painting failed.")
	var/mob/living/carbon/human/thief = allocate(/mob/living/carbon/human)
	TEST_ASSERT(!print.apply_signature(thief, "Thief", "Stolen Glory"), "A print of another's work accepted a new signature.")
	TEST_ASSERT_EQUAL(print.author, "Rightful Painter", "Re-signing changed the print's author.")

	print.modified_areas["3,3"] = "#000000"
	print.update_drawing(3, 3, "#000000")
	var/result = print.upload_painting(null)
	var/list/stored = SSpaintings.paintings[painting_id]
	var/stored_title = islist(stored) ? stored["painting_title"] : null
	SSpaintings.del_player_painting(painting_id)

	TEST_ASSERT(findtext(result, "only its painter"), "Uploading a defaced print was not refused. Result was: [result]")
	TEST_ASSERT_EQUAL(stored_title, "Mine Alone", "The refused upload still changed the archive.")

/// Eora's art task pays once per canvas, and only once there is paint on it
/datum/unit_test/painting_signature_pays_eora_once
	var/art_signals = 0

/datum/unit_test/painting_signature_pays_eora_once/proc/count_art()
	SIGNAL_HANDLER
	art_signals++

/datum/unit_test/painting_signature_pays_eora_once/Run()
	var/obj/item/canvas/canvas = allocate(/obj/item/canvas)
	var/mob/living/carbon/human/painter = allocate(/mob/living/carbon/human)
	RegisterSignal(painter, COMSIG_ART_CREATED, PROC_REF(count_art))

	var/signed_blank = canvas.apply_signature(painter, "Idle Hands", "Nothing At All")
	var/blank_signals = art_signals
	canvas.modified_areas["6,6"] = "#ff00ff"
	canvas.apply_signature(painter, null, "Something At Last")
	var/painted_signals = art_signals
	canvas.apply_signature(painter, null, "Something Else")
	UnregisterSignal(painter, COMSIG_ART_CREATED)

	TEST_ASSERT(signed_blank, "Signing a blank canvas failed.")
	TEST_ASSERT_EQUAL(blank_signals, 0, "Signing a blank canvas paid devotion.")
	TEST_ASSERT_EQUAL(painted_signals, 1, "Signing a painted canvas did not pay devotion.")
	TEST_ASSERT_EQUAL(art_signals, 1, "Re-signing the same canvas paid devotion again.")

/// random canvases show every archived painting before repeating one
/datum/unit_test/painting_pick_prefers_unseen

/datum/unit_test/painting_pick_prefers_unseen/Run()
	var/list/filed_ids = list()
	for(var/i in 1 to 2)
		var/obj/item/canvas/canvas = allocate(/obj/item/canvas)
		canvas.author = "Gallery Filler"
		canvas.author_ckey = "unittestpainter"
		canvas.title = "Piece [i]"
		// a size no real canvas uses keeps any live archive out of the draw
		canvas.canvas_size = "unittest_size"
		canvas.modified_areas["[i],[i]"] = "#ffffff"
		canvas.upload_painting(null)
		if(canvas.painting_id)
			filed_ids += canvas.painting_id

	var/first_pick = SSpaintings.pick_painting_id("unittest_size")
	var/second_pick = SSpaintings.pick_painting_id("unittest_size")
	var/third_pick = SSpaintings.pick_painting_id("unittest_size")
	for(var/painting_id in filed_ids)
		SSpaintings.del_player_painting(painting_id)

	TEST_ASSERT_EQUAL(length(filed_ids), 2, "The test paintings were not archived.")
	TEST_ASSERT((first_pick in filed_ids) && (second_pick in filed_ids), "Picking returned a painting that was not filed.")
	TEST_ASSERT_NOTEQUAL(first_pick, second_pick, "A painting repeated while another was still unseen.")
	TEST_ASSERT(third_pick in filed_ids, "Once every painting was shown, picking stopped instead of repeating.")

/// pre-rewrite archives named files by raw title, they must be carried over and set aside
/datum/unit_test/painting_legacy_archive_migrates

/datum/unit_test/painting_legacy_archive_migrates/Run()
	var/obj/item/canvas/canvas = allocate(/obj/item/canvas)
	canvas.modified_areas["7,7"] = "#ffff00"
	canvas.update_drawing(7, 7, "#ffff00")
	canvas.flatten()

	var/legacy_title = "Unit Test Old Master Piece"
	var/legacy_image = SSpaintings.get_legacy_image_filename(legacy_title)
	var/legacy_metadata = SSpaintings.get_metadata_filename("unittest_legacy_piece")
	var/hostile_metadata = SSpaintings.get_metadata_filename("unittest_legacy_hostile")
	var/backup_image = SSpaintings.get_legacy_backup_filename("[legacy_title].png")
	var/backup_metadata = SSpaintings.get_legacy_backup_filename("unittest_legacy_piece.json")

	TEST_ASSERT(fcopy(canvas.icon, legacy_image), "Could not write the legacy test image.")
	text2file(json_encode(list("painting_title" = legacy_title, "author" = "Old Master", "author_ckey" = "unittestlegacy", "canvas_size" = "32x32")), legacy_metadata)
	text2file(json_encode(list("painting_title" = "../../unittest_escape", "author" = "Vandal", "author_ckey" = "unittestvandal", "canvas_size" = "32x32")), hostile_metadata)

	SSpaintings.update_paintings()
	// a second scan must not migrate the same painting twice
	SSpaintings.update_paintings()

	var/list/migrated_ids = list()
	for(var/painting_id in SSpaintings.paintings)
		var/list/metadata = SSpaintings.paintings[painting_id]
		if(metadata["author_ckey"] == "unittestlegacy")
			migrated_ids += painting_id
	var/migrated_loads = FALSE
	var/migrated_title
	if(length(migrated_ids))
		var/obj/item/canvas/reloaded = allocate(/obj/item/canvas)
		migrated_loads = reloaded.load_painting(migrated_ids[1])
		migrated_title = reloaded.title
	var/image_moved = !fexists(legacy_image) && fexists(backup_image)
	var/metadata_moved = !fexists(legacy_metadata) && fexists(backup_metadata)
	var/hostile_untouched = fexists(hostile_metadata)

	for(var/painting_id in migrated_ids)
		SSpaintings.del_player_painting(painting_id)
	for(var/leftover in list(legacy_image, legacy_metadata, hostile_metadata, backup_image, backup_metadata))
		fdel(leftover)

	TEST_ASSERT_EQUAL(length(migrated_ids), 1, "The legacy painting was not migrated exactly once.")
	TEST_ASSERT(migrated_loads, "The migrated painting could not be loaded onto a canvas.")
	TEST_ASSERT_EQUAL(migrated_title, legacy_title, "The migrated painting lost its title.")
	TEST_ASSERT(image_moved, "The legacy image was not moved into the backup folder.")
	TEST_ASSERT(metadata_moved, "The legacy metadata was not moved into the backup folder.")
	TEST_ASSERT(hostile_untouched, "A legacy entry with a traversal title was touched.")
