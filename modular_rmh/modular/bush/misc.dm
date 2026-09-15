/datum/customizer_entry/body_hair
	var/growth_enabled = FALSE

/datum/customizer_entry/pubic_hair
	var/growth_enabled = FALSE
	var/grooming_state = HAIR_GROOMING_NATURAL

/datum/customizer/bodypart_feature/body_hair
	name = "Body Hair"
	customizer_choices = list(/datum/customizer_choice/bodypart_feature/body_hair)
	allows_disabling = TRUE
	default_disabled = TRUE
	gender_enabled = MALE

/datum/customizer_choice/bodypart_feature/body_hair
	name = "Body Hair"
	feature_type = /datum/bodypart_feature/hair/body_hair
	customizer_entry_type = /datum/customizer_entry/body_hair
	sprite_accessories = list(
		/datum/sprite_accessory/body_hair/body/some_hair,
		/datum/sprite_accessory/body_hair/body/hairy,
		/datum/sprite_accessory/body_hair/body/very_hairy,
	)

/datum/customizer_choice/bodypart_feature/body_hair/make_default_customizer_entry(datum/preferences/prefs, customizer_type, changed_entry = TRUE)
	. = ..()
	var/datum/species/species = return_species(prefs)
	if(species?.hairyness)
		set_accessory_type(prefs, body_hair_species_default_accessory(species), .)

/datum/customizer_choice/bodypart_feature/body_hair/customize_feature(datum/bodypart_feature/feature, mob/living/carbon/human/human, datum/preferences/prefs, datum/customizer_entry/body_hair/entry)
	var/datum/bodypart_feature/hair/body_hair/body_hair_feature = feature
	body_hair_feature.growth_enabled = entry.growth_enabled

/datum/customizer_choice/bodypart_feature/body_hair/generate_pref_choices(list/dat, datum/preferences/prefs, datum/customizer_entry/entry, customizer_type)
	..()
	var/datum/customizer_entry/body_hair/body_hair_entry = entry
	dat += "<br>Growth: <a href='byond://?_src_=prefs;task=change_customizer;customizer=[customizer_type];customizer_task=toggle_body_hair_growth'>[body_hair_entry.growth_enabled ? "Enabled" : "Disabled"]</a>"

/datum/customizer_choice/bodypart_feature/body_hair/handle_topic(mob/user, list/href_list, datum/preferences/prefs, datum/customizer_entry/entry, customizer_type)
	..()
	var/datum/customizer_entry/body_hair/body_hair_entry = entry
	switch(href_list["customizer_task"])
		if("toggle_body_hair_growth")
			body_hair_entry.growth_enabled = !body_hair_entry.growth_enabled

/datum/customizer_choice/bodypart_feature/body_hair/validate_entry(datum/preferences/prefs, datum/customizer_entry/entry)
	..()
	var/datum/customizer_entry/body_hair/body_hair_entry = entry
	if(isnull(body_hair_entry.growth_enabled))
		body_hair_entry.growth_enabled = initial(body_hair_entry.growth_enabled)
	else
		body_hair_entry.growth_enabled = body_hair_entry.growth_enabled ? TRUE : FALSE

/datum/customizer/bodypart_feature/pubic_hair
	name = "Pubic Hair"
	customizer_choices = list(/datum/customizer_choice/bodypart_feature/pubic_hair)

/datum/customizer_choice/bodypart_feature/pubic_hair
	name = "Pubic Hair"
	feature_type = /datum/bodypart_feature/hair/body_hair/pubic
	customizer_entry_type = /datum/customizer_entry/pubic_hair
	sprite_accessories = list(
		/datum/sprite_accessory/body_hair/pubic/shaved,
		/datum/sprite_accessory/body_hair/pubic/stubble,
		/datum/sprite_accessory/body_hair/pubic/some_hair,
		/datum/sprite_accessory/body_hair/pubic/hairy,
		/datum/sprite_accessory/body_hair/pubic/very_hairy,
	)

/datum/customizer_choice/bodypart_feature/pubic_hair/customize_feature(datum/bodypart_feature/feature, mob/living/carbon/human/human, datum/preferences/prefs, datum/customizer_entry/pubic_hair/entry)
	var/datum/bodypart_feature/hair/body_hair/pubic/pubic_hair_feature = feature
	pubic_hair_feature.growth_enabled = entry.growth_enabled
	pubic_hair_feature.grooming_state = entry.grooming_state

/datum/customizer_choice/bodypart_feature/pubic_hair/generate_pref_choices(list/dat, datum/preferences/prefs, datum/customizer_entry/entry, customizer_type)
	..()
	var/datum/customizer_entry/pubic_hair/pubic_hair_entry = entry
	dat += "<br>Growth: <a href='byond://?_src_=prefs;task=change_customizer;customizer=[customizer_type];customizer_task=toggle_pubic_hair_growth'>[pubic_hair_entry.growth_enabled ? "Enabled" : "Disabled"]</a>"
	dat += "<br>Grooming: <a href='byond://?_src_=prefs;task=change_customizer;customizer=[customizer_type];customizer_task=pubic_hair_grooming'>[body_hair_grooming_name(pubic_hair_entry.grooming_state)]</a>"

/datum/customizer_choice/bodypart_feature/pubic_hair/handle_topic(mob/user, list/href_list, datum/preferences/prefs, datum/customizer_entry/entry, customizer_type)
	..()
	var/datum/customizer_entry/pubic_hair/pubic_hair_entry = entry
	switch(href_list["customizer_task"])
		if("toggle_pubic_hair_growth")
			pubic_hair_entry.growth_enabled = !pubic_hair_entry.growth_enabled
		if("pubic_hair_grooming")
			var/list/grooming_choices = body_hair_grooming_choices()
			var/chosen_input = browser_input_list(user, "Choose your grooming state:", "Character Preference", grooming_choices)
			if(!chosen_input)
				return
			pubic_hair_entry.grooming_state = grooming_choices[chosen_input]

/datum/customizer_choice/bodypart_feature/pubic_hair/validate_entry(datum/preferences/prefs, datum/customizer_entry/entry)
	..()
	var/datum/customizer_entry/pubic_hair/pubic_hair_entry = entry
	if(isnull(pubic_hair_entry.growth_enabled))
		pubic_hair_entry.growth_enabled = initial(pubic_hair_entry.growth_enabled)
	else
		pubic_hair_entry.growth_enabled = pubic_hair_entry.growth_enabled ? TRUE : FALSE
	var/list/grooming_states = body_hair_grooming_choices()
	if(!find_key_by_value(grooming_states, pubic_hair_entry.grooming_state))
		pubic_hair_entry.grooming_state = HAIR_GROOMING_NATURAL
