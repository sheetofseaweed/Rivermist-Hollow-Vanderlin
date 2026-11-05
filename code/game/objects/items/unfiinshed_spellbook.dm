/obj/item/spellbook_unfinished
	name = "bound scrollpaper"
	dropshrink = 0.6
	icon = 'icons/roguetown/items/books.dmi'
	icon_state = "basic_book_0"
	desc = "Thick scroll paper bound at the spine. It lacks pages."
	throw_speed = 1
	throw_range = 5
	w_class = WEIGHT_CLASS_NORMAL
	attack_verb = list("bashed", "whacked", "educated")
	resistance_flags = FLAMMABLE
	drop_sound = 'sound/foley/dropsound/book_drop.ogg'
	pickup_sound = 'sound/blank.ogg'
	/// Pages still needed before the binding is complete.
	var/pages_left = 4

/obj/item/spellbook_unfinished/pre_arcyne
	name = "tome in waiting"
	icon_state = "spellbook_unfinished"
	desc = "A fully bound tome of scroll paper. It's lacking a certain arcyne energy."

/obj/item/spellbook_unfinished/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(!istype(tool, /obj/item/paper/scroll))
		return NONE
	if(!isturf(loc) || !locate(/obj/structure/table) in loc)
		to_chat(user, span_warning("You need to put [src] on a table to work on it."))
		return ITEM_INTERACT_BLOCKING

	var/crafttime = max(0, 60 - GET_MOB_SKILL_VALUE_OLD(user, /datum/attribute/skill/magic/arcane) * 5)
	if(!do_after(user, crafttime, target = src))
		return ITEM_INTERACT_BLOCKING

	pages_left--
	if(pages_left > 0)
		playsound(src, 'sound/items/book_page.ogg', 100, TRUE)
		to_chat(user, span_notice("[pages_left] left..."))
		qdel(tool)
		return ITEM_INTERACT_SUCCESS

	playsound(src, 'sound/items/book_open.ogg', 100, TRUE)
	if(GET_MOB_SKILL_VALUE(user, /datum/attribute/skill/magic/arcane) > SKILL_LEVEL_NONE)
		to_chat(user, span_notice("The book is bound. I must find a catalyst to channel the arcyne into it now."))
	else
		to_chat(user, span_notice("I've made an empty book of thick, useless scroll paper. I can't even thumb through it!"))
	new /obj/item/spellbook_unfinished/pre_arcyne(loc)
	qdel(tool)
	qdel(src)
	return ITEM_INTERACT_SUCCESS

/obj/item/spellbook_unfinished/pre_arcyne/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(istype(tool, /obj/item/gem/amethyst))
		user.visible_message(span_notice("[user] runs arcyne energy into [tool], but its artificial lattice pulses and falls dormant."), span_notice("I run my arcyne energy into the crystal. Its artificial lattice pulses and falls dormant; it is not strong enough to make a spellbook."))
		return ITEM_INTERACT_BLOCKING

	if(isturf(loc) && !locate(/obj/structure/table) in loc)
		to_chat(user, span_warning("You need to put [src] on a table to work on it."))
		return ITEM_INTERACT_BLOCKING

	if(istype(tool, /obj/item/gem/violet))
		apply_gem_catalyst(user, tool, /obj/item/book/granter/spellbook/expert)
		return ITEM_INTERACT_SUCCESS
	if(istype(tool, /obj/item/gem))
		apply_gem_catalyst(user, tool, /obj/item/book/granter/spellbook/adept)
		return ITEM_INTERACT_SUCCESS
	if(istype(tool, /obj/item/natural/stone))
		var/obj/item/natural/stone/stone = tool
		if(!stone.magic_power)
			to_chat(user, span_notice("This is a mere rock—it has no arcyne potential."))
			return ITEM_INTERACT_BLOCKING
		apply_stone_catalyst(user, stone)
		return ITEM_INTERACT_SUCCESS
	if(istype(tool, /obj/item/natural/melded))
		var/obj/item/natural/melded/meld = tool
		apply_melded_catalyst(user, meld, meld.melded_quality, meld.shock_damage)
		return ITEM_INTERACT_SUCCESS
	return NONE

/// Spawns the finished book after the crafter picks tome or grimoire, consuming the catalyst and unfinished tome.
/obj/item/spellbook_unfinished/pre_arcyne/proc/finish_book(mob/living/user, obj/item/catalyst, book_type, born_of_rock = FALSE, extra_desc)
	book_type = choose_finish(user, book_type)
	if(QDELETED(src) || QDELETED(catalyst))
		return
	playsound(src, 'sound/magic/crystal.ogg', 100, TRUE)
	var/atom/old_loc = loc
	var/obj/item/new_book
	if(ispath(book_type, /obj/item/spellbook))
		new_book = new book_type(get_turf(src))
	else
		var/obj/item/book/granter/spellbook/tome = new book_type(get_turf(src))
		tome.owner = user
		if(born_of_rock)
			tome.born_of_rock = TRUE
		new_book = tome
	if(extra_desc)
		new_book.desc += extra_desc
	qdel(catalyst)
	qdel(src)
	if(ismob(old_loc))
		var/mob/living/holder = old_loc
		holder.put_in_hands(new_book)
	return new_book

/// Offers a grimoire of the tome's tier; no client, no answer or a slow one keeps the tome.
/obj/item/spellbook_unfinished/pre_arcyne/proc/choose_finish(mob/living/user, tome_type)
	var/obj/item/spellbook/grimoire_type = grimoire_for_tome(tome_type)
	if(!grimoire_type || !user?.client)
		return tome_type
	var/obj/item/book/granter/spellbook/typed_tome = tome_type
	var/list/choices = list(
		"[initial(typed_tome.name)]" = tome_type,
		"[initial(grimoire_type.name)]" = grimoire_type,
	)
	var/asked_at = world.time
	var/choice = tgui_input_list(user, "What should the catalyst make of the bound pages?", "Finish the Book", choices, timeout = 30 SECONDS)
	if(!choice || world.time > asked_at + 30 SECONDS)
		return tome_type
	return choices[choice]

/// The grimoire tier that mirrors a point tome tier; null for anything else.
/obj/item/spellbook_unfinished/pre_arcyne/proc/grimoire_for_tome(tome_type)
	switch(tome_type)
		if(/obj/item/book/granter/spellbook/horrible)
			return /obj/item/spellbook/horrible
		if(/obj/item/book/granter/spellbook/mid)
			return /obj/item/spellbook/mid
		if(/obj/item/book/granter/spellbook/apprentice)
			return /obj/item/spellbook/apprentice
		if(/obj/item/book/granter/spellbook/adept)
			return /obj/item/spellbook/adept
		if(/obj/item/book/granter/spellbook/expert)
			return /obj/item/spellbook/expert
		if(/obj/item/book/granter/spellbook/master)
			return /obj/item/spellbook/master
		if(/obj/item/book/granter/spellbook/legendary)
			return /obj/item/spellbook/legendary
	return null

/obj/item/spellbook_unfinished/pre_arcyne/proc/apply_gem_catalyst(mob/living/user, obj/item/gem/gem, book_type)
	if(!do_after(user, max(0, 100 - GET_MOB_SKILL_VALUE_OLD(user, /datum/attribute/skill/magic/arcane) * 5), target = src))
		return
	if(GET_MOB_SKILL_VALUE(user, /datum/attribute/skill/magic/arcane) <= SKILL_LEVEL_NONE)
		to_chat(user, span_notice("I press the gem into the cover of the book. What a pretty design this would make!"))
		return
	user.visible_message(
		span_warning("[user] crushes [gem], and its powder seeps into [src]."),
		span_notice("I run my arcyne energy into the crystal. It shatters and seeps into the tome, covering its pages in unknowable runes."),
	)
	finish_book(user, gem, book_type)

/obj/item/spellbook_unfinished/pre_arcyne/proc/apply_stone_catalyst(mob/living/user, obj/item/natural/stone/stone)
	var/crafttime = max(0, 130 - stone.magic_power - GET_MOB_SKILL_VALUE_OLD(user, /datum/attribute/skill/magic/arcane) * 5)
	if(!do_after(user, crafttime, target = src))
		return
	var/book_type = stone_quality_to_book(stone.magic_power)
	if(GET_MOB_SKILL_VALUE(user, /datum/attribute/skill/magic/arcane) > SKILL_LEVEL_NONE)
		user.visible_message(
			span_warning("[user] crushes [stone], and its powder seeps into [src]."),
			span_notice("I join my arcyne energy with the stone. It dissolves into motes of ash and unknowable runes cover the tome."),
		)
		finish_book(user, stone, book_type, born_of_rock = TRUE, extra_desc = " Traces of multicolored stone limn its margins.")
		return
	if(prob(stone.magic_power * 5))
		user.visible_message(
			span_warning("The glow around [stone] liquefies and soaks into [src]."),
			span_notice("I knew this stone was special! Its colourful magick has soaked into my tome."),
		)
		finish_book(user, stone, book_type, born_of_rock = TRUE, extra_desc = " Traces of multicolored stone limn its margins.")
		return
	user.visible_message(
		span_warning("[stone] violently pops on the surface of [src]!"),
		span_notice("No! My precious stone! It must not have wanted to share its mysteries with me."),
	)
	user.electrocute_act(5, src)
	qdel(stone)

/obj/item/spellbook_unfinished/pre_arcyne/proc/stone_quality_to_book(magic_power)
	if(magic_power >= 10)
		return /obj/item/book/granter/spellbook/apprentice
	if(magic_power > 5)
		return /obj/item/book/granter/spellbook/mid
	return /obj/item/book/granter/spellbook/horrible

/obj/item/spellbook_unfinished/pre_arcyne/proc/apply_melded_catalyst(mob/living/user, obj/item/melded, book_type, shock_damage)
	if(!do_after(user, max(0, 100 - GET_MOB_SKILL_VALUE_OLD(user, /datum/attribute/skill/magic/arcane) * 5), target = src))
		return
	if(GET_MOB_SKILL_VALUE(user, /datum/attribute/skill/magic/arcane) > SKILL_LEVEL_NONE)
		user.visible_message(
			span_warning("[user] imbues [melded], and it fuses into [src]."),
			span_notice("I join my arcyne energy with [melded]. It dissolves into motes of energy and unknowable runes cover the tome."),
		)
		finish_book(user, melded, book_type)
		return
	user.visible_message(
		span_warning("[melded] violently explodes on the surface of [src]!"),
		span_notice("I should have known that meddling with the arcyne was dangerous!"),
	)
	user.electrocute_act(shock_damage, src)
	qdel(melded)
