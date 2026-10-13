/obj/item/clothing/gloves/leather/otavan/inqgloves/overseer
	name = "silver-trimmed confessor gloves"
	desc = "Black leather gloves decorated with bright stripes."
	icon = 'modular_twilightaxis/icons/clothing/inquisition_overseer/overseer.dmi'
	mob_overlay_icon = 'modular_twilightaxis/icons/clothing/inquisition_overseer/onmob/overseer_onmob.dmi'
	sleeved = 'modular_twilightaxis/icons/clothing/onmob/gloves.dmi'
	icon_state = "viceseergloves"
	item_state = "viceseergloves"
	color = null
	misc_flags = CRAFTING_TEST_EXCLUDE

/obj/item/clothing/gloves/leather/otavan/psygloves/overseer
	name = "confessor gloves"
	desc = "Black leather gloves decorated with bright stripes."
	icon = 'modular_twilightaxis/icons/clothing/inquisition_overseer/overseer.dmi'
	mob_overlay_icon = 'modular_twilightaxis/icons/clothing/inquisition_overseer/onmob/overseer_onmob.dmi'
	sleeved = 'modular_twilightaxis/icons/clothing/onmob/gloves.dmi'
	icon_state = "overseergloves"
	item_state = "overseergloves"
	color = null
	misc_flags = CRAFTING_TEST_EXCLUDE

/obj/item/clothing/gloves/knuckles/psydon/relic
	name = "\"Penance\""
	desc = "Forged in the workshops of Amn from silver-blessed steel, these brutal knuckles were carried by an inquisitor who made a practice of delivering judgement without drawing a blade. The three crowned studs bear the mark of Ao, and each blow is said to serve as a reminder that faith need not wield a sword to break the bones of the wicked."
	icon = 'modular_twilightaxis/icons/clothing/32.dmi'
	mob_overlay_icon = 'modular_twilightaxis/icons/clothing/onmob/gloves.dmi'
	sleeved = 'modular_twilightaxis/icons/clothing/onmob/gloves.dmi'
	unarmed_bonus = 10
	misc_flags = CRAFTING_TEST_EXCLUDE

/obj/item/clothing/gloves/knuckles/psydon/relic/Initialize(mapload)
	. = ..()
	AddComponent(\
		pre_blessed = 1,\
		added_force = 0,\
		added_blade_int = 0,\
		added_int = 50,\
		added_def = 2,\
	)
