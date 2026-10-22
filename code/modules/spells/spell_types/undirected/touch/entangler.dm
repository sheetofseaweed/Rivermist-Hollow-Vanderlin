/datum/action/cooldown/spell/undirected/touch/entangler
	name = "Hand of Silvanus"
	desc = "Invoke a hand which will create living vines and grant protection. The minor form holds one charge and its vine withers in a minute."
	button_icon_state = "entangle"
	sound = 'sound/items/dig_shovel.ogg'

	spell_type = SPELL_MIRACLE
	associated_skill = /datum/attribute/skill/magic/holy

	cooldown_time = 5 MINUTES
	spell_cost = 15

	required_form = FORM_EARTH
	required_technique = TECHNIQUE_ALTERATION
	slot_level = 1
	minor_cost = SPELL_MINOR_COST_DEFAULT

	charges = 3
	/// Set while the hand came from a Minor cast: one charge, short-lived vines.
	var/minor_hand = FALSE

/datum/action/cooldown/spell/undirected/touch/entangler/create_hand(mob/living/carbon/cast_on)
	. = ..()
	if(!.)
		return
	// Permanent for now
	ADD_TRAIT(cast_on, TRAIT_ENTANGLER_IMMUNE, MAGIC_TRAIT)
	minor_hand = is_minor_cast()
	if(minor_hand)
		charges = 1

/datum/action/cooldown/spell/undirected/touch/entangler/cast_on_hand_hit(obj/item/melee/touch_attack/hand, atom/victim, mob/living/carbon/caster, list/modifiers)
	. = ..()
	if(isliving(victim))
		try_mark(victim)
		return FALSE // no cooldown for marking
	var/turf/to_grow = get_turf(victim)
	if(to_grow.is_blocked_turf(TRUE))
		to_chat(caster, span_warning("The blessing of the tree father can not reach here."))
		return FALSE
	for(var/obj/structure/flora/grass/tangler/real in to_grow)
		to_chat(caster, span_warning("The soil may only be blessed once."))
		return FALSE

	var/obj/structure/flora/grass/tangler/real/vine = new(to_grow)
	if(minor_hand)
		QDEL_IN(vine, 1 MINUTES)

	return TRUE

/datum/action/cooldown/spell/undirected/touch/entangler/proc/try_mark(mob/living/victim)
	var/has_trait = HAS_TRAIT_FROM(victim, TRAIT_ENTANGLER_IMMUNE, MAGIC_TRAIT)
	var/action = has_trait ? "removing" : "adding"
	owner.visible_message("[owner] presses their thumb on [victim]'s forehead and begins [action] Silvanus's mark.")
	if(!do_after(owner, 5 SECONDS, victim))
		return
	if(has_trait)
		playsound(owner, 'sound/magic/swap.ogg', 55, TRUE)
		owner.visible_message(
			span_warning("[owner] removes the mark from [victim]'s forehead."),
			span_warning("I remove the mark from [victim]'s forehead."),
		)
		to_chat(victim, span_userdanger("The vines have forsaken you."))
		REMOVE_TRAIT(victim, TRAIT_ENTANGLER_IMMUNE, MAGIC_TRAIT)
		return
	playsound(owner, 'sound/magic/ahh2.ogg', 55, TRUE)
	owner.visible_message(
		span_nicegreen("[owner] marks [victim]'s forehead."),
		span_nicegreen("I mark [victim]'s forehead."),
	)
	to_chat(victim, span_nicegreen("You are a child of the vines."))
	ADD_TRAIT(victim, TRAIT_ENTANGLER_IMMUNE, MAGIC_TRAIT)
