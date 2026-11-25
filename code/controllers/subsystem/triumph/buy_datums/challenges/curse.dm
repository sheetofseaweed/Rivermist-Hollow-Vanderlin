/datum/triumph_buy/random_curse
	name = "Random Curse"
	desc = "Become cursed by a random deity different from your patron. Curse effects vary from deity to deity."
	triumph_buy_id = TRIUMPH_BUY_CURSE
	triumph_cost = 0
	category = TRIUMPH_CAT_CHALLENGES
	visible_on_active_menu = TRUE
	manual_activation = TRUE
	var/list/patron_curse_map = list(
		/datum/patron/faerun/good_gods/Lathander = /datum/curse/astrata,
		/datum/patron/faerun/neutral_gods/Tempus = /datum/curse/ravox,
		/datum/patron/faerun/neutral_gods/Jergal = /datum/curse/necra,
		/datum/patron/faerun/neutral_gods/Tymora = /datum/curse/xylix,
		/datum/patron/faerun/good_gods/Ilmater = /datum/curse/pestra,
		/datum/patron/faerun/good_gods/Sune = /datum/curse/eora,
		/datum/patron/faerun/evil_gods/Lolth = /datum/curse/zizo/minor,
		/datum/patron/faerun/evil_gods/Mask = /datum/curse/matthios,
		/datum/patron/faerun/evil_gods/Blissara = /datum/curse/baotha,
		/datum/patron/faerun/evil_gods/shattered_idol = /datum/curse/zizo/minor,
	)

/datum/triumph_buy/random_curse/on_after_spawn(mob/living/carbon/human/H)
	. = ..()

	var/list/available_curses = (TEN_CURSES + INHUMEN_CURSES) - list(/datum/curse/noc, /datum/curse/graggar, /datum/curse/zizo)

	if(H.patron && patron_curse_map[H.patron.type])
		var/datum/curse/patron_curse = patron_curse_map[H.patron.type]
		available_curses -= patron_curse

	if(!length(available_curses))
		return

	var/selected_curse_type = pick(available_curses)
	H.add_curse(selected_curse_type)

	on_activate()
