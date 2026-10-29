// Scorching Ray: three rays of fire, one more per upcast step.
/datum/action/cooldown/spell/projectile/scorching_ray
	name = "Scorching Ray"
	desc = "Hurl three rays of fire at a target, one after another. Each ray deals 18 burn, scaled by rank, and sets what it strikes briefly alight. Every slot level above the second adds a ray, six at level 5."
	button_icon_state = "meteor_storm"
	sound = 'sound/magic/fireball.ogg'
	charge_sound = 'sound/magic/charging_fire.ogg'

	cast_range = SPELL_RANGE_PROJECTILE
	point_cost = 3

	invocation = "RADIUS IGNIS!"
	invocation_type = INVOCATION_SHOUT

	charge_time = CHARGETIME_MAJOR
	charge_drain = 1
	charge_slowdown = 0.7
	cooldown_time = 25 SECONDS
	spell_cost = 45
	spell_flags = SPELL_RITUOS
	projectile_type = /obj/projectile/magic/scorching_ray
	projectiles_per_fire = 3

	slot_level = 2
	slot_only = TRUE
	slot_label = "Scorching Ray"
	required_form = FORM_FIRE
	required_technique = TECHNIQUE_DESTRUCTION
	required_level = MASTERY_RANK_ADEPT
	prerequisite_spells = list(/datum/action/cooldown/spell/projectile/fire_flare)
	learnable = TRUE

	/// Burn of each ray before the rank multiplier; upcasting adds rays, not damage.
	var/ray_damage = 18

/// Rays for the cast in progress: one more per upcast step.
/datum/action/cooldown/spell/projectile/scorching_ray/proc/get_ray_count()
	return projectiles_per_fire + get_upcast_steps()

/datum/action/cooldown/spell/projectile/scorching_ray/fire_projectile(atom/target)
	current_amount--
	var/rays = get_ray_count()
	var/level = get_effect_level()
	if(level)
		to_chat(owner, span_notice("The [get_slot_label()] forms [rays] rays at spell level [level]."))
	var/turf/aim_turf = get_turf(target)
	for(var/i in 1 to rays)
		// The click path runs async, so a short sleep keeps the rays apart in flight.
		if(i > 1)
			sleep(1)
			if(QDELETED(src) || QDELETED(owner) || !isturf(owner.loc))
				return FALSE
			if(QDELETED(target))
				target = aim_turf
		var/obj/projectile/to_fire = new projectile_type()
		ready_projectile(to_fire, target, owner, i)
		to_fire.fire()
	return TRUE

/datum/action/cooldown/spell/projectile/scorching_ray/ready_projectile(obj/projectile/to_fire, atom/target, mob/user, iteration)
	. = ..()
	to_fire.damage = ray_damage * get_rank_multiplier()

/// A volley can outlive its owner, and removal already unset the click.
/datum/action/cooldown/spell/projectile/scorching_ray/unset_click_ability(mob/on_who, refund_cooldown = TRUE)
	if(!on_who)
		return FALSE
	return ..()

/// A ray of fire that leaves the creature it strikes briefly burning.
/obj/projectile/magic/scorching_ray
	name = "scorching ray"
	icon_state = "firebeam"
	damage = 18
	damage_type = BURN
	woundclass = BCLASS_BURN
	nodamage = FALSE
	hitsound = 'sound/fireball.ogg'
	speed = 1
	light_color = LIGHT_COLOR_FIRE
	light_outer_range = 1
	/// Fire stacks each ray adds; a Fire Flare blast adds six.
	var/fire_stacks_added = 1

/obj/projectile/magic/scorching_ray/on_hit(atom/target, blocked = FALSE, pierce_hit)
	. = ..()
	// A shield block reports the hit as fully blocked.
	if(blocked >= 100 || !isliving(target))
		return
	var/mob/living/burning = target
	burning.adjust_fire_stacks(fire_stacks_added)
	burning.IgniteMob()
