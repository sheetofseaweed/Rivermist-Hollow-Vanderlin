/datum/action/cooldown/spell/projectile/arcyne_bolt
	name = "Arcane Bolt"
	desc = "Shoot out rapid bolts of arcane power."
	button_icon_state =  "arcane_bolt"
	sound = 'sound/magic/vlightning.ogg'

	cast_range = 12
	point_cost = 2

	invocation = "MAGIC MISSILE!!!"
	invocation_type = INVOCATION_SHOUT
	auto_aim = FALSE

	charge_time = 1 SECONDS
	charge_drain = 1
	charge_slowdown = 1.3
	cooldown_time = 5 SECONDS
	spell_cost = 20
	spell_flags = SPELL_RITUOS
	projectile_type = /obj/projectile/magic/energy/rogue3

	slot_level = 1
	minor_cost = SPELL_MINOR_COST_DEFAULT
	slot_label = "Arcane Bolt"
	required_form = FORM_ARCANE

/datum/action/cooldown/spell/projectile/arcyne_bolt/ready_projectile(obj/projectile/to_fire, atom/target, mob/user, iteration)
	. = ..()
	var/level = get_effect_level()
	if(isnull(level))
		to_fire.damage *= get_rank_multiplier()
		return
	if(level == SPELL_SLOT_MINOR)
		to_fire.damage = 10 * get_cantrip_multiplier()
		to_fire.armor_penetration = 0
		return
	switch(level)
		if(1)
			to_fire.damage = 30
		if(2)
			to_fire.damage = 38
		if(3)
			to_fire.damage = 46
		if(4)
			to_fire.damage = 55
		if(5)
			to_fire.damage = 65
	to_fire.damage *= get_rank_multiplier()
	if(user)
		to_chat(user, span_notice("The [get_slot_label()] forms at spell level [level]."))

/obj/projectile/magic/energy/rogue3
	name = "arcyne bolt"
	icon_state = "arcane_barrage"
	damage = 30
	damage_type = BRUTE
	armor_penetration = 10
	nodamage = FALSE
	flag = "piercing"
	woundclass = BCLASS_PIERCE
	speed = 2
	spread = 4
