/obj/item/organ/genitals/filling_organ/testicles
	name = "testicles"
	icon = 'modular_rmh/icons/eaglephntm/icons/obj/surgery.dmi'
	icon_state = "testicles"
	visible_organ = TRUE
	zone = BODY_ZONE_PRECISE_GROIN
	slot = ORGAN_SLOT_TESTICLES
	accessory_type = /datum/sprite_accessory/genitals/testicles/pair
	altnames = list("balls", "testicles", "testes", "orbs", "cum tanks", "seed tanks") //used in thought messages.
	organ_size = DEFAULT_TESTICLES_SIZE
	var/virility = TRUE
	reagent_to_make = /datum/reagent/consumable/cum
	reagent_generate_rate = 6
	storage_per_size = 75
	startsfilled = TRUE
	blocker = ITEM_SLOT_PANTS
	organ_sizeable  = TRUE
	refilling = TRUE

/obj/item/organ/genitals/filling_organ/testicles/invisible //so it can be surgically removed but still not visible on sprite
	accessory_type = /datum/sprite_accessory/none

/obj/item/organ/genitals/filling_organ/testicles/internal
	name = "internal testicles"
	visible_organ = FALSE
	accessory_type = /datum/sprite_accessory/none

/obj/item/organ/genitals/filling_organ/testicles/Insert(mob/living/M, special, drop_if_replaced)
	. = ..()
	if(M.cum)
		reagent_to_make = M.cum
	if(!virility)
		reagent_to_make = /datum/reagent/consumable/cum/sterile
		reagents.clear_reagents()
		reagents.add_reagent(reagent_to_make, reagents.maximum_volume)
	add_bodystorage(M, null, /datum/component/body_storage/testicles)

/obj/item/organ/genitals/filling_organ/testicles/Remove(mob/living/M, special, drop_if_replaced)
	. = ..()
	var/datum/component/body_storage/testicles/comp = GetComponent(/datum/component/body_storage/testicles)
	comp?.RemoveComponent()
	qdel(comp)

/obj/item/organ/genitals/filling_organ/testicles/get_availability(datum/species/owner_species, mob/living/C, datum/preferences/pref_load)
	if(issimple(C))
		return C.gender == MALE
	else
		if(pref_load)
			return pref_load.get_customizer_entry_of_type(/datum/customizer_entry/organ/genitals/testicles)
		else
			return C.gender == MALE

