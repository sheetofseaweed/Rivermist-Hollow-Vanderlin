/**
 * Shared spell-family execution adapters.
 *
 * These replacements are part of the compiled anti-magic module. They reuse
 * the exact selections prepared by get_anti_magic_effect_turfs() before
 * Activate() plays feedback or executes effects. Do not leave the old duplicate
 * target gathering implementations in the spell-family source.
 */
/datum/action/cooldown/spell/aoe/cast(atom/cast_on)
	. = ..()
	var/list/things_to_cast_on = anti_magic_prepared_aoe_targets
	if(!islist(things_to_cast_on))
		// Defensive fallback for internal casts that bypass Activate(). Validate again.
		things_to_cast_on = get_things_to_cast_on(cast_on)
		if(!islist(things_to_cast_on))
			return
		if(shuffle_targets_list)
			shuffle_inplace(things_to_cast_on)
		if(max_targets > 0 && length(things_to_cast_on) > max_targets)
			things_to_cast_on = things_to_cast_on.Copy(1, max_targets + 1)
		var/list/effect_turfs = list()
		var/turf/center_turf = get_turf(cast_on)
		if(center_turf)
			effect_turfs += center_turf
		for(var/atom/affected_atom as anything in things_to_cast_on)
			var/turf/affected_turf = get_turf(affected_atom)
			if(affected_turf && !(affected_turf in effect_turfs))
				effect_turfs += affected_turf
		var/turf/origin_turf = get_turf(owner)
		if(GLOB.anti_magic_field_manager.is_action_blocked_on_turfs(origin_turf, "[type]", effect_turfs))
			GLOB.anti_magic_field_manager.notify_blocked(owner)
			return
		anti_magic_prepared_aoe_targets = things_to_cast_on

	if(!length(things_to_cast_on))
		feedback(FALSE)
		return

	feedback(TRUE)
	SEND_SIGNAL(src, COMSIG_SPELL_AOE_ON_CAST, things_to_cast_on, cast_on)
	for(var/thing_to_target in things_to_cast_on)
		if(cast_on_thing_in_aoe(thing_to_target, cast_on))
			break

/datum/action/cooldown/spell/cone/cast(atom/cast_on)
	. = ..()
	var/list/cone_turfs = anti_magic_prepared_cone_turfs
	if(!islist(cone_turfs))
		cone_turfs = get_cone_turfs(get_turf(cast_on), cast_on.dir, cone_levels)
		var/list/effect_turfs = list()
		for(var/list/level_turfs as anything in cone_turfs)
			for(var/turf/affected_turf as anything in level_turfs)
				if(affected_turf && !(affected_turf in effect_turfs))
					effect_turfs += affected_turf
		if(GLOB.anti_magic_field_manager.is_action_blocked_on_turfs(get_turf(owner), "[type]", effect_turfs))
			GLOB.anti_magic_field_manager.notify_blocked(owner)
			return
	SEND_SIGNAL(src, COMSIG_SPELL_CONE_ON_CAST, cone_turfs, cast_on)
	make_cone(cone_turfs, cast_on)
