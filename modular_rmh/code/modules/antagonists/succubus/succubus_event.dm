// Midround solo antag event, modeled on the vampire event's candidate-poll/ban/whitelist plumbing.
// Deliberately midround (not roundstart) with a conservative weight so the succubus isn't
// roundstart witch-hunt bait. Corruption/magic tags, no role restrictions.

/datum/round_event_control/antagonist/solo/succubus
	name = "Succubus"
	tags = list(
		TAG_CORRUPTION,
		TAG_MAGIC,
		TAG_VILLAIN,
	)
	roundstart = FALSE
	antag_flag = ROLE_SUCCUBUS
	shared_occurence_type = null

	weight = 5

	denominator = 25

	base_antags = 1
	maximum_antags = 1

	earliest_start = 30 MINUTES

	typepath = /datum/round_event/antagonist/solo/succubus
	antag_datum = /datum/antagonist/succubus

	restricted_roles = null

/datum/round_event_control/antagonist/solo/succubus/valid_for_map()
	if(SSmapping.config.map_name != "Voyage")
		return TRUE
	return FALSE

/datum/round_event/antagonist/solo/succubus
