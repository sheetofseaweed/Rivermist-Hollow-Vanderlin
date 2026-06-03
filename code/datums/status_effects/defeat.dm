/datum/status_effect/defeat_knockout
	id = "defeat_knockout"
	duration = STATUS_EFFECT_PERMANENT
	alert_type = null
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

/datum/status_effect/defeat_knockout/on_remove()
	if(!owner || QDELETED(owner))
		return
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

/datum/status_effect/debuff/defeat
	id = "defeat_trauma"
	duration = 30 MINUTES
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	var/severity = DEFEAT_SEVERITY_NORMAL

/datum/status_effect/debuff/defeat/on_creation(mob/living/new_owner, duration_override, severity_override)
	if(severity_override)
		severity = severity_override
	if(!duration_override)
		duration_override = defeat_duration_for_severity(severity)
	return ..()

/datum/status_effect/debuff/defeat/on_apply()
	var/penalty = defeat_penalty_for_severity(severity)
	if(penalty)
		effectedstats = list(STAT_ENDURANCE = -penalty, STAT_SPEED = -penalty)
	return ..()

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

/datum/status_effect/debuff/defeat/physical
	id = "defeat_physical_trauma"

/datum/status_effect/debuff/defeat/physical/wound
	id = "defeat_wound_trauma"

/datum/status_effect/debuff/defeat/physical/burn
	id = "defeat_burn_trauma"

/datum/status_effect/debuff/defeat/physical/body
	id = "defeat_body_trauma"

/datum/status_effect/debuff/defeat/physical/concussion
	id = "defeat_concussion_trauma"

/datum/status_effect/debuff/defeat/pain
	id = "defeat_pain_trauma"

/datum/status_effect/debuff/defeat/rune
	id = "defeat_rune_trauma"

/datum/status_effect/debuff/defeat/horny
	id = "defeat_horny_trauma"
