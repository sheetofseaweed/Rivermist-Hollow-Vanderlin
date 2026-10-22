// Fighter Action Surge on the class feature pools.

/datum/action/cooldown/spell/undirected/action_surge
	name = "Action Surge"
	desc = "Push past your limits: your stamina refills completely and your other stamina abilities are ready again. Spends an Action Surge charge, which a short rest restores."
	button_icon_state = "celerity"
	sound = 'sound/magic/haste.ogg'

	antimagic_flags = NONE

	associated_skill = /datum/attribute/skill/misc/athletics
	associated_stat = STAT_ENDURANCE

	charge_required = FALSE
	has_visual_effects = FALSE
	invocation_type = INVOCATION_NONE
	cooldown_time = 5 SECONDS
	spell_type = SPELL_STAMINA
	spell_cost = 0
	slot_level = null
	learnable = FALSE
	feature_id = FEATURE_ACTION_SURGE
	feature_rest = REST_SHORT

/datum/action/cooldown/spell/undirected/action_surge/is_valid_target(atom/cast_on)
	. = ..()
	if(!.)
		return
	return isliving(owner)

/// Clears all fatigue and readies every other stamina ability still on cooldown.
/datum/action/cooldown/spell/undirected/action_surge/cast(mob/living/cast_on)
	. = ..()
	cast_on.adjust_stamina(-cast_on.maximum_stamina, internal_regen = FALSE)
	for(var/datum/action/cooldown/spell/other in owner.actions)
		if(other == src || other.spell_type != SPELL_STAMINA || other.next_use_time <= world.time)
			continue
		other.reset_spell_cooldown()
	cast_on.visible_message(span_warning("[cast_on] grits [cast_on.p_their()] teeth and surges with renewed vigor!"), span_notice("I dig deep and fresh strength floods my limbs."))
