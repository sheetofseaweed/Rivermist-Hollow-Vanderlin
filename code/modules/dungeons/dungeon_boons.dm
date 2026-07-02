/// A run-scoped buff. Applied to every roster member while the run lives,
/// stripped on run end. Stat-based boons use named stat modifiers so they
/// never leak outside the dungeon.
/datum/dungeon_boon
	abstract_type = /datum/dungeon_boon
	var/name = "Boon"
	var/desc = "A blessing of the deep."
	/// Higher = more common in the pick-three offer
	var/weight = 10
	/// Domain tags matching /datum/dungeon_god_profile domains
	var/list/domains = list("fate")
	/// DUNGEON_BOON_* rarity this instance rolled (display + magnitude)
	var/rarity = DUNGEON_BOON_COMMON
	/// Effect multiplier set from rarity when the card is built
	var/magnitude = 1
	/// Synergy prerequisite boon types; synergies only appear via the dedicated
	/// offer slot once every prerequisite is held by the run
	var/list/requires

/datum/dungeon_boon/proc/get_mod_id(datum/dungeon_run/run)
	return "dungeon_boon_[type]_[REF(run)]"

/datum/dungeon_boon/proc/apply(datum/dungeon_run/run, mob/living/target)
	return

/datum/dungeon_boon/proc/remove(datum/dungeon_run/run, mob/living/target)
	return

/// Optional per-room hook, called for every active boon when a combat room clears.
/datum/dungeon_boon/proc/on_room_cleared(datum/dungeon_run/run, datum/pocket_dimension/dungeon/room)
	return

// -- Life --

/datum/dungeon_boon/vigor
	name = "Vigor of the Deep"
	desc = "Your flesh hardens against the dark. (+max health)"
	domains = list("life", "war")
	var/applied_amount = 25

/datum/dungeon_boon/vigor/apply(datum/dungeon_run/run, mob/living/target)
	if(!istype(target))
		return
	applied_amount = round(25 * magnitude)
	target.maxHealth += applied_amount
	target.health = min(target.health + applied_amount, target.maxHealth)

/datum/dungeon_boon/vigor/remove(datum/dungeon_run/run, mob/living/target)
	if(!istype(target))
		return
	target.maxHealth = max(1, target.maxHealth - applied_amount)
	target.health = min(target.health, target.maxHealth)

/datum/dungeon_boon/second_wind
	name = "Second Wind"
	desc = "Every victory knits your wounds. (heal on room clear)"
	domains = list("life")

/datum/dungeon_boon/second_wind/on_room_cleared(datum/dungeon_run/run, datum/pocket_dimension/dungeon/room)
	for(var/mob/living/member as anything in run.get_members_in_room(room))
		member.adjustBruteLoss(-round(10 * magnitude))
		member.adjustFireLoss(-round(10 * magnitude))

// -- Luck --

/datum/dungeon_boon/fortune
	name = "Fortune's Favor"
	desc = "Luck clings to you; the dungeon yields more. (+fortune)"
	domains = list("luck")

/datum/dungeon_boon/fortune/apply(datum/dungeon_run/run, mob/living/target)
	if(!istype(target))
		return
	target.set_stat_modifier(get_mod_id(run), STAT_FORTUNE, round(10 * magnitude))

/datum/dungeon_boon/fortune/remove(datum/dungeon_run/run, mob/living/target)
	if(!istype(target))
		return
	target.remove_stat_modifier(get_mod_id(run))

/datum/dungeon_boon/greed
	name = "Hunger for Motes"
	desc = "Slain guardians spill more light. (+mote drops)"
	domains = list("luck", "shadow")

/datum/dungeon_boon/greed/apply(datum/dungeon_run/run, mob/living/target)
	run.mote_multiplier = 1 + 0.5 * magnitude

/datum/dungeon_boon/greed/remove(datum/dungeon_run/run, mob/living/target)
	run.mote_multiplier = 1

// -- War --

/datum/dungeon_boon/edge
	name = "Battle Edge"
	desc = "Your blows land harder. (+strength)"
	domains = list("war")

/datum/dungeon_boon/edge/apply(datum/dungeon_run/run, mob/living/target)
	if(!istype(target))
		return
	target.set_stat_modifier(get_mod_id(run), STAT_STRENGTH, max(1, round(2 * magnitude)))

/datum/dungeon_boon/edge/remove(datum/dungeon_run/run, mob/living/target)
	if(!istype(target))
		return
	target.remove_stat_modifier(get_mod_id(run))

/datum/dungeon_boon/warding
	name = "Warding"
	desc = "You endure what should fell you. (+endurance)"
	domains = list("war", "craft")

/datum/dungeon_boon/warding/apply(datum/dungeon_run/run, mob/living/target)
	if(!istype(target))
		return
	target.set_stat_modifier(get_mod_id(run), STAT_ENDURANCE, max(1, round(2 * magnitude)))

/datum/dungeon_boon/warding/remove(datum/dungeon_run/run, mob/living/target)
	if(!istype(target))
		return
	target.remove_stat_modifier(get_mod_id(run))

// -- Nature --

/datum/dungeon_boon/fleetfoot
	name = "Fleetfoot"
	desc = "The dungeon's paths seem shorter. (+speed)"
	domains = list("nature", "shadow")

/datum/dungeon_boon/fleetfoot/apply(datum/dungeon_run/run, mob/living/target)
	if(!istype(target))
		return
	target.set_stat_modifier(get_mod_id(run), STAT_SPEED, max(1, round(1 * magnitude)))

/datum/dungeon_boon/fleetfoot/remove(datum/dungeon_run/run, mob/living/target)
	if(!istype(target))
		return
	target.remove_stat_modifier(get_mod_id(run))

// -- Shadow --

/datum/dungeon_boon/mote_magnet
	name = "Mote Magnet"
	desc = "Cleared rooms bleed extra light. (bonus motes on clear)"
	domains = list("shadow", "luck")

/datum/dungeon_boon/mote_magnet/on_room_cleared(datum/dungeon_run/run, datum/pocket_dimension/dungeon/room)
	run.award_motes(round(8 * magnitude), null)

// -- Fate --

/datum/dungeon_boon/echo_affinity
	name = "Echo Affinity"
	desc = "Your deeds crystallize more readily. (+echo conversion)"
	domains = list("fate")

/datum/dungeon_boon/echo_affinity/apply(datum/dungeon_run/run, mob/living/target)
	run.echo_conversion_bonus = 0.1 * magnitude

/datum/dungeon_boon/echo_affinity/remove(datum/dungeon_run/run, mob/living/target)
	run.echo_conversion_bonus = 0

// -- Synergies (guaranteed card once prerequisites are held) --

/datum/dungeon_boon/battle_luck
	name = "Battle Luck"
	desc = "Fortune rides your blade - strength and luck entwined."
	domains = list("war", "luck")
	requires = list(/datum/dungeon_boon/edge, /datum/dungeon_boon/fortune)

/datum/dungeon_boon/battle_luck/apply(datum/dungeon_run/run, mob/living/target)
	if(!istype(target))
		return
	target.set_stat_modifier(get_mod_id(run), list(STAT_STRENGTH = max(1, round(1 * magnitude)), STAT_FORTUNE = round(5 * magnitude)))

/datum/dungeon_boon/battle_luck/remove(datum/dungeon_run/run, mob/living/target)
	if(!istype(target))
		return
	target.remove_stat_modifier(get_mod_id(run))

/datum/dungeon_boon/martyrs_resolve
	name = "Martyr's Resolve"
	desc = "Suffering endured becomes strength shared."
	domains = list("life", "war")
	requires = list(/datum/dungeon_boon/vigor, /datum/dungeon_boon/second_wind)
	var/applied_amount = 15

/datum/dungeon_boon/martyrs_resolve/apply(datum/dungeon_run/run, mob/living/target)
	if(!istype(target))
		return
	applied_amount = round(15 * magnitude)
	target.maxHealth += applied_amount
	target.health = min(target.health + applied_amount, target.maxHealth)

/datum/dungeon_boon/martyrs_resolve/remove(datum/dungeon_run/run, mob/living/target)
	if(!istype(target))
		return
	target.maxHealth = max(1, target.maxHealth - applied_amount)
	target.health = min(target.health, target.maxHealth)

// -- Offer construction ------------------------------------------------------

/// Builds a weighted pool of non-synergy boon instances not already active.
/proc/get_dungeon_boon_choices(datum/dungeon_run/run, count = 3)
	var/list/pool = list()
	var/list/active_types = list()
	for(var/datum/dungeon_boon/active as anything in run.active_boons)
		active_types[active.type] = TRUE
	for(var/datum/dungeon_boon/boon_type as anything in subtypesof(/datum/dungeon_boon))
		if(IS_ABSTRACT(boon_type))
			continue
		if(active_types[boon_type])
			continue
		if(initial(boon_type.requires)) // synergies never roll normally
			continue
		pool += new boon_type
	var/list/chosen = list()
	while(length(pool) && length(chosen) < count)
		var/datum/dungeon_boon/picked = pick(pool)
		pool -= picked
		chosen += picked
	for(var/datum/dungeon_boon/leftover as anything in pool)
		qdel(leftover)
	return chosen

/// Returns an available synergy boon type whose prerequisites the run holds.
/proc/get_available_synergy(datum/dungeon_run/run)
	var/list/active_types = list()
	for(var/datum/dungeon_boon/active as anything in run.active_boons)
		active_types[active.type] = TRUE
	for(var/datum/dungeon_boon/boon_type as anything in subtypesof(/datum/dungeon_boon))
		if(IS_ABSTRACT(boon_type) || active_types[boon_type])
			continue
		var/list/needs = initial(boon_type.requires)
		if(!needs)
			continue
		var/satisfied = TRUE
		for(var/required_type in needs)
			if(!active_types[required_type])
				satisfied = FALSE
				break
		if(satisfied)
			return boon_type
	return null

/// Builds the full offer: branded, rarity-rolled cards from the watching gods.
/// Returns a list of ready boon instances; caller owns them (qdel the unpicked).
/proc/build_boon_offer(datum/dungeon_run/run, count = 3)
	var/list/datum/dungeon_boon/cards = get_dungeon_boon_choices(run, count)
	var/list/profiles = list()
	for(var/god_type in run.watching_god_types)
		for(var/datum/dungeon_god_profile/profile as anything in get_dungeon_god_profiles())
			if(profile.patron_type == god_type)
				profiles += profile
				break

	for(var/datum/dungeon_boon/card as anything in cards)
		var/datum/dungeon_god_profile/god
		if(length(profiles))
			// Prefer a watching god whose domains match this boon.
			var/list/matching = list()
			for(var/datum/dungeon_god_profile/profile as anything in profiles)
				for(var/domain in profile.domains)
					if(domain in card.domains)
						matching += profile
						break
			god = length(matching) ? pick(matching) : pick(profiles)
		card.rarity = run.roll_boon_rarity()
		card.magnitude = run.get_rarity_magnitude(card.rarity)
		var/rarity_tag = card.rarity == DUNGEON_BOON_COMMON ? "" : " ([capitalize(card.rarity)])"
		if(god)
			card.name = "[god.get_boon_prefix()] [card.name][rarity_tag]"
		else
			card.name = "[card.name][rarity_tag]"

	// A satisfied synergy claims the last card slot, Hades duo-boon style.
	var/synergy_type = get_available_synergy(run)
	if(synergy_type && length(cards))
		var/datum/dungeon_boon/replaced = cards[length(cards)]
		cards -= replaced
		qdel(replaced)
		var/datum/dungeon_boon/synergy = new synergy_type
		synergy.rarity = DUNGEON_BOON_RARE
		synergy.magnitude = run.get_rarity_magnitude(DUNGEON_BOON_RARE)
		synergy.name = "[synergy.name] (Synergy)"
		cards += synergy

	return cards

/// Offers a boon choice to a player; the chosen boon applies to the whole run.
/datum/dungeon_run/proc/offer_boon(mob/living/chooser)
	if(!istype(chooser) || !chooser.client)
		return
	var/list/datum/dungeon_boon/cards = build_boon_offer(src, 3)
	if(!length(cards))
		return
	var/list/by_name = list()
	for(var/datum/dungeon_boon/card as anything in cards)
		by_name["[card.name] — [card.desc]"] = card
	var/picked_label = tgui_input_list(chooser, "The watching gods offer a blessing. Choose one.", "Dungeon Boon", by_name)
	var/datum/dungeon_boon/chosen = by_name[picked_label]
	for(var/datum/dungeon_boon/card as anything in cards)
		if(card != chosen)
			qdel(card)
	if(!chosen)
		return
	add_boon(chosen)
	to_chat(chooser, span_nicegreen("The run is blessed: [chosen.name]."))

/// Break rooms and shrines route through the same offer.
/datum/dungeon_run/proc/offer_break_room_boon(mob/living/chooser)
	offer_boon(chooser)
