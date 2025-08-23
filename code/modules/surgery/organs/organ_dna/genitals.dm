/datum/organ_dna/penis
	var/penis_size = DEFAULT_PENIS_SIZE
	var/functional = TRUE

/datum/organ_dna/penis/imprint_organ(obj/item/organ/organ, datum/species/species)
	..()
	var/obj/item/organ/genitals/penis/penis_organ = organ
	penis_organ.penis_size = penis_size
	penis_organ.functional = functional

/datum/organ_dna/testicles
	var/ball_size = DEFAULT_TESTICLES_SIZE
	var/virility = TRUE

/datum/organ_dna/testicles/imprint_organ(obj/item/organ/organ, datum/species/species)
	..()
	var/obj/item/organ/genitals/testicles/testicles_organ = organ
	testicles_organ.ball_size = ball_size
	testicles_organ.virility = virility

/datum/organ_dna/breasts
	var/breast_size = DEFAULT_BREASTS_SIZE
	var/lactating = FALSE

/datum/organ_dna/breasts/imprint_organ(obj/item/organ/organ, datum/species/species)
	..()
	var/obj/item/organ/genitals/breasts/breasts_organ = organ
	breasts_organ.breast_size = breast_size
	breasts_organ.lactating = lactating
	breasts_organ.milk_max = max(75, breasts_organ.breast_size * 100)

/datum/organ_dna/vagina
	var/fertility = TRUE

/datum/organ_dna/vagina/imprint_organ(obj/item/organ/organ, datum/species/species)
	..()
	var/obj/item/organ/genitals/vagina/vagina_organ = organ
	vagina_organ.fertility = fertility
