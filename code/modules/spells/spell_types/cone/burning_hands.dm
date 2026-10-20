// Burning Hands: a short cone of flame.
/datum/action/cooldown/spell/cone/staggered/burning_hands
	name = "Burning Hands"
	desc = "A sheet of flame roars from your hands in a cone three tiles deep. Each creature it reaches takes 20 burn, scaled by rank, and catches fire, as do flammable objects. Every slot level above the first adds a quarter more damage."
	button_icon_state = "immolation"
	sound = 'sound/magic/fireball.ogg'
	charge_sound = 'sound/magic/charging_fire.ogg'

	invocation = "MANUS FLAMMAE!"
	invocation_type = INVOCATION_SHOUT

	cone_levels = 3
	respect_density = TRUE
	delay_between_level = 0.1 SECONDS
	point_cost = 2
	charge_time = CHARGETIME_MINOR
	charge_drain = 1
	charge_slowdown = 0.7
	cooldown_time = 15 SECONDS
	spell_cost = 30
	spell_flags = SPELL_RITUOS

	slot_level = 1
	slot_only = TRUE
	slot_label = "Burning Hands"
	required_form = FORM_FIRE
	required_technique = TECHNIQUE_DESTRUCTION
	required_level = MASTERY_RANK_NOVICE
	learnable = TRUE

	/// Burn dealt to each creature the flames reach, before the multipliers.
	var/burn_damage = 20
	/// Fire stacks the flames leave on each creature they reach.
	var/fire_stacks_added = 2
	/// Rank times upcast multiplier, captured at cast since the staggered layers land after it.
	var/tmp/cone_damage_multiplier = 1
	/// Refs of creatures this cast already burned, so one walking with the flames burns once.
	var/tmp/list/burned_refs

/datum/action/cooldown/spell/cone/staggered/burning_hands/cast(atom/cast_on)
	cone_damage_multiplier = get_rank_multiplier() * get_upcast_multiplier()
	burned_refs = null
	return ..()

/datum/action/cooldown/spell/cone/staggered/burning_hands/do_turf_cone_effect(turf/target_turf, atom/caster, level)
	if(isopenturf(target_turf))
		new /obj/effect/temp_visual/fire(target_turf)

/datum/action/cooldown/spell/cone/staggered/burning_hands/do_mob_cone_effect(mob/living/target_mob, atom/caster, level)
	if(target_mob == caster || target_mob.can_block_magic(antimagic_flags))
		return
	var/mob_ref = REF(target_mob)
	if(LAZYACCESS(burned_refs, mob_ref))
		return
	LAZYSET(burned_refs, mob_ref, TRUE)
	if(isliving(caster))
		target_mob.set_damage_attack_context(caster)
	target_mob.take_overall_damage(0, burn_damage * cone_damage_multiplier)
	target_mob.clear_damage_attack_context()
	target_mob.adjust_fire_stacks(fire_stacks_added)
	target_mob.IgniteMob()
	to_chat(target_mob, span_userdanger("Flames wash over me!"))

/datum/action/cooldown/spell/cone/staggered/burning_hands/do_obj_cone_effect(obj/target_obj, atom/caster, level)
	// Each object decides through fire_act; flammable ones catch, torches and hearths light.
	target_obj.fire_act(burn_damage * cone_damage_multiplier)
