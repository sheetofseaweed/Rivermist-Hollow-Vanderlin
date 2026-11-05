/datum/action/cooldown/spell/undirected/shapeshift/crow
	name = "Crow Form"
	desc = "Transform into a crow to fly."

	charge_required = FALSE
	cooldown_time = 50 SECONDS

	possible_shapes = list(/mob/living/simple_animal/hostile/retaliate/bat/crow)
	die_with_shapeshifted_form = FALSE
