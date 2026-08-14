/datum/book_entry/attunement
	name = "Gate Improvements"

/datum/book_entry/attunement/inner_book_html(mob/user)
	var/html = {"
		<div>
		<h2>What are gates?</h2>
		Gates are pathways in your body in which mana travels, every spell has gates where the mana travels.<br>
		The stronger your gate is the more mana that can flow through it and the less is lost travelling.<br>
		</div>
		<br>

		<div>
		<h2> How to improve your gates </h2>
		The simpliest way to improve your gate is through the Attunement Ritual. <br>
		It uses items that have internal energy inside of them and breaks it down infusing it into your body. <br>
		Its not without its drawbacks, since it has strong internal energy it degrades its opposing gates. <br>
		<br>
		The other way is to socket a gem into your griomire which will cause your gateway to strength while studying. <br>
		This doesn't have the downside of breaking down your opposing gates but is slower. <br>
		<br>
		The final way is the god you worship. All the gods bestow their blessing into you improving their respective gates.
		</div>
		<br>

		<div>
		<h2> Items with internal energy </h2>
	"}

	html += attunement_listing(user, subtypesof(/obj/item/natural))
	html += attunement_listing(user, subtypesof(/obj/item/alch))

	return html

/// Lists every type in item_types carrying attunement values, probed via a throwaway instance.
/datum/book_entry/attunement/proc/attunement_listing(mob/user, list/item_types)
	var/html = ""
	for(var/obj/item/item_type as anything in item_types)
		// initial() reads null on list vars, so the values only exist on a real instance
		var/obj/item/item = new item_type
		if(QDELETED(item)) // some types delete themselves during Initialize
			continue
		if(length(item.attunement_values))
			html += "<h3>[item.name]</h3><br>"
			html += "[icon2html(item, user)]<br>"
			for(var/datum/attunement/attunement as anything in item.attunement_values)
				if(item.attunement_values[attunement] > 0)
					html += "[initial(attunement.name)] - Increase<br>"
				else
					html += "[initial(attunement.name)] - Decrease<br>"
		qdel(item)
	return html
