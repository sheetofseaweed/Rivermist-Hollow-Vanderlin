/datum/component/storage/concrete/grid/jewelry_box
	screen_max_columns = 1
	screen_max_rows = 2
	max_w_class = WEIGHT_CLASS_SMALL
	rustle_sound = FALSE
	var/reshowing = FALSE

/datum/component/storage/concrete/grid/jewelry_box/New(datum/P, ...)
	. = ..()
	set_holdable(cant_hold_list = list(/obj/item/grown/log))

/datum/component/storage/concrete/grid/jewelry_box/show_to(mob/M)
	reshowing = TRUE
	. = ..()
	reshowing = FALSE
	if(!.)
		return
	var/obj/item/storage/jewelry_box/box = parent
	if(istype(box))
		box.set_lid_open(TRUE)

/datum/component/storage/concrete/grid/jewelry_box/hide_from(mob/M)
	. = ..()
	if(reshowing || length(can_see_contents()))
		return
	var/obj/item/storage/jewelry_box/box = parent
	if(istype(box) && !QDELETED(box))
		box.set_lid_open(FALSE)

/datum/component/storage/concrete/grid/jewelry_box/big
	screen_max_columns = 2
	screen_max_rows = 3
	max_w_class = WEIGHT_CLASS_NORMAL

/datum/component/storage/concrete/grid/kerchief
	screen_max_columns = 1
	screen_max_rows = 1
	max_w_class = WEIGHT_CLASS_SMALL
	rustle_sound = 'sound/foley/cloth_wipe (1).ogg'

/datum/component/storage/concrete/grid/kerchief/New(datum/P, ...)
	. = ..()
	set_holdable(cant_hold_list = list(/obj/item/grown/log))

/* ------------------------------------------------------------------ */
/* Jewelry boxes                                                       */
/* ------------------------------------------------------------------ */

/obj/item/storage/jewelry_box
	abstract_type = /obj/item/storage/jewelry_box
	name = "jewelry box"
	desc = "A small wooden box for keeping valuables."
	icon = 'modular_rmh/icons/obj/jewelry_boxes.dmi'
	icon_state = "jbox_big"
	base_icon_state = "jbox_big"
	resistance_flags = FLAMMABLE
	component_type = /datum/component/storage/concrete/grid/jewelry_box
	/// TRUE while at least one mob is looking inside.
	var/lid_open = FALSE

/obj/item/storage/jewelry_box/examine(mob/user)
	. = ..()
	. += span_info("Middle-click to open or close the lid.")

/obj/item/storage/jewelry_box/proc/set_lid_open(new_state)
	if(lid_open == new_state)
		return
	lid_open = new_state
	playsound(src, lid_open ? 'sound/misc/chestopen.ogg' : 'sound/misc/chestclose.ogg', 25, TRUE, -3)
	update_appearance(UPDATE_ICON_STATE)

/obj/item/storage/jewelry_box/update_icon_state()
	. = ..()
	var/state = base_icon_state
	if(lid_open)
		state += length(contents) ? "_full" : "_open"
	if(isturf(loc))
		state += "_world"
	icon_state = state

/obj/item/storage/jewelry_box/Moved(atom/OldLoc, Dir, Forced = FALSE)
	. = ..()
	if(isturf(OldLoc) != isturf(loc))
		update_appearance(UPDATE_ICON_STATE)

/obj/item/storage/jewelry_box/Exited(atom/movable/gone, direction)
	. = ..()
	update_appearance(UPDATE_ICON_STATE)

/obj/item/storage/jewelry_box/MiddleClick(mob/user, list/modifiers)
	var/datum/component/storage/storage = GetComponent(/datum/component/storage)
	if(!storage || !isliving(user))
		return
	user.changeNext_move(CLICK_CD_FAST)
	if(user.active_storage == storage)
		storage.close(user)
		return
	storage.user_show_to_mob(user)

/obj/item/storage/jewelry_box/big
	name = "large jewelry box"
	desc = "A sturdy nailed box of planks. Heavy, but it keeps a lot safe."
	icon_state = "jbox_big"
	base_icon_state = "jbox_big"
	item_weight = 900 GRAMS
	w_class = WEIGHT_CLASS_NORMAL
	grid_width = 64
	grid_height = 64
	sellprice = 15
	component_type = /datum/component/storage/concrete/grid/jewelry_box/big

/obj/item/storage/jewelry_box/rich
	name = "rich jewelry box"
	desc = "A dainty box lined with dyed cloth and dusted with gold. Simply holding it feels nice."
	icon_state = "jbox_rich"
	base_icon_state = "jbox_rich"
	item_weight = 500 GRAMS
	w_class = WEIGHT_CLASS_SMALL
	grid_width = 32
	grid_height = 64
	sellprice = 60
	var/datum/weakref/carrier_ref

/obj/item/storage/jewelry_box/rich/Initialize(mapload, ...)
	. = ..()
	var/static/list/container_connections = list(
		COMSIG_MOVABLE_MOVED = PROC_REF(on_container_moved),
	)
	AddComponent(/datum/component/connect_containers, src, container_connections)
	update_carrier()

/obj/item/storage/jewelry_box/rich/Destroy()
	var/mob/living/carbon/old_carrier = carrier_ref?.resolve()
	carrier_ref = null
	if(old_carrier)
		release_carrier(old_carrier)
	return ..()

/obj/item/storage/jewelry_box/rich/Moved(atom/OldLoc, Dir, Forced = FALSE)
	. = ..()
	update_carrier()

/obj/item/storage/jewelry_box/rich/proc/on_container_moved(datum/source, atom/old_loc, dir, forced)
	SIGNAL_HANDLER
	update_carrier()

/obj/item/storage/jewelry_box/rich/proc/update_carrier()
	var/mob/living/carbon/new_carrier = recursive_loc_check(src, /mob/living/carbon)
	var/mob/living/carbon/old_carrier = carrier_ref?.resolve()
	if(new_carrier == old_carrier)
		return
	carrier_ref = new_carrier ? WEAKREF(new_carrier) : null
	if(old_carrier)
		release_carrier(old_carrier)
	new_carrier?.add_stress(/datum/stress_event/jewelry_box)

/obj/item/storage/jewelry_box/rich/proc/release_carrier(mob/living/carbon/old_carrier)
	if(QDELETED(old_carrier))
		return
	old_carrier.remove_stress(/datum/stress_event/jewelry_box)
	// The bonus does not stack, but another box still carried must keep it alive.
	for(var/obj/item/storage/jewelry_box/rich/other in old_carrier.get_all_contents())
		if(other != src && other.carrier_ref?.resolve() == old_carrier)
			old_carrier.add_stress(/datum/stress_event/jewelry_box)
			return

/datum/stress_event/jewelry_box
	stress_change = -1
	desc = span_green("I carry a lovely jewelry box.")

/* ------------------------------------------------------------------ */
/* Kerchief                                                            */
/* ------------------------------------------------------------------ */

/obj/item/storage/kerchief
	name = "kerchief"
	desc = "A square of cloth, good for wrapping a small treasure or a bite to eat."
	icon = 'modular_rmh/icons/obj/jewelry_boxes.dmi'
	icon_state = "kerchief"
	base_icon_state = "kerchief"
	item_weight = 10 GRAMS
	w_class = WEIGHT_CLASS_TINY
	grid_width = 32
	grid_height = 32
	resistance_flags = FLAMMABLE
	sellprice = 4
	component_type = /datum/component/storage/concrete/grid/kerchief
	var/list/wrapped_food
	var/dyeing = FALSE

/obj/item/storage/kerchief/Destroy()
	for(var/obj/item/reagent_containers/food/snacks/food as anything in wrapped_food)
		unwrap_food(food)
	LAZYNULL(wrapped_food)
	return ..()

/obj/item/storage/kerchief/examine(mob/user)
	. = ..()
	. += span_info("Food wrapped in it spoils at half the usual pace.")
	if(!length(contents))
		. += span_info("Middle-click it while holding dyes to dye it.")

/obj/item/storage/kerchief/update_icon_state()
	. = ..()
	var/state = base_icon_state
	if(length(contents))
		state += "_tied"
	if(isturf(loc))
		state += "_world"
	icon_state = state

/obj/item/storage/kerchief/Moved(atom/OldLoc, Dir, Forced = FALSE)
	. = ..()
	if(isturf(OldLoc) != isturf(loc))
		update_appearance(UPDATE_ICON_STATE)

/obj/item/storage/kerchief/Entered(atom/movable/arrived, atom/old_loc)
	. = ..()
	if(istype(arrived, /obj/item/reagent_containers/food/snacks))
		wrap_food(arrived)
	update_appearance(UPDATE_ICON_STATE)

/obj/item/storage/kerchief/Exited(atom/movable/gone, direction)
	. = ..()
	if(LAZYACCESS(wrapped_food, gone))
		unwrap_food(gone)
	update_appearance(UPDATE_ICON_STATE)

/obj/item/storage/kerchief/proc/wrap_food(obj/item/reagent_containers/food/snacks/food)
	if(!food.rotprocess)
		return
	var/start_warming = food.warming || 0
	LAZYSET(wrapped_food, food, list(start_warming, food.rotprocess))
	food.rotprocess = food.rotprocess * 2 + start_warming

/obj/item/storage/kerchief/proc/unwrap_food(obj/item/reagent_containers/food/snacks/food)
	var/list/saved = LAZYACCESS(wrapped_food, food)
	LAZYREMOVE(wrapped_food, food)
	if(!saved || !food.rotprocess)
		return
	var/start_warming = saved[1]
	var/lost = start_warming - (food.warming || 0)
	food.warming = start_warming - lost / 2
	food.rotprocess = saved[2]

/obj/item/storage/kerchief/MiddleClick(mob/user, list/modifiers)
	var/obj/item/dye_pack/dye = user.get_active_held_item()
	if(!istype(dye) || !isliving(user))
		return
	if(length(contents))
		to_chat(user, span_warning("I need to empty [src] before dyeing it."))
		return
	if(dyeing)
		return
	INVOKE_ASYNC(src, PROC_REF(start_dyeing), user, dye)

/obj/item/storage/kerchief/proc/can_keep_dyeing(mob/living/user, obj/item/dye_pack/dye)
	if(QDELETED(src) || QDELETED(user) || QDELETED(dye))
		return FALSE
	if(user.get_active_held_item() != dye)
		return FALSE
	if(!user.CanReach(src))
		to_chat(user, span_warning("I am too far from [src]."))
		return FALSE
	if(length(contents))
		to_chat(user, span_warning("I need to empty [src] before dyeing it."))
		return FALSE
	return TRUE

/obj/item/storage/kerchief/proc/start_dyeing(mob/living/user, obj/item/dye_pack/dye)
	dyeing = TRUE
	var/new_color = tgui_color_picker(user, "Choose a color for [src].", "Dyeing", color || "#FFFFFF", 1 MINUTES)
	dyeing = FALSE
	if(!new_color || !can_keep_dyeing(user, dye))
		return
	user.visible_message(span_notice("[user] starts dyeing [src]."), span_notice("I start dyeing [src]."))
	playsound(src, pick('sound/foley/waterwash (1).ogg', 'sound/foley/waterwash (2).ogg'), 50, FALSE)
	if(!do_after(user, 2 SECONDS, src))
		return
	if(!can_keep_dyeing(user, dye))
		return
	add_atom_colour(new_color, FIXED_COLOUR_PRIORITY)
	qdel(dye)
	user.visible_message(span_notice("[user] dyes [src]."), span_notice("I dye [src]."))

/* ------------------------------------------------------------------ */
/* Nails                                                               */
/* ------------------------------------------------------------------ */

/obj/item/natural/nail
	name = "nail"
	desc = "A small iron nail."
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state = "nails1"
	item_weight = 10 GRAMS
	sellprice = 1
	bundletype = /obj/item/natural/bundle/nails

/obj/item/natural/bundle/nails
	name = "handful of nails"
	desc = "A handful of iron nails."
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state = "nails2"
	w_class = WEIGHT_CLASS_TINY
	grid_width = 32
	grid_height = 32
	resistance_flags = NONE
	firefuel = 0
	firemod = 0
	amount = 2
	maxamount = 5
	icon1 = null
	icon2 = null
	icon3 = null
	items_per_increase = 6
	stacktype = /obj/item/natural/nail
	stackname = "nails"
	bundle_verb = "handful"

/obj/item/natural/bundle/nails/update_bundle()
	. = ..()
	icon_state = "nails[clamp(amount, 1, 5)]"
/obj/item/natural/bundle/nails/full
	icon_state = "nails5"
	amount = 5

/datum/anvil_recipe/tools/iron/nails
	name = "Handful of Nails (5)"
	recipe_name = "a handful of nails"
	created_item = /obj/item/natural/bundle/nails/full
	craftdiff = 2

/* ------------------------------------------------------------------ */
/* Crafting                                                            */
/* ------------------------------------------------------------------ */

/datum/repeatable_crafting_recipe/crafting/jewelry_box
	abstract_type = /datum/repeatable_crafting_recipe/crafting/jewelry_box
	category = "Containers"
	skillcraft = /datum/attribute/skill/craft/carpentry
	starting_atom = /obj/item/weapon/chisel
	attacked_atom = /obj/item/natural/wood/plank
	allow_inverse_start = FALSE
	tool_usage = list(
		/obj/item/weapon/chisel = list("carves the planks", "carve the planks"),
		/obj/item/weapon/hammer = list("hammers the nails in", "hammer the nails in", 'sound/foley/Building-01.ogg'),
	)

/datum/repeatable_crafting_recipe/crafting/jewelry_box/rich
	name = "rich jewelry box"
	output = /obj/item/storage/jewelry_box/rich
	requirements = list(
		/obj/item/natural/wood/plank = 1,
		/obj/item/natural/nail = 5,
		/obj/item/natural/cloth = 1,
		/obj/item/dye_pack/luxury = 1,
		/obj/item/ore/dust/gold = 1,
	)
	craftdiff = 3

/datum/repeatable_crafting_recipe/crafting/jewelry_box/big
	name = "large jewelry box"
	output = /obj/item/storage/jewelry_box/big
	requirements = list(
		/obj/item/natural/wood/plank = 2,
		/obj/item/natural/nail = 10,
	)
	craftdiff = 2

/datum/repeatable_crafting_recipe/sewing/kerchief
	name = "kerchief"
	output = /obj/item/storage/kerchief
	requirements = list(
		/obj/item/natural/cloth = 2,
		/obj/item/natural/fibers = 2,
	)
	category = "Misc"
	craftdiff = 1

/obj/item/scomstone
	grid_width = 32
	grid_height = 32
