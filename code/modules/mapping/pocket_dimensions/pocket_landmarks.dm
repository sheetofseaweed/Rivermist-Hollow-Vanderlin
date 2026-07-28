/obj/effect/landmark/pocket_dimension
	name = "pocket dimension marker"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE

/obj/effect/landmark/pocket_dimension/entry
	name = "pocket entry marker"

/obj/effect/landmark/pocket_dimension/drop_spot
	name = "pocket drop spot marker"

/obj/effect/landmark/pocket_dimension/exit
	name = "pocket exit marker"
	var/exit_structure_type = /obj/structure/pocket_dimension_exit

/obj/effect/landmark/pocket_dimension/exit/closet
	name = "pocket closet exit marker"
	exit_structure_type = /obj/structure/pocket_dimension_exit/closet

/obj/effect/landmark/pocket_dimension/exit/werewolf
	name = "pocket closet exit marker"
	exit_structure_type = /obj/structure/pocket_dimension_exit/hole

/obj/effect/landmark/pocket_dimension/exit/camp_shelter
	name = "pocket shelter exit marker"
	exit_structure_type = /obj/structure/pocket_dimension_exit/camp_shelter

/obj/effect/abstract/pocket_dimension_storage
	invisibility = INVISIBILITY_ABSTRACT
