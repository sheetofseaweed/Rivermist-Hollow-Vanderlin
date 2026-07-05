/datum/pocket_dimension/dungeon
	/// TRUE once every guardian is dead
	var/cleared = FALSE
	/// Number of rooms cleared before this one in an infinite run; 0 for one-bite dungeons
	var/depth = 0
	/// How many combat rooms into the current stretch this room sits; 0 for break rooms
	var/stretch_position = 0
	/// DUNGEON_PATH_* of the gate that leads into this room; drives elite spawns
	var/incoming_path_type = DUNGEON_PATH_COMBAT
	/// DUNGEON_REWARD_* promised by the gate that led here; delivered on clear
	var/promised_reward = DUNGEON_REWARD_MOTES
	/// Key id for a VAULT room's keyholder + locked cache pair
	var/vault_key_id
	/// Set by a room trait before scatter: restrict scattered mobs to this style
	var/scatter_style_override = null
	/// Set by a room trait before scatter: add this many mobs to the scatter count
	var/scatter_count_bonus = 0
	/// The room's rolled trait, if any (Slice 4)
	var/datum/dungeon_room_trait/current_trait
	/// When TRUE (infinite-run rooms), collapse deletes loose foreign items and
	/// decals instead of ejecting them - didn't pick it up, don't get to keep it.
	var/delete_foreign_on_collapse = FALSE
	/// REF text -> weakref of living guardians that must die for the room to clear
	var/list/guardian_refs = list()
	/// REF text -> TRUE for mobs that belong to the dungeon; qdel'd on collapse instead of ejected
	var/list/native_mob_refs = list()
	/// REF text -> TRUE for guardians flagged elite (bigger mote drop)
	var/list/elite_guardian_refs = list()
	/// REF text -> mote bounty for promoted bosses in this room
	var/list/boss_bounties = list()
	/// REF text -> key_id for guardians that drop a key on death
	var/list/keyholder_drops = list()
	/// Owning infinite-dungeon run, if any
	var/datum/dungeon_run/owning_run
	/// Reward caches to unlock on clear
	var/list/obj/structure/dungeon_loot_cache/loot_caches = list()
	/// Gates created in this room by the run controller
	var/list/obj/structure/dungeon_gate/gates = list()
	/// list(list("turf" = T, "role" = DUNGEON_GATE_*)) collected from gate landmarks
	var/list/gate_landmark_info = list()
	/// Turfs where shrines should be built (break rooms)
	var/list/shrine_turfs = list()
	var/contents_setup_done = FALSE

/datum/pocket_dimension/dungeon/Destroy(force)
	var/obj/structure/dungeon_entrance/entrance = get_pocket_holder()
	owning_run = null
	guardian_refs = null
	native_mob_refs = null
	elite_guardian_refs = null
	boss_bounties = null
	keyholder_drops = null
	current_trait = null // shared singleton - never qdel
	loot_caches = null
	for(var/atom/movable/native as anything in native_movables)
		if(QDELETED(native) || ismob(native))
			continue
		qdel(native)
	QDEL_LIST(gates)
	gate_landmark_info = null
	shrine_turfs = null
	. = ..()
	if(istype(entrance))
		entrance.on_dungeon_collapsed(src)

/datum/pocket_dimension/dungeon/proc/get_dungeon_template()
	var/datum/map_template/pocket/dungeon/dungeon_template = template
	return istype(dungeon_template) ? dungeon_template : null

/datum/pocket_dimension/dungeon/activate()
	. = ..()
	if(. && !contents_setup_done)
		contents_setup_done = TRUE
		setup_dungeon_contents()

// Combat rooms in a run must not get the automatic fallback exit seam -
// the only way out of a stretch is forward or back through gates.
/datum/pocket_dimension/dungeon/create_exit_object(obj/effect/landmark/pocket_dimension/exit/exit_marker, turf/current_turf)
	var/datum/map_template/pocket/dungeon/dungeon_template = get_dungeon_template()
	if(!exit_marker && dungeon_template?.room_kind == DUNGEON_ROOM_COMBAT)
		return null
	return ..()

/// Rolls a room trait (50%) and lets it reshape the plan before scatter.
/datum/pocket_dimension/dungeon/proc/roll_room_trait()
	var/datum/map_template/pocket/dungeon/dungeon_template = get_dungeon_template()
	if(!dungeon_template)
		return
	var/trait_chance = owning_run?.floor_config ? owning_run.floor_config.trait_chance : DUNGEON_ROOM_TRAIT_CHANCE
	if(!prob(trait_chance))
		return
	var/list/pool = get_dungeon_room_traits(src, dungeon_template.room_kind)
	if(!length(pool))
		return
	// Traits are shared singletons - pick one, never qdel any.
	current_trait = pickweight(pool)
	current_trait.modify_plan(src)

/// Applies the rolled trait's post-spawn effects and announces it.
/datum/pocket_dimension/dungeon/proc/apply_room_trait_effects()
	if(!current_trait)
		return
	current_trait.apply_to_room(src)
	for(var/mob/occupant as anything in get_occupants())
		if(occupant.client && current_trait.announce)
			to_chat(occupant, span_warning(current_trait.announce))

/datum/pocket_dimension/dungeon/proc/setup_dungeon_contents()
	var/list/mobs_to_register = list()
	var/list/forced_elites = list()
	var/list/shrine_landmark_turfs = list()
	var/list/larder_turfs = list()
	var/want_scatter = FALSE
	var/scatter_density_override = 0
	var/scatter_marker_style = null

	for(var/turf/current_turf as anything in affected_turfs)
		for(var/obj/effect/landmark/dungeon/guardian/guardian_marker in current_turf)
			var/mob/living/spawned
			if(istype(guardian_marker, /obj/effect/landmark/dungeon/guardian/boss))
				spawned = spawn_floor_boss(guardian_marker, current_turf)
			else
				spawned = spawn_guardian_from_marker(guardian_marker, current_turf)
			if(spawned)
				mobs_to_register += spawned
				if(guardian_marker.force_elite)
					forced_elites[spawned] = TRUE
				if(istype(guardian_marker, /obj/effect/landmark/dungeon/guardian/keyholder))
					var/obj/effect/landmark/dungeon/guardian/keyholder/kh = guardian_marker
					keyholder_drops["[REF(spawned)]"] = kh.key_id
			qdel(guardian_marker)

		for(var/obj/effect/landmark/dungeon/loot/loot_marker in current_turf)
			var/obj/structure/dungeon_loot_cache/cache = loot_marker.create_cache(current_turf, src)
			if(cache)
				loot_caches += cache
				// Created after layout caching, so mark it native by hand or it
				// would be ejected outside as a "foreign movable" on collapse.
				native_movables[cache] = TRUE
			qdel(loot_marker)

		for(var/obj/effect/landmark/dungeon/gate/gate_marker in current_turf)
			gate_landmark_info += list(list("turf" = current_turf, "role" = gate_marker.gate_role, "path" = gate_marker.path_type, "requires_key" = gate_marker.requires_key, "key_id" = gate_marker.key_id))
			qdel(gate_marker)

		for(var/obj/effect/landmark/dungeon/shrine/shrine_marker in current_turf)
			shrine_landmark_turfs += current_turf
			qdel(shrine_marker)

		for(var/obj/effect/landmark/dungeon/encounter/encounter_marker in current_turf)
			want_scatter = TRUE
			scatter_density_override = max(scatter_density_override, encounter_marker.density_override)
			if(encounter_marker.style_filter)
				scatter_marker_style = encounter_marker.style_filter
			qdel(encounter_marker)

		for(var/obj/effect/landmark/dungeon/larder/larder_marker in current_turf)
			larder_turfs += current_turf
			qdel(larder_marker)

		// Hostile mobs mapped directly into the .dmm count as guardians too.
		for(var/mob/living/simple_animal/hostile/mapped_mob in current_turf)
			mobs_to_register |= mapped_mob

	shrine_turfs = shrine_landmark_turfs

	// Build the larder before guardians register, so natives can be tagged to it.
	if(length(larder_turfs) && owning_run)
		for(var/turf/larder_turf as anything in larder_turfs)
			build_larder(larder_turf)

	// Let a room trait reshape the plan (sets scatter_style_override / scatter_count_bonus).
	roll_room_trait()

	// Scatter random mobs from the floor pool, if this room requested an encounter.
	if(want_scatter && owning_run?.floor_config)
		var/datum/dungeon_floor_config/cfg = owning_run.floor_config
		var/count = scatter_density_override > 0 ? scatter_density_override : rand(cfg.density_min, cfg.density_max)
		var/party_size = max(1, length(owning_run.present_ckeys))
		count = min(count + (party_size - 1) + scatter_count_bonus, cfg.density_max + scatter_count_bonus + 4)
		var/use_style = scatter_style_override || scatter_marker_style
		var/list/turf/open = get_open_dungeon_turfs()
		for(var/i in 1 to count)
			if(!length(open))
				break
			var/turf/spot = pick(open)
			open -= spot
			var/datum/dungeon_spawn_entry/entry = pick_floor_spawn_entry(cfg, use_style, owning_run.get_target_tier())
			if(entry && ispath(entry.mob_type, /mob/living))
				mobs_to_register += new entry.mob_type(spot)

	var/datum/dungeon_floor_config/reg_cfg = owning_run?.floor_config
	var/elite_chance = reg_cfg ? reg_cfg.elite_chance : 0
	var/enhance_chance = reg_cfg ? reg_cfg.enhance_chance : 0
	for(var/mob/living/guardian as anything in mobs_to_register)
		var/is_elite = forced_elites[guardian] || (incoming_path_type == DUNGEON_PATH_ELITE) || prob(elite_chance)
		var/force_enhance = prob(enhance_chance)
		register_guardian(guardian, is_elite, force_enhance)

	// A VAULT-promised room hides its treasure behind a key: one guardian
	// becomes the keyholder, and the clear reward is a matching locked cache.
	if(promised_reward == DUNGEON_REWARD_VAULT && length(guardian_refs))
		vault_key_id = "vault_[REF(src)]"
		var/keyholder_ref = pick(guardian_refs)
		keyholder_drops[keyholder_ref] = vault_key_id

	apply_room_trait_effects()

	if(!length(guardian_refs))
		on_cleared(silent = TRUE)

/// Spawns a bonus loot cache on a drop turf. Used by door rewards and the
/// Treasure-laden trait. Returns the cache, or null without a valid turf.
/datum/pocket_dimension/dungeon/proc/spawn_bonus_loot_cache(sealed = FALSE, bonus_delve = 0, cache_key_id = null)
	var/turf/spot = get_drop_turf(null)
	if(!spot)
		return null
	var/obj/structure/dungeon_loot_cache/cache = new(spot)
	var/datum/map_template/pocket/dungeon/dungeon_template = get_dungeon_template()
	if(dungeon_template?.loot_table_type)
		cache.loot = new dungeon_template.loot_table_type
	cache.delve_level = max(1, depth + bonus_delve)
	if(cache_key_id)
		cache.key_id = cache_key_id
	if(!sealed)
		cache.unseal()
	loot_caches += cache
	native_movables[cache] = TRUE
	return cache

/mob/living/proc/get_kidnap_escape_override()
	var/turf/here = get_turf(src)
	if(!here)
		return null
	for(var/datum/dungeon_run/run as anything in get_active_dungeon_runs())
		if(run.ending || QDELETED(run.current_break_room))
			continue
		for(var/datum/pocket_dimension/dungeon/room as anything in run.get_all_rooms())
			if(room.contains_turf(here))
				return run.current_break_room.get_entry_turf()
	return null

/datum/pocket_dimension/dungeon/proc/build_larder(turf/larder_turf)
	if(QDELETED(larder_turf) || !owning_run)
		return
	var/run_tag = owning_run.get_larder_tag()
	var/obj/effect/landmark/kidnap/entrance/lair_entrance = new(larder_turf)
	lair_entrance.lair_tag = run_tag
	LAZYADDASSOCLIST(GLOB.kidnap_entrance_markers, run_tag, lair_entrance)
	LAZYREMOVEASSOC(GLOB.kidnap_entrance_markers, "default", lair_entrance)
	native_movables[lair_entrance] = TRUE
	// Escape tile beside it, so a released captive can crawl out.
	for(var/turf/adjacent as anything in RANGE_TURFS(1, larder_turf))
		if(adjacent == larder_turf || !is_valid_drop_turf(adjacent, null))
			continue
		var/obj/effect/landmark/kidnap/escape/lair_escape = new(adjacent)
		lair_escape.lair_tag = run_tag
		LAZYADDASSOCLIST(GLOB.kidnap_escape_markers, run_tag, lair_escape)
		LAZYREMOVEASSOC(GLOB.kidnap_escape_markers, "default", lair_escape)
		native_movables[lair_escape] = TRUE
		break

/datum/pocket_dimension/dungeon/proc/get_open_dungeon_turfs()
	var/list/turf/open = list()
	for(var/turf/current_turf as anything in affected_turfs)
		if(is_valid_drop_turf(current_turf, null))
			open += current_turf
	return open

/// Spawns a guardian from a marker's own pool, or — if empty, or the marker is
/// the /random subtype — from the run's floor combat pool.
/datum/pocket_dimension/dungeon/proc/spawn_guardian_from_marker(obj/effect/landmark/dungeon/guardian/marker, turf/spawn_turf)
	if(length(marker.mob_pool))
		return marker.spawn_guardian(spawn_turf)
	if(!owning_run?.floor_config)
		return null
	var/style_filter = null
	if(istype(marker, /obj/effect/landmark/dungeon/guardian/random))
		var/obj/effect/landmark/dungeon/guardian/random/random_marker = marker
		style_filter = random_marker.style_filter
	var/datum/dungeon_spawn_entry/entry = pick_floor_spawn_entry(owning_run.floor_config, style_filter, owning_run.get_target_tier())
	if(!entry || !ispath(entry.mob_type, /mob/living))
		return null
	return new entry.mob_type(spawn_turf)

/datum/pocket_dimension/dungeon/proc/spawn_floor_boss(obj/effect/landmark/dungeon/guardian/boss/boss_marker, turf/spawn_turf)
	var/boss_type
	if(boss_marker.use_floor_boss_pool && owning_run?.floor_config && length(owning_run.floor_config.boss_pool))
		boss_type = pickweight(owning_run.floor_config.boss_pool.Copy())
	else if(length(boss_marker.mob_pool))
		boss_type = pickweight(boss_marker.mob_pool.Copy())
	if(!ispath(boss_type, /mob/living))
		return null
	var/mob/living/boss = new boss_type(spawn_turf)
	var/run_floor = owning_run ? owning_run.floor : 1
	var/run_tier = owning_run ? owning_run.get_target_tier() : 1
	var/bounty = make_dungeon_boss(boss, run_floor, run_tier)
	boss_bounties["[REF(boss)]"] = bounty
	return boss

/datum/pocket_dimension/dungeon/proc/register_guardian(mob/living/guardian, elite = FALSE, force_enhance = FALSE)
	if(QDELETED(guardian) || guardian.stat == DEAD || guardian.mind || guardian.client)
		return
	native_mob_refs["[REF(guardian)]"] = TRUE
	guardian_refs["[REF(guardian)]"] = WEAKREF(guardian)
	if(depth > 0 || elite || force_enhance)
		SSmobs.enhance_mob_elite(guardian, depth, elite ? 2 : 0)
	if(elite)
		elite_guardian_refs["[REF(guardian)]"] = TRUE
		guardian.add_atom_colour("#ffcc33", TEMPORARY_COLOUR_PRIORITY)
		guardian.name = "Champion [guardian.name]"
	// Party scaling: a bigger present party makes guardians tougher.
	var/party_size = owning_run ? max(1, length(owning_run.present_ckeys)) : 1
	if(party_size > 1 && istype(guardian, /mob/living/simple_animal))
		var/party_factor = 1 + min(party_size - 1, 4) * 0.4 // +40% hp per extra member, capped at 5
		guardian.maxHealth = round(guardian.maxHealth * party_factor)
		guardian.health = guardian.maxHealth
	// One shared faction so goblins, bogbugs and wolves never brawl each other.
	guardian.faction = list(FACTION_DUNGEON)
	RegisterSignals(guardian, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING), PROC_REF(on_guardian_death))
	// Dungeon natives haul defeated prey to the run's own larder if one stands;
	// never to an overworld lair (that would teleport players out of the run).
	guardian.kidnap_lair_tag = owning_run?.get_live_larder_tag()
	if(iscarbon(guardian))
		// Carbons never reach "dead" cleanly in a brawl - pain/shock thresholds drop
		// them into crit long before health runs out, and their AI flees in pain.
		// Dungeon guardians fight to the fall: no fleeing, and a downed carbon
		// counts as defeated so the room clears.
		if("flee_in_pain" in guardian.vars)
			guardian.vars["flee_in_pain"] = FALSE
		RegisterSignal(guardian, COMSIG_LIVING_HEALTH_UPDATE, PROC_REF(on_carbon_guardian_health))

/// A carbon guardian knocked into crit counts as defeated (see register_guardian).
/datum/pocket_dimension/dungeon/proc/on_carbon_guardian_health(mob/living/source)
	SIGNAL_HANDLER
	if(source.stat < UNCONSCIOUS)
		return
	on_guardian_death(source)

/datum/pocket_dimension/dungeon/proc/on_guardian_death(mob/living/source)
	SIGNAL_HANDLER
	var/source_ref = "[REF(source)]"
	if(!guardian_refs || !guardian_refs[source_ref])
		return // already counted (e.g. downed into crit, then killed)
	UnregisterSignal(source, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING, COMSIG_LIVING_HEALTH_UPDATE))
	if(keyholder_drops[source_ref])
		var/turf/drop_turf = get_turf(source)
		if(drop_turf)
			var/obj/item/dungeon_key/key = new(drop_turf)
			key.key_id = keyholder_drops[source_ref]
			native_movables[key] = TRUE
		keyholder_drops -= source_ref
	if(owning_run)
		var/floor_for_drops = owning_run.floor
		var/drop = DUNGEON_MOTE_GUARDIAN_BASE + (floor_for_drops - 1) * DUNGEON_MOTE_FLOOR_BONUS
		if(boss_bounties[source_ref])
			drop = boss_bounties[source_ref] + (floor_for_drops - 1) * DUNGEON_MOTE_FLOOR_BONUS * 5
		else if(elite_guardian_refs[source_ref])
			drop *= DUNGEON_MOTE_ELITE_MULT
		owning_run.award_motes(drop, source)
	boss_bounties -= source_ref
	elite_guardian_refs -= source_ref
	guardian_refs -= source_ref
	if(!cleared && !length(guardian_refs))
		on_cleared()

/datum/pocket_dimension/dungeon/proc/on_cleared(silent = FALSE)
	if(cleared)
		return
	cleared = TRUE
	idle_timeout = DUNGEON_CLEARED_IDLE_TIMEOUT
	for(var/obj/structure/dungeon_loot_cache/cache as anything in loot_caches)
		if(!QDELETED(cache))
			cache.unseal()
	if(!silent)
		for(var/mob/occupant as anything in get_occupants())
			to_chat(occupant, span_notice("The hostile presence fades. The walls give a long, grinding groan - this place will not hold its shape forever."))
	owning_run?.on_room_cleared(src)

/datum/pocket_dimension/dungeon/proc/is_native_dungeon_mob(mob/subject)
	if(subject.mind || subject.client)
		return FALSE
	return !!native_mob_refs?["[REF(subject)]"]

// Infinite-run rooms swallow whatever was left on the floor; standalone
// one-shot dungeons keep the base behavior (dropped items eject to the entrance).
/datum/pocket_dimension/dungeon/eject_foreign_movables(items_only = FALSE, atom/override_destination = null)
	if(!delete_foreign_on_collapse)
		return ..()
	for(var/atom/movable/movable as anything in get_preservable_foreign_movables(items_only))
		qdel(movable)
	QDEL_LIST_ASSOC_VAL(hibernated_foreign_movables)
	if(storage && !length(storage.contents))
		QDEL_NULL(storage)

// Native dungeon mobs die with the dungeon instead of being dumped outside.
// Captives held in this room's larder are released before the eject moves them.
/datum/pocket_dimension/dungeon/eject_occupants(message = null, atom/override_destination = null)
	var/run_tag = owning_run?.get_larder_tag()
	for(var/mob/occupant as anything in get_occupants())
		if(QDELETED(occupant))
			continue
		if(is_native_dungeon_mob(occupant))
			qdel(occupant)
			continue
		if(run_tag)
			var/datum/component/kidnap_captivity/captivity = occupant.GetComponent(/datum/component/kidnap_captivity)
			if(captivity?.lair_tag == run_tag)
				captivity.end_captivity()
	return ..()

// Only break rooms (and standalone one-bite dungeons) allow stepping back out.
/datum/pocket_dimension/dungeon/can_exit_mob(mob/user, obj/structure/pocket_dimension_exit/exit_object, show_feedback = TRUE)
	var/datum/map_template/pocket/dungeon/dungeon_template = get_dungeon_template()
	if(owning_run && dungeon_template?.room_kind != DUNGEON_ROOM_BREAK)
		if(show_feedback)
			to_chat(user, span_warning("The dungeon's grip is too strong here. I can only leave from a place of respite."))
		return FALSE
	return TRUE

/datum/pocket_dimension/dungeon/enter_mob(mob/user, turf/new_return_turf, atom/new_return_anchor = null)
	. = ..()
	if(. && current_trait?.announce && ismob(user))
		var/mob/entrant = user
		if(entrant.client)
			to_chat(entrant, span_warning(current_trait.announce))

/datum/pocket_dimension/dungeon/exit_mob(mob/user)
	if(owning_run && isliving(user))
		owning_run.strip_boons_from(user)
		owning_run.mark_absent(user)
	. = ..()
	if(. && owning_run)
		owning_run.note_possible_run_end()

/datum/pocket_dimension/dungeon/process_pocket()
	owning_run?.check_abandonment()
	return ..()
