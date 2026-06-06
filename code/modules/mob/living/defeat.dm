/mob/living
	/// Player-facing defeat routing preference cached from character preferences.
	var/defeat_mode = DEFEAT_MODE_DEFAULT
	/// Major damage category threshold that can convert normal defeat into the defeat system.
	var/defeat_damage_threshold = DEFEAT_DAMAGE_THRESHOLD_DEFAULT
	/// Explicit opt-in gate for AI bodies. Player-controlled bodies are evaluated separately.
	var/defeat_system_ai_opt_in = FALSE
	/// Most recent defeat snapshot captured before stabilization/rune routing.
	var/datum/defeat_snapshot/last_defeat_snapshot

/mob/living/proc/cache_defeat_preferences_from_prefs(datum/preferences/prefs)
	if(!prefs)
		return
	defeat_mode = prefs.get_defeat_mode()
	defeat_damage_threshold = prefs.get_defeat_damage_threshold()
	ensure_defeat_monitor()

/mob/living/proc/ensure_defeat_monitor()
	if(defeat_mode == DEFEAT_MODE_NO_RETURN)
		return
	if(!defeat_system_is_eligible())
		return
	AddComponent(/datum/component/defeat_monitor)

/mob/living/proc/defeat_system_is_eligible()
	if(defeat_mode == DEFEAT_MODE_NO_RETURN)
		return FALSE
	if(!iscarbon(src))
		return FALSE
	if(defeat_system_ai_opt_in)
		return TRUE
	if(client || mind)
		return TRUE
	return FALSE

/mob/living/proc/handle_defeat_health_update()
	var/datum/component/defeat_monitor/monitor = GetComponent(/datum/component/defeat_monitor)
	return monitor?.check_defeat_triggers()

/mob/living/proc/handle_defeat_life_update()
	var/datum/component/defeat_monitor/monitor = GetComponent(/datum/component/defeat_monitor)
	return monitor?.check_defeat_triggers()

/mob/living/proc/enter_defeat(reason = DEFEAT_REASON_DAMAGE, severity = DEFEAT_SEVERITY_NORMAL, mob/living/source)
	if(!defeat_system_is_eligible())
		return FALSE
	if(has_status_effect(/datum/status_effect/defeat_knockout))
		return FALSE

	var/mob/living/carbon/carbon_target = src
	if(!istype(carbon_target))
		return FALSE

	var/datum/defeat_snapshot/snapshot = new
	if(!snapshot.capture_from(carbon_target, reason, severity, source))
		qdel(snapshot)
		return FALSE

	last_defeat_snapshot = snapshot
	apply_status_effect(/datum/status_effect/defeat_knockout)
	defeat_stabilize_from_snapshot(snapshot)
	return TRUE

/mob/living/proc/defeat_rescue(mob/living/helper, rescue_source = "help")
	if(!has_status_effect(/datum/status_effect/defeat_knockout))
		return FALSE
	if(!defeat_can_be_rescued_by(helper))
		return FALSE

	remove_status_effect(/datum/status_effect/defeat_knockout)
	apply_defeat_snapshot_debuffs()
	SEND_SIGNAL(src, COMSIG_LIVING_DEFEAT_RESCUED, helper, rescue_source)
	return TRUE

/mob/living/proc/defeat_can_be_rescued_by(mob/living/helper)
	if(!helper || helper == src)
		return FALSE
	if(stat == DEAD || helper.stat == DEAD)
		return FALSE
	if(!helper.Adjacent(src))
		return FALSE
	if(defeat_is_active_harm_from(helper))
		return FALSE
	return TRUE

/mob/living/proc/defeat_is_active_harm_from(mob/living/helper)
	if(!helper)
		return FALSE
	if(pulledby == helper && helper.grab_state >= GRAB_AGGRESSIVE)
		return TRUE
	if(helper.pulling == src && helper.grab_state >= GRAB_AGGRESSIVE)
		return TRUE
	if(defeat_recent_source_is(helper) && recent_damage_source_time && world.time - recent_damage_source_time <= DEFEAT_ACTIVE_HARM_WINDOW)
		return TRUE
	if(helper.ai_controller?.current_movement_target == src)
		return TRUE
	return FALSE

/mob/living/proc/defeat_try_auto_rescue_from_healing(mob/living/helper, amount = 0, rescue_source = "healing")
	if(!has_status_effect(/datum/status_effect/defeat_knockout))
		return FALSE
	if(amount < DEFEAT_AUTO_RESCUE_HEALING_THRESHOLD)
		return FALSE
	return defeat_rescue(helper, rescue_source)

/mob/living/proc/defeat_recent_source_is(mob/living/helper)
	if(!helper)
		return FALSE
	var/mob/living/snapshot_source = last_defeat_snapshot?.source_weakref?.resolve()
	if(snapshot_source == helper)
		return TRUE
	var/mob/living/recent_damage_source = recent_damage_source_attacker_weakref?.resolve()
	if(recent_damage_source == helper)
		return TRUE
	return FALSE

/mob/living/proc/defeat_is_immediate_rune_hazard()
	if(!defeat_is_immediate_hazard())
		return FALSE
	if(!ishuman(src))
		return FALSE

	var/mob/living/carbon/human/human_target = src
	if(!human_target.rune_linked)
		return FALSE

	var/datum/resurrection_rune_controller/rune_controller = get_resurrection_rune_controller_for_user(human_target)
	return rune_controller?.can_queue_rescue_for(human_target)

/mob/living/proc/defeat_is_immediate_hazard()
	var/turf/current_turf = get_turf(src)
	return istype(current_turf, /turf/open/lava) || istype(current_turf, /turf/open/lava/acid)

/mob/living/proc/apply_defeat_snapshot_debuffs()
	var/datum/defeat_snapshot/snapshot = last_defeat_snapshot
	if(!snapshot)
		return FALSE
	var/debuff_type = snapshot.defeat_debuff_type()
	if(!debuff_type)
		return FALSE
	apply_defeat_trauma_status(debuff_type, snapshot.severity)
	return TRUE

/mob/living/proc/apply_defeat_trauma_status(datum/status_effect/debuff/defeat/debuff_type, severity = DEFEAT_SEVERITY_NORMAL)
	var/new_rank = defeat_severity_rank(severity)
	var/status_id = initial(debuff_type.id)
	for(var/datum/status_effect/debuff/defeat/existing_trauma as anything in status_effects)
		if(existing_trauma.id != status_id)
			continue
		if(defeat_severity_rank(existing_trauma.severity) >= new_rank)
			existing_trauma.refresh(src, null, existing_trauma.severity)
			return existing_trauma
		qdel(existing_trauma)
		break
	return apply_status_effect(debuff_type, null, severity)

/mob/living/proc/defeat_treat_trauma(mob/living/helper, treatment_type = DEFEAT_TREATMENT_MEDICAL)
	if(!helper || helper.stat == DEAD)
		return FALSE

	var/treated = FALSE
	switch(treatment_type)
		if(DEFEAT_TREATMENT_MEDICAL)
			if(!helper.defeat_can_do_medical_treatment())
				return FALSE
			treated = defeat_clear_matching_trauma(helper, list(
				/datum/status_effect/debuff/defeat/physical,
				/datum/status_effect/debuff/defeat/physical/wound,
				/datum/status_effect/debuff/defeat/physical/burn,
				/datum/status_effect/debuff/defeat/physical/body,
				/datum/status_effect/debuff/defeat/physical/concussion,
				/datum/status_effect/debuff/defeat/pain,
			), treatment_type)
		if(DEFEAT_TREATMENT_SPIRITUAL)
			if(!helper.defeat_can_do_spiritual_treatment())
				return FALSE
			treated = defeat_clear_matching_trauma(helper, list(
				/datum/status_effect/debuff/defeat/rune,
				/datum/status_effect/debuff/defeat/horny,
			), treatment_type)
		if(DEFEAT_TREATMENT_UNIVERSAL)
			treated = defeat_clear_one_trauma()
			if(treated)
				SEND_SIGNAL(src, COMSIG_LIVING_DEFEAT_TREATED, helper, treatment_type)
	return treated

/mob/living/proc/defeat_clear_matching_trauma(mob/living/helper, list/trauma_types, treatment_type = DEFEAT_TREATMENT_MEDICAL)
	var/treated = FALSE
	for(var/trauma_type in trauma_types)
		treated = remove_status_effect(trauma_type) || treated
	if(treated)
		SEND_SIGNAL(src, COMSIG_LIVING_DEFEAT_TREATED, helper, treatment_type)
	return treated

/mob/living/proc/defeat_treat_tool_physical_trauma(mob/living/helper, list/trauma_types)
	if(!helper || helper.stat == DEAD)
		return FALSE
	if(!helper.defeat_can_do_medical_treatment())
		return FALSE
	return defeat_clear_matching_trauma(helper, trauma_types, DEFEAT_TREATMENT_MEDICAL)

/mob/living/proc/defeat_attempt_adjacent_treatment(mob/living/helper, treatment_type = DEFEAT_TREATMENT_MEDICAL)
	if(!helper || helper == src)
		return FALSE
	if(stat == DEAD || helper.stat == DEAD)
		return FALSE
	if(!helper.Adjacent(src))
		return FALSE

	var/treatment_time = defeat_treatment_time(helper, treatment_type)
	if(!do_after(helper, treatment_time, target = src))
		return FALSE
	if(!defeat_treat_trauma(helper, treatment_type))
		to_chat(helper, span_warning("There is no matching defeat trauma I can treat."))
		return FALSE
	helper.visible_message(span_notice("[helper] treats the lingering defeat trauma in [src]."), span_notice("I treat the lingering defeat trauma in [src]."))
	return TRUE

/mob/living/proc/defeat_treatment_time(mob/living/helper, treatment_type = DEFEAT_TREATMENT_MEDICAL)
	var/skill_value = 0
	if(treatment_type == DEFEAT_TREATMENT_SPIRITUAL)
		skill_value = GET_MOB_SKILL_VALUE_OLD(helper, /datum/attribute/skill/magic/holy)
	else
		skill_value = GET_MOB_SKILL_VALUE_OLD(helper, /datum/attribute/skill/misc/medicine)
	return max(8 SECONDS, 12 SECONDS - (skill_value * 0.5 SECONDS))

/mob/living/verb/treat_defeat_trauma_medical()
	set name = "Treat Defeat Trauma"
	set category = "IC"
	set src in oview(1)

	var/mob/living/helper = usr
	defeat_attempt_adjacent_treatment(helper, DEFEAT_TREATMENT_MEDICAL)

/mob/living/verb/treat_defeat_trauma_spiritual()
	set name = "Soothe Defeat Trauma"
	set category = "IC"
	set src in oview(1)

	var/mob/living/helper = usr
	defeat_attempt_adjacent_treatment(helper, DEFEAT_TREATMENT_SPIRITUAL)

/mob/living/proc/defeat_can_do_medical_treatment()
	return HAS_TRAIT(src, TRAIT_SURGEON) || (get_skill_level(/datum/skill/misc/medicine) >= SKILL_RANK_APPRENTICE)

/mob/living/proc/defeat_can_do_spiritual_treatment()
	return HAS_TRAIT(src, TRAIT_HOLY) || (get_skill_level(/datum/skill/magic/holy) >= SKILL_RANK_NOVICE)

/mob/living/proc/defeat_clear_one_trauma()
	var/list/trauma_types = list(
		/datum/status_effect/debuff/defeat/physical,
		/datum/status_effect/debuff/defeat/physical/wound,
		/datum/status_effect/debuff/defeat/physical/burn,
		/datum/status_effect/debuff/defeat/physical/body,
		/datum/status_effect/debuff/defeat/physical/concussion,
		/datum/status_effect/debuff/defeat/pain,
		/datum/status_effect/debuff/defeat/rune,
		/datum/status_effect/debuff/defeat/horny,
	)
	for(var/trauma_type in trauma_types)
		if(remove_status_effect(trauma_type))
			return TRUE
	return FALSE

/mob/living/proc/has_any_defeat_trauma()
	for(var/datum/status_effect/debuff/defeat/trauma as anything in status_effects)
		if(istype(trauma))
			return TRUE
	return FALSE

/mob/living/proc/has_any_defeat_physical_trauma()
	return has_status_effect(/datum/status_effect/debuff/defeat/physical) \
		|| has_status_effect(/datum/status_effect/debuff/defeat/physical/wound) \
		|| has_status_effect(/datum/status_effect/debuff/defeat/physical/burn) \
		|| has_status_effect(/datum/status_effect/debuff/defeat/physical/body) \
		|| has_status_effect(/datum/status_effect/debuff/defeat/physical/concussion)

/mob/living/proc/defeat_stabilize_from_snapshot(datum/defeat_snapshot/snapshot)
	defeat_stabilize_live_damage()
	if(iscarbon(src))
		var/mob/living/carbon/carbon_target = src
		carbon_target.defeat_stabilize_active_injuries()

/mob/living/proc/defeat_stabilize_live_damage(run_update = TRUE)
	setBruteLoss(0, FALSE, TRUE)
	setFireLoss(0, FALSE, TRUE)
	setToxLoss(0, FALSE, TRUE)
	setOxyLoss(0, FALSE, TRUE)
	setCloneLoss(0, FALSE, TRUE)
	setPainLoss(0, FALSE, TRUE)
	setShockStage(0, FALSE, TRUE)
	if(run_update)
		updatehealth()

/mob/living/carbon/proc/defeat_stabilize_active_injuries(run_update = TRUE)
	var/cleared_anything = FALSE

	for(var/obj/item/bodypart/bodypart as anything in bodyparts)
		if(!bodypart)
			continue
		if(length(bodypart.embedded_objects))
			var/list/embedded_to_clear = bodypart.embedded_objects.Copy()
			for(var/obj/item/embedded_item as anything in embedded_to_clear)
				if(bodypart.remove_embedded_object(embedded_item))
					cleared_anything = TRUE

	if(length(simple_embedded_objects))
		var/list/simple_embedded_to_clear = simple_embedded_objects.Copy()
		for(var/obj/item/embedded_item as anything in simple_embedded_to_clear)
			if(simple_remove_embedded_object(embedded_item))
				cleared_anything = TRUE

	if(length(all_injuries))
		var/list/injuries_to_clear = all_injuries.Copy()
		for(var/datum/injury/injury as anything in injuries_to_clear)
			if(!injury || QDELETED(injury))
				continue
			var/obj/item/bodypart/injured_bodypart = injury.parent_bodypart
			if(length(injury.embedded_objects))
				var/list/injury_embedded_to_clear = injury.embedded_objects.Copy()
				for(var/obj/item/embedded_item as anything in injury_embedded_to_clear)
					if(injured_bodypart?.remove_embedded_object(embedded_item))
						cleared_anything = TRUE
					else if(simple_remove_embedded_object(embedded_item))
						cleared_anything = TRUE
			if(injury.damage > 0)
				injury.heal_damage(injury.damage)
			if(!QDELETED(injury))
				qdel(injury)
			cleared_anything = TRUE

	for(var/obj/item/bodypart/bodypart as anything in bodyparts)
		bodypart.update_damages()
		bodypart.update_bodypart_damage_state()

	if(run_update)
		update_damage_overlays()
		updatehealth()
	return cleared_anything

/datum/defeat_snapshot
	var/reason
	var/severity = DEFEAT_SEVERITY_NORMAL
	var/brute_loss = 0
	var/burn_loss = 0
	var/tox_loss = 0
	var/oxy_loss = 0
	var/clone_loss = 0
	var/pain_loss = 0
	var/traumatic_shock = 0
	var/shock_stage = 0
	var/worst_body_zone
	var/worst_bodypart_name
	var/worst_injury_type
	var/worst_injury_stage = 0
	var/worst_injury_damage = 0
	var/source_name
	var/source_type
	var/source_ckey
	var/datum/weakref/source_weakref
	var/created_at = 0

/datum/defeat_snapshot/proc/capture_from(mob/living/carbon/target, new_reason, new_severity = DEFEAT_SEVERITY_NORMAL, mob/living/source)
	if(!target)
		return FALSE

	reason = new_reason
	severity = new_severity
	brute_loss = target.getBruteLoss()
	burn_loss = target.getFireLoss()
	tox_loss = target.getToxLoss()
	oxy_loss = target.getOxyLoss()
	clone_loss = target.getCloneLoss()
	pain_loss = target.getPainLoss()
	traumatic_shock = target.getShock()
	shock_stage = target.shock_stage
	created_at = world.time

	if(source)
		source_name = source.name
		source_type = source.type
		source_ckey = source.ckey
		source_weakref = WEAKREF(source)
	else
		source_name = target.recent_damage_source_name
		source_type = target.recent_damage_source_mob_type
		source_weakref = target.recent_damage_source_attacker_weakref

	capture_worst_injury(target)
	return TRUE

/datum/defeat_snapshot/proc/defeat_debuff_type()
	switch(reason)
		if(DEFEAT_REASON_DAMAGE, DEFEAT_REASON_DEATH, DEFEAT_REASON_HAZARD)
			switch(worst_injury_type)
				if(WOUND_SLASH, WOUND_PIERCE, WOUND_BITE, WOUND_LASH, WOUND_SCRATCH, WOUND_ARTERY, WOUND_TENDON, WOUND_NERVE)
					return /datum/status_effect/debuff/defeat/physical/wound
				if(WOUND_BURN)
					return /datum/status_effect/debuff/defeat/physical/burn
				if(WOUND_BLUNT, WOUND_INTERNAL_BRUISE)
					if(worst_body_zone == BODY_ZONE_HEAD)
						return /datum/status_effect/debuff/defeat/physical/concussion
					return /datum/status_effect/debuff/defeat/physical/body
			return /datum/status_effect/debuff/defeat/physical
		if(DEFEAT_REASON_PAIN)
			return /datum/status_effect/debuff/defeat/pain
		if(DEFEAT_REASON_HORNY)
			return /datum/status_effect/debuff/defeat/horny
	return /datum/status_effect/debuff/defeat/physical

/proc/defeat_severity_rank(severity)
	switch(severity)
		if(DEFEAT_SEVERITY_LIGHT)
			return 1
		if(DEFEAT_SEVERITY_SEVERE)
			return 3
	return 2

/datum/defeat_snapshot/proc/capture_worst_injury(mob/living/carbon/target)
	for(var/datum/injury/injury as anything in target.all_injuries)
		if(!injury || injury.damage < worst_injury_damage)
			continue
		worst_injury_damage = injury.damage
		worst_injury_stage = injury.current_stage
		worst_injury_type = injury.damage_type
		var/obj/item/bodypart/bodypart = injury.parent_bodypart
		if(bodypart)
			worst_body_zone = bodypart.body_zone
			worst_bodypart_name = bodypart.name
