
/obj/structure/flora/shroom_tree/happy
	name = "underdark mushroom"
	icon_state = "happymush1"
	icon = 'modular_rmh/icons/obj/structures/foliagetall.dmi'
	desc = "Mushrooms might be the happiest beings in this god forsaken place."

/obj/structure/flora/shroom_tree/happy/mushroom2
	icon_state = "happymush2"

/obj/structure/flora/shroom_tree/happy/mushroom3
	icon_state = "happymush3"

/obj/structure/flora/shroom_tree/happy/mushroom4
	icon_state = "happymush4"

/obj/structure/flora/shroom_tree/happy/mushroom5
	icon_state = "happymush5"

/obj/structure/flora/shroom_tree/happy/random

/obj/structure/flora/shroom_tree/happy/random/Initialize()
	. = ..()
	icon_state = "happymush[rand(1,5)]"

/obj/structure/flora/shroom_tree/happy/New(loc)
	..()
	set_light(3, 3, 3, l_color ="#5D3FD3")

//bushes
/obj/structure/flora/bush
	name = "bush"
	desc = ""
	icon = 'icons/obj/flora/snowflora.dmi'
	icon_state = "snowbush1"
	anchored = TRUE

/obj/structure/flora/bush/Initialize()
	icon_state = "snowbush[rand(1, 6)]"
	. = ..()
