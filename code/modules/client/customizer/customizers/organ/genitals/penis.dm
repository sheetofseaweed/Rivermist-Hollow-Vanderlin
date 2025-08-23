/datum/customizer/organ/genitals/penis
	abstract_type = /datum/customizer/organ/genitals/penis
	name = "Penis"
	allows_disabling = TRUE
	default_disabled = TRUE
	gender_enabled = MALE

/datum/customizer/organ/genitals/penis/is_allowed(datum/preferences/prefs)
	return TRUE

/datum/customizer_choice/organ/genitals/penis
	name = "Penis"
	organ_type = /obj/item/organ/genitals/penis
	organ_slot = ORGAN_SLOT_PENIS
	customizer_entry_type = /datum/customizer_entry/organ/genitals/penis
	organ_dna_type = /datum/organ_dna/penis

/datum/customizer_choice/organ/genitals/penis/validate_entry(datum/preferences/prefs, datum/customizer_entry/entry)
	..()
	var/datum/customizer_entry/organ/genitals/penis/penis_entry = entry
	penis_entry.penis_size = sanitize_integer(penis_entry.penis_size, MIN_PENIS_SIZE, MAX_PENIS_SIZE, DEFAULT_PENIS_SIZE)

/datum/customizer_choice/organ/genitals/penis/imprint_organ_dna(datum/organ_dna/organ_dna, datum/customizer_entry/entry, datum/preferences/prefs)
	..()
	var/datum/organ_dna/penis/penis_dna = organ_dna
	var/datum/customizer_entry/organ/genitals/penis/penis_entry = entry
	penis_dna.penis_size = penis_entry.penis_size
	penis_dna.functional = penis_entry.functional

/datum/customizer_choice/organ/genitals/penis/generate_pref_choices(list/dat, datum/preferences/prefs, datum/customizer_entry/entry, customizer_type)
	..()
	var/datum/customizer_entry/organ/genitals/penis/penis_entry = entry
	dat += "<br>Penis size: <a href='?_src_=prefs;task=change_customizer;customizer=[customizer_type];customizer_task=penis_size''>[find_key_by_value(PENIS_SIZES_BY_NAME, penis_entry.penis_size)]</a>"
	dat += "<br>Functional: <a href='?_src_=prefs;task=change_customizer;customizer=[customizer_type];customizer_task=functional''>[penis_entry.functional ? "YES" : "NO"]</a>"

/datum/customizer_choice/organ/genitals/penis/handle_topic(mob/user, list/href_list, datum/preferences/prefs, datum/customizer_entry/entry, customizer_type)
	..()
	var/datum/customizer_entry/organ/genitals/penis/penis_entry = entry
	switch(href_list["customizer_task"])
		if("penis_size")
			var/named_size = browser_input_list(user, "Choose your penis size:", "Character Preference", PENIS_SIZES_BY_NAME, penis_entry.penis_size)
			if(isnull(named_size))
				return
			var/new_size = PENIS_SIZES_BY_NAME[named_size]
			penis_entry.penis_size = sanitize_integer(new_size, MIN_PENIS_SIZE, MAX_PENIS_SIZE, DEFAULT_PENIS_SIZE)
		if("functional")
			penis_entry.functional = !penis_entry.functional

/datum/customizer_entry/organ/genitals/penis
	var/penis_size = DEFAULT_PENIS_SIZE
	var/functional = TRUE

/datum/customizer/organ/genitals/penis/human
	customizer_choices = list(/datum/customizer_choice/organ/genitals/penis/human)

/datum/customizer/organ/genitals/penis/anthro
	customizer_choices = list(
		/datum/customizer_choice/organ/genitals/penis/human_anthro,
		/datum/customizer_choice/organ/genitals/penis/knotted,
		/datum/customizer_choice/organ/genitals/penis/equine,
		/datum/customizer_choice/organ/genitals/penis/tapered_mammal,
		/datum/customizer_choice/organ/genitals/penis/tapered,
		/datum/customizer_choice/organ/genitals/penis/tapered_double,
		/datum/customizer_choice/organ/genitals/penis/tapered_double_knot,
		/datum/customizer_choice/organ/genitals/penis/barbed,
		/datum/customizer_choice/organ/genitals/penis/barbed_knotted,
		/datum/customizer_choice/organ/genitals/penis/tentacle,
		)

/datum/customizer/organ/genitals/penis/canine
	customizer_choices = list(
		/datum/customizer_choice/organ/genitals/penis/human_anthro,
		/datum/customizer_choice/organ/genitals/penis/knotted,
		)

/datum/customizer/organ/genitals/penis/feline
	customizer_choices = list(
		/datum/customizer_choice/organ/genitals/penis/human_anthro,
		/datum/customizer_choice/organ/genitals/penis/barbed,
		/datum/customizer_choice/organ/genitals/penis/barbed_knotted,
		)

/datum/customizer/organ/genitals/penis/lizard
	customizer_choices = list(
		/datum/customizer_choice/organ/genitals/penis/human_anthro,
		/datum/customizer_choice/organ/genitals/penis/tapered,
		/datum/customizer_choice/organ/genitals/penis/tapered_double,
		/datum/customizer_choice/organ/genitals/penis/tapered_double_knot,
		)

/datum/customizer/organ/genitals/penis/equine
	customizer_choices = list(
		/datum/customizer_choice/organ/genitals/penis/human_anthro,
		/datum/customizer_choice/organ/genitals/penis/equine,
		)

/datum/customizer_choice/organ/genitals/penis/human
	name = "Plain Penis"
	organ_type = /obj/item/organ/genitals/penis
	sprite_accessories = list(/datum/sprite_accessory/genitals/penis/human)
	allows_accessory_color_customization = FALSE

/datum/customizer_choice/organ/genitals/penis/human_anthro
	name = "Plain Penis"
	organ_type = /obj/item/organ/genitals/penis
	sprite_accessories = list(/datum/sprite_accessory/genitals/penis/human)
	allows_accessory_color_customization = TRUE

/datum/customizer_choice/organ/genitals/penis/knotted
	name = "Knotted Penis"
	organ_type = /obj/item/organ/genitals/penis/knotted
	sprite_accessories = list(
		/datum/sprite_accessory/genitals/penis/knotted,
		/datum/sprite_accessory/genitals/penis/knotted2,
		)

/datum/customizer_choice/organ/genitals/penis/equine
	name = "Equine Penis"
	organ_type = /obj/item/organ/genitals/penis/equine
	sprite_accessories = list(
		/datum/sprite_accessory/genitals/penis/flared,
		)

/datum/customizer_choice/organ/genitals/penis/tapered_mammal
	name = "Tapered Penis (Mammal)"
	organ_type = /obj/item/organ/genitals/penis/tapered_mammal
	sprite_accessories = list(
		/datum/sprite_accessory/genitals/penis/tapered_mammal,
		)

/datum/customizer_choice/organ/genitals/penis/tapered
	name = "Tapered Penis"
	organ_type = /obj/item/organ/genitals/penis/tapered
	sprite_accessories = list(
		/datum/sprite_accessory/genitals/penis/tapered,
		)

/datum/customizer_choice/organ/genitals/penis/tapered_double
	name = "Hemi Tapered Penis"
	organ_type = /obj/item/organ/genitals/penis/tapered
	sprite_accessories = list(
		/datum/sprite_accessory/genitals/penis/hemi,
		)

/datum/customizer_choice/organ/genitals/penis/tapered_double_knot
	name = "Knotted Hemi Tapered Penis"
	organ_type = /obj/item/organ/genitals/penis/tapered
	sprite_accessories = list(
		/datum/sprite_accessory/genitals/penis/hemiknot,
		)

/datum/customizer_choice/organ/genitals/penis/barbed
	name = "Barbed Penis"
	organ_type = /obj/item/organ/genitals/penis/barbed
	sprite_accessories = list(
		/datum/sprite_accessory/genitals/penis/barbknot,
		)

/datum/customizer_choice/organ/genitals/penis/barbed_knotted
	name = "Barbed Knotted Penis"
	organ_type = /obj/item/organ/genitals/penis/barbed_knotted
	sprite_accessories = list(
		/datum/sprite_accessory/genitals/penis/barbknot,
		)

/datum/customizer_choice/organ/genitals/penis/tentacle
	name = "Tentacle Penis"
	organ_type = /obj/item/organ/genitals/penis/tentacle
	sprite_accessories = list(
		/datum/sprite_accessory/genitals/penis/tentacle,
		)
