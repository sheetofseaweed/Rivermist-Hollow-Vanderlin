
/obj/item/storage/fancy/ifak
	item_weight = 740 GRAMS
	name = "personal patch kit"
	desc = "Personal treatment pouch; has all you need to stop you or someone else from meeting Jergal."
	icon = 'icons/obj/medical.dmi'
	icon_state = "ifak"
	w_class = WEIGHT_CLASS_SMALL
	component_type = /datum/component/storage/concrete/grid/ifak
	throwforce = 1
	slot_flags = ITEM_SLOT_HIP
	populate_contents = list(
		/obj/item/reagent_containers/syringe,
		/obj/item/natural/bundle/cloth/bandage/full,
		/obj/item/storage/fancy/pilltin/atropine,
		/obj/item/storage/fancy/pilltin/charcoal,
		/obj/item/candle/yellow,
		/obj/item/needle,
	)
	contents_tag = "item"

/obj/item/storage/fancy/ifak/update_icon_state()
	. = ..()
	if(is_open)
		if(length(contents) == 0)
			icon_state = "ifak_empty"
		else
			icon_state = "ifak_open"
	else
		icon_state = "ifak"

/obj/item/storage/fancy/ifak/attack_self(mob/user, list/modifiers)
	. = ..()
	to_chat(user, span_notice("[src] is now [is_open ? "open" : "closed"]."))

/obj/item/storage/fancy/ifak/MiddleClick(mob/user, list/modifiers)
	. = ..()
	to_chat(user, span_notice("[src] is now [is_open ? "open" : "closed"]."))

