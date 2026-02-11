//Fix for plant loot updates
/obj/structure/flora/grass/bush/attack_hand(mob/user)
	if(!looty.len && world.time > res_replenish)
		loot_replenish()
	return ..()
/obj/structure/flora/grass/pyroclasticflowers/attack_hand(mob/user)
	if(!looty2.len && world.time > res_replenish2)
		loot_replenish2()
	return ..()

/obj/structure/flora/grass/swampweed/attack_hand(mob/user)
	if(!looty3.len && world.time > res_replenish3)
		loot_replenish3()
	return ..()

