/turf/open/floor/AzureSand
	name = "sand"
	icon = 'modular_rmh/icons/turf/roguefloor.dmi'
	desc = "Warm sand that, sadly, have been mixed with dirt."
	icon_state = "grimshart"
	layer = MID_TURF_LAYER
	footstep = FOOTSTEP_SAND
	barefootstep = FOOTSTEP_SOFT_BAREFOOT
	heavyfootstep = FOOTSTEP_GENERIC_HEAVY
	//tiled_dirt = FALSE
	landsound = 'sound/foley/jumpland/grassland.wav'
	slowdown = 0
	neighborlay = "grimshartedge"
	smoothing_flags = SMOOTH_EDGE
	smoothing_groups = SMOOTH_GROUP_OPEN_FLOOR
	smoothing_list = SMOOTH_GROUP_FLOOR_DIRT_ROAD + SMOOTH_GROUP_FLOOR_GRASS

/turf/open/floor/AzureSand/Initialize()
	dir = pick(GLOB.cardinals)
	. = ..()

/obj/effect/decal/mossy
	name = "mossy brick floor"
	desc = "dirt and moss have crept between the gaps of this stone-brick flooring."
	icon = 'modular_rmh/icons/turf/roguefloor.dmi'
	icon_state = "mossyedge"
	mouse_opacity = 0

/obj/effect/decal/cobble/mossy
	name = "mossy brick floor"
	desc = "Dirt and moss have crept between the gaps of this stone-brick flooring. Rather fitting for an outdoor garden; not so much for a home."
	icon = 'modular_rmh/icons/turf/roguefloor.dmi'
	icon_state = "mossystone_edges"
	mouse_opacity = 0

/obj/effect/decal/edge
	name = "stone edge"
	desc = "A piece of stone used to border city roads."
	icon = 'modular_rmh/icons/turf/roguefloor.dmi'
	icon_state = "border"
	mouse_opacity = 0

/obj/effect/decal/edge_corner
	name = "stone edge corner"
	desc = "A piece of stone used to border city roads."
	icon = 'modular_rmh/icons/turf/roguefloor.dmi'
	icon_state = "border_corner"
	mouse_opacity = 0

/turf/open/floor/tile/harem
	icon = 'modular_rmh/icons/turf/roguefloor.dmi'
	icon_state = "harem"

/turf/open/floor/tile/harem1
	icon = 'modular_rmh/icons/turf/roguefloor.dmi'
	icon_state = "harem1"

/turf/open/floor/tile/harem2
	icon = 'modular_rmh/icons/turf/roguefloor.dmi'
	icon_state = "harem2"

/turf/open/floor/carpet/inn
	icon = 'modular_rmh/icons/turf/inn.dmi'

/turf/open/floor/tile/harem
	icon = 'modular_rmh/icons/turf/roguefloor.dmi'
	icon_state = "harem"

/turf/open/floor/tile/harem1
	icon = 'modular_rmh/icons/turf/roguefloor.dmi'
	icon_state = "harem1"

/turf/open/floor/tile/harem2
	icon = 'modular_rmh/icons/turf/roguefloor.dmi'
	icon_state = "harem2"
