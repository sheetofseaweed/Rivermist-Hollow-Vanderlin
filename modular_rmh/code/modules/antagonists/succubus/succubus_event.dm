// Succubus antagonist core — midround solo antag event (Task 6)
// See docs/superpowers/plans/2026-07-17-succubus-core.md
//
// Structural mirror of code/modules/events/antagonist/solo/vampires.dm: same candidate-poll +
// ban/whitelist mechanics, inherited unmodified from /datum/round_event_control/antagonist/solo's
// get_candidates() (gates on antag_flag through SSgamemode.get_candidates(), exactly like the
// vampire event), same Voyage exclusion, half the vampire event's weight. Deviations from a
// literal copy (flagged in the Task 6/7 final report):
//   - roundstart is FALSE with a midround earliest_start, not TRUE/0 SECONDS like vampires.dm —
//     spec (docs/superpowers/specs/2026-07-17-succubus-antag-design.md) §10 is explicit: "Spawn
//     mid-round via antag event (vampire-event precedent), never roundstart witch-hunt bait."
//     vampires.dm is itself a roundstart event, so this one field cannot be mirrored verbatim;
//     30 MINUTES matches this codebase's only other live midround solo-antag precedents
//     (daewalker.dm, maniac's /midround variant).
//   - maximum_antags is 1 ("one candidate" per plan), not 4.
//   - restricted_roles is null: vampire excludes Lord/Captain because "Vampire Lord" displaces the
//     town's political leadership narratively; nothing in the succubus design calls for the same
//     exclusion, and null is the majority precedent among the other solo villain events (lich only
//     restricts Lord, rebel/zizo_cult restrict nothing) — this is not a vampire-only pattern.
//   - tags swap TAG_BLOOD -> TAG_CORRUPTION (matches the essence "corruption multiplier" concept)
//     and drop TAG_COMBAT (spec §10: "King-of-RP, not King-of-Combat"); TAG_MAGIC added for the
//     spellcasting kit.
//   - shared_occurence_type is null, matching this codebase's midround-event precedent
//     (daewalker.dm, maniac/midround) rather than vampire's SHARED_HIGH_THREAT (a roundstart-batch
//     throttle that doesn't apply the same way to a dynamically-triggered midround pick).
// No lord/spawn split exists for succubus, so no add_datum_to_mind() override is needed: the base
// class's default (antag_mind.add_antag_datum(antag_datum)) already does exactly "add
// /datum/antagonist/succubus to their mind" per the plan.

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
