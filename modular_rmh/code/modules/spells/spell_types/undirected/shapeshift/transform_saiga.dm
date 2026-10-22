/datum/action/cooldown/spell/undirected/shapeshift/saiga
	name = "Saiga Form"
	desc = "Transform into a saiga. Damage is not inherited between forms."

	charge_required = FALSE
	cooldown_time = 50 SECONDS

	possible_shapes = list(/mob/living/simple_animal/hostile/retaliate/saiga)
	die_with_shapeshifted_form = FALSE
	convert_damage = FALSE

/datum/action/cooldown/spell/undirected/shapeshift/saiga/do_shapeshift(mob/living/caster)
	. = ..()
	if(!.)
		return
	var/mob/living/new_shape = .
	new_shape.adjust_stat_modifier("[REF(src)]", STATKEY_SPD, 15 - GET_MOB_ATTRIBUTE_VALUE(new_shape, STAT_SPEED))
