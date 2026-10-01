/obj/item/reagent_containers/glass/bucket
	name = "bugged bucket please report to mappers"
	desc = ""
	icon = 'icons/roguetown/items/misc.dmi'
	lefthand_file = 'icons/roguetown/onmob/lefthand.dmi'
	righthand_file = 'icons/roguetown/onmob/righthand.dmi'
	icon_state = "woodbucket"
	item_state = "woodbucket"
	fill_icon_thresholds = list(0, 50, 100)
	reagent_flags = OPENCONTAINER
	max_integrity = 300
	w_class = WEIGHT_CLASS_BULKY
	amount_per_transfer_from_this = 10
	possible_transfer_amounts = list(10)
	volume = 100
	flags_inv = HIDEHAIR
	obj_flags = CAN_BE_HIT
	resistance_flags = NONE

/obj/item/reagent_containers/glass/bucket/dropped(mob/user)
	. = ..()
	reagents.flags = initial(reagent_flags)

/obj/item/reagent_containers/glass/bucket/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(!istype(tool, /obj/item/reagent_containers/powder/salt))
		return ..()

	if(!reagents?.total_volume)
		return NONE

	if(!length(get_saltable_milk_types()))
		return NONE

	to_chat(user, span_danger("Adding salt to the milk."))
	playsound(src, pick('sound/foley/waterwash (1).ogg','sound/foley/waterwash (2).ogg'), 100, FALSE)

	if(!do_after(user, 2 SECONDS, src))
		return ITEM_INTERACT_BLOCKING

	if(!salt_milks())
		return ITEM_INTERACT_BLOCKING

	qdel(tool)

	return ITEM_INTERACT_SUCCESS

/// Milk types in the bucket with enough volume to salt; species milk counts as well as cow and gote milk.
/obj/item/reagent_containers/glass/bucket/proc/get_saltable_milk_types()
	. = list()
	for(var/datum/reagent/consumable/milk/milk in reagents?.reagent_list)
		if(milk.volume >= 15 && milk.get_salted_type())
			. += milk.type

/// Salts 15 units of every saltable milk and returns how many kinds were salted.
/obj/item/reagent_containers/glass/bucket/proc/salt_milks()
	. = 0
	for(var/datum/reagent/consumable/milk/milk_type as anything in get_saltable_milk_types())
		var/datum/reagent/consumable/milk/milk = reagents.get_reagent(milk_type)
		var/salted_type = milk.get_salted_type()
		reagents.remove_reagent(milk_type, 15)
		reagents.add_reagent(salted_type, 15)
		.++

/obj/item/reagent_containers/glass/bucket/wooden
	name = "bucket"
	fill_icon_state = "bucket"
	force = 5
	throwforce = 10
	armor_type = /datum/armor/bucket
	resistance_flags = FLAMMABLE
	dropshrink = 0.8
	slot_flags = null
	drop_sound = 'sound/foley/dropsound/wooden_drop.ogg'

/obj/item/reagent_containers/glass/bucket/wooden/Initialize(mapload, vol)
	. = ..()
	AddComponent(/datum/component/storage/concrete/grid/bucket)

/obj/item/reagent_containers/glass/bucket/wooden/alter // just new look, trying it on for size
	icon = 'icons/roguetown/items/cooking.dmi'

/obj/item/reagent_containers/glass/bucket/wooden/getonmobprop(tag)
	. = ..()
	if(tag)
		switch(tag)
			if("gen")
				return list("shrink" = 0.5,"sx" = -5,"sy" = -8,"nx" = 7,"ny" = -9,"wx" = -1,"wy" = -8,"ex" = -1,"ey" = -8,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 0,"sturn" = 0,"wturn" = 0,"eturn" = 0,"nflip" = 0,"sflip" = 0,"wflip" = 0,"eflip" = 0)

/obj/item/reagent_containers/glass/bucket/pot
	name = "pot"
	desc = "The peasants friend, when filled with boiling water it will turn the driest oats to filling oatmeal."
	icon = 'icons/roguetown/items/cooking.dmi'
	icon_state = "pote"
	fill_icon_state = "pote"
	force = 10
	drop_sound = 'sound/foley/dropsound/shovel_drop.ogg'
	melting_material = /datum/material/iron
	melt_amount = 80
	volume = 200
	var/processing_amount = 0 ///we use this to "reserve" reagents
	var/static/list/recipe_list = list()

/obj/item/reagent_containers/glass/bucket/pot/Initialize(mapload, vol)
	. = ..()
	if(!length(recipe_list))
		for(var/datum/container_craft/recipe as anything in subtypesof(/datum/container_craft/cooking))
			if(!IS_ABSTRACT(recipe))
				recipe_list += recipe

	AddComponent(/datum/component/storage/concrete/grid/food/cooking/pot)
	if(length(recipe_list))
		AddComponent(/datum/component/container_craft, recipe_list, TRUE)

/obj/item/reagent_containers/glass/bucket/pot/copper
	icon_state = "pote_copper"
	melting_material = /datum/material/copper
	volume = 100

/obj/item/reagent_containers/glass/bucket/pot/stone
	icon_state = "pote_stone"
	melting_material = null
	volume = 50

/obj/item/reagent_containers/glass/bucket/pot/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(!istype(tool, /obj/item/reagent_containers/glass/bowl))
		return ..()

	if(tool.reagents?.holder_full())
		balloon_alert(user, "the [tool] is full!")
		return ITEM_INTERACT_BLOCKING

	balloon_alert(user, "filling [tool].")

	playsound(user, pick('sound/foley/waterwash (1).ogg','sound/foley/waterwash (2).ogg'), 70, FALSE)

	if(!do_after(user, 2 SECONDS, src))
		return ITEM_INTERACT_BLOCKING

	reagents.trans_to(tool, reagents.total_volume)

	return ITEM_INTERACT_SKIP_TO_ATTACK

/obj/item/reagent_containers/glass/bucket/pot/throw_impact(atom/hit_atom, datum/thrownthing/thrownthing)
	if(reagents.total_volume > 5)
		new /obj/effect/decal/cleanable/food/mess/soup(get_turf(src))
	. = ..()

/obj/item/reagent_containers/glass/bucket/pot/getonmobprop(tag)
	. = ..()
	if(tag)
		switch(tag)
			if("gen")
				return list("shrink" = 0.5,"sx" = -5,"sy" = -8,"nx" = 7,"ny" = -9,"wx" = -1,"wy" = -8,"ex" = -1,"ey" = -8,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 0,"sturn" = 0,"wturn" = 0,"eturn" = 0,"nflip" = 0,"sflip" = 0,"wflip" = 0,"eflip" = 0)
