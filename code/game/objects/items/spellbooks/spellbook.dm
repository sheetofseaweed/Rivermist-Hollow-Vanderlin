// Grimoires: the wizard's key to learning and preparing. Mastery itself lives on the mind.

/obj/item/spellbook
	name = "grimoire"
	desc = "A bound book of arcyne notes, waiting for a mind to claim it."
	icon = 'icons/roguetown/items/books.dmi'
	icon_state = "spellbookbrown_0"
	slot_flags = ITEM_SLOT_HIP
	firefuel = 2 MINUTES
	dropshrink = 0.6
	drop_sound = 'sound/foley/dropsound/book_drop.ogg'
	force = 5
	associated_skill = /datum/attribute/skill/misc/reading
	item_weight = 547 GRAMS
	grid_height = 64
	grid_width = 32

	/// The mind this grimoire is bound to.
	var/datum/weakref/bound_mind_ref
	/// Up to two more mobs allowed to read without recoil.
	var/list/allowed_readers = list()
	/// Whether a cover design has been chosen.
	var/picked = FALSE
	/// Quality scales the points a themed book carries. Higher is better.
	var/bookquality = 3
	/// Form this book specialises in, if any.
	var/themed_form = null
	/// Points the first binder receives toward forms.
	var/base_form_points = 0
	/// Points the first binder receives toward techniques.
	var/base_technique_points = 0
	/// Cost multiplier for spells of themed_form while worn or held.
	var/themed_cost_multiplier = 1
	var/themed_cast_speed_multiplier = 1
	/// Flat magnitude addition for spells of themed_form.
	var/themed_magnitude_bonus = 0
	/// Points are claimed once, by the first mind that binds the book.
	var/points_claimed = FALSE
	var/list/designlist = list("green", "yellow", "brown")
	var/open = FALSE

/obj/item/spellbook/Initialize()
	. = ..()
	apply_theme()
	if(length(designlist) == 1)
		base_icon_state = "spellbook[designlist[1]]"
		update_appearance(UPDATE_ICON_STATE)
		picked = TRUE

/obj/item/spellbook/Destroy()
	allowed_readers = null
	bound_mind_ref = null
	return ..()

/// Themed books get their points from quality and carry a gear modifier for their form.
/obj/item/spellbook/proc/apply_theme()
	if(!themed_form)
		return
	var/list/flavor = get_theme_flavor(themed_form)
	if(flavor[1])
		name = "[initial(name)] [flavor[1]]"
	if(flavor[2])
		desc = "[initial(desc)] [flavor[2]]"
	if(!base_form_points && !base_technique_points)
		var/scale = bookquality / SPELLBOOK_THEME_BASELINE_QUALITY
		base_form_points = CEILING(SPELLBOOK_THEME_BASELINE_FORM_POINTS * scale, 1)
		base_technique_points = CEILING(SPELLBOOK_THEME_BASELINE_TECHNIQUE_POINTS * scale, 1)
	if(themed_cost_multiplier != 1 || themed_cast_speed_multiplier != 1 || themed_magnitude_bonus != 0)
		AddComponent(/datum/component/spell_modifier, \
			list("[themed_form]" = themed_cost_multiplier), \
			list("[themed_form]" = themed_cast_speed_multiplier), \
			list("[themed_form]" = themed_magnitude_bonus))

/proc/get_theme_flavor(form)
	switch(form)
		if(FORM_FIRE)
			return list("of Cinders", "Its pages are warm to the touch.")
		if(FORM_ICE)
			return list("of Rime", "Frost creeps along the binding.")
		if(FORM_LIGHTNING)
			return list("of Storms", "The clasp crackles faintly.")
		if(FORM_EARTH)
			return list("of Stone", "Grit sits in the spine.")
		if(FORM_ARCANE)
			return list("of the Weave", "The runes shift when unobserved.")
		if(FORM_DEATH)
			return list("of Dust", "It smells of old graves.")
		if(FORM_LIFE)
			return list("of Bloom", "Pressed leaves mark its chapters.")
		if(FORM_AIR)
			return list("of Gales", "The pages stir in still air.")
		if(FORM_WATER)
			return list("of Tides", "The vellum never quite dries.")
		if(FORM_BLOOD)
			return list("of Vitae", "Its ink was never ink.")
	return list(null, null)

/obj/item/spellbook/proc/get_bound_mind()
	RETURN_TYPE(/datum/mind)
	return bound_mind_ref?.resolve()

/// Binds the book to a mind. The first binder claims the book's points.
/obj/item/spellbook/proc/bind_owner(datum/mind/new_owner)
	if(!new_owner)
		return FALSE
	bound_mind_ref = WEAKREF(new_owner)
	var/datum/spell_mastery/mastery = new_owner.get_spell_mastery()
	mastery.bind_book(src)
	if(!points_claimed)
		points_claimed = TRUE
		if(base_form_points > 0)
			if(themed_form)
				var/themed_amount = CEILING(base_form_points * 0.5, 1)
				mastery.adjust_form_mastery_points(themed_amount, FALSE, themed_form)
				if(base_form_points - themed_amount)
					mastery.adjust_form_points(base_form_points - themed_amount)
			else
				mastery.adjust_form_points(base_form_points)
		if(base_technique_points > 0)
			mastery.adjust_technique_points(base_technique_points)
		mastery.recalculate_unspent_points()
	return TRUE

/obj/item/spellbook/examine(mob/user)
	. = ..()
	var/datum/mind/bound = get_bound_mind()
	if(bound)
		. += span_notice("It is bound to [bound.name].")
	else
		. += span_notice("It is bound to no one yet; opening it would claim it.")
	if(themed_form)
		. += span_notice("Its notes favour [themed_form].")
	if(!points_claimed && (base_form_points || base_technique_points))
		. += span_notice("Its unread notes still hold insight for whoever claims it.")

/obj/item/spellbook/getonmobprop(tag)
	. = ..()
	if(!tag)
		return
	switch(tag)
		if("gen")
			return list(
				"shrink" = 0.4,
				"sx" = -2, "sy" = -3,
				"nx" = 10, "ny" = -2,
				"wx" = 1,  "wy" = -3,
				"ex" = 5,  "ey" = -3,
				"northabove" = 0, "southabove" = 1,
				"eastabove" = 1,  "westabove" = 0,
				"nturn" = 0, "sturn" = 0, "wturn" = 0, "eturn" = 0,
				"nflip" = 0, "sflip" = 0, "wflip" = 0, "eflip" = 0
			)
		if("onbelt")
			return list(
				"shrink" = 0.3,
				"sx" = -2, "sy" = -5,
				"nx" = 4,  "ny" = -5,
				"wx" = 0,  "wy" = -5,
				"ex" = 2,  "ey" = -5,
				"nturn" = 0, "sturn" = 0, "wturn" = 0, "eturn" = 0,
				"nflip" = 0, "sflip" = 0, "wflip" = 0, "eflip" = 0,
				"northabove" = 0, "southabove" = 1,
				"eastabove" = 1,  "westabove" = 0
			)

/obj/item/spellbook/update_icon_state()
	. = ..()
	icon_state = "[base_icon_state]_[open]"

/// Left-click in hand: claim if unbound, then open the spellbook UI.
/obj/item/spellbook/attack_self(mob/user, list/modifiers)
	if(!isliving(user) || !user.mind)
		return
	if(HAS_TRAIT(user, TRAIT_SORCERER))
		to_chat(user, span_warning("The written word has nothing to teach my blood."))
		return
	if(!get_bound_mind())
		bind_owner(user.mind)
		to_chat(user, span_notice("The grimoire settles into my mind. It is mine now."))
	if(!compare_magic(user))
		return
	if(!open)
		set_open(TRUE, user)
	user.mind.get_spell_mastery().open_ui(user)

/obj/item/spellbook/attack_self_secondary(mob/user, list/modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return
	attack_hand_secondary(user, modifiers)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/// Right-click: pick a cover first, then open or close the book.
/obj/item/spellbook/attack_hand_secondary(mob/user, list/modifiers)
	if(!picked)
		var/the_time = world.time
		var/design = tgui_input_list(user, "Select a design.", "Grimoire Design", designlist)
		if(!design || world.time > (the_time + 30 SECONDS))
			return
		base_icon_state = "spellbook[design]"
		update_appearance(UPDATE_ICON_STATE)
		picked = TRUE
		return
	set_open(!open, user)

/obj/item/spellbook/proc/set_open(state, mob/user)
	open = state
	if(open)
		slot_flags &= ~ITEM_SLOT_HIP
		playsound(src, 'sound/items/book_open.ogg', 100, FALSE, -1)
	else
		slot_flags |= ITEM_SLOT_HIP
		playsound(src, 'sound/items/book_close.ogg', 100, FALSE, -1)
	update_appearance(UPDATE_ICON_STATE)
	user?.update_inv_hands()

/// Readers weaker in the arcyne than the owner get a shock instead of the pages.
/obj/item/spellbook/proc/compare_magic(mob/user, recoil = TRUE)
	var/datum/mind/bound = get_bound_mind()
	if(!bound || user.mind == bound || (user in allowed_readers))
		return TRUE
	var/mob/living/owner_body = bound.current
	if(!owner_body)
		return TRUE
	var/magic_compare = GET_MOB_SKILL_VALUE(user, /datum/attribute/skill/magic/arcane)
	var/owners_magic = GET_MOB_SKILL_VALUE(owner_body, /datum/attribute/skill/magic/arcane)
	if(owners_magic > magic_compare)
		if(recoil)
			addtimer(CALLBACK(src, PROC_REF(recoil), user), 0.1 SECONDS)
		return FALSE
	return TRUE

/obj/item/spellbook/proc/recoil(mob/living/user)
	if(QDELETED(user))
		return
	user.visible_message(span_warning("[src] shoots out a spark of angry, arcyne energy at [user]!"))
	user.electrocute_act(5, src)

/// Smacking someone with the book chains them as an allowed reader instead of hurting them.
/obj/item/spellbook/pre_attack(atom/A, mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return .
	if(!isliving(A) || user.mind != get_bound_mind())
		return .
	var/mob/living/target = A
	if(target.stat == DEAD)
		target.visible_message(span_danger("[user] smacks [target]'s lifeless corpse with [src]."))
		playsound(src, "punch", 25, TRUE, -1)
		return TRUE
	if(user == target)
		to_chat(user, span_warning("I'm already chained to this tome!"))
		return TRUE
	target.visible_message(
		span_danger("[user] beats [target] over the head with [src]!"),
		span_danger("[user] beats [target] over the head with [src]!")
	)
	if(length(allowed_readers) > 2 || (target in allowed_readers))
		to_chat(user, span_smallnotice("I can't chain [target.p_them()] to my tome..."))
		return TRUE
	allowed_readers += target
	playsound(src, "punch", 25, TRUE, -1)
	return TRUE

// Quality tiers

/obj/item/spellbook/horrible
	name = "poorly made grimoire"
	desc = "A poorly made book, it barely glows with arcyne and has only small notes on arcyne symbols."
	bookquality = 1
	sellprice = 15

/obj/item/spellbook/mid
	name = "beginner's grimoire"
	desc = "An obviously handcrafted book, it glows occasionally with arcyne and has a meager amount of notes on arcyne symbols."
	bookquality = 2
	sellprice = 30

/obj/item/spellbook/apprentice
	name = "apprentice grimoire"
	desc = "A carefully made book, faintly glowing with arcyne and half filled with notes and theory on arcyne symbols."
	bookquality = 3
	sellprice = 75

/obj/item/spellbook/adept
	name = "adept grimoire"
	desc = "A well-made book, it shines moderately with arcyne light. It has been filled with notes of varying degrees on the arcyne."
	bookquality = 4
	sellprice = 150

/obj/item/spellbook/expert
	name = "expert grimoire"
	desc = "A well cared for book, shining brightly with arcyne. It has many runes and arcyne symbols scribed within, with detailed notes."
	bookquality = 6
	sellprice = 200

/obj/item/spellbook/master
	name = "masterful grimoire"
	desc = "A crackling, glowing book, filled with advanced arcyne runes and symbols that hurt the mind to stare at. A true master of the arcyne has left their mark behind."
	bookquality = 8
	sellprice = 250

/obj/item/spellbook/legendary
	name = "legendary grimoire"
	desc = "An incredible book that gives off glowing arcyne motes, it is filled with runes and arcyne theories that is hard for even masters of arcyne to understand. The arcyne script glows and practically whispers from the page..."
	bookquality = 12
	sellprice = 400

// Themed starter grimoires: points from quality, half of them into the theme, plus a gear modifier.

/obj/item/spellbook/apprentice/starter
	abstract_type = /obj/item/spellbook/apprentice/starter
	themed_cost_multiplier = 0.91
	themed_cast_speed_multiplier = 1.15
	themed_magnitude_bonus = 0.2

/obj/item/spellbook/apprentice/starter/fire
	themed_form = FORM_FIRE
	designlist = list("steel")

/obj/item/spellbook/apprentice/starter/ice
	themed_form = FORM_ICE
	designlist = list("steel")

/obj/item/spellbook/apprentice/starter/lightning
	themed_form = FORM_LIGHTNING
	designlist = list("steel")

/obj/item/spellbook/apprentice/starter/earth
	themed_form = FORM_EARTH
	designlist = list("steel")

/obj/item/spellbook/apprentice/starter/arcane
	themed_form = FORM_ARCANE
	designlist = list("gem")

/obj/item/spellbook/apprentice/starter/death
	themed_form = FORM_DEATH
	designlist = list("skin")

/obj/item/spellbook/apprentice/starter/life
	themed_form = FORM_LIFE
	designlist = list("mimic")

/obj/item/spellbook/apprentice/starter/air
	themed_form = FORM_AIR
	designlist = list("steel")

/obj/item/spellbook/apprentice/starter/water
	themed_form = FORM_WATER
	designlist = list("steel")

/obj/item/spellbook/expert/starter
	abstract_type = /obj/item/spellbook/expert/starter
	themed_cost_multiplier = 0.86
	themed_cast_speed_multiplier = 1.25
	themed_magnitude_bonus = 0.35

/obj/item/spellbook/expert/starter/fire
	themed_form = FORM_FIRE
	designlist = list("steel")

/obj/item/spellbook/expert/starter/ice
	themed_form = FORM_ICE
	designlist = list("steel")

/obj/item/spellbook/expert/starter/lightning
	themed_form = FORM_LIGHTNING
	designlist = list("steel")

/obj/item/spellbook/expert/starter/earth
	themed_form = FORM_EARTH
	designlist = list("steel")

/obj/item/spellbook/expert/starter/arcane
	themed_form = FORM_ARCANE
	designlist = list("gem")

/obj/item/spellbook/expert/starter/death
	themed_form = FORM_DEATH
	designlist = list("skin")

/obj/item/spellbook/expert/starter/life
	themed_form = FORM_LIFE
	designlist = list("mimic")

/obj/item/spellbook/expert/starter/air
	themed_form = FORM_AIR
	designlist = list("steel")

/obj/item/spellbook/expert/starter/water
	themed_form = FORM_WATER
	designlist = list("steel")

/obj/item/spellbook/master/starter
	abstract_type = /obj/item/spellbook/master/starter
	themed_cost_multiplier = 0.80
	themed_cast_speed_multiplier = 1.40
	themed_magnitude_bonus = 0.5

/obj/item/spellbook/master/starter/fire
	themed_form = FORM_FIRE
	designlist = list("steel")

/obj/item/spellbook/master/starter/ice
	themed_form = FORM_ICE
	designlist = list("steel")

/obj/item/spellbook/master/starter/lightning
	themed_form = FORM_LIGHTNING
	designlist = list("steel")

/obj/item/spellbook/master/starter/earth
	themed_form = FORM_EARTH
	designlist = list("steel")

/obj/item/spellbook/master/starter/arcane
	themed_form = FORM_ARCANE
	designlist = list("gem")

/obj/item/spellbook/master/starter/death
	themed_form = FORM_DEATH
	designlist = list("skin")

/obj/item/spellbook/master/starter/life
	themed_form = FORM_LIFE
	designlist = list("mimic")

/obj/item/spellbook/master/starter/air
	themed_form = FORM_AIR
	designlist = list("steel")

/obj/item/spellbook/master/starter/water
	themed_form = FORM_WATER
	designlist = list("steel")
