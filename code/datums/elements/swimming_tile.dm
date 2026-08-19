/// Applies the unique swimming status to immersed living mobs on a swimmable water turf.
/datum/element/swimming_tile
	element_flags = ELEMENT_DETACH | ELEMENT_BESPOKE
	id_arg_index = 2
	/// Stamina drained each status tick.
	var/ticking_stamina_cost
	/// Oxygen damage dealt each status tick while drowning.
	var/ticking_oxygen_damage
	/// Whether standing human-sized mobs are still fully underwater.
	var/block_breathing
	/// Living mobs currently present on attached turfs.
	var/list/mob/living/swimmers = list()

/datum/element/swimming_tile/Destroy(force)
	swimmers = null
	return ..()

/datum/element/swimming_tile/Attach(turf/target, ticking_stamina_cost = 5, ticking_oxygen_damage = 2, block_breathing = FALSE)
	. = ..()
	if(!isturf(target))
		return ELEMENT_INCOMPATIBLE

	src.ticking_stamina_cost = ticking_stamina_cost
	src.ticking_oxygen_damage = ticking_oxygen_damage
	src.block_breathing = block_breathing
	RegisterSignals(target, list(COMSIG_ATOM_ENTERED, COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZED_ON), PROC_REF(enter_water))
	RegisterSignal(target, COMSIG_TURF_EXITED, PROC_REF(exit_water))

	for(var/mob/living/swimmer in target.contents)
		if(!(swimmer.flags_1 & INITIALIZED_1))
			continue
		enter_water(target, swimmer)

/datum/element/swimming_tile/Detach(turf/source)
	UnregisterSignal(source, list(COMSIG_ATOM_ENTERED, COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZED_ON, COMSIG_TURF_EXITED))
	for(var/mob/living/swimmer in source.contents)
		exit_water(source, swimmer)
	return ..()

/datum/element/swimming_tile/proc/enter_water(atom/source, mob/living/swimmer)
	SIGNAL_HANDLER

	if(!istype(swimmer) || QDELETED(swimmer))
		return
	if(HAS_TRAIT(swimmer, TRAIT_IMMERSED))
		start_swimming(swimmer)
	if(swimmer in swimmers)
		return

	swimmers |= swimmer
	RegisterSignal(swimmer, SIGNAL_ADDTRAIT(TRAIT_IMMERSED), PROC_REF(start_swimming))
	RegisterSignal(swimmer, COMSIG_PARENT_QDELETING, PROC_REF(on_swimmer_deleted))

/datum/element/swimming_tile/proc/exit_water(atom/source, mob/living/swimmer, atom/new_loc)
	SIGNAL_HANDLER

	if(!istype(swimmer))
		return
	UnregisterSignal(swimmer, list(SIGNAL_ADDTRAIT(TRAIT_IMMERSED), COMSIG_PARENT_QDELETING))
	swimmers -= swimmer

	var/turf/open/water/next_water = new_loc
	if(istype(next_water) && next_water.is_swimmable())
		return
	swimmer.remove_status_effect(/datum/status_effect/swimming)

/datum/element/swimming_tile/proc/on_swimmer_deleted(mob/living/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, list(SIGNAL_ADDTRAIT(TRAIT_IMMERSED), COMSIG_PARENT_QDELETING))
	swimmers -= source

/datum/element/swimming_tile/proc/start_swimming(mob/living/swimmer)
	SIGNAL_HANDLER
	var/datum/status_effect/swimming/current_status = swimmer.has_status_effect(/datum/status_effect/swimming)
	if(current_status)
		current_status.update_water_config(ticking_stamina_cost, ticking_oxygen_damage, block_breathing)
		return
	swimmer.apply_status_effect(/datum/status_effect/swimming, null, ticking_stamina_cost, ticking_oxygen_damage, block_breathing)

/// Owns stamina drain, drowning, and sinking while a mob is swimming.
/datum/status_effect/swimming
	id = "swimming"
	alert_type = null
	duration = STATUS_EFFECT_PERMANENT
	status_type = STATUS_EFFECT_UNIQUE
	tick_interval = 2 SECONDS
	/// Stamina drained each interval before skill reduction.
	var/stamina_per_interval
	/// Oxygen damage dealt each interval while drowning.
	var/oxygen_per_interval
	/// Whether the owner's head remains underwater while standing.
	var/block_breathing
	/// Prevents repeated stamina knockdowns from chaining without recovery time.
	COOLDOWN_DECLARE(stamina_failure_pity)

/datum/status_effect/swimming/on_creation(mob/living/new_owner, duration_override, ticking_stamina_cost = 5, ticking_oxygen_damage = 2, block_breathing = FALSE)
	. = ..()
	if(QDELETED(src))
		return

	stamina_per_interval = ticking_stamina_cost
	oxygen_per_interval = ticking_oxygen_damage
	src.block_breathing = block_breathing
	RegisterSignal(owner, SIGNAL_REMOVETRAIT(TRAIT_IMMERSED), PROC_REF(stop_swimming))
	RegisterSignal(owner, COMSIG_MOB_STATCHANGE, PROC_REF(on_stat_change))
	RegisterSignals(owner, list(COMSIG_MOB_EQUIPPED_ITEM, COMSIG_MOB_UNEQUIPPED_ITEM), PROC_REF(on_equipment_changed))
	update_sinking_state()

/datum/status_effect/swimming/proc/update_water_config(ticking_stamina_cost, ticking_oxygen_damage, block_breathing)
	stamina_per_interval = ticking_stamina_cost
	oxygen_per_interval = ticking_oxygen_damage
	src.block_breathing = block_breathing
	update_sinking_state()

/datum/status_effect/swimming/on_remove()
	UnregisterSignal(owner, list(
		SIGNAL_REMOVETRAIT(TRAIT_IMMERSED),
		COMSIG_MOB_STATCHANGE,
		COMSIG_MOB_EQUIPPED_ITEM,
		COMSIG_MOB_UNEQUIPPED_ITEM,
	))
	REMOVE_TRAIT(owner, TRAIT_SINKING, TRAIT_STATUS_EFFECT(id))
	return ..()

/datum/status_effect/swimming/tick()
	var/turf/open/water/current_water = get_turf(owner)
	if(!HAS_TRAIT(owner, TRAIT_IMMERSED) || !istype(current_water) || !current_water.is_swimmable())
		qdel(src)
		return

	update_sinking_state(move_down = TRUE)
	if(QDELETED(src))
		return

	if(!ismob(owner.buckled) && !HAS_TRAIT(owner, TRAIT_GOOD_SWIM) && COOLDOWN_FINISHED(src, stamina_failure_pity))
		var/swimming_skill = GET_MOB_SKILL_VALUE_OLD(owner, /datum/attribute/skill/misc/swimming)
		var/final_stamina_cost = max(stamina_per_interval - swimming_skill, 0)
		if(final_stamina_cost > 0 && !owner.adjust_stamina(final_stamina_cost, "drown"))
			addtimer(CALLBACK(owner, TYPE_PROC_REF(/mob/living, Knockdown), 3 SECONDS), 1 SECONDS)
			COOLDOWN_START(src, stamina_failure_pity, 6 SECONDS)
		owner.adjust_experience(
			/datum/attribute/skill/misc/swimming,
			max(stamina_per_interval, 1) * GET_MOB_ATTRIBUTE_VALUE(owner, STAT_ENDURANCE) * 0.01,
		)

	if(HAS_TRAIT(owner, TRAIT_WATER_BREATHING) || HAS_TRAIT(owner, TRAIT_NOBREATH))
		return
	if(!block_breathing && owner.mob_size >= MOB_SIZE_HUMAN && owner.body_position == STANDING_UP)
		return
	if(owner.sex_scene && !QDELETED(owner.sex_scene))
		for(var/datum/sex_action/active_action as anything in owner.sex_scene.active_actions)
			if(QDELETED(active_action) || active_action.action_target != owner)
				continue
			if(active_action.action_user == owner || QDELETED(active_action.action_user))
				continue
			return

	if(prob(50))
		owner.emote("drown")
	owner.apply_damage(oxygen_per_interval, OXY)
	if(prob(20))
		owner.losebreath += oxygen_per_interval

/datum/status_effect/swimming/proc/update_sinking_state(move_down = FALSE)
	var/turf/open/water/current_water = get_turf(owner)
	var/sinking_threshold = HAS_TRAIT(owner, TRAIT_GOOD_SWIM) ? ENCUMBRANCE_HEAVY : ENCUMBRANCE_MEDIUM
	var/should_sink = istype(current_water) && current_water.is_swimmable() && owner.encumbrance >= sinking_threshold
	var/was_sinking = HAS_TRAIT(owner, TRAIT_SINKING)

	if(!should_sink)
		REMOVE_TRAIT(owner, TRAIT_SINKING, TRAIT_STATUS_EFFECT(id))
		return

	ADD_TRAIT(owner, TRAIT_SINKING, TRAIT_STATUS_EFFECT(id))
	if(!was_sinking)
		to_chat(owner, span_warning("The weight I bear pulls me down."))
	if(move_down && (current_water.open_bottom || current_water.fake_bottomless))
		var/z_move_flags = (ZMOVE_SWIM_FLAGS | ZMOVE_FEEDBACK) & ~ZMOVE_INCAPACITATED_CHECKS
		var/turf/destination = owner.can_z_move(DOWN, current_water, z_move_flags = z_move_flags)
		if(destination && owner.zMove(DOWN, destination, z_move_flags = z_move_flags))
			to_chat(owner, span_warningbig("I sink beneath the water!"))

/datum/status_effect/swimming/proc/on_equipment_changed()
	SIGNAL_HANDLER
	update_sinking_state()

/datum/status_effect/swimming/proc/on_stat_change(mob/living/source, new_stat, old_stat)
	SIGNAL_HANDLER
	if(!owner.client || HAS_TRAIT(owner, TRAIT_NOBREATH))
		return
	if(old_stat == DEAD || new_stat != DEAD)
		return
	record_round_statistic(STATS_PEOPLE_DROWNED)

/datum/status_effect/swimming/proc/stop_swimming()
	SIGNAL_HANDLER
	qdel(src)
