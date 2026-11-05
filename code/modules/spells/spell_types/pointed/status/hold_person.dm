// Hold Person: a paralysis the victim may shake off each few seconds.
/datum/action/cooldown/spell/status/hold_person
	name = "Hold Person"
	desc = "Lock a living humanoid in place for 12 seconds. Every 3 seconds they may break free with a constitution roll; the undead are immune. Each slot level above the second lengthens the hold by half. Needs concentration."
	button_icon_state = "thebends"
	sound = 'sound/magic/timestop.ogg'
	self_cast_possible = FALSE
	// One concentration target per caster, so a twinned cast would end the first hold.
	twinnable = FALSE

	invocation = "Be still!"
	invocation_type = INVOCATION_SHOUT

	charge_time = 1.5 SECONDS
	cooldown_time = 40 SECONDS
	spell_cost = 50
	status_effect = /datum/status_effect/debuff/held_person

	slot_level = 2
	slot_only = TRUE
	concentration = TRUE
	slot_label = "Hold Person"
	required_form = FORM_ARCANE
	required_technique = TECHNIQUE_ILLUSION
	required_level = MASTERY_RANK_ADEPT
	learnable = TRUE

/datum/action/cooldown/spell/status/hold_person/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	// Refusing here spends neither the slot nor the cooldown.
	if(!ishuman(cast_on))
		owner.balloon_alert(owner, "only works on people!")
		return . | SPELL_CANCEL_CAST
	var/mob/living/carbon/human/victim = cast_on
	if(victim.stat == DEAD || (victim.mob_biotypes & MOB_UNDEAD))
		owner.balloon_alert(owner, "no living will to seize!")
		return . | SPELL_CANCEL_CAST
	if(!can_see(owner, victim, get_cast_range()))
		owner.balloon_alert(owner, "can't see them!")
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/status/hold_person/cast(mob/living/cast_on)
	// The hold checks antimagic as it lands, so the flags ride along with the status.
	extra_args = list(antimagic_flags)
	return ..()

/datum/status_effect/debuff/held_person
	id = "held_person"
	alert_type = /atom/movable/screen/alert/status_effect/debuff/held_person
	duration = 12 SECONDS
	tick_interval = 1 SECONDS
	remove_on_fullheal = TRUE
	heal_flag_necessary = HEAL_CC_STATUS
	examine_text = span_warning("SUBJECTPRONOUN is locked rigid by an unseen force.")
	/// Time between the victim's constitution rolls to break free.
	var/break_interval = 3 SECONDS
	/// Paralysis renewed each tick; long enough to bridge a late tick.
	var/hold_refresh = 2 SECONDS
	COOLDOWN_DECLARE(break_roll_cooldown)

/datum/status_effect/debuff/held_person/on_creation(mob/living/new_owner, duration_override, antimagic_flags = NONE)
	// A warded target shrugs the hold off before it takes; the cast stays paid.
	if(antimagic_flags && new_owner?.can_block_magic(antimagic_flags))
		new_owner.visible_message(span_warning("The arcyne hold slides off [new_owner]!"), span_warning("Something grasps at my limbs and slides away."))
		playsound(new_owner, 'sound/magic/magic_nulled.ogg', 100)
		qdel(src)
		return FALSE
	return ..()

/datum/status_effect/debuff/held_person/on_apply()
	. = ..()
	COOLDOWN_START(src, break_roll_cooldown, break_interval)
	hold()
	owner.visible_message(span_danger("[owner] locks rigid, seized by arcyne force!"), span_userdanger("My limbs lock in place!"))

/datum/status_effect/debuff/held_person/tick()
	if(COOLDOWN_FINISHED(src, break_roll_cooldown))
		COOLDOWN_START(src, break_roll_cooldown, break_interval)
		if(try_break_free())
			return
	hold()

/datum/status_effect/debuff/held_person/on_remove()
	. = ..()
	if(QDELETED(owner))
		return
	// Lift only the hold's own paralysis; a longer stun from elsewhere stays.
	if(owner.IsParalyzed() && owner.AmountParalyzed() <= hold_refresh)
		owner.SetParalyzed(0)
	if(owner.IsImmobilized() && owner.AmountImmobilized() <= hold_refresh)
		owner.SetImmobilized(0)

/datum/status_effect/debuff/held_person/proc/hold()
	owner.Immobilize(hold_refresh)
	owner.Paralyze(hold_refresh)

/// Constitution in the mental context, the same roll that holds concentration through a wound.
/datum/status_effect/debuff/held_person/proc/try_break_free()
	var/result = owner.diceroll(owner.get_stat(STAT_CONSTITUTION), context = DICE_CONTEXT_MENTAL)
	if(result != DICE_SUCCESS && result != DICE_CRIT_SUCCESS)
		to_chat(owner, span_warning("I strain against the hold, but it does not give."))
		return FALSE
	owner.visible_message(span_warning("[owner] wrenches free of the arcyne hold!"), span_notice("I wrench free of the hold!"))
	qdel(src)
	return TRUE

/atom/movable/screen/alert/status_effect/debuff/held_person
	name = "Held"
	desc = "Arcyne force locks my limbs. I can strain against it every few seconds."
	icon_state = "paralyze"
