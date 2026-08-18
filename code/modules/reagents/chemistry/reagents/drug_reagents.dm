/datum/reagent/drug
	name = "Drug"
	metabolization_rate = 0.1
	taste_description = "bitterness"
	var/trippy = TRUE //Does this drug make you trip?

/datum/reagent/drug/space_drugs
	name = "Space drugs"
	description = "An illegal chemical compound used as drug."
	color = "#60A584" // rgb: 96, 165, 132
	overdose_threshold = 30

/datum/reagent/drug/space_drugs/on_mob_life(mob/living/carbon/M, efficiency)
	M.set_drugginess(30 SECONDS * efficiency)
	if(prob(5))
		if(M.gender == FEMALE)
			M.emote(pick("twitch_s","giggle"))
		else
			M.emote(pick("twitch_s","chuckle"))
	if(M.has_quirk(/datum/quirk/vice/smoker))
		M.sate_addiction(/datum/quirk/vice/smoker)
	..()

/datum/reagent/drug/space_drugs/on_mob_metabolize(mob/living/M)
	..()
	M.set_drugginess(30 SECONDS)
	M.apply_status_effect(/datum/status_effect/buff/weed)
	M.overlay_fullscreen("weedsm", /atom/movable/screen/fullscreen/weedsm)

/datum/reagent/drug/space_drugs/on_mob_end_metabolize(mob/living/M)
	M.set_drugginess(0)
	M.clear_fullscreen("weedsm")
	M.remove_status_effect(/datum/status_effect/buff/weed)

/atom/movable/screen/fullscreen/weedsm
	icon_state = "smok"
	plane = BLACKNESS_PLANE
	layer = AREA_LAYER
	blend_mode = 0
	alpha = 100
	show_when_dead = FALSE

/atom/movable/screen/fullscreen/weedsm/Initialize()
	. = ..()
//			if(L.has_status_effect(/datum/status_effect/buff/weed))
	filters += filter(type="angular_blur",x=5,y=5,size=1)

/datum/reagent/drug/space_drugs/overdose_start(mob/living/M)
	. = ..()
	to_chat(M, "<span class='danger'>I start tripping hard!</span>")

/datum/reagent/drug/space_drugs/overdose_process(mob/living/M)
	M.adjustToxLoss(0.1*REM, 0)
	M.adjustOxyLoss(1.1*REM, 0)
	..()

/datum/reagent/drug/nicotine
	name = "Nicotine"
	description = "Slightly reduces stun times. If overdosed it will deal toxin and oxygen damage."
	reagent_state = LIQUID
	color = "#60A584" // rgb: 96, 165, 132
	addiction_threshold = 999
	taste_description = "smoke"
	trippy = FALSE
	overdose_threshold=999
	metabolization_rate = 0.1 * REAGENTS_METABOLISM


/datum/reagent/drug/nicotine/on_mob_end_metabolize(mob/living/M)
//	M.remove_stress(/datum/stress_event/pweed)
	..()

/datum/reagent/drug/nicotine/on_mob_metabolize(mob/living/M)
	var/mob/living/carbon/V = M
	V.add_stress(/datum/stress_event/pweed)
	..()

/datum/reagent/drug/nicotine/on_mob_life(mob/living/carbon/M, efficiency)
	if(M.has_quirk(/datum/quirk/vice/smoker))
		M.sate_addiction(/datum/quirk/vice/smoker)
	..()
	. = 1

/datum/reagent/drug/nicotine/overdose_process(mob/living/M)
	M.adjustToxLoss(0.1*REM, 0)
	M.adjustOxyLoss(1.1*REM, 0)
	..()
	. = 1

/datum/reagent/drug/skum
	name = "Skum"
	description = "A mixture of ozium and pure moon dust, a highly addictive and rewarding drug"
	color = "#878178"
	taste_description = "Bliss"
	overdose_threshold = 10
	metabolization_rate = 0.2

/datum/reagent/drug/skum/on_mob_life(mob/living/carbon/M, efficiency)
	. = ..()
	M.set_drugginess(90 SECONDS * efficiency)
	if(prob(5))
		if(M.gender == FEMALE)
			M.emote(pick("giggle", "twitch_s"))
		else
			M.emote(pick("chuckle", "twitch_s"))

/datum/reagent/drug/skum/on_mob_metabolize(mob/living/M)
	..()
	M.set_drugginess(90 SECONDS)
	M.apply_status_effect(/datum/status_effect/buff/skum)
	M.overlay_fullscreen("weedsm", /atom/movable/screen/fullscreen/weedsm)

/datum/reagent/drug/skum/on_mob_end_metabolize(mob/living/M)
	M.set_drugginess(0)
	M.clear_fullscreen("weedsm")
	M.remove_status_effect(/datum/status_effect/buff/skum)

/datum/reagent/drug/skum/overdose_process(mob/living/M)
	M.adjustOrganLoss(ORGAN_SLOT_HEART,0.25*REM, 0)
	. = ..()

/datum/reagent/drug/skum/overdose_start(mob/living/M)
	M.playsound_local(get_turf(M), 'sound/misc/heroin_rush.ogg', 100, FALSE)
	M.visible_message(span_warning("Blood runs from [M]'s nose."))

/datum/reagent/drug/bimb
	name = "Bimb"
	description = "A light pink substance that turns you into an incredibly dumb creature"
	color = "#f594ef"
	taste_description = "Dumb-pink"
	overdose_threshold = 25
	metabolization_rate = 0.1

/datum/reagent/drug/bimb/on_mob_metabolize(mob/living/M)
	. = ..()
	M.apply_status_effect(/datum/status_effect/debuff/dumb)

/datum/reagent/drug/bimb/on_mob_end_metabolize(mob/living/M)
	. = ..()
	M.remove_status_effect(/datum/status_effect/debuff/dumb)

/datum/reagent/drug/madness
	name = "Madness"
	description = "A mixture of mushrooms and an unknown liquid"
	color = "#9a1e54"
	taste_description = "Mushroom"
	metabolization_rate = 0.5
	var/hallucination_prob = 25
	var/atom/movable/screen/fullscreen/maniac/hallucinations

/datum/reagent/drug/madness/on_mob_metabolize(mob/living/M)
	. = ..()
	hallucinations = M.overlay_fullscreen("maniac", /atom/movable/screen/fullscreen/maniac)

/datum/reagent/drug/madness/on_mob_end_metabolize(mob/living/M)
	. = ..()
	hallucinations = null

