/obj/item/clothing/shirt/tunic/silktunic
	icon = 'modular_rmh/icons/clothing/shirts.dmi'
	mob_overlay_icon = 'modular_rmh/icons/clothing/onmob/shirts.dmi'
	sleeved = 'icons/roguetown/clothing/onmob/helpers/sleeves_shirts.dmi'
	name = "ornate silk tunic"
	desc = "A billowing tunic made of the finest silks and softest fabrics. Inlaid with golden thread, this is the height of fashion for the wealthiest of wearers."
	icon_state = "stewardtunic"
	item_state = "stewardtunic"

//WEDDING CLOTHES
/obj/item/clothing/shirt/dress/silkdress/weddingdress
	icon = 'modular_rmh/icons/clothing/shirts.dmi'
	mob_overlay_icon = 'modular_rmh/icons/clothing/onmob/shirts.dmi'
	sleeved = 'icons/roguetown/clothing/onmob/helpers/sleeves_shirts.dmi'
	name = "wedding silk dress"
	desc = "A dress woven from fine silks, with golden threads inlaid in it. Made for that special day."
	icon_state = "weddingdress"
	item_state = "weddingdress"

/obj/item/clothing/shirt/exoticsilkbra
	icon = 'modular_rmh/icons/clothing/shirts.dmi'
	mob_overlay_icon = 'modular_rmh/icons/clothing/onmob/shirts.dmi'
	sleeved = 'icons/roguetown/clothing/onmob/helpers/sleeves_shirts.dmi'
	name = "exotic silk bra"
	desc = "An exquisite bra crafted from the finest silk and adorned with gold rings. It leaves little to the imagination."
	icon_state = "exoticsilkbra"
	item_state = "exoticsilkbra"
	body_parts_covered = CHEST
	boobed = TRUE
	sewrepair = TRUE
	flags_inv = null
	slot_flags = ITEM_SLOT_SHIRT

//kazengite content
/obj/item/clothing/shirt/undershirt/eastshirt1
	icon = 'modular_rmh/icons/clothing/shirts.dmi'
	mob_overlay_icon = 'modular_rmh/icons/clothing/onmob/shirts.dmi'
	sleeved = 'icons/roguetown/clothing/onmob/helpers/sleeves_shirts.dmi'
	slot_flags = ITEM_SLOT_SHIRT|ITEM_SLOT_ARMOR
	name = "black foreign shirt"
	desc = "A shirt typically used by thugs."
	body_parts_covered = CHEST|GROIN|ARMS|VITALS
	icon_state = "eastshirt1"
	boobed = TRUE
	r_sleeve_status = SLEEVE_NORMAL
	l_sleeve_status = SLEEVE_NORMAL
	//flags_inv = HIDECROTCH|HIDEBOOB|HIDEBELLY
	allowed_race = SPECIES_BASE_BODY

/obj/item/clothing/shirt/undershirt/eastshirt2
	icon = 'modular_rmh/icons/clothing/shirts.dmi'
	mob_overlay_icon = 'modular_rmh/icons/clothing/onmob/shirts.dmi'
	sleeved = 'modular_rmh/icons/clothing/onmob/helpers/sleeves_shirts.dmi'
	slot_flags = ITEM_SLOT_SHIRT|ITEM_SLOT_ARMOR
	name = "white foreign shirt"
	desc = "A shirt typically used by foreign gangs."
	body_parts_covered = CHEST|GROIN|ARMS|VITALS
	icon_state = "eastshirt2"
	boobed = TRUE
	r_sleeve_status = SLEEVE_NORMAL
	l_sleeve_status = SLEEVE_NORMAL
	//flags_inv = HIDECROTCH|HIDEBOOB|HIDEBELLY
	allowed_race = SPECIES_BASE_BODY

