/datum/action/cooldown/spell/undirected/shapeshift/tentacle
	name = "Tentacle Form"
	desc = "Transform into a writhing tentacle mass. Damage is not inherited between forms!"

	attunements = list(
		/datum/attunement/dark = 0.4,
		/datum/attunement/polymorph = 0.6,
		/datum/attunement/blood = 0.2,
	)

	charge_required = FALSE
	cooldown_time = 50 SECONDS

	possible_shapes = list(/mob/living/simple_animal/hostile/retaliate/tentacle)
	die_with_shapeshifted_form = FALSE
	convert_damage = FALSE

/datum/action/cooldown/spell/undirected/shapeshift/tentacle/do_shapeshift(mob/living/caster)
	. = ..()
	if(!.)
		return
	var/mob/living/new_shape = .
	new_shape.adjust_stat_modifier("[REF(src)]", STATKEY_SPD, 15 - GET_MOB_ATTRIBUTE_VALUE(new_shape, STAT_SPEED))
