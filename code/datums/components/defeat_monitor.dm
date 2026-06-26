/datum/component/defeat_monitor
	dupe_mode = COMPONENT_DUPE_HIGHLANDER
	/// First tick at or above the sustained pain defeat stage.
	var/shock_defeat_started_at = 0
	/// Last warning tick while pain shock is approaching defeat.
	var/shock_warning_last_at = 0
	/// Last warning tick while damage/blood loss is approaching defeat.
	var/damage_warning_last_at = 0
	/// Valid hostile climax events accumulated toward horny defeat.
	var/horny_defeat_climax_count = 0
	/// Climaxes needed for horny defeat this encounter. Rolled lazily (rand 10-20) on the first
	/// valid hostile-grab climax, per the design - separate from the legacy hostile_grab threshold.
	var/horny_defeat_climax_threshold = 0

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

	var/selected_threshold = carbon_parent.get_effective_defeat_threshold()
	// Total damage across all pools (not the single biggest) - predictable: you fall at roughly
	// maxHealth - threshold, regardless of how the damage is split across brute/burn/tox/etc.
	var/total_damage = carbon_parent.getBruteLoss() + carbon_parent.getFireLoss() + carbon_parent.getToxLoss() + carbon_parent.getOxyLoss() + carbon_parent.getCloneLoss()
	maybe_warn_damage_defeat(carbon_parent, total_damage, selected_threshold)
	if(total_damage >= selected_threshold)
		return carbon_parent.enter_defeat(DEFEAT_REASON_DAMAGE, DEFEAT_SEVERITY_NORMAL)

	if(carbon_parent.defeat_is_near_death())
		return carbon_parent.enter_defeat(DEFEAT_REASON_DEATH, DEFEAT_SEVERITY_SEVERE)

	var/current_shock_stage = carbon_parent.getShockStage()
	maybe_warn_shock_defeat(current_shock_stage)
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

/datum/component/defeat_monitor/proc/maybe_warn_shock_defeat(current_shock_stage)
	var/mob/living/carbon/carbon_parent = parent
	if(!istype(carbon_parent))
		return FALSE
	if(current_shock_stage < DEFEAT_SHOCK_WARNING_STAGE)
		shock_warning_last_at = 0
		return FALSE
	if(shock_warning_last_at && world.time - shock_warning_last_at < DEFEAT_SHOCK_WARNING_COOLDOWN)
		return FALSE
	shock_warning_last_at = world.time
	to_chat(carbon_parent, span_warning("Pain is pulling you toward defeat. You need help soon."))
	carbon_parent.flash_fullscreen("redflash1")
	return TRUE

/// Warn the player as their wounds (or blood loss) approach the point of defeat, throttled.
/datum/component/defeat_monitor/proc/maybe_warn_damage_defeat(mob/living/carbon/carbon_parent, total_damage, threshold)
	var/nearly_beaten = (threshold > 0 && total_damage >= threshold * DEFEAT_DAMAGE_WARNING_FRACTION && total_damage < threshold)
	var/bleeding_out = (carbon_parent.blood_volume <= BLOOD_VOLUME_BAD && carbon_parent.blood_volume > BLOOD_VOLUME_SURVIVE && !HAS_TRAIT(carbon_parent, TRAIT_BLOODLOSS_IMMUNE))
	if(!nearly_beaten && !bleeding_out)
		damage_warning_last_at = 0
		return FALSE
	if(damage_warning_last_at && world.time - damage_warning_last_at < DEFEAT_SHOCK_WARNING_COOLDOWN)
		return FALSE
	damage_warning_last_at = world.time
	to_chat(carbon_parent, span_warning(bleeding_out ? "You're bleeding badly - stay on your feet or you'll fall." : "You're battered to the brink - one more blow and you'll go down."))
	carbon_parent.flash_fullscreen("redflash1")
	return TRUE

/datum/component/defeat_monitor/proc/on_health_update(datum/source, ...)
	SIGNAL_HANDLER
	return check_defeat_triggers()

/datum/component/defeat_monitor/proc/on_life(datum/source, ...)
	SIGNAL_HANDLER
	return check_defeat_triggers()

/datum/component/defeat_monitor/proc/on_death(datum/source, ...)
	SIGNAL_HANDLER
	var/mob/living/carbon/carbon_parent = parent
	if(!istype(carbon_parent))
		return FALSE
	if(!is_defeat_eligible())
		return FALSE
	if(carbon_parent.has_status_effect(/datum/status_effect/defeat_knockout))
		return FALSE
	if(!carbon_parent.defeat_is_immediate_rune_hazard())
		return FALSE
	return carbon_parent.enter_defeat(DEFEAT_REASON_HAZARD, DEFEAT_SEVERITY_SEVERE)

/datum/component/defeat_monitor/proc/on_climax(datum/source, datum/sex_action/action, mob/living/action_receiver, mob/living/action_partner, mob/living/action_performer)
	SIGNAL_HANDLER
	if(try_holy_communion_rescue(action_receiver, action_partner, action_performer))
		return
	return check_horny_defeat_climax(source, action_receiver, action_partner, action_performer)

/// A holy character (TRAIT_HOLY) bringing a downed victim to climax frees them - the design's
/// "ERP with the saints" rescue (section 3.1). A holy one who is actively harming the victim
/// (aggressive grab / recent attacker) is blocked by defeat_can_be_rescued_by, so only a tender act frees.
/datum/component/defeat_monitor/proc/try_holy_communion_rescue(mob/living/action_receiver, mob/living/action_partner, mob/living/action_performer)
	var/mob/living/carbon/victim = parent
	if(!istype(victim))
		return FALSE
	if(action_receiver != victim)
		return FALSE
	if(!victim.has_status_effect(/datum/status_effect/defeat_knockout))
		return FALSE
	var/mob/living/holy_one = action_performer || action_partner
	if(!holy_one || holy_one == victim)
		return FALSE
	if(!HAS_TRAIT(holy_one, TRAIT_HOLY))
		return FALSE
	return victim.defeat_rescue(holy_one, "holy communion")

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

	// Roll this encounter's threshold once, on the first valid hostile climax (10-20 per design).
	if(horny_defeat_climax_threshold <= 0)
		horny_defeat_climax_threshold = rand(10, 20)
	horny_defeat_climax_count++
	if(horny_defeat_climax_count < horny_defeat_climax_threshold)
		return FALSE

	horny_defeat_climax_count = 0
	return carbon_parent.enter_defeat(DEFEAT_REASON_HORNY, DEFEAT_SEVERITY_NORMAL, action_performer)

/datum/component/defeat_ai_opt_in
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/previous_opt_in = FALSE

/datum/component/defeat_ai_opt_in/Initialize(...)
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	return ..()

/datum/component/defeat_ai_opt_in/RegisterWithParent()
	var/mob/living/living_parent = parent
	previous_opt_in = living_parent.defeat_system_ai_opt_in
	living_parent.defeat_system_ai_opt_in = TRUE
	living_parent.ensure_defeat_monitor()

/datum/component/defeat_ai_opt_in/UnregisterFromParent()
	var/mob/living/living_parent = parent
	if(!istype(living_parent))
		return
	living_parent.defeat_system_ai_opt_in = previous_opt_in
	if(!living_parent.defeat_system_is_eligible())
		var/datum/component/defeat_monitor/monitor = living_parent.GetComponent(/datum/component/defeat_monitor)
		qdel(monitor)
