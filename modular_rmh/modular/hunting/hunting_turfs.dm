// Hunting & Tracking pack - which ground holds a footprint.

/turf
	/// Chance (0-100) that a living mob leaves a footprint when stepping onto this turf.
	var/track_prob = 0

/turf/open/floor
	track_prob = 25
