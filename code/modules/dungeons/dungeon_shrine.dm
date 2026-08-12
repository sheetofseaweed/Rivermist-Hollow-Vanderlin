/obj/structure/dungeon_shrine
	name = "shrine of respite"
	desc = "A worn altar that trades the dungeon's own light for small mercies."
	icon = 'icons/roguetown/misc/tallstructure.dmi'
	icon_state = "subduedstatue_hasring"
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
	// Validate before charging - nothing here refunds.
	if(!can_buy_offer(chosen["id"], user))
		return
	if(!owning_run.try_pay_offer(chosen["cost"]))
		to_chat(user, span_warning("Not enough motes."))
		return
	apply_shrine_offer(chosen["id"], user)

/// Pre-payment gate for offers that can be bought pointlessly.
/obj/structure/dungeon_shrine/proc/can_buy_offer(id, mob/living/user)
	if(id == "repair")
		if(length(get_damaged_worn_armor(user)))
			return TRUE
		to_chat(user, span_warning("The light finds no damaged armor upon you."))
		return FALSE
	if(id != "revive")
		return TRUE
	if(!user.has_any_defeat_trauma())
		to_chat(user, span_warning("The light searches you and finds nothing lingering to undo."))
		return FALSE
	// Grievous Wounds are town-clinic-only by design. Carrying nothing else
	// means there is nothing here to buy - say so instead of taking the motes.
	if(!has_treatable_trauma(user))
		to_chat(user, span_warning("The shrine's light washes over you and recoils. This place mends lesser hurts; it cannot touch maiming this deep - only a healer's hands at the town clinic can set you right."))
		return FALSE
	return TRUE

/// The hurt this shrine would lift, or null. Grievous Wounds are town-clinic
/// only by design, so they are never chosen - and because the universal
/// treatment provider WILL cure them if left to pick its own target, the
/// shrine always names its target explicitly.
/obj/structure/dungeon_shrine/proc/get_treatable_trauma(mob/living/user)
	for(var/datum/status_effect/effect as anything in user.status_effects)
		if(!istype(effect, /datum/status_effect/debuff/defeat))
			continue
		if(istype(effect, /datum/status_effect/debuff/defeat/grievous))
			continue
		return effect
	return null

/// TRUE when the buyer carries a hurt this shrine can actually lift.
/obj/structure/dungeon_shrine/proc/has_treatable_trauma(mob/living/user)
	return !!get_treatable_trauma(user)

/// Damaged, normally repairable armor currently worn by the buyer. This uses
/// the same protective layers as human armor checks and excludes bags, belts,
/// ordinary clothes, and indestructible costume pieces.
/obj/structure/dungeon_shrine/proc/get_damaged_worn_armor(mob/living/user)
	var/list/damaged = list()
	if(!ishuman(user))
		return damaged
	var/mob/living/carbon/human/human = user
	var/list/worn_layers = list(
		human.skin_armor,
		human.head,
		human.wear_mask,
		human.wear_wrists,
		human.gloves,
		human.wear_neck,
		human.cloak,
		human.wear_armor,
		human.wear_shirt,
		human.shoes,
		human.wear_pants,
	)
	for(var/obj/item/clothing/armor_piece as anything in worn_layers)
		if(!armor_piece)
			continue
		if(!(armor_piece.anvilrepair || armor_piece.sewrepair) || !armor_piece.uses_integrity || armor_piece.get_integrity() >= armor_piece.max_integrity)
			continue
		var/is_protective = length(armor_piece.prevent_crits)
		if(!is_protective)
			for(var/rating in armor_piece.armor.getList())
				if(armor_piece.armor.getRating(rating) > 0)
					is_protective = TRUE
					break
		if(is_protective)
			damaged |= armor_piece
	return damaged

/// Price of an offer by id, for refunds.
/obj/structure/dungeon_shrine/proc/get_offer_cost(id)
	for(var/list/offer as anything in build_shrine_offers())
		if(offer["id"] == id)
			return offer["cost"]
	return 0

/obj/structure/dungeon_shrine/proc/build_shrine_offers()
	var/floor = owning_run?.floor || 1
	return list(
		list("id" = "heal", "label" = "Mend wounds", "cost" = 25),
		list("id" = "repair", "label" = "Reforge worn armor (fully repairs equipped armor)", "cost" = DUNGEON_SHRINE_ARMOR_REPAIR_COST),
		list("id" = "revive", "label" = "Undo a lingering hurt (clears one defeat trauma)", "cost" = DUNGEON_SHRINE_TRAUMA_COST),
		list("id" = "boon", "label" = "Beg a blessing (extra boon)", "cost" = 150),
		list("id" = "cache", "label" = "Conjure a cache roll", "cost" = 60 + floor * 20),
		list("id" = "bank", "label" = "Bank motes as echoes now", "cost" = 0),
	)

/obj/structure/dungeon_shrine/proc/apply_shrine_offer(id, mob/living/user)
	switch(id)
		if("heal")
			user.adjustBruteLoss(-40)
			user.adjustFireLoss(-40)
			to_chat(user, span_nicegreen("The shrine's light knits your wounds."))
		if("repair")
			var/list/damaged_armor = get_damaged_worn_armor(user)
			for(var/obj/item/clothing/armor_piece as anything in damaged_armor)
				armor_piece.repair_damage(armor_piece.max_integrity)
			to_chat(user, span_nicegreen("The shrine's light runs across your worn armor, sealing rents and straightening battered plates."))
		if("revive")
			// The dungeon's own light pays the debt a fall left behind. Routed
			// through the defeat system's universal treatment so every listener
			// (logging, achievements) sees a normal cure.
			var/datum/status_effect/debuff/defeat/target = get_treatable_trauma(user)
			if(target && user.defeat_treat_trauma(user, DEFEAT_TREATMENT_UNIVERSAL, target))
				user.visible_message(
					span_nicegreen("[user] straightens as something long-carried lets go of [user.p_them()]."),
					span_nicegreen("The shrine's light reaches into an old hurt and undoes it. You stand easier."),
				)
				// Be honest about what it could not reach, so nobody keeps paying
				// at this shrine hoping to mend a maiming.
				if(user.has_status_effect(/datum/status_effect/debuff/defeat/grievous))
					to_chat(user, span_warning("The deeper maiming does not answer. This shrine mends lesser hurts; only a healer at the town clinic can undo that one."))
			else
				// Nothing was lifted - the light took nothing for nothing.
				var/refund = get_offer_cost("revive")
				if(refund > 0)
					owning_run.motes += refund
				to_chat(user, span_warning("The light gutters and gives your motes back. Whatever ails you lies beyond this shrine's reach."))
		if("boon")
			owning_run.offer_break_room_boon(user)
		if("cache")
			var/table_type = get_dungeon_loot_table_type_for_floor(owning_run.floor)
			var/datum/loot_table/table = new table_type
			table.spawn_loot(user, owning_run.floor, user.return_item_rarity())
			qdel(table)
			to_chat(user, span_nicegreen("The shrine spits out a reward."))
		if("bank")
			owning_run.bank_motes_now(user)
