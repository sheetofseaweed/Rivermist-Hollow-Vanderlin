/datum/action/cooldown/spell/projectile/sickness
	name = "Ray of Sickness"
	desc = "Fire a toxic projectile at the living."
	button_icon_state = "raiseskele"
	sound = 'sound/misc/portal_enter.ogg'

	charge_time = 2 SECONDS
	charge_drain = 1
	charge_slowdown = 0.3
	cooldown_time = 10 SECONDS
	spell_cost = 30

	projectile_type = /obj/projectile/magic/sickness

	slot_level = 1
	minor_cost = SPELL_MINOR_COST_DEFAULT
	slot_label = "Ray of Sickness"
	required_form = FORM_DEATH
	required_technique = TECHNIQUE_DESTRUCTION

/datum/action/cooldown/spell/projectile/sickness/ready_projectile(obj/projectile/to_fire, atom/target, mob/user, iteration)
	. = ..()
	var/level = get_effect_level()
	if(isnull(level))
		return
	if(level == SPELL_SLOT_MINOR)
		to_fire.damage = 8 * get_cantrip_multiplier()
		return
	to_fire.damage = round((10 + 5 * level) * get_rank_multiplier())
	if(user)
		to_chat(user, span_notice("The [get_slot_label()] forms at spell level [level]."))

/obj/projectile/magic/sickness
	name = "Bolt of Sickness"
	icon_state = "xray"
	damage = 15
	damage_type = TOX

/obj/projectile/magic/sickness/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(target.reagents)
		target.reagents.add_reagent(/datum/reagent/toxin, 5)
