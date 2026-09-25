/obj/effect/landmark/mapGenerator/rmh_town
	mapGeneratorType = /datum/mapGenerator/rmh_town
	endTurfX = 255
	endTurfY = 255
	startTurfX = 1
	startTurfY = 1

/datum/mapGenerator/rmh_town
	modules = list(
		/datum/mapGeneratorModule/rmh_town/leafs
		)

/datum/mapGeneratorModule/rmh_town/leafs
	clusterCheckFlags = CLUSTER_CHECK_NONE
	allowed_turfs = list(/turf/open)
	excluded_turfs = list(/turf/open/openspace)
	spawnableAtoms = list(/obj/effect/decal/cleanable/dirt/leafs = 10)
	spawnableTurfs = list()
	allowed_areas = list(/area/outdoors/town/rmh, /area/outdoors/town/rmh/livingquart, /area/outdoors/exposed/town/rmh/farm)
	include_subtypes = FALSE
