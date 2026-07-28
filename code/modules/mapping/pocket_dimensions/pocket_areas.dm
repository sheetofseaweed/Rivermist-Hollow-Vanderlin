/area/pocket_dimension
	name = "Pocket Dimension"
	area_flags = NO_TELEPORT | HIDDEN_AREA
	var/datum/pocket_dimension/linked_pocket

/area/pocket_dimension/Destroy(force)
	linked_pocket = null
	return ..()

/area/pocket_dimension/test_chamber
	name = "Pocket Test Chamber"

/area/pocket_dimension/bag_of_holding
	name = "Bag of Holding Cache"

/area/pocket_dimension/magic_closet
	name = "Magic Closet Interior"

/area/pocket_dimension/lighting_test
	name = "Pocket Lighting Test"

/area/pocket_dimension/camp_tent
	name = "Tent Interior"

/area/pocket_dimension/camp_yurt
	name = "Yurt Interior"

/area/pocket_dimension/camp_pavilion
	name = "Pavilion Interior"

/turf/closed/indestructible/pocket_border
	name = "folded-space boundary"
	desc = "Looking at this is making your head hurt."
	icon_state = "shroud1"
