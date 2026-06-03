/datum/component/defeat_monitor
	dupe_mode = COMPONENT_DUPE_HIGHLANDER
	/// First tick at or above the sustained pain defeat stage.
	var/shock_defeat_started_at = 0
	/// Valid hostile climax events accumulated toward horny defeat.
	var/horny_defeat_climax_count = 0

/datum/component/defeat_monitor/Initialize(...)
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	return ..()

/datum/component/defeat_monitor/RegisterWithParent()
	RegisterSignal(parent, COMSIG_LIVING_HEALTH_UPDATE, PROC_REF(on_health_update))
	RegisterSignal(parent, COMSIG_LIVING_LIFE, PROC_REF(on_life))
	RegisterSignal(parent, COMSIG_LIVING_DEATH, PROC_REF(on_death))
	RegisterSignal(parent, COMSIG_SEX_CLIMAX, PROC_REF(on_climax))

/datum/component/defeat_monitor/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_LIVING_HEALTH_UPDATE, COMSIG_LIVING_LIFE, COMSIG_LIVING_DEATH, COMSIG_SEX_CLIMAX))

/datum/component/defeat_monitor/proc/is_defeat_eligible()
	var/mob/living/living_parent = parent
	return living_parent?.defeat_system_is_eligible()

/datum/component/defeat_monitor/proc/check_defeat_triggers()
	var/mob/living/carbon/carbon_parent = parent
	if(!istype(carbon_parent))
		return FALSE
	if(!is_defeat_eligible())
		reset_shock_defeat_window()
		return FALSE
	if(carbon_parent.has_status_effect(/datum/status_effect/defeat_knockout))
		carbon_parent.defeat_stabilize_live_damage(FALSE)
		return FALSE

	if(carbon_parent.defeat_is_immediate_rune_hazard())
		return carbon_parent.enter_defeat(DEFEAT_REASON_HAZARD, DEFEAT_SEVERITY_SEVERE)

	var/selected_threshold = carbon_parent.defeat_damage_threshold || DEFEAT_DAMAGE_THRESHOLD_DEFAULT
	if(max(carbon_parent.getBruteLoss(), carbon_parent.getFireLoss(), carbon_parent.getToxLoss(), carbon_parent.getOxyLoss(), carbon_parent.getCloneLoss()) >= selected_threshold)
		return carbon_parent.enter_defeat(DEFEAT_REASON_DAMAGE, DEFEAT_SEVERITY_NORMAL)

	if(carbon_parent.health <= HEALTH_THRESHOLD_DEAD)
		return carbon_parent.enter_defeat(DEFEAT_REASON_DEATH, DEFEAT_SEVERITY_SEVERE)

	var/current_shock_stage = carbon_parent.getShockStage()
	if(current_shock_stage >= DEFEAT_SHOCK_HARD_STAGE)
		return carbon_parent.enter_defeat(DEFEAT_REASON_PAIN, DEFEAT_SEVERITY_SEVERE)

	if(current_shock_stage < DEFEAT_SHOCK_DEFEAT_STAGE)
		reset_shock_defeat_window()
		return FALSE

	if(!shock_defeat_started_at)
		shock_defeat_started_at = world.time
		return FALSE

	if(world.time - shock_defeat_started_at >= DEFEAT_SHOCK_SUSTAIN_DURATION)
		return carbon_parent.enter_defeat(DEFEAT_REASON_PAIN, DEFEAT_SEVERITY_NORMAL)

	return FALSE

/datum/component/defeat_monitor/proc/reset_shock_defeat_window()
	shock_defeat_started_at = 0

/datum/component/defeat_monitor/proc/on_health_update(datum/source, ...)
	SIGNAL_HANDLER
	return check_defeat_triggers()

/datum/component/defeat_monitor/proc/on_life(datum/source, ...)
	SIGNAL_HANDLER
	return check_defeat_triggers()

/datum/component/defeat_monitor/proc/on_death(datum/source, ...)
	SIGNAL_HANDLER
	return

/datum/component/defeat_monitor/proc/on_climax(datum/source, datum/sex_action/action, mob/living/action_receiver, mob/living/action_partner, mob/living/action_performer)
	SIGNAL_HANDLER
	return check_horny_defeat_climax(source, action_receiver, action_partner, action_performer)

/datum/component/defeat_monitor/proc/check_horny_defeat_climax(datum/source, mob/living/action_receiver, mob/living/action_partner, mob/living/action_performer)
	var/mob/living/carbon/carbon_parent = parent
	if(!istype(carbon_parent))
		return FALSE
	if(!is_defeat_eligible())
		horny_defeat_climax_count = 0
		return FALSE
	if(carbon_parent.has_status_effect(/datum/status_effect/defeat_knockout))
		return FALSE
	if(source != carbon_parent)
		return FALSE
	if(action_receiver != carbon_parent)
		return FALSE
	if(!action_partner || !action_performer || action_partner != action_performer)
		return FALSE
	if(action_partner == carbon_parent)
		return FALSE
	if(carbon_parent.pulledby != action_partner)
		return FALSE
	if(action_partner.grab_state < GRAB_AGGRESSIVE)
		return FALSE

	horny_defeat_climax_count++
	if(horny_defeat_climax_count < max(1, carbon_parent.hostile_grab_horny_climax_threshold))
		return FALSE

	horny_defeat_climax_count = 0
	return carbon_parent.enter_defeat(DEFEAT_REASON_HORNY, DEFEAT_SEVERITY_NORMAL, action_performer)
