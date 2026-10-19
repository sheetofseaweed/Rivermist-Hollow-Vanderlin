/**
 * Tomes of the Weave: one read grants form mastery points, a gem's attunement themes half of them.
 * Difficult to learn by default, has multipliers for weed, gems and rituals.
 * Inherits most of its functionality from default granters, however also has some copy paste from roguebooks for parity.
 */

/obj/item/book/granter/spellbook
	item_weight = 547 GRAMS
	icon = 'icons/roguetown/items/books.dmi'
	icon_state = "spellbookbrown_0"
	slot_flags = ITEM_SLOT_HIP
	unique = TRUE
	firefuel = 2 MINUTES
	dropshrink = 0.6
	drop_sound = 'sound/foley/dropsound/book_drop.ogg'
	force = 5
	associated_skill = /datum/skill/misc/reading
	name = "tome of the Weave"
	desc = "A crackling, glowing book, filled with runes and symbols that hurt the mind to stare at."
	pages_to_mastery = 7
	remarks = list("Recall that place of white and black, so cold after its season of heat...",
	"Time slips away as I devour each pictograph and sigil...",
	"Noc is a shrewd God, and his followers’ writings are no different...",
	"The smell of wet rain fills the room with every turned page...",
	"Helical text spans the page like a winding puzzle...",
	"Tracing a finger over one rune renders  my hand paralyzed, if only for a moment...",
	"This page clearly details the benefits of swampweed on one's capacity to conceptualize the arcyne...",
	"Conceptualize. Theorize. Feel. Flow. Manifest...",
	"Passion. Strength. Power. Victory. The tenets through which we break the chains of reality...",
	"Magick is to be kept close, a guarded secret. Noc changed the rules again. I need to catch up...",
	"Didn’t I just read this page...?",
	"A lone illustration of Noc’s visage fills this page, his stony gaze boring into my soul...",
	"My eyes begin to lid as I finish this chapter. These symbols cast a heavy fog over my mind...",
	"Silver. Blade. Mana. Blood. These are the ingredients I’ll need to imbibe the very ground with arcyne abilities...",
	"Elysium incants speak to me in an extinct tongue immortalized on parchment...",
	"My mind wanders and waves. Z's temptations draw close, but I weather through as I finally finish this chapter...",
	"I close my eye's for but a moment, and the competing visages of Noc and Z stare into my very soul. I see them blink, and my eyelids open...",
	"I am the Root. The Root is me. I must reach it, and the Tree...",
	"I feel the arcyne circuits running through my body, empowered with each word I read...",
	"Am I reading? Are these words, symbols or inane scribbles? I cannot be sure, yet with each one my eyes glaze over, I can feel the arcyne pulse within me...",
	"A mystery is revealed before my very eyes. I do not read it, yet I am aware. Gems are the Root's natural arcyne energy, manifest. Perhaps I can use them to better my conceptualization...")
	oneuse = FALSE
	var/owner = null
	var/list/allowed_readers = list()
	var/stored_gem = FALSE
	var/datum/attunement/stored_attunement
	var/picked // if the book has had it's style picked or not
	var/born_of_rock = FALSE // was a magical stone used to make it instead of a gem?
	var/bookquality = 3

/obj/item/book/granter/spellbook/getonmobprop(tag)
	. = ..()
	if(tag)
		if(open)
			switch(tag)
				if("gen")
					return list("shrink" = 0.4,
	"sx" = -2,
	"sy" = -3,
	"nx" = 10,
	"ny" = -2,
	"wx" = 1,
	"wy" = -3,
	"ex" = 5,
	"ey" = -3,
	"northabove" = 0,
	"southabove" = 1,
	"eastabove" = 1,
	"westabove" = 0,
	"nturn" = 0,
	"sturn" = 0,
	"wturn" = 0,
	"eturn" = 0,
	"nflip" = 0,
	"sflip" = 0,
	"wflip" = 0,
	"eflip" = 0)
				if("onbelt")
					return list("shrink" = 0.3,"sx" = -2,"sy" = -5,"nx" = 4,"ny" = -5,"wx" = 0,"wy" = -5,"ex" = 2,"ey" = -5,"nturn" = 0,"sturn" = 0,"wturn" = 0,"eturn" = 0,"nflip" = 0,"sflip" = 0,"wflip" = 0,"eflip" = 0,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0)
		else
			switch(tag)
				if("gen")
					return list("shrink" = 0.4,
	"sx" = -2,
	"sy" = -3,
	"nx" = 10,
	"ny" = -2,
	"wx" = 1,
	"wy" = -3,
	"ex" = 5,
	"ey" = -3,
	"northabove" = 0,
	"southabove" = 1,
	"eastabove" = 1,
	"westabove" = 0,
	"nturn" = 0,
	"sturn" = 0,
	"wturn" = 0,
	"eturn" = 0,
	"nflip" = 0,
	"sflip" = 0,
	"wflip" = 0,
	"eflip" = 0)
				if("onbelt")
					return list("shrink" = 0.3,"sx" = -2,"sy" = -5,"nx" = 4,"ny" = -5,"wx" = 0,"wy" = -5,"ex" = 2,"ey" = -5,"nturn" = 0,"sturn" = 0,"wturn" = 0,"eturn" = 0,"nflip" = 0,"sflip" = 0,"wflip" = 0,"eflip" = 0,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0)


/obj/item/book/granter/spellbook/attack_self(mob/user, list/modifiers)
	if(!open)
		attack_hand_secondary(user, modifiers)
		return
	if(HAS_TRAIT(user, TRAIT_SORCERER))
		to_chat(user, span_warning("The written word has nothing to teach my blood."))
		return
	..()
	user.update_inv_hands()

/obj/item/book/granter/spellbook/attack_self_secondary(mob/user, list/modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return
	attack_hand_secondary(user, modifiers)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/item/book/granter/spellbook/read(mob/user)
	return FALSE

/obj/item/book/granter/spellbook/attack_hand_secondary(mob/user, list/modifiers)
	if(!picked)
		var/list/designlist = list("green", "yellow", "brown")
		var/mob/living/carbon/human/gamer = user
		if(gamer.job == "Court Magician")
			designlist = list("steel", "gem", "skin", "mimic")
		var/the_time = world.time
		var/design = input(user, "Select a design.","Spellbook Design") as null|anything in designlist
		if(!design)
			return
		if(world.time > (the_time + 30 SECONDS))
			return
		base_icon_state = "spellbook[design]"
		update_appearance(UPDATE_ICON_STATE)
		picked = TRUE
		return
	if(owner == null)
		owner = user
	if(!open)
		slot_flags &= ~ITEM_SLOT_HIP
		open = TRUE
		playsound(src, 'sound/items/book_open.ogg', 100, FALSE, -1)
	else
		slot_flags |= ITEM_SLOT_HIP
		open = FALSE
		playsound(src, 'sound/items/book_close.ogg', 100, FALSE, -1)
	curpage = 1
	update_appearance(UPDATE_ICON_STATE)
	user.update_inv_hands()

/obj/item/book/granter/spellbook/update_icon_state()
	. = ..()
	icon_state = "[base_icon_state]_[open]"

/obj/item/book/granter/spellbook/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!isliving(interacting_with))
		return NONE

	var/mob/living/target = interacting_with
	if(target.stat == DEAD)
		target.visible_message(span_danger("[user] smacks [target]'s lifeless corpse with [src]."))
		playsound(src, "punch", 25, TRUE, -1)
		return ITEM_INTERACT_SUCCESS
	if(user == target)
		to_chat(user, span_warning("I'm already chained to this tome!"))
		return ITEM_INTERACT_BLOCKING

	target.visible_message(
		span_danger("[user] beats [target] over the head with [src]!"),
		span_danger("[user] beats [target] over the head with [src]!")
	)
	if(length(allowed_readers) > 2 || (target in allowed_readers))
		to_chat(user, span_smallnotice("I can't chain [target.p_them()] to my tome..."))
		return ITEM_INTERACT_BLOCKING

	allowed_readers += target
	playsound(src, "punch", 25, TRUE, -1)
	log_combat(user, target, "attacked", src)
	return ITEM_INTERACT_SUCCESS

/obj/item/book/granter/spellbook/on_reading_start(mob/user)
	to_chat(user, span_notice("Arcane mysteries abound in this enigmatic tome, gift of Mystra..."))

/obj/item/book/granter/spellbook/on_reading_finished(mob/user)
	var/mob/living/carbon/human/gamer = user
	if(gamer != owner && !allowed_readers.Find(gamer))
		to_chat(user, span_notice("What was that gibberish? Even for the arcane it was completely illegible!"))
		recoil(user)
		return
	user.mind?.has_studied = TRUE
	var/mob/living/reader = user
	var/qualityoflearn = (GET_MOB_ATTRIBUTE_VALUE(reader, STAT_INTELLIGENCE)*2 + (GET_MOB_SKILL_VALUE_OLD(user, /datum/attribute/skill/misc/reading)* 5) + (GET_MOB_SKILL_VALUE_OLD(user, /datum/attribute/skill/magic/arcane)*5))
	if(reader.has_status_effect(/datum/status_effect/buff/weed))
		to_chat(user, span_smallgreen("Swampweed truly does open one's third eye to the secrets of the Weave..."))
		qualityoflearn += 10
	var/obj/effect/decal/cleanable/roguerune/rune = (locate(/obj/effect/decal/cleanable/roguerune) in range(1, user))
	if(rune)
		to_chat(user, span_cultsmall("The rune beneath my feet glows..."))
		qualityoflearn += rune.spellbonus
		rune.do_invoke_glow()
	if(stored_gem)
		to_chat(user, span_smallnotice("I can feel the magical energies imbued within the crystalline dust scattered upon my tome resonate with the Weave..."))
		qualityoflearn += stored_gem
		stored_gem = FALSE
	if(!isarcyne(user))
		if (gamer != owner) // if you didn't make this book, get fucked.
			qualityoflearn = 1
		else
			qualityoflearn *= 0.5
			qualityoflearn = min(qualityoflearn, 15)
	if (born_of_rock)
		// the rock tomes are a *lot* easier to make, so we make them worse by them reducing your chances by 20%
		qualityoflearn *= 0.8

	user.visible_message(span_warning("[user] is filled with arcane energy! You witness [user.p_their()] body convulse and spark brightly."), \
	span_notice("Mystra blesses me. I have been granted knowledge and wisdom beyond my years, this tome's mysteries unveiled one at a time."))
	qualityoflearn = qualityoflearn / 100
	var/spellpoints = CEILING(src.bookquality * qualityoflearn, 1)
	// Slot casters learn through mastery; everyone else still feeds the old tree.
	if(reader.mind?.spell_slots)
		grant_mastery_points(reader, spellpoints)
	else
		reader.adjust_spell_points(spellpoints)
	user.log_message("successfully studied their spellbook and gained [spellpoints] form mastery points", LOG_ATTACK, color="orange")
	onlearned(user)
	if(prob(55))
		to_chat(user, span_notice("Confounded arcane mysteries, my notes have gone in circles. I must sleep before I can bring myself to open this damned thing again..."))
		user.mind?.add_sleep_experience(/datum/skill/misc/reading, reader.STAINT*10)
	to_chat(user, span_small("My notes include passages I've read before, but don't understand. I must sleep on their meaning..."))

/obj/item/book/granter/spellbook/onlearned(mob/user)
	used = FALSE

/// Form points equal to the old spell points; a gem's attunement themes half of them like a grimoire.
/obj/item/book/granter/spellbook/proc/grant_mastery_points(mob/living/reader, points)
	var/datum/spell_mastery/mastery = reader.mind?.get_spell_mastery()
	if(!mastery || points <= 0)
		return FALSE
	var/themed_form = attunement_to_form(stored_attunement)
	if(themed_form)
		var/themed_amount = CEILING(points * 0.5, 1)
		mastery.adjust_form_mastery_points(themed_amount, FALSE, themed_form)
		if(points - themed_amount)
			mastery.adjust_form_points(points - themed_amount)
	else
		mastery.adjust_form_points(points)
	mastery.recalculate_unspent_points()
	to_chat(reader, span_notice("I gain [points] form mastery point[points == 1 ? "" : "s"][themed_form ? ", half of them in [themed_form]" : ""]."))
	return TRUE

/// The form a gem attunement feeds; null for attunements without one.
/proc/attunement_to_form(datum/attunement/attunement_path)
	switch(attunement_path)
		if(/datum/attunement/fire)
			return FORM_FIRE
		if(/datum/attunement/ice)
			return FORM_ICE
		if(/datum/attunement/electric)
			return FORM_LIGHTNING
		if(/datum/attunement/earth)
			return FORM_EARTH
		if(/datum/attunement/arcyne)
			return FORM_ARCANE
		if(/datum/attunement/death)
			return FORM_DEATH
		if(/datum/attunement/life)
			return FORM_LIFE
		if(/datum/attunement/aeromancy)
			return FORM_AIR
		if(/datum/attunement/blood)
			return FORM_BLOOD
	return null

/obj/item/book/granter/spellbook/recoil(mob/user)
	user.visible_message(span_warning("[src] shoots out a spark of angry, arcane energy at [user]!"))
	var/mob/living/gamer = user
	gamer.electrocute_act(5, src)

/obj/item/book/granter/spellbook/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(!istype(tool, /obj/item/gem))
		return NONE

	if(stored_gem)
		to_chat(user, span_notice("This tome is already coursing with arcyne energies..."))
		return ITEM_INTERACT_BLOCKING

	if(GET_MOB_SKILL_VALUE(user, /datum/attribute/skill/magic/arcane) <= SKILL_LEVEL_NONE)
		to_chat(user, span_notice("Why am I jamming a gem into a book? I must look like a fool!"))
		return ITEM_INTERACT_BLOCKING

	var/obj/item/gem/gem = tool
	var/crafttime = max(0, 60 - GET_MOB_SKILL_VALUE_OLD(user, /datum/attribute/skill/magic/arcane) * 5)
	if(!do_after(user, crafttime, target = src))
		return ITEM_INTERACT_BLOCKING

	playsound(src, 'sound/magic/glass.ogg', 100, TRUE)
	to_chat(user, span_notice("Running my arcyne energy through this crystal, I imbue the tome with my natural essence, attuning it to my state of mind..."))
	stored_gem = gem.arcyne_potency
	stored_attunement = gem.attuned
	qdel(tool)
	return ITEM_INTERACT_SUCCESS

/// Book Types:
/obj/item/book/granter/spellbook/horrible	//makeable with magic stones (bad quality ones)
	name = "poorly made tome of the Weave"
	desc = "A poorly made book that barely glows with arcane power and has only small notes on Weave symbols."
	bookquality = 1
	sellprice = 15

/obj/item/book/granter/spellbook/mid	//decent magic stones and basic crafting materials
	name = "beginners tome of the Weave"
	desc = "An obviously handcrafted book. It glows occasionally with arcane power and has a meager amount of notes on Weave symbols."
	bookquality = 2
	sellprice = 30

/obj/item/book/granter/spellbook/apprentice	//apprentices get made with obsidian
	name = "apprentice tome of the Weave"
	desc = "A carefully made book, faintly glowing with arcane power and half filled with notes and theory on Weave symbols."
	bookquality = 3
	sellprice = 75

/obj/item/book/granter/spellbook/adept	//refugee mages &normal loot
	name = "adept tome of the Weave"
	desc = "A well-made book. It shines moderately with arcane light and has been filled with notes of varying depth on the Weave."
	bookquality = 4
	sellprice = 150

/obj/item/book/granter/spellbook/expert	//made from 2nd tier loot item
	name = "expert tome of the Weave"
	desc = "A well cared for book, shining brightly with arcane power. It has many runes and Weave symbols scribed within, with detailed notes."
	bookquality = 6
	sellprice = 200

/obj/item/book/granter/spellbook/master	// Court mage & made from 3rd tier loot item
	name = "masterful tome of the Weave"
	desc = "A crackling, glowing book filled with advanced arcane runes and symbols that hurt the mind to stare at. A true master of the Weave has left their mark behind."
	bookquality = 8
	sellprice = 250

/obj/item/book/granter/spellbook/legendary	//max tier lootmade item
	name = "legendary tome of the Weave"
	desc = "An incredible book that gives off glowing arcane motes. It is filled with runes and arcane theories that are hard for even masters of the Weave to understand. The script glows and practically whispers from the page."
	bookquality = 12
	sellprice = 400
