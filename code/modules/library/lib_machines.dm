#define PRINTER_COOLDOWN 600 // The time between printing manuscripts and binding books
#define PRINTING_TIME 250 // The time it takes to actually print something using the printing press
#define PAINTINGS_PER_PAGE 12

/obj/machinery/printingpress
	name = "printing press"
	icon = 'icons/roguetown/misc/machines.dmi'
	icon_state = "Ppress_Clean"
	desc = "The Archivist's wonder. Gears, ink, and wood blocks can turn the written word to the printed word."
	density = TRUE
	var/cooldown = 0
	var/printing = FALSE
	var/has_paper = FALSE
	var/obj/item/paper/loaded_paper
	var/obj/item/output_item // Variable to store the prFliinted item

	var/static/list/manuel_name_to_path = list()

/obj/machinery/printingpress/attackby(obj/item/O, mob/user, list/modifiers)
	if(printing)
		to_chat(user, span_warning("[src] is currently printing. Please wait."))
		return
	if(output_item)
		to_chat(user, span_notice("Please retrieve the printed item before inserting new items."))
		return
	if(istype(O, /obj/item/canvas))
		var/obj/item/canvas/M = O
		if(!M.has_paint())
			show_painting_archive(user)
			return
		if(!M.author || !M.title)
			to_chat(user, span_notice("This canvas isn't signed."))
			return
		var/choice = input(user, "Do you want to add the painting to the archive?") in list("Yes", "No")
		if(choice != "Yes")
			to_chat(user, span_notice("You decide not to upload the painting."))
			return
		if(QDELETED(M) || !user.is_holding(M) || !user.Adjacent(src))
			return
		upload_painting(user, M)
		return

	if(istype(O, /obj/item/manuscript))
		var/obj/item/manuscript/M = O
		if(!M.written)
			to_chat(user, span_notice("This manuscript has yet to be authored and titled. You'll need to do so before uploading it."))
			return
		// Prompt the user to upload the manuscript
		var/choice = input(user, "Do you want to add the manuscript to the archive?") in list("Yes", "No")
		if(choice == "Yes")
			upload_manuscript(user, M)
			// // Optionally delete the manuscript after uploading
			// qdel(M)
			to_chat(user, span_notice("The manuscript has been uploaded."))
		else
			to_chat(user, span_notice("You decide not to upload the manuscript."))
		return
	if(istype(O, /obj/item/book/playerbook)) //yeah it's a little silly, but whatever, we're magic
		var/obj/item/book/playerbook/B = O
		// Prompt the user to upload the book
		var/choice = input(user, "Do you want to add the book to the archive?") in list("Yes", "No")
		if(choice == "Yes")
			upload_book(user, B)
			// // Optionally delete the book after uploading
			// qdel(B)
			to_chat(user, span_notice("The book has been uploaded."))
		else
			to_chat(user, span_notice("You decide not to upload the book."))
		return
	// THIS IS FOR LOADING BLANK PAPER AS MATERIAL
	if((O.type == /obj/item/paper) && !has_paper)
		var/obj/item/paper/paper = O
		if(paper.info)
			to_chat(user, span_warning("The paper needs to be blank to be put into [src]."))
			return
		has_paper = TRUE
		loaded_paper = O
		src.icon_state = "Ppress_Prepared"
		to_chat(user, span_warning("You insert the blank paper into [src]."))
		qdel(O)
	return ..()

/obj/machinery/printingpress/attack_hand(mob/user)
	if(printing)
		to_chat(user, span_warning("[src] is currently printing. Please wait."))
		return
	if(output_item)
		// Try to put the item into the user's hands
		if(!user.put_in_hands(output_item))
			output_item.forceMove(get_turf(user))
		else
			to_chat(user, span_warning("You retrieve [output_item] from [src]."))
		output_item = null
		src.icon_state = has_paper ? "Ppress_Prepared" : "Ppress_Clean"
		return
	if(loaded_paper)
		// Allow the user to retrieve the blank paper
		var/obj/item/paper/P = new /obj/item/paper(get_turf(user)) // Create the item at the user's location
		if(!user.put_in_hands(P)) // Try to put the item in the user's hands
			P.forceMove(get_turf(user)) // If not, drop it at the user's location
		to_chat(user, span_warning("You retrieve [P.name] from [src]."))
		has_paper = FALSE
		loaded_paper = null
		src.icon_state = "Ppress_Clean"
		return
	else
		// Default interaction or message
		to_chat(user, span_warning("[src] is empty."))
		return

/obj/machinery/printingpress/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return
	. = SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	if(printing)
		to_chat(user, span_warning("[src] is currently printing. Please wait."))
		return
	if(output_item)
		to_chat(user, span_warning("There is a finished product in [src]. Use an empty hand to retrieve it."))
		return
	if(!has_paper)
		to_chat(user, span_warning("[src] requires a blank piece of paper to print."))
		return
	var/choice = input(user, "Choose an option for \the [src]") as null|anything in list("Print The Book", "Print a Tome of Justice", "Print from the Archive", "Profession Manuel")
	switch(choice)
		if ("Print The Book")
			start_printing(user, "bibble")
		if ("Print a Tome of Justice")
			start_printing(user, "justice")
		if ("Print from the Archive")
			choose_search_parameters(user)
		if("Profession Manuel")
			if(!length(manuel_name_to_path))
				for(var/obj/item/recipe_book/book as anything in subtypesof(/obj/item/recipe_book))
					if(!initial(book.can_spawn))
						continue
					manuel_name_to_path |= initial(book.name)
					manuel_name_to_path[initial(book.name)] = book
			choice = input(user, "Choose an option for \the [src]") as null|anything in manuel_name_to_path
			if(choice)
				start_printing(user, manuel_name_to_path[choice])

/obj/machinery/printingpress/proc/start_printing(mob/user, print_type, id = null)
	if(cooldown > world.time)
		to_chat(user, span_warning("[src] is still recalibrating."))
		return
	printing = TRUE
	src.icon_state = "Ppress_Printing"
	to_chat(user, span_warning("[src] starts printing..."))
	playsound(src, 'sound/misc/ppress.ogg', 100, FALSE)
	// Delete the blank paper as it's consumed during printing
	if(loaded_paper)
		qdel(loaded_paper)
		loaded_paper = null
		has_paper = FALSE
	sleep(PRINTING_TIME)
	if(print_type == "bibble")
		print_bibble(user)
	else if(print_type == "justice")
		print_justice(user)
	else if(print_type == "archive")
		print_manuscript(user, id)
	else if (ispath(print_type))
		var/obj/item/recipe_book/path = print_type
		var/obj/item/recipe_book/book = new path()
		output_item = book
		visible_message("<span class='notice'>The printing press hums as it produces [book.name].</span>")

	// Printing is done
	record_round_statistic(STATS_BOOKS_PRINTED)
	printing = FALSE
	src.icon_state = "Ppress_Done"
	cooldown = world.time + PRINTER_COOLDOWN

/obj/machinery/printingpress/proc/upload_manuscript(mob/user, obj/item/manuscript/M)
	SSlibrarian.playerbook2file(M.compiled_pages, M.name, M.author, M.ckey, M.select_icon, M.category)
	SSlibrarian.update_books()

/obj/machinery/printingpress/proc/upload_book(mob/user, obj/item/book/playerbook/B)
	var/result = SSlibrarian.playerbook2file(B.plaintext, B.player_book_title, B.player_book_author, B.player_book_author_ckey, B.player_book_icon, B.category)
	to_chat(user, span_info(result))
	SSlibrarian.update_books()

/obj/machinery/printingpress/proc/upload_painting(mob/user, obj/item/canvas/M)
	var/result = M.upload_painting(user)
	to_chat(user, span_info(result))

/obj/machinery/printingpress/proc/show_painting_archive(mob/user, page = 1)
	var/list/painting_ids = list()
	for(var/painting_id in SSpaintings.paintings)
		if(fexists(SSpaintings.get_painting_filename(painting_id)))
			painting_ids += painting_id

	var/page_count = max(1, CEILING(length(painting_ids) / PAINTINGS_PER_PAGE, 1))
	page = clamp(round(page || 1), 1, page_count)

	var/dat = "<h3>The Painting Archive</h3>"
	if(!length(painting_ids))
		dat += "<p>The archive holds no paintings yet.</p>"
	else
		dat += "<p>Hold a blank canvas and choose a work to print onto it.</p>"
		dat += "<table style='width: 100%;'>"
		var/first_index = (page - 1) * PAINTINGS_PER_PAGE + 1
		var/last_index = min(page * PAINTINGS_PER_PAGE, length(painting_ids))
		for(var/i in first_index to last_index)
			var/painting_id = painting_ids[i]
			var/list/metadata = SSpaintings.paintings[painting_id]
			var/res_name = "painting_[md5(painting_id)].png"
			user << browse_rsc(file(SSpaintings.get_painting_filename(painting_id)), res_name)
			dat += "<tr>"
			dat += "<td><img src='[res_name]' width=64 height=64 style='image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;'></td>"
			// signing already encodes, decoding first stops a second pass from showing entities
			dat += "<td>[html_encode(html_decode(metadata["painting_title"]))]<br>by [html_encode(html_decode(metadata["author"]))]</td>"
			dat += "<td><a href='byond://?src=[REF(src)];print_painting=[url_encode(painting_id)]'>Print</a></td>"
			dat += "</tr>"
		dat += "</table>"
		if(page_count > 1)
			dat += "<p>"
			if(page > 1)
				dat += "<a href='byond://?src=[REF(src)];painting_page=[page - 1]'>Previous</a> "
			dat += "Page [page] of [page_count]"
			if(page < page_count)
				dat += " <a href='byond://?src=[REF(src)];painting_page=[page + 1]'>Next</a>"
			dat += "</p>"

	var/datum/browser/popup = new(user, "painting_archive", "The Painting Archive", 420, 600)
	popup.set_content(dat)
	popup.open()

/obj/machinery/printingpress/proc/print_painting(mob/living/user, painting_id)
	if(!istype(user) || !user.Adjacent(src))
		return
	if(printing || output_item)
		to_chat(user, span_warning("[src] is busy."))
		return
	if(cooldown > world.time)
		to_chat(user, span_warning("[src] is still recalibrating."))
		return
	if(!SSpaintings.paintings[painting_id])
		to_chat(user, span_warning("That painting is no longer in the archive."))
		return
	var/obj/item/canvas/blank = user.get_active_held_item()
	if(!istype(blank) || blank.has_paint())
		to_chat(user, span_warning("I need a blank canvas in my hand to take a print."))
		return
	if(!user.transferItemToLoc(blank, src))
		return

	printing = TRUE
	icon_state = "Ppress_Printing"
	to_chat(user, span_notice("[src] starts pressing the painting onto [blank]..."))
	playsound(src, 'sound/misc/ppress.ogg', 100, FALSE)
	sleep(PRINTING_TIME)
	if(QDELETED(src))
		return
	printing = FALSE
	cooldown = world.time + PRINTER_COOLDOWN
	if(QDELETED(blank))
		icon_state = has_paper ? "Ppress_Prepared" : "Ppress_Clean"
		return

	if(blank.load_painting(painting_id))
		visible_message(span_notice("[src] hums as it produces a print of [blank.name]."))
	else
		visible_message(span_warning("[src] smears ink across the canvas, the painting has gone from the archive."))
	output_item = blank
	icon_state = "Ppress_Done"

/obj/machinery/printingpress/proc/print_bibble(mob/user)
	// Creates a static book (Bibble)
	var/obj/item/book/bibble/B = new()
	output_item = B
	visible_message("<span class='notice'>The printing press hums as it produces [B.name].</span>")

/obj/machinery/printingpress/proc/print_justice(mob/user)
	// Creates a static book (Tome of Justice)
	var/obj/item/book/law/B = new()
	output_item = B
	visible_message("<span class='notice'>[src] hums as it produces [B.name].</span>")

/obj/machinery/printingpress/proc/print_manuscript(mob/user, id)
	output_item = new /obj/item/book/playerbook(src, null, null, null, id)

/obj/machinery/printingpress/proc/choose_search_parameters(mob/user)
	var/search_title = input(user, "Enter the title (optional):") as text|null
	var/search_author = input(user, "Enter the author (optional):") as text|null
	var/search_category = input(user, "Select a category (optional):") in list("Any", "Myths & Tales", "Legends & Accounts", "Thesis", "Erotica") // Removed "Apocrypha & Grimoires"
	// Pass the selected parameters to search_manuscripts
	search_manuscripts(user, search_title, search_author, search_category)

/obj/machinery/printingpress/proc/search_manuscripts(mob/user, search_title, search_author, search_category)
	var/list/matching_books = SSlibrarian.get_books(search_title, search_author, search_category)
	var/list/available_books = SSlibrarian.pull_player_book_titles()

	var/list/book_data_to_filename = list()
	for(var/filename in available_books)
		var/list/book_data = SSlibrarian.file2playerbook(filename)
		if(book_data && book_data["book_title"])
			book_data_to_filename[json_encode(book_data)] = filename

	var/dat = "<h3>Manuscript Search Results:</h3><br>"
	dat += "<table><tr><th>Title</th><th>Author</th><th>Category</th><th>Print</th></tr>"

	for(var/list/book in matching_books)
		var/filename = book_data_to_filename[json_encode(book)]
		if(filename)
			dat += "<tr><td>[book["book_title"]]</td><td>[book["author"]]</td><td>[book["category"]]</td><td><a href='byond://?src=[REF(src)];print=1;filename=[url_encode(filename)]'>Print</a></td></tr>"

	if(!length(matching_books))
		dat += "<tr><td colspan='4'>No results found.</td></tr>"

	dat += "</table>"
	var/datum/browser/popup = new(user, "printing press", "Which book to print?", 460, 500)
	popup.set_content(dat)
	popup.open()

/obj/machinery/printingpress/Topic(href, href_list)
	if(printing)
		return
	if(href_list["painting_page"])
		show_painting_archive(usr, text2num(href_list["painting_page"]))
		return
	if(href_list["print_painting"])
		print_painting(usr, href_list["print_painting"])
		return
	if("print" in href_list)
		var/filename = SANITIZE_FILENAME(href_list["filename"])

		if(!SSlibrarian.player_book_exists(filename))
			to_chat(usr, span_notice("This book doesn't exist."))
			return

		start_printing(usr, "archive", filename)

#undef PRINTER_COOLDOWN
#undef PRINTING_TIME
#undef PAINTINGS_PER_PAGE
