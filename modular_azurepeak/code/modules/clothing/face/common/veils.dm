/obj/item/clothing/face/bandana
	name = "botany bandana"
	desc = ""
	icon = 'modular_azurepeak/icons/clothing/masks.dmi'
	mob_overlay_icon = null
	sleeved = null
	icon_state = "bandbotany"
	w_class = WEIGHT_CLASS_TINY
	flags_cover = MASKCOVERSMOUTH
	flags_inv = HIDEFACE|HIDEFACIALHAIR
	visor_flags_inv = HIDEFACE|HIDEFACIALHAIR
	visor_flags_cover = MASKCOVERSMOUTH | PEPPERPROOF
	slot_flags = ITEM_SLOT_MASK
	adjusted_flags = ITEM_SLOT_HEAD
	ported_clothing = TRUE
	misc_flags = CRAFTING_TEST_EXCLUDE

/obj/item/clothing/face/bandana/attack_self(mob/user, list/modifiers)
	adjustmask(user)

/obj/item/clothing/face/bandana/black
	name = "black bandana"
	desc = ""
	icon = 'modular_azurepeak/icons/clothing/masks.dmi'
	mob_overlay_icon = null
	sleeved = null
	icon_state = "bandblack"
	misc_flags = CRAFTING_TEST_EXCLUDE

/obj/item/clothing/face/faceveil
	name = "simple veil"
	desc = "A remarkably plain veil meant to conceal ones face... if you wore this, a gust of wind would be all it takes to reveal your identity."
	icon = 'modular_azurepeak/icons/clothing/masks_2.dmi'
	mob_overlay_icon = 'modular_azurepeak/icons/clothing/onmob/masks.dmi'
	sleeved = null
	icon_state = "faceveil"
	flags_inv = HIDEFACE
	adjustable = CAN_CADJUST
	toggle_icon_state = TRUE
	grid_width = 32
	grid_height = 32
	ported_adjust = TRUE
	adj_open_coverage = NECK
	adj_sound = 'sound/foley/equip/rummaging-03.ogg'
	ported_clothing = TRUE
