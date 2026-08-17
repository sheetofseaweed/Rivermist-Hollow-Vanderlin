/datum/reagent/medicine
	name = "Medicine"
	taste_description = "bitterness"
	random_reagent_color = TRUE
	overdose_threshold = 0

/datum/reagent/medicine/on_mob_life(mob/living/carbon/M, efficiency)
	current_cycle++
	. = ..()

/datum/reagent/medicine/atropine
	name = "Atropine"
	description = "If a patient is in critical condition, rapidly heals all damage types as well as regulating oxygen in the body. Excellent for stabilizing wounded patients, and said to neutralize blood-activated internal explosives found amongst clandestine black op agents."
	reagent_state = LIQUID
	color = "#1D3535" //slightly more blue, like epinephrine
	random_reagent_color = FALSE
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	overdose_threshold = 35

/datum/reagent/medicine/atropine/on_mob_metabolize(mob/living/L)
	. = ..()
	if(!iscarbon(L))
		return
	var/mob/living/carbon/C = L
	var/numbing = min(50, CEILING(C.getShock(TRUE)/2, 1))
	C.add_chem_effect(CE_BLOODRESTORE, 1, "[type]")
	C.add_chem_effect(CE_PAINKILLER, numbing, "[type]")
	C.add_chem_effect(CE_STABLE, 1, "[type]")
	if(C.undergoing_cardiac_arrest() || C.undergoing_nervous_system_failure())
		C.add_chem_effect(CE_ORGAN_REGEN, 1, "[type]")

/datum/reagent/medicine/atropine/on_mob_end_metabolize(mob/living/L)
	. = ..()
	L.remove_chem_effect(CE_BLOODRESTORE, "[type]")
	L.remove_chem_effect(CE_ORGAN_REGEN, "[type]")
	L.remove_chem_effect(CE_PAINKILLER, "[type]")
	L.remove_chem_effect(CE_TOXIN, "[type]")
	L.remove_chem_effect(CE_BLOCKAGE, "[type]")
	L.remove_chem_effect(CE_STABLE, "[type]")

/datum/reagent/medicine/atropine/on_mob_life(mob/living/carbon/affected_mob, efficiency)
	if(affected_mob.health <= 35)
		affected_mob.adjustToxLoss(-5 * REM * efficiency , FALSE)
		affected_mob.adjustBruteLoss(-15* REM * efficiency, FALSE)
		affected_mob.adjustFireLoss(-15 * REM * efficiency, FALSE)
		affected_mob.adjustOxyLoss(-15 * REM * efficiency, FALSE)
		. = TRUE
	if(prob(10))
		affected_mob.set_dizzy(10 SECONDS * efficiency)
		affected_mob.adjust_jitter(10 SECONDS * efficiency)
	..()

/datum/reagent/medicine/atropine/overdose_process(mob/living/affected_mob)
	affected_mob.adjustToxLoss(0.5 * REM, FALSE)
	. = TRUE
	affected_mob.set_dizzy(2 SECONDS * REM)
	affected_mob.adjust_jitter(2 SECONDS * REM)
	..()

/datum/reagent/medicine/charcoal
	name = "Charcoal"
	description = "Heals mild toxin damage as well as slowly removing any other chemicals the patient has in their bloodstream."
	reagent_state = LIQUID
	taste_description = "ash"
	color = "#000000"
	random_reagent_color = FALSE
	metabolization_rate = 0.50 * REAGENTS_METABOLISM

/datum/reagent/medicine/charcoal/on_mob_life(mob/living/affected_mob, efficiency)
	. = ..()
	affected_mob.adjustToxLoss(-1 * REM, 0)
	for(var/datum/reagent/R in affected_mob.reagents.reagent_list)
		if(R != src)
			affected_mob.reagents.remove_reagent(R.type,0.75)

/datum/reagent/medicine/pregplus
	name = "PregPlus"
	description = "A special substance that makes your eggs work in a frenzy"
	reagent_state = LIQUID
	taste_description = "lime"
	color = "#914127"
	random_reagent_color = FALSE
	metabolization_rate = 0.01

/datum/reagent/medicine/vertplus
	name = "VertPlus"
	description = "A special substance that makes your sperm be insanely fertile"
	reagent_state = LIQUID
	taste_description = "Thick orange"
	color = "#b94d0c"
	random_reagent_color = FALSE
	metabolization_rate = 0.05
	var/vitilty_factor = 1

/datum/reagent/medicine/vertplus/on_mob_metabolize(mob/living/M)
	. = ..()
	vitilty_factor = 100
/datum/reagent/medicine/vertplus/on_mob_end_metabolize(mob/living/M)
	. = ..()
	vitilty_factor = 1
