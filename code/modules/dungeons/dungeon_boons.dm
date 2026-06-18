/// A run-scoped buff. Applied to every roster member while the run lives,
/// stripped on run end. Stat-based boons use named stat modifiers so they
/// never leak outside the dungeon.
/datum/dungeon_boon
	var/name = "Boon"
	var/desc = "A blessing of the deep."
	/// Higher = more common in the pick-three offer
	var/weight = 10

/datum/dungeon_boon/proc/get_mod_id(datum/dungeon_run/run)
	return "dungeon_boon_[type]_[REF(run)]"

/datum/dungeon_boon/proc/apply(datum/dungeon_run/run, mob/living/target)
	return

/datum/dungeon_boon/proc/remove(datum/dungeon_run/run, mob/living/target)
	return

/datum/dungeon_boon/vigor
	name = "Vigor of the Deep"
	desc = "Your flesh hardens against the dark. (+max health)"

/datum/dungeon_boon/vigor/apply(datum/dungeon_run/run, mob/living/target)
	if(!istype(target))
		return
	target.maxHealth += 25
	target.health = min(target.health + 25, target.maxHealth)

/datum/dungeon_boon/vigor/remove(datum/dungeon_run/run, mob/living/target)
	if(!istype(target))
		return
	target.maxHealth = max(1, target.maxHealth - 25)
	target.health = min(target.health, target.maxHealth)

/datum/dungeon_boon/fortune
	name = "Fortune's Favor"
	desc = "Luck clings to you; the dungeon yields more. (+fortune)"

/datum/dungeon_boon/fortune/apply(datum/dungeon_run/run, mob/living/target)
	if(!istype(target))
		return
	target.set_stat_modifier(get_mod_id(run), STAT_FORTUNE, 10)

/datum/dungeon_boon/fortune/remove(datum/dungeon_run/run, mob/living/target)
	if(!istype(target))
		return
	target.remove_stat_modifier(get_mod_id(run))

/datum/dungeon_boon/greed
	name = "Hunger for Motes"
	desc = "Slain guardians spill more light. (+mote drops)"

/datum/dungeon_boon/greed/apply(datum/dungeon_run/run, mob/living/target)
	run.mote_multiplier = 1.5 // shared run flag; see award_motes

/datum/dungeon_boon/greed/remove(datum/dungeon_run/run, mob/living/target)
	run.mote_multiplier = 1

// -- Break-room boon offer ---------------------------------------------------

/// Builds a weighted pool of boon instances not already active (non-stackable).
/proc/get_dungeon_boon_choices(datum/dungeon_run/run, count = 3)
	var/list/pool = list()
	var/list/active_types = list()
	for(var/datum/dungeon_boon/active as anything in run.active_boons)
		active_types[active.type] = TRUE
	for(var/boon_type in subtypesof(/datum/dungeon_boon))
		if(active_types[boon_type])
			continue
		var/datum/dungeon_boon/boon = new boon_type
		if(!boon.name || boon.name == "Boon")
			qdel(boon)
			continue
		pool += boon
	var/list/chosen = list()
	while(length(pool) && length(chosen) < count)
		var/datum/dungeon_boon/picked = pick(pool)
		pool -= picked
		chosen += picked
	for(var/datum/dungeon_boon/leftover as anything in pool)
		qdel(leftover)
	return chosen

/// Offers a break-room boon choice to a player; the chosen boon applies to the
/// whole run roster.
/datum/dungeon_run/proc/offer_break_room_boon(mob/living/chooser)
	if(!istype(chooser) || !chooser.client)
		return
	var/list/datum/dungeon_boon/choices = get_dungeon_boon_choices(src, 3)
	if(!length(choices))
		return
	var/list/by_name = list()
	for(var/datum/dungeon_boon/boon as anything in choices)
		by_name["[boon.name] — [boon.desc]"] = boon
	var/picked_label = tgui_input_list(chooser, "The respite offers a blessing. Choose one.", "Dungeon Boon", by_name)
	var/datum/dungeon_boon/chosen = by_name[picked_label]
	for(var/datum/dungeon_boon/boon as anything in choices)
		if(boon != chosen)
			qdel(boon)
	if(!chosen)
		return
	add_boon(chosen)
	to_chat(chooser, span_nicegreen("The run is blessed: [chosen.name]."))
