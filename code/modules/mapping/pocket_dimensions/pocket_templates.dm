/datum/map_template/pocket/test_chamber
	name = "Pocket Test Chamber"
	id = "pocket_test_chamber"
	mappath = "_maps/templates/pockets/pocket_test_chamber.dmm"

/datum/map_template/pocket/bag_of_holding
	name = "Bag of Holding Cache"
	id = "pocket_bag_of_holding"
	mappath = "_maps/templates/pockets/pocket_bag_of_holding.dmm"
	lifecycle_policy = POCKET_LIFECYCLE_HIBERNATE
	idle_timeout = 2 MINUTES
	persistence_mode = POCKET_PERSISTENCE_MOVABLES

/datum/map_template/pocket/magic_closet
	name = "Magic Closet Interior"
	id = "pocket_magic_closet"
	mappath = "_maps/templates/pockets/pocket_magic_closet.dmm"
	lifecycle_policy = POCKET_LIFECYCLE_HIBERNATE
	idle_timeout = 2 MINUTES
	persistence_mode = POCKET_PERSISTENCE_MOVABLES
	exit_structure_type = /obj/structure/pocket_dimension_exit/closet

/datum/map_template/pocket/magic_closet/dungeon
	name = "Dungeon Closet Interior"
	id = "pocket_magic_closet_dungeon"
	mappath = "_maps/templates/pockets/intimate_dungeon.dmm"
	lifecycle_policy = POCKET_LIFECYCLE_KEEP_LOADED
	persistence_mode = POCKET_PERSISTENCE_MOVABLES
	exit_structure_type = /obj/structure/pocket_dimension_exit/closet

/datum/map_template/pocket/lighting_test
	name = "Pocket Lighting Test"
	id = "pocket_lighting_test"
	mappath = "_maps/templates/pockets/pocket_lighting_test.dmm"

/datum/map_template/pocket/camp_tent
	name = "Tent Interior"
	id = "pocket_camp_tent"
	mappath = "_maps/templates/pockets/pocket_camp_tent.dmm"
	lifecycle_policy = POCKET_LIFECYCLE_HIBERNATE
	idle_timeout = 5 MINUTES
	persistence_mode = POCKET_PERSISTENCE_MOVABLES
	exit_structure_type = /obj/structure/pocket_dimension_exit/camp_shelter

/datum/map_template/pocket/camp_yurt
	name = "Yurt Interior"
	id = "pocket_camp_yurt"
	mappath = "_maps/templates/pockets/pocket_camp_yurt.dmm"
	lifecycle_policy = POCKET_LIFECYCLE_HIBERNATE
	idle_timeout = 5 MINUTES
	persistence_mode = POCKET_PERSISTENCE_MOVABLES
	exit_structure_type = /obj/structure/pocket_dimension_exit/camp_shelter

/datum/map_template/pocket/camp_pavilion
	name = "Pavilion Interior"
	id = "pocket_camp_pavilion"
	mappath = "_maps/templates/pockets/pocket_camp_pavilion.dmm"
	lifecycle_policy = POCKET_LIFECYCLE_HIBERNATE
	idle_timeout = 5 MINUTES
	persistence_mode = POCKET_PERSISTENCE_MOVABLES
	exit_structure_type = /obj/structure/pocket_dimension_exit/camp_shelter
