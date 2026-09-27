/obj/item/organ/genitals/filling_organ/testicles
	name = "testicles"
	icon_state = "testicles"
	visible_organ = TRUE
	zone = BODY_ZONE_PRECISE_GROIN
	slot = ORGAN_SLOT_TESTICLES
	accessory_type = /datum/sprite_accessory/genitals/testicles/pair
	altnames = list("balls", "testicles", "testes", "orbs", "cum tanks", "seed tanks") //used in thought messages.
	organ_size = DEFAULT_TESTICLES_SIZE
	var/virility = TRUE
	reagent_to_make = /datum/reagent/consumable/cum
	production_rate = 3
	storage_per_size = 75
	startsfilled = TRUE
	allows_oviposition_pregnancy = FALSE
	blocker = ITEM_SLOT_PANTS
	organ_sizeable  = TRUE
	produces_fluid = TRUE
	can_engorge = TRUE

/obj/item/organ/genitals/filling_organ/testicles/invisible //so it can be surgically removed but still not visible on sprite
	accessory_type = /datum/sprite_accessory/none

/obj/item/organ/genitals/filling_organ/testicles/internal
	name = "internal testicles"
	visible_organ = FALSE
	accessory_type = /datum/sprite_accessory/none

/obj/item/organ/genitals/filling_organ/testicles/Insert(mob/living/M, special, drop_if_replaced, new_zone = null)
	set_reagent_to_make(M?.cum || reagent_to_make)
	. = ..()
	if(!.)
		return FALSE
	add_bodystorage(M, null, /datum/component/body_storage/testicles)
	sync_cum_source_data()

/obj/item/organ/genitals/filling_organ/testicles/set_reagent_to_make(datum/reagent/new_reagent)
	if(!virility)
		new_reagent = /datum/reagent/consumable/cum/sterile
	return ..(new_reagent)

/obj/item/organ/genitals/filling_organ/testicles/Remove(mob/living/M, special, drop_if_replaced)
	. = ..()
	var/datum/component/body_storage/testicles/comp = GetComponent(/datum/component/body_storage/testicles)
	comp?.RemoveComponent()
	qdel(comp)

/obj/item/organ/genitals/filling_organ/testicles/process_fluids(seconds)
	. = ..()
	sync_cum_source_data()

/obj/item/organ/genitals/filling_organ/testicles/get_base_climax_release(climax_location)
	switch(climax_location)
		if(ORGASM_LOCATION_ONTO)
			return min(reagents.maximum_volume / 2, 10 * organ_size)
		if(ORGASM_LOCATION_INTO, ORGASM_LOCATION_ORAL)
			return reagents.maximum_volume / 4
		if(ORGASM_LOCATION_SELF)
			return reagents.maximum_volume / 5
		if(ORGASM_LOCATION_CONTAINER)
			return reagents.maximum_volume / 3
	return min(3, 10 * organ_size)

/// Fuller testicles release more: the base amount at half full, up to half again when full.
/obj/item/organ/genitals/filling_organ/testicles/get_pent_up_multiplier()
	return FLUID_PENT_UP_MIN_MULT + get_own_fullness() * (FLUID_PENT_UP_MAX_MULT - FLUID_PENT_UP_MIN_MULT)

/obj/item/organ/genitals/filling_organ/testicles/is_pent_up()
	return get_own_fullness() >= FLUID_PENT_UP_RATIO

/obj/item/organ/genitals/filling_organ/testicles/proc/sync_cum_source_data()
	if(!owner || !reagents)
		return FALSE

	var/datum/reagent/current_reagent = reagents.get_reagent(reagent_to_make)
	if(!istype(current_reagent, /datum/reagent/consumable/cum))
		current_reagent = reagents.get_master_reagent()
	if(!istype(current_reagent, /datum/reagent/consumable/cum))
		return FALSE

	var/datum/reagent/consumable/cum/current_cum = current_reagent
	return current_cum.sync_parent_data(owner)

/obj/item/organ/genitals/filling_organ/testicles/get_availability(datum/species/owner_species, mob/living/C, datum/preferences/pref_load)
	if(issimple(C))
		return C.gender == MALE
	else
		if(pref_load)
			return pref_load.has_enabled_customizer_entry(/datum/customizer_entry/organ/genitals/testicles)
		else
			return C.gender == MALE

