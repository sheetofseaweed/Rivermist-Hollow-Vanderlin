// Magic Missile: three unerring bolts, one more per upcast step.
/datum/action/cooldown/spell/projectile/magic_missile
	name = "Magic Missile"
	desc = "Loose three bolts of arcyne force that home in on a creature and cannot be dodged or deflected. Each bolt deals 13 damage, scaled by rank. Every slot level above the first adds a bolt, seven at level 5. Minor: a single 10-damage bolt, scaled like a cantrip."
	button_icon_state = "missile"
	sound = 'sound/magic/vlightning.ogg'

	cast_range = SPELL_RANGE_PROJECTILE
	point_cost = 2

	invocation = "FORTI GY AMA!"
	invocation_type = INVOCATION_SHOUT

	charge_time = CHARGETIME_MINOR
	charge_drain = 1
	charge_slowdown = 0.7
	cooldown_time = 12 SECONDS
	spell_cost = 25
	spell_flags = SPELL_RITUOS
	projectile_type = /obj/projectile/magic/magic_missile
	projectiles_per_fire = 3

	slot_level = 1
	minor_cost = SPELL_MINOR_COST_DEFAULT
	minor_projectile_type = /obj/projectile/magic/magic_missile/minor
	slot_label = "Magic Missile"
	required_form = FORM_ARCANE
	required_technique = TECHNIQUE_DESTRUCTION
	required_level = MASTERY_RANK_NOVICE
	learnable = TRUE

	/// Damage of each bolt before the rank multiplier; upcasting adds bolts, not damage.
	var/bolt_damage = 13
	/// Damage of the single Minor bolt before the cantrip multiplier.
	var/minor_bolt_damage = 10

/// Bolts for the cast in progress: one for a Minor cast, one more per upcast step otherwise.
/datum/action/cooldown/spell/projectile/magic_missile/proc/get_bolt_count()
	var/level = get_effect_level()
	if(!isnull(level) && level == SPELL_SLOT_MINOR)
		return 1
	return projectiles_per_fire + get_upcast_steps()

/datum/action/cooldown/spell/projectile/magic_missile/fire_projectile(atom/target)
	current_amount--
	var/bolts = get_bolt_count()
	var/level = get_effect_level()
	if(level)
		to_chat(owner, span_notice("The [get_slot_label()] forms [bolts] bolts at spell level [level]."))
	var/turf/aim_turf = get_turf(target)
	for(var/i in 1 to bolts)
		// The click path runs async, so a short sleep keeps the bolts apart in flight.
		if(i > 1)
			sleep(1)
			if(QDELETED(src) || QDELETED(owner) || !isturf(owner.loc))
				return FALSE
			if(QDELETED(target))
				target = aim_turf
		var/shot_type = projectile_type
		if(minor_projectile_type && uses_spell_slots() && get_cast_level() == SPELL_SLOT_MINOR)
			shot_type = minor_projectile_type
		var/obj/projectile/to_fire = new shot_type()
		ready_projectile(to_fire, target, owner, i)
		to_fire.fire()
	return TRUE

/datum/action/cooldown/spell/projectile/magic_missile/ready_projectile(obj/projectile/to_fire, atom/target, mob/user, iteration)
	. = ..()
	var/level = get_effect_level()
	if(!isnull(level) && level == SPELL_SLOT_MINOR)
		to_fire.damage = minor_bolt_damage * get_cantrip_multiplier()
	else
		to_fire.damage = bolt_damage * get_rank_multiplier()
	if(isliving(target))
		to_fire.set_homing_target(target)

/// A volley can outlive its owner, and removal already unset the click.
/datum/action/cooldown/spell/projectile/magic_missile/unset_click_ability(mob/on_who, refund_cooldown = TRUE)
	if(!on_who)
		return FALSE
	return ..()

/// A force bolt that no dodge or guard turns aside, homing on the creature it was sent at.
/obj/projectile/magic/magic_missile
	name = "magic missile"
	icon_state = "magicm"
	damage = 13
	damage_type = BRUTE
	woundclass = BCLASS_BLUNT
	nodamage = FALSE
	speed = 1.5
	range = 20
	dodgeable = FALSE
	guard_deflectable = FALSE
	homing_turn_speed = 30

/// A Shield ward swallows force bolts whole, as in the tabletop.
/obj/projectile/magic/magic_missile/on_hit(atom/target, blocked = FALSE, pierce_hit)
	if(isliving(target))
		var/mob/living/warded = target
		if(warded.has_status_effect(/datum/status_effect/buff/arcane_shield))
			warded.visible_message(span_notice("[src] breaks apart against the ward around [warded]."), span_notice("My ward swallows [src]."))
			return BULLET_ACT_BLOCK
	return ..()

/obj/projectile/magic/magic_missile/Destroy()
	homing_target = null
	return ..()

/obj/projectile/magic/magic_missile/process_homing()
	// A deleted target sits in nullspace; the bolt flies straight on instead.
	if(QDELETED(homing_target))
		homing = FALSE
		homing_target = null
		return FALSE
	return ..()

/// Minor Magic Missile: one weaker bolt with the same flight.
/obj/projectile/magic/magic_missile/minor
	name = "minor magic missile"
	icon_state = "magicmd"
	damage = 10
