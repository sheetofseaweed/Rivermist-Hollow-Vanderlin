/datum/organ_dna/penis
	var/penis_size = DEFAULT_PENIS_SIZE
	var/functional = TRUE
	var/is_ovipositor = FALSE
	var/egg_type = null

/datum/organ_dna/penis/imprint_organ(obj/item/organ/organ, datum/species/species)
	..()
	var/obj/item/organ/genitals/penis/penis_organ = organ
	penis_organ.organ_size = penis_size
	penis_organ.functional = functional

/datum/organ_dna/testicles
	var/ball_size = DEFAULT_TESTICLES_SIZE
	var/virility = TRUE

/datum/organ_dna/testicles/imprint_organ(obj/item/organ/organ, datum/species/species)
	..()
	var/obj/item/organ/genitals/filling_organ/testicles/testicles_organ = organ
	testicles_organ.organ_size = ball_size
	testicles_organ.virility = virility

/datum/organ_dna/breasts
	var/breast_size = DEFAULT_BREASTS_SIZE
	var/lactating = FALSE

/datum/organ_dna/breasts/imprint_organ(obj/item/organ/organ, datum/species/species)
	..()
	var/obj/item/organ/genitals/filling_organ/breasts/breasts_organ = organ
	breasts_organ.organ_size = breast_size
	breasts_organ.produces_fluid = lactating

/datum/organ_dna/vagina
	var/fertility = TRUE

/datum/organ_dna/vagina/imprint_organ(obj/item/organ/organ, datum/species/species)
	..()
	var/obj/item/organ/genitals/filling_organ/vagina/vagina_organ = organ
	vagina_organ.fertility = fertility

/datum/organ_dna/butt
	var/butt_size = DEFAULT_BUTT_SIZE

/datum/organ_dna/butt/imprint_organ(obj/item/organ/organ, datum/species/species)
	..()
	var/obj/item/organ/genitals/butt/butt_organ = organ
	butt_organ.organ_size = butt_size

/datum/organ_dna/belly
	var/belly_size = DEFAULT_BELLY_SIZE

/datum/organ_dna/belly/imprint_organ(obj/item/organ/organ, datum/species/species)
	..()
	var/obj/item/organ/genitals/belly/belly_organ = organ
	belly_organ.organ_size = belly_size
	belly_organ.resting_size = belly_size
