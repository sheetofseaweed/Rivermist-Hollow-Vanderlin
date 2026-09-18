/datum/customizer_choice/organ/eyes/imprint_organ_dna(datum/organ_dna/eyes/eyes_dna, datum/customizer_entry/organ/eyes/eyes_entry, datum/preferences/prefs)
	..()
	eyes_dna.eye_glowing = eyes_entry.eye_glowing

/datum/customizer_choice/organ/eyes/generate_pref_choices(list/dat, datum/preferences/prefs, datum/customizer_entry/organ/eyes/eyes_entry, customizer_type)
	..()
	dat += "<br>Eye Glowing: <a href='byond://?_src_=prefs;task=change_customizer;customizer=[customizer_type];customizer_task=eye_glowing''>[eyes_entry.eye_glowing ? "Yes" : "No"]</a>"

/datum/customizer_choice/organ/eyes/handle_topic(mob/user, list/href_list, datum/preferences/prefs, datum/customizer_entry/organ/eyes/eyes_entry, customizer_type)
	..()
	switch(href_list["customizer_task"]) // Yes, for the sake of consistency
		if("eye_glowing")
			eyes_entry.eye_glowing = !eyes_entry.eye_glowing

/datum/customizer_entry/organ/eyes
	var/eye_glowing = FALSE
