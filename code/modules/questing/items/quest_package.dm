/obj/item/quest_package
	name = "commission parcel"
	desc = "A sealed parcel associated with a player commission."
	icon = 'icons/obj/ration.dmi'
	icon_state = "ration_small"
	resistance_flags = FIRE_PROOF | LAVA_PROOF | INDESTRUCTIBLE | UNACIDABLE
	max_integrity = 1000
	armor_type = /datum/armor/immune
	var/quest_title = ""
	var/datum/weakref/pledge_ref
	var/delivery_target_name = ""
	var/delivery_target_ckey = ""

/obj/item/quest_package/examine(mob/user)
	. = ..()
	if(quest_title)
		. += span_notice("It is labeled: \"[quest_title]\".")
	if(pledge_ref)
		. += span_notice("Only the originating quest pledge can break this seal.")
	else if(delivery_target_name)
		. += span_notice("It is addressed to [delivery_target_name].")

/obj/item/quest_package/attackby(obj/item/used_item, mob/living/carbon/human/user, params)
	if(pledge_ref)
		var/obj/item/paper/scroll/quest/pledge/pledge = pledge_ref.resolve()
		if(!pledge || used_item != pledge)
			to_chat(user, span_warning("The pledge seal refuses to open."))
			return
		open_package(user)
		return
	return ..()

/obj/item/quest_package/attack_self(mob/user)
	if(pledge_ref)
		to_chat(user, span_warning("This parcel requires its originating quest pledge."))
		return
	if(delivery_target_ckey && user.ckey != delivery_target_ckey)
		to_chat(user, span_warning("This parcel is addressed to [delivery_target_name]."))
		return
	if(!delivery_target_ckey && delivery_target_name && user.real_name != delivery_target_name)
		to_chat(user, span_warning("This parcel is addressed to [delivery_target_name]."))
		return
	open_package(user)

/obj/item/quest_package/proc/open_package(mob/user)
	if(!length(contents))
		to_chat(user, span_warning("The parcel is empty."))
		return
	to_chat(user, span_notice("You break the seal on [src] and unpack it."))
	for(var/obj/item/item in contents)
		item.forceMove(get_turf(user))
	qdel(src)
