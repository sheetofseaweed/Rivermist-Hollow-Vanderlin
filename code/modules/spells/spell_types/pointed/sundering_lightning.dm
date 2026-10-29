/datum/action/cooldown/spell/sundering_lightning
	name = "Sundering Lightning"
	desc = "Summons forth dangerous rapid lightning strikes."
	button_icon_state = "sundering"
	sound = 'sound/weather/rain/thunder_1.ogg'

	point_cost = 8
	cast_range = 4

	invocation = "Lightning strikes more than twice!"
	invocation_type = INVOCATION_SHOUT

	spell_flags = SPELL_RITUOS
	charge_time = 3.5 SECONDS
	charge_drain = 1
	charge_slowdown = 1.3
	cooldown_time = 1.5 MINUTES
	spell_cost = 60

	slot_level = 4
	slot_only = TRUE
	slot_label = "Sundering Lightning"
	required_form = FORM_LIGHTNING
	required_technique = TECHNIQUE_DESTRUCTION
	required_level = MASTERY_RANK_MASTER
	prerequisite_spells = list(/datum/action/cooldown/spell/projectile/lightning)

	/// Shock damage of each strike at the spell's own level.
	var/strike_damage = 50

/datum/action/cooldown/spell/sundering_lightning/cast(atom/cast_on)
	. = ..()
	// The strikes fall after the cast ends, so the upcast damage is read now.
	addtimer(CALLBACK(src, PROC_REF(create_lightning), get_turf(cast_on), get_strike_damage()), 3 SECONDS)

/// Strike damage for the cast in progress; each upcast level adds a quarter.
/datum/action/cooldown/spell/sundering_lightning/proc/get_strike_damage()
	return strike_damage * get_upcast_multiplier()

/datum/action/cooldown/spell/sundering_lightning/proc/create_lightning(turf/victim, shock_damage = 50)
	var/last_dist = 0
	for(var/turf/T as anything in spiral_range_turfs(4, victim))
		if(T.density)
			continue
		var/dist = get_dist(victim, T)
		if(dist > last_dist)
			last_dist = dist
			sleep(2 + min(4 - last_dist, 12) * 0.5)
		new /obj/effect/temp_visual/target/lightning/sundering(T, null, shock_damage)

/// A strike that carries its cast's shock damage.
/obj/effect/temp_visual/target/lightning/sundering
	/// Shock damage dealt to everyone on the turf when the strike lands.
	var/shock_damage = 50

/obj/effect/temp_visual/target/lightning/sundering/Initialize(mapload, list/hit_atoms, shock_damage = 50)
	src.shock_damage = shock_damage
	return ..()

/obj/effect/temp_visual/target/lightning/sundering/fall(list/hit_atoms)
	var/turf/T = get_turf(src)
	sleep(duration)
	playsound(T, 'sound/magic/lightning.ogg', 80, TRUE)
	new /obj/effect/temp_visual/lightning(T)
	for(var/mob/living/L in T)
		L.electrocute_act(shock_damage)
