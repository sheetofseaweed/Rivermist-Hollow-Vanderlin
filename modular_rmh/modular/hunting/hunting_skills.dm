// Hunting & Tracking pack - the two new skills.
// Both are plain new subtypes of /datum/attribute/skill/misc, so no core skill file is touched.
// Granted by the hunter and ranger job sheets - see the pack README for the spread.

/datum/attribute/skill/misc/tracking
	name = "Tracking"
	desc = "Represents your character's ability to notice and interpret tracks left by people and animals. \
	The higher your skill in Tracking, the more likely you are to spot old or faint tracks, and the more \
	detail you can glean from them - which way they lead, what made them, and how the maker was moving."
	category = SKILL_CATEGORY_GENERAL
	governing_attribute = STAT_PERCEPTION
	default_attributes = list(
		STAT_PERCEPTION = -6,
	)
	difficulty = SKILL_DIFFICULTY_AVERAGE
	dreams = list(
		"...you crouch low over the muddy trail, fingers brushing the broken grass... something passed here, and not long ago...",
	)

/datum/attribute/skill/misc/hunting
	name = "Hunting"
	desc = "Represents your character's ability to follow the trail of a wild animal back to its source. \
	The higher your skill in Hunting, the faster you can read a trail, the fewer signs you need to find, \
	and the rarer the game you can run down."
	category = SKILL_CATEGORY_GENERAL
	governing_attribute = STAT_PERCEPTION
	default_attributes = list(
		STAT_PERCEPTION = -6,
		STAT_ENDURANCE = -4,
	)
	difficulty = SKILL_DIFFICULTY_AVERAGE
	dreams = list(
		"...you follow the broken twigs and the scattered earth, deeper into the woods, certain your quarry is close...",
	)
