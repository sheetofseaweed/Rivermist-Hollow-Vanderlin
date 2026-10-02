/// Every selectable undies and bra has each worn state that build_worn_icon() asks for.
/datum/unit_test/underwear_worn_states/Run()
	var/list/custom_ids = list(null)
	for(var/species_id in GLOB.roundstart_species)
		var/datum/species/species_type = GLOB.species_list[species_id]
		if(initial(species_type.custom_clothes))
			custom_ids |= initial(species_type.custom_id) || species_id
	TEST_ASSERT(SPEC_ID_DWARF in custom_ids, "Small playable species should draw their clothes from the [SPEC_ID_DWARF] states.")

	var/list/worn_types = get_global_selectable_undies() + get_global_selectable_bras()
	for(var/obj/item/clothing/worn_type as anything in worn_types)
		if(isnull(worn_type))
			continue
		var/icon_file = initial(worn_type.mob_overlay_icon)
		var/icon_state = initial(worn_type.icon_state)
		var/boob_sized = initial(worn_type.boob_sized)
		// Suffix order mirrors build_worn_icon(): _f, then _B[size], then _[custom id].
		for(var/female in (initial(worn_type.gendered) ? list(FALSE, TRUE) : list(FALSE)))
			for(var/breast_size in 0 to (boob_sized ? MAX_BREASTS_SIZE : 0))
				for(var/custom_id in custom_ids)
					var/state = "[icon_state][female ? "_f" : ""][breast_size ? "_B[breast_size]" : ""][custom_id ? "_[custom_id]" : ""]"
					if(!icon_exists(icon_file, state))
						TEST_FAIL("[worn_type] has no worn state \"[state]\" in [icon_file || "no mob_overlay_icon"].")
