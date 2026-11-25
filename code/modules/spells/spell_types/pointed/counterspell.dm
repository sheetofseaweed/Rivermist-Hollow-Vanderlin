// Counterspell: a reaction that breaks a visible caster's charge.
/datum/action/cooldown/spell/counterspell
	name = "Counterspell"
	desc = "Unravel the spell a caster in sight is charging. A spell above your slot level must lose an arcyne check."
	button_icon_state = "regression"
	sound = 'sound/magic/magic_nulled.ogg'

	self_cast_possible = FALSE
	cast_range = 7

	invocation_type = INVOCATION_NONE
	charge_required = TRUE
	charge_time = 1.5 SECONDS
	cooldown_time = 20 SECONDS
	spell_cost = 40

	slot_level = 3
	slot_only = TRUE
	reaction = TRUE
	slot_label = "Counterspell"
	required_form = FORM_ARCANE
	required_technique = TECHNIQUE_DESTRUCTION
	required_level = MASTERY_RANK_EXPERT
	learnable = TRUE

/datum/action/cooldown/spell/counterspell/is_valid_target(atom/cast_on)
	. = ..()
	if(!.)
		return
	return isliving(cast_on)

/datum/action/cooldown/spell/counterspell/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	if(!can_see(owner, cast_on, get_cast_range()))
		owner.balloon_alert(owner, "can't see them!")
		return . | SPELL_CANCEL_CAST
	// Refusing here leaves the slot and the cooldown untouched.
	if(!get_charging_spell(cast_on))
		owner.balloon_alert(owner, "nothing to counter!")
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/counterspell/cast(mob/living/cast_on)
	. = ..()
	var/datum/action/cooldown/spell/target_spell = get_charging_spell(cast_on)
	if(!target_spell)
		return
	var/own_level = get_effect_level()
	if(isnull(own_level))
		own_level = slot_level
	// Legacy and cantrip casts carry no slot level and count as level 1.
	var/target_level = target_spell.get_effect_level()
	if(isnull(target_level))
		target_level = 1
	if(target_level > own_level && !win_counter_roll(target_level - own_level))
		cast_on.visible_message(
			span_warning("[owner] tries to unravel [cast_on]'s spell, but it holds!"),
			span_warning("[owner] tries to unravel my spell, but I hold it together!"),
			ignored_mobs = owner,
		)
		to_chat(owner, span_warning("The spell [cast_on] is weaving is too strong to unravel."))
		return
	stop_charge(target_spell)
	cast_on.visible_message(
		span_warning("[owner] unravels the spell [cast_on] was weaving!"),
		span_userdanger("[owner] unravels my spell!"),
		ignored_mobs = owner,
	)
	to_chat(owner, span_notice("I unravel the spell [cast_on] was weaving."))

/// The spell a mob is charging; abilities no antimagic can block are not spells to unravel.
/datum/action/cooldown/spell/counterspell/proc/get_charging_spell(mob/living/target)
	if(!isliving(target))
		return null
	for(var/datum/action/cooldown/spell/spell in target.actions)
		if(spell != src && spell.currently_charging && spell.antimagic_flags)
			return spell
	return null

/// Arcyne check against a stronger spell: effective skill over four, minus one per level of difference.
/datum/action/cooldown/spell/counterspell/proc/win_counter_roll(level_gap)
	var/mob/living/caster = owner
	var/requirement = floor(nulltozero(GET_MOB_SKILL_VALUE(caster, associated_skill)) / 4) - level_gap
	var/result = caster.diceroll(requirement, context = DICE_CONTEXT_MENTAL)
	return result == DICE_SUCCESS || result == DICE_CRIT_SUCCESS

/// cancel_casting ends click and do_after charges alike and clears the locked level and charged flag.
/datum/action/cooldown/spell/counterspell/proc/stop_charge(datum/action/cooldown/spell/target_spell)
	// The click charge failsafe timer would otherwise cancel a later charge of the same spell.
	if(target_spell.auto_cancel_timer)
		deltimer(target_spell.auto_cancel_timer)
		target_spell.auto_cancel_timer = null
	target_spell.cancel_casting()
