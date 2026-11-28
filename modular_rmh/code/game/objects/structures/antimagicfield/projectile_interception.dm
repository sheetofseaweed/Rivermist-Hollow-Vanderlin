/**
 * Anti-magic attribution is stored on the common projectile base so legacy
 * spell families that fire /obj/projectile/energy as well as /obj/projectile/magic
 * receive the same interception policy. Only tagged spell projectiles are
 * handled here; ordinary arrows and bullets remain untouched.
 */
/obj/projectile
	var/anti_magic_action_id
	var/anti_magic_origin_x
	var/anti_magic_origin_y
	var/anti_magic_origin_z
	var/tmp/anti_magic_interception_pending = FALSE

/obj/projectile/Moved(atom/OldLoc, Dir)
	if(QDELETED(src) || QDELING(src) || anti_magic_interception_pending)
		return

	if(fired)
		// Modern datum/action spells can stamp their context automatically when
		// their projectile moves synchronously during Activate()/cast().
		if(!anti_magic_action_id && istype(firer, /mob/living))
			var/mob/living/living_firer = firer
			var/datum/action/cooldown/spell/active_spell = living_firer.anti_magic_active_spell
			if(active_spell)
				active_spell.apply_anti_magic_projectile_metadata(src)

		var/action_id = anti_magic_action_id
		// Unattributed magical projectiles remain conservative: identify them by
		// projectile type, which is not on the allowlist by default.
		if(!action_id && istype(src, /obj/projectile/magic))
			action_id = "[type]"

		if(action_id)
			var/turf/current_turf = get_turf(src)
			// Only legacy fallback. The shared spell launchers stamp the caster
			// origin before fire(), so OldLoc must not replace a known snapshot.
			if(isnull(anti_magic_origin_x) || isnull(anti_magic_origin_y) || isnull(anti_magic_origin_z))
				var/turf/launch_turf = get_turf(firer)
				if(launch_turf)
					anti_magic_origin_x = launch_turf.x
					anti_magic_origin_y = launch_turf.y
					anti_magic_origin_z = launch_turf.z

			var/turf/origin_turf
			if(!isnull(anti_magic_origin_x) && !isnull(anti_magic_origin_y) && !isnull(anti_magic_origin_z))
				origin_turf = locate(anti_magic_origin_x, anti_magic_origin_y, anti_magic_origin_z)

			var/list/effect_turfs = list()
			if(current_turf)
				effect_turfs += current_turf
			if(GLOB.anti_magic_field_manager.is_action_blocked_on_turfs(origin_turf, action_id, effect_turfs))
				anti_magic_interception_pending = TRUE
				if(ismob(firer))
					GLOB.anti_magic_field_manager.notify_blocked(firer)
				visible_message(span_warning("[src] fizzles and is destroyed as it enters an anti-magic field!"))
				// Never synchronously qdel from our own Moved() stack. The one-shot
				// guard also prevents another movement callback from queuing deletion.
				QDEL_IN(src, 0)
				return

	. = ..()

/mob/living
	/// Spell action currently executing; shared modern projectile launchers copy its metadata.
	var/tmp/datum/action/cooldown/spell/anti_magic_active_spell
