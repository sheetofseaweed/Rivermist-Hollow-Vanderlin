/**
 * Toggle spell for a partial transformation. Subtypes set kit_type and flavor;
 * the kit datum drives everything else.
 */
/datum/action/cooldown/spell/undirected/partial_transformation
	name = "Partial Shift"
	desc = "Let another shape surface, or suppress it again."
	button_icon_state = "tamebeast"

	spell_type = SPELL_RAGE
	antimagic_flags = MAGIC_RESISTANCE_HOLY
	has_visual_effects = FALSE

	invocation = null
	invocation_type = INVOCATION_NONE
	ignore_can_speak = TRUE

	charge_required = FALSE
	cooldown_time = 0
	retrigger_after_cooldown = FALSE
	spell_cost = 0

	/// Typepath of the partial_transformation_kit this spell toggles.
	var/kit_type
	/// Instantiated kit, owned by this spell.
	var/datum/partial_transformation_kit/kit

/datum/action/cooldown/spell/undirected/partial_transformation/New(Target)
	. = ..()
	if(kit_type)
		kit = new kit_type()

/datum/action/cooldown/spell/undirected/partial_transformation/Destroy()
	QDEL_NULL(kit)
	return ..()

/// Returns the active partial transformation status effect on the owner, if any.
/datum/action/cooldown/spell/undirected/partial_transformation/proc/get_active_shift()
	if(!isliving(owner))
		return null
	var/mob/living/living_owner = owner
	return living_owner.has_status_effect(/datum/status_effect/partial_transformation)

/datum/action/cooldown/spell/undirected/partial_transformation/can_cast_spell(feedback)
	. = ..()
	if(!.)
		return FALSE
	if(!kit || !ishuman(owner))
		return FALSE

	var/mob/living/living_owner = owner
	if(living_owner.stat >= UNCONSCIOUS)
		if(feedback)
			to_chat(living_owner, span_warning("I am in no condition to shift my shape."))
		return FALSE

	var/datum/status_effect/partial_transformation/active_shift = get_active_shift()
	if(active_shift)
		if(active_shift.kit != kit)
			if(feedback)
				to_chat(living_owner, span_warning("Another shape already rides my body."))
			return FALSE
		// Reverting our own form is always allowed past this point.
		return TRUE

	if(HAS_TRAIT(living_owner, TRAIT_NO_TRANSFORM))
		if(feedback)
			to_chat(living_owner, span_warning("Something prevents my body from changing right now."))
		return FALSE
	for(var/trait in kit.blocking_traits)
		if(HAS_TRAIT(living_owner, trait))
			if(feedback)
				to_chat(living_owner, span_warning(kit.get_block_message(trait)))
			return FALSE

	return TRUE

/datum/action/cooldown/spell/undirected/partial_transformation/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return .
	return . | SPELL_NO_IMMEDIATE_COOLDOWN | SPELL_NO_FEEDBACK

/datum/action/cooldown/spell/undirected/partial_transformation/cast(atom/cast_on)
	. = ..()
	var/mob/living/carbon/human/human_owner = owner
	if(!istype(human_owner) || !kit)
		return

	var/datum/status_effect/partial_transformation/active_shift = get_active_shift()
	if(active_shift)
		if(active_shift.kit != kit)
			return
		human_owner.remove_status_effect(/datum/status_effect/partial_transformation)
		to_chat(human_owner, span_notice(replacetext(kit.unshift_message, "%FORM%", kit.form_name)))
		if(kit.unshift_sound)
			playsound(human_owner, kit.unshift_sound, 60, TRUE)
		SEND_SIGNAL(human_owner, COMSIG_MOB_PARTIAL_UNSHIFTED, kit)
		StartCooldown(kit.cooldown)
		return

	var/datum/status_effect/applied = human_owner.apply_status_effect(/datum/status_effect/partial_transformation, null, kit)
	if(!applied)
		return
	to_chat(human_owner, span_userdanger(replacetext(kit.shift_message, "%FORM%", kit.form_name)))
	if(kit.shift_sound)
		playsound(human_owner, kit.shift_sound, 60, TRUE)
	SEND_SIGNAL(human_owner, COMSIG_MOB_PARTIAL_SHIFTED, kit)
	StartCooldown(kit.cooldown)
