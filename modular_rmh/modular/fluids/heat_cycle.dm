// Heat and rut: a timed cycle from the quirk or species, or nightfall for werewolves.

/// Time from gaining the cycle to the first heat, picked at random between these.
#define HEAT_FIRST_DELAY_MIN (40 MINUTES)
#define HEAT_FIRST_DELAY_MAX (80 MINUTES)
/// Time from one heat starting to the next one, picked at random between these.
#define HEAT_INTERVAL_MIN (120 MINUTES)
#define HEAT_INTERVAL_MAX (180 MINUTES)
/// How long one heat lasts.
#define HEAT_DURATION (30 MINUTES)
/// A climax stops the heat pulling arousal up for this long.
#define HEAT_SATED_DURATION (10 MINUTES)
/// Most arousal one heat tick adds.
#define HEAT_AROUSAL_STEP 4
#define HEAT_MUSK_INTERVAL (1 MINUTES)
#define HEAT_MUSK_AMOUNT 10
#define HEAT_MUSK_CAP 20
/// Time between heat reminders, picked at random between these.
#define HEAT_MESSAGE_MIN (3 MINUTES)
#define HEAT_MESSAGE_MAX (5 MINUTES)

/// Gives heat cycles from one source; the cycle runs while any source remains.
/mob/living/proc/grant_heat_cycle(source)
	ADD_TRAIT(src, TRAIT_HEAT_CYCLE, source)
	var/datum/component/heat_cycle/cycle = LoadComponent(/datum/component/heat_cycle)
	cycle.update_schedule()

/mob/living/proc/revoke_heat_cycle(source)
	REMOVE_TRAIT(src, TRAIT_HEAT_CYCLE, source)
	var/datum/component/heat_cycle/cycle = GetComponent(/datum/component/heat_cycle)
	if(!cycle)
		return
	if(!HAS_TRAIT(src, TRAIT_HEAT_CYCLE))
		qdel(cycle)
		return
	cycle.update_schedule()

/// Starts heat on a timer, or at nightfall for werewolves; losing the last source ends any heat.
/datum/component/heat_cycle
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// Timer that starts the next timed heat.
	var/next_heat_timer

/datum/component/heat_cycle/Initialize()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/heat_cycle/RegisterWithParent()
	RegisterSignal(SSdcs, COMSIG_GLOB_TIME_OF_DAY_CHANGED, PROC_REF(on_time_of_day_changed))

/datum/component/heat_cycle/UnregisterFromParent()
	UnregisterSignal(SSdcs, COMSIG_GLOB_TIME_OF_DAY_CHANGED)

/datum/component/heat_cycle/Destroy(force)
	deltimer(next_heat_timer)
	next_heat_timer = null
	var/mob/living/living_parent = parent
	living_parent?.remove_status_effect(/datum/status_effect/in_heat)
	return ..()

/// Every source but the werewolf curse runs on the timer.
/datum/component/heat_cycle/proc/is_timed()
	return HAS_TRAIT_NOT_FROM(parent, TRAIT_HEAT_CYCLE, HEAT_SOURCE_WEREWOLF)

/datum/component/heat_cycle/proc/update_schedule()
	if(!is_timed())
		deltimer(next_heat_timer)
		next_heat_timer = null
		return
	if(!next_heat_timer)
		schedule_heat(rand(HEAT_FIRST_DELAY_MIN, HEAT_FIRST_DELAY_MAX))

/datum/component/heat_cycle/proc/schedule_heat(delay)
	deltimer(next_heat_timer)
	next_heat_timer = addtimer(CALLBACK(src, PROC_REF(on_heat_timer)), delay, TIMER_STOPPABLE)

/datum/component/heat_cycle/proc/on_heat_timer()
	next_heat_timer = null
	schedule_heat(rand(HEAT_INTERVAL_MIN, HEAT_INTERVAL_MAX))
	start_heat()

/datum/component/heat_cycle/proc/on_time_of_day_changed(datum/source, new_tod, old_tod)
	SIGNAL_HANDLER
	if(new_tod == "night" && HAS_TRAIT_FROM(parent, TRAIT_HEAT_CYCLE, HEAT_SOURCE_WEREWOLF))
		start_heat()

/// Starts a heat unless one runs already or the preferences refuse it; returns TRUE if it started.
/datum/component/heat_cycle/proc/start_heat()
	var/mob/living/living_parent = parent
	if(living_parent.stat == DEAD || living_parent.has_status_effect(/datum/status_effect/in_heat))
		return FALSE
	if(!allows_heat())
		return FALSE
	return !!living_parent.apply_status_effect(/datum/status_effect/in_heat)

/// The quirk is the player's own choice; species and curse heat need the ERP preference.
/datum/component/heat_cycle/proc/allows_heat()
	if(HAS_TRAIT_FROM(parent, TRAIT_HEAT_CYCLE, HEAT_SOURCE_QUIRK))
		return TRUE
	var/mob/living/living_parent = parent
	return living_parent.get_erp_pref(/datum/erp_preference/boolean/allow_heat_cycles)

/// More fluid, rising arousal, musk and reminders; a climax sates it for a while.
/datum/status_effect/in_heat
	id = "in_heat"
	duration = HEAT_DURATION
	tick_interval = 10 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/buff/in_heat
	examine_text = span_love("SUBJECTPRONOUN is flushed and restless.")
	/// TRUE when the mob has a penis and no vagina, so this is a rut.
	var/is_rut = FALSE
	COOLDOWN_DECLARE(next_musk)
	COOLDOWN_DECLARE(next_message)

/datum/status_effect/in_heat/on_creation(mob/living/new_owner, duration_override, ...)
	. = ..()
	if(linked_alert && is_rut)
		linked_alert.name = "In Rut"
		linked_alert.desc = "My body is in rut. I make more seed, and I keep getting aroused."

/datum/status_effect/in_heat/on_apply()
	. = ..()
	is_rut = owner.getorganslot(ORGAN_SLOT_PENIS) && !owner.getorganslot(ORGAN_SLOT_VAGINA)
	owner.add_fluid_modifier(/datum/fluid_modifier/in_heat, id)
	RegisterSignal(owner, COMSIG_SEX_CLIMAX, PROC_REF(on_climax))
	COOLDOWN_START(src, next_message, rand(HEAT_MESSAGE_MIN, HEAT_MESSAGE_MAX))
	if(is_rut)
		to_chat(owner, span_love("A hungry, restless rut takes hold of me. I crave a mate."))
	else
		to_chat(owner, span_love("A slow, restless heat builds deep inside me. My body craves a mate."))

/datum/status_effect/in_heat/on_remove()
	owner.remove_fluid_modifier(/datum/fluid_modifier/in_heat, id)
	UnregisterSignal(owner, COMSIG_SEX_CLIMAX)
	owner.remove_status_effect(/datum/status_effect/heat_sated)
	if(owner.stat != DEAD)
		to_chat(owner, span_notice("The [is_rut ? "rut" : "heat"] fades, and my head clears."))
	return ..()

/datum/status_effect/in_heat/tick()
	if(owner.stat == DEAD)
		return
	if(COOLDOWN_FINISHED(src, next_musk))
		COOLDOWN_START(src, next_musk, HEAT_MUSK_INTERVAL)
		var/turf/owner_turf = get_turf(owner)
		owner_turf?.pollute_turf(/datum/pollutant/heat_musk, HEAT_MUSK_AMOUNT, HEAT_MUSK_CAP)
	if(owner.has_status_effect(/datum/status_effect/heat_sated))
		return
	pull_arousal()
	if(COOLDOWN_FINISHED(src, next_message))
		COOLDOWN_START(src, next_message, rand(HEAT_MESSAGE_MIN, HEAT_MESSAGE_MAX))
		to_chat(owner, span_love(pick(
			"My skin feels hot and too tight. I need a mate.",
			"A needy ache pulses low in my belly.",
			"Every scent around me makes my mind wander.",
			"I can't sit still. The [is_rut ? "rut" : "heat"] won't let me.",
		)))

/// Raises arousal toward the floor without passing it, so heat alone never brings a climax.
/datum/status_effect/in_heat/proc/pull_arousal()
	var/list/arousal_data = list()
	SEND_SIGNAL(owner, COMSIG_SEX_GET_AROUSAL, arousal_data)
	var/arousal = arousal_data["arousal"]
	if(isnull(arousal) || arousal >= HEAT_AROUSAL_FLOOR)
		return
	SEND_SIGNAL(owner, COMSIG_SEX_ADJUST_AROUSAL, min(HEAT_AROUSAL_STEP, HEAT_AROUSAL_FLOOR - arousal))

/datum/status_effect/in_heat/proc/on_climax(datum/source)
	SIGNAL_HANDLER
	owner.apply_status_effect(/datum/status_effect/heat_sated)

/// Pauses the heat's arousal pull and reminders after a climax.
/datum/status_effect/heat_sated
	id = "heat_sated"
	duration = HEAT_SATED_DURATION
	tick_interval = STATUS_EFFECT_NO_TICK
	status_type = STATUS_EFFECT_REFRESH
	alert_type = null

/datum/status_effect/heat_sated/on_apply()
	to_chat(owner, span_love("For now, the need inside me is sated."))
	return ..()

/atom/movable/screen/alert/status_effect/buff/in_heat
	name = "In Heat"
	desc = "My body is in heat. I make more fluids, and I keep getting aroused."

/datum/pollutant/heat_musk
	name = "musk"
	pollutant_flags = POLLUTANT_SMELL
	smell_intensity = 1
	descriptor = SCENT_DESC_SMELL
	scent = "a heavy, animal musk"

/datum/quirk/peculiarity/heat_cycles
	name = "Heat Cycles"
	desc = "Every few hours my body goes into heat, or rut, and craves a mate."
	desc_hint = "Every 2-3 hours you go into heat for 30 minutes: more fluids, rising arousal and a musky smell. A climax gives some relief."

/datum/quirk/peculiarity/heat_cycles/on_spawn()
	. = ..()
	owner?.grant_heat_cycle(HEAT_SOURCE_QUIRK)

/datum/quirk/peculiarity/heat_cycles/on_remove()
	if(!QDELETED(owner))
		owner.revoke_heat_cycle(HEAT_SOURCE_QUIRK)
	return ..()

// The werewolf curse brings heat at nightfall; the body transfer hooks move it with the mind.

/datum/antagonist/werewolf/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/body = mob_override || owner.current
	if(istype(body))
		body.grant_heat_cycle(HEAT_SOURCE_WEREWOLF)

/datum/antagonist/werewolf/remove_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/body = mob_override || owner.current
	if(istype(body))
		body.revoke_heat_cycle(HEAT_SOURCE_WEREWOLF)

#undef HEAT_FIRST_DELAY_MIN
#undef HEAT_FIRST_DELAY_MAX
#undef HEAT_INTERVAL_MIN
#undef HEAT_INTERVAL_MAX
#undef HEAT_DURATION
#undef HEAT_SATED_DURATION
#undef HEAT_AROUSAL_STEP
#undef HEAT_MUSK_INTERVAL
#undef HEAT_MUSK_AMOUNT
#undef HEAT_MUSK_CAP
#undef HEAT_MESSAGE_MIN
#undef HEAT_MESSAGE_MAX
