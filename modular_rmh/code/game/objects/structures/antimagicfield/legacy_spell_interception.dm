/**
 * Legacy spell-framework adapter.
 *
 * The wizard spells shown in the video (including Sundering Lightning and
 * Blade Burst) are /obj/effect/proc_holder/spell children. They do NOT execute
 * through /datum/action/cooldown/spell/Activate(). The base cast_check()/perform()
 * hooks must therefore call this adapter or the modern interception patch will
 * never see them.
 */
/obj/effect/proc_holder/spell
	/// Additional radius for spells whose cast() expands beyond its selected target.
	var/anti_magic_effect_radius = 0
	/// Use the caster as the expansion center instead of targets[1].
	var/anti_magic_effect_center_on_caster = FALSE
	/// Restrict radius expansion to the caster's current view (used by LOS-limited AOEs).
	var/anti_magic_effect_respect_los = FALSE

/// Gather the selected target turfs and any explicitly declared effect footprint.
/obj/effect/proc_holder/spell/proc/get_anti_magic_field_effect_turfs(list/targets, mob/user)
	var/list/effect_turfs = list()
	for(var/atom/target_atom as anything in targets)
		var/turf/target_turf = get_turf(target_atom)
		if(target_turf && !(target_turf in effect_turfs))
			effect_turfs += target_turf

	if(anti_magic_effect_radius <= 0)
		return effect_turfs

	var/turf/effect_center
	if(anti_magic_effect_center_on_caster)
		effect_center = get_turf(user)
	else if(length(targets))
		effect_center = get_turf(targets[1])
	if(!effect_center)
		return effect_turfs

	var/list/visible_turfs
	if(anti_magic_effect_respect_los)
		var/turf/source_turf = get_turf(user)
		if(source_turf && effect_center.z > source_turf.z)
			source_turf = get_step_multiz(source_turf, UP)
		else if(source_turf && effect_center.z < source_turf.z)
			source_turf = get_step_multiz(source_turf, DOWN)
		if(source_turf)
			visible_turfs = list()
			for(var/turf/visible_turf as anything in view(source_turf))
				visible_turfs += visible_turf

	for(var/turf/affected_turf as anything in view(anti_magic_effect_radius, effect_center))
		if(anti_magic_effect_respect_los && (!visible_turfs || !(affected_turf in visible_turfs)))
			continue
		if(!(affected_turf in effect_turfs))
			effect_turfs += affected_turf
	return effect_turfs

/// Shared predicate used by cast_check() and perform().
/obj/effect/proc_holder/spell/proc/anti_magic_field_blocks_cast(list/targets, mob/user)
	var/turf/source_turf = get_turf(user)
	var/list/effect_turfs = get_anti_magic_field_effect_turfs(targets, user)
	return GLOB.anti_magic_field_manager.is_action_blocked_on_turfs(source_turf, "[type]", effect_turfs)

// Precise AOE footprints for the player-harming wizard spells in learnable_spells.
// Keep these accessors independent of child-only spell vars: this adapter is
// compiled as a separate modular file and must not require those vars to be in
// the parent proc-holder declaration.
/obj/effect/proc_holder/spell/invoked/sundering_lightning/proc/get_anti_magic_footprint_radius()
	return 4 // Matches Sundering Lightning's range.

/obj/effect/proc_holder/spell/invoked/sundering_lightning/get_anti_magic_field_effect_turfs(list/targets, mob/user)
	var/list/effect_turfs = ..()
	if(!length(targets))
		return effect_turfs
	var/turf/center = get_turf(targets[1])
	if(!center)
		return effect_turfs
	for(var/turf/affected_turf as anything in spiral_range_turfs(get_anti_magic_footprint_radius(), center))
		if(!(affected_turf in effect_turfs))
			effect_turfs += affected_turf
	return effect_turfs

/obj/effect/proc_holder/spell/invoked/blade_burst/proc/get_anti_magic_footprint_radius()
	return 1 // Matches Blade Burst's area_of_effect.

/obj/effect/proc_holder/spell/invoked/blade_burst/get_anti_magic_field_effect_turfs(list/targets, mob/user)
	var/list/effect_turfs = ..()
	if(!length(targets))
		return effect_turfs
	var/turf/center = get_turf(targets[1])
	var/turf/source_turf = get_turf(user)
	if(!center || !source_turf)
		return effect_turfs
	if(center.z > source_turf.z)
		source_turf = get_step_multiz(source_turf, UP)
	else if(center.z < source_turf.z)
		source_turf = get_step_multiz(source_turf, DOWN)
	for(var/turf/affected_turf as anything in view(get_anti_magic_footprint_radius(), center))
		if(!(affected_turf in view(source_turf)))
			continue
		if(!(affected_turf in effect_turfs))
			effect_turfs += affected_turf
	return effect_turfs

/obj/effect/proc_holder/spell/invoked/meteor_storm/get_anti_magic_field_effect_turfs(list/targets, mob/user)
	var/list/effect_turfs = ..()
	if(length(targets))
		var/turf/center = get_turf(targets[1])
		if(center)
			for(var/turf/affected_turf as anything in RANGE_TURFS(9, center))
				if(!(affected_turf in effect_turfs))
					effect_turfs += affected_turf
	return effect_turfs

/obj/effect/proc_holder/spell/invoked/thunderstrike/get_anti_magic_field_effect_turfs(list/targets, mob/user)
	var/list/effect_turfs = ..()
	if(length(targets))
		var/turf/center = get_turf(targets[1])
		if(center)
			for(var/turf/affected_turf in range(2, center))
				if(get_dist(center, affected_turf) > 2 || !(affected_turf in view(center)))
					continue
				if(!(affected_turf in effect_turfs))
					effect_turfs += affected_turf
	return effect_turfs

/obj/effect/proc_holder/spell/invoked/snap_freeze/proc/get_anti_magic_footprint_radius()
	return 2 // Matches Snap Freeze's area_of_effect.

/obj/effect/proc_holder/spell/invoked/snap_freeze/get_anti_magic_field_effect_turfs(list/targets, mob/user)
	var/list/effect_turfs = ..()
	if(length(targets))
		var/turf/center = get_turf(targets[1])
		var/turf/source_turf = get_turf(user)
		if(center && source_turf)
			if(center.z > source_turf.z)
				source_turf = get_step_multiz(source_turf, UP)
			else if(center.z < source_turf.z)
				source_turf = get_step_multiz(source_turf, DOWN)
			for(var/turf/affected_turf as anything in view(get_anti_magic_footprint_radius(), center))
				if(!(affected_turf in view(source_turf)))
					continue
				if(!(affected_turf in effect_turfs))
					effect_turfs += affected_turf
	return effect_turfs

/obj/effect/proc_holder/spell/invoked/ensnare/proc/get_anti_magic_footprint_radius()
	return 1 // Matches Ensnare's area_of_effect.

/obj/effect/proc_holder/spell/invoked/ensnare/get_anti_magic_field_effect_turfs(list/targets, mob/user)
	var/list/effect_turfs = ..()
	if(length(targets))
		var/turf/center = get_turf(targets[1])
		if(center)
			for(var/turf/affected_turf in range(get_anti_magic_footprint_radius(), center))
				if(!(affected_turf in effect_turfs))
					effect_turfs += affected_turf
	return effect_turfs

/obj/effect/proc_holder/spell/invoked/repulse/proc/get_anti_magic_footprint_radius()
	return 1 // Matches Repulse's push_range.

/obj/effect/proc_holder/spell/invoked/repulse/get_anti_magic_field_effect_turfs(list/targets, mob/user)
	var/list/effect_turfs = ..()
	var/turf/center = get_turf(user)
	if(center)
		for(var/turf/affected_turf as anything in view(get_anti_magic_footprint_radius(), center))
			if(!(affected_turf in effect_turfs))
				effect_turfs += affected_turf
	return effect_turfs

// Gravity currently declares area_of_effect = 0; the base target-turf footprint is exact.

/obj/effect/proc_holder/spell/invoked/wither/get_anti_magic_field_effect_turfs(list/targets, mob/user)
	var/list/effect_turfs = ..()
	if(length(targets))
		var/turf/source_turf = get_turf(user)
		var/turf/target_turf = get_turf(targets[1])
		if(source_turf && target_turf)
			for(var/turf/line_turf as anything in getline(source_turf, target_turf))
				if(!(line_turf in effect_turfs))
					effect_turfs += line_turf
	return effect_turfs

/obj/effect/proc_holder/spell/invoked/aerosolize/get_anti_magic_field_effect_turfs(list/targets, mob/user)
	var/list/effect_turfs = ..()
	if(length(targets))
		var/turf/center = get_turf(targets[1])
		if(center)
			for(var/turf/affected_turf as anything in RANGE_TURFS(1, center))
				if(!(affected_turf in effect_turfs))
					effect_turfs += affected_turf
	return effect_turfs

/obj/effect/proc_holder/spell/invoked/forcewall/get_anti_magic_field_effect_turfs(list/targets, mob/user)
	var/list/effect_turfs = ..()
	if(length(targets))
		var/turf/front = get_turf(targets[1])
		if(front)
			effect_turfs += front
			if(user.dir == SOUTH || user.dir == NORTH)
				effect_turfs += get_step(front, WEST)
				effect_turfs += get_step(front, EAST)
			else
				effect_turfs += get_step(front, NORTH)
				effect_turfs += get_step(front, SOUTH)
	return effect_turfs

/obj/effect/proc_holder/spell/invoked/forcewall/greater/get_anti_magic_field_effect_turfs(list/targets, mob/user)
	var/list/effect_turfs = ..()
	if(length(targets))
		var/turf/front = get_turf(targets[1])
		if(front)
			effect_turfs += front
			var/side_a
			var/side_b
			if(user.dir == SOUTH || user.dir == NORTH)
				side_a = WEST
				side_b = EAST
			else
				side_a = NORTH
				side_b = SOUTH
			effect_turfs += get_step(front, side_a)
			effect_turfs += get_step(front, side_b)
			effect_turfs += get_step(get_step(front, side_a), side_a)
			effect_turfs += get_step(get_step(front, side_b), side_b)
	return effect_turfs

/obj/effect/proc_holder/spell/invoked/forcewall/arcyne_prison/get_anti_magic_field_effect_turfs(list/targets, mob/user)
	// Bypass the ordinary 3-tile Forcewall footprint: Arcyne Prison creates only its outer ring.
	var/list/effect_turfs = list()
	if(length(targets))
		var/turf/selected_turf = get_turf(targets[1])
		if(selected_turf)
			effect_turfs += selected_turf
	if(length(targets))
		var/turf/center = get_turf(targets[1])
		if(center)
			for(var/turf/affected_turf as anything in view(2, center))
				if(get_dist(center, affected_turf) != 2 || !(affected_turf in view(center)))
					continue
				if(!(affected_turf in effect_turfs))
					effect_turfs += affected_turf
	return effect_turfs


/obj/effect/proc_holder/spell/invoked/projectile/fireball/get_anti_magic_field_effect_turfs(list/targets, mob/user)
	var/list/effect_turfs = ..()
	if(length(targets))
		var/turf/center = get_turf(targets[1])
		if(center)
			for(var/turf/affected_turf as anything in RANGE_TURFS(1, center))
				if(!(affected_turf in effect_turfs))
					effect_turfs += affected_turf
	return effect_turfs

/obj/effect/proc_holder/spell/invoked/projectile/fireball/greater/get_anti_magic_field_effect_turfs(list/targets, mob/user)
	var/list/effect_turfs = ..()
	if(length(targets))
		var/turf/center = get_turf(targets[1])
		if(center)
			for(var/turf/affected_turf as anything in RANGE_TURFS(2, center))
				if(!(affected_turf in effect_turfs))
					effect_turfs += affected_turf
	return effect_turfs

/obj/effect/proc_holder/spell/invoked/projectile/acidsplash/get_anti_magic_field_effect_turfs(list/targets, mob/user)
	var/list/effect_turfs = ..()
	if(length(targets))
		var/turf/center = get_turf(targets[1])
		if(center)
			for(var/turf/affected_turf as anything in RANGE_TURFS(1, center))
				if(!(affected_turf in effect_turfs))
					effect_turfs += affected_turf
	return effect_turfs

