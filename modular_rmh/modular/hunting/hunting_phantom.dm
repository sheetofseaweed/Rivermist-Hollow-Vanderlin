// Hunting & Tracking pack - the shape in the brush at the end of a trail.
//
// The timer is only a ceiling: the shape darkens in place and turns into the real animal as soon
// as a player actually lays eyes on it or walks up on it, so the hunter gets the moment of
// spotting their kill rather than watching a countdown.

/// How close a watcher has to be for the quarry to break cover.
#define PHANTOM_TRIGGER_RANGE 4
/// How often the shape checks whether anyone is looking.
#define PHANTOM_WATCH_INTERVAL (1 SECONDS)

/obj/effect/temp_visual/hunting_phantom
	name = "approaching quarry"
	desc = "Something is moving in the brush..."
	icon_state = ""
	layer = MOB_LAYER
	plane = GAME_PLANE
	alpha = 50
	anchored = TRUE
	duration = 30 SECONDS
	mouse_opacity = MOUSE_OPACITY_ICON
	var/mob_type_to_spawn
	/// Ceiling: the quarry breaks cover on its own after this even if nobody comes close.
	var/spawn_delay = 15 SECONDS
	/// Guards against the watch timer and the ceiling timer both firing.
	var/spawned = FALSE
	var/watch_timer

/obj/effect/temp_visual/hunting_phantom/Initialize(mapload, target_mob_path, custom_delay)
	. = ..()
	if(!ispath(target_mob_path, /mob/living))
		return INITIALIZE_HINT_QDEL
	if(custom_delay)
		spawn_delay = custom_delay

	mob_type_to_spawn = target_mob_path
	var/mob/living/path_cast = target_mob_path
	icon = initial(path_cast.icon)
	icon_state = initial(path_cast.icon_state)
	pixel_x = initial(path_cast.pixel_x)
	pixel_y = initial(path_cast.pixel_y)
	color = "#777777"

	animate(src, alpha = 200, time = spawn_delay, easing = EASE_IN)
	addtimer(CALLBACK(src, PROC_REF(finalize_spawn)), spawn_delay)
	check_for_watcher()

/obj/effect/temp_visual/hunting_phantom/Destroy()
	if(watch_timer)
		deltimer(watch_timer)
		watch_timer = null
	return ..()

/// Breaks cover the moment a player can see the shape from close by.
/obj/effect/temp_visual/hunting_phantom/proc/check_for_watcher()
	watch_timer = null
	if(spawned)
		return
	for(var/mob/living/watcher in viewers(PHANTOM_TRIGGER_RANGE, src))
		if(!watcher.client || watcher.eyesclosed || watcher.stat == DEAD)
			continue
		finalize_spawn()
		return
	watch_timer = addtimer(CALLBACK(src, PROC_REF(check_for_watcher)), PHANTOM_WATCH_INTERVAL, TIMER_STOPPABLE)

/obj/effect/temp_visual/hunting_phantom/proc/finalize_spawn()
	if(spawned)
		return
	spawned = TRUE
	var/turf/spawn_turf = get_turf(src)
	if(spawn_turf)
		// Spawned with its own type's default faction on purpose: tagging it with an extra
		// faction string would change how it reads other mobs, and nothing here reads the tag.
		var/mob/living/real_mob = new mob_type_to_spawn(spawn_turf)
		spawn_turf.visible_message(span_boldwarning("[real_mob] breaks from the brush!"))
	qdel(src)

#undef PHANTOM_TRIGGER_RANGE
#undef PHANTOM_WATCH_INTERVAL
