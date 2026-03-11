/obj/item/organ/genitals/pubes
	visible_organ = FALSE
	zone = BODY_ZONE_CHEST
	slot = ORGAN_SLOT_PUBIC
	name = "pube"
	altnames = list("pelvis", "pubes") //used in thought messages.

/obj/item/organ/genitals/pubes/Insert(mob/living/M, special, drop_if_replaced)
	. = ..()
	add_bodystorage(M, null, /datum/component/body_storage/pubes)

/obj/item/organ/genitals/pubes/Remove(mob/living/M, special, drop_if_replaced)
	. = ..()
	var/datum/component/body_storage/pubes/comp = GetComponent(/datum/component/body_storage/pubes)
	comp?.RemoveComponent()
	qdel(comp)
