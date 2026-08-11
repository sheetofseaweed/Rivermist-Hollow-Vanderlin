#define BB_TENTACLE_AMBUSH_HOME "BB_tentacle_ambush_home"
#define BB_TENTACLE_AMBUSH_LEASH "BB_tentacle_ambush_leash"
#define BB_TENTACLE_COLONY_KIDNAP_STARTED "BB_tentacle_colony_kidnap_started"
#define BB_TENTACLE_COLONY_KIDNAP_TARGET "BB_tentacle_colony_kidnap_target"

/// Colony cores can disappear between the bounded component's asynchronous moved signal and its
/// bounds resolution. Keep that local teardown race from falling through to the base null turf read.
/datum/component/bounded/tentacle_colony

/datum/component/bounded/tentacle_colony/resolve_stranded()
	if(QDELETED(src) || QDELETED(parent) || QDELETED(master) || !get_turf(parent) || !get_turf(master))
		return
	return ..()

/datum/targetting_datum/basic/tentacle/ambusher

/datum/targetting_datum/basic/tentacle/ambusher/proc/is_within_home_range(mob/living/living_mob, atom/target)
	var/turf/home_turf = living_mob.ai_controller?.blackboard[BB_TENTACLE_AMBUSH_HOME]
	var/leash_distance = living_mob.ai_controller?.blackboard[BB_TENTACLE_AMBUSH_LEASH]
	var/turf/pawn_turf = get_turf(living_mob)
	var/turf/target_turf = get_turf(target)
	if(!home_turf || !pawn_turf || !target_turf || leash_distance <= 0)
		return FALSE
	if(home_turf.z != pawn_turf.z || home_turf.z != target_turf.z)
		return FALSE
	if(get_dist(home_turf, pawn_turf) > leash_distance)
		return FALSE
	return get_dist(home_turf, target_turf) <= leash_distance

/datum/targetting_datum/basic/tentacle/ambusher/can_attack(mob/living/living_mob, atom/target)
	if(!..())
		return FALSE
	return is_within_home_range(living_mob, target)

/datum/targetting_datum/basic/tentacle/ambusher/can_horny(mob/living/living_mob, atom/target)
	if(!..())
		return FALSE
	return is_within_home_range(living_mob, target)

/datum/targetting_datum/basic/tentacle/ambusher/maneater

/datum/targetting_datum/basic/tentacle/ambusher/maneater/is_horny_pref_target(mob/living/living_mob, atom/target)
	if(!ishuman(target))
		return FALSE
	var/mob/living/carbon/human/human_target = target
	if(!is_horny_mob_family_allowed(living_mob, human_target))
		return FALSE
	// Maneater vines are sexless plants. Either ordinary horny-mob gender opt-in enables them;
	// the dedicated family preference remains the authoritative plant-specific gate.
	return !!get_horny_mob_pref_flags(human_target)

/datum/ai_planning_subtree/basic_melee_attack_subtree/agile/tentacle_ambusher

/datum/ai_planning_subtree/basic_melee_attack_subtree/agile/tentacle_ambusher/SelectBehaviors(datum/ai_controller/controller, delta_time)
	var/atom/target = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	if(!QDELETED(target))
		var/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/tentacle = controller.pawn
		tentacle?.emerge_from_ground()
	return ..()

/datum/ai_planning_subtree/tentacle_return_home

/datum/ai_planning_subtree/tentacle_return_home/SelectBehaviors(datum/ai_controller/controller, delta_time)
	if(controller.blackboard[BB_BASIC_MOB_CURRENT_HORNY_TARGET] || controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET])
		return

	var/turf/home_turf = controller.blackboard[BB_TENTACLE_AMBUSH_HOME]
	var/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/tentacle = controller.pawn
	if(!home_turf || !istype(tentacle))
		return

	if(get_turf(tentacle) == home_turf || tentacle.Adjacent(home_turf))
		tentacle.hide_in_ground()
		return

	controller.queue_behavior(/datum/ai_behavior/tentacle_return_home, BB_TENTACLE_AMBUSH_HOME)
	return SUBTREE_RETURN_FINISH_PLANNING

/datum/ai_behavior/tentacle_return_home
	action_cooldown = 0.5 SECONDS
	required_distance = 1
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_MOVE_AND_PERFORM

/datum/ai_behavior/tentacle_return_home/setup(datum/ai_controller/controller, home_key)
	. = ..()
	var/turf/home_turf = controller.blackboard[home_key]
	var/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/tentacle = controller.pawn
	if(!home_turf || !istype(tentacle))
		return FALSE
	if(get_turf(tentacle) == home_turf || tentacle.Adjacent(home_turf))
		tentacle.hide_in_ground()
		return FALSE

	tentacle.emerge_from_ground()
	set_movement_target(controller, home_turf)
	return TRUE

/datum/ai_behavior/tentacle_return_home/perform(seconds_per_tick, datum/ai_controller/controller, home_key)
	. = ..()
	var/turf/home_turf = controller.blackboard[home_key]
	var/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/tentacle = controller.pawn
	if(!home_turf || !istype(tentacle))
		finish_action(controller, FALSE, home_key)
		return
	if(get_turf(tentacle) != home_turf && !tentacle.Adjacent(home_turf))
		return

	tentacle.hide_in_ground()
	finish_action(controller, TRUE, home_key)

/datum/ai_controller/tentacle_ambusher
	movement_delay = 0.5 SECONDS
	ai_movement = /datum/ai_movement/hybrid_pathing
	horny_pref_family_flag = HORNY_MOB_TYPE_TENTACLES

	blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic/tentacle/ambusher(),
	)

	planning_subtrees = list(
		/datum/ai_planning_subtree/kidnap_defeated_prey,
		/datum/ai_planning_subtree/simple_find_horny,
		/datum/ai_planning_subtree/horny,

		/datum/ai_planning_subtree/simple_find_target,
		/datum/ai_planning_subtree/basic_melee_attack_subtree/agile/tentacle_ambusher,

		/datum/ai_planning_subtree/tentacle_return_home,
	)

	idle_behavior = /datum/idle_behavior/nothing

/datum/ai_controller/tentacle_ambusher/maneater
	horny_pref_family_flag = HORNY_MOB_TYPE_MANEATERS
	blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic/tentacle/ambusher/maneater(),
	)

/datum/ai_controller/tentacle_colony_defender
	movement_delay = 0.5 SECONDS
	ai_movement = /datum/ai_movement/hybrid_pathing
	horny_pref_family_flag = HORNY_MOB_TYPE_TENTACLES

	blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic/tentacle/ambusher(),
	)

	planning_subtrees = list(
		/datum/ai_planning_subtree/tentacle_colony_kidnap,
		/datum/ai_planning_subtree/simple_find_horny,
		/datum/ai_planning_subtree/horny,

		/datum/ai_planning_subtree/simple_find_target,
		/datum/ai_planning_subtree/basic_melee_attack_subtree/agile/tentacle_ambusher,

		/datum/ai_planning_subtree/tentacle_return_home,
	)

	idle_behavior = /datum/idle_behavior/nothing

/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher
	name = "greater burrow tentacle"
	desc = "A thick, wine-dark tentacle rooted beneath the soil. It looks unwilling to stray far from its burrow."
	icon = 'modular_rmh/icons/mob/monster/tentacle_spawns.dmi'
	icon_state = "tentacle_big"
	icon_living = "tentacle_big"
	icon_dead = "tentacle_big_dead"
	ai_controller = /datum/ai_controller/tentacle_ambusher

	health = 80
	maxHealth = 80
	base_constitution = 7
	base_strength = 8
	base_speed = 10
	melee_damage_lower = 8
	melee_damage_upper = 14
	vision_range = 7
	aggro_vision_range = 7

	/// Maximum distance this tentacle can move or select a target from its initial turf.
	var/leash_distance = 7
	/// Icon state used while lying in wait. Null means the mob hides by becoming transparent.
	var/hide_icon_state = "tentacle_big_hide_on"
	/// One-shot emergence animation. Null means the living sprite simply appears.
	var/emerge_icon_state = "tentacle_big_hide_off"
	/// Whether the tentacle is currently withdrawn into its burrow.
	var/ambush_hidden = FALSE
	/// Colony which produced this defender. A weak reference lets the defender harmlessly fall back to
	/// ordinary ambush behavior if its core is destroyed.
	var/tmp/datum/weakref/colony_core_ref

/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/Initialize(mapload)
	. = ..()
	var/turf/home_turf = get_turf(src)
	if(home_turf)
		ai_controller?.set_blackboard_key(BB_TENTACLE_AMBUSH_HOME, home_turf)
		ai_controller?.set_blackboard_key(BB_TENTACLE_AMBUSH_LEASH, leash_distance)
		AddComponent(/datum/component/bounded, home_turf, 0, leash_distance, null, null, FALSE, FALSE)
	RegisterSignal(src, COMSIG_HORNY_TARGET_SET, PROC_REF(on_horny_target_set))
	RegisterSignal(src, COMSIG_ATOM_WAS_ATTACKED, PROC_REF(on_ambush_attacked))
	hide_in_ground()

/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/Destroy()
	if(isliving(pulling))
		var/mob/living/pulled_victim = pulling
		pulled_victim.clear_kidnap_reservation(src)
	if(pulling)
		stop_pulling()
	colony_core_ref = null
	UnregisterSignal(src, list(COMSIG_HORNY_TARGET_SET, COMSIG_ATOM_WAS_ATTACKED))
	return ..()

/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/death(gibbed)
	if(ambush_hidden)
		ambush_hidden = FALSE
		alpha = initial(alpha)
		density = initial(density)
		mouse_opacity = initial(mouse_opacity)
	return ..()

/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/proc/on_horny_target_set(datum/source, has_target)
	SIGNAL_HANDLER
	if(has_target)
		emerge_from_ground()

/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/proc/on_ambush_attacked()
	SIGNAL_HANDLER
	emerge_from_ground()

/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/proc/hide_in_ground()
	if(ambush_hidden || stat == DEAD)
		return
	ambush_hidden = TRUE
	density = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	if(hide_icon_state)
		icon_state = hide_icon_state
		return
	alpha = 0

/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/proc/emerge_from_ground()
	if(!ambush_hidden || stat == DEAD)
		return
	ambush_hidden = FALSE
	alpha = initial(alpha)
	density = initial(density)
	mouse_opacity = initial(mouse_opacity)
	icon_state = icon_living
	if(emerge_icon_state)
		flick(emerge_icon_state, src)

/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/proc/set_colony_core(obj/structure/tentacle_growth/colony_core/core)
	colony_core_ref = core ? WEAKREF(core) : null
	if(!core)
		return
	var/datum/component/bounded/old_bounds = GetComponent(/datum/component/bounded)
	old_bounds?.RemoveComponent()
	// Keep the original burrow as the combat leash, but permit the one deliberate route between that
	// burrow and the colony core when hauling prey.
	var/core_route_distance = max(leash_distance, get_dist(src, core) + 1)
	AddComponent(/datum/component/bounded/tentacle_colony, core, 0, core_route_distance, null, null, FALSE, FALSE)

/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/proc/get_colony_core()
	var/obj/structure/tentacle_growth/colony_core/core = colony_core_ref?.resolve()
	if(istype(core) && !QDELETED(core))
		return core
	colony_core_ref = null
	return null

/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/proc/is_colony_kidnap_candidate(mob/living/victim, allow_own_reservation = FALSE)
	if(!get_colony_core() || world.time < kidnap_retry_after)
		return FALSE
	if(!istype(victim) || victim == src || victim.buckled)
		return FALSE
	if(world.time < victim.kidnap_protected_until)
		return FALSE
	var/mob/living/reserving_captor = victim.get_kidnap_reserver()
	if(reserving_captor && (!allow_own_reservation || reserving_captor != src))
		return FALSE
	if(!victim.has_status_effect(/datum/status_effect/defeat_knockout))
		return FALSE
	if(victim.last_defeat_snapshot?.reason != DEFEAT_REASON_HORNY)
		return FALSE
	if(victim.GetComponent(/datum/component/kidnap_captivity))
		return FALSE
	return TRUE

/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/proc/begin_colony_kidnap(mob/living/victim)
	if(!Adjacent(victim) || !is_colony_kidnap_candidate(victim) || kidnap_is_outnumbered(victim))
		return FALSE
	if(!victim.try_reserve_kidnap(src))
		return FALSE

	if(ishuman(victim))
		var/mob/living/carbon/human/human_victim = victim
		if(human_victim.get_num_arms(TRUE) > 1 && !human_victim.handcuffed)
			var/obj/item/rope/spider_silk/tentacle_resin/restraints = new
			if(!restraints.apply_cuffs(human_victim))
				qdel(restraints)

	if(!start_handless_pull(victim, GRAB_AGGRESSIVE, suppress_message = TRUE))
		victim.clear_kidnap_reservation(src)
		return FALSE

	emerge_from_ground()
	visible_message(
		span_userdanger("[src] knots itself around [victim] and begins dragging [victim.p_them()] toward the colony!"),
		null,
		span_hear("I hear resin stretch and a body scrape across the ground."),
	)
	to_chat(victim, span_userdanger("[src] binds my limbs in resin and starts dragging me toward its core!"))
	return TRUE

/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/proc/finish_colony_kidnap(mob/living/victim, turf/nest_turf)
	if(pulling != victim || victim.pulledby != src || !is_colony_kidnap_candidate(victim, allow_own_reservation = TRUE))
		return FALSE
	if(!nest_turf || get_dist(src, nest_turf) > 1)
		return FALSE

	var/obj/structure/tentacle_growth/nest/nest = locate() in nest_turf
	if(nest?.has_buckled_mobs())
		return FALSE
	if(!nest)
		nest = new(nest_turf)
	stop_pulling()
	if(!nest.buckle_mob(victim, TRUE, check_loc = FALSE))
		victim.clear_kidnap_reservation(src)
		return FALSE

	victim.clear_kidnap_reservation(src)
	visible_message(
		span_userdanger("[src] presses [victim] into [nest] and seals [victim.p_them()] beneath fresh resin!"),
		null,
		span_hear("I hear a wet, fibrous cocoon tightening."),
	)
	to_chat(victim, span_userdanger("The tentacles seal me into [nest]. I can struggle free, or hope someone cuts me loose."))
	return TRUE

/datum/ai_planning_subtree/tentacle_colony_kidnap

/datum/ai_planning_subtree/tentacle_colony_kidnap/SelectBehaviors(datum/ai_controller/controller, delta_time)
	var/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/defender = controller.pawn
	if(!istype(defender) || !defender.get_colony_core())
		return

	var/mob/living/target = controller.blackboard[BB_TENTACLE_COLONY_KIDNAP_TARGET]
	if(target && (QDELETED(target) || !defender.is_colony_kidnap_candidate(target, allow_own_reservation = TRUE)))
		if(defender.pulling == target)
			defender.stop_pulling()
		if(!QDELETED(target))
			target.clear_kidnap_reservation(defender)
		controller.clear_blackboard_key(BB_TENTACLE_COLONY_KIDNAP_TARGET)
		target = null

	if(!target)
		for(var/mob/living/candidate in view(KIDNAP_GUARD_VIEW, defender))
			if(!defender.is_colony_kidnap_candidate(candidate))
				continue
			target = candidate
			controller.set_blackboard_key(BB_TENTACLE_COLONY_KIDNAP_TARGET, candidate)
			break
	if(!target)
		return

	controller.queue_behavior(/datum/ai_behavior/tentacle_colony_kidnap, BB_TENTACLE_COLONY_KIDNAP_TARGET)
	return SUBTREE_RETURN_FINISH_PLANNING

/datum/ai_behavior/tentacle_colony_kidnap
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_MOVE_AND_PERFORM
	required_distance = 1

/datum/ai_behavior/tentacle_colony_kidnap/perform(seconds_per_tick, datum/ai_controller/controller, target_key)
	. = ..()
	var/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/defender = controller.pawn
	var/mob/living/victim = controller.blackboard[target_key]
	var/obj/structure/tentacle_growth/colony_core/core = defender?.get_colony_core()
	if(!istype(defender) || !core || QDELETED(victim))
		finish_action(controller, FALSE, target_key)
		return

	if(defender.pulling != victim || victim.get_kidnap_reserver() != defender)
		if(!defender.is_colony_kidnap_candidate(victim))
			finish_action(controller, FALSE, target_key)
			return
		set_movement_target(controller, victim)
		if(defender.Adjacent(victim))
			if(!defender.begin_colony_kidnap(victim))
				finish_action(controller, FALSE, target_key)
				return
			controller.set_blackboard_key(BB_TENTACLE_COLONY_KIDNAP_STARTED, world.time)
		return

	if(victim.pulledby != defender || !defender.is_colony_kidnap_candidate(victim, allow_own_reservation = TRUE))
		finish_action(controller, FALSE, target_key)
		return
	var/started_at = controller.blackboard[BB_TENTACLE_COLONY_KIDNAP_STARTED]
	if(!started_at || world.time > started_at + 45 SECONDS)
		finish_action(controller, FALSE, target_key)
		return

	var/turf/nest_turf = core.get_available_nest_turf()
	if(!nest_turf)
		finish_action(controller, FALSE, target_key)
		return
	set_movement_target(controller, nest_turf)
	if(get_dist(defender, nest_turf) <= 1)
		var/succeeded = defender.finish_colony_kidnap(victim, nest_turf)
		finish_action(controller, succeeded, target_key)

/datum/ai_behavior/tentacle_colony_kidnap/finish_action(datum/ai_controller/controller, succeeded, target_key)
	var/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/defender = controller.pawn
	var/mob/living/victim = controller.blackboard[target_key]
	if(!succeeded && defender?.pulling == victim)
		defender.stop_pulling()
	if(victim && !QDELETED(victim))
		victim.clear_kidnap_reservation(defender)
	controller.clear_blackboard_key(BB_TENTACLE_COLONY_KIDNAP_STARTED)
	controller.clear_blackboard_key(target_key)
	return ..()

/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/alternative
	icon = 'modular_rmh/icons/mob/monster/tentacle_spawns_alt.dmi'

/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/medium
	name = "burrow tentacle"
	desc = "A searching tentacle that can vanish almost completely into a narrow burrow."
	icon_state = "tentacle_medium"
	icon_living = "tentacle_medium"
	health = 55
	maxHealth = 55
	base_constitution = 6
	base_strength = 6
	base_speed = 11
	melee_damage_lower = 6
	melee_damage_upper = 11
	vision_range = 6
	aggro_vision_range = 6
	leash_distance = 6
	hide_icon_state = null
	emerge_icon_state = null

/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/medium/alternative
	icon = 'modular_rmh/icons/mob/monster/tentacle_spawns_alt.dmi'

/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/medium/alternative/colony
	ai_controller = /datum/ai_controller/tentacle_colony_defender
	kidnap_lair_tag = null
	kidnap_captivity_profile = null

/// Green stomach vines use the burrow-tentacle movement and combat model, but belong to the
/// maneater preference family and produce seedlings rather than more tentacles.
/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/maneater
	name = "maneater stomach vine"
	desc = "A slick green feeding vine rooted in the yielding walls of a maneater's stomach."
	icon = 'modular_rmh/icons/mob/monster/maneater_tentacles.dmi'
	icon_state = "tentacle_medium"
	icon_living = "tentacle_medium"
	icon_dead = "tentacle_big_dead"
	ai_controller = /datum/ai_controller/tentacle_ambusher/maneater
	faction = list("maneater")
	kidnap_lair_tag = null
	kidnap_captivity_profile = null
	health = 55
	maxHealth = 55
	base_constitution = 6
	base_strength = 6
	base_speed = 11
	melee_damage_lower = 6
	melee_damage_upper = 11
	vision_range = 8
	aggro_vision_range = 8
	leash_distance = 8
	hide_icon_state = null
	emerge_icon_state = null

/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/maneater/Initialize(mapload)
	. = ..()
	var/obj/item/organ/genitals/penis/ovipositor/ovipositor = ensure_typed_ovipositor(src, OVI_EGG_MANEATER)
	if(ovipositor)
		ovipositor.name = "seed-bearing vine"
		ovipositor.desc = "A prehensile plant tendril adapted to implant soft, root-filled eggs."

/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/maneater/small
	name = "lesser maneater stomach vine"
	desc = "A thin green tendril searching the stomach floor for something warm to coil around."
	icon_state = "tentacle_small"
	icon_living = "tentacle_small"
	health = 35
	maxHealth = 35
	base_constitution = 4
	base_strength = 4
	base_speed = 12
	melee_damage_lower = 3
	melee_damage_upper = 7
	leash_distance = 7

/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/small
	name = "lesser burrow tentacle"
	desc = "A slim, furtive tentacle. Where one waits, several more are usually close by."
	icon_state = "tentacle_small"
	icon_living = "tentacle_small"
	health = 35
	maxHealth = 35
	base_constitution = 4
	base_strength = 4
	base_speed = 12
	melee_damage_lower = 3
	melee_damage_upper = 7
	vision_range = 5
	aggro_vision_range = 5
	leash_distance = 5
	hide_icon_state = null
	emerge_icon_state = null

/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/small/alternative
	icon = 'modular_rmh/icons/mob/monster/tentacle_spawns_alt.dmi'

/// Colony-created defenders physically haul defeated prey back to their core. They deliberately do
/// not inherit the roaming tentacle's mapped-lair teleport behavior.
/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/small/alternative/colony
	ai_controller = /datum/ai_controller/tentacle_colony_defender
	kidnap_lair_tag = null
	kidnap_captivity_profile = null

/obj/effect/spawner/tentacle_pack
	name = "mixed tentacle pack spawner"
	icon = 'modular_rmh/icons/mob/monster/tentacle_spawns.dmi'
	icon_state = "tentacle_medium"
	/// Minimum number of individual tentacles produced by this mapper helper.
	var/minimum_tentacles = 2
	/// Maximum number of individual tentacles produced by this mapper helper.
	var/maximum_tentacles = 4
	/// Radius used to cluster the pack around the mapped spawner.
	var/spawn_radius = 2
	/// Weighted mob paths available to this pack.
	var/list/tentacle_types = list(
		/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher = 1,
		/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/medium = 4,
		/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/small = 5,
	)

/obj/effect/spawner/tentacle_pack/Initialize(mapload)
	var/list/valid_turfs = list()
	for(var/turf/open/candidate_turf as anything in RANGE_TURFS(spawn_radius, src))
		if(candidate_turf.is_blocked_turf())
			continue
		valid_turfs += candidate_turf
	if(!length(valid_turfs))
		return ..()

	var/spawn_count = min(rand(minimum_tentacles, maximum_tentacles), length(valid_turfs))
	for(var/index in 1 to spawn_count)
		var/turf/spawn_turf = pick_n_take(valid_turfs)
		var/mob_type = pickweight(tentacle_types)
		new mob_type(spawn_turf)

	return ..()

/obj/effect/spawner/tentacle_pack/large
	name = "large tentacle pack spawner"
	minimum_tentacles = 2
	maximum_tentacles = 3
	tentacle_types = list(
		/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher = 2,
		/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/medium = 3,
	)

/obj/effect/spawner/tentacle_pack/small
	name = "small tentacle pack spawner"
	icon_state = "tentacle_small"
	minimum_tentacles = 3
	maximum_tentacles = 5
	tentacle_types = list(
		/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/medium = 1,
		/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/small = 6,
	)

/obj/effect/spawner/tentacle_pack/alternative
	name = "alternative mixed tentacle pack spawner"
	icon = 'modular_rmh/icons/mob/monster/tentacle_spawns_alt.dmi'
	tentacle_types = list(
		/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/alternative = 1,
		/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/medium/alternative = 4,
		/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/small/alternative = 5,
	)

/obj/effect/spawner/tentacle_pack/alternative/large
	name = "alternative large tentacle pack spawner"
	minimum_tentacles = 2
	maximum_tentacles = 3
	tentacle_types = list(
		/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/alternative = 2,
		/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/medium/alternative = 3,
	)

/obj/effect/spawner/tentacle_pack/alternative/small
	name = "alternative small tentacle pack spawner"
	icon_state = "tentacle_small"
	minimum_tentacles = 3
	maximum_tentacles = 5
	tentacle_types = list(
		/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/medium/alternative = 1,
		/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/small/alternative = 6,
	)

#undef BB_TENTACLE_AMBUSH_HOME
#undef BB_TENTACLE_AMBUSH_LEASH
#undef BB_TENTACLE_COLONY_KIDNAP_STARTED
#undef BB_TENTACLE_COLONY_KIDNAP_TARGET
