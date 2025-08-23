/obj/item/organ/genitals/breasts
	name = "breasts"
	icon_state = "severedtail"
	visible_organ = TRUE
	zone = BODY_ZONE_CHEST
	slot = ORGAN_SLOT_BREASTS
	var/breast_size = DEFAULT_BREASTS_SIZE
	var/lactating = FALSE
	var/milk_stored = 0
	var/milk_max = 75

/obj/item/organ/genitals/breasts/New()
	..()
	milk_max = max(75, breast_size * 100)

/obj/item/organ/genitals/breasts/Insert(mob/living/carbon/M, special, drop_if_replaced)
	. = ..()
	M.add_hole(ORGAN_SLOT_BREASTS, /datum/component/storage/concrete/grid/hole/breasts)
	SEND_SIGNAL(M, COMSIG_HOLE_MODIFY_HOLE, ORGAN_SLOT_BREASTS, 3, CEILING(breast_size / 4, 1))

/obj/item/organ/genitals/breasts/Remove(mob/living/carbon/M, special, drop_if_replaced)
	. = ..()
	SEND_SIGNAL(M, COMSIG_HOLE_REMOVE_HOLE, ORGAN_SLOT_BREASTS)
