#define VAGINA_MAX_UNITS 20
#define VAGINA_BASE_PREGNANCY_CHANCE 20
#define VAGINA_KNOT_PREGNANCY_MAX_BONUS 90

/datum/erp_sex_organ/vagina
	erp_organ_type = SEX_ORGAN_VAGINA
	var/can_be_pregnant = FALSE
	var/pregnant = FALSE
	active_arousal = 1.0
	passive_arousal = 1.15
	active_pain = 0.1
	passive_pain = 0.2

/datum/erp_sex_organ/vagina/New(obj/item/organ/genitals/filling_organ/vagina/V)
	. = ..(V)
	can_be_pregnant = V.fertility
	storage = new(VAGINA_MAX_UNITS, src)

/datum/erp_sex_organ/vagina/proc/on_climax(mob/living/carbon/human/father, arousal, knot_bonus = 0)
	if(pregnant || !can_be_pregnant || !father)
		return

	var/mob/living/carbon/human/mother = host
	if(!istype(mother))
		return

	if(!mother.is_fertile() || !father.is_virile())
		return

	var/chance = VAGINA_BASE_PREGNANCY_CHANCE
	chance += clamp(knot_bonus, 0, VAGINA_KNOT_PREGNANCY_MAX_BONUS)

	if(prob(clamp(chance, 0, 90)))
		pregnant = TRUE
		var/obj/item/organ/genitals/filling_organ/vagina/V = src.host
		if(V && hascall(V, "be_impregnated"))
			call(V, "be_impregnated")()
		to_chat(mother, span_love("Я чувствую тепло в животе… кажется, я беременна."))

#undef VAGINA_MAX_UNITS
#undef VAGINA_BASE_PREGNANCY_CHANCE
#undef VAGINA_KNOT_PREGNANCY_MAX_BONUS
