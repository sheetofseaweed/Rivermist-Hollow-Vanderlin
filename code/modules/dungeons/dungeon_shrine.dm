/obj/structure/dungeon_shrine
	name = "shrine of respite"
	desc = "A worn altar that trades the dungeon's own light for small mercies."
	icon = 'icons/roguetown/misc/structure.dmi'
	icon_state = "closet3"
	density = TRUE
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	/// The run this shrine belongs to
	var/datum/dungeon_run/owning_run

/obj/structure/dungeon_shrine/Destroy()
	owning_run = null
	return ..()

/obj/structure/dungeon_shrine/examine(mob/user)
	. = ..()
	if(owning_run)
		. += span_notice("It hums with [owning_run.motes] motes of stored light. Touch it to barter.")

/obj/structure/dungeon_shrine/attack_hand(mob/user, list/modifiers)
	. = ..()
	open_shrine_menu(user)

/obj/structure/dungeon_shrine/proc/open_shrine_menu(mob/living/user)
	if(!istype(user) || !user.client || !owning_run)
		return
	var/list/options = build_shrine_offers()
	var/list/by_label = list()
	for(var/list/offer as anything in options)
		by_label["[offer["label"]] ([offer["cost"]] motes)"] = offer
	var/picked = tgui_input_list(user, "The shrine offers (you have [owning_run.motes] motes):", "Shrine of Respite", by_label)
	var/list/chosen = by_label[picked]
	if(!chosen)
		return
	if(!owning_run.spend_motes(chosen["cost"]))
		to_chat(user, span_warning("Not enough motes."))
		return
	apply_shrine_offer(chosen["id"], user)

/obj/structure/dungeon_shrine/proc/build_shrine_offers()
	var/floor = owning_run?.floor || 1
	return list(
		list("id" = "heal", "label" = "Mend wounds", "cost" = 20),
		list("id" = "boon", "label" = "Beg a blessing (extra boon)", "cost" = 60),
		list("id" = "cache", "label" = "Conjure a cache roll", "cost" = 40 + floor * 10),
		list("id" = "bank", "label" = "Bank motes as echoes now", "cost" = 0),
	)

/obj/structure/dungeon_shrine/proc/apply_shrine_offer(id, mob/living/user)
	switch(id)
		if("heal")
			user.adjustBruteLoss(-40)
			user.adjustFireLoss(-40)
			to_chat(user, span_nicegreen("The shrine's light knits your wounds."))
		if("boon")
			owning_run.offer_break_room_boon(user)
		if("cache")
			var/datum/loot_table/debug/table = new
			table.spawn_loot(user, owning_run.floor, user.return_item_rarity())
			qdel(table)
			to_chat(user, span_nicegreen("The shrine spits out a reward."))
		if("bank")
			owning_run.bank_motes_now(user)
