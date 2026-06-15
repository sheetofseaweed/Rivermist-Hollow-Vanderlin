/datum/status_effect/defeat_knockout
	id = "defeat_knockout"
	duration = STATUS_EFFECT_PERMANENT
	alert_type = /atom/movable/screen/alert/status_effect/defeat_knockout
	remove_on_fullheal = FALSE
	/// TRUE while we are actively holding the victim's view narrowed (so we know to restore it).
	var/defeat_view_clamped = FALSE
	/// The view_size offsets the victim had before we clamped them, restored on wake.
	var/defeat_saved_view_width = 0
	var/defeat_saved_view_height = 0

/datum/status_effect/defeat_knockout/on_apply()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(owner, TRAIT_NODEATH, TRAIT_STATUS_EFFECT(id))
	ADD_TRAIT(owner, TRAIT_NOSOFTCRIT, TRAIT_STATUS_EFFECT(id))
	ADD_TRAIT(owner, TRAIT_NOHARDCRIT, TRAIT_STATUS_EFFECT(id))
	ADD_TRAIT(owner, TRAIT_PACIFISM, TRAIT_STATUS_EFFECT(id))
	ADD_TRAIT(owner, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT(id))
	ADD_TRAIT(owner, TRAIT_FLOORED, TRAIT_STATUS_EFFECT(id))
	ADD_TRAIT(owner, TRAIT_HANDS_BLOCKED, TRAIT_STATUS_EFFECT(id))
	owner.cmode = FALSE
	owner.overlay_fullscreen("defeat", /atom/movable/screen/fullscreen/defeat)
	apply_defeat_vision_clamp()
	to_chat(owner, span_userdanger("You are defeated. You can still speak, emote, and call for help - but you can barely see past arm's reach."))
	to_chat(owner, span_notice("Another can bring you back: a curative potion fed to you, a healer's or holy hand, or other aid - but never your own doing. If the rune is yours to call, it may answer too."))
	SEND_SIGNAL(owner, COMSIG_LIVING_DEFEATED)

/datum/status_effect/defeat_knockout/on_remove()
	if(!owner || QDELETED(owner))
		return
	owner.clear_fullscreen("defeat", FALSE)
	remove_defeat_vision_clamp()
	to_chat(owner, span_notice("You can move again, but the defeat still clings to you."))
	if(ishuman(owner))
		var/mob/living/carbon/human/human_owner = owner
		if(!human_owner.physiology)
			return
	REMOVE_TRAIT(owner, TRAIT_NODEATH, TRAIT_STATUS_EFFECT(id))
	REMOVE_TRAIT(owner, TRAIT_NOSOFTCRIT, TRAIT_STATUS_EFFECT(id))
	REMOVE_TRAIT(owner, TRAIT_NOHARDCRIT, TRAIT_STATUS_EFFECT(id))
	REMOVE_TRAIT(owner, TRAIT_PACIFISM, TRAIT_STATUS_EFFECT(id))
	REMOVE_TRAIT(owner, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT(id))
	REMOVE_TRAIT(owner, TRAIT_FLOORED, TRAIT_STATUS_EFFECT(id))
	REMOVE_TRAIT(owner, TRAIT_HANDS_BLOCKED, TRAIT_STATUS_EFFECT(id))
	return ..()

/// Narrows the victim's view to a tight radius while they are down (design section 2.2).
/// No-ops for clientless bodies (e.g. opted-in AI) since they have no viewport.
/datum/status_effect/defeat_knockout/proc/apply_defeat_vision_clamp()
	if(defeat_view_clamped)
		return
	var/client/victim_client = owner?.client
	if(!victim_client || !victim_client.view_size)
		return
	var/list/default_size = getviewsize(victim_client.view_size.default)
	defeat_saved_view_width = victim_client.view_size.width
	defeat_saved_view_height = victim_client.view_size.height
	defeat_view_clamped = TRUE
	victim_client.view_size.setBoth(DEFEAT_KNOCKOUT_VIEW_SIZE - default_size[1], DEFEAT_KNOCKOUT_VIEW_SIZE - default_size[2])

/// Restores whatever view offsets the victim had before we clamped them.
/datum/status_effect/defeat_knockout/proc/remove_defeat_vision_clamp()
	if(!defeat_view_clamped)
		return
	defeat_view_clamped = FALSE
	var/client/victim_client = owner?.client
	if(!victim_client || !victim_client.view_size)
		return
	victim_client.view_size.setBoth(defeat_saved_view_width, defeat_saved_view_height)

/atom/movable/screen/alert/status_effect/defeat_knockout
	name = "Defeated"
	desc = "You are defeated. You can speak, emote, call for help, or call the rune if available."
	icon_state = "paralysis"

/datum/status_effect/debuff/defeat
	id = "defeat_trauma"
	duration = 30 MINUTES
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	var/severity = DEFEAT_SEVERITY_NORMAL
	var/next_feedback_at = 0

/datum/status_effect/debuff/defeat/on_creation(mob/living/new_owner, duration_override, severity_override)
	if(severity_override)
		severity = severity_override
	if(!duration_override)
		duration_override = defeat_duration_for_severity(severity)
	return ..()

/datum/status_effect/debuff/defeat/on_apply()
	var/penalty = defeat_penalty_for_severity(severity)
	if(penalty)
		effectedstats = defeat_stat_penalties(penalty)
	return ..()

/datum/status_effect/debuff/defeat/tick()
	if(!owner || world.time < next_feedback_at)
		return
	if(!prob(defeat_feedback_chance()))
		return
	next_feedback_at = world.time + rand(35 SECONDS, 70 SECONDS)
	defeat_apply_feedback()

/datum/status_effect/debuff/defeat/proc/defeat_duration_for_severity(defeat_severity)
	switch(defeat_severity)
		if(DEFEAT_SEVERITY_LIGHT)
			return 10 MINUTES
		if(DEFEAT_SEVERITY_SEVERE)
			return 60 MINUTES
	return 30 MINUTES

/datum/status_effect/debuff/defeat/proc/defeat_penalty_for_severity(defeat_severity)
	switch(defeat_severity)
		if(DEFEAT_SEVERITY_LIGHT)
			return 1
		if(DEFEAT_SEVERITY_SEVERE)
			return 3
	return 2

/// The normal-severity attribute profile for this trauma. Subtypes override with their own fixed
/// profile (see DEFEAT_SYSTEM_SPEC_ADDENDUM.md section 4). Stamina% from the design is folded into
/// STAT_ENDURANCE (about -1 per 10%). Mana% is handled separately where it matters (see rune trauma).
/datum/status_effect/debuff/defeat/proc/defeat_base_profile()
	return list(STAT_ENDURANCE = -2, STAT_SPEED = -2)

/datum/status_effect/debuff/defeat/proc/defeat_stat_penalties(penalty)
	var/list/base = defeat_base_profile()
	var/list/scaled = list()
	for(var/stat in base)
		scaled[stat] = defeat_scaled_stat(base[stat], penalty)
	return scaled

/// Scales a normal-severity stat value by the severity penalty (1 light / 2 normal / 3 severe),
/// i.e. x0.5 / x1.0 / x1.5, never letting a non-zero value round away to nothing.
/proc/defeat_scaled_stat(base, penalty)
	if(!base)
		return 0
	var/magnitude = max(1, round(abs(base) * penalty / 2 + 0.5))
	return (base < 0) ? -magnitude : magnitude

/datum/status_effect/debuff/defeat/proc/defeat_feedback_chance()
	switch(severity)
		if(DEFEAT_SEVERITY_LIGHT)
			return 8
		if(DEFEAT_SEVERITY_SEVERE)
			return 18
	return 12

/datum/status_effect/debuff/defeat/proc/defeat_apply_feedback()
	if(!owner)
		return
	to_chat(owner, span_warning("The defeat still weighs on me."))

/datum/status_effect/debuff/defeat/physical
	id = "defeat_physical_trauma"

/datum/status_effect/debuff/defeat/physical/defeat_base_profile()
	return list(STAT_ENDURANCE = -2, STAT_STRENGTH = -2, STAT_SPEED = -1)

/datum/status_effect/debuff/defeat/physical/defeat_apply_feedback()
	to_chat(owner, span_warning("My body protests every hard motion."))
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		carbon_owner.adjustPainLoss(severity == DEFEAT_SEVERITY_SEVERE ? 3 : 1)

/datum/status_effect/debuff/defeat/physical/wound
	id = "defeat_wound_trauma"

/datum/status_effect/debuff/defeat/physical/wound/defeat_base_profile()
	return list(STAT_ENDURANCE = -2, STAT_SPEED = -2, STAT_STRENGTH = -1)

/datum/status_effect/debuff/defeat/physical/wound/defeat_apply_feedback()
	to_chat(owner, span_warning("Old wound pain flares through my body."))
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		carbon_owner.adjustPainLoss(severity == DEFEAT_SEVERITY_SEVERE ? 4 : 2)

/datum/status_effect/debuff/defeat/physical/burn
	id = "defeat_burn_trauma"

/datum/status_effect/debuff/defeat/physical/burn/defeat_base_profile()
	return list(STAT_ENDURANCE = -2, STAT_CONSTITUTION = -2)

/datum/status_effect/debuff/defeat/physical/burn/defeat_apply_feedback()
	to_chat(owner, span_warning("My burned skin prickles with raw heat."))
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		carbon_owner.adjustPainLoss(severity == DEFEAT_SEVERITY_SEVERE ? 4 : 2)

/datum/status_effect/debuff/defeat/physical/body
	id = "defeat_body_trauma"

// Internal Bruising (Chest Injury) - section 4 of the spec.
/datum/status_effect/debuff/defeat/physical/body/defeat_base_profile()
	return list(STAT_ENDURANCE = -3, STAT_STRENGTH = -2, STAT_SPEED = -2, STAT_CONSTITUTION = -3)

/datum/status_effect/debuff/defeat/physical/body/defeat_apply_feedback()
	to_chat(owner, span_warning("My bruised chest strains under the effort."))
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		carbon_owner.adjustPainLoss(severity == DEFEAT_SEVERITY_SEVERE ? 3 : 1)

/datum/status_effect/debuff/defeat/physical/concussion
	id = "defeat_concussion_trauma"

// Concussion (Head Trauma) - section 4 of the spec.
/datum/status_effect/debuff/defeat/physical/concussion/defeat_base_profile()
	return list(STAT_ENDURANCE = -2, STAT_PERCEPTION = -3, STAT_INTELLIGENCE = -2, STAT_CONSTITUTION = -2, STAT_SPEED = -1, STAT_FORTUNE = -2)

/datum/status_effect/debuff/defeat/physical/concussion/defeat_apply_feedback()
	to_chat(owner, span_warning("My thoughts swim and the world tilts."))
	owner.adjust_dizzy(severity == DEFEAT_SEVERITY_SEVERE ? 6 SECONDS : 3 SECONDS)
	if(severity != DEFEAT_SEVERITY_LIGHT)
		owner.adjust_confusion(2 SECONDS)

// Sprained/Torn Knee or Ankle (Leg Injury) - random falls, can't jump. Section 4.
/datum/status_effect/debuff/defeat/physical/leg
	id = "defeat_leg_trauma"

/datum/status_effect/debuff/defeat/physical/leg/defeat_base_profile()
	return list(STAT_ENDURANCE = -3, STAT_STRENGTH = -2, STAT_SPEED = -4, STAT_FORTUNE = -1)

/datum/status_effect/debuff/defeat/physical/leg/on_apply()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(owner, TRAIT_DEFEAT_NO_JUMP, TRAIT_STATUS_EFFECT(id))

/datum/status_effect/debuff/defeat/physical/leg/on_remove()
	if(owner)
		REMOVE_TRAIT(owner, TRAIT_DEFEAT_NO_JUMP, TRAIT_STATUS_EFFECT(id))
	return ..()

/datum/status_effect/debuff/defeat/physical/leg/defeat_apply_feedback()
	to_chat(owner, span_warning("My injured leg buckles under me."))
	if(prob(severity == DEFEAT_SEVERITY_SEVERE ? 60 : 35))
		owner.Knockdown(severity == DEFEAT_SEVERITY_SEVERE ? 3 SECONDS : 1.5 SECONDS)

// Dislocated Shoulder or Fractured Arm (Arm Injury) - random item drops. Section 4.
/datum/status_effect/debuff/defeat/physical/arm
	id = "defeat_arm_trauma"

/datum/status_effect/debuff/defeat/physical/arm/defeat_base_profile()
	return list(STAT_ENDURANCE = -2, STAT_STRENGTH = -4, STAT_PERCEPTION = -1, STAT_SPEED = -2)

/datum/status_effect/debuff/defeat/physical/arm/defeat_apply_feedback()
	to_chat(owner, span_warning("My arm spasms and my grip fails."))
	if(prob(severity == DEFEAT_SEVERITY_SEVERE ? 55 : 30))
		var/obj/item/dropped = owner.get_active_held_item()
		if(dropped)
			owner.dropItemToGround(dropped)
			to_chat(owner, span_warning("[dropped] slips from my hand!"))

/datum/status_effect/debuff/defeat/pain
	id = "defeat_pain_trauma"

/datum/status_effect/debuff/defeat/pain/defeat_base_profile()
	return list(STAT_ENDURANCE = -2, STAT_PERCEPTION = -2)

/datum/status_effect/debuff/defeat/pain/defeat_apply_feedback()
	to_chat(owner, span_warning("A memory of pain rolls back through me."))
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		carbon_owner.adjustPainLoss(severity == DEFEAT_SEVERITY_SEVERE ? 5 : 2)

/datum/status_effect/debuff/defeat/rune
	id = "defeat_rune_trauma"

// Mana-Backlash Exhaustion - the toll of being yanked back by the rune. Section 4.
/datum/status_effect/debuff/defeat/rune/defeat_base_profile()
	return list(STAT_INTELLIGENCE = -4, STAT_CONSTITUTION = -3, STAT_FORTUNE = -2)

/datum/status_effect/debuff/defeat/rune/on_apply()
	. = ..()
	if(!.)
		return
	// One-time mana backlash - drains half of whatever mana the caster had left.
	if(owner.mana_pool)
		owner.mana_pool.adjust_mana(-round(owner.mana_pool.amount * 0.5))

/datum/status_effect/debuff/defeat/rune/defeat_apply_feedback()
	to_chat(owner, span_warning("A cold rune-weariness passes through my soul."))
	owner.flash_fullscreen("curse1")

/datum/status_effect/debuff/defeat/horny
	id = "defeat_horny_trauma"

/datum/status_effect/debuff/defeat/horny/defeat_base_profile()
	return list(STAT_PERCEPTION = -2, STAT_FORTUNE = -2)

/datum/status_effect/debuff/defeat/horny/defeat_apply_feedback()
	to_chat(owner, span_warning("A humiliating memory cuts through my focus."))
	if(severity == DEFEAT_SEVERITY_SEVERE)
		owner.adjust_confusion(2 SECONDS)

// 4.1 Horny debuffs - six flavors. They all inherit the "defeat_horny_trauma" id so any of them is
// cleared the same way (lifting/time/priest); they differ only in stat profile and special effects.

// Post-Climax Brain-Fog ("Can't Think Straight")
/datum/status_effect/debuff/defeat/horny/brainfog/defeat_base_profile()
	return list(STAT_PERCEPTION = -3, STAT_INTELLIGENCE = -4, STAT_CONSTITUTION = -3)

/datum/status_effect/debuff/defeat/horny/brainfog/defeat_apply_feedback()
	to_chat(owner, span_warning("I can't think straight - my head swims with afterglow."))
	if(severity != DEFEAT_SEVERITY_LIGHT)
		owner.adjust_confusion(2 SECONDS)

// Over-Sensitive Skin & Throbbing Heat ("Body on Fire")
/datum/status_effect/debuff/defeat/horny/oversensitive/defeat_base_profile()
	return list(STAT_ENDURANCE = -3, STAT_STRENGTH = -2, STAT_CONSTITUTION = -4, STAT_SPEED = -2)

/datum/status_effect/debuff/defeat/horny/oversensitive/defeat_apply_feedback()
	to_chat(owner, span_warning("My skin burns - every brush of cloth is far too much."))

// Rubbery Legs / Aroused Wobble ("Can't Walk Straight") - random falls, can't jump.
/datum/status_effect/debuff/defeat/horny/wobble/defeat_base_profile()
	return list(STAT_ENDURANCE = -3, STAT_STRENGTH = -3, STAT_SPEED = -4, STAT_FORTUNE = -2)

/datum/status_effect/debuff/defeat/horny/wobble/on_apply()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(owner, TRAIT_DEFEAT_NO_JUMP, TRAIT_STATUS_EFFECT(id))

/datum/status_effect/debuff/defeat/horny/wobble/on_remove()
	if(owner)
		REMOVE_TRAIT(owner, TRAIT_DEFEAT_NO_JUMP, TRAIT_STATUS_EFFECT(id))
	return ..()

/datum/status_effect/debuff/defeat/horny/wobble/defeat_apply_feedback()
	to_chat(owner, span_warning("My legs wobble, weak and trembling beneath me."))
	if(prob(severity == DEFEAT_SEVERITY_SEVERE ? 55 : 30))
		owner.Knockdown(severity == DEFEAT_SEVERITY_SEVERE ? 3 SECONDS : 1.5 SECONDS)

// Trembling Hands & Weak Grip ("Can't Hold On") - random item drops.
/datum/status_effect/debuff/defeat/horny/trembling/defeat_base_profile()
	return list(STAT_ENDURANCE = -2, STAT_STRENGTH = -4, STAT_PERCEPTION = -1, STAT_SPEED = -2)

/datum/status_effect/debuff/defeat/horny/trembling/defeat_apply_feedback()
	to_chat(owner, span_warning("My hands tremble - I can barely keep my grip."))
	if(prob(severity == DEFEAT_SEVERITY_SEVERE ? 50 : 28))
		var/obj/item/dropped = owner.get_active_held_item()
		if(dropped)
			owner.dropItemToGround(dropped)
			to_chat(owner, span_warning("[dropped] slips from my trembling fingers!"))

// Panting & Breathless Craving ("Can't Breathe Right")
/datum/status_effect/debuff/defeat/horny/breathless/defeat_base_profile()
	return list(STAT_ENDURANCE = -5, STAT_SPEED = -2, STAT_CONSTITUTION = -3)

/datum/status_effect/debuff/defeat/horny/breathless/defeat_apply_feedback()
	to_chat(owner, span_warning("I can't catch my breath, chest heaving uselessly."))

// Lust-Mana Overcharge ("Horny Magic Burn") - one-time mana burn like the rune backlash.
/datum/status_effect/debuff/defeat/horny/overcharge/defeat_base_profile()
	return list(STAT_INTELLIGENCE = -4, STAT_CONSTITUTION = -3, STAT_FORTUNE = -2)

/datum/status_effect/debuff/defeat/horny/overcharge/on_apply()
	. = ..()
	if(!.)
		return
	if(owner.mana_pool)
		owner.mana_pool.adjust_mana(-round(owner.mana_pool.amount * 0.5))

/datum/status_effect/debuff/defeat/horny/overcharge/defeat_apply_feedback()
	to_chat(owner, span_warning("Lust-burned magic crackles uselessly through me."))
