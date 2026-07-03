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
	defeat_ensure_emergency_rune_link()
	defeat_maybe_arm_struggle_up()
	defeat_stabilize_from_snapshot(snapshot)
	return TRUE

/// Arms the KO Only self-rescue (§8 anti-softlock) when nothing else can save the victim - i.e. a
/// non-horny defeat with no rune that can answer (KO Only always; a KO+Rune player whose rune is
/// depleted / uncallable, checked *after* the emergency-link attempt). Horny defeats self-recover light.
/mob/living/proc/defeat_maybe_arm_struggle_up()
	var/datum/status_effect/defeat_knockout/knockout = has_status_effect(/datum/status_effect/defeat_knockout)
	if(!knockout)
		return
	if(last_defeat_snapshot?.reason == DEFEAT_REASON_HORNY)
		return
	if(defeat_has_rune_safety_net())
		return
	knockout.arm_struggle_up()

/// TRUE when a linked rune can actually pull this KO+Rune victim back right now (a spendable charge).
/// A depleted or uncallable rune returns FALSE, so the victim is treated like KO Only for self-rescue.
/mob/living/proc/defeat_has_rune_safety_net()
	if(defeat_mode != DEFEAT_MODE_KO_RUNE)
		return FALSE
	var/datum/resurrection_rune_controller/controller = get_resurrection_rune_controller_for_user(src)
	return controller?.can_offer_defeat_rune_return(src)

/// Safeguard for KO+Rune players who fall with no working rune link (never linked, or their rune was
/// destroyed): forge an emergency bond to the public city rune on the spot, so the rune-return path
/// can still reach them instead of leaving them stranded as if they were KO Only. No-op for other modes.
/mob/living/proc/defeat_ensure_emergency_rune_link()
	if(defeat_mode != DEFEAT_MODE_KO_RUNE)
		return FALSE
	if(!ishuman(src) || !mind)
		return FALSE
	// Already tied to a live rune - nothing to do.
	if(get_resurrection_rune_controller_for_user(src))
		return FALSE
	var/obj/structure/resurrection_rune/emergency_rune = get_emergency_resurrection_rune()
	if(!emergency_rune?.resrunecontroler)
		return FALSE
	if(!emergency_rune.resrunecontroler.add_user(src))
		return FALSE
	to_chat(src, span_blue("As you fall, a distant rune flickers alight and seizes your fading thread - an emergency bond, forged in the nick of time."))
	return TRUE

/mob/living/proc/defeat_rescue(mob/living/helper, rescue_source = "help")
	if(!has_status_effect(/datum/status_effect/defeat_knockout))
		return FALSE
	if(!defeat_can_be_rescued_by(helper))
		return FALSE
	return perform_defeat_rescue(helper, rescue_source)

/// Rescue with no helper, for environmental sources (a healing spring, a holy site...) that the
/// design allows as an exception to the "another player / non-hostile mob" source rule.
/mob/living/proc/defeat_environmental_rescue(rescue_source = "spring")
	if(!has_status_effect(/datum/status_effect/defeat_knockout))
		return FALSE
	return perform_defeat_rescue(null, rescue_source)

/// Shared rescue body: clear the knockout, apply the aftermath trauma, and announce it.
/mob/living/proc/perform_defeat_rescue(mob/living/helper, rescue_source)
	remove_status_effect(/datum/status_effect/defeat_knockout)
	apply_defeat_snapshot_debuffs()
	SEND_SIGNAL(src, COMSIG_LIVING_DEFEAT_RESCUED, helper, rescue_source)
	return TRUE

/// A horny knockout is the light case: after DEFEAT_HORNY_SELF_RECOVER_TIME the victim picks themselves
/// back up unaided (still keeping the Lewd Exhaustion aftermath). Suppressed once kidnapped - captivity
/// runs on its own KO-release clock, so a captive can't wriggle free just by waiting out this timer.
/mob/living/proc/defeat_horny_self_recover()
	if(!has_status_effect(/datum/status_effect/defeat_knockout))
		return FALSE
	if(GetComponent(/datum/component/kidnap_captivity))
		return FALSE
	to_chat(src, span_notice("The haze of exhaustion lifts - your strength trickles back, and you pull yourself together."))
	return perform_defeat_rescue(null, "self-recovery")

/// KO Only anti-softlock: with no rune and no rescuer, a downed victim can drag themselves up on their
/// own (the "Struggle to Your Feet" action, or the auto safety-net). The price is Grievous Wounds, on
/// top of the usual injury - so being rescued by another stays strictly better. Suppressed once kidnapped.
/mob/living/proc/defeat_ko_only_self_recover()
	if(!has_status_effect(/datum/status_effect/defeat_knockout))
		return FALSE
	if(GetComponent(/datum/component/kidnap_captivity))
		return FALSE
	to_chat(src, span_userdanger("Gritting your teeth, you drag yourself up from defeat - broken, but alive. You will have to limp to the town clinic to be made whole."))
	perform_defeat_rescue(null, "struggle")
	apply_defeat_trauma_status(/datum/status_effect/debuff/defeat/grievous, DEFEAT_SEVERITY_SEVERE)
	return TRUE

/// Empty-handed revive channel length, scaled by the reviver's medicine skill: no skill takes the
/// longest (DEFEAT_REVIVE_TIME_MAX), legendary the shortest (DEFEAT_REVIVE_TIME_MIN).
/mob/living/proc/defeat_revive_time()
	var/rank = clamp(get_skill_level(/datum/skill/misc/medicine), SKILL_RANK_NONE, SKILL_RANK_LEGENDARY)
	return round(DEFEAT_REVIVE_TIME_MAX - (rank / SKILL_RANK_LEGENDARY) * (DEFEAT_REVIVE_TIME_MAX - DEFEAT_REVIVE_TIME_MIN))

/// A loyal pet/ally beside a downed friend frees them - the rescuer is a valid non-hostile mob, so
/// this is the testable core of the pet-rescue behaviour (and a reusable primitive for other helpers).
/mob/living/proc/try_rescue_downed_ally(mob/living/fallen)
	if(!istype(fallen) || fallen == src)
		return FALSE
	if(!fallen.has_status_effect(/datum/status_effect/defeat_knockout))
		return FALSE
	if(!Adjacent(fallen))
		return FALSE
	return fallen.defeat_rescue(src, "loyal companion")

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

/// A helper feeding a downed victim a drink holding enough curative reagent rescues them from
/// knockout (design section 3.1: "a potion can revive you - but only another's, never your own").
/// Self-administered drinks never reach here (the feed path requires feeder != target).
/obj/item/reagent_containers/proc/defeat_try_potion_rescue(mob/living/target, mob/living/feeder)
	if(!isliving(target) || !isliving(feeder) || target == feeder)
		return FALSE
	if(!target.has_status_effect(/datum/status_effect/defeat_knockout))
		return FALSE
	if(!reagents)
		return FALSE
	var/healing_volume = 0
	for(var/datum/reagent/medicine/medicine in reagents.reagent_list)
		healing_volume += medicine.volume
	if(healing_volume < DEFEAT_AUTO_RESCUE_HEALING_THRESHOLD)
		return FALSE
	return target.defeat_try_auto_rescue_from_healing(feeder, healing_volume, "potion")

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
	if(!current_turf)
		return FALSE
	// Only lava/acid and open chasms are "unfair instant death" turfs worth an auto-rune - but only
	// if the turf would actually claim us *right now*. can_traverse_safely already excludes anyone
	// merely passing over: flying, floating, mid-jump (thrown), or phasing/shadow-walking. So a jump
	// across a lava channel no longer triggers the rune - only genuinely standing in it does.
	if(islava(current_turf) || istype(current_turf, /turf/open/openspace))
		return !current_turf.can_traverse_safely(src)
	return FALSE

/// This fork's actual lethal conditions, so the defeat net catches every death path - not just the
/// health floor (tox/oxy/face-burn), but also bleed-out and brain death (how brute/burn really kill).
/mob/living/proc/defeat_is_near_death()
	if(health <= HEALTH_THRESHOLD_DEAD)
		return TRUE
	if(blood_volume <= BLOOD_VOLUME_SURVIVE && !HAS_TRAIT(src, TRAIT_BLOODLOSS_IMMUNE))
		return TRUE
	if(iscarbon(src))
		var/mob/living/carbon/carbon_src = src
		if(carbon_src.getOrganLoss(ORGAN_SLOT_BRAIN) >= BRAIN_DAMAGE_DEATH)
			return TRUE
	return FALSE

/// Damage threshold for defeat after fragility quirks (e.g. Frail, Atrophy) are applied.
/mob/living/proc/get_effective_defeat_threshold()
	var/threshold = defeat_damage_threshold || DEFEAT_DAMAGE_THRESHOLD_DEFAULT
	if(!ishuman(src))
		return threshold
	var/mob/living/carbon/human/human_src = src
	var/mult = 1
	for(var/datum/quirk/quirk as anything in human_src.quirks)
		mult *= quirk.defeat_threshold_mult
	return max(1, round(threshold * mult))

/// Draws a blood tax from this mob to power the resurrection rune.
/// Stub: currently just removes the blood. TODO: deposit the drawn blood into the
/// vampire blood bank once it exists, so the rune is literally sustained by it.
/mob/living/proc/collect_blood_tax(amount)
	if(amount <= 0)
		return 0
	var/drawn = min(blood_volume, amount)
	blood_volume = max(0, blood_volume - drawn)
	return drawn

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
		// Already carrying this trauma untreated -> it festers and escalates one stage past the worse
		// of the two, capped at severe. Keep getting defeated without treatment and it only worsens.
		var/escalated_rank = min(max(defeat_severity_rank(existing_trauma.severity), new_rank) + 1, defeat_severity_rank(DEFEAT_SEVERITY_SEVERE))
		severity = defeat_severity_from_rank(escalated_rank)
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
			treated = defeat_clear_trauma_class(helper, treatment_type)
		if(DEFEAT_TREATMENT_SPIRITUAL)
			if(!helper.defeat_can_do_spiritual_treatment())
				return FALSE
			treated = defeat_clear_trauma_class(helper, treatment_type)
		if(DEFEAT_TREATMENT_UNIVERSAL)
			treated = defeat_clear_one_trauma()
			if(treated)
				SEND_SIGNAL(src, COMSIG_LIVING_DEFEAT_TREATED, helper, treatment_type)
	return treated

/// Clears every defeat trauma whose treatment_class matches. Traumas self-register their cure via
/// that var (medical/clinic by default, spiritual for rune and horny), so a new trauma subtype is
/// curable the moment it exists - no hand-maintained type list to forget it from.
/mob/living/proc/defeat_clear_trauma_class(mob/living/helper, treatment_type)
	var/treated = FALSE
	for(var/datum/status_effect/debuff/defeat/trauma in status_effects)
		if(trauma.treatment_class != treatment_type)
			continue
		qdel(trauma)
		treated = TRUE
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
	if(!defeat_treatment_zone_ok(treatment_type))
		var/zone_warning = (treatment_type == DEFEAT_TREATMENT_SPIRITUAL) ? "This rite can only be performed within a church." : "This kind of care can only be given within a clinic."
		to_chat(helper, span_warning(zone_warning))
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

/// Skill-based trauma cures must be done in the right place (design section 3.4): medical care in a
/// clinic, spiritual rites in a church. The expensive universal cure (mercy draught / absolution
/// spell) routes through DEFEAT_TREATMENT_UNIVERSAL and is the deliberate exception - works anywhere.
/mob/living/proc/defeat_treatment_zone_ok(treatment_type)
	switch(treatment_type)
		if(DEFEAT_TREATMENT_MEDICAL)
			return istype(get_area(src), /area/indoors/town/clinic_large)
		if(DEFEAT_TREATMENT_SPIRITUAL)
			return istype(get_area(src), /area/indoors/town/church)
	return TRUE

/mob/living/proc/defeat_clear_one_trauma()
	var/list/trauma_types = list(
		/datum/status_effect/debuff/defeat/physical,
		/datum/status_effect/debuff/defeat/physical/wound,
		/datum/status_effect/debuff/defeat/physical/burn,
		/datum/status_effect/debuff/defeat/physical/body,
		/datum/status_effect/debuff/defeat/physical/concussion,
		/datum/status_effect/debuff/defeat/physical/leg,
		/datum/status_effect/debuff/defeat/physical/arm,
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
		|| has_status_effect(/datum/status_effect/debuff/defeat/physical/concussion) \
		|| has_status_effect(/datum/status_effect/debuff/defeat/physical/leg) \
		|| has_status_effect(/datum/status_effect/debuff/defeat/physical/arm)

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

//////////////////////////////////////////////////
// KIDNAPPING (DEFEAT_SYSTEM_SPEC_ADDENDUM.md section 6)
// Mob lairs live off-map (the "Centcomm" z). Mappers place entrance + escape markers, both keyed by
// a shared lair_tag. Kidnapping a downed victim teleports them to an entrance marker; reaching an
// escape marker flings them back out into the wilds. Trigger wiring + surrender/NPC-in-distress are
// a later chunk - this is the captivity core.
//////////////////////////////////////////////////

/// lair_tag -> list of /obj/effect/landmark/kidnap/entrance
GLOBAL_LIST_EMPTY(kidnap_entrance_markers)
/// lair_tag -> list of /obj/effect/landmark/kidnap/escape
GLOBAL_LIST_EMPTY(kidnap_escape_markers)

/obj/effect/landmark/kidnap
	name = "kidnap marker"
	icon = 'icons/mob/landmarks.dmi'
	icon_state = "x"
	/// Entrance + escape markers sharing this tag form one lair.
	var/lair_tag = "default"

/// Drop point a kidnapped victim is teleported to inside the lair.
/obj/effect/landmark/kidnap/entrance
	name = "kidnap lair entrance"

/obj/effect/landmark/kidnap/entrance/Initialize(mapload)
	. = ..()
	LAZYADDASSOCLIST(GLOB.kidnap_entrance_markers, lair_tag, src)

/obj/effect/landmark/kidnap/entrance/Destroy()
	LAZYREMOVEASSOC(GLOB.kidnap_entrance_markers, lair_tag, src)
	return ..()

/// Escape tile inside the lair. A captive stepping onto it is flung back out into the wilds.
/obj/effect/landmark/kidnap/escape
	name = "kidnap lair escape"

/obj/effect/landmark/kidnap/escape/Initialize(mapload)
	. = ..()
	LAZYADDASSOCLIST(GLOB.kidnap_escape_markers, lair_tag, src)

/obj/effect/landmark/kidnap/escape/Destroy()
	LAZYREMOVEASSOC(GLOB.kidnap_escape_markers, lair_tag, src)
	return ..()

/obj/effect/landmark/kidnap/escape/Crossed(atom/movable/crosser, oldloc)
	. = ..()
	if(!isliving(crosser))
		return
	var/mob/living/victim = crosser
	var/datum/component/kidnap_captivity/captivity = victim.GetComponent(/datum/component/kidnap_captivity)
	if(!captivity)
		return
	victim.kidnap_escape_to_wilds(captivity)

/// Teleports a downed victim into a lair (a random entrance marker for lair_tag) and begins captivity.
/mob/living/proc/kidnap_to_lair(lair_tag, list/captor_faction = null)
	if(!has_status_effect(/datum/status_effect/defeat_knockout))
		return FALSE
	if(GetComponent(/datum/component/kidnap_captivity))
		return FALSE
	var/list/entrances = GLOB.kidnap_entrance_markers[lair_tag]
	if(!LAZYLEN(entrances))
		return FALSE
	var/obj/effect/landmark/kidnap/entrance/destination = pick(entrances)
	var/turf/destination_turf = get_turf(destination)
	if(!destination_turf)
		return FALSE
	forceMove(destination_turf)
	AddComponent(/datum/component/kidnap_captivity, lair_tag, captor_faction)
	// Anyone already in the lair sees the fresh captive hauled in; the victim gets their own line.
	visible_message(span_userdanger("[src] is dragged in and dumped on the ground, freshly captured!"), \
		span_userdanger("You are dragged off into a lair, far from any help..."))
	return TRUE

/// Frees a captive: dump them in the wilds and tear down the captivity state.
/mob/living/proc/kidnap_escape_to_wilds(datum/component/kidnap_captivity/captivity)
	if(!captivity)
		return FALSE
	var/turf/destination = get_random_kidnap_wilds_turf()
	if(destination)
		forceMove(destination)
	captivity.end_captivity()
	to_chat(src, span_notice("You drag yourself past the threshold and the world swallows you whole - free, but lost and far from home."))
	return TRUE

/// Surfaces the captive's rune-return option, reusing the rune's own eligibility (KO+Rune, charged,
/// still knocked out). Returns TRUE if the option was actually offered.
/mob/living/proc/kidnap_surface_rune_return()
	if(!ishuman(src))
		return FALSE
	var/mob/living/carbon/human/human_src = src
	if(!human_src.rune_linked)
		return FALSE
	var/datum/resurrection_rune_controller/controller = get_resurrection_rune_controller_for_user(human_src)
	if(!controller || !controller.can_offer_defeat_rune_return(human_src))
		return FALSE
	controller.update_linked_user_rescue_state(human_src)
	return TRUE

/// A scattering of wilderness spawn points to fling escapees toward.
/proc/get_random_kidnap_wilds_turf()
	var/list/spots = list()
	for(var/obj/effect/landmark/start/adventurerlate/late_spawn in GLOB.start_landmarks_list)
		var/turf/spot = get_turf(late_spawn)
		if(spot)
			spots += spot
	if(!length(spots))
		for(var/obj/effect/landmark/start/any_spawn in GLOB.start_landmarks_list)
			var/turf/spot = get_turf(any_spawn)
			if(spot)
				spots += spot
	return length(spots) ? pick(spots) : null

/// Toggle handed to a released captive: steel yourself and horny mobs leave you be. Granted on
/// release_from_knockout, torn down when captivity ends (escape / rune / surrender), so it never
/// follows the player out of the lair.
/datum/action/innate/defeat_refuse_advances
	name = "Refuse Advances"
	desc = "Steel yourself and rebuff the lair - its denizens will leave you be. Toggle again to relent."
	button_icon_state = "shieldsparkles"

/datum/action/innate/defeat_refuse_advances/Activate()
	if(!isliving(owner))
		return
	if(HAS_TRAIT(owner, TRAIT_DEFEAT_REFUSE_ADVANCES))
		REMOVE_TRAIT(owner, TRAIT_DEFEAT_REFUSE_ADVANCES, KIDNAP_TRAIT)
		to_chat(owner, span_notice("You relent, lowering your guard to the lair's attentions once more."))
	else
		ADD_TRAIT(owner, TRAIT_DEFEAT_REFUSE_ADVANCES, KIDNAP_TRAIT)
		to_chat(owner, span_notice("You steel yourself and rebuff the lair - its denizens will leave you be."))

/datum/component/kidnap_captivity
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/lair_tag
	/// The captor's faction, handed to a surrendered captive so the lair won't attack the new NPC.
	var/list/captor_faction
	var/captive_since = 0
	/// TRUE once the knockout has worn off and the captive has their agency back.
	var/released = FALSE
	/// The "Refuse Advances" opt-out action granted on release; cleared when captivity ends.
	var/datum/action/innate/defeat_refuse_advances/refuse_action
	/// TRUE once the captive may give up (the Surrender verb becomes usable).
	var/surrender_available = FALSE
	/// Climaxes endured in captivity; enough of them offers surrender early.
	var/captivity_climaxes = 0
	var/ko_release_timer
	var/surrender_timer

/datum/component/kidnap_captivity/Initialize(lair_tag, list/captor_faction = null)
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	src.lair_tag = lair_tag
	src.captor_faction = captor_faction
	captive_since = world.time

/datum/component/kidnap_captivity/RegisterWithParent()
	ko_release_timer = addtimer(CALLBACK(src, PROC_REF(release_from_knockout)), KIDNAP_KO_RELEASE, TIMER_STOPPABLE)
	surrender_timer = addtimer(CALLBACK(src, PROC_REF(offer_surrender)), KIDNAP_SURRENDER_WINDOW, TIMER_STOPPABLE)
	RegisterSignal(parent, COMSIG_SEX_CLIMAX, PROC_REF(on_captive_climax))

/datum/component/kidnap_captivity/UnregisterFromParent()
	deltimer(ko_release_timer)
	deltimer(surrender_timer)
	UnregisterSignal(parent, COMSIG_SEX_CLIMAX)
	// The opt-out never leaves the lair with the captive - strip trait + action on any teardown path.
	var/mob/living/victim = parent
	if(victim)
		REMOVE_TRAIT(victim, TRAIT_DEFEAT_REFUSE_ADVANCES, KIDNAP_TRAIT)
	if(refuse_action)
		refuse_action.Remove(victim)
		QDEL_NULL(refuse_action)

/// After the hold time: KO+Rune captives get their rune-return option (and stay down to use it);
/// everyone else trades knockout for captive pacifism so they can crawl to an escape marker.
/datum/component/kidnap_captivity/proc/release_from_knockout()
	var/mob/living/victim = parent
	if(!victim || released)
		return
	released = TRUE
	if(victim.defeat_mode == DEFEAT_MODE_KO_RUNE && victim.kidnap_surface_rune_return())
		to_chat(victim, span_blue("Your captors' hold is all that keeps you - if the rune is yours to call, wrench yourself free now."))
		return
	victim.remove_status_effect(/datum/status_effect/defeat_knockout)
	grant_refuse_advances(victim)
	to_chat(victim, span_warning("The grip of defeat loosens - you can move, fight, and flee again."))
	to_chat(victim, span_warning("No rune will answer here. Seek the edges of this place - a way out may wait there."))
	to_chat(victim, span_notice("If the lair's attentions become too much, use <b>Refuse Advances</b> to rebuff them while you find your way out."))

/// Hands the released captive the "Refuse Advances" opt-out toggle (once).
/datum/component/kidnap_captivity/proc/grant_refuse_advances(mob/living/victim)
	if(refuse_action || !victim)
		return
	refuse_action = new(victim)
	refuse_action.Grant(victim)

/// Once the window passes, the captive may give up via the Surrender verb.
/datum/component/kidnap_captivity/proc/offer_surrender()
	var/mob/living/victim = parent
	if(!victim)
		return
	surrender_available = TRUE
	to_chat(victim, span_userdanger("Despair claws at you. If escape will never come, you may give yourself up - use the \"Surrender to Captivity\" verb (IC tab). It cannot be undone."))

/// Each climax endured in captivity wears the captive down; enough of them offers surrender early.
/datum/component/kidnap_captivity/proc/on_captive_climax(datum/source, datum/sex_action/action, mob/living/receiver, mob/living/partner, mob/living/performer)
	SIGNAL_HANDLER
	captivity_climaxes++
	if(captivity_climaxes >= KIDNAP_SURRENDER_CLIMAXES && !surrender_available)
		offer_surrender()

/// The captive gives up: their body becomes a wretched NPC-in-distress and the player is sent off.
/datum/component/kidnap_captivity/proc/do_surrender()
	var/mob/living/carbon/human/victim = parent
	if(!ishuman(victim))
		return FALSE
	victim.become_npc_in_distress(decays = TRUE, captor_faction = captor_faction)
	qdel(src)
	return TRUE

/// Tears down captivity state (qdel routes through UnregisterFromParent, which strips the opt-out).
/datum/component/kidnap_captivity/proc/end_captivity()
	qdel(src)

// --- Captor side: faction mobs dragging defeated prey to their lair ---

/// Which lair this mob hauls defeated prey to. Null = this mob cannot kidnap.
/mob/living
	var/kidnap_lair_tag

/// Can this mob drag the given freshly-defeated victim back to its lair right now?
/// Everything that makes a downed victim claimable EXCEPT proximity/outnumbering, so the AI can spot
/// a candidate across the room and path toward it. can_kidnap_defeated_prey adds the here-and-now gates.
/mob/living/proc/is_kidnap_candidate(mob/living/victim)
	if(!kidnap_lair_tag)
		return FALSE
	if(!istype(victim) || victim == src)
		return FALSE
	if(!victim.has_status_effect(/datum/status_effect/defeat_knockout))
		return FALSE
	// Kept lighthearted: only a *horny* defeat gets someone hauled off to a lair. A plain beatdown
	// leaves them downed where they fell - no being dragged away just to be mauled again.
	if(victim.last_defeat_snapshot?.reason != DEFEAT_REASON_HORNY)
		return FALSE
	if(victim.GetComponent(/datum/component/kidnap_captivity))
		return FALSE
	// Only the mob that actually put them down gets to claim the prize.
	if(!victim.defeat_recent_source_is(src))
		return FALSE
	return TRUE

/mob/living/proc/can_kidnap_defeated_prey(mob/living/victim)
	if(!is_kidnap_candidate(victim))
		return FALSE
	if(!Adjacent(victim))
		return FALSE
	// Won't risk hauling prey off with rescuers about - hold the body instead.
	if(kidnap_is_outnumbered(victim))
		return FALSE
	return TRUE

/// TRUE when conscious would-be rescuers near the captor outnumber its own faction allies.
/// Keeps a lone wolf from yoinking someone out of the middle of a teamfight.
/mob/living/proc/kidnap_is_outnumbered(mob/living/victim)
	var/allies = 1 // the captor itself
	var/rescuers = 0
	for(var/mob/living/nearby in view(KIDNAP_GUARD_VIEW, src))
		if(nearby == src || nearby == victim)
			continue
		if(nearby.stat != CONSCIOUS)
			continue
		if(nearby.has_status_effect(/datum/status_effect/defeat_knockout))
			continue
		if(faction_check_mob(nearby))
			allies++
			continue
		// Only real people (players / humanoids) count as rescuers, not wandering critters.
		if(nearby.ckey || iscarbon(nearby))
			rescuers++
	return rescuers > allies

/// Hauls a defeated victim off to this mob's lair. Instant by design - a brief channel is unreliable
/// for NPCs (their own AI movement cancels do_after), and an instant grab reads cleanly as "seized".
/mob/living/proc/try_kidnap_defeated_prey(mob/living/victim)
	if(!can_kidnap_defeated_prey(victim))
		return FALSE
	// A cry for help so nearby allies learn their friend was taken, not simply vanished.
	victim.visible_message(span_userdanger("[victim] screams as [src] seizes [victim.p_them()]!"), span_userdanger("[src] seizes me - I am being dragged off! HELP!"))
	victim.emote("scream")
	visible_message(span_danger("[src] hauls [victim] away toward its lair!"), span_danger("I haul [victim] off to the lair..."))
	return victim.kidnap_to_lair(kidnap_lair_tag, faction)

// --- AI wiring ---------------------------------------------------------------------------------
// Simple hostile mobs claim prey straight from AttackingTarget (hostile.dm). Carbon NPCs (goblins,
// bandits) attack through the human_npc committed-swing flow instead, which never calls that hook -
// so they need this planning subtree to notice a horny-defeated victim and go haul it off.

/datum/ai_planning_subtree/kidnap_defeated_prey

/datum/ai_planning_subtree/kidnap_defeated_prey/SelectBehaviors(datum/ai_controller/controller, delta_time)
	var/mob/living/living_pawn = controller.pawn
	if(!istype(living_pawn) || !living_pawn.kidnap_lair_tag)
		return
	var/mob/living/target = controller.blackboard[BB_KIDNAP_TARGET]
	if(target && (QDELETED(target) || !living_pawn.is_kidnap_candidate(target)))
		controller.clear_blackboard_key(BB_KIDNAP_TARGET)
		target = null
	if(!target)
		for(var/mob/living/candidate in view(KIDNAP_GUARD_VIEW, living_pawn))
			if(!living_pawn.is_kidnap_candidate(candidate))
				continue
			target = candidate
			controller.set_blackboard_key(BB_KIDNAP_TARGET, candidate)
			break
	if(!target)
		return
	controller.queue_behavior(/datum/ai_behavior/kidnap_defeated_prey, BB_KIDNAP_TARGET)
	return SUBTREE_RETURN_FINISH_PLANNING

/datum/ai_behavior/kidnap_defeated_prey
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_MOVE_AND_PERFORM
	required_distance = 1

/datum/ai_behavior/kidnap_defeated_prey/perform(seconds_per_tick, datum/ai_controller/controller, target_key)
	. = ..()
	var/mob/living/pawn = controller.pawn
	var/mob/living/victim = controller.blackboard[target_key]
	if(!isliving(pawn) || !isturf(pawn.loc) || QDELETED(victim) || !pawn.is_kidnap_candidate(victim))
		finish_action(controller, FALSE, target_key)
		return
	set_movement_target(controller, victim)
	if(pawn.Adjacent(victim))
		pawn.try_kidnap_defeated_prey(victim)
		finish_action(controller, TRUE, target_key)

/datum/ai_behavior/kidnap_defeated_prey/finish_action(datum/ai_controller/controller, succeeded, target_key)
	. = ..()
	controller.clear_blackboard_key(target_key)

// Faction mobs that drag defeated prey to their lairs. Mappers place entrance + escape markers
// tagged with the matching lair_tag ("greenskin_lair" for orcs/goblins, "wolfden_lair" for canines).
/mob/living/simple_animal/hostile/orc
	kidnap_lair_tag = "greenskin_lair"

/mob/living/simple_animal/hostile/retaliate/wolf
	kidnap_lair_tag = "wolfden_lair"

/mob/living/carbon/human/species/human/northern/highwayman
	kidnap_lair_tag = "bandit_lair"

/mob/living/carbon/human/species/human/northern/thief
	kidnap_lair_tag = "bandit_lair"

/mob/living/carbon/human/species/human/northern/searaider
	kidnap_lair_tag = "bandit_lair"

// Friendly summoned/tamed wolves never kidnap.
/mob/living/simple_animal/hostile/retaliate/wolf/companion
	kidnap_lair_tag = null

/mob/living/simple_animal/hostile/retaliate/wolf/familiar
	kidnap_lair_tag = null

/mob/living/simple_animal/hostile/werewolf
	kidnap_lair_tag = "wolfden_lair"

//////////////////////////////////////////////////
// NPC-IN-DISTRESS (rescue NPCs)
// Wretched captives players can free for a coin reward. Two origins, one behavior:
//  - Ambient: mapper-placed / spawned random-race captives that persist until rescued.
//  - Player-turned: a surrendered captive, keeps their look + worn clothes, decays if left.
//////////////////////////////////////////////////

GLOBAL_LIST_INIT(npc_distress_pleas, list(
	"Save me, please!",
	"Someone - anyone - help me!",
	"Please, don't leave me here!",
	"Get me out of this place, I beg you!",
	"Mercy! Set me free!",
	"Help... I can't last much longer...",
))

GLOBAL_LIST_INIT(npc_distress_thanks, list(
	"Bless you, friend! Bless you!",
	"Thank you - thank you, a thousand times!",
	"I am saved... I cannot thank you enough!",
	"May the gods watch over you always!",
	"You came... you actually came for me!",
))

/datum/component/npc_in_distress
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// Player-turned captives decay if not rescued; ambient ones persist.
	var/decays = FALSE
	var/rescued = FALSE
	var/next_plea = 0
	var/decay_timer

/datum/component/npc_in_distress/Initialize(decays = FALSE)
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	src.decays = decays

/datum/component/npc_in_distress/RegisterWithParent()
	RegisterSignal(parent, COMSIG_ATOM_ATTACK_HAND, PROC_REF(on_attack_hand))
	START_PROCESSING(SSobj, src)
	if(decays)
		decay_timer = addtimer(CALLBACK(src, PROC_REF(decay_away)), KIDNAP_NPC_DECAY, TIMER_STOPPABLE)

/datum/component/npc_in_distress/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_ATOM_ATTACK_HAND)
	STOP_PROCESSING(SSobj, src)
	deltimer(decay_timer)

/datum/component/npc_in_distress/process(seconds_per_tick)
	var/mob/living/poor_soul = parent
	if(!poor_soul || rescued)
		return
	if(world.time < next_plea)
		return
	if(!npc_distress_player_nearby(poor_soul))
		return
	next_plea = world.time + rand(8 SECONDS, 16 SECONDS)
	poor_soul.say(pick(GLOB.npc_distress_pleas))

/datum/component/npc_in_distress/proc/npc_distress_player_nearby(mob/living/poor_soul)
	for(var/mob/nearby in view(NPC_DISTRESS_PLEA_VIEW, poor_soul))
		if(nearby == poor_soul)
			continue
		if(nearby.client)
			return TRUE
	return FALSE

/datum/component/npc_in_distress/proc/on_attack_hand(datum/source, mob/user, list/modifiers)
	SIGNAL_HANDLER
	if(rescued || !isliving(user) || user == parent)
		return
	INVOKE_ASYNC(src, PROC_REF(try_rescue), user)
	return COMPONENT_CANCEL_ATTACK_CHAIN

/datum/component/npc_in_distress/proc/try_rescue(mob/living/rescuer)
	var/mob/living/poor_soul = parent
	if(!poor_soul || rescued)
		return
	to_chat(rescuer, span_notice("I begin working [poor_soul] free of their bonds..."))
	if(!do_after(rescuer, NPC_DISTRESS_RESCUE_TIME, target = poor_soul))
		return
	if(rescued || QDELETED(poor_soul))
		return
	rescued = TRUE
	complete_rescue(rescuer)

/datum/component/npc_in_distress/proc/complete_rescue(mob/living/rescuer)
	var/mob/living/poor_soul = parent
	if(!poor_soul)
		return
	poor_soul.say(pick(GLOB.npc_distress_thanks))
	var/turf/spot = get_turf(poor_soul)
	if(spot)
		var/reward = rand(NPC_DISTRESS_REWARD_MIN, NPC_DISTRESS_REWARD_MAX)
		for(var/i in 1 to reward)
			new /obj/item/coin/silver(spot)
	poor_soul.visible_message(span_blue("The power of the Rune takes [poor_soul] away for treatment, leaving only a scattering of coin behind."))
	qdel(poor_soul)

/datum/component/npc_in_distress/proc/decay_away()
	var/mob/living/poor_soul = parent
	if(!poor_soul || rescued)
		return
	poor_soul.visible_message(span_warning("[poor_soul] is hauled away into the dark, lost for good."))
	qdel(poor_soul)

/// Ambient captive: a random downtrodden race, no gear, crying for rescue.
/mob/living/carbon/human/npc_in_distress

/mob/living/carbon/human/npc_in_distress/Initialize(mapload)
	. = ..()
	var/species_type = pick(
		/datum/species/human,
		/datum/species/elf/wood,
		/datum/species/elf/dark,
		/datum/species/human/halfelf,
		/datum/species/human/halfdrow,
	)
	set_species(species_type)
	// Randomize the look (gender, age, skin, eyes...) but keep the rolled species and our own naming.
	randomize_human_appearance(ALL & ~RANDOMIZE_SPECIES & ~RANDOMIZE_NAME)
	var/datum/species/our_species = dna?.species
	var/new_name = our_species ? our_species.random_name(gender) : random_unique_name(gender)
	fully_replace_character_name(real_name, new_name)
	AddComponent(/datum/component/npc_in_distress, FALSE)

/// Mapper landmark that spawns one ambient captive where placed.
/obj/effect/landmark/distress_spawner
	name = "distress captive spawner"
	icon = 'icons/mob/landmarks.dmi'
	icon_state = "x"
	/// Faction given to the spawned captive so the lair's own monsters won't maul their prize.
	var/list/captive_faction

/obj/effect/landmark/distress_spawner/Initialize(mapload)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/effect/landmark/distress_spawner/LateInitialize()
	. = ..()
	var/turf/spot = get_turf(src)
	if(spot)
		var/mob/living/carbon/human/npc_in_distress/poor_soul = new(spot)
		if(captive_faction)
			poor_soul.faction = captive_faction.Copy()
	return INITIALIZE_HINT_QDEL

// Faction-matched spawners so captives share their captors' faction (place in the matching lair).
/obj/effect/landmark/distress_spawner/greenskin
	name = "greenskin distress captive spawner"
	captive_faction = list(FACTION_ORCS)

/obj/effect/landmark/distress_spawner/wolfden
	name = "wolfden distress captive spawner"
	captive_faction = list("wolves")

/// Converts a (surrendered) human into a wretched NPC-in-distress: keeps look + worn clothes,
/// drops everything carried, and sends the player off to spectate.
/mob/living/carbon/human/proc/become_npc_in_distress(decays = TRUE, list/captor_faction = null)
	npc_in_distress_drop_carried()
	if(captor_faction)
		faction = captor_faction.Copy() // share the captors' faction so they won't attack the new captive
	visible_message(span_warning("[src]'s eyes go vacant - just another wretch lost to the dark."))
	ghostize(FALSE)
	AddComponent(/datum/component/npc_in_distress, decays)

/// Drops held items and carried containers (back/belt/pouch); leaves worn clothing on.
/mob/living/carbon/human/proc/npc_in_distress_drop_carried()
	for(var/obj/item/held in held_items)
		if(held)
			dropItemToGround(held)
	for(var/obj/item/carried in list(backr, backl, belt, beltl, beltr, wear_neck))
		if(carried)
			dropItemToGround(carried)

/mob/living/verb/kidnap_surrender()
	set name = "Surrender to Captivity"
	set category = "IC"
	set src = usr
	var/datum/component/kidnap_captivity/captivity = GetComponent(/datum/component/kidnap_captivity)
	if(!captivity || !captivity.surrender_available)
		to_chat(src, span_warning("There is nothing to surrender to right now."))
		return
	if(tgui_alert(usr, "Give yourself up to captivity? You will lose your character for good.", "Surrender", list("Yes", "No")) != "Yes")
		return
	captivity = GetComponent(/datum/component/kidnap_captivity) // re-fetch after the prompt
	if(!captivity || !captivity.surrender_available)
		return
	captivity.do_surrender()

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
			// Burns always read as burn trauma regardless of where they land.
			if(worst_injury_type == WOUND_BURN)
				return /datum/status_effect/debuff/defeat/physical/burn
			// Limb injuries are zone-driven: sprained leg, dislocated arm.
			switch(worst_body_zone)
				if(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
					return /datum/status_effect/debuff/defeat/physical/arm
				if(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
					return /datum/status_effect/debuff/defeat/physical/leg
			switch(worst_injury_type)
				if(WOUND_BLUNT, WOUND_INTERNAL_BRUISE)
					if(worst_body_zone == BODY_ZONE_HEAD)
						return /datum/status_effect/debuff/defeat/physical/concussion
					return /datum/status_effect/debuff/defeat/physical/body
				if(WOUND_SLASH, WOUND_PIERCE, WOUND_BITE, WOUND_LASH, WOUND_SCRATCH, WOUND_ARTERY, WOUND_TENDON, WOUND_NERVE)
					return /datum/status_effect/debuff/defeat/physical/wound
			return /datum/status_effect/debuff/defeat/physical
		if(DEFEAT_REASON_PAIN)
			return /datum/status_effect/debuff/defeat/pain
		if(DEFEAT_REASON_HORNY)
			return pick(
				/datum/status_effect/debuff/defeat/horny/brainfog,
				/datum/status_effect/debuff/defeat/horny/oversensitive,
				/datum/status_effect/debuff/defeat/horny/wobble,
				/datum/status_effect/debuff/defeat/horny/trembling,
				/datum/status_effect/debuff/defeat/horny/breathless,
				/datum/status_effect/debuff/defeat/horny/overcharge,
			)
	return /datum/status_effect/debuff/defeat/physical

/proc/defeat_severity_rank(severity)
	switch(severity)
		if(DEFEAT_SEVERITY_LIGHT)
			return 1
		if(DEFEAT_SEVERITY_SEVERE)
			return 3
	return 2

/proc/defeat_severity_from_rank(rank)
	switch(rank)
		if(1)
			return DEFEAT_SEVERITY_LIGHT
		if(3)
			return DEFEAT_SEVERITY_SEVERE
	return DEFEAT_SEVERITY_NORMAL

/// Player-facing severity word for alerts/UI.
/proc/defeat_severity_label(severity)
	switch(severity)
		if(DEFEAT_SEVERITY_LIGHT)
			return "Light"
		if(DEFEAT_SEVERITY_SEVERE)
			return "Severe"
	return "Moderate"

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

/obj/effect/landmark/kidnap/escape/bandit
	lair_tag = "bandit_lair"

/obj/effect/landmark/kidnap/entrance/bandit
	lair_tag = "bandit_lair"

/obj/effect/landmark/kidnap/escape/greenskin
	lair_tag = "greenskin_lair"

/obj/effect/landmark/kidnap/entrance/greenskin
	lair_tag = "greenskin_lair"

/obj/effect/landmark/kidnap/escape/wolfden
	lair_tag = "wolfden_lair"

/obj/effect/landmark/kidnap/entrance/wolfden
	lair_tag = "wolfden_lair"

/obj/effect/landmark/kidnap/escape/bandit
	lair_tag = "bandit_lair"

/obj/effect/landmark/kidnap/entrance/bandit
	lair_tag = "bandit_lair"
