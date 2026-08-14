/// covers the on-disk archive: id generation, save, index rebuild, load and delete
/datum/unit_test/painting_archive_roundtrip

/datum/unit_test/painting_archive_roundtrip/Run()
	var/obj/item/canvas/canvas = allocate(/obj/item/canvas)
	canvas.author = "Testy McPainter"
	canvas.author_ckey = "unittestpainter"
	canvas.title = "A Study In Squares"
	canvas.modified_areas["4,4"] = "#ff0000"
	canvas.modified_areas["5,5"] = "#00ff00"

	var/result = canvas.upload_painting(null)
	TEST_ASSERT_NOTNULL(canvas.painting_id, "Uploading did not assign a painting id.")

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

	var/obj/item/canvas/canvas = allocate(/obj/item/canvas)
	canvas.author = "Rude Artist"
	canvas.author_ckey = "unittestpainter"
	canvas.title = "../../../_painting_titles"

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
