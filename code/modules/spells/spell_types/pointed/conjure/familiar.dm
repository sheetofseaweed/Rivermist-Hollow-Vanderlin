/datum/action/cooldown/spell/conjure/familiar
	name = "Find Familiar"
	desc = "Summons a temporary spectral volf to aid you."
	button_icon_state = "zad"
	self_cast_possible = FALSE

	point_cost = 3

	sound = 'sound/magic/whiteflame.ogg'

	invocation = "B'ST FR'ND!"
	invocation_type = INVOCATION_SHOUT

	charge_time = 2 SECONDS
	charge_drain = 1
	charge_slowdown = 1.3
	cooldown_time = 6 MINUTES
	spell_cost = 30
	spell_flags = SPELL_RITUOS
	summon_type = list(/mob/living/simple_animal/hostile/retaliate/wolf/familiar)
	summon_radius = 0
	summon_lifespan = 5 MINUTES
	upcast_extra_summons = TRUE

	slot_level = 2
	slot_level_max = 4
	slot_only = TRUE
	concentration = TRUE
	slot_label = "Familiar"
	required_form = FORM_ARCANE
	required_technique = TECHNIQUE_SUMMONING
	required_level = MASTERY_RANK_ADEPT

	/// The living familiars, so concentration can dismiss them.
	var/list/datum/weakref/familiar_refs

/datum/action/cooldown/spell/conjure/familiar/Destroy()
	familiar_refs = null
	return ..()

/// One pack per concentration: summoning again dismisses the last one.
/datum/action/cooldown/spell/conjure/familiar/cast(atom/cast_on)
	if(uses_spell_slots())
		on_concentration_broken(CONCENTRATION_REPLACED)
	return ..()

/datum/action/cooldown/spell/conjure/familiar/on_concentration_broken(reason)
	var/list/familiars = familiar_refs
	familiar_refs = null
	for(var/datum/weakref/familiar_ref as anything in familiars)
		var/mob/living/wolf = familiar_ref.resolve()
		if(QDELETED(wolf))
			continue
		wolf.visible_message(span_warning("[wolf] fades away as its master's focus slips."))
		qdel(wolf)

/datum/action/cooldown/spell/conjure/familiar/proc/on_familiar_gone(datum/source)
	SIGNAL_HANDLER
	// Weakrefs stop resolving during deletion, so match the reference itself.
	LAZYREMOVE(familiar_refs, source.weak_reference)
	if(!LAZYLEN(familiar_refs))
		get_spell_slots()?.clear_concentration(src)

/datum/action/cooldown/spell/conjure/familiar/post_summon(atom/summoned_object, atom/cast_on)
	var/mob/living/wolf = summoned_object
	wolf.befriend(owner)
	LAZYADD(familiar_refs, WEAKREF(wolf))
	RegisterSignal(wolf, COMSIG_PARENT_QDELETING, PROC_REF(on_familiar_gone))

	if(isliving(cast_on))
		var/mob/living/L = cast_on
		if(L.stat != DEAD)
			wolf.ai_controller?.set_blackboard_key(BB_BASIC_MOB_PRIORITY_TARGETS, L)
		return
	for(var/mob/living/L in get_turf(cast_on))
		if(L.stat == DEAD)
			continue
		wolf.ai_controller?.set_blackboard_key(BB_BASIC_MOB_PRIORITY_TARGETS, L)
		break
