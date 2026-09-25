/turf/open/floor/maneater_stomach
	name = "stomach lining"
	desc = "Soft, ridged flesh slick with mucus. It flexes and squeezes underfoot."
	icon = 'modular_rmh/icons/turf/maneater_stomach.dmi'
	icon_state = "floor_0_0"
	baseturfs = /turf/open/floor/maneater_stomach
	heelstep = HEELSTEP_MUD
	footstep = FOOTSTEP_MUD
	barefootstep = FOOTSTEP_MUD
	heavyfootstep = FOOTSTEP_MUD
	// The claw sound list has no mud entry.
	clawfootstep = FOOTSTEP_GRASS

/turf/open/floor/maneater_stomach/Initialize(mapload)
	. = ..()
	// Nine cuts of one seamless texture; choosing by position keeps every seam matched.
	icon_state = "floor_[x % 3]_[y % 3]"

/turf/open/floor/maneater_stomach/puddle
	name = "pool of digestive nectar"
	desc = "Warm, syrupy nectar has pooled between the folds. It smells sweet and clings to skin."
	heelstep = HEELSTEP_WATER
	footstep = FOOTSTEP_WATER
	barefootstep = FOOTSTEP_WATER
	heavyfootstep = FOOTSTEP_WATER
	clawfootstep = FOOTSTEP_WATER

/turf/open/floor/maneater_stomach/puddle/Initialize(mapload)
	. = ..()
	add_overlay(mutable_appearance(icon, "puddle_[rand(1, 3)]"))

/turf/closed/indestructible/maneater_stomach
	name = "stomach wall"
	desc = "A heaving wall of wet, muscular flesh. It squeezes back when pushed."
	icon = 'modular_rmh/icons/turf/maneater_stomach_wall.dmi'
	icon_state = MAP_SWITCH("stomach_wall", "stomach_wall-0")
	// The 44px sprite spills 6px of fleshy folds over each neighbouring floor.
	transform = MAP_SWITCH(TRANSLATE_MATRIX(-6, -6), matrix())
	smoothing_flags = SMOOTH_BITMASK
	baseturfs = /turf/closed/indestructible/maneater_stomach
