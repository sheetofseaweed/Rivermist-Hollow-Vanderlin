/**
 * Identifying what's in a container.
 *
 * Base game only lets the dead and silicons read a container's exact contents;
 * a living character sees the vague "it contains something" line no matter how
 * skilled they are. A trained palate - either the Cicerone quirk or a skilled
 * cook or alchemist - can now name what's in the cup, but only up close: you
 * have to be near enough to smell it.
 *
 * Sealed containers (barrels, kegs) stay unreadable by design - pour some out
 * into a cup first.
 */

#define TRAIT_CICERONE "Cicerone"

/// Skill rank at which a character can identify reagents unaided.
#define CICERONE_SKILL_RANK SKILL_RANK_EXPERT

/mob/living/can_see_reagents(atom/target)
	. = ..()
	if(.)
		return
	// A nose, not x-ray vision: only works within reach.
	if(!target || get_dist(get_turf(target), get_turf(src)) > 1)
		return FALSE
	if(HAS_TRAIT(src, TRAIT_CICERONE))
		return TRUE
	if(!mind)
		return FALSE
	if(GET_MOB_SKILL_VALUE_OLD(src, /datum/attribute/skill/craft/cooking) >= CICERONE_SKILL_RANK)
		return TRUE
	if(GET_MOB_SKILL_VALUE_OLD(src, /datum/attribute/skill/craft/alchemy) >= CICERONE_SKILL_RANK)
		return TRUE

/datum/quirk/boon/cicerone
	name = "Cicerone"
	desc = "A lifetime spent around pots, casks, and apothecary shelves has sharpened your palate. A sip or a sniff is all it takes for you to name what's in a cup or bottle."
	point_value = -4

/datum/quirk/boon/cicerone/on_spawn()
	ADD_TRAIT(owner, TRAIT_CICERONE, "[type]")

/datum/quirk/boon/cicerone/on_remove()
	if(owner)
		REMOVE_TRAIT(owner, TRAIT_CICERONE, "[type]")

#undef CICERONE_SKILL_RANK
