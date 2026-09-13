GLOBAL_LIST_EMPTY(wave_defense_landmarks)

/obj/effect/landmark/wave_defense
	name = "wave defense point"
	icon_state = "x2"
	/// Waypoint set this landmark belongs to.
	var/set_id
	/// Position within its set; lower values are visited first.
	var/order = 1

/obj/effect/landmark/wave_defense/Initialize(mapload)
	. = ..()
	GLOB.wave_defense_landmarks += src

/obj/effect/landmark/wave_defense/Destroy(force, ...)
	GLOB.wave_defense_landmarks -= src
	return ..()

/proc/cmp_wave_landmark_order(obj/effect/landmark/wave_defense/first, obj/effect/landmark/wave_defense/second)
	return first.order - second.order

/proc/get_wave_defense_points(set_id)
	var/list/matching_landmarks = list()
	for(var/obj/effect/landmark/wave_defense/landmark in GLOB.wave_defense_landmarks)
		if(landmark.set_id == set_id)
			matching_landmarks += landmark

	if(!length(matching_landmarks))
		return list()

	sortTim(matching_landmarks, GLOBAL_PROC_REF(cmp_wave_landmark_order))
	var/list/turf/waypoint_turfs = list()
	for(var/obj/effect/landmark/wave_defense/landmark as anything in matching_landmarks)
		waypoint_turfs += get_turf(landmark)
	return waypoint_turfs
