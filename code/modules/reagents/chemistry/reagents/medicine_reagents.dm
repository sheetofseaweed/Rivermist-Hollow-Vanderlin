/datum/reagent/medicine
	name = "Medicine"
	taste_description = "bitterness"
	random_reagent_color = TRUE
	overdose_threshold = 0

/datum/reagent/medicine/on_mob_life(mob/living/carbon/M, efficiency)
	current_cycle++
	. = ..()

/datum/reagent/medicine/atropine
	name = "Nightshade Mercy"
	description = "A carefully measured nightshade tincture that steadies failing hearts and breathing. It is a rescue medicine, not a substitute for proper treatment."
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
		var/rescue_multiplier = affected_mob.health <= affected_mob.crit_threshold ? 2 : 1
		affected_mob.adjustToxLoss(-1 * REM * efficiency * rescue_multiplier, FALSE)
		affected_mob.adjustBruteLoss(-1 * REM * efficiency * rescue_multiplier, FALSE)
		affected_mob.adjustFireLoss(-1 * REM * efficiency * rescue_multiplier, FALSE)
		affected_mob.adjustOxyLoss(-4 * REM * efficiency * rescue_multiplier, FALSE)
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
	name = "Black Draught"
	description = "A suspension of finely prepared wood charcoal. It eases mild poisoning while indiscriminately drawing other substances from the blood."
	reagent_state = LIQUID
	taste_description = "coal"
	color = "#000000"
	random_reagent_color = FALSE
	metabolization_rate = 0.50 * REAGENTS_METABOLISM

/datum/reagent/medicine/charcoal/on_mob_life(mob/living/affected_mob, efficiency)
	. = ..()
	affected_mob.adjustToxLoss(-1 * REM * efficiency, 0)
	for(var/datum/reagent/R in affected_mob.reagents.reagent_list)
		if(R != src)
			affected_mob.reagents.remove_reagent(R.type, 0.5 * efficiency)

/datum/reagent/medicine/pregplus
	name = "Pregnancy Potion"
	description = "An essence draught invoking the Nurturing Matriarch's fertile blessing for a brief, certain season."
	reagent_state = LIQUID
	taste_description = "warm grain and spring water"
	color = "#914127"
	random_reagent_color = FALSE
	metabolization_rate = 0.04 * REAGENTS_METABOLISM

/datum/reagent/medicine/pregplus/on_mob_metabolize(mob/living/M)
	. = ..()
	M.apply_status_effect(/datum/status_effect/buff/yondallas_quickening)

/datum/reagent/medicine/pregplus/on_mob_end_metabolize(mob/living/M)
	. = ..()
	M.remove_status_effect(/datum/status_effect/buff/yondallas_quickening)

/datum/reagent/medicine/vertplus
	name = "Vertil"
	description = "An essence draught kindled with the Morninglord's vigor, granting a brief season of certain virility."
	reagent_state = LIQUID
	taste_description = "honeyed citrus and warm spice"
	color = "#b94d0c"
	random_reagent_color = FALSE
	metabolization_rate = 0.06 * REAGENTS_METABOLISM

/datum/reagent/medicine/vertplus/on_mob_metabolize(mob/living/M)
	. = ..()
	M.apply_status_effect(/datum/status_effect/buff/lathanders_seed)

/datum/reagent/medicine/vertplus/on_mob_end_metabolize(mob/living/M)
	. = ..()
	M.remove_status_effect(/datum/status_effect/buff/lathanders_seed)
