// (included via vanderlin.dme)
/datum/dungeon_cosmetic
	var/id = "base"
	var/name = "Cosmetic"
	var/desc = ""
	var/echo_cost = 50
	/// "title" cosmetics provide an examinable suffix
	var/cosmetic_kind = "title"
	/// For titles: the suffix text, e.g. "Delver of the Deep"
	var/title_text

/datum/dungeon_cosmetic/title_delver
	id = "title_delver"
	name = "Title: Delver"
	desc = "Be known as a Delver of the Deep."
	echo_cost = 50
	title_text = "Delver of the Deep"

/datum/dungeon_cosmetic/title_breaker
	id = "title_breaker"
	name = "Title: Breaker of Floors"
	desc = "Be known as a Breaker of Floors."
	echo_cost = 200
	title_text = "Breaker of Floors"

/proc/get_dungeon_cosmetic_catalogue()
	var/list/catalogue = list()
	for(var/cosmetic_type in subtypesof(/datum/dungeon_cosmetic))
		var/datum/dungeon_cosmetic/cosmetic = new cosmetic_type
		if(cosmetic.id == "base")
			qdel(cosmetic)
			continue
		catalogue += cosmetic
	return catalogue

/proc/get_dungeon_cosmetic_by_id(cosmetic_id)
	for(var/cosmetic_type in subtypesof(/datum/dungeon_cosmetic))
		var/datum/dungeon_cosmetic/cosmetic = new cosmetic_type
		if(cosmetic.id == cosmetic_id)
			return cosmetic
		qdel(cosmetic)
	return null

/mob/living/carbon/human/examine(mob/user)
	. = ..()
	if(!ckey)
		return
	var/datum/dungeon_progress/progress = GLOB.player_dungeon_progress[ckey]
	if(!progress || !progress.selected_title)
		return
	var/datum/dungeon_cosmetic/cosmetic = get_dungeon_cosmetic_by_id(progress.selected_title)
	if(cosmetic?.title_text)
		. += span_notice("<b>[src.name], [cosmetic.title_text].</b>")
	qdel(cosmetic)
