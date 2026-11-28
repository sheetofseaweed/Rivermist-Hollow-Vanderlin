/**
 * Shared helpers for the base spell and spell-family adapters.
 *
 * This file does not replace Activate() or the existing AOE/cone cast procs.
 * Apply the integration edits documented in integration/SPELL_INTEGRATION.md.
 */
/datum/action/cooldown/spell
	/// Immutable cast-origin snapshot for this spell execution.
	var/anti_magic_cast_origin_x
	var/anti_magic_cast_origin_y
	var/anti_magic_cast_origin_z
	/// Prepared effect turfs are reused by the family-specific cast implementation.
	var/list/anti_magic_prepared_effect_turfs
	/// Prepared AOE target list (filled by the AOE adapter).
	var/list/anti_magic_prepared_aoe_targets
	/// Prepared cone levels (filled by the cone adapter).
	var/list/anti_magic_prepared_cone_turfs

/datum/action/cooldown/spell/proc/clear_anti_magic_cast_context()
	anti_magic_cast_origin_x = null
	anti_magic_cast_origin_y = null
	anti_magic_cast_origin_z = null
	anti_magic_prepared_effect_turfs = null
	anti_magic_prepared_aoe_targets = null
	anti_magic_prepared_cone_turfs = null

/// Default shape adapter: a normal spell affects its selected target turf.
/datum/action/cooldown/spell/proc/get_anti_magic_effect_turfs(atom/cast_on)
	var/list/effect_turfs = list()
	var/turf/target_turf = get_turf(cast_on)
	if(target_turf)
		effect_turfs += target_turf
	return effect_turfs

/// Called once by Activate() after ordinary validation and before feedback/effects.
/datum/action/cooldown/spell/proc/prepare_anti_magic_cast(atom/cast_on)
	clear_anti_magic_cast_context()
	var/turf/origin_turf = get_turf(owner)
	// A spell with no valid world origin cannot prove that it is outside a field.
	// Fail closed rather than silently bypassing anti-magic validation.
	if(!origin_turf)
		return FALSE
	anti_magic_cast_origin_x = origin_turf.x
	anti_magic_cast_origin_y = origin_turf.y
	anti_magic_cast_origin_z = origin_turf.z
	anti_magic_prepared_effect_turfs = get_anti_magic_effect_turfs(cast_on)
	return !GLOB.anti_magic_field_manager.is_action_blocked_on_turfs(
		origin_turf,
		"[type]",
		anti_magic_prepared_effect_turfs,
	)

/// Reusable late-effect check for touch, delayed effects, and other custom execution paths.
/datum/action/cooldown/spell/proc/is_anti_magic_effect_blocked(atom/effect_target)
	var/turf/origin_turf
	if(!isnull(anti_magic_cast_origin_x) && !isnull(anti_magic_cast_origin_y) && !isnull(anti_magic_cast_origin_z))
		origin_turf = locate(anti_magic_cast_origin_x, anti_magic_cast_origin_y, anti_magic_cast_origin_z)
	var/list/effect_turfs = list()
	var/turf/effect_turf = get_turf(effect_target)
	if(effect_turf)
		effect_turfs += effect_turf
	return GLOB.anti_magic_field_manager.is_action_blocked_on_turfs(origin_turf, "[type]", effect_turfs)

/// Call from the shared projectile creation/firing path, while the cast context is alive.
/datum/action/cooldown/spell/proc/apply_anti_magic_projectile_metadata(obj/projectile/projectile)
	if(!projectile)
		return FALSE
	projectile.anti_magic_action_id = "[type]"
	projectile.anti_magic_origin_x = anti_magic_cast_origin_x
	projectile.anti_magic_origin_y = anti_magic_cast_origin_y
	projectile.anti_magic_origin_z = anti_magic_cast_origin_z
	return TRUE


/*
 * Effect-family adapters.
 *
 * These are deliberately defined on shared spell families, not individual
 * spells. Unknown/unreviewed spell families inherit the base target-turf
 * behavior and remain denied by the manager unless explicitly whitelisted.
 */

/datum/action/cooldown/spell/aoe/get_anti_magic_effect_turfs(atom/cast_on)
	// Prepare the target selection exactly once. The same list is consumed by cast().
	var/list/targets = get_things_to_cast_on(cast_on)
	if(!islist(targets))
		// A malformed family adapter must not silently turn an unknown AOE into an allowed cast.
		anti_magic_prepared_aoe_targets = list()
		return list()
	if(shuffle_targets_list)
		shuffle_inplace(targets)
	if(max_targets > 0 && length(targets) > max_targets)
		targets = targets.Copy(1, max_targets + 1)
	anti_magic_prepared_aoe_targets = targets

	var/list/effect_turfs = list()
	// Include the center turf as well; some AOE families create environmental effects there.
	var/turf/center_turf = get_turf(cast_on)
	if(center_turf)
		effect_turfs += center_turf
	for(var/atom/affected_atom as anything in targets)
		var/turf/affected_turf = get_turf(affected_atom)
		if(affected_turf && !(affected_turf in effect_turfs))
			effect_turfs += affected_turf
	return effect_turfs

/datum/action/cooldown/spell/cone/get_anti_magic_effect_turfs(atom/cast_on)
	var/turf/starter_turf = get_turf(cast_on)
	if(!starter_turf)
		anti_magic_prepared_cone_turfs = list()
		return list()

	anti_magic_prepared_cone_turfs = get_cone_turfs(starter_turf, cast_on.dir, cone_levels)
	var/list/effect_turfs = list()
	for(var/list/level_turfs as anything in anti_magic_prepared_cone_turfs)
		for(var/turf/affected_turf as anything in level_turfs)
			if(affected_turf && !(affected_turf in effect_turfs))
				effect_turfs += affected_turf
	return effect_turfs


/// Beam effects occupy every turf along the caster-target line, not only their endpoints.
/datum/action/cooldown/spell/beam/get_anti_magic_effect_turfs(atom/cast_on)
	var/list/effect_turfs = list()
	var/turf/source_turf = get_turf(owner)
	var/turf/target_turf = get_turf(cast_on)
	if(!source_turf || !target_turf)
		return effect_turfs
	for(var/turf/beam_turf as anything in getline(source_turf, target_turf))
		if(beam_turf && !(beam_turf in effect_turfs))
			effect_turfs += beam_turf
	return effect_turfs
