// Hunting & Tracking pack - the bramblesnout's charge.
//
// Built on /datum/action/cooldown/mob_cooldown, the same base the kraken's abilities use, and
// wired to the AI through the existing targeted_mob_ability planning subtree. The shape of it:
//
//   telegraph -> run forward in a three-wide lane -> gore the first enemy hit, or slam into
//   whatever stopped it. A clean miss refunds the cooldown once, so it can immediately wheel
//   around for a second pass - that is what missed_once tracks.

/// Blackboard key the AI looks up the charge action under. Core's BB_* keys live in
/// code/__DEFINES/ai/_ai.dm; this one is the pack's own, so it is declared here.
#define BB_BOAR_CHARGE "bb_boar_charge"

/// How far the boar will run in one charge.
#define BOAR_CHARGE_RANGE 7
/// It will not bother charging something already on top of it.
#define BOAR_CHARGE_MIN_RANGE 2
/// Pause between charge steps, in deciseconds. Fast enough to be frightening, slow enough to dodge.
#define BOAR_CHARGE_STEP_DELAY 1
/// Windup before it commits, so the telegraph is readable.
#define BOAR_CHARGE_WINDUP (1.2 SECONDS)

/datum/action/cooldown/mob_cooldown/boar_charge
	name = "Charge"
	desc = "Lowers its head and barrels forward."
	button_icon = 'icons/effects/effects.dmi'
	button_icon_state = "strike"
	cooldown_time = 20 SECONDS
	/// Damage dealt to whoever it catches.
	var/gore_damage = 60
	/// Damage the shockwave deals to bystanders when it hits a wall instead.
	var/slam_damage = 20
	/// Set after a charge that connected with nothing, to grant one immediate retry.
	var/missed_once = FALSE
	/// Guards against the AI queueing a second charge mid-run.
	var/charging = FALSE

/datum/action/cooldown/mob_cooldown/boar_charge/Activate(atom/target)
	var/mob/living/boar = owner
	if(!isliving(boar) || charging)
		return FALSE
	if(QDELETED(target) || boar.stat != CONSCIOUS || boar.incapacitated())
		return FALSE

	var/facing = get_dir(boar, target)
	if(!(facing in GLOB.cardinals))
		return FALSE
	if(get_dist(boar, target) < BOAR_CHARGE_MIN_RANGE)
		return FALSE

	StartCooldown()
	charging = TRUE
	boar.visible_message(span_boldwarning("[boar] lowers its head and paws at the ground!"))
	playsound(get_turf(boar), 'modular_rmh/sound/hunting/boar_charge.ogg', 80, TRUE)
	addtimer(CALLBACK(src, PROC_REF(begin_run), boar, facing), BOAR_CHARGE_WINDUP)
	return TRUE

/datum/action/cooldown/mob_cooldown/boar_charge/proc/begin_run(mob/living/boar, facing)
	if(QDELETED(boar) || boar.stat != CONSCIOUS || boar.incapacitated())
		charging = FALSE
		return
	boar.visible_message(span_danger("<b>[boar]</b> charges!"))
	INVOKE_ASYNC(src, PROC_REF(charge_run), boar, facing)

/// The tiles the boar sweeps at each step: the one ahead plus the two flanking it.
/datum/action/cooldown/mob_cooldown/boar_charge/proc/row_turfs(turf/centre, facing)
	. = list(centre)
	var/list/sides = (facing in list(EAST, WEST)) ? list(NORTH, SOUTH) : list(WEST, EAST)
	for(var/side in sides)
		var/turf/flank = get_step(centre, side)
		if(flank && !flank.density)
			. += flank

/datum/action/cooldown/mob_cooldown/boar_charge/proc/charge_run(mob/living/boar, facing)
	for(var/step_number in 1 to BOAR_CHARGE_RANGE)
		if(QDELETED(boar) || boar.stat != CONSCIOUS || boar.incapacitated())
			break

		var/turf/next = get_step(get_turf(boar), facing)
		if(!next || next.density || blocked_by_structure(next))
			slam_into(boar, next || get_turf(boar))
			charging = FALSE
			return

		var/hit_something = FALSE
		for(var/turf/swept as anything in row_turfs(next, facing))
			for(var/mob/living/victim in swept)
				if(victim == boar || victim.stat == DEAD)
					continue
				if(victim.faction_check_atom(boar, TRUE))
					continue
				gore(boar, victim)
				hit_something = TRUE
				break
			if(hit_something)
				break
		if(hit_something)
			charging = FALSE
			return

		step(boar, facing)
		sleep(BOAR_CHARGE_STEP_DELAY)

	charging = FALSE
	if(missed_once)
		missed_once = FALSE
		return
	// First clean miss: let it wheel around and try again straight away.
	missed_once = TRUE
	StartCooldownSelf(1 SECONDS)
	if(!QDELETED(boar))
		boar.visible_message(span_notice("[boar] skids to a halt and prepares to lunge again!"))

/datum/action/cooldown/mob_cooldown/boar_charge/proc/blocked_by_structure(turf/checked)
	for(var/obj/structure/blocker in checked)
		if(blocker.density && !blocker.climbable)
			return TRUE
	return FALSE

/datum/action/cooldown/mob_cooldown/boar_charge/proc/gore(mob/living/boar, mob/living/victim)
	missed_once = FALSE
	victim.visible_message(span_userdanger("[boar] gores [victim]!"), span_userdanger("[boar] drives its tusks into you!"))
	playsound(victim, 'sound/combat/crit.ogg', 75, TRUE)

	victim.apply_damage(gore_damage, BRUTE, BODY_ZONE_CHEST)
	victim.Stun(2 SECONDS)
	victim.apply_status_effect(/datum/status_effect/debuff/exposed)
	// The boar has to recover from the impact too, which is the hunter's window.
	boar.Stun(3 SECONDS)

/datum/action/cooldown/mob_cooldown/boar_charge/proc/slam_into(mob/living/boar, turf/impact_turf)
	missed_once = FALSE
	boar.visible_message(span_danger("[boar] slams into the environment with bone-shattering force!"))
	playsound(impact_turf, 'sound/combat/hits/onwood/fence_hit3.ogg', 100, TRUE)
	boar.Stun(3 SECONDS)

	for(var/mob/living/bystander in range(1, impact_turf))
		if(bystander == boar || bystander.stat == DEAD)
			continue
		bystander.visible_message(span_warning("The shockwave from [boar]'s impact staggers [bystander]!"))
		bystander.apply_status_effect(/datum/status_effect/debuff/vulnerable)
		bystander.apply_damage(slam_damage, BRUTE, BODY_ZONE_CHEST)

/datum/ai_planning_subtree/targeted_mob_ability/continue_planning/boar_charge
	ability_key = BB_BOAR_CHARGE

#undef BOAR_CHARGE_RANGE
#undef BOAR_CHARGE_MIN_RANGE
#undef BOAR_CHARGE_STEP_DELAY
#undef BOAR_CHARGE_WINDUP
