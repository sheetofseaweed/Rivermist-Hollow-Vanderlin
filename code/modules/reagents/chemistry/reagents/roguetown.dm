/datum/reagent/rogueacid
	name = "Acid"
	description = "."
	reagent_state = LIQUID
	color = "#5eff00"
	taste_description = "burning"
	self_consuming = TRUE

/datum/reagent/rogueacid/reaction_mob(mob/living/M, method=TOUCH, reac_volume)
	M.adjustFireLoss(35, 0)
	..()

/datum/reagent/blastpowder
	name = "Blastpowder"
	description = "."
	reagent_state = SOLID
	color = "#6b0000"
	taste_description = "spicy"
	self_consuming = TRUE
