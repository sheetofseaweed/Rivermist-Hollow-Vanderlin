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


	// Size stats and effects: one status kept up to date with the visible size, see breast_weight.dm
	// (replaces the per-size "<size>boobs/permanent/lite" statuses applied here once).
	if(ishuman(M))
		var/mob/living/carbon/human/human_owner = M
		human_owner.update_breast_size_effect()

/obj/item/organ/genitals/filling_organ/breasts/Remove(mob/living/M, special, drop_if_replaced)
	. = ..()
	var/datum/component/body_storage/breasts/comp = GetComponent(/datum/component/body_storage/breasts)
	comp?.RemoveComponent()
	if(ishuman(M))
		var/mob/living/carbon/human/human_owner = M
		human_owner.update_breast_size_effect()

/obj/item/organ/genitals/filling_organ/breasts/get_availability(datum/species/owner_species, mob/living/C, datum/preferences/pref_load)
	if(issimple(C))
		return C.gender == FEMALE
	else
		if(pref_load)
			return pref_load.has_enabled_customizer_entry(/datum/customizer_entry/organ/genitals/breasts)
		else
			return C.gender == FEMALE
