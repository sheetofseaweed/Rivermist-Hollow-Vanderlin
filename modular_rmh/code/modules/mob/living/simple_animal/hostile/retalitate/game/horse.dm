/mob/living/simple_animal/hostile/retaliate/saiga/horse
	icon = 'modular_rmh/icons/mob/monster/horse.dmi'
	name = "horse"
	desc = "Proud beasts of burden, war mounts, and symbols of luxury alike."
	icon_state = ""
	icon_living = ""
	icon_dead = ""
	gender = "female"
	SET_BASE_PIXEL(-8, 0)

/mob/living/simple_animal/hostile/retaliate/saiga/horse/Initialize()
	. = ..()
	var/horsecolor = pick("horsewhite","horseblack","horsebrown")
	icon_state = "[horsecolor]"
	icon_living = "[horsecolor]"
	icon_dead = "[horsecolor]_dead"

/mob/living/simple_animal/hostile/retaliate/saiga/horse/update_overlays()
	. = ..()
	if(stat == DEAD)
		return
	if(ssaddle)
		var/mutable_appearance/saddlet = mutable_appearance(icon, "saddle-above", 4.3)
		. += saddlet
		saddlet = mutable_appearance(icon, "saddle")
		. += saddlet
	if(has_buckled_mobs())
		var/mutable_appearance/mounted = mutable_appearance(icon, "[icon_state]_mounted", 4.3)
		. += mounted

/mob/living/simple_animal/hostile/retaliate/saiga/horse/tamed(mob/user)
	. = ..()
	deaggroprob = 30
	if(can_buckle)
		AddComponent(/datum/component/riding/saiga)
	if(can_breed)
		AddComponent(\
			/datum/component/breed,\
			list(/mob/living/simple_animal/hostile/retaliate/saiga/horse, /mob/living/simple_animal/hostile/retaliate/saiga/horse/male),\
			3 MINUTES, \
			list(/mob/living/simple_animal/hostile/retaliate/saiga/horse/kid = 90, /mob/living/simple_animal/hostile/retaliate/saiga/horse/kid/boy = 10),\
			CALLBACK(src, PROC_REF(after_birth)),\
		)

///
/mob/living/simple_animal/hostile/retaliate/saiga/horse/kid
	icon = 'modular_rmh/icons/mob/monster/horse.dmi'
	name = "foal"
	icon_state = ""
	icon_living = ""
	icon_dead = ""
	icon_gib = "skele"
	gender = "female"

/mob/living/simple_animal/hostile/retaliate/saiga/horse/kid/Initialize()
	. = ..()
	var/foalcolor = pick("foalwhite","foalblack","foalbrown")
	icon_state = "[foalcolor]"
	icon_living = "[foalcolor]"
	icon_dead = "[foalcolor]_dead"

///
/mob/living/simple_animal/hostile/retaliate/saiga/horse/male // Делим на два пола, чтобы работал horse/tamed(mob/user)
	gender = "male"

/mob/living/simple_animal/hostile/retaliate/saiga/horse/kid/boy // Делим на два пола, чтобы ничего не сломалось, на всякий случай.
	gender = "male"

///
/mob/living/simple_animal/hostile/retaliate/saiga/horse/tame
	tame = TRUE

/mob/living/simple_animal/hostile/retaliate/saiga/horse/male/tame
	tame = TRUE

/mob/living/simple_animal/hostile/retaliate/saiga/horse/tame/saddled/Initialize()
	. = ..()
	var/obj/item/natural/saddle/S = new(src)
	ssaddle = S
	update_appearance(UPDATE_OVERLAYS)

/mob/living/simple_animal/hostile/retaliate/saiga/horse/male/tame/saddled/Initialize()
	. = ..()
	var/obj/item/natural/saddle/S = new(src)
	ssaddle = S
	update_appearance(UPDATE_OVERLAYS)
