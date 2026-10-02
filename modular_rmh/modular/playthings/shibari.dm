// Shibari ropes: a decorative rope harness in the bra slot. It frames the body and hides nothing.

/obj/item/clothing/bra/shibari
	name = "shibari ropes"
	desc = "Thin silk ropes wound decoratively across the body's more immodest points."
	icon = 'modular_rmh/icons/obj/lewd/playthings.dmi'
	mob_overlay_icon = 'modular_rmh/icons/clothing/underwear/onmob/shibari.dmi'
	icon_state = "shibari"
	item_state = "shibari"
	gendered = TRUE
	flags_inv = NONE
	salvage_result = /obj/item/natural/fibers
	sellprice = 6

/datum/repeatable_crafting_recipe/crafting/shibari
	name = "shibari ropes"
	output = /obj/item/clothing/bra/shibari
	requirements = list(/obj/item/rope = 1, /obj/item/natural/fibers = 2)
	starting_atom = /obj/item/natural/fibers
	attacked_atom = /obj/item/rope
	category = "Lewd"
	craftdiff = 1

/datum/repeatable_crafting_recipe/crafting/shibari/create_blacklisted_paths()
	blacklisted_paths = subtypesof(/obj/item/rope)
