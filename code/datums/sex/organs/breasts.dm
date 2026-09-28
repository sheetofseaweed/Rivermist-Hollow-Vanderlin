/obj/item/organ/genitals/filling_organ/breasts
	name = "breasts"
	icon_state = "breasts"
	visible_organ = TRUE
	zone = BODY_ZONE_CHEST
	slot = ORGAN_SLOT_BREASTS
	organ_size = DEFAULT_BREASTS_SIZE
	reagent_to_make = /datum/reagent/consumable/milk
	// Milk costs more than drinking it gives back, so it cannot feed its maker.
	nutrition_per_unit = 2
	// A cow's pace, so one person is no cheese factory.
	production_rate = 0.5
	hungerhelp = TRUE
	absorbing = FALSE //funny liquid tanks
	startsfilled = TRUE
	allows_oviposition_pregnancy = FALSE
	altnames = list("breasts", "tits", "milkers", "tiddies", "badonkas", "boobas") //used in thought messages.
	blocker = ITEM_SLOT_SHIRT
	additional_blocker = "bra"
	organ_sizeable = TRUE
	can_engorge = TRUE
	leaks_when_full = TRUE
	drips_as_drops = TRUE
	stain_zone = FLUID_STAIN_CHEST

/obj/item/organ/genitals/filling_organ/breasts/Insert(mob/living/M, special, drop_if_replaced, new_zone = null)
	if(M?.breast_milk)
		set_reagent_to_make(M.breast_milk)
	. = ..()
	if(!.)
		return FALSE
	add_bodystorage(M, null, /datum/component/body_storage/breasts)
	var/obj/item/organ/genitals/nipple/left/l_nip = new /obj/item/organ/genitals/nipple/left
	var/obj/item/organ/genitals/nipple/right/r_nip = new /obj/item/organ/genitals/nipple/right
	l_nip.Insert(M, FALSE, FALSE)
	r_nip.Insert(M, FALSE, FALSE)


	var/obj/item/organ/genitals/filling_organ/breasts/badonkas = M.getorganslot(ORGAN_SLOT_BREASTS)
	if(!badonkas)
		return TRUE
	//Making users of big BOOBA suk dikus
	if(badonkas.organ_size >= BREAST_SIZE_ENORMOUS)
		M.apply_status_effect(/datum/status_effect/debuff/bigboobs/permanent/lite)
	else if(badonkas.organ_size == BREAST_SIZE_LARGE)
		M.apply_status_effect(/datum/status_effect/debuff/largeboobs/permanent/lite)
	else if(badonkas.organ_size == BREAST_SIZE_SMALL)
		M.apply_status_effect(/datum/status_effect/debuff/smallboobs/permanent/lite)
	else if(badonkas.organ_size == BREAST_SIZE_VERY_SMALL)
		M.apply_status_effect(/datum/status_effect/debuff/vsmallboobs/permanent/lite)
	else if(badonkas.organ_size == BREAST_SIZE_FLAT)
		M.apply_status_effect(/datum/status_effect/debuff/flatboobs/permanent/lite)

/obj/item/organ/genitals/filling_organ/breasts/Remove(mob/living/M, special, drop_if_replaced)
	. = ..()
	var/datum/component/body_storage/breasts/comp = GetComponent(/datum/component/body_storage/breasts)
	comp?.RemoveComponent()

/obj/item/organ/genitals/filling_organ/breasts/get_availability(datum/species/owner_species, mob/living/C, datum/preferences/pref_load)
	if(issimple(C))
		return C.gender == FEMALE
	else
		if(pref_load)
			return pref_load.has_enabled_customizer_entry(/datum/customizer_entry/organ/genitals/breasts)
		else
			return C.gender == FEMALE
