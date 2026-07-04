/obj/structure/window/harem1
	name = "harem window"
	icon = 'modular_rmh/icons/obj/structures/roguewindow.dmi'
	icon_state = "harem1-solid"

/obj/structure/window/harem2
	name = "harem window"
	icon = 'modular_rmh/icons/obj/structures/roguewindow.dmi'
	icon_state = "harem2-solid"
	opacity = TRUE

/obj/structure/window/harem3
	name = "harem window"
	icon = 'modular_rmh/icons/obj/structures/roguewindow.dmi'
	icon_state = "harem3-solid"

/obj/structure/door/viewport/stone
	desc = "stone door"
	icon_state = "stone"
	max_integrity = 1500
	attacked_sound = list('sound/combat/hits/onwood/woodimpact (1).ogg','sound/combat/hits/onwood/woodimpact (2).ogg')
	broken_repair = /obj/item/natural/stone

/obj/structure/door/viewport/stone/broken
	desc = "A broken stone door from an era bygone. A new one must be constructed in its place."
	icon_state = "stonebr"
	density = 0
	opacity = 0
	max_integrity = 150
	obj_broken = 1

/obj/structure/fluff/railing/stonewall
	name = "stone wall"
	icon = 'modular_rmh/icons/obj/structures/cobble_fence.dmi'
	icon_state = "stonewall"
	blade_dulling = DULLING_BASHCHOP

// ===========================================================================
//  WASHBASIN - a /obj/item/bin variant for grooming/cleaning.
//  - holds only a hundred units of water
//  - 2x2 restricted storage: soap (+subtypes), a single cloth, a hairbrush
//  - sprite = water state (empty / clean / dirty) + per-item overlays
// ===========================================================================

/obj/item/bin/washbasin
	name = "washbasin"
	icon = 'modular_rmh/icons/obj/structures/decorations.dmi'
	desc = "A wooden washbasin, meant to keep a body and its linens presentable."
	icon_state = "washbasin"
	// base_state is intentionally left null so the parent Initialize() still
	// creates the reagent holder (it skips creation when base_state is preset).

/obj/item/bin/washbasin/Initialize()
	. = ..() // parent makes a 600u holder + a generic bin grid and sets base_state
	// A washbasin only ever holds a hundred units of water.
	if(reagents)
		reagents.maximum_volume = 100
	// Swap the unrestricted bin grid for our restricted 2x2 grid.
	var/datum/component/storage/old_storage = GetComponent(/datum/component/storage)
	if(old_storage)
		qdel(old_storage)
	AddComponent(/datum/component/storage/concrete/grid/washbasin)
	// Refresh the sprite whenever an item enters/leaves the basin's contents.
	RegisterSignal(src, list(COMSIG_ATOM_ENTERED, COMSIG_ATOM_EXITED), PROC_REF(on_contents_changed))
	update_appearance(UPDATE_ICON)

// Roguetown calls this whenever the held reagents change (fill, wash, splash).
/obj/item/bin/washbasin/on_reagent_change(changetype)
	. = ..()
	update_appearance(UPDATE_ICON)

/obj/item/bin/washbasin/proc/on_contents_changed(datum/source)
	SIGNAL_HANDLER
	update_appearance(UPDATE_ICON)

// --- Sprite: base state from the water, overlays from the stored items ------

/obj/item/bin/washbasin/update_icon_state()
	. = ..() // parent already applies the base / kicked-over ("over") sprite
	if(kover)
		return // a tipped basin uses the parent's "over" sprite as-is
	var/water_suffix = ""
	if(reagents?.total_volume)
		if(reagents.has_reagent(/datum/reagent/water/gross))
			water_suffix = "_dirty"	// any foul water at all reads as dirty
		else
			water_suffix = "_water"
	icon_state = "[base_state][water_suffix]" // "washbasin" / "washbasin_water" / "washbasin_dirty"

/obj/item/bin/washbasin/update_overlays()
	. = ..() // required by must_call_parent
	// The parent appends a generic liquid overlay, but the washbasin shows water
	// through its base sprite, so we rebuild the overlay list from scratch here.
	. = list()
	if(kover)
		return // tipped over - nothing to show on top
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	if(!STR)
		return
	var/has_soap = FALSE
	var/has_cloth = FALSE
	var/has_brush = FALSE
	for(var/obj/item/I in STR.contents())
		if(istype(I, /obj/item/soap))
			has_soap = TRUE
		else if(istype(I, /obj/item/natural/cloth))
			has_cloth = TRUE
		else if(istype(I, /obj/item/hairbrush))
			has_brush = TRUE
	if(has_soap)
		. += mutable_appearance(icon, "[base_state]_soap")
	if(has_cloth)
		. += mutable_appearance(icon, "[base_state]_cloth")
	if(has_brush)
		. += mutable_appearance(icon, "[base_state]_brush")

// ===========================================================================
//  Restricted 2x2 storage for the washbasin.
//  Whitelisting only /obj/item/natural/cloth automatically rejects bundles,
//  since /obj/item/natural/bundle/cloth is a separate path, not a subtype.
// ===========================================================================

/datum/component/storage/concrete/grid/washbasin
	screen_max_rows = 2
	screen_max_columns = 2
	max_w_class = WEIGHT_CLASS_NORMAL
	max_items = 4

/datum/component/storage/concrete/grid/washbasin/New(datum/P, ...)
	. = ..()
	set_holdable(list(
		/obj/item/soap,
		/obj/item/natural/cloth,
		/obj/item/hairbrush,
		))

/datum/component/storage/concrete/grid/washbasin/can_be_inserted(obj/item/storing, stop_messages, mob/user, worn_check, list/modifiers, storage_click)
	. = ..()
	if(!.)
		return
	// Only one loose cloth may soak at a time (bundles are already filtered out by the whitelist).
	if(istype(storing, /obj/item/natural/cloth))
		for(var/obj/item/natural/cloth/existing in parent)
			if(existing == storing)
				continue
			if(!stop_messages && user)
				to_chat(user, span_warning("There is already a cloth soaking in here."))
			return FALSE

/////////

/obj/machinery/light/fueled/hearth/vertical
	name = "long hearth"
	icon = 'modular_rmh/icons/obj/structures/decorations.dmi'
	icon_state = "longhearth_vert0"
	base_state = "longhearth_vert"

/obj/machinery/light/fueled/hearth/horizontal
	name = "long hearth"
	icon_state = "longhearth_horz0"
	icon = 'modular_rmh/icons/obj/structures/decorations.dmi'
	base_state = "longhearth_horz"
