/obj/item/clothing/wrists/bracers/dreamwalker
	name = "otherworldly bracers"
	desc = "Strange iridescent bracers. It reflects light as if covered in shiny oil."
	icon = 'modular_azurepeak/icons/clothing/wrists.dmi'
	mob_overlay_icon = 'modular_azurepeak/icons/clothing/onmob/wrists.dmi'
	sleeved = 'modular_azurepeak/icons/clothing/onmob/wrists.dmi'
	item_flags = (1<<13)
	color = "#2ba6b2"
	dyeable = TRUE
	misc_flags = CRAFTING_TEST_EXCLUDE

/obj/item/clothing/wrists/bracers/dreamwalker/Initialize(mapload)
	. = ..()
