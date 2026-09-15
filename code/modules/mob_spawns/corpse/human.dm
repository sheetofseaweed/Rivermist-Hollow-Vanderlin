/obj/effect/mob_spawn/corpse/human
	name = "human corpse spawner"
	mob_type = /mob/living/carbon/human
	mob_species = /datum/species/human/northern

CREATE_ALL_SPECIES_SPAWNERS(/obj/effect/mob_spawn/corpse/human)

/obj/effect/mob_spawn/corpse/human/damaged
	brute_damage = 150

CREATE_ALL_SPECIES_SPAWNERS(/obj/effect/mob_spawn/corpse/human/damaged)

/obj/effect/mob_spawn/corpse/human/random
	name = "randomized species corpse spawner"

/obj/effect/mob_spawn/corpse/human/random/special(mob/living/spawned_mob, mob/mob_possessor, apply_prefs, preview_only = FALSE)
	if(LAZYLEN(GLOB.roundstart_species))
		mob_species = GLOB.species_list[pick(GLOB.roundstart_species)]
	return ..()

/obj/effect/mob_spawn/corpse/human/random/damaged
	brute_damage = 150
