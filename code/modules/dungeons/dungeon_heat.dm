/// A voluntary difficulty dial (Pact of Punishment style). Stateless shared
/// singletons; the chosen ranks live on the entrance (pending) and the run.
/datum/dungeon_heat_dial
	abstract_type = /datum/dungeon_heat_dial
	var/id = ""
	var/name = "Dial"
	var/desc = ""
	var/max_rank = 1

/datum/dungeon_heat_dial/hardened
	id = DUNGEON_HEAT_HARDENED
	name = "Hardened Foes"
	desc = "Guardians endure far more punishment. (+25% / +50% health)"
	max_rank = 2

/datum/dungeon_heat_dial/elites
	id = DUNGEON_HEAT_ELITES
	name = "Elite Presence"
	desc = "Champions stalk the halls more often. (+10% / +20% elite chance)"
	max_rank = 2

/datum/dungeon_heat_dial/cruel
	id = DUNGEON_HEAT_CRUEL
	name = "Cruel Architecture"
	desc = "The rooms themselves turn against you. (75% / 100% trait chance)"
	max_rank = 2

/datum/dungeon_heat_dial/forced_march
	id = DUNGEON_HEAT_FORCED_MARCH
	name = "Forced March"
	desc = "Places of respite grow further apart. (+1 / +2 rooms per stretch)"
	max_rank = 2

/datum/dungeon_heat_dial/iron_contract
	id = DUNGEON_HEAT_IRON_CONTRACT
	name = "Iron Contract"
	desc = "A fallen party is given almost no time to rise. (wipe grace 30s → 10s)"
	max_rank = 1

/datum/dungeon_heat_dial/sealed_mercy
	id = DUNGEON_HEAT_SEALED_MERCY
	name = "Sealed Mercy"
	desc = "No door beyond will ever promise healing."
	max_rank = 1

GLOBAL_LIST_EMPTY(dungeon_heat_dial_singletons)

/proc/get_dungeon_heat_dials()
	if(!length(GLOB.dungeon_heat_dial_singletons))
		for(var/datum/dungeon_heat_dial/dial_type as anything in subtypesof(/datum/dungeon_heat_dial))
			if(IS_ABSTRACT(dial_type))
				continue
			GLOB.dungeon_heat_dial_singletons += new dial_type
	return GLOB.dungeon_heat_dial_singletons

// -- Run-side heat reads ------------------------------------------------------

/datum/dungeon_run/proc/get_heat_rank(dial_id)
	return heat_ranks?[dial_id] || 0

/datum/dungeon_run/proc/get_total_heat()
	var/total = 0
	for(var/dial_id in heat_ranks)
		total += heat_ranks[dial_id]
	return total

/// Base conversion + Echo Affinity boon + heat pact bonus. The single source
/// of truth for every mote->echo conversion in the run.
/datum/dungeon_run/proc/get_echo_conversion()
	return DUNGEON_ECHO_CONVERSION + echo_conversion_bonus + get_total_heat() * DUNGEON_HEAT_ECHO_BONUS

/datum/dungeon_run/proc/get_heat_hp_mult()
	return 1 + get_heat_rank(DUNGEON_HEAT_HARDENED) * 0.25

/datum/dungeon_run/proc/get_heat_elite_bonus()
	return get_heat_rank(DUNGEON_HEAT_ELITES) * 10

/// The floor's trait chance, escalated by Cruel Architecture (75 / 100).
/datum/dungeon_run/proc/get_trait_chance()
	var/base = floor_config ? floor_config.trait_chance : DUNGEON_ROOM_TRAIT_CHANCE
	switch(get_heat_rank(DUNGEON_HEAT_CRUEL))
		if(1)
			return max(base, 75)
		if(2)
			return 100
	return base

/datum/dungeon_run/proc/get_wipe_grace()
	return get_heat_rank(DUNGEON_HEAT_IRON_CONTRACT) ? DUNGEON_WIPE_GRACE_IRON : DUNGEON_WIPE_GRACE
