/obj/item/organ/genitals/testicles
	name = "testicles"
	icon_state = "severedtail" //placeholder
	visible_organ = TRUE
	zone = BODY_ZONE_PRECISE_GROIN
	slot = ORGAN_SLOT_TESTICLES
	accessory_type = /datum/sprite_accessory/genitals/testicles/pair
	var/ball_size = DEFAULT_TESTICLES_SIZE
	var/virility = TRUE

/obj/item/organ/genitals/testicles/internal
	name = "internal testicles"
	visible_organ = FALSE
	accessory_type = /datum/sprite_accessory/none
