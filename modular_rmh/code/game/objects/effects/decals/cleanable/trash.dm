/obj/effect/decal/cleanable/dirt/paper
	name = "paper"
	desc = ""
	icon = 'modular_rmh/icons/obj/items/decoration.dmi'
	icon_state = "paper"

/obj/effect/decal/cleanable/dirt/leafs
	name = "pile of leaves"
	desc = ""
	icon = 'modular_alizeria/icons/roguetown/alizeria/vladegeg_decor.dmi'
	icon_state = "leaves1"

/obj/effect/decal/cleanable/dirt/leafs/Initialize()
	icon_state = "leaves[rand(1, 10)]"
	. = ..()
