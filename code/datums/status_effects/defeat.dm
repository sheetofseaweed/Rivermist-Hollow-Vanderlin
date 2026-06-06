/datum/status_effect/defeat_knockout
	id = "defeat_knockout"
	duration = STATUS_EFFECT_PERMANENT
	alert_type = /atom/movable/screen/alert/status_effect/defeat_knockout
	remove_on_fullheal = FALSE

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
	to_chat(owner, span_userdanger("You are defeated. You can still speak, emote, call for help, or call the rune if it is available."))

/datum/status_effect/defeat_knockout/on_remove()
	if(!owner || QDELETED(owner))
		return
	owner.clear_fullscreen("defeat", FALSE)
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

/datum/status_effect/debuff/defeat/proc/defeat_stat_penalties(penalty)
	return list(STAT_ENDURANCE = -penalty, STAT_SPEED = -penalty)

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

/datum/status_effect/debuff/defeat/physical/defeat_stat_penalties(penalty)
	return list(STAT_ENDURANCE = -penalty, STAT_STRENGTH = -penalty, STAT_SPEED = -max(1, round(penalty * 0.5)))

/datum/status_effect/debuff/defeat/physical/defeat_apply_feedback()
	to_chat(owner, span_warning("My body protests every hard motion."))
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		carbon_owner.adjustPainLoss(severity == DEFEAT_SEVERITY_SEVERE ? 3 : 1)

/datum/status_effect/debuff/defeat/physical/wound
	id = "defeat_wound_trauma"

/datum/status_effect/debuff/defeat/physical/wound/defeat_stat_penalties(penalty)
	return list(STAT_ENDURANCE = -penalty, STAT_SPEED = -penalty)

/datum/status_effect/debuff/defeat/physical/wound/defeat_apply_feedback()
	to_chat(owner, span_warning("Old wound pain flares through my body."))
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		carbon_owner.adjustPainLoss(severity == DEFEAT_SEVERITY_SEVERE ? 4 : 2)

/datum/status_effect/debuff/defeat/physical/burn
	id = "defeat_burn_trauma"

/datum/status_effect/debuff/defeat/physical/burn/defeat_stat_penalties(penalty)
	return list(STAT_ENDURANCE = -penalty, STAT_CONSTITUTION = -penalty)

/datum/status_effect/debuff/defeat/physical/burn/defeat_apply_feedback()
	to_chat(owner, span_warning("My burned skin prickles with raw heat."))
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		carbon_owner.adjustPainLoss(severity == DEFEAT_SEVERITY_SEVERE ? 4 : 2)

/datum/status_effect/debuff/defeat/physical/body
	id = "defeat_body_trauma"

/datum/status_effect/debuff/defeat/physical/body/defeat_stat_penalties(penalty)
	return list(STAT_STRENGTH = -penalty, STAT_CONSTITUTION = -penalty, STAT_ENDURANCE = -max(1, round(penalty * 0.5)))

/datum/status_effect/debuff/defeat/physical/body/defeat_apply_feedback()
	to_chat(owner, span_warning("My battered body strains under the effort."))
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		carbon_owner.adjustPainLoss(severity == DEFEAT_SEVERITY_SEVERE ? 3 : 1)

/datum/status_effect/debuff/defeat/physical/concussion
	id = "defeat_concussion_trauma"

/datum/status_effect/debuff/defeat/physical/concussion/defeat_stat_penalties(penalty)
	return list(STAT_PERCEPTION = -penalty, STAT_INTELLIGENCE = -penalty)

/datum/status_effect/debuff/defeat/physical/concussion/defeat_apply_feedback()
	to_chat(owner, span_warning("My thoughts swim and the world tilts."))
	owner.adjust_dizzy(severity == DEFEAT_SEVERITY_SEVERE ? 6 SECONDS : 3 SECONDS)
	if(severity != DEFEAT_SEVERITY_LIGHT)
		owner.adjust_confusion(2 SECONDS)

/datum/status_effect/debuff/defeat/pain
	id = "defeat_pain_trauma"

/datum/status_effect/debuff/defeat/pain/defeat_stat_penalties(penalty)
	return list(STAT_ENDURANCE = -penalty, STAT_PERCEPTION = -penalty)

/datum/status_effect/debuff/defeat/pain/defeat_apply_feedback()
	to_chat(owner, span_warning("A memory of pain rolls back through me."))
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		carbon_owner.adjustPainLoss(severity == DEFEAT_SEVERITY_SEVERE ? 5 : 2)

/datum/status_effect/debuff/defeat/rune
	id = "defeat_rune_trauma"

/datum/status_effect/debuff/defeat/rune/defeat_stat_penalties(penalty)
	return list(STAT_ENDURANCE = -penalty, STAT_FORTUNE = -penalty)

/datum/status_effect/debuff/defeat/rune/defeat_apply_feedback()
	to_chat(owner, span_warning("A cold rune-weariness passes through my soul."))
	owner.flash_fullscreen("curse1")

/datum/status_effect/debuff/defeat/horny
	id = "defeat_horny_trauma"

/datum/status_effect/debuff/defeat/horny/defeat_stat_penalties(penalty)
	return list(STAT_PERCEPTION = -penalty, STAT_FORTUNE = -penalty)

/datum/status_effect/debuff/defeat/horny/defeat_apply_feedback()
	to_chat(owner, span_warning("A humiliating memory cuts through my focus."))
	if(severity == DEFEAT_SEVERITY_SEVERE)
		owner.adjust_confusion(2 SECONDS)
