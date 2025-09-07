/turf/open/floor/blocks/sandstone
	icon = 'modular_rmh/icons/turf/desert.dmi'
	icon_state = "sandstone"
	name = "sandstone blocks"
	desc = "A square made up of smaller squares."
	footstep = FOOTSTEP_STONE
	barefootstep = FOOTSTEP_HARD_BAREFOOT
	clawfootstep = FOOTSTEP_HARD_CLAW
	heavyfootstep = FOOTSTEP_GENERIC_HEAVY

/turf/open/floor/blocks/sandstone/Initialize()
	dir = pick(GLOB.cardinals)
	. = ..()

/turf/open/floor/sand/desertsand
	name = "sand"
	desc = "Hot sand."
	icon = 'modular_rmh/icons/turf/desert.dmi'
	icon_state = "sand"
	footstep = FOOTSTEP_SAND
	barefootstep = FOOTSTEP_SOFT_BAREFOOT
	heavyfootstep = FOOTSTEP_GENERIC_HEAVY
	landsound = 'sound/foley/jumpland/grassland.wav'
	slowdown = 5
	smoothing_flags = NONE

/turf/open/floor/sand/desertsand/sandbrick
	name = "sand brick"
	desc = "Brickwork made of sandstone. However, it is already practically weathered away."
	icon = 'modular_rmh/icons/turf/desert.dmi'
	icon_state = "sandbrick"
	footstep = FOOTSTEP_SAND
	barefootstep = FOOTSTEP_SOFT_BAREFOOT
	heavyfootstep = FOOTSTEP_GENERIC_HEAVY
	landsound = 'sound/foley/jumpland/grassland.wav'
	slowdown = 2

/turf/open/floor/sand/desertsand/sandpath
	name = "sand road"
	desc = "Tamped sand. Looks like a path."
	icon = 'modular_rmh/icons/turf/desert.dmi'
	icon_state = "sandpath"
	footstep = FOOTSTEP_SAND
	barefootstep = FOOTSTEP_SOFT_BAREFOOT
	heavyfootstep = FOOTSTEP_GENERIC_HEAVY
	landsound = 'sound/foley/jumpland/grassland.wav'
	slowdown = 2

/turf/open/floor/sand/desertsand/oasis
	name = "wet sand"
	desc = "Dump sand."
	icon = 'modular_rmh/icons/turf/desert.dmi'
	icon_state = "oasissand"
	footstep = FOOTSTEP_SAND
	barefootstep = FOOTSTEP_SOFT_BAREFOOT
	heavyfootstep = FOOTSTEP_GENERIC_HEAVY
	landsound = 'sound/foley/jumpland/grassland.wav'
	slowdown = 2


