/obj/structure/desertbarrier //Blocks sprite locations
	name = "Rune Barrier"
	desc = "A barrier made of runes that does not let in the living or the dead."
	icon = 'modular_rmh/icons/obj/structures/runebarrier.dmi'
	icon_state = "barrier_1"
	base_icon_state = "barrier_"
	density = TRUE
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE

/obj/structure/desertbarrier/Initialize()
	. = ..()
	icon_state = "barrier_[rand(1,3)]"
