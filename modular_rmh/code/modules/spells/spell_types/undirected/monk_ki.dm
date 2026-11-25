// Monk Ki on the class feature pools.

/datum/action/cooldown/spell/undirected/longstrider/ki
	name = "Ki: Longstrider"
	desc = "Grant yourself and any creatures adjacent to you free movement through rough terrain. Spends one Ki point, which a short rest restores."
	spell_cost = 0
	// Keeps the Ki copy out of the Rituos choices.
	spell_flags = NONE
	slot_level = null
	learnable = FALSE
	feature_id = FEATURE_KI
	feature_rest = REST_SHORT

/datum/action/cooldown/spell/undirected/feather_falling/ki
	name = "Ki: Feather Falling"
	desc = "Grant yourself and any creatures adjacent to you some defense against falls. Spends one Ki point, which a short rest restores."
	spell_cost = 0
	spell_flags = NONE
	slot_level = null
	learnable = FALSE
	feature_id = FEATURE_KI
	feature_rest = REST_SHORT

/datum/action/cooldown/spell/healing/ki
	name = "Ki: Hand of Healing"
	desc = "Channel ki through your palm to mend wounds, and to steady the dying: every limb knits a little, shock lifts and breath returns. Spends one Ki point, which a short rest restores."
	spell_cost = 0
	slot_level = null
	learnable = FALSE
	slot_label = "Hand of Healing"
	feature_id = FEATURE_KI
	feature_rest = REST_SHORT
	base_healing = 40
	wound_modifier = 0.5
	/// Healing spread over every limb of a dying patient.
	var/stabilize_healing = 15

/// A patient in shock or below zero health is pulled back from the brink after the normal heal.
/datum/action/cooldown/spell/healing/ki/cast(mob/living/cast_on)
	. = ..()
	if(QDELETED(cast_on) || !iscarbon(cast_on) || cast_on.stat == DEAD)
		return
	if((cast_on.mob_biotypes & MOB_UNDEAD) || HAS_TRAIT(cast_on, TRAIT_ASTRATA_CURSE))
		return
	var/mob/living/carbon/patient = cast_on
	if(!patient.InCritical() && patient.shock_stage < SHOCK_STAGE_4 && patient.health > 0)
		return
	for(var/obj/item/bodypart/limb as anything in patient.bodyparts)
		limb.heal_damage(stabilize_healing, stabilize_healing)
		for(var/datum/injury/injury as anything in limb.injuries)
			if(injury.damage_type == WOUND_DIVINE)
				continue
			injury.heal_damage(stabilize_healing)
	patient.adjustOxyLoss(-40)
	patient.setShockStage(min(patient.shock_stage, SHOCK_STAGE_2))
	patient.SetUnconscious(0)
	patient.update_damage_overlays()
	patient.visible_message(span_notice("[owner]'s steady hand pulls [patient] back from the brink."), span_notice("Warmth spreads from the hand on my chest; the dark draws back and I can breathe again."))
