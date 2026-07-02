// The Faerûn gaze: each infinite run is watched by three gods whose domains
// shape the boons on offer. Worship matters — a god with faithful in the
// descending party is far likelier to watch, and evil gods only watch parties
// that carry at least one of their own.

/// Maps a /datum/patron/faerun/* god to the boon domains it offers.
/datum/dungeon_god_profile
	abstract_type = /datum/dungeon_god_profile
	/// The patron this profile speaks for
	var/patron_type
	/// Boon domain tags this god can bless (see /datum/dungeon_boon/domains)
	var/list/domains = list("fate")
	/// Possessive brand on boon cards; defaults to "[god name]'s"
	var/boon_prefix_override

// -- War --
/datum/dungeon_god_profile/tempus
	patron_type = /datum/patron/faerun/neutral_gods/Tempus
	domains = list("war")

/datum/dungeon_god_profile/tyr
	patron_type = /datum/patron/faerun/good_gods/Tyr
	domains = list("war", "fate")

/datum/dungeon_god_profile/torm
	patron_type = /datum/patron/faerun/good_gods/Torm
	domains = list("war", "life")

/datum/dungeon_god_profile/gruumsh
	patron_type = /datum/patron/faerun/evil_gods/Gruumsh
	domains = list("war")

// -- Luck --
/datum/dungeon_god_profile/tymora
	patron_type = /datum/patron/faerun/neutral_gods/Tymora
	domains = list("luck")

// -- Life --
/datum/dungeon_god_profile/ilmater
	patron_type = /datum/patron/faerun/good_gods/Ilmater
	domains = list("life")

/datum/dungeon_god_profile/lathander
	patron_type = /datum/patron/faerun/good_gods/Lathander
	domains = list("life", "fate")

// -- Shadow --
/datum/dungeon_god_profile/shar
	patron_type = /datum/patron/faerun/evil_gods/Shar
	domains = list("shadow")

/datum/dungeon_god_profile/lolth
	patron_type = /datum/patron/faerun/evil_gods/Lolth
	domains = list("shadow", "war")

/datum/dungeon_god_profile/mask
	patron_type = /datum/patron/faerun/evil_gods/Mask
	domains = list("shadow", "luck")

// -- Nature --
/datum/dungeon_god_profile/mielikki
	patron_type = /datum/patron/faerun/good_gods/Mielikki
	domains = list("nature")

/datum/dungeon_god_profile/silvanus
	patron_type = /datum/patron/faerun/neutral_gods/Silvanus
	domains = list("nature", "life")

/datum/dungeon_god_profile/malar
	patron_type = /datum/patron/faerun/evil_gods/Malar
	domains = list("nature", "war")

// -- Craft --
/datum/dungeon_god_profile/moradin
	patron_type = /datum/patron/faerun/good_gods/Moradin
	domains = list("craft", "war")

// -- Fate --
/datum/dungeon_god_profile/mystra
	patron_type = /datum/patron/faerun/neutral_gods/Mystra
	domains = list("fate")

/datum/dungeon_god_profile/selune
	patron_type = /datum/patron/faerun/good_gods/Selune
	domains = list("fate", "life")

/datum/dungeon_god_profile/oghma
	patron_type = /datum/patron/faerun/neutral_gods/Oghma
	domains = list("fate", "craft")

GLOBAL_LIST_EMPTY(dungeon_god_profiles)

/proc/build_dungeon_god_profiles()
	GLOB.dungeon_god_profiles = list()
	for(var/datum/dungeon_god_profile/profile_type as anything in subtypesof(/datum/dungeon_god_profile))
		if(IS_ABSTRACT(profile_type))
			continue
		var/datum/dungeon_god_profile/profile = new profile_type
		if(!ispath(profile.patron_type, /datum/patron))
			qdel(profile)
			continue
		GLOB.dungeon_god_profiles += profile

/proc/get_dungeon_god_profiles()
	if(!length(GLOB.dungeon_god_profiles))
		build_dungeon_god_profiles()
	return GLOB.dungeon_god_profiles

/// Weighted pool of watching-god candidates for a party. Base weight per god;
/// +40 per present member who worships them; evil gods need >= 1 worshipper.
/proc/get_watching_god_weights(list/mob/living/members)
	var/list/weights = list()
	for(var/datum/dungeon_god_profile/profile as anything in get_dungeon_god_profiles())
		var/worshippers = 0
		for(var/mob/living/member as anything in members)
			if(QDELETED(member) || !member.patron)
				continue
			if(member.patron.type == profile.patron_type)
				worshippers++
		if(ispath(profile.patron_type, /datum/patron/faerun/evil_gods) && !worshippers)
			continue // dark gods only watch parties carrying their faithful
		weights[profile] = 10 + worshippers * 40
	return weights

/// Rolls `count` distinct watching gods for a run.
/proc/roll_watching_gods(list/mob/living/members, count = 3)
	var/list/weights = get_watching_god_weights(members)
	var/list/datum/dungeon_god_profile/chosen = list()
	while(length(weights) && length(chosen) < count)
		var/datum/dungeon_god_profile/picked = pickweight(weights)
		weights -= picked
		chosen += picked
	return chosen

/datum/dungeon_god_profile/proc/get_god_name()
	var/datum/patron/patron = GLOB.patron_list[patron_type]
	return patron?.name || "an unknown god"

/datum/dungeon_god_profile/proc/get_boon_prefix()
	return boon_prefix_override || "[get_god_name()]'s"
