/// Ratwood muzzle and expression choices use native descriptor slots.
/datum/mob_descriptor/face/gnoll
	abstract_type = /datum/mob_descriptor/face/gnoll
	suffix = "muzzle"

/datum/mob_descriptor/face/gnoll/long_muzzle
	name = "Long"
	prefix = "a"

/datum/mob_descriptor/face/gnoll/short_muzzle
	name = "Short"
	prefix = "a"

/datum/mob_descriptor/face/gnoll/broad_muzzle
	name = "Broad"
	prefix = "a"

/datum/mob_descriptor/face/gnoll/narrow_muzzle
	name = "Narrow"
	prefix = "a"

/datum/mob_descriptor/face/gnoll/scarred_muzzle
	name = "Scarred"
	prefix = "a"

/datum/mob_descriptor/face/gnoll/sharp_muzzle
	name = "Sharp"
	prefix = "a"

/datum/mob_descriptor/face/gnoll/worn_muzzle
	name = "Worn"
	prefix = "a"

/datum/mob_descriptor/face/gnoll/disfigured_muzzle
	name = "Disfigured"
	prefix = "a"

// Gnoll expressions — slot FACE_EXPRESSION; output e.g. "a predatory look"
/datum/mob_descriptor/face_exp/gnoll
	abstract_type = /datum/mob_descriptor/face_exp/gnoll
	suffix = "look"

/datum/mob_descriptor/face_exp/gnoll/alert
	name = "Alert"
	prefix = "an"

/datum/mob_descriptor/face_exp/gnoll/snarling
	name = "Snarling"
	prefix = "a"

/datum/mob_descriptor/face_exp/gnoll/predatory
	name = "Predatory"
	prefix = "a"

/datum/mob_descriptor/face_exp/gnoll/hollow
	name = "Hollow"
	prefix = "a"

/datum/mob_descriptor/face_exp/gnoll/fierce
	name = "Fierce"
	prefix = "a"

/datum/mob_descriptor/face_exp/gnoll/vacant
	name = "Vacant"
	prefix = "a"

/datum/mob_descriptor/face_exp/gnoll/groveling
	name = "Groveling"
	prefix = "a"

/datum/mob_descriptor/face_exp/gnoll/leering
	name = "Leering"
	prefix = "a"

/datum/mob_descriptor/stature/gnoll_champion
	name = "Gnoll"

/datum/mob_descriptor/stature/gnoll_champion/get_description(mob/living/described)
	return "gnoll"
