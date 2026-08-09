/datum/supply_pack/livestock/terrorbird
	name = "Terrorbird"
	cost = 160
	contains = list(
					/mob/living/simple_animal/hostile/retaliate/saiga/terrorbird/tame/saddled,
				)

/datum/stock/import/terrorbird
	name = "Terrorbird"
	desc = "One tamed terrorbird with a saddle. Feed it meat, and keep your fingers behind the reins."
	item_type = /obj/structure/closet/crate/chest/steward/terrorbird
	export_price = 300
	importexport_amt = 1

/obj/structure/closet/crate/chest/steward/terrorbird/populate_contents()
	new /mob/living/simple_animal/hostile/retaliate/saiga/terrorbird/tame/saddled(src)
