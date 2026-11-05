// Slumber (the BG3 Sleep): an area slumber that spends a pool of vitality.
/datum/action/cooldown/spell/aoe/slumber
	name = "Sleep"
	desc = "Lull everyone within 2 tiles of a point up to 7 tiles away into a 20 second sleep. The spell carries 40 points, plus 15 per slot level above the first, and spends them on the weakest first: a creature costs its remaining vitality as a share of full health, so a fresh one costs 100 and only a level-five cast lulls the unhurt. Anyone already fighting may resist with constitution; the undead and you are immune."
	button_icon_state = "sands_of_time"
	sound = 'sound/magic/churn.ogg'

	invocation = "Hush now, and sleep."
	invocation_type = INVOCATION_WHISPER

	cast_range = 7
	aoe_radius = 2
	charge_time = 1.5 SECONDS
	cooldown_time = 45 SECONDS
	spell_cost = 40

	slot_level = 1
	slot_only = TRUE
	slot_label = "Sleep"
	required_form = FORM_ARCANE
	required_technique = TECHNIQUE_ILLUSION
	required_level = MASTERY_RANK_NOVICE
	learnable = TRUE

	/// Hit points of slumber at the spell's own level.
	var/base_pool = 40
	/// Extra hit points per slot level above the first.
	var/pool_per_upcast = 15
	/// How long each sleeper stays down.
	var/sleep_duration = 20 SECONDS
	/// Hit points left to spend on the cast in progress.
	var/tmp/pool_left = 0
	/// Sleepers felled by the cast in progress.
	var/tmp/sleepers_felled = 0

/datum/action/cooldown/spell/aoe/slumber/is_valid_target(atom/cast_on)
	return !isnull(get_turf(cast_on))

/datum/action/cooldown/spell/aoe/slumber/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	// Refusing here spends neither the slot nor the cooldown.
	if(!can_see(owner, cast_on, get_cast_range()))
		owner.balloon_alert(owner, "can't see there!")
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/aoe/slumber/cast(atom/cast_on)
	pool_left = get_sleep_pool()
	sleepers_felled = 0
	. = ..()
	if(!sleepers_felled)
		to_chat(owner, span_warning("No one there falls asleep."))

/// The pool for the cast in progress: 40, 55, 70, 85, then 100 at level 5.
/datum/action/cooldown/spell/aoe/slumber/proc/get_sleep_pool()
	return base_pool + pool_per_upcast * get_upcast_steps()

/// Living sleepers around the point, keyed to their health and sorted weakest first.
/datum/action/cooldown/spell/aoe/slumber/get_things_to_cast_on(atom/center)
	var/list/sleepers = list()
	for(var/mob/living/victim in hearers(aoe_radius, get_turf(center)))
		if(victim == owner || victim.stat >= UNCONSCIOUS)
			continue
		if((victim.mob_biotypes & MOB_UNDEAD) || HAS_TRAIT(victim, TRAIT_SLEEPIMMUNE))
			continue
		sleepers[victim] = get_sleep_cost(victim)
	return sortTim(sleepers, GLOBAL_PROC_REF(cmp_numeric_asc), associative = TRUE)

/datum/action/cooldown/spell/aoe/slumber/cast_on_thing_in_aoe(mob/living/victim, atom/center)
	var/cost = get_sleep_cost(victim)
	// Weakest come first, so the first sleeper the pool cannot cover ends the spell.
	if(cost > pool_left)
		return TRUE
	// Wards and resisted rolls still use up the slumber spent on that target.
	pool_left -= cost
	if(victim.can_block_magic(antimagic_flags))
		victim.visible_message(span_warning("The drowsy haze parts around [victim]."), span_warning("A drowsy haze washes over me and parts."))
		playsound(victim, 'sound/magic/magic_nulled.ogg', 100)
		return
	if(victim.cmode && resists_sleep(victim))
		victim.visible_message(span_warning("[victim] shakes off a wave of drowsiness!"), span_notice("I fight off a wave of drowsiness!"))
		return
	victim.Sleeping(sleep_duration)
	sleepers_felled++
	victim.visible_message(span_warning("[victim] slumps into a magical sleep!"), span_userdanger("An overwhelming drowsiness drags me under..."))

/// Remaining vitality as a share of full health, 1 to 100; health alone ignores brute here.
/datum/action/cooldown/spell/aoe/slumber/proc/get_sleep_cost(mob/living/victim)
	var/damage = victim.getBruteLoss() + victim.getFireLoss() + victim.getToxLoss() + victim.getOxyLoss()
	var/full = max(victim.maxHealth, 1)
	return round(100 * clamp(full - damage, 1, full) / full)

/// A target braced for a fight rolls constitution in the mental context to stay awake.
/datum/action/cooldown/spell/aoe/slumber/proc/resists_sleep(mob/living/victim)
	var/result = victim.diceroll(victim.get_stat(STAT_CONSTITUTION), context = DICE_CONTEXT_MENTAL)
	return result == DICE_SUCCESS || result == DICE_CRIT_SUCCESS

/// The cast reports its own outcome once the pool is spent.
/datum/action/cooldown/spell/aoe/slumber/feedback(had_targets)
	return
