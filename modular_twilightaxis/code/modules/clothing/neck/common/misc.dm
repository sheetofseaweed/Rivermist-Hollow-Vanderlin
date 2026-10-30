/obj/item/clothing/neck/necklace
	mob_overlay_icon = null
	sleeved = null
	ported_clothing = TRUE
	abstract_type = /obj/item/clothing/neck/necklace

/obj/item/clothing/neck/collar/bell
	mob_overlay_icon = null
	sleeved = null
	abstract_type = /obj/item/clothing/neck/collar/bell

/obj/item/clothing/neck/collar/bell/Initialize(mapload)
	if(bellsound == TRUE)
		. = ..()
		AddComponent(/datum/component/squeak, SFX_COLLARJINGLE, 50, 100, 1) //We want squeak so wearer jingles if touched while wearing collar
