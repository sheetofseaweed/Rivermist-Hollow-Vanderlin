/// Corpse spawners trigger without player interaction and create an already-dead mob.
/obj/effect/mob_spawn/corpse
	abstract_type = /obj/effect/mob_spawn/corpse
	density = FALSE
	/// When this spawner should create its corpse.
	var/spawn_when = CORPSE_INSTANT
	var/brute_damage = 0
	var/oxy_damage = 0
	var/burn_damage = 0

/obj/effect/mob_spawn/corpse/Initialize(mapload, preview_only = FALSE)
	. = ..()
	if(preview_only)
		return

	switch(spawn_when)
		if(CORPSE_INSTANT)
			INVOKE_ASYNC(src, PROC_REF(create))
		if(CORPSE_ROUNDSTART)
			if(SSticker.current_state < GAME_STATE_PLAYING)
				SSticker.OnRoundstart(CALLBACK(src, PROC_REF(create)))
			else
				INVOKE_ASYNC(src, PROC_REF(create))

/obj/effect/mob_spawn/corpse/special(mob/living/spawned_mob, mob/mob_possessor, apply_prefs, preview_only = FALSE)
	. = ..()
	if(preview_only)
		return

	ADD_TRAIT(spawned_mob, TRAIT_NO_ROT, INNATE_TRAIT)
	spawned_mob.death(TRUE)
	spawned_mob.adjustOxyLoss(oxy_damage, updating_health = FALSE)
	spawned_mob.adjustBruteLoss(brute_damage, updating_health = FALSE, damage_type = pick(BCLASS_BITE, BCLASS_BLUNT, BCLASS_LASHING, BCLASS_CUT))
	spawned_mob.adjustFireLoss(burn_damage, updating_health = FALSE)

/obj/effect/mob_spawn/corpse/create(mob/mob_possessor, newname, apply_prefs)
	. = ..()
	qdel(src)
