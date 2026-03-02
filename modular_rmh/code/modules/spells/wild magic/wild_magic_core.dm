

/datum/element/wild_magic
	element_flags = ELEMENT_DETACH
	var/processing = FALSE

/datum/element/wild_magic/Attach(datum/target)
	. = ..()
	if(!ismob(target))
		return ELEMENT_INCOMPATIBLE

	RegisterSignal(target, COMSIG_MOB_AFTER_SPELL_CAST, PROC_REF(OnSpellCast))
	return

/datum/element/wild_magic/Detach(datum/source)
	UnregisterSignal(source, COMSIG_MOB_AFTER_SPELL_CAST)
	return ..()

/datum/element/wild_magic/proc/OnSpellCast(mob/living/caster, datum/action/cooldown/spell/spell, atom/target)
	if(processing)
		return
	if(!caster || QDELETED(caster))
		return

	if(!prob(WILD_CHANCE))
		return

	processing = TRUE
	DoWildSurge(caster, target)
	addtimer(VARSET_CALLBACK(src, processing, FALSE), WILD_CD)

/datum/element/wild_magic/proc/DoWildSurge(mob/living/caster, atom/original_target)
	if(!length(GLOB.wild_surge_table))
		return

	var/datum/wild_surge_entry/E = pick(GLOB.wild_surge_table)

	var/mob/living/random_living = null
	for(var/mob/living/M in view(7, caster))
		if(M != caster)
			random_living = M
			break

	RunSurgeEntry(E, caster, original_target, random_living)

/datum/element/wild_magic/proc/RunSurgeEntry(
	datum/wild_surge_entry/E,
	mob/living/caster,
	atom/real_target,
	mob/living/random_target
)
	if(E.message)
		var/msg = replacetext(E.message, "\[WILD_CASTER\]", "[caster]")
		caster.visible_message(msg)

	// PROC based surge
	if(E.progname)
		if(hascall(src, E.progname))
			call(src, E.progname)(caster, real_target)
		return

	// SPELL based surge
	if(E.spell_type)
		CastSurgeSpell(E, caster, ResolveTarget(E, caster, real_target, random_target))

/datum/element/wild_magic/proc/ResolveTarget(
	datum/wild_surge_entry/E,
	mob/living/caster,
	atom/real_target,
	mob/living/random_target
)
	switch(E.target_mode)
		if(WILD_TARGET_SELF)
			return caster

		if(WILD_TARGET_RANDOM_LIVING)
			return random_target ? random_target : caster

		if(WILD_TARGET_CAST_ON)
			return real_target ? real_target : caster

		if(WILD_TARGET_TURF_OF_CAST_ON)
			return real_target ? get_turf(real_target) : get_turf(caster)

		if(WILD_TARGET_TURF_OF_CASTER)
			return get_turf(caster)

	return caster

/datum/element/wild_magic/proc/CastSurgeSpell(
	datum/wild_surge_entry/E,
	mob/living/caster,
	atom/target
)
	if(!caster || QDELETED(caster))
		return

	if(!target)
		target = caster

	var/datum/action/cooldown/spell/S = new E.spell_type

	S.owner = caster
	S.cast(target)

#undef WILD_CHANCE
#undef WILD_CD

#undef WILD_TARGET_SELF
#undef WILD_TARGET_RANDOM_LIVING
#undef WILD_TARGET_CAST_ON
#undef WILD_TARGET_TURF_OF_CAST_ON
#undef WILD_TARGET_TURF_OF_CASTER