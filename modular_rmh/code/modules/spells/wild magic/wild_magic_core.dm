
/**
 * Wild magic support code.
 *
 * The element attaches to a caster, listens for completed spell casts,
 * rolls one surge from the wild surge table, and executes it safely.
 * The local spell subtypes below are wrappers used by surge-only casts.
 */
/datum/action/cooldown/spell/undirected/teleport/radius_turf/wild_magic
	charge_required = FALSE

/datum/action/cooldown/spell/essence/silence/wild_magic
	charge_required = FALSE

/datum/action/cooldown/spell/essence/toxic_cleanse/wild_magic
	charge_required = FALSE

/datum/element/wild_magic
	element_flags = ELEMENT_DETACH
	var/processing = FALSE
	var/static/list/forbidden_trigger_spell_types = typecacheof(list(
		/datum/action/cooldown/spell/undirected/touch/prestidigitation,
		/datum/action/cooldown/spell/undirected/learn,
		/datum/action/cooldown/spell/enrapture,
		/datum/action/cooldown/spell/forced_orgasm,
	))

/datum/element/wild_magic/Attach(datum/target)
	if(!isliving(target))
		return ELEMENT_INCOMPATIBLE
	. = ..()

	RegisterSignal(target, COMSIG_MOB_AFTER_SPELL_CAST, PROC_REF(OnSpellCast))
	return

/datum/element/wild_magic/Detach(datum/source)
	UnregisterSignal(source, COMSIG_MOB_AFTER_SPELL_CAST)
	return ..()

/datum/element/wild_magic/proc/OnSpellCast(mob/living/caster, datum/action/cooldown/spell/spell, atom/target)
	SIGNAL_HANDLER

	if(!CanTriggerWildMagic(caster, spell))
		return

	if(!prob(WILD_CHANCE))
		return

	processing = TRUE
	// Keep the spell after-cast signal path cheap and non-blocking.
	INVOKE_ASYNC(src, PROC_REF(HandleWildSurge), caster, target)
	addtimer(VARSET_CALLBACK(src, processing, FALSE), WILD_CD)

/datum/element/wild_magic/proc/CanTriggerWildMagic(mob/living/caster, datum/action/cooldown/spell/spell)
	if(processing)
		return FALSE
	if(!caster || QDELETED(caster))
		return FALSE
	if(!spell || QDELETED(spell))
		return FALSE
	if(is_type_in_typecache(spell, forbidden_trigger_spell_types))
		return FALSE
	return TRUE

/datum/element/wild_magic/proc/HandleWildSurge(mob/living/caster, atom/original_target)
	if(!caster || QDELETED(caster))
		return

	DoWildSurge(caster, original_target)

/datum/element/wild_magic/proc/DoWildSurge(mob/living/caster, atom/original_target)
	if(!length(GLOB.wild_surge_table))
		return

	var/datum/wild_surge_entry/E = pick(GLOB.wild_surge_table)
	var/mob/living/random_living = FindRandomLivingTarget(caster)

	RunSurgeEntry(E, caster, original_target, random_living)

/datum/element/wild_magic/proc/FindRandomLivingTarget(mob/living/caster)
	var/list/targets = list()

	for(var/mob/living/possible_target in view(7, caster))
		if(possible_target == caster)
			continue
		if(possible_target.stat == DEAD)
			continue
		targets += possible_target

	if(!length(targets))
		return null

	return pick(targets)

/datum/element/wild_magic/proc/RunSurgeEntry(
	datum/wild_surge_entry/E,
	mob/living/caster,
	atom/real_target,
	mob/living/random_target
)
	if(E.message)
		var/msg = replacetext(E.message, "\[WILD_CASTER\]", "[caster]")
		caster.visible_message(msg)

	if(E.effect_proc)
		RunSurgeEffect(E.effect_proc, caster, real_target, random_target)
		return

	if(E.spell_type)
		CastSurgeSpell(E, caster, real_target, random_target)

/datum/element/wild_magic/proc/RunSurgeEffect(effect_proc, mob/living/caster, atom/real_target, mob/living/random_target)
	if(!effect_proc || !hascall(src, effect_proc))
		return

	call(src, effect_proc)(caster, real_target, random_target)

/datum/element/wild_magic/proc/CastSurgeSpell(
	datum/wild_surge_entry/E,
	mob/living/caster,
	atom/real_target,
	mob/living/random_target
)
	if(!caster || QDELETED(caster) || !ispath(E.spell_type, /datum/action/cooldown/spell))
		return

	var/datum/action/cooldown/spell/surge_spell = new E.spell_type
	surge_spell.owner = caster

	PrepareSurgeSpell(E, surge_spell)

	var/atom/target = ResolveSpellTarget(E, surge_spell, caster, real_target, random_target)
	if(!target)
		return

	if(istype(surge_spell, /datum/action/cooldown/spell/undirected/teleport))
		target = get_turf(target)
		if(!target)
			return

	INVOKE_ASYNC(src, PROC_REF(PerformSurgeCast), surge_spell, target)

/datum/element/wild_magic/proc/PerformSurgeCast(datum/action/cooldown/spell/surge_spell, atom/target)
	if(!surge_spell || QDELETED(surge_spell))
		return
	if(!target || QDELETED(target))
		return

	surge_spell.cast(target)

/datum/element/wild_magic/proc/PrepareSurgeSpell(
	datum/wild_surge_entry/E,
	datum/action/cooldown/spell/surge_spell
)
	if(length(surge_spell.attunements))
		surge_spell.handle_attunements()
	else
		surge_spell.attuned_strength = 1

	if(istype(surge_spell, /datum/action/cooldown/spell/projectile))
		var/datum/action/cooldown/spell/projectile/projectile_spell = surge_spell
		projectile_spell.current_amount = max(projectile_spell.projectile_amount, 1)

	if(istype(surge_spell, /datum/action/cooldown/spell/undirected/teleport/radius_turf))
		var/datum/action/cooldown/spell/undirected/teleport/radius_turf/teleport_spell = surge_spell
		if(!isnull(E.inner_tele_radius))
			teleport_spell.inner_tele_radius = E.inner_tele_radius
		if(!isnull(E.outer_tele_radius))
			teleport_spell.outer_tele_radius = E.outer_tele_radius

/datum/element/wild_magic/proc/ResolveSpellTarget(
	datum/wild_surge_entry/E,
	datum/action/cooldown/spell/surge_spell,
	mob/living/caster,
	atom/real_target,
	mob/living/random_target
)
	var/list/candidates = BuildTargetCandidates(E, caster, real_target, random_target)

	for(var/atom/candidate as anything in candidates)
		if(IsSpellTargetSafe(surge_spell, candidate, caster))
			return candidate

	return null

/datum/element/wild_magic/proc/BuildTargetCandidates(
	datum/wild_surge_entry/E,
	mob/living/caster,
	atom/real_target,
	mob/living/random_target
)
	var/list/candidates = list()

	switch(E.target_mode)
		if(WILD_TARGET_SELF)
			AddTargetCandidate(candidates, caster)

		if(WILD_TARGET_CAST_ON)
			AddTargetCandidate(candidates, real_target)
			AddTargetCandidate(candidates, caster)

		if(WILD_TARGET_RANDOM_LIVING)
			AddTargetCandidate(candidates, random_target)
			AddTargetCandidate(candidates, real_target)
			AddTargetCandidate(candidates, caster)

		if(WILD_TARGET_TURF_OF_CAST_ON)
			AddTargetCandidate(candidates, get_turf(real_target))

		if(WILD_TARGET_TURF_OF_CASTER)
			AddTargetCandidate(candidates, get_turf(caster))

	return candidates

/datum/element/wild_magic/proc/AddTargetCandidate(list/candidates, atom/candidate)
	if(!candidate || QDELETED(candidate))
		return
	if(candidate in candidates)
		return
	candidates += candidate

/datum/element/wild_magic/proc/IsSpellTargetSafe(
	datum/action/cooldown/spell/surge_spell,
	atom/candidate,
	mob/living/caster
)
	if(!candidate || QDELETED(candidate))
		return FALSE

	if(istype(surge_spell, /datum/action/cooldown/spell/healing))
		return isliving(candidate)

	if(istype(surge_spell, /datum/action/cooldown/spell/beast_tame))
		return istype(candidate, /mob/living/simple_animal/hostile/retaliate)

	if(istype(surge_spell, /datum/action/cooldown/spell/find_flaw))
		return ishuman(candidate)

	if(istype(surge_spell, /datum/action/cooldown/spell/blindness))
		return isliving(candidate)

	if(istype(surge_spell, /datum/action/cooldown/spell/chill_touch))
		return istype(candidate, /mob/living/carbon)

	if(istype(surge_spell, /datum/action/cooldown/spell/gravity))
		return isliving(candidate)

	return TRUE

/datum/element/wild_magic/proc/surge_mute(mob/living/caster, atom/real_target, mob/living/random_target)
	if(!caster || QDELETED(caster))
		return

	ADD_TRAIT(caster, TRAIT_MUTE, "wild_magic")
	addtimer(CALLBACK(src, PROC_REF(restore_mute), caster), 60 SECONDS)

/datum/element/wild_magic/proc/surge_mist(mob/living/caster, atom/real_target, mob/living/random_target)
	RunShapeshiftSurge(caster, /datum/action/cooldown/spell/undirected/shapeshift/mist, PROC_REF(restore_mist_form))

/datum/element/wild_magic/proc/surge_cat(mob/living/caster, atom/real_target, mob/living/random_target)
	RunShapeshiftSurge(caster, /datum/action/cooldown/spell/undirected/shapeshift/cat, PROC_REF(restore_cat_form))

/datum/element/wild_magic/proc/surge_crow(mob/living/caster, atom/real_target, mob/living/random_target)
	RunShapeshiftSurge(caster, /datum/action/cooldown/spell/undirected/shapeshift/crow, PROC_REF(restore_crow_form))

/datum/element/wild_magic/proc/RunShapeshiftSurge(
	mob/living/caster,
	datum/action/cooldown/spell/undirected/shapeshift/spell_type,
	restore_proc
)
	if(!caster || QDELETED(caster))
		return
	if(caster.has_status_effect(/datum/status_effect/shapechange_mob/from_spell) || !isturf(caster.loc))
		return

	var/datum/action/cooldown/spell/undirected/shapeshift/shift_spell = new spell_type
	shift_spell.owner = caster
	if(!length(shift_spell.possible_shapes))
		return
	shift_spell.shapeshift_type = shift_spell.possible_shapes[1]

	var/mob/living/shifted_mob = shift_spell.do_shapeshift(caster)
	if(!shifted_mob)
		return

	addtimer(CALLBACK(src, restore_proc, shifted_mob), WILD_SHAPESHIFT_DURATION)

/datum/element/wild_magic/proc/restore_mist_form(mob/living/mist)
	if(!mist || QDELETED(mist))
		return

	var/datum/status_effect/shapechange_mob/from_spell/shape = mist.has_status_effect(/datum/status_effect/shapechange_mob/from_spell)
	if(!shape)
		return

	mist.visible_message(span_notice("The mist condenses, reforming into a solid body!"))
	shape.restore_caster()

/datum/element/wild_magic/proc/restore_cat_form(mob/living/cat)
	if(!cat || QDELETED(cat))
		return

	var/datum/status_effect/shapechange_mob/from_spell/shape = cat.has_status_effect(/datum/status_effect/shapechange_mob/from_spell)
	if(!shape)
		return

	cat.visible_message(span_notice("[cat] shimmers and reforms into their original shape!"))
	shape.restore_caster()

/datum/element/wild_magic/proc/restore_crow_form(mob/living/crow)
	if(!crow || QDELETED(crow))
		return

	var/datum/status_effect/shapechange_mob/from_spell/shape = crow.has_status_effect(/datum/status_effect/shapechange_mob/from_spell)
	if(!shape)
		return

	crow.visible_message(span_notice("The crow shimmers and reforms into its original shape!"))
	shape.restore_caster()

/datum/element/wild_magic/proc/restore_mute(mob/living/caster)
	if(!caster || QDELETED(caster))
		return
	if(!HAS_TRAIT(caster, TRAIT_MUTE))
		return

	REMOVE_TRAIT(caster, TRAIT_MUTE, "wild_magic")
	caster.visible_message(span_danger("Pink bubbles stop coming out of [caster]'s mouth."))

#undef WILD_CHANCE
#undef WILD_CD
#undef WILD_SHAPESHIFT_DURATION

#undef WILD_TARGET_SELF
#undef WILD_TARGET_RANDOM_LIVING
#undef WILD_TARGET_CAST_ON
#undef WILD_TARGET_TURF_OF_CAST_ON
#undef WILD_TARGET_TURF_OF_CASTER
