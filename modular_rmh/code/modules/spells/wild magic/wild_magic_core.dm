#define WILD_CHANCE 99
#define WILD_CD 1.5 SECONDS

#define SHAPE_CD 10 SECONDS
#define MUTE 60 SECONDS

/datum/element/wild_magic
	element_flags = ELEMENT_DETACH

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
	if(!caster || QDELETED(caster))
		return
	if(HAS_TRAIT(caster, TRAIT_WILDMAGIC))
		return
	if(!prob(WILD_CHANCE))
		return

	ADD_TRAIT(caster, TRAIT_WILDMAGIC, "wild_magic")
	addtimer(CALLBACK(src, PROC_REF(RemoveWildMagicCD), caster),WILD_CD)
	to_chat(caster, span_danger("⚡ Your wild magic surges uncontrollably! ⚡"))

	DoWildSurge(caster, spell, target)

/datum/element/wild_magic/proc/DoWildSurge(mob/living/caster, datum/action/cooldown/spell/spell, atom/target)
	if(!length(GLOB.wild_surge_table))
		return

	var/list/nearby = list()
	for(var/mob/living/L in view(7, caster))
		if(L.stat != DEAD && L != caster)
			nearby += L

	var/mob/living/random_target = length(nearby) ? pick(nearby) : caster

	caster.visible_message(span_danger("<span style='font-size:150%'>[caster]'s magic spirals out of control!</span>"))
/*
	var/datum/wild_surge_entry/E = pick(GLOB.wild_surge_table)
	RunSurgeEntry(E, caster, target, random_target)
*/
	for(var/datum/wild_surge_entry/E in GLOB.wild_surge_table)
		RunSurgeEntry(E, caster, target, random_target)

/datum/element/wild_magic/proc/RunSurgeEntry(datum/wild_surge_entry/E, mob/living/caster, atom/cast_on, mob/living/random_target)
	if(!E || !caster || QDELETED(caster))
		return

	if(E.message)
		var/msg = replacetext(E.message, "\[WILD_CASTER\]", "[caster]")
		caster.visible_message(msg)

	var/atom/real_target = ResolveSurgeTarget(E.target_mode, caster, cast_on, random_target)

	if(E.progname)
		call(src, E.progname)(caster, real_target, random_target)
		return

	if(E.spell_type)
		CastSurgeSpell(E, caster, real_target)

/datum/element/wild_magic/proc/ResolveSurgeTarget(mode, mob/living/caster, atom/cast_on, mob/living/random_target)
	switch(mode)
		if(WILD_TARGET_SELF)
			return caster
		if(WILD_TARGET_RANDOM_LIVING)
			return (random_target && !QDELETED(random_target)) ? random_target : caster
		if(WILD_TARGET_CAST_ON)
			return cast_on ? cast_on : caster
		if(WILD_TARGET_TURF_OF_CAST_ON)
			return cast_on ? get_turf(cast_on) : get_turf(caster)
		if(WILD_TARGET_TURF_OF_CASTER)
			return get_turf(caster)
	return caster

/datum/element/wild_magic/proc/CastSurgeSpell(datum/wild_surge_entry/E, mob/living/caster, atom/real_target)
	var/datum/action/cooldown/spell/S = new E.spell_type
	S.owner = caster

	if(!isnull(E.inner_tele_radius) && istype(S, /datum/action/cooldown/spell/undirected/teleport/radius_turf))
		var/datum/action/cooldown/spell/undirected/teleport/radius_turf/T = S
		T.inner_tele_radius = E.inner_tele_radius
		T.outer_tele_radius = E.outer_tele_radius

	S.cast(real_target)
	qdel(S)


// =========================
// PROC-BASED SURGES
// =========================

/datum/element/wild_magic/proc/surge_mute(mob/living/caster, atom/real_target, mob/living/random_target)
	ADD_TRAIT(caster, TRAIT_MUTE, "wild_magic")
	addtimer(CALLBACK(src, PROC_REF(RestoreMute), caster), MUTE)

/datum/element/wild_magic/proc/RestoreMute(mob/living/M)
	if(!M || QDELETED(M))
		return
	REMOVE_TRAIT(M, TRAIT_MUTE, "wild_magic")

/datum/element/wild_magic/proc/surge_mist(mob/living/caster, atom/real_target, mob/living/random_target)
	var/datum/action/cooldown/spell/undirected/shapeshift/mist/M = new
	M.owner = caster
	var/mob/living/mist = M.do_shapeshift(caster)
	if(mist)
		addtimer(CALLBACK(src, PROC_REF(RestoreShape), mist), SHAPE_CD)

/datum/element/wild_magic/proc/surge_cat(mob/living/caster, atom/real_target, mob/living/random_target)
	var/datum/action/cooldown/spell/undirected/shapeshift/cat/C = new
	C.owner = caster
	var/mob/living/cat = C.do_shapeshift(caster)
	if(cat)
		addtimer(CALLBACK(src, PROC_REF(RestoreShape), cat), SHAPE_CD)

/datum/element/wild_magic/proc/surge_crow(mob/living/caster, atom/real_target, mob/living/random_target)
	var/datum/action/cooldown/spell/undirected/shapeshift/crow/C = new
	C.owner = caster
	var/mob/living/crow = C.do_shapeshift(caster)
	if(crow)
		addtimer(CALLBACK(src, PROC_REF(RestoreShape), crow), SHAPE_CD)

/datum/element/wild_magic/proc/RestoreShape(mob/living/M)
	if(!M || QDELETED(M))
		return
	var/datum/status_effect/shapechange_mob/from_spell/S = M.has_status_effect(/datum/status_effect/shapechange_mob/from_spell)
	if(S)
		S.restore_caster()

/datum/element/wild_magic/proc/RemoveWildMagicCD(mob/living/M)
	if(!M || QDELETED(M))
		return

	REMOVE_TRAIT(M, TRAIT_WILDMAGIC, "wild_magic")

#undef WILD_CHANCE
#undef WILD_CD
#undef SHAPE_CD
#undef MUTE