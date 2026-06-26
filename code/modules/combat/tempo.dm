/mob/living/carbon/human/proc/process_tempo_attack(mob/living/attacker)
	if(!HAS_TRAIT(src, TRAIT_TEMPO))
		return
	if(!iscarbon(attacker) || attacker == src || !attacker.mind)
		return
	prune_tempo_attackers()
	if(length(tempo_attackers) < TEMPO_CAP || (REF(attacker) in tempo_attackers))
		var/newtime
		switch(length(tempo_attackers))
			if(0 to TEMPO_ONE)
				newtime = world.time + TEMPO_DELAY_ONE
			if(TEMPO_TWO)
				newtime = world.time + TEMPO_DELAY_TWO
			else
				newtime = world.time + TEMPO_DELAY_MAX
		tempo_attackers[REF(attacker)] = newtime
		next_tempo_cull = world.time + TEMPO_CULL_DELAY
	manage_tempo()

/mob/living/carbon/human/proc/manage_tempo()
	switch(length(tempo_attackers))
		if(TEMPO_MAX to INFINITY)
			apply_status_effect(/datum/status_effect/buff/tempo_three)
			remove_status_effect(/datum/status_effect/buff/tempo_two)
			remove_status_effect(/datum/status_effect/buff/tempo_one)
		if(TEMPO_TWO)
			apply_status_effect(/datum/status_effect/buff/tempo_two)
			remove_status_effect(/datum/status_effect/buff/tempo_three)
			remove_status_effect(/datum/status_effect/buff/tempo_one)
		if(TEMPO_ONE)
			apply_status_effect(/datum/status_effect/buff/tempo_one)
			remove_status_effect(/datum/status_effect/buff/tempo_three)
			remove_status_effect(/datum/status_effect/buff/tempo_two)
		else
			remove_status_effect(/datum/status_effect/buff/tempo_one)
			remove_status_effect(/datum/status_effect/buff/tempo_two)
			remove_status_effect(/datum/status_effect/buff/tempo_three)

/// Drop expired attacker entries without touching buffs; callers decide when to manage_tempo.
/mob/living/carbon/human/proc/prune_tempo_attackers()
	for(var/mob_ref in tempo_attackers)
		if(tempo_attackers[mob_ref] < world.time)
			tempo_attackers -= mob_ref

/mob/living/carbon/human/proc/cull_tempo_list()
	prune_tempo_attackers()
	manage_tempo()

/mob/living/carbon/human/proc/clear_tempo_all()
	if(length(tempo_attackers))
		tempo_attackers.Cut()
		manage_tempo()

/// Tempo bonus lookup. Returns neutral values (0, or 1 for multiplicative factors) without tempo.
/mob/living/proc/get_tempo_bonus(id)
	var/tier = 0
	if(has_status_effect(/datum/status_effect/buff/tempo_three))
		tier = 3
	else if(has_status_effect(/datum/status_effect/buff/tempo_two))
		tier = 2
	else if(has_status_effect(/datum/status_effect/buff/tempo_one))
		tier = 1
	if(!tier)
		return (id == TEMPO_TAG_ARMOR_INTEGFACTOR) ? 1 : 0
	switch(id)
		if(TEMPO_TAG_PARRYCD_BONUS)
			return tier * 2 // deciseconds off the parry cooldown
		if(TEMPO_TAG_STAMLOSS_PARRY)
			return tier
		if(TEMPO_TAG_STAMLOSS_DODGE)
			return 1 + (tier * 2)
		if(TEMPO_TAG_ARMOR_INTEGFACTOR)
			return 1 - (tier * 0.1) // 0.9 / 0.8 / 0.7
		if(TEMPO_TAG_NOLOS_PARRY, TEMPO_TAG_NOLOS_DODGE)
			return tier >= 2
		if(TEMPO_TAG_BINDABLE)
			return tier >= 1
	return 0
