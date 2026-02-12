//traits with no real impact that can be taken freely
//MAKE SURE THESE DO NOT MAJORLY IMPACT GAMEPLAY. those should be positive or negative traits.

/datum/quirk/monsterhuntermale
	name = "Monster Seeker (Males)"
	desc = "Allows targeting by specific monsters (such as werewolves, goblins and minotaurs etc.) for something very lewd. May be unfair to you in combat. Male monsters lust for me..."
	value = 0

/datum/quirk/monsterhunterfemale
	name = "Monster Seeker (Females)"
	desc = "Allows targeting by specific monsters (such as werewolves, goblins and minotaurs etc.) for something very lewd. May be unfair to you in combat. Female monsters lust for me... "
	value = 0

/datum/quirk/selfawaregeni
	name = "Sensitiveness"
	desc = "I can tell more about my private bits (may be spammy, exact liquid information and alerts etc.)"
	value = 0

//damn snowflakes.
/*/datum/quirk/weirdo
	name = "Freeky"
	desc = "I can use my 'orifices' to store things and do more strange sexual things that wouldn't come to sane mind."
	value = 0*/

/datum/quirk/virgin
	name = "Virgin"
	desc = "I am a virgin, whether truly, by magic or plot holes. Vampires and cultists are likely to lust for my blood."
	value = 0
	gain_text = span_notice("I am a virgin.")

/datum/quirk/virgin/on_spawn()
	var/mob/living/carbon/human/H = quirk_holder
	H.virginity = TRUE
	ADD_TRAIT(H, TRAIT_NUTCRACKER, TRAIT_GENERIC)
