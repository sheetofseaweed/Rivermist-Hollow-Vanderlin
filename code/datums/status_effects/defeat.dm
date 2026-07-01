/datum/status_effect/defeat_knockout
	id = "defeat_knockout"
	duration = STATUS_EFFECT_PERMANENT
	alert_type = /atom/movable/screen/alert/status_effect/defeat_knockout
	remove_on_fullheal = FALSE
	/// Timer that lets a horny knockout wear off on its own (the light case); null for other defeats.
	var/self_recover_timer

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
	// Severity is required: overlay_fullscreen builds the icon_state as "[base][severity]", and only the
	// numbered "oxydamageoverlay[4-10]" states exist. 8 = heavy tunnel vision, see only right around you.
	owner.overlay_fullscreen("defeat", /atom/movable/screen/fullscreen/defeat, 8)
	var/horny_defeat = owner.last_defeat_snapshot?.reason == DEFEAT_REASON_HORNY
	if(horny_defeat)
		// A horny defeat reads differently: the dark vignette stays, but the pink arousal wash (the
		// existing "lovehud" overlay) floods over it, so it never looks like a plain beatdown.
		owner.overlay_fullscreen("defeat_horny", /atom/movable/screen/fullscreen/love, 10)
		to_chat(owner, span_userdanger("Your body finally gives out, overwhelmed - you sink down, flushed and spent, too weak to resist."))
		// The light case: a horny knockout wears off on its own after a short while (unless kidnapped).
		self_recover_timer = addtimer(CALLBACK(owner, TYPE_PROC_REF(/mob/living, defeat_horny_self_recover)), DEFEAT_HORNY_SELF_RECOVER_TIME, TIMER_STOPPABLE)
	else
		to_chat(owner, span_userdanger("You are defeated. You can still speak, emote, and call for help - but darkness crowds in at the edges of your sight."))
	to_chat(owner, span_notice("Another can bring you back: a curative potion fed to you, a healer's or holy hand, or other aid - but never your own doing. If the rune is yours to call, it may answer too."))
	SEND_SIGNAL(owner, COMSIG_LIVING_DEFEATED)
	if(horny_defeat)
		owner.visible_message(span_userdanger("[owner] sinks down, overwhelmed and spent!"))
		owner.balloon_alert_to_viewers("overwhelmed!")
	else
		owner.visible_message(span_userdanger("[owner] collapses to the ground, defeated!"))
		owner.balloon_alert_to_viewers("defeated!")

/datum/status_effect/defeat_knockout/on_remove()
	if(self_recover_timer)
		deltimer(self_recover_timer)
		self_recover_timer = null
	if(!owner || QDELETED(owner))
		return
	owner.clear_fullscreen("defeat", FALSE)
	owner.clear_fullscreen("defeat_horny")
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

/atom/movable/screen/alert/status_effect/defeat_knockout
	name = "Defeated"
	desc = "You are defeated. You can speak, emote, call for help, or call the rune if available."
	icon_state = "paralysis"

/atom/movable/screen/alert/status_effect/debuff/defeat_trauma
	name = "Defeat Trauma"
	desc = "Lingering harm from a recent defeat. A town healer, priest, or potent remedy can mend it - and it festers worse each time you are defeated untreated."
	icon_state = "muscles"

/datum/status_effect/debuff/defeat
	id = "defeat_trauma"
	duration = 30 MINUTES
	status_type = STATUS_EFFECT_REPLACE
	alert_type = /atom/movable/screen/alert/status_effect/debuff/defeat_trauma
	/// Player-facing label shown on the status alert; subtypes override per injury.
	var/trauma_label = "Defeat Trauma"
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
	. = ..()
	if(. && linked_alert)
		linked_alert.name = "[trauma_label] ([defeat_severity_label(severity)])"

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
	trauma_label = "Battered Body"

/datum/status_effect/debuff/defeat/physical/defeat_base_profile()
	return list(STAT_ENDURANCE = -2, STAT_STRENGTH = -2, STAT_SPEED = -1)

/datum/status_effect/debuff/defeat/physical/defeat_apply_feedback()
	to_chat(owner, span_warning("My body protests every hard motion."))
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		carbon_owner.adjustPainLoss(severity == DEFEAT_SEVERITY_SEVERE ? 3 : 1)

/datum/status_effect/debuff/defeat/physical/wound
	id = "defeat_wound_trauma"
	trauma_label = "Open Wounds"

/datum/status_effect/debuff/defeat/physical/wound/defeat_base_profile()
	return list(STAT_ENDURANCE = -2, STAT_SPEED = -2, STAT_STRENGTH = -1)

/datum/status_effect/debuff/defeat/physical/wound/defeat_apply_feedback()
	to_chat(owner, span_warning("Old wound pain flares through my body."))
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		carbon_owner.adjustPainLoss(severity == DEFEAT_SEVERITY_SEVERE ? 4 : 2)

/datum/status_effect/debuff/defeat/physical/burn
	id = "defeat_burn_trauma"
	trauma_label = "Searing Burns"

/datum/status_effect/debuff/defeat/physical/burn/defeat_base_profile()
	return list(STAT_ENDURANCE = -2, STAT_CONSTITUTION = -2)

/datum/status_effect/debuff/defeat/physical/burn/defeat_apply_feedback()
	to_chat(owner, span_warning("My burned skin prickles with raw heat."))
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		carbon_owner.adjustPainLoss(severity == DEFEAT_SEVERITY_SEVERE ? 4 : 2)

/datum/status_effect/debuff/defeat/physical/body
	id = "defeat_body_trauma"
	trauma_label = "Internal Bruising"

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
	trauma_label = "Concussion"

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
	trauma_label = "Wrenched Leg"

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
	trauma_label = "Wrenched Arm"

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
	trauma_label = "Lingering Pain"

/datum/status_effect/debuff/defeat/pain/defeat_base_profile()
	return list(STAT_ENDURANCE = -2, STAT_PERCEPTION = -2)

/datum/status_effect/debuff/defeat/pain/defeat_apply_feedback()
	to_chat(owner, span_warning("A memory of pain rolls back through me."))
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		carbon_owner.adjustPainLoss(severity == DEFEAT_SEVERITY_SEVERE ? 5 : 2)

/datum/status_effect/debuff/defeat/rune
	id = "defeat_rune_trauma"
	trauma_label = "Mana Backlash"

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
	trauma_label = "Lewd Exhaustion"

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
