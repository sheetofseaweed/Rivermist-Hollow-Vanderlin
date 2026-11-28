/**
 * Admin-only, client-side view of the exact turfs currently returned by
 * field.covers_turf(). This intentionally visualizes active coverage only.
 * It does not draw the configured bounding box when a turf is not actually
 * covered, which keeps the view aligned with the permission manager.
 */
/client
	var/tmp/anti_magic_field_debug_enabled = FALSE
	var/tmp/list/anti_magic_field_debug_images

/client/verb/toggle_anti_magic_field_debug()
	set name = "Toggle Anti-Magic Field Coverage"
	set category = "Debug"
	if(!check_rights(R_ADMIN))
		return

	anti_magic_field_debug_enabled = !anti_magic_field_debug_enabled
	if(!anti_magic_field_debug_enabled)
		clear_anti_magic_field_debug()
		to_chat(src, span_notice("Anti-magic field coverage visualization disabled."))
		return

	refresh_anti_magic_field_debug()
	to_chat(src, span_notice("Anti-magic field coverage visualization enabled. Blue = stationary, cyan = throwable, orange = overlap."))

/client/proc/clear_anti_magic_field_debug()
	if(islist(anti_magic_field_debug_images) && length(anti_magic_field_debug_images))
		images -= anti_magic_field_debug_images
	anti_magic_field_debug_images = null

/client/proc/refresh_anti_magic_field_debug()
	if(!anti_magic_field_debug_enabled || !src)
		return

	// Called on demand and when the manager's active registry changes.
	// Never run this from a subsystem process tick.
	clear_anti_magic_field_debug()
	anti_magic_field_debug_images = list()

	// Assoc turf => bit flags and number of active fields covering that turf.
	var/list/coverage_flags = list()
	var/list/coverage_counts = list()
	for(var/obj/structure/anti_magic_field/field as anything in GLOB.anti_magic_field_manager.active_fields)
		if(QDELETED(field) || !field.is_active)
			continue
		var/turf/anchor = get_turf(field)
		if(!anchor)
			continue

		var/min_z = max(1, anchor.z - field.field_z_coverage)
		var/max_z = min(world.maxz, anchor.z + field.field_z_coverage)
		var/min_x = anchor.x - round(field.field_width / 2)
		var/min_y = anchor.y - round(field.field_height / 2)
		for(var/z_level in min_z to max_z)
			for(var/x_coord in min_x to (min_x + field.field_width - 1))
				for(var/y_coord in min_y to (min_y + field.field_height - 1))
					var/turf/coverage_turf = locate(x_coord, y_coord, z_level)
					if(!coverage_turf || !field.covers_turf(coverage_turf))
						continue

					var/flags = coverage_flags[coverage_turf]
					if(isnull(flags))
						flags = 0
					var/field_count = coverage_counts[coverage_turf]
					if(isnull(field_count))
						field_count = 0
					field_count++
					coverage_counts[coverage_turf] = field_count
					if(istype(field, /obj/structure/anti_magic_field/stationary))
						flags |= 1
					else if(istype(field, /obj/structure/anti_magic_field/throwable))
						flags |= 2
					coverage_flags[coverage_turf] = flags

	for(var/turf/coverage_turf as anything in coverage_flags)
		var/flags = coverage_flags[coverage_turf]
		var/tile_color
		if(coverage_counts[coverage_turf] > 1 || (flags & 3) == 3)
			tile_color = "#FF9F0A" // Any overlap.
		else if(flags & 1)
			tile_color = "#3478F6" // Stationary.
		else
			tile_color = "#30D5C8" // Throwable.

		// alphacolors.dmi's white tile is tinted and alpha-blended per client.
		var/image/coverage_image = image('icons/effects/alphacolors.dmi', coverage_turf, "white")
		coverage_image.color = tile_color
		coverage_image.alpha = 105
		coverage_image.plane = coverage_turf.plane
		coverage_image.layer = coverage_turf.layer + 0.01
		images += coverage_image
		anti_magic_field_debug_images += coverage_image
