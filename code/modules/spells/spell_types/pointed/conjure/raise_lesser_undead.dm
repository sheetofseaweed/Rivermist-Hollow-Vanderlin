/datum/action/cooldown/spell/conjure/raise_lesser_undead
	name = "Raise Lesser undead"
	desc = "Summons a temporary skeleton to aid you."
	button_icon_state = "animate"
	self_cast_possible = FALSE
	sound = 'sound/magic/magnet.ogg'

	invocation = "SERVE ME!"
	invocation_type = INVOCATION_SHOUT

	charge_time = 2 SECONDS
	charge_drain = 1
	charge_slowdown = 1.3
	cooldown_time = 6 MINUTES
	spell_cost = 70
	summon_type = list(/mob/living/simple_animal/hostile/skeleton)
	summon_radius = 0
	summon_lifespan = 5 MINUTES
	spell_type = SPELL_MIRACLE
	antimagic_flags = MAGIC_RESISTANCE_HOLY
	associated_skill = /datum/attribute/skill/magic/holy
	var/cabal_affine = FALSE

/datum/action/cooldown/spell/conjure/raise_lesser_undead/before_cast()
	. = ..()
	var/skeleton_roll = rand(1,100)
	switch(skeleton_roll)
		if(1 to 20)
			summon_type = list(/mob/living/simple_animal/hostile/skeleton/axe)
		if(21 to 40)
			summon_type = list(/mob/living/simple_animal/hostile/skeleton/spear)
		if(41 to 60)
			summon_type = list(/mob/living/simple_animal/hostile/skeleton/guard)
		if(61 to 80)
			summon_type = list(/mob/living/simple_animal/hostile/skeleton/bow)
		if(81 to 100)
			summon_type = list(/mob/living/simple_animal/hostile/skeleton)


/datum/action/cooldown/spell/conjure/raise_lesser_undead/post_summon(atom/summoned_object, atom/cast_on)
	var/mob/living/skeleton = summoned_object
	skeleton.befriend(owner)
	if(cabal_affine)
		skeleton.add_faction(FACTION_CABAL)

	if(isliving(cast_on))
		var/mob/living/L = cast_on
		if(L.stat != DEAD)
			skeleton.ai_controller?.set_blackboard_key(BB_BASIC_MOB_PRIORITY_TARGETS, L)
		return
	for(var/mob/living/L in get_turf(cast_on))
		if(L.stat == DEAD)
			continue
		skeleton.ai_controller?.set_blackboard_key(BB_BASIC_MOB_PRIORITY_TARGETS, L)
		break


/datum/action/cooldown/spell/conjure/raise_lesser_undead/necromancer
	name = "Lesser Necromancy"
	spell_type = SPELL_MANA
	antimagic_flags = MAGIC_RESISTANCE
	associated_skill = /datum/attribute/skill/magic/arcane
	cabal_affine = TRUE
	cooldown_time = 30 SECONDS
	summon_lifespan = 1 MINUTES
	upcast_extra_summons = TRUE

	slot_level = 2
	slot_level_max = 4
	slot_only = TRUE
	concentration = TRUE
	slot_label = "Lesser Necromancy"
	required_form = FORM_DEATH
	required_technique = TECHNIQUE_SUMMONING
	required_level = MASTERY_RANK_ADEPT

	/// The raised skeletons, so concentration can dismiss them.
	var/list/datum/weakref/skeleton_refs

/datum/action/cooldown/spell/conjure/raise_lesser_undead/necromancer/Destroy()
	skeleton_refs = null
	return ..()

/// One raising per concentration: raising again dismisses the last skeletons.
/datum/action/cooldown/spell/conjure/raise_lesser_undead/necromancer/cast(atom/cast_on)
	if(uses_spell_slots())
		on_concentration_broken(CONCENTRATION_REPLACED)
	return ..()

/datum/action/cooldown/spell/conjure/raise_lesser_undead/necromancer/post_summon(atom/summoned_object, atom/cast_on)
	. = ..()
	LAZYADD(skeleton_refs, WEAKREF(summoned_object))
	RegisterSignal(summoned_object, COMSIG_PARENT_QDELETING, PROC_REF(on_skeleton_gone))

/datum/action/cooldown/spell/conjure/raise_lesser_undead/necromancer/on_concentration_broken(reason)
	var/list/skeletons = skeleton_refs
	skeleton_refs = null
	for(var/datum/weakref/skeleton_ref as anything in skeletons)
		var/mob/living/skeleton = skeleton_ref.resolve()
		if(QDELETED(skeleton))
			continue
		skeleton.visible_message(span_warning("[skeleton] collapses into dust as its master's focus slips."))
		qdel(skeleton)

/datum/action/cooldown/spell/conjure/raise_lesser_undead/necromancer/proc/on_skeleton_gone(datum/source)
	SIGNAL_HANDLER
	// Weakrefs stop resolving during deletion, so match the reference itself.
	LAZYREMOVE(skeleton_refs, source.weak_reference)
	if(!LAZYLEN(skeleton_refs))
		get_spell_slots()?.clear_concentration(src)
