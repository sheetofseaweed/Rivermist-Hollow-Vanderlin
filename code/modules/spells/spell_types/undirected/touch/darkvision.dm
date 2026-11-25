/datum/action/cooldown/spell/undirected/touch/darkvision
	name = "Darkvision"
	desc = "Enhance the night vision of a target you touch for half a dae."
	button_icon_state = "darkvision"
	can_cast_on_self = TRUE

	point_cost = 2
	spell_flags = SPELL_RITUOS
	cooldown_time = 6 MINUTES

	hand_path = /obj/item/melee/touch_attack/darkvision
	draw_message = "I prepare to grant Darkvision."
	drop_message = "I release my arcyne focus."
	charges = 3

	slot_level = 1
	slot_only = TRUE
	slot_label = "Darkvision"
	required_form = FORM_DEATH

/datum/action/cooldown/spell/undirected/touch/darkvision/adjust_hand_charges()
	// One spare charge above the base count.
	charges++

/datum/action/cooldown/spell/undirected/touch/darkvision/is_valid_target(atom/cast_on)
	. = ..()
	if(!.)
		return FALSE
	return isliving(cast_on)

/datum/action/cooldown/spell/undirected/touch/darkvision/cast_on_hand_hit(obj/item/melee/touch_attack/hand, mob/living/victim, mob/living/carbon/caster, list/modifiers)
	. = ..()
	if(!do_after(caster, 5 SECONDS, victim))
		return FALSE

	var/duration_increase = get_rank_multiplier() * 2 MINUTES

	if(victim != caster)
		caster.visible_message("[caster] draws a glyph in the air and touches [victim] with an arcyne focus.")
	else
		caster.visible_message("[caster] draws a glyph in the air and touches themselves with an arcyne focus.")

	victim.apply_status_effect(/datum/status_effect/buff/darkvision, (10 MINUTES + duration_increase) * hand_duration_multiplier)
	return TRUE

/obj/item/melee/touch_attack/darkvision
	name = "\improper arcyne focus"
	desc = "Touch a creature to grant them Darkvision for half a dae."
	color = "#3FBAFD"
