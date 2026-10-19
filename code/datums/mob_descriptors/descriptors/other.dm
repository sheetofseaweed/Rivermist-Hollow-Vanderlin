/datum/mob_descriptor/age
	name = "Age"
	slot = MOB_DESCRIPTOR_SLOT_AGE
	verbage = "looks"

/datum/mob_descriptor/age/can_describe(mob/living/described)
	if(!ishuman(described))
		return FALSE
	return TRUE

/datum/mob_descriptor/age/get_description(mob/living/described)
	var/mob/living/carbon/human/human = described
	switch(human.age)
		if(AGE_OLD)
			return "old"
		if(AGE_MIDDLEAGED)
			return "middle-aged"
	//ADULT and IMMORTAL
	return "of adult age"

/datum/mob_descriptor/penis
	name = "penis"
	slot = MOB_DESCRIPTOR_SLOT_PENIS
	verbage = "has"
	show_obscured = TRUE

/datum/mob_descriptor/penis/can_describe(mob/living/described)
	if(!ishuman(described))
		return FALSE
	var/mob/living/carbon/human/H = described
	var/obj/item/organ/genitals/penis/penis = H.getorganslot(ORGAN_SLOT_PENIS)
	if(!penis)
		return FALSE
	if(!get_location_accessible(H, BODY_ZONE_PRECISE_GROIN))
		return FALSE
	return TRUE

/datum/mob_descriptor/penis/get_description(mob/living/described)
	var/mob/living/carbon/human/H = described
	var/obj/item/organ/genitals/penis/penis = H.getorganslot(ORGAN_SLOT_PENIS)
	if(!penis)
		return
	var/adjective
	var/arousal_modifier
	switch(penis.organ_size)
		if(1)
			adjective = "a small"
		if(2)
			adjective = "an average"
		if(3)
			adjective = "a large"
	var/list/arousal_data = list()
	SEND_SIGNAL(H, COMSIG_SEX_GET_AROUSAL, arousal_data)
	switch(arousal_data["arousal"])
		if(80 to INFINITY)
			arousal_modifier = ", throbbing violently"
		if(50 to 80)
			arousal_modifier = ", turgid and leaky"
		if(20 to 50)
			arousal_modifier = ", stiffened and twitching"
		else
			arousal_modifier = ", soft and flaccid"
	var/used_name
	if(penis.erect_state != ERECT_STATE_HARD && penis.sheath_type != SHEATH_TYPE_NONE)
		switch(penis.sheath_type)
			if(SHEATH_TYPE_NORMAL)
				if(penis.organ_size == 3)
					used_name = "a fat sheath"
				else
					used_name = "a sheath"
			if(SHEATH_TYPE_SLIT)
				used_name = "a genital slit"
	else
		used_name = "[adjective] [penis.name][arousal_modifier]"
	return "[used_name][H.get_pubic_hair_clause(ORGAN_SLOT_PENIS)]"

/datum/mob_descriptor/testicles
	name = "balls"
	slot = MOB_DESCRIPTOR_SLOT_TESTICLES
	verbage = "has"
	show_obscured = TRUE

/datum/mob_descriptor/testicles/can_describe(mob/living/described)
	if(!ishuman(described))
		return FALSE
	var/mob/living/carbon/human/H = described
	var/obj/item/organ/genitals/filling_organ/testicles/testes = H.getorganslot(ORGAN_SLOT_TESTICLES)
	if(!testes)
		return FALSE
	if(!get_location_accessible(H, BODY_ZONE_PRECISE_GROIN))
		return FALSE
	var/obj/item/organ/genitals/penis/penis = H.getorganslot(ORGAN_SLOT_PENIS)
	if(penis && penis.sheath_type == SHEATH_TYPE_SLIT) //If our penis hides in a slit, dont describe testicles
		return FALSE
	return TRUE

/datum/mob_descriptor/testicles/get_description(mob/living/described)
	var/mob/living/carbon/human/H = described
	var/obj/item/organ/genitals/filling_organ/testicles/testes = H.getorganslot(ORGAN_SLOT_TESTICLES)
	if(!testes)
		return
	var/adjective
	switch(testes.get_visible_size())
		if(1)
			adjective = "a small"
		if(2)
			adjective = "an average"
		if(3)
			adjective = "a large"
		if(4)
			adjective = "a huge"
		if(5)
			adjective = "a massive"
		if(6)
			adjective = "an enormous"
	var/fullness = testes.get_fullness_description()
	return "[adjective] pair of balls[fullness ? ", [fullness]" : ""][H.get_pubic_hair_clause(ORGAN_SLOT_TESTICLES)]"

/datum/mob_descriptor/butt
	name = "butt"
	slot = MOB_DESCRIPTOR_SLOT_BUTT
	verbage = "has"
	show_obscured = FALSE

/datum/mob_descriptor/butt/can_describe(mob/living/described)
	if(!ishuman(described))
		return FALSE
	var/mob/living/carbon/human/H = described
	var/obj/item/organ/genitals/butt/buttie = H.getorganslot(ORGAN_SLOT_BUTT)
	if(!buttie)
		return FALSE
	if(!get_location_accessible(H, BODY_ZONE_PRECISE_GROIN))
		return FALSE
	return TRUE

/datum/mob_descriptor/butt/get_description(mob/living/described)
	var/mob/living/carbon/human/H = described
	var/obj/item/organ/genitals/butt/buttie = H.getorganslot(ORGAN_SLOT_BUTT)
	if(!buttie)
		return
	var/adjective
	switch(buttie.organ_size)
		if(0)
			adjective = "a flat"
		if(1)
			adjective = "a small"
		if(2)
			adjective = "an average"
		if(3)
			adjective = "a large"
		if(4)
			adjective = "a massive"
		if(5)
			adjective = "a colossal"
	return "[adjective] ass"

/datum/mob_descriptor/vagina
	name = "vagina"
	slot = MOB_DESCRIPTOR_SLOT_VAGINA
	verbage = "has"
	show_obscured = TRUE

/datum/mob_descriptor/vagina/can_describe(mob/living/described)
	if(!ishuman(described))
		return FALSE
	var/mob/living/carbon/human/H = described
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = H.getorganslot(ORGAN_SLOT_VAGINA)
	if(!vagina)
		return FALSE
	if(!get_location_accessible(H, BODY_ZONE_PRECISE_GROIN))
		return FALSE
	return TRUE

/datum/mob_descriptor/vagina/get_description(mob/living/described)
	var/mob/living/carbon/human/H = described
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = H.getorganslot(ORGAN_SLOT_VAGINA)
	if(!vagina)
		return
	var/vagina_type = "vagina"
	var/arousal_modifier
	switch(vagina.accessory_type)
		if(/datum/sprite_accessory/genitals/vagina/human)
			vagina_type = "plain vagina"
		if(/datum/sprite_accessory/genitals/vagina/spade)
			vagina_type = "spade vagina"
		if(/datum/sprite_accessory/genitals/vagina/gaping)
			vagina_type = "gaping vagina"
		if(/datum/sprite_accessory/genitals/vagina/cloaca)
			vagina_type = "cloaca"
	var/list/arousal_data = list()
	SEND_SIGNAL(H, COMSIG_SEX_GET_AROUSAL, arousal_data)
	switch(arousal_data["arousal"])
		if(80 to INFINITY)
			arousal_modifier = ", gushing with arousal"
		if(50 to 80)
			arousal_modifier = ", slickened with arousal"
		if(20 to 50)
			arousal_modifier = ", wet with arousal"
	return "a [vagina_type][arousal_modifier][H.get_pubic_hair_clause(ORGAN_SLOT_VAGINA)]"

/datum/mob_descriptor/breasts
	name = "breasts"
	slot = MOB_DESCRIPTOR_SLOT_BREASTS
	verbage = "has"
	show_obscured = TRUE

/datum/mob_descriptor/breasts/can_describe(mob/living/described)
	if(!ishuman(described))
		return FALSE
	var/mob/living/carbon/human/H = described
	var/obj/item/organ/genitals/filling_organ/breasts/breasts = H.getorganslot(ORGAN_SLOT_BREASTS)
	if(!breasts)
		return FALSE
	if(H.underwear && H.underwear.covers_breasts)
		return FALSE
	if(!get_location_accessible(H, BODY_ZONE_CHEST))
		return FALSE
	return TRUE

/datum/mob_descriptor/breasts/get_description(mob/living/described)
	var/mob/living/carbon/human/H = described
	var/obj/item/organ/genitals/filling_organ/breasts/breasts = H.getorganslot(ORGAN_SLOT_BREASTS)
	if(!breasts)
		return
	var/adjective
	switch(breasts.get_visible_size())
		if(0)
			adjective = "a flat"
		if(1)
			adjective = "a very small"
		if(2)
			adjective = "a small"
		if(3)
			adjective = "an average"
		if(4)
			adjective = "a large"
		if(5)
			adjective = "an enormous"
		if(6)
			adjective = "a towering"
		if(7)
			adjective = "a gigantic"
		if(8)
			adjective = "a titanic"
	var/fullness = breasts.get_fullness_description()
	return "[adjective] pair of breasts[fullness ? ", [fullness]" : ""]"
