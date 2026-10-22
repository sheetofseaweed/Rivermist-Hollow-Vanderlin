// Faerun devotion holders. The pantheon bases cover gods without a holder of their own.
/datum/devotion/faerun

/datum/devotion/faerun/good
	miracles = list(
		CLERIC_T0 = /datum/action/cooldown/spell/healing,
		CLERIC_T1 = /datum/action/cooldown/spell/sacred_flame,
	)

/datum/devotion/faerun/neutral
	miracles = list(
		CLERIC_T0 = /datum/action/cooldown/spell/healing,
		CLERIC_T1 = /datum/action/cooldown/spell/sacred_flame,
	)

// Evil gods grant heretical miracles and never forsake their own.
/datum/devotion/faerun/evil
	miracles = list(
		CLERIC_T0 = /datum/action/cooldown/spell/healing/profane,
		CLERIC_T1 = /datum/action/cooldown/spell/projectile/profane,
	)

/datum/devotion/faerun/evil/make_cleric()
	. = ..()
	miracles_extra += list(
		/datum/action/cooldown/spell/healing/profane,
		/datum/action/cooldown/spell/undirected/rituos,
	)

/// Evil gods answer with corrupt forms of the kit's good miracles.
/datum/devotion/faerun/evil/grant_to(mob/living/carbon/human/holder)
	. = ..()
	if(!.)
		return
	var/static/list/corruptions = list(
		/datum/action/cooldown/spell/healing = /datum/action/cooldown/spell/healing/profane,
		/datum/action/cooldown/spell/healing/greater = /datum/action/cooldown/spell/healing/greater/profane,
		/datum/action/cooldown/spell/sacred_flame = /datum/action/cooldown/spell/sacred_flame/oathbreaker,
	)
	for(var/good_type in corruptions)
		if(!holder_mob.get_spell(good_type, TRUE))
			continue
		holder_mob.remove_spell(good_type)
		holder_mob.add_spell(corruptions[good_type], source = src, mastery_spell = holder_mob.mind?.is_slot_caster())

/datum/devotion/faerun/evil/make_templar()
	. = ..()
	miracles_extra += list(
		/datum/action/cooldown/spell/healing/profane,
	)

/datum/devotion/faerun/evil/make_acolyte()
	. = ..()
	miracles_extra += list(
		/datum/action/cooldown/spell/healing/profane,
	)

/datum/devotion/faerun/evil/excommunicate()
	return

/datum/devotion/faerun/evil/recommunicate()
	return

// Good gods

/datum/devotion/faerun/good/lathander
	miracles = list(
		CLERIC_T0 = /datum/action/cooldown/spell/healing,
		CLERIC_T1 = /datum/action/cooldown/spell/sacred_flame,
		CLERIC_T2 = /datum/action/cooldown/spell/healing/greater,
		CLERIC_T3 = /datum/action/cooldown/spell/revive,
	)
	viable_tasks = list(
		/datum/devotion_task/lathander_purge,
	)

/datum/devotion/faerun/good/ilmater
	miracles = list(
		CLERIC_T0 = list(/datum/action/cooldown/spell/healing, /datum/action/cooldown/spell/undirected/conjure_item/summon_leech),
		CLERIC_T1 = /datum/action/cooldown/spell/diagnose/holy,
		CLERIC_T2 = /datum/action/cooldown/spell/attach_bodypart,
		CLERIC_T3 = /datum/action/cooldown/spell/cure_rot,
	)
	viable_tasks = list(
		/datum/devotion_task/ilmater_heal,
		/datum/devotion_task/ilmater_medicine,
	)

/datum/devotion/faerun/good/moradin
	miracles = list(
		CLERIC_T0 = /datum/action/cooldown/spell/healing,
		CLERIC_T1 = /datum/action/cooldown/spell/status/vigorous_craft,
		CLERIC_T2 = /datum/action/cooldown/spell/hammer_fall,
		CLERIC_T3 = /datum/action/cooldown/spell/heat_metal,
	)
	viable_tasks = list(
		/datum/devotion_task/moradin_craft,
		/datum/devotion_task/moradin_smelt,
		/datum/devotion_task/moradin_forge,
	)

/datum/devotion/faerun/good/sune
	miracles = list(
		CLERIC_T0 = /datum/action/cooldown/spell/healing,
		CLERIC_T1 = /datum/action/cooldown/spell/instill_perfection,
		CLERIC_T2 = /datum/action/cooldown/spell/projectile/eora_curse,
		CLERIC_T3 = /datum/action/cooldown/spell/eoran_bloom,
	)
	favored_species = list(SPEC_ID_HARPY)
	favored_miracles = list(
		CLERIC_T3 = /datum/action/cooldown/spell/charm/eoran
	)
	viable_tasks = list(
		/datum/devotion_task/sune_create,
		/datum/devotion_task/sune_hug,
	)

// Neutral gods

/datum/devotion/faerun/neutral/mystra
	miracles = list(
		CLERIC_T0 = /datum/action/cooldown/spell/healing,
		CLERIC_T1 = /datum/action/cooldown/spell/status/invisibility,
		CLERIC_T2 = /datum/action/cooldown/spell/blindness/miracle,
		CLERIC_T3 = /datum/action/cooldown/spell/projectile/moonlit_dagger,
	)
	viable_tasks = list(
		/datum/devotion_task/mystra_teach,
		/datum/devotion_task/mystra_write,
		/datum/devotion_task/mystra_read,
	)

/datum/devotion/faerun/neutral/silvanus
	miracles = list(
		CLERIC_T0 = /datum/action/cooldown/spell/healing,
		CLERIC_T1 = /datum/action/cooldown/spell/undirected/bless_crops,
		CLERIC_T2 = /datum/action/cooldown/spell/undirected/beast_sense,
		CLERIC_T3 = /datum/action/cooldown/spell/beast_tame,
	)
	viable_tasks = list(
		/datum/devotion_task/silvanus_tend,
		/datum/devotion_task/silvanus_harvest,
		/datum/devotion_task/silvanus_bless,
	)

/datum/devotion/faerun/neutral/jergal
	miracles = list(
		CLERIC_T0 = list(/datum/action/cooldown/spell/healing, /datum/action/cooldown/spell/avert),
		CLERIC_T2 = list(/datum/action/cooldown/spell/undirected/locate_dead, /datum/action/cooldown/spell/aoe/abrogation, /datum/action/cooldown/spell/undirected/soul_speak, ),
		CLERIC_T3 = /datum/action/cooldown/spell/aoe/churn_undead,
	)
	viable_tasks = list(
		/datum/devotion_task/jergal_bury,
		/datum/devotion_task/lathander_purge,
	)
	traits = list(TRAIT_DEATHSIGHT)

/datum/devotion/faerun/neutral/tempus
	miracles = list(
		CLERIC_T0 = /datum/action/cooldown/spell/healing,
		CLERIC_T1 = /datum/action/cooldown/spell/undirected/call_to_arms,
		CLERIC_T2 = /datum/action/cooldown/spell/undirected/divine_strike,
		CLERIC_T3 = /datum/action/cooldown/spell/persistence,
	)

/datum/devotion/faerun/neutral/tymora
	miracles = list(
		CLERIC_T0 = /datum/action/cooldown/spell/healing,
		CLERIC_T1 = /datum/action/cooldown/spell/undirected/list_target/vicious_mimicry,
		CLERIC_T2 = /datum/action/cooldown/spell/status/wheel,
		CLERIC_T3 = /datum/action/cooldown/spell/undirected/jaunt/illusory_prop,
	)
	viable_tasks = list(
		/datum/devotion_task/tymora_gamble,
		/datum/devotion_task/tymora_trick,
	)

// Evil gods

/datum/devotion/faerun/evil/umberlee
	miracles = list(
		CLERIC_T0 = list(/datum/action/cooldown/spell/healing, /datum/action/cooldown/spell/undirected/conjure_item/summon_leech),
		CLERIC_T1 = /datum/action/cooldown/spell/projectile/swordfish,
		CLERIC_T2 = /datum/action/cooldown/spell/undirected/conjure_item/summon_trident/miracle,
		CLERIC_T3 = /datum/action/cooldown/spell/ocean_embrace,
	)
	viable_tasks = list(
		/datum/devotion_task/umberlee_sail,
		/datum/devotion_task/umberlee_fish,
	)

/datum/devotion/faerun/evil/lolth
	miracles = list(
		CLERIC_T0 = list(/datum/action/cooldown/spell/undirected/touch/orison, /datum/action/cooldown/spell/aoe/snuff),
		CLERIC_T1 = /datum/action/cooldown/spell/projectile/profane,
		CLERIC_T2 = /datum/action/cooldown/spell/conjure/raise_lesser_undead,
		CLERIC_T3 = /datum/action/cooldown/spell/undirected/rituos,
	)
	traits = list(TRAIT_DEATHSIGHT)

/datum/devotion/faerun/evil/gruumsh
	miracles = list(
		CLERIC_T0 = /datum/action/cooldown/spell/undirected/bloodrage,
		CLERIC_T1 = /datum/action/cooldown/spell/undirected/call_to_slaughter,
		CLERIC_T2 = /datum/action/cooldown/spell/projectile/blood_net,
		CLERIC_T3 = /datum/action/cooldown/spell/revel_in_slaughter,
	)
	viable_tasks = list(
		/datum/devotion_task/gruumsh_consume,
	)

/datum/devotion/faerun/evil/mask
	miracles = list(
		CLERIC_T0 = /datum/action/cooldown/spell/appraise/holy,
		CLERIC_T1 = /datum/action/cooldown/spell/transact,
		CLERIC_T2 = /datum/action/cooldown/spell/beam/equalize,
		CLERIC_T3 = /datum/action/cooldown/spell/churn_wealthy,
	)
	viable_tasks = list(
		/datum/devotion_task/mask_steal,
	)

/datum/devotion/faerun/evil/blissara
	miracles = list(
		CLERIC_T0 = /datum/action/cooldown/spell/find_flaw,
		CLERIC_T1 = /datum/action/cooldown/spell/baothablessings,
		CLERIC_T2 = /datum/action/cooldown/spell/projectile/blowingdust,
		CLERIC_T3 = /datum/action/cooldown/spell/painkiller,
	)
	viable_tasks = list(
		/datum/devotion_task/blissara_indulge,
	)

// Per-god holders for the gods that used the pantheon defaults: defaults plus domain picks.

/datum/devotion/faerun/good/bahamut
	miracles = list(
		CLERIC_T0 = list(/datum/action/cooldown/spell/healing, /datum/action/cooldown/spell/undirected/protection_evil_good),
		CLERIC_T1 = list(/datum/action/cooldown/spell/sacred_flame, /datum/action/cooldown/spell/undirected/divine_strike, /datum/action/cooldown/spell/defeat_absolution),
		CLERIC_T2 = /datum/action/cooldown/spell/healing/greater,
	)


/datum/devotion/faerun/good/corellon
	miracles = list(
		CLERIC_T0 = list(/datum/action/cooldown/spell/healing, /datum/action/cooldown/spell/diagnose/holy),
		CLERIC_T1 = list(/datum/action/cooldown/spell/sacred_flame, /datum/action/cooldown/spell/cure_rot),
		CLERIC_T2 = /datum/action/cooldown/spell/attach_bodypart,
	)


/datum/devotion/faerun/good/eilistraee
	miracles = list(
		CLERIC_T0 = list(/datum/action/cooldown/spell/healing, /datum/action/cooldown/spell/undirected/protection_evil_good),
		CLERIC_T1 = list(/datum/action/cooldown/spell/sacred_flame, /datum/action/cooldown/spell/undirected/soul_speak),
		CLERIC_T2 = /datum/action/cooldown/spell/healing/greater,
		CLERIC_T3 = /datum/action/cooldown/spell/revive,
	)


/datum/devotion/faerun/good/mielikki
	miracles = list(
		CLERIC_T0 = list(/datum/action/cooldown/spell/healing, /datum/action/cooldown/spell/undirected/locate_dead),
		CLERIC_T1 = list(/datum/action/cooldown/spell/sacred_flame, /datum/action/cooldown/spell/cure_rot),
		CLERIC_T2 = /datum/action/cooldown/spell/attach_bodypart,
	)


/datum/devotion/faerun/good/selune
	miracles = list(
		CLERIC_T0 = list(/datum/action/cooldown/spell/healing, /datum/action/cooldown/spell/undirected/protection_evil_good, /datum/action/cooldown/spell/undirected/locate_dead),
		CLERIC_T1 = list(/datum/action/cooldown/spell/sacred_flame, /datum/action/cooldown/spell/undirected/soul_speak),
		CLERIC_T2 = /datum/action/cooldown/spell/aoe/churn_undead,
		CLERIC_T3 = /datum/action/cooldown/spell/revive,
	)


/datum/devotion/faerun/good/tyr
	miracles = list(
		CLERIC_T0 = list(/datum/action/cooldown/spell/healing, /datum/action/cooldown/spell/undirected/protection_evil_good),
		CLERIC_T1 = list(/datum/action/cooldown/spell/sacred_flame, /datum/action/cooldown/spell/undirected/divine_strike),
		CLERIC_T2 = /datum/action/cooldown/spell/aoe/churn_undead,
	)


/datum/devotion/faerun/good/yondalla
	miracles = list(
		CLERIC_T0 = list(/datum/action/cooldown/spell/healing, /datum/action/cooldown/spell/undirected/protection_evil_good, /datum/action/cooldown/spell/diagnose/holy),
		CLERIC_T1 = list(/datum/action/cooldown/spell/sacred_flame, /datum/action/cooldown/spell/cure_rot),
		CLERIC_T2 = /datum/action/cooldown/spell/healing/greater,
	)


/datum/devotion/faerun/good/sharess
	miracles = list(
		CLERIC_T0 = list(/datum/action/cooldown/spell/healing, /datum/action/cooldown/spell/diagnose/holy),
		CLERIC_T1 = list(/datum/action/cooldown/spell/sacred_flame, /datum/action/cooldown/spell/defeat_absolution, /datum/action/cooldown/spell/cure_rot),
	)


/datum/devotion/faerun/good/torm
	miracles = list(
		CLERIC_T0 = list(/datum/action/cooldown/spell/healing, /datum/action/cooldown/spell/undirected/protection_evil_good),
		CLERIC_T1 = list(/datum/action/cooldown/spell/sacred_flame, /datum/action/cooldown/spell/defeat_absolution, /datum/action/cooldown/spell/undirected/divine_strike),
		CLERIC_T2 = /datum/action/cooldown/spell/healing/greater,
	)


/datum/devotion/faerun/good/milil
	miracles = list(
		CLERIC_T0 = list(/datum/action/cooldown/spell/healing, /datum/action/cooldown/spell/undirected/touch/orison),
		CLERIC_T1 = list(/datum/action/cooldown/spell/sacred_flame, /datum/action/cooldown/spell/undirected/soul_speak, /datum/action/cooldown/spell/defeat_absolution),
	)


/datum/devotion/faerun/good/deneir
	miracles = list(
		CLERIC_T0 = list(/datum/action/cooldown/spell/healing, /datum/action/cooldown/spell/undirected/locate_dead, /datum/action/cooldown/spell/diagnose/holy),
		CLERIC_T1 = list(/datum/action/cooldown/spell/sacred_flame, /datum/action/cooldown/spell/undirected/soul_speak),
	)


/datum/devotion/faerun/good/garl_glittergold
	miracles = list(
		CLERIC_T0 = list(/datum/action/cooldown/spell/healing, /datum/action/cooldown/spell/undirected/protection_evil_good, /datum/action/cooldown/spell/undirected/touch/orison),
		CLERIC_T1 = list(/datum/action/cooldown/spell/sacred_flame, /datum/action/cooldown/spell/cure_rot),
	)


/datum/devotion/faerun/neutral/helm
	miracles = list(
		CLERIC_T0 = list(/datum/action/cooldown/spell/healing, /datum/action/cooldown/spell/undirected/protection_evil_good),
		CLERIC_T1 = list(/datum/action/cooldown/spell/sacred_flame, /datum/action/cooldown/spell/undirected/divine_strike, /datum/action/cooldown/spell/defeat_absolution),
		CLERIC_T2 = /datum/action/cooldown/spell/healing/greater,
	)


/datum/devotion/faerun/neutral/oghma
	miracles = list(
		CLERIC_T0 = list(/datum/action/cooldown/spell/healing, /datum/action/cooldown/spell/diagnose/holy, /datum/action/cooldown/spell/undirected/locate_dead),
		CLERIC_T1 = list(/datum/action/cooldown/spell/sacred_flame, /datum/action/cooldown/spell/undirected/soul_speak),
		CLERIC_T2 = /datum/action/cooldown/spell/attach_bodypart,
	)


/datum/devotion/faerun/evil/vlaakith
	miracles = list(
		CLERIC_T0 = list(/datum/action/cooldown/spell/healing/profane, /datum/action/cooldown/spell/undirected/locate_dead),
		CLERIC_T1 = list(/datum/action/cooldown/spell/projectile/profane, /datum/action/cooldown/spell/undirected/soul_speak),
		CLERIC_T2 = /datum/action/cooldown/spell/healing/greater/profane,
	)


/datum/devotion/faerun/evil/shar
	miracles = list(
		CLERIC_T0 = list(/datum/action/cooldown/spell/healing/profane, /datum/action/cooldown/spell/sacred_flame/oathbreaker),
		CLERIC_T1 = list(/datum/action/cooldown/spell/projectile/profane, /datum/action/cooldown/spell/undirected/soul_speak),
		CLERIC_T2 = /datum/action/cooldown/spell/healing/greater/profane,
	)


/datum/devotion/faerun/evil/laduguer
	miracles = list(
		CLERIC_T0 = list(/datum/action/cooldown/spell/healing/profane, /datum/action/cooldown/spell/diagnose/holy),
		CLERIC_T1 = list(/datum/action/cooldown/spell/projectile/profane, /datum/action/cooldown/spell/defeat_absolution),
		CLERIC_T2 = /datum/action/cooldown/spell/attach_bodypart,
	)


/datum/devotion/faerun/evil/talos
	miracles = list(
		CLERIC_T0 = list(/datum/action/cooldown/spell/healing/profane, /datum/action/cooldown/spell/sacred_flame/oathbreaker),
		CLERIC_T1 = list(/datum/action/cooldown/spell/projectile/profane, /datum/action/cooldown/spell/undirected/divine_strike),
		CLERIC_T2 = /datum/action/cooldown/spell/aoe/churn_undead,
	)


/datum/devotion/faerun/evil/tiamat
	miracles = list(
		CLERIC_T0 = list(/datum/action/cooldown/spell/healing/profane, /datum/action/cooldown/spell/sacred_flame/oathbreaker),
		CLERIC_T1 = list(/datum/action/cooldown/spell/projectile/profane, /datum/action/cooldown/spell/undirected/divine_strike),
		CLERIC_T2 = /datum/action/cooldown/spell/healing/greater/profane,
	)


/datum/devotion/faerun/evil/malar
	miracles = list(
		CLERIC_T0 = list(/datum/action/cooldown/spell/healing/profane, /datum/action/cooldown/spell/sacred_flame/oathbreaker),
		CLERIC_T1 = list(/datum/action/cooldown/spell/projectile/profane, /datum/action/cooldown/spell/undirected/divine_strike, /datum/action/cooldown/spell/cure_rot),
	)


/datum/devotion/faerun/evil/maglubiyet
	miracles = list(
		CLERIC_T0 = list(/datum/action/cooldown/spell/healing/profane, /datum/action/cooldown/spell/undirected/protection_evil_good),
		CLERIC_T1 = list(/datum/action/cooldown/spell/projectile/profane, /datum/action/cooldown/spell/undirected/divine_strike),
		CLERIC_T2 = /datum/action/cooldown/spell/aoe/churn_undead,
	)


/datum/devotion/faerun/evil/loviatar
	miracles = list(
		CLERIC_T0 = list(/datum/action/cooldown/spell/healing/profane, /datum/action/cooldown/spell/diagnose/holy),
		CLERIC_T1 = list(/datum/action/cooldown/spell/projectile/profane, /datum/action/cooldown/spell/defeat_absolution),
		CLERIC_T2 = /datum/action/cooldown/spell/healing/greater/profane,
	)


/datum/devotion/faerun/evil/asmodeus
	miracles = list(
		CLERIC_T0 = list(/datum/action/cooldown/spell/healing/profane, /datum/action/cooldown/spell/sacred_flame/oathbreaker),
		CLERIC_T1 = list(/datum/action/cooldown/spell/projectile/profane, /datum/action/cooldown/spell/undirected/soul_speak),
		CLERIC_T2 = /datum/action/cooldown/spell/healing/greater/profane,
		CLERIC_T3 = /datum/action/cooldown/spell/revive,
	)
