/// A dark power's altar: two epic boons, each priced in flesh or curses.
/// Grows in floor-2+ break rooms. Menu stays tgui_input_list (shrine-consistent).
/obj/structure/dungeon_bargain_altar
	name = "black-veined altar"
	desc = "An altar of dark stone, warm to the touch. Something on the far side of it is listening."
	icon = 'icons/roguetown/misc/structure.dmi'
	icon_state = "closet3"
	density = TRUE
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	var/datum/dungeon_run/owning_run
	/// "Shar" or "Asmodeus" - flavor only
	var/patron_name
	/// list of entries: list("boon" = /datum/dungeon_boon, "price" = "flesh"|"curse", "bought" = FALSE)
	var/list/offers = list()

/obj/structure/dungeon_bargain_altar/Initialize()
	. = ..()
	patron_name = pick("Shar", "Asmodeus")

/obj/structure/dungeon_bargain_altar/Destroy()
	for(var/list/offer as anything in offers)
		var/datum/dungeon_boon/boon = offer["boon"]
		if(boon && !QDELETED(boon))
			qdel(boon)
	offers = null
	owning_run = null
	return ..()

/obj/structure/dungeon_bargain_altar/examine(mob/user)
	. = ..()
	if(!count_open_offers())
		. += span_warning("It is spent. Whatever listened here has gone.")
	else
		. += span_warning("[patron_name] is listening. Touch it to hear the bargain.")

/obj/structure/dungeon_bargain_altar/proc/count_open_offers()
	var/open = 0
	for(var/list/offer as anything in offers)
		if(!offer["bought"])
			open++
	return open

/// Builds two offers from the dark pool, skipping boons the run already holds.
/obj/structure/dungeon_bargain_altar/proc/build_offers()
	if(!owning_run)
		return
	var/list/pool = list()
	var/list/active_types = list()
	for(var/datum/dungeon_boon/active as anything in owning_run.active_boons)
		active_types[active.type] = TRUE
	for(var/datum/dungeon_boon/boon_type as anything in subtypesof(/datum/dungeon_boon/dark))
		if(IS_ABSTRACT(boon_type) || active_types[boon_type])
			continue
		pool += boon_type
	for(var/i in 1 to 2)
		if(!length(pool))
			break
		var/picked_type = pick(pool)
		pool -= picked_type
		var/datum/dungeon_boon/boon = new picked_type
		boon.rarity = DUNGEON_BOON_EPIC
		boon.magnitude = owning_run.get_rarity_magnitude(DUNGEON_BOON_EPIC)
		boon.god_brand = (patron_name == "Shar") ? "Shar's" : "Asmodeus's"
		offers += list(list("boon" = boon, "price" = pick("flesh", "curse"), "bought" = FALSE))

/obj/structure/dungeon_bargain_altar/proc/get_price_text(price)
	if(price == "flesh")
		return "a [DUNGEON_BARGAIN_FLESH_CUT * 100]% cut of every member's vitality, until the run ends"
	return "[DUNGEON_BARGAIN_CURSE_ROOMS] cursed rooms somewhere ahead"

/obj/structure/dungeon_bargain_altar/attack_hand(mob/user, list/modifiers)
	. = ..()
	open_bargain_menu(user)

/obj/structure/dungeon_bargain_altar/proc/open_bargain_menu(mob/living/user)
	if(!istype(user) || !user.client || !owning_run || QDELETED(owning_run))
		return
	if(!count_open_offers())
		to_chat(user, span_warning("The altar is spent."))
		return
	var/list/by_label = list()
	for(var/list/offer as anything in offers)
		if(offer["bought"])
			continue
		var/datum/dungeon_boon/boon = offer["boon"]
		by_label["[boon.get_display_name()] — [boon.desc] | PRICE: [get_price_text(offer["price"])]"] = offer
	var/picked = tgui_input_list(user, "[patron_name] offers power. Every bargain has its price.", "Dark Bargain", by_label)
	var/list/chosen = by_label[picked]
	if(!chosen || chosen["bought"] || QDELETED(src) || !owning_run || QDELETED(owning_run))
		return
	purchase(chosen, user)

/obj/structure/dungeon_bargain_altar/proc/purchase(list/offer, mob/living/user)
	offer["bought"] = TRUE
	var/datum/dungeon_boon/boon = offer["boon"]
	offer["boon"] = null // Destroy() must not qdel an applied boon
	switch(offer["price"])
		if("flesh")
			owning_run.add_boon(new /datum/dungeon_boon/dark_price/flesh)
			owning_run.notify_roster("[user.real_name || user.name] has bargained with [patron_name] - the price is paid in everyone's flesh!", "userdanger")
		if("curse")
			owning_run.cursed_rooms_owed += DUNGEON_BARGAIN_CURSE_ROOMS
			owning_run.notify_roster("[user.real_name || user.name] has bargained with [patron_name] - a curse now waits in the rooms ahead!", "userdanger")
	owning_run.add_boon(boon)
	to_chat(user, span_nicegreen("The bargain is struck: [boon.get_display_name()]."))
	visible_message(span_warning("The altar's black veins pulse once, and go still."))
	if(!count_open_offers())
		name = "spent altar"
		desc = "Cold, dead stone. Whatever listened here has taken what it came for."
