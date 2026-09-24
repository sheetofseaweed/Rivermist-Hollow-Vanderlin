// Oozes have a neural core, but no bones to fracture.
/datum/injury/ooze
	desc = "membrasion"
	damage_type = WOUND_SLASH
	bleed_rate = 0
	bleed_threshold = INFINITY
	infection_rate = 0.5
	autoheal_cutoff = INFINITY
	base_autoheal_amount = 0.5
	stages = list(
		"massive membrasion" = 70,
		"wide membrasion" = 50,
		"membrasion" = 25,
		"small membrasion" = 10,
		"healing membrane" = 0,
	)

/datum/wound/slime
	abstract_type = /datum/wound/slime
	category = "Ooze"
	critical = TRUE
	sleep_healing = 1
	bleed_rate = null
	ignore_bloody = TRUE
	associated_bclasses = FRACTURE_BCLASSES
	viable_zones = list(BODY_ZONE_HEAD)

/datum/wound/slime/can_apply_to_bodypart(obj/item/bodypart/affected)
	if(!istype(affected?.owner?.dna?.species, /datum/species/ooze))
		return FALSE
	return ..()

/datum/wound/slime/can_stack_with(datum/wound/other)
	return !istype(other, type)

/datum/wound/slime/rupture
	name = "neural core rupture"
	check_name = "<span class='bone'><B>RUPTURE!</B></span>"
	severity = WOUND_SEVERITY_SEVERE
	crit_message = list("Ooze leaks from the neural core!", "The neural core is pierced!", "The neural core is torn!")
	whp = 20
	woundpain = 60

/datum/wound/slime/rupture/on_mob_gain(mob/living/affected)
	. = ..()
	affected.Unconscious(4 SECONDS)

/datum/wound/slime/shattered
	name = "shattered neural core"
	check_name = "<span class='bone'><B>SHATTERED!</B></span>"
	severity = WOUND_SEVERITY_CRITICAL
	crit_message = list("THE NEURAL CORE SHATTERS!", "THE NEURAL CORE SPLITS IN HALF!", "THE NEURAL CORE CAVES IN!")
	whp = 40
	woundpain = 100

/datum/wound/slime/shattered/on_mob_gain(mob/living/affected)
	. = ..()
	ADD_TRAIT(affected, TRAIT_PARALYSIS, "[type]")
	ADD_TRAIT(affected, TRAIT_NOPAIN, "[type]")

/datum/wound/slime/shattered/on_mob_loss(mob/living/affected)
	. = ..()
	REMOVE_TRAIT(affected, TRAIT_PARALYSIS, "[type]")
	REMOVE_TRAIT(affected, TRAIT_NOPAIN, "[type]")
